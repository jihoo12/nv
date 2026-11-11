local M = { selected = {} }
M.root_markers = { 'pyrightconfig.json', 'pyproject.toml', 'setup.cfg', 'setup.py', 'requirements.txt', '.git' }

function M.root(buf)
  buf = buf or 0
  if vim.bo[buf].buftype ~= '' then
    local alternate = vim.fn.bufnr('#')
    buf = alternate > 0 and vim.api.nvim_buf_is_valid(alternate) and vim.bo[alternate].buftype == ''
      and alternate or nil
  end
  local file = buf and vim.api.nvim_buf_get_name(buf) or ''
  return vim.fs.root(file ~= '' and file or vim.uv.cwd(), M.root_markers)
    or (file ~= '' and vim.fs.dirname(file) or vim.uv.cwd())
end

local function interpreter(value, root)
  if not value or value == '' then return end
  value = vim.fn.expand(value)
  if value:sub(1, 1) ~= '/' and (value:find('/', 1, true) or vim.fn.isdirectory(root .. '/' .. value) == 1) then
    value = root .. '/' .. value
  end
  if vim.fn.isdirectory(value) == 1 then value = value .. '/bin/python' end
  -- Keep virtualenv symlinks intact: realpath() would lose sys.prefix.
  return require('nv.environment').resolve(value)
end

function M.detect(root, configured)
  root = root or M.root()
  local options = M.options or { auto_detect = true }
  local override = options.interpreter
  if type(override) == 'function' then override = override(root) end
  local lsp = package.loaded['nv.lsp']
  if configured == nil and lsp and lsp.active and lsp.active.pyright then
    configured = vim.tbl_get(lsp.active.pyright, 'settings', 'python', 'pythonPath')
  end
  local explicit = M.selected[root] or override or configured
  if explicit then
    local path = interpreter(explicit, root)
    return path and { path = path, root = root, source = 'explicit' } or nil
  end
  if options.auto_detect == false then return end
  local candidates = {
    { vim.env.VIRTUAL_ENV, 'VIRTUAL_ENV' },
    { root .. '/.venv', 'project .venv' }, { root .. '/venv', 'project venv' },
    { vim.env.CONDA_PREFIX, 'CONDA_PREFIX' },
  }
  for _, candidate in ipairs(candidates) do
    local path = candidate[1] and interpreter(candidate[1] .. '/bin/python', root)
    if path then return { path = path, root = root, source = candidate[2], venv = candidate[1] } end
  end
  local env = require('nv.environment')
  local path
  for _, dir in ipairs(vim.split(env.path(), ':', { plain = true, trimempty = true })) do
    path = env.resolve(dir .. '/python') or env.resolve(dir .. '/python3')
    if path then break end
  end
  return path and { path = path, root = root, source = env.source(path) } or nil
end

function M.apply(config)
  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  local info = M.detect(config.root_dir, config.settings.python.pythonPath)
  if info then config.settings.python.pythonPath = info.path end
end

function M.configure(config)
  -- Client.settings is initialized before before_init; mutate this shared table.
  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  local before_init = config.before_init
  config.before_init = function(params, client_config)
    local shared = client_config.settings
    if type(before_init) == 'table' then
      for _, callback in ipairs(before_init) do callback(params, client_config) end
    elseif before_init then before_init(params, client_config) end
    M.apply(client_config)
    if client_config.settings ~= shared then
      -- User callbacks may replace settings; keep Client.settings in sync too.
      for key in pairs(shared) do shared[key] = nil end
      for key, value in pairs(client_config.settings) do shared[key] = value end
      client_config.settings = shared
    end
  end
end

function M.command_env(buf)
  local info = M.detect(M.root(buf))
  local env = require('nv.environment').command_env(info and vim.fs.dirname(info.path))
  if info and info.venv then
    if info.source == 'CONDA_PREFIX' then env.CONDA_PREFIX = info.venv
    else env.VIRTUAL_ENV = info.venv end
  elseif info and vim.uv.fs_stat(vim.fs.dirname(vim.fs.dirname(info.path)) .. '/pyvenv.cfg') then
    env.VIRTUAL_ENV = vim.fs.dirname(vim.fs.dirname(info.path))
  end
  return env
end

function M.resolve_tool(command, buf)
  local info = M.detect(M.root(buf))
  return require('nv.environment').resolve(command, info and vim.fs.dirname(info.path))
end

function M.select(value, buf)
  local root = M.root(buf)
  if value == 'auto' then
    M.selected[root] = nil
  else
    local path = interpreter(value, root)
    if not path then
      vim.notify('NV: Python interpreter not executable: ' .. value, vim.log.levels.ERROR)
      return false
    end
    M.selected[root] = path
  end
  require('nv.environment').refresh()
  -- Update only this workspace, preserving every other Python client's settings.
  for _, client in ipairs(vim.lsp.get_clients({ name = 'pyright' })) do
    if client.config.root_dir == root then
      local settings = vim.tbl_get(require('nv.lsp').active or {}, 'pyright', 'settings') or {}
      local config = { root_dir = root, settings = vim.deepcopy(settings) }
      M.apply(config)
      client.config.settings = config.settings
      client.settings = config.settings
      client:notify('workspace/didChangeConfiguration', { settings = config.settings })
    end
  end
  return true
end

function M.setup(options)
  M.options = options
  vim.api.nvim_create_user_command('NvPython', function(args)
    local value = args.fargs[1] or ''
    if value ~= '' and not M.select(value) then return end
    local info = M.detect()
    vim.notify(info and (info.path .. '\nSource: ' .. info.source .. '\nProject: ' .. info.root)
      or 'NV: no Python interpreter found. Use :NvPython /path/to/venv/bin/python')
  end, { nargs = '?', complete = 'file', desc = 'Show/select project Python; use auto to reset' })
end

return M
