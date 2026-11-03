vim.g.nv_root = vim.env.NV_TEST_ROOT
vim.opt.rtp:prepend(vim.g.nv_root)
local temp = vim.fn.tempname()
local function executable(path, body)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(vim.split(body or '#!/bin/sh\nexit 0\n', '\n', { plain = true }), path)
  assert(vim.uv.fs_chmod(path, 493))
  return path
end
local env, python = require('nv.environment'), require('nv.python')
local caller, runtime, profile = temp .. '/caller', temp .. '/runtime', temp .. '/profile'
local caller_ls = executable(caller .. '/nv-fixture-ls')
executable(runtime .. '/nv-fixture-ls')
local profile_ls = executable(profile .. '/bin/nv-profile-ls')
local original_path = vim.env.PATH
vim.env.NV_INHERITED_PATH = caller
vim.env.NV_INHERITED_PYTHONPATH = temp .. '/python-libs'
vim.env.PATH = runtime .. ':' .. original_path
vim.env.NIX_PROFILES = profile
assert(env.resolve('nv-fixture-ls') == caller_ls, 'runtime shadowed caller tool')
assert(env.resolve('nv-profile-ls') == profile_ls, 'Nix profile was not discovered')
env.setup()
assert(vim.fn.exepath('nv-profile-ls') == profile_ls, 'direct nvim startup did not expose Nix tools to plugins')
assert(env.command_env().PYTHONPATH == temp .. '/python-libs', 'caller PYTHONPATH was lost')

local caller_python = executable(caller .. '/python3')
executable(runtime .. '/python')
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
python.setup({ auto_detect = true })
local root = temp .. '/project with spaces'
vim.fn.mkdir(root, 'p')
vim.fn.writefile({ '[project]', 'name = "nv-fixture"' }, root .. '/pyproject.toml')
assert(python.detect(root).path == caller_python, 'runtime python beat caller python3')
local venv = root .. '/.venv'
vim.fn.mkdir(venv .. '/bin', 'p')
assert(vim.uv.fs_symlink(caller_python, venv .. '/bin/python'))
vim.fn.writefile({ 'home = ' .. caller }, venv .. '/pyvenv.cfg')
assert(python.detect(root).path == venv .. '/bin/python', 'project venv symlink was resolved away')
local activated = temp .. '/active'
executable(activated .. '/bin/python')
vim.env.VIRTUAL_ENV = activated
assert(python.detect(root).path == activated .. '/bin/python', 'activated venv not preferred')
vim.env.VIRTUAL_ENV = nil
python.options.interpreter = function(project) assert(project == root); return caller_python end
assert(python.detect(root).path == caller_python, 'configured interpreter ignored')
python.options.interpreter = nil
assert(python.detect(root, caller_python).path == caller_python, 'explicit LSP Python path ignored')
local config = { root_dir = root }
python.configure(config)
local client_settings = config.settings
config.before_init({}, config)
assert(client_settings.python.pythonPath == venv .. '/bin/python', 'before_init did not update client settings')
local replaced = { root_dir = root, before_init = {
  function(_, cfg) cfg.settings = { python = { analysis = { typeCheckingMode = 'basic' } } } end,
} }
python.configure(replaced)
local shared = replaced.settings
replaced.before_init({}, replaced)
assert(replaced.settings == shared and shared.python.pythonPath == venv .. '/bin/python', 'user callback disconnected client settings')
assert(shared.python.analysis.typeCheckingMode == 'basic', 'user callback settings were lost')

vim.api.nvim_buf_set_name(0, root .. '/app.py')
vim.bo.filetype = 'python'
assert(python.root() == root, 'Python workspace root wrong')
assert(python.select(activated, 0), 'selecting a venv directory failed')
assert(python.detect(root).path == activated .. '/bin/python', 'manual interpreter ignored')
assert(python.select('auto', 0), 'reset failed')
assert(python.detect(root).path == venv .. '/bin/python', 'auto interpreter not restored')
assert(python.select('.venv', 0), 'project-relative venv directory was not recognized')
assert(python.selected[root] == venv .. '/bin/python', 'relative venv used editor cwd instead of project root')
vim.cmd('NvPython ' .. vim.fn.fnameescape(venv .. '/bin/python'))
assert(python.selected[root] == venv .. '/bin/python', 'command did not handle spaces in interpreter path')
python.select('auto', 0)
python.options.auto_detect = false
assert(python.detect(root) == nil, 'auto_detect=false ignored')
python.options.auto_detect = true

executable(venv .. '/bin/black', '#!/bin/sh\nprintf "%s\\n" "$VIRTUAL_ENV"\n')
executable(caller .. '/black')
assert(python.resolve_tool('black', 0) == venv .. '/bin/black', 'project formatter was not preferred')
require('nv.actions').format()
assert(vim.wait(3000, function() return vim.api.nvim_get_current_line() == venv end, 10), 'formatter did not use the venv environment')
assert(python.command_env(0).VIRTUAL_ENV == venv, 'terminal environment lost virtualenv')

-- Existing external servers should resolve to absolute commands without changing defaults.
local overrides = {}
for name in pairs(require('nv.lsp').servers) do overrides[name] = false end
overrides.fixture = { cmd = { 'nv-fixture-ls' }, filetypes = { 'nvfixture' } }
require('nv.lsp').setup(overrides)
assert(vim.lsp.config.fixture.cmd[1] == caller_ls, 'native LSP did not use the caller executable')
assert(require('nv.lsp').active.fixture.cmd[1] == 'nv-fixture-ls', 'default command was mutated')
vim.bo.modified = false
vim.fn.delete(temp, 'rf')
print('PASS: Nix profiles, caller PATH/PYTHONPATH, Python selection, symlinks, project formatting, absolute LSP commands')
