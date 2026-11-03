local M = {}

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    return
  end
  local cwd = require('nv.actions').root()
  local env = require('nv.python').command_env(0)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then M.buf = vim.api.nvim_create_buf(false, true) end
  local width = math.max(1, math.floor(vim.o.columns * 0.85))
  local height = math.max(1, math.floor((vim.o.lines - 2) * 0.75))
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = 'editor', width = width, height = height,
    col = math.floor((vim.o.columns - width) / 2), row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    style = 'minimal', border = 'rounded', title = ' NV terminal ', title_pos = 'center',
  })
  if vim.bo[M.buf].buftype ~= 'terminal' then
    vim.fn.jobstart(vim.o.shell, { term = true, cwd = cwd, env = env })
    vim.bo[M.buf].bufhidden = 'hide'
  end
  vim.cmd.startinsert()
end

function M.setup()
  vim.api.nvim_create_user_command('NvTerminal', M.toggle, { desc = 'Toggle floating terminal' })
end

return M
