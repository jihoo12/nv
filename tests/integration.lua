local function check(value, message) assert(value, message) end
local function wait_for(fn, message) check(vim.wait(5000, fn, 10), message) end
local root = vim.g.nv_root

check(vim.g.colors_name == 'nv', 'theme missing')
check(MiniPick and MiniFiles and MiniCompletion and MiniDiff, 'mini modules missing')
check(require('nv.tools').available, 'Mason not configured')
check(require('nv.treesitter').available, 'Tree-sitter not configured')
check(vim.fn.exists(':Mason') == 2, 'Mason command missing')
check(vim.fn.exists(':TSInstall') == 2, 'TSInstall command missing')
check(vim.treesitter.language.get_lang('typescriptreact') == 'tsx', 'TSX parser mapping missing')
check(vim.treesitter.language.get_lang('javascriptreact') == 'javascript', 'JSX parser mapping missing')
check(vim.treesitter.language.get_lang('sh') == 'bash', 'shell parser mapping missing')
check(vim.fn.maparg('<leader>ff', 'n') ~= '', 'file picker mapping missing')
check(vim.fn.maparg('gc', 'n') ~= '', 'native commenting missing')
check(vim.fn.exists(':NvFormat') == 2, 'format command missing')
check(vim.fn.exists(':Git') == 2, 'Git command missing')
check(vim.fn.stdpath('data'):match('/nv$'), 'app data must be isolated')
check(vim.loader.enabled, 'Lua module cache is not enabled')
-- Startup must not search PATH for language servers that no open file needs.
for name in pairs(require('nv.lsp').servers) do
  check(not require('nv.lsp').enabled[name], name .. ' was resolved at startup')
end
-- `gr` must not be a prefix of built-in mappings, or key hints wait for Enter.
for _, key in ipairs({ 'grn', 'gra', 'grr', 'gri', 'grt', 'grx' }) do
  check(vim.fn.maparg(key, 'n') == '', key .. ' still shadows gr')
end
for _, group in ipairs({ 'MiniTablineCurrent', 'DiagnosticUnderlineHint', 'LspInlayHint', 'Folded' }) do
  check(next(vim.api.nvim_get_hl(0, { name = group })) ~= nil, 'theme lacks ' .. group)
end

-- Disabled and custom servers must survive configuration merging.
require('nv.lsp').setup({ pyright = false, nv_test = {
  cmd = { 'python3', root .. '/tests/mock_lsp.py' },
  filetypes = { 'nvtest' }, root_markers = { '.git' },
} })
check(require('nv.lsp').active.pyright == false, 'server disabling failed')
vim.cmd.enew()
vim.api.nvim_buf_set_name(0, root .. '/tests/fixture.nvtest')
vim.bo.filetype = 'nvtest'
local buf = vim.api.nvim_get_current_buf()
wait_for(function() return #vim.lsp.get_clients({ bufnr = buf }) > 0 end, 'LSP did not attach')
wait_for(function() return vim.fn.maparg('<leader>cr', 'n') ~= '' end, 'LspAttach mappings missing')
check(vim.fn.maparg('gr', 'n') ~= '' and vim.fn.maparg('gy', 'n') ~= '', 'LSP navigation mappings missing')
check(vim.fn.maparg('<leader>ca', 'x') ~= '', 'range code action mapping missing')
local client = vim.lsp.get_clients({ bufnr = buf })[1]
local response = client:request_sync('textDocument/hover', {
  textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = 0 },
}, 3000, buf)
check(response and response.result.contents.value == 'NV test server', 'LSP request failed')
client:stop(true)

-- Diagnostics can be silenced everywhere or for one buffer, and restored.
local function press(keys) vim.api.nvim_feedkeys(vim.keycode(keys), 'x', false) end
local quiet_notify = vim.notify
vim.notify = function() end
press('<Space>ud')
check(not vim.diagnostic.is_enabled(), 'diagnostics toggle did not disable')
press('<Space>ud')
check(vim.diagnostic.is_enabled(), 'diagnostics toggle did not re-enable')
press('<Space>uD')
check(not vim.diagnostic.is_enabled({ bufnr = 0 }), 'buffer diagnostics toggle did not disable')
vim.cmd.new()
check(vim.diagnostic.is_enabled({ bufnr = 0 }), 'buffer toggle silenced another buffer')
vim.cmd.close()
press('<Space>uD')
check(vim.diagnostic.is_enabled({ bufnr = 0 }), 'buffer diagnostics toggle did not re-enable')
vim.notify = quiet_notify

-- Tab accepts a completion (the first when none is selected) and stays a plain Tab otherwise.
vim.cmd.enew()
vim.bo.expandtab = false
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'nvcompletionword', '' })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
press('invcomp<C-x><C-n><Tab><Esc>')
check(vim.api.nvim_get_current_line() == 'nvcompletionword', 'Tab did not accept the first completion: ' .. vim.api.nvim_get_current_line())
press('cc<Tab>x<Esc>')
check(vim.api.nvim_get_current_line() == '\tx', 'Tab without a completion menu is not a plain Tab')
vim.bo.modified = false

-- Exercise the actual file browser and picker, including the source directory.
require('mini.files').open(root)
check(require('mini.files').get_explorer_state() ~= nil, 'file explorer did not open')
require('mini.files').close()
local picker_checked = false
vim.schedule(function()
  picker_checked = MiniPick.is_picker_active() and MiniPick.get_picker_opts().source.cwd == root
  MiniPick.stop()
end)
MiniPick.builtin.files({}, { source = { cwd = root } })
check(picker_checked, 'file picker did not use project root')

-- Format through a real subprocess, then ensure edits made in flight win.
vim.cmd.enew()
vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '.lua')
vim.bo.filetype = 'lua'
local actions = require('nv.actions')
local original = actions.formatters.lua
actions.formatters.lua = { 'python3', '-c', 'import sys; print(sys.stdin.read().upper(), end="")' }
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
actions.format()
wait_for(function() return vim.api.nvim_get_current_line() == 'HELLO' end, 'formatter output not applied')
check(vim.bo.modified, 'format should leave file unsaved')
local messages, notify = {}, vim.notify
vim.notify = function(msg) messages[#messages + 1] = msg end
actions.formatters.lua = { 'python3', '-c', 'import sys,time; data=sys.stdin.read(); time.sleep(.15); print(data.upper(), end="")' }
actions.format()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'new edit' })
wait_for(function() return #messages > 0 end, 'stale result was not reported')
check(vim.api.nvim_get_current_line() == 'new edit', 'formatter overwrote a newer edit')
messages = {}
actions.formatters.lua = { 'python3', '-c', 'import sys; sys.stderr.write("test failure"); sys.exit(1)' }
actions.format()
wait_for(function() return #messages > 0 end, 'formatter error was not reported')
check(vim.api.nvim_get_current_line() == 'new edit', 'failed formatter changed buffer')
messages = {}
actions.formatters.lua = { 'python3', '-c', 'import sys; sys.exit(3)' }
actions.format()
wait_for(function() return #messages > 0 end, 'silent formatter failure was not reported')
check(messages[1]:find('exited with code 3', 1, true), 'failure without stderr has no explanation: ' .. messages[1])

-- Format on save is opt-in, synchronous, and can be exempted per buffer.
actions.formatters.lua = { 'python3', '-c', 'import sys; print(sys.stdin.read().upper(), end="")' }
local function saved() return table.concat(vim.fn.readfile(vim.api.nvim_buf_get_name(0)), '\n') end
vim.cmd('silent write')
check(saved() == 'new edit', 'format on save ran without opting in')
require('nv.config').options.format_on_save = true
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'saved text' })
vim.cmd('silent write')
check(saved() == 'SAVED TEXT' and not vim.bo.modified, 'format on save did not format the written file')
vim.b.nv_format_on_save = false
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'exempt' })
vim.cmd('silent write')
check(saved() == 'exempt', 'buffer exemption ignored')
require('nv.config').options.format_on_save = false
actions.formatters.lua, vim.notify = original, notify

-- Floating terminal keeps its running buffer when hidden and reopened.
vim.bo.modified = false
local terminal = require('nv.terminal')
terminal.toggle()
check(vim.bo.buftype == 'terminal', 'terminal not started')
local term_buf = terminal.buf
terminal.toggle()
check(vim.api.nvim_buf_is_valid(term_buf), 'hiding killed terminal buffer')
terminal.toggle()
check(terminal.buf == term_buf, 'reopening replaced terminal buffer')
-- When the shell exits, its window and buffer go away and the next toggle starts fresh.
vim.fn.jobstop(vim.bo[term_buf].channel)
wait_for(function() return not vim.api.nvim_buf_is_valid(term_buf) end, 'exited terminal buffer was kept')
check(terminal.win == nil and vim.bo.buftype ~= 'terminal', 'exited terminal window was kept')
terminal.toggle()
check(vim.bo.buftype == 'terminal' and terminal.buf ~= term_buf, 'terminal did not restart after exit')
terminal.toggle()

-- Dashboard must not leak its window options into the next document.
vim.cmd.enew()
require('nv.dashboard').open()
check(vim.bo.filetype == 'nvstart', 'dashboard not shown')
vim.cmd.enew()
check(vim.wo.number and vim.wo.relativenumber, 'dashboard leaked number options')
vim.wo.relativenumber = false
require('nv.dashboard').open()
vim.cmd.enew()
check(not vim.wo.relativenumber, 'dashboard ignored user number settings')

vim.cmd('checkhealth nv')
local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
check(report:find('pinned at', 1, true), 'health report missing dependency pin')
check(not report:find('ERROR', 1, true), 'health report contains an error')
print('PASS: startup, plugins, explorer/picker, LSP, formatter safety, terminal, dashboard, health')
