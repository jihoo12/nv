-- Resolve user/dev-shell tools independently of the editor's bootstrap runtime.
local M = {}

function M.profile_bins()
  local home = vim.uv.os_homedir()
  local state = vim.env.XDG_STATE_HOME or (home .. '/.local/state')
  local profiles = {
    home .. '/.nix-profile', state .. '/nix/profile', state .. '/nix/profiles/profile',
    '/etc/profiles/per-user/' .. vim.uv.os_get_passwd().username,
    '/nix/var/nix/profiles/per-user/' .. vim.uv.os_get_passwd().username .. '/profile',
    '/run/current-system/sw',
    '/nix/var/nix/profiles/default',
  }
  vim.list_extend(profiles, vim.split(vim.env.NIX_PROFILES or '', '%s+', { trimempty = true }))
  local result = {}
  for _, profile in ipairs(profiles) do
    if vim.fn.isdirectory(profile .. '/bin') == 1 then result[#result + 1] = profile .. '/bin' end
  end
  return result
end

function M.path(prefix)
  local paths, seen = {}, {}
  local candidates = { prefix or '', vim.env.NV_INHERITED_PATH or '', vim.env.PATH or '' }
  vim.list_extend(candidates, M.profile_bins())
  for _, candidate in ipairs(candidates) do
    for _, dir in ipairs(vim.split(candidate, ':', { plain = true, trimempty = true })) do
      if not seen[dir] then paths[#paths + 1], seen[dir] = dir, true end
    end
  end
  return table.concat(paths, ':')
end

function M.resolve(command, prefix)
  if command:find('/', 1, true) then
    return vim.fn.executable(command) == 1 and vim.fs.normalize(vim.fn.fnamemodify(command, ':p')) or nil
  end
  for _, dir in ipairs(vim.split(M.path(prefix), ':', { plain = true, trimempty = true })) do
    local path = dir .. '/' .. command
    if vim.fn.executable(path) == 1 then return path end
  end
end

function M.command_env(prefix)
  local env = { PATH = M.path(prefix) }
  if vim.env.NV_INHERITED_PYTHONPATH ~= nil then env.PYTHONPATH = vim.env.NV_INHERITED_PYTHONPATH end
  return env
end

function M.source(path)
  local real = vim.uv.fs_realpath(path) or path
  if path:find('/mason/', 1, true) then return 'Mason' end
  if real:sub(1, 11) == '/nix/store/' then return 'Nix' end
  return 'environment'
end

function M.setup()
  -- Also support invoking nvim -u init.lua without bin/nv.
  local paths = vim.split(vim.env.PATH or '', ':', { plain = true, trimempty = true })
  for _, dir in ipairs(M.profile_bins()) do
    if not vim.tbl_contains(paths, dir) then paths[#paths + 1] = dir end
  end
  vim.env.PATH = table.concat(paths, ':')
  if not vim.env.NV_INHERITED_PATH then vim.env.NV_INHERITED_PATH = M.path() end
  if vim.env.NV_INHERITED_PYTHONPATH == nil then vim.env.NV_INHERITED_PYTHONPATH = vim.env.PYTHONPATH or '' end
end

return M
