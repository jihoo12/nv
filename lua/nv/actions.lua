local M = {}

function M.root(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  local start = name ~= '' and name or vim.uv.cwd()
  return vim.fs.root(start, { '.git', 'go.mod', 'Cargo.toml', 'pyproject.toml', 'package.json' }) or vim.uv.cwd()
end

M.formatters = {
  lua = { 'stylua', '--stdin-filepath', '$FILE', '-' },
  python = { 'black', '--quiet', '--stdin-filename', '$FILE', '-' },
  go = { 'gofmt' },
  nix = { 'nixfmt' },
  rust = { 'rustfmt', '--emit', 'stdout', '--edition', '2021' },
  javascript = { 'prettier', '--stdin-filepath', '$FILE' },
  javascriptreact = { 'prettier', '--stdin-filepath', '$FILE' },
  typescript = { 'prettier', '--stdin-filepath', '$FILE' },
  typescriptreact = { 'prettier', '--stdin-filepath', '$FILE' },
  json = { 'prettier', '--stdin-filepath', '$FILE' },
  jsonc = { 'prettier', '--stdin-filepath', '$FILE' },
  html = { 'prettier', '--stdin-filepath', '$FILE' },
  css = { 'prettier', '--stdin-filepath', '$FILE' },
  yaml = { 'prettier', '--stdin-filepath', '$FILE' },
  markdown = { 'prettier', '--stdin-filepath', '$FILE' },
}

local function apply(buf, input, output)
  if output == input then return end
  local lines = vim.split(output, '\n', { plain = true })
  local has_eol = output:sub(-1) == '\n'
  if has_eol then table.remove(lines) end
  if #lines == 0 then lines = { '' } end
  local views = {}
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    views[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].endofline = has_eol
  for win, view in pairs(views) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end)
    end
  end
end

local function failure(cmd, result)
  if result.signal ~= 0 or result.code == 124 then return vim.fs.basename(cmd[1]) .. ' timed out' end
  local message = vim.trim(result.stderr or '')
  return message ~= '' and message or (vim.fs.basename(cmd[1]) .. ' exited with code ' .. result.code)
end

-- stdin/stdout formatting: never writes the file or applies stale results.
-- opts.sync waits for the result (used before saving); opts.buf defaults to the current buffer.
function M.format(opts)
  opts = type(opts) == 'table' and opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' or not vim.bo[buf].modifiable then return end
  local cmd = vim.deepcopy(M.formatters[vim.bo[buf].filetype])
  local python = vim.bo[buf].filetype == 'python'
  local executable = cmd and (python and require('nv.python').resolve_tool(cmd[1], buf)
    or require('nv.environment').resolve(cmd[1]))
  if not executable then
    local clients = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/formatting' })
    if #clients == 0 then
      if not opts.quiet then vim.notify('NV: no formatter available. See :checkhealth nv', vim.log.levels.WARN) end
      return
    end
    -- Choose a single server, with synchronous edits to avoid stale async edits.
    table.sort(clients, function(a, b) return a.name < b.name end)
    vim.lsp.buf.format({ bufnr = buf, id = clients[1].id, timeout_ms = 3000 })
    return
  end
  cmd[1] = executable
  local file = vim.api.nvim_buf_get_name(buf)
  if file == '' then
    vim.notify('NV: give this buffer a filename before formatting.', vim.log.levels.WARN)
    return
  end
  for i, arg in ipairs(cmd) do if arg == '$FILE' then cmd[i] = file end end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  if vim.bo[buf].endofline then input = input .. '\n' end
  local env = python and require('nv.python').command_env(buf) or require('nv.environment').command_env()
  local options = { stdin = input, text = true, cwd = M.root(buf), timeout = opts.sync and 3000 or 10000, env = env }
  local function done(result)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then return end
    if result.code ~= 0 then
      vim.notify('NV format: ' .. failure(cmd, result), vim.log.levels.ERROR)
      return
    end
    if tick ~= vim.api.nvim_buf_get_changedtick(buf) then
      vim.notify('NV: buffer changed during formatting; result discarded.', vim.log.levels.WARN)
      return
    end
    apply(buf, input, result.stdout or '')
  end
  local started, job = pcall(vim.system, cmd, options, not opts.sync and vim.schedule_wrap(done) or nil)
  if not started then
    vim.notify('NV format: could not run ' .. cmd[1] .. ': ' .. tostring(job), vim.log.levels.ERROR)
  elseif opts.sync then
    done(job:wait())
  end
end

function M.setup()
  vim.api.nvim_create_user_command('NvFormat', function() M.format() end, { desc = 'Format current buffer' })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('NvFormatOnSave', { clear = true }),
    callback = function(args)
      -- Opt-in. `vim.b.nv_format_on_save = false` exempts one buffer.
      if require('nv.config').options.format_on_save and vim.b[args.buf].nv_format_on_save ~= false then
        M.format({ buf = args.buf, sync = true, quiet = true })
      end
    end,
  })
  vim.api.nvim_create_user_command('NvHealth', 'checkhealth nv', { desc = 'Check NV dependencies' })
  vim.api.nvim_create_user_command('NvRoot', function() vim.notify(M.root()) end, { desc = 'Show project root' })
end

return M
