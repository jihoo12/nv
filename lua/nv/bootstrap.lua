local M = {}

function M.spec(name)
  local contents = table.concat(vim.fn.readfile(vim.g.nv_root .. '/plugins-lock.json'), '\n')
  return vim.json.decode(contents)[name or 'mini.nvim']
end

function M.path(name)
  name = name or 'mini.nvim'
  return vim.fn.stdpath('data') .. '/plugins/' .. name .. '-' .. M.spec(name).commit
end

function M.load(name)
  name = name or 'mini.nvim'
  local spec, path = M.spec(name), M.path(name)
  local function ready(dir) return vim.uv.fs_stat(dir .. '/' .. (spec.entry or 'lua/mini/init.lua')) ~= nil end
  if not ready(path) then
    if vim.env.NV_OFFLINE == '1' then
      vim.notify('NV: ' .. name .. ' is not installed; its features are disabled. Restart online to install.', vim.log.levels.WARN)
      return false
    end
    if vim.fn.executable('git') == 0 then
      vim.notify('NV: install Git, then restart to install ' .. name .. '.', vim.log.levels.ERROR)
      return false
    end
    vim.notify('NV: installing pinned ' .. name .. ' (first launch only)…')
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    local temp = path .. '.tmp-' .. vim.fn.getpid()
    local function run(args)
      local result = vim.system(args, { text = true }):wait(120000)
      if result.code ~= 0 then error(result.stderr or 'Git command timed out') end
    end
    local success, err = pcall(function()
      run({ 'git', 'clone', '--depth', '1', '--branch', spec.branch, spec.url, temp })
      local head = vim.system({ 'git', '-C', temp, 'rev-parse', 'HEAD' }, { text = true }):wait()
      if vim.trim(head.stdout or '') ~= spec.commit then
        run({ 'git', '-C', temp, 'fetch', '--depth', '1', 'origin', spec.commit })
      end
      run({ 'git', '-C', temp, 'checkout', '--detach', spec.commit })
      assert(ready(temp), name .. ' checkout is incomplete')
      local renamed, rename_err = vim.uv.fs_rename(temp, path)
      assert(renamed or ready(path), rename_err)
    end)
    -- Only this process's temporary installation is disposable.
    if vim.uv.fs_stat(temp) then vim.fn.delete(temp, 'rf') end
    if not success then
      vim.notify('NV plugin installation failed: ' .. tostring(err)
        .. '\nCore editing remains available. Check network/Git and restart.', vim.log.levels.ERROR)
      return false
    end
  end
  vim.opt.rtp:prepend(path)
  return true
end

return M
