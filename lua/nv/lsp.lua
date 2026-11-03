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
}

function M.enable(name)
  local config = M.active[name]
  if not config then return false end
  if type(config.cmd) == 'table' then
    local executable = require('nv.environment').resolve(config.cmd[1])
    if not executable then return false end
    -- Do not mutate the default command: it is also used to match Mason packages.
    local command = vim.deepcopy(config.cmd)
    command[1] = executable
    vim.lsp.config(name, { cmd = command })
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
  local group = vim.api.nvim_create_augroup('NvLsp', { clear = true })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local function map(key, fn, desc)
        vim.keymap.set('n', key, fn, { buffer = args.buf, desc = desc })
      end
      map('gd', vim.lsp.buf.definition, 'Go to definition')
      map('gD', vim.lsp.buf.declaration, 'Go to declaration')
      map('gr', vim.lsp.buf.references, 'References')
      map('gi', vim.lsp.buf.implementation, 'Implementation')
      map('K', vim.lsp.buf.hover, 'Hover documentation')
      map('<leader>cr', vim.lsp.buf.rename, 'Rename symbol')
      map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
      map('<leader>cs', vim.lsp.buf.document_symbol, 'Document symbols')
      map('<leader>ch', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
      end, 'Toggle inlay hints')
    end,
  })
  M.active = vim.deepcopy(M.servers)
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
      M.enable(name)
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
