-- Run after auto-install.lua has prepared a real Pyright server.
local base = vim.fn.stdpath('state') .. '/python-environments'
local python = require('nv.environment').resolve('python3')
local result = vim.system({ python, vim.g.nv_root .. '/tests/python_fixture.py', base }, { text = true }):wait(60000)
assert(result.code == 0, result.stderr)
local previous_virtual, previous_conda = vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
local clients, buffers = {}, {}
local function definition(buf, client, expected)
  local resolved
  assert(vim.wait(20000, function()
    local response = client:request_sync('textDocument/definition', {
      textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = 12 },
    }, 2000, buf)
    local locations = response and response.result
    local location = locations and (locations[1] or locations)
    local uri = location and (location.uri or location.targetUri)
    resolved = uri and vim.uri_to_fname(uri)
    return resolved and resolved:find(expected, 1, true) ~= nil
  end, 100), 'Pyright failed to resolve venv package: ' .. tostring(resolved))
end
for _, label in ipairs({ 'a', 'b' }) do
  local root = base .. '/project ' .. label
  vim.cmd.edit(vim.fn.fnameescape(root .. '/app.py'))
  local buf = vim.api.nvim_get_current_buf()
  assert(vim.wait(20000, function()
    local attached = vim.lsp.get_clients({ bufnr = buf, name = 'pyright' })
    clients[label] = attached[1]
    return clients[label] ~= nil
  end, 50), 'Pyright did not attach')
  assert(clients[label].settings.python.pythonPath == root .. '/.venv/bin/python', 'wrong venv interpreter')
  local run = vim.system({ root .. '/.venv/bin/python', '-c', 'import nv_venv_library_' .. label
    .. '; print(nv_venv_library_' .. label .. '.answer())' }, { text = true }):wait()
  assert(run.code == 0 and vim.trim(run.stdout) == '42', 'runtime could not import installed library')
  definition(buf, clients[label], root .. '/.venv/')
  buffers[label] = buf
end
assert(clients.a.id ~= clients.b.id, 'different projects shared Python settings')
local python_b = clients.b.settings.python.pythonPath
assert(require('nv.python').select(python_b, buffers.a), 'could not switch interpreter')
vim.api.nvim_buf_set_lines(buffers.a, 0, -1, false, { 'import nv_venv_library_b' })
definition(buffers.a, clients.a, base .. '/project b/.venv/')
assert(clients.b.settings.python.pythonPath == python_b, 'selection changed another project')
assert(require('nv.python').select('auto', buffers.a), 'could not reset interpreter')
assert(clients.a.settings.python.pythonPath == base .. '/project a/.venv/bin/python', 'reset did not restore auto detection')
vim.bo[buffers.a].modified = false
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = previous_virtual, previous_conda
print('PASS: pip-installed libraries resolve in two project venvs; live selection stays workspace-local')
