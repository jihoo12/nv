-- Deterministic tests of installation orchestration; no downloads or user data.
vim.g.nv_root = vim.env.NV_TEST_ROOT
vim.opt.rtp:prepend(vim.g.nv_root)
vim.env.NV_OFFLINE = nil
local callbacks, packages, refreshes = {}, {}, 0
local function fixture_package(name)
  if packages[name] then return packages[name] end
  local pkg = { name = name, installed = false, installing = false, installs = 0 }
  function pkg:is_installed() return self.installed end
  function pkg:is_installing() return self.installing end
  function pkg:install()
    self.installs = self.installs + 1
    self.installing = true
    vim.defer_fn(function()
      self.installing = false
      self.installed = not self.fail
      local event = self.fail and 'package:install:failed' or 'package:install:success'
      callbacks[event](self, self.fail and 'fixture failure' or nil)
    end, 20)
  end
  packages[name] = pkg
  return pkg
end
package.loaded['mason-registry'] = {
  refresh = function(callback)
    refreshes = refreshes + 1
    vim.defer_fn(function() callback(true) end, 10)
  end,
  get_package = fixture_package,
  on = function(_, event, fn) callbacks[event] = fn end,
}
package.loaded['mason'] = { setup = function() end }
package.loaded['nv.bootstrap'] = { load = function() return true end }
local tools = require('nv.tools')
tools.setup({ enabled = true, auto_install = true, formatters = false, servers = {}, ensure_installed = {} })
local function wait_for(fn, msg) assert(vim.wait(2000, fn, 5), msg) end

local completed = 0
for _ = 1, 3 do tools.ensure('shared', function(ok) assert(ok); completed = completed + 1 end) end
tools.ensure('other')
wait_for(function() return completed == 3 and fixture_package('other').installed end, 'installation callbacks missing')
assert(refreshes == 1, 'concurrent requests refreshed registry more than once')
assert(fixture_package('shared').installs == 1, 'duplicate package install')

local failed = fixture_package('broken')
failed.fail = true
local notified = {}
vim.notify = function(msg) notified[#notified + 1] = msg end
tools.ensure('broken')
wait_for(function() return tools.failed.broken ~= nil end, 'failed install was not recorded')
tools.ensure('broken')
assert(failed.installs == 1, 'automatic failure retried repeatedly')
assert(table.concat(notified):find('NvToolsInstall', 1, true), 'retry instructions missing')

local refreshed = 0
package.loaded['nv.environment'] = { refresh = function() refreshed = refreshed + 1 end, resolve = function(cmd)
  if cmd == 'nv-fixture-server' and fixture_package('server-fixture').installed then return '/fixture/bin/server' end
end }
local enabled = 0
local defaults = { cmd = { 'nv-fixture-server' }, filetypes = { 'nvtest' } }
package.loaded['nv.lsp'] = {
  servers = { fixture = defaults }, active = { fixture = defaults },
  enable = function(name)
    assert(name == 'fixture')
    local config = package.loaded['nv.lsp'].active[name]
    if not config or not package.loaded['nv.environment'].resolve(config.cmd[1]) then return false end
    enabled = enabled + 1
    return true
  end,
}
tools.options.servers.fixture = 'server-fixture'
vim.bo.filetype = 'nvtest'
local buf = vim.api.nvim_get_current_buf()
tools.options.auto_install = false
tools.ensure_buffer(buf)
assert(fixture_package('server-fixture').installs == 0, 'auto_install=false was ignored')
tools.options.auto_install = true
tools.ensure_buffer(buf)
tools.ensure_buffer(buf)
wait_for(function() return enabled > 0 end, 'newly installed server was not enabled')
assert(fixture_package('server-fixture').installs == 1, 'multiple buffers duplicated server installation')
assert(refreshed > 0, 'installation did not clear cached executable lookups')
-- Without Mason, tools already in the environment must still be activated.
tools.available = false
local before_unmanaged = enabled
tools.ensure_buffer(buf)
assert(enabled == before_unmanaged + 1, 'existing server ignored when Mason is unavailable')
tools.available = true

-- Opting out and custom commands must not install an unrelated default package.
package.loaded['nv.lsp'].active.fixture = false
local before = enabled
tools.ensure_buffer(buf)
assert(enabled == before, 'disabled server was enabled')
package.loaded['nv.lsp'].active.fixture = { cmd = { 'nv-custom-server' }, filetypes = { 'nvtest' } }
tools.options.servers.fixture = nil
tools.ensure_buffer(buf)
assert(enabled == before, 'custom command triggered the default installer')

vim.env.NV_OFFLINE = '1'
local offline_result
tools.ensure('offline-new', function(ok) offline_result = ok end)
assert(offline_result == false and fixture_package('offline-new').installs == 0, 'offline mode installed a package')
tools.ensure('shared', function(ok) assert(ok, 'offline mode rejected installed tool') end)
assert(refreshes == 1, 'offline mode refreshed registry')
vim.env.NV_OFFLINE = nil

package.loaded['nv.treesitter'] = { failed = {}, warned = {}, ensure_buffer = function() end }
failed.fail = false
tools.options.ensure_installed = { 'broken' }
tools.retry()
wait_for(function() return failed.installed end, 'manual retry did not recover')
assert(failed.installs == 2 and tools.failed.broken == nil, 'retry state was not cleared')
print('PASS: automatic installs, deduplication, registry sharing, LSP activation, opt-out, offline, retry')
