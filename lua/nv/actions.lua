local M = {}

function M.root()
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= '' and name or vim.uv.cwd()
  return vim.fs.root(start, { '.git', 'go.mod', 'Cargo.toml', 'pyproject.toml', 'package.json' }) or vim.uv.cwd()
end

M.formatters = {
  lua = { 'stylua', '--stdin-filepath', '$FILE', '-' },
  python = { 'black', '--quiet', '--stdin-filename', '$FILE', '-' },
  go = { 'gofmt' },
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

-- stdin/stdout formatting: never writes the file or applies stale results.
function M.format()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' or not vim.bo[buf].modifiable then return end
  local cmd = vim.deepcopy(M.formatters[vim.bo[buf].filetype])
  local python = vim.bo[buf].filetype == 'python'
  local executable = cmd and (python and require('nv.python').resolve_tool(cmd[1], buf)
    or require('nv.environment').resolve(cmd[1]))
  if not executable then
    local clients = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/formatting' })
    if #clients == 0 then
      vim.notify('NV: no formatter available. See :checkhealth nv', vim.log.levels.WARN)
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
  vim.system(cmd, { stdin = input, text = true, cwd = M.root(), timeout = 10000, env = env }, function(result)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then return end
      if result.code ~= 0 then
        vim.notify('NV format: ' .. (result.stderr or 'formatter failed'), vim.log.levels.ERROR)
        return
      end
      if tick ~= vim.api.nvim_buf_get_changedtick(buf) then
        vim.notify('NV: buffer changed during formatting; result discarded.', vim.log.levels.WARN)
        return
      end
      local output = result.stdout or ''
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
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('NvFormat', M.format, { desc = 'Format current buffer' })
  vim.api.nvim_create_user_command('NvHealth', 'checkhealth nv', { desc = 'Check NV dependencies' })
  vim.api.nvim_create_user_command('NvRoot', function() vim.notify(M.root()) end, { desc = 'Show project root' })
end

return M
