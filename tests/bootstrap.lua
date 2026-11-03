-- Use a local Git remote to test first install without requiring network access.
vim.g.nv_root = vim.env.NV_TEST_ROOT
vim.opt.rtp:prepend(vim.g.nv_root)
local bootstrap = require('nv.bootstrap')
local spec = bootstrap.spec()
spec.url = vim.env.NV_TEST_MINI_SOURCE
bootstrap.spec = function() return spec end
vim.env.NV_OFFLINE = nil
assert(bootstrap.load(), 'first-install failed')
local head = vim.system({ 'git', '-C', bootstrap.path(), 'rev-parse', 'HEAD' }, { text = true }):wait()
assert(vim.trim(head.stdout or '') == spec.commit, 'installed wrong commit')
vim.env.NV_OFFLINE = '1'
assert(bootstrap.load(), 'installed plugin did not load offline')

-- A bad remote must fail gracefully and clean its partial checkout.
spec.commit = string.rep('0', 40)
spec.url = vim.env.NV_TEST_MINI_SOURCE .. '/nonexistent-remote'
vim.env.NV_OFFLINE = nil
local notifications, notify = {}, vim.notify
vim.notify = function(msg) notifications[#notifications + 1] = msg end
assert(not bootstrap.load(), 'broken remote should return false')
assert(not vim.uv.fs_stat(bootstrap.path()), 'failed checkout left behind')
assert(not vim.uv.fs_stat(bootstrap.path() .. '.tmp-' .. vim.fn.getpid()), 'partial checkout not cleaned')
assert(table.concat(notifications):find('installation failed', 1, true), 'installation failure not reported')
vim.notify = notify
print('PASS: bootstrap install, pinned commit, offline reuse, failed install cleanup')
