local M = {}

function M.setup()
  local config = require('nv.config').options
  require('mini.icons').setup({ style = config.icons and 'glyph' or 'ascii' })
  require('mini.ai').setup()
  require('mini.align').setup()
  require('mini.surround').setup()
  require('mini.pairs').setup()
  require('mini.move').setup()
  require('mini.splitjoin').setup()
  require('mini.bracketed').setup()
  require('mini.bufremove').setup()
  require('mini.completion').setup()
  require('mini.pick').setup()
  require('mini.extra').setup()
  require('mini.files').setup({ windows = { preview = true } })
  require('mini.git').setup()
  require('mini.diff').setup()
  require('mini.statusline').setup({ use_icons = config.icons })
  require('mini.tabline').setup({ show_icons = config.icons })
  local hipatterns = require('mini.hipatterns')
  hipatterns.setup({ highlighters = {
    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
    hex_color = hipatterns.gen_highlighter.hex_color(),
  } })
  local clue = require('mini.clue')
  clue.setup({
    triggers = {
      { mode = 'n', keys = '<Leader>' }, { mode = 'x', keys = '<Leader>' },
      { mode = 'n', keys = 'g' }, { mode = 'n', keys = '[' }, { mode = 'n', keys = ']' },
      { mode = 'n', keys = '<C-w>' }, { mode = 'i', keys = '<C-x>' },
    },
    clues = {
      { mode = 'n', keys = '<Leader>f', desc = '+Find' },
      { mode = 'n', keys = '<Leader>c', desc = '+Code' },
      { mode = 'n', keys = '<Leader>g', desc = '+Git' },
      { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
      { mode = 'n', keys = '<Leader>u', desc = '+UI' },
      clue.gen_clues.g(), clue.gen_clues.square_brackets(),
      clue.gen_clues.windows(), clue.gen_clues.builtin_completion(),
    },
    window = { delay = 300, config = { width = 'auto' } },
  })
  vim.ui.select = require('mini.pick').ui_select
end

return M
