-- On-demand Mason installation with one registry refresh and one job per package.
local M = { pending = {}, failed = {}, waiting = {}, refreshing = false }

M.server_packages = {
  lua_ls = 'lua-language-server', pyright = 'pyright', ts_ls = 'typescript-language-server',
  gopls = 'gopls', rust_analyzer = 'rust-analyzer', clangd = 'clangd', bashls = 'bash-language-server',
}
M.formatter_packages = { stylua = 'stylua', black = 'black', prettier = 'prettier' }

local function finish(name, success, reason)
  local callbacks = M.pending[name] or {}
  M.pending[name] = nil
  if success then M.failed[name] = nil end
  if not success then
    M.failed[name] = reason or 'installation failed'
    vim.notify('NV: could not install ' .. name .. ': ' .. tostring(reason)
      .. '\nSee :MasonLog; use :NvToolsInstall to retry.', vim.log.levels.WARN)
  end
  for _, callback in ipairs(callbacks) do callback(success) end
end

local function with_registry(callback)
  if M.registry_ready then callback(); return end
  M.waiting[#M.waiting + 1] = callback
  if M.refreshing then return end
  M.refreshing = true
  require('mason-registry').refresh(vim.schedule_wrap(function(success)
    M.refreshing = false
    M.registry_ready = success
    local waiting = M.waiting
    M.waiting = {}
    -- Even on refresh failure, try the previously cached registry.
    for _, fn in ipairs(waiting) do fn() end
  end))
end

function M.ensure(name, callback)
  callback = callback or function() end
  if not M.available then callback(false); return end
  if M.pending[name] then table.insert(M.pending[name], callback); return end
  local registry = require('mason-registry')
  local ok, pkg = pcall(registry.get_package, name)
  if ok and pkg:is_installed() then callback(true); return end
  if vim.env.NV_OFFLINE == '1' or M.failed[name] then callback(false); return end
  M.pending[name] = { callback }
  with_registry(function()
    local found, package = pcall(registry.get_package, name)
    if not found then finish(name, false, package); return end
    if package:is_installed() then finish(name, true); return end
    -- Registry events also cover an installation already started from :Mason.
    if package:is_installing() then return end
    vim.notify('NV: installing ' .. name .. '…')
    local started, err = pcall(package.install, package)
    if not started then finish(name, false, err) end
  end)
end

function M.ensure_buffer(buf, force)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf)
    or vim.bo[buf].buftype ~= '' then return end
  if not M.available or (not force and not M.options.auto_install) then return end
  local ft = vim.bo[buf].filetype
  if ft == '' then return end
  local lsp = require('nv.lsp')
  for name, config in pairs(lsp.active or {}) do
    if config and vim.tbl_contains(config.filetypes or {}, ft) and type(config.cmd) == 'table' then
      if vim.fn.executable(config.cmd[1]) == 1 then
        vim.lsp.enable(name)
      else
        local package = M.options.servers[name]
        if package == nil and lsp.servers[name] and config.cmd[1] == lsp.servers[name].cmd[1] then
          package = M.server_packages[name]
        end
        if package then
          M.ensure(package, function(success)
            if success and lsp.active[name] and vim.fn.executable(config.cmd[1]) == 1 then
              -- enable() also attaches to matching buffers already open.
              vim.lsp.enable(name)
            end
          end)
        end
      end
    end
  end
  if M.options.formatters then
    local cmd = require('nv.actions').formatters[ft]
    if cmd and vim.fn.executable(cmd[1]) == 0 and M.formatter_packages[cmd[1]] then
      M.ensure(M.formatter_packages[cmd[1]])
    end
  end
end

function M.retry()
  M.failed = {}
  for _, name in ipairs(M.options.ensure_installed) do M.ensure(name) end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do M.ensure_buffer(buf, true) end
  local ts = require('nv.treesitter')
  ts.failed = {}
  ts.warned = {}
  if ts.available then
    for _, lang in ipairs(ts.options.ensure_installed) do ts.install(lang) end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do ts.ensure_buffer(buf, true) end
end

function M.setup(options)
  M.options = options
  vim.api.nvim_create_user_command('NvToolsInstall', M.retry, { desc = 'Install/retry tools for open buffers' })
  if not options.enabled then return end
  if not require('nv.bootstrap').load('mason.nvim') then return end
  require('mason').setup({
    PATH = 'prepend', max_concurrent_installers = 3,
    registry_cache = { refresh = vim.env.NV_OFFLINE ~= '1' },
  })
  M.available = true
  local registry = require('mason-registry')
  registry:on('package:install:success', vim.schedule_wrap(function(pkg) finish(pkg.name, true) end))
  registry:on('package:install:failed', vim.schedule_wrap(function(pkg, err) finish(pkg.name, false, err) end))
  if options.auto_install and vim.env.NV_OFFLINE ~= '1' then
    vim.schedule(function()
      for _, name in ipairs(options.ensure_installed) do M.ensure(name) end
    end)
  end
end

return M
