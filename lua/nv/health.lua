local M = {}

function M.check()
  local h = vim.health
  h.start('NV runtime')
  if vim.fn.has('nvim-0.12') == 1 then h.ok('Neovim >= 0.12') else h.error('Neovim >= 0.12 required') end
  local bootstrap = require('nv.bootstrap')
  for _, name in ipairs({ 'mini.nvim', 'mason.nvim', 'nvim-treesitter' }) do
    local spec = bootstrap.spec(name)
    if vim.uv.fs_stat(bootstrap.path(name) .. '/' .. (spec.entry or 'lua/mini/init.lua')) then
      h.ok(name .. ' ' .. spec.version .. ' pinned at ' .. spec.commit)
    else h.warn(name .. ' missing; restart with Git and network access (NV_OFFLINE unset)') end
  end
  for _, tool in ipairs({ 'git', 'rg' }) do
    if vim.fn.executable(tool) == 1 then h.ok(tool .. ' found')
    else h.warn(tool .. ' missing', { tool == 'rg' and 'Install ripgrep for live grep.' or 'Install Git for plugins and Git integration.' }) end
  end
  if vim.fn.has('clipboard') == 1 and vim.fn.executable('wl-copy') == 1 then
    h.ok('Wayland clipboard provider found')
  else h.info('Clipboard: see :checkhealth vim.provider if Space y / Space p are unavailable.') end
  h.start('Automatic tooling')
  local tools, ts = require('nv.tools'), require('nv.treesitter')
  h.info('Offline mode: ' .. tostring(vim.env.NV_OFFLINE == '1'))
  h.info('Mason available: ' .. tostring(tools.available == true))
  h.info('Auto-install language tools: ' .. tostring(tools.options.auto_install))
  for _, cmd in ipairs({ 'curl', 'tar', 'unzip', 'node', 'npm', 'python3', 'go', 'tree-sitter' }) do
    if vim.fn.executable(cmd) == 1 then h.ok(cmd .. ' found')
    else h.info(cmd .. ' missing (only needed for packages using this runtime; tree-sitter CLI is installed automatically)') end
  end
  if vim.fn.executable('cc') == 1 or vim.fn.executable('gcc') == 1 or vim.fn.executable('clang') == 1
    or (vim.env.CC and vim.fn.executable(vim.split(vim.env.CC, ' ')[1]) == 1) then
    h.ok('C compiler available for parsers')
  else h.warn('C compiler missing: install cc/gcc/clang to build Tree-sitter parsers') end
  h.info('Tree-sitter available: ' .. tostring(ts.available == true))
  if ts.available then
    h.info('Parser/query directory: ' .. ts.install_dir)
    h.info('Installed parsers: ' .. table.concat(require('nvim-treesitter').get_installed('parsers'), ', '))
  end
  for name, reason in pairs(tools.failed) do h.warn(name .. ': ' .. tostring(reason)) end
  for name in pairs(ts.failed) do h.warn('Parser installation failed: ' .. name .. '; see :TSLog') end
  h.start('Language servers (installed automatically on demand)')
  for _, name in ipairs(vim.fn.sort(vim.tbl_keys(require('nv.lsp').active or {}))) do
    local cfg = require('nv.lsp').active[name]
    if cfg == false then h.info(name .. ': disabled')
    elseif cfg.cmd and vim.fn.executable(cfg.cmd[1]) == 1 then h.ok(name .. ': ' .. cfg.cmd[1])
    else h.info(name .. ': installed on first matching file (' .. ((cfg.cmd or {})[1] or 'no command') .. ')') end
  end
  h.start('Formatters (optional)')
  local seen = {}
  for _, cmd in pairs(require('nv.actions').formatters) do
    if not seen[cmd[1]] then
      seen[cmd[1]] = true
      if vim.fn.executable(cmd[1]) == 1 then h.ok(cmd[1] .. ' found') else h.info(cmd[1] .. ' not installed; LSP formatting used when available') end
    end
  end
end

return M
