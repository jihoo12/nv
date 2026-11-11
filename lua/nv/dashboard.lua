local M = {}

function M.open()
  if vim.fn.argc() > 0 or vim.bo.buftype ~= '' or vim.bo.modified
    or vim.api.nvim_buf_get_name(0) ~= '' or vim.fn.line('$') > 1
    or vim.api.nvim_get_current_line() ~= '' then return end
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'nvstart'
  local lines = {
    '', '', '       N V', '       a quieter workspace', '',
    '       [f]  Find files', '       [e]  Explore project', '       [r]  Recent files',
    '       [n]  New buffer', '       [h]  Health check', '       [q]  Quit', '',
    '       Space is your leader. Pause to see available keys.', '',
    '       ' .. vim.fn.fnamemodify(vim.uv.cwd(), ':~'),
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  local win = vim.api.nvim_get_current_win()
  local previous = { number = vim.wo.number, relativenumber = vim.wo.relativenumber, cursorline = vim.wo.cursorline }
  vim.wo.number, vim.wo.relativenumber, vim.wo.cursorline = false, false, false
  local ns = vim.api.nvim_create_namespace('NvDashboard')
  vim.api.nvim_buf_set_extmark(buf, ns, 2, 0, { line_hl_group = 'NvTitle' })
  vim.api.nvim_buf_set_extmark(buf, ns, 3, 0, { line_hl_group = 'Comment' })
  for _, key in ipairs({ 'f', 'e', 'r' }) do
    local target = ({ f = '<leader>ff', e = '<leader>e', r = '<leader>fr' })[key]
    vim.keymap.set('n', key, target, { buffer = buf, remap = true, nowait = true })
  end
  vim.keymap.set('n', 'n', '<cmd>enew<cr>', { buffer = buf })
  vim.keymap.set('n', 'h', '<cmd>checkhealth nv<cr>', { buffer = buf })
  vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = buf })
  -- Window-local dashboard options must not leak into an opened file.
  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = buf, once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        for name, value in pairs(previous) do vim.wo[win][name] = value end
      end
    end,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup('NvDashboard', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function()
      if #vim.api.nvim_list_uis() > 0 then M.open() end
    end,
  })
end

return M
