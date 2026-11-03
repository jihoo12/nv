local o = vim.opt
o.number = true
o.relativenumber = true
o.termguicolors = true
o.mouse = 'a'
o.signcolumn = 'yes'
o.cursorline = true
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'
o.undofile = true
o.swapfile = true
o.updatetime = 250
o.timeoutlen = 400
o.scrolloff = 6
o.sidescrolloff = 6
o.wrap = false
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.completeopt = { 'menuone', 'noselect', 'noinsert' }
o.pumheight = 12
o.laststatus = 3
o.showmode = false
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.fillchars:append({ eob = ' ' })
o.shortmess:append('I')
o.confirm = true
o.exrc = false
o.sessionoptions = { 'buffers', 'curdir', 'folds', 'help', 'tabpages', 'winsize' }

local group = vim.api.nvim_create_augroup('NvCore', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})
vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function(args)
    local line = vim.api.nvim_buf_get_mark(args.buf, '"')[1]
    if line > 1 and line <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    end
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'help', 'checkhealth', 'qf' },
  callback = function(args)
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = args.buf, desc = 'Close window' })
  end,
})
