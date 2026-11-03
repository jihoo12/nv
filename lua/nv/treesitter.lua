local M = { pending = {}, failed = {}, warned = {} }

local function warn_once(key, message)
  if M.warned[key] then return end
  M.warned[key] = true
  vim.notify('NV Tree-sitter: ' .. message, vim.log.levels.WARN)
end

local function start_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then M.start(buf) end
  end
end

function M.start(buf)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then return false end
  local path = M.install_dir and (M.install_dir .. '/parser/' .. lang .. '.so')
  if path and vim.uv.fs_stat(path) then
    -- Runtime discovery can retain a negative result from before installation.
    -- Load the new library by its exact path so the first buffer works immediately.
    local ok, loaded, err = pcall(vim.treesitter.language.add, lang, { path = path })
    if not ok or not loaded then return false, err or loaded end
  end
  return pcall(vim.treesitter.start, buf, lang)
end

function M.install(lang)
  if not M.available or vim.env.NV_OFFLINE == '1' then return end
  if M.pending[lang] or M.failed[lang] then return end
  local parser = require('nvim-treesitter.parsers')[lang]
  -- Avoid unsupported/unmaintained parsers in automatic installations.
  if not parser or (parser.tier or 2) > 2 then return end
  if not (vim.fn.executable('cc') == 1 or vim.fn.executable('gcc') == 1
    or vim.fn.executable('clang') == 1 or (vim.env.CC and vim.fn.executable(vim.split(vim.env.CC, ' ')[1]) == 1)) then
    warn_once('compiler', 'a C compiler is required to build parsers. Install cc/gcc/clang, then :NvToolsInstall.')
    return
  end
  M.pending[lang] = true
  local function install(cli_ready)
    if not cli_ready then
      M.pending[lang] = nil
      return
    end
    require('nvim-treesitter').install({ lang }):await(vim.schedule_wrap(function(err, success)
      M.pending[lang] = nil
      if err or not success then
        M.failed[lang] = true
        warn_once(lang, 'could not install ' .. lang .. '. See :TSLog; use :NvToolsInstall to retry.')
        return
      end
      -- Also invalidate runtime query discovery after creating new directories.
      vim.o.runtimepath = vim.o.runtimepath
      start_buffers()
    end))
  end
  if M.cli_ready then install(true); return end
  if vim.fn.executable('tree-sitter') == 1 then
    vim.system({ 'tree-sitter', '--version' }, { text = true }, vim.schedule_wrap(function(result)
      local version = (result.stdout or ''):match('%d+%.%d+%.%d+')
      if result.code == 0 and version and vim.version.ge(version, '0.26.1') then
        M.cli_ready = true
        install(true)
      else
        require('nv.tools').ensure('tree-sitter-cli', function(success)
          M.cli_ready = success
          install(success)
        end)
      end
    end))
  else
    require('nv.tools').ensure('tree-sitter-cli', function(success)
      M.cli_ready = success
      install(success)
    end)
  end
end

function M.ensure_buffer(buf, force)
  if not M.available or not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= '' then return end
  local ft = vim.bo[buf].filetype
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang then return end
  -- Always use existing parsers in offline mode and when auto-install is disabled.
  local has_managed = vim.uv.fs_stat(M.install_dir .. '/parser/' .. lang .. '.so')
  if M.start(buf) and has_managed then return end
  if vim.env.NV_OFFLINE == '1' or (not force and not M.options.auto_install) then return end
  M.install(lang)
end

function M.setup(options)
  M.options = options
  if not options.enabled then return end
  if not require('nv.bootstrap').load('nvim-treesitter') then return end
  for lang, filetypes in pairs({
    bash = { 'sh', 'bash' }, javascript = { 'javascriptreact' },
    tsx = { 'typescriptreact' }, json = { 'jsonc' },
  }) do vim.treesitter.language.register(lang, filetypes) end
  -- Parser and query revisions are tied to the pinned plugin, so upgrades get a clean cache.
  M.install_dir = vim.fn.stdpath('data') .. '/treesitter/' .. require('nv.bootstrap').spec('nvim-treesitter').commit
  require('nvim-treesitter').setup({ install_dir = M.install_dir })
  M.available = true
  local group = vim.api.nvim_create_augroup('NvTreesitter', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(args) M.ensure_buffer(args.buf) end,
  })
  vim.schedule(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do M.ensure_buffer(buf) end
    if options.auto_install and vim.env.NV_OFFLINE ~= '1' then
      for _, lang in ipairs(options.ensure_installed) do M.install(lang) end
    end
  end)
end

return M
