local M = {}

M.servers = {
  lua_ls = {
    cmd = { 'lua-language-server' }, filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
    settings = { Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { checkThirdParty = false }, telemetry = { enable = false },
    } },
  },
  pyright = {
    cmd = { 'pyright-langserver', '--stdio' }, filetypes = { 'python' },
    root_markers = require('nv.python').root_markers,
  },
  ts_ls = {
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  },
  gopls = {
    cmd = { 'gopls' }, filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_markers = { 'go.work', 'go.mod', '.git' },
  },
  rust_analyzer = {
    cmd = { 'rust-analyzer' }, filetypes = { 'rust' },
    root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
  },
  clangd = {
    cmd = { 'clangd' }, filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_markers = { '.clangd', 'compile_commands.json', 'compile_flags.txt', '.git' },
  },
  bashls = {
    cmd = { 'bash-language-server', 'start' }, filetypes = { 'sh', 'bash' },
    root_markers = { '.git' },
  },
  -- Nix servers are never downloaded: they attach when your profile or dev shell provides them.
  nixd = {
    cmd = { 'nixd' }, filetypes = { 'nix' },
    root_markers = { 'flake.nix', '.git' },
  },
  nil_ls = {
    cmd = { 'nil' }, filetypes = { 'nix' },
    root_markers = { 'flake.nix', '.git' },
  },
}

M.alternatives = { nil_ls = 'nixd' }

-- Resolve and enable a server; safe to call repeatedly. Returns false while its command is missing.
function M.enable(name)
  local config = M.active[name]
  if not config then return false end
  if type(config.cmd) == 'table' then
    local executable = require('nv.environment').resolve(config.cmd[1])
    if not executable then return false end
    if M.enabled[name] == executable then return true end
    -- Two servers for one language would duplicate every result; the preferred one wins.
    local preferred = M.active[M.alternatives[name]]
    if preferred and type(preferred.cmd) == 'table' and require('nv.environment').resolve(preferred.cmd[1]) then
      return false
    end
    -- Do not mutate the default command: it is also used to match Mason packages.
    local command = vim.deepcopy(config.cmd)
    command[1] = executable
    vim.lsp.config(name, { cmd = command })
    M.enabled[name] = executable
  elseif M.enabled[name] then
    return true
  else
    M.enabled[name] = true
  end
  vim.lsp.enable(name)
  return true
end

function M.setup(overrides)
  vim.diagnostic.config({
    severity_sort = true, underline = true, update_in_insert = false,
    virtual_text = { spacing = 2, prefix = '●', severity = { min = vim.diagnostic.severity.WARN } },
    float = { border = 'rounded', source = true },
    signs = { text = { [1] = 'E', [2] = 'W', [3] = 'I', [4] = 'H' } },
  })
  -- Neovim's gr-prefixed defaults make `gr` ambiguous, so the key hints would wait for Enter.
  -- NV maps every one of them: gr, gi, gy, Space cr, Space ca.
  for _, key in ipairs({ 'grn', 'gra', 'grr', 'gri', 'grt', 'grx' }) do
    pcall(vim.keymap.del, 'n', key)
  end
  pcall(vim.keymap.del, 'x', 'gra')
  local group = vim.api.nvim_create_augroup('NvLsp', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local function map(key, fn, desc)
        vim.keymap.set('n', key, fn, { buffer = args.buf, desc = desc })
      end
      -- With the picker available, multi-result lists are filterable and previewable.
      local function list(scope, fallback)
        return function()
          if _G.MiniExtra then MiniExtra.pickers.lsp({ scope = scope }) else fallback() end
        end
      end
      map('gd', vim.lsp.buf.definition, 'Go to definition')
      map('gD', vim.lsp.buf.declaration, 'Go to declaration')
      map('gr', list('references', vim.lsp.buf.references), 'References')
      map('gi', list('implementation', vim.lsp.buf.implementation), 'Implementation')
      map('gy', vim.lsp.buf.type_definition, 'Go to type definition')
      map('K', vim.lsp.buf.hover, 'Hover documentation')
      map('<leader>cr', vim.lsp.buf.rename, 'Rename symbol')
      vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { buffer = args.buf, desc = 'Code action' })
      map('<leader>cs', list('document_symbol', vim.lsp.buf.document_symbol), 'Document symbols')
      map('<leader>cS', list('workspace_symbol_live', vim.lsp.buf.workspace_symbol), 'Workspace symbols')
      map('<leader>ch', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
      end, 'Toggle inlay hints')
    end,
  })
  M.active, M.enabled = vim.deepcopy(M.servers), {}
  if _G.MiniCompletion then
    -- Advertise what the completion engine supports (resolve, snippets-as-text, etc.).
    vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
  end
  for name, config in pairs(overrides or {}) do
    if config == false then
      M.active[name] = false
    else
      M.active[name] = vim.tbl_deep_extend('force', M.active[name] or {}, config)
    end
  end
  for name, config in pairs(M.active) do
    if config then
      config.cmd_env = vim.tbl_extend('force', require('nv.environment').command_env(), config.cmd_env or {})
      if name == 'pyright' then require('nv.python').configure(config) end
      vim.lsp.config(name, config)
      -- Commands are looked up when a matching filetype opens; searching PATH for every
      -- server here would slow each launch. Servers without that trigger start now.
      if type(config.cmd) ~= 'table' or not config.filetypes then M.enable(name) end
    end
  end
  local tools = require('nv.tools')
  local tool_group = vim.api.nvim_create_augroup('NvLspTools', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = tool_group,
    callback = function(args) tools.ensure_buffer(args.buf) end,
  })
  vim.schedule(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then tools.ensure_buffer(buf) end
    end
  end)
end

return M
