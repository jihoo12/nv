vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then vim.cmd('syntax reset') end
vim.o.background = 'dark'
vim.g.colors_name = 'nv'

local c = {
  bg = '#141b25', surface = '#1c2633', raised = '#263344', fg = '#d8e1eb',
  muted = '#8293a7', mint = '#8bd5ba', blue = '#91b9ed', purple = '#c7a8eb',
  yellow = '#ebcf91', red = '#ef9398', orange = '#eeb18a',
}
local groups = {
  Normal = { fg = c.fg, bg = c.bg }, NormalFloat = { fg = c.fg, bg = c.surface },
  FloatBorder = { fg = c.muted, bg = c.surface }, FloatTitle = { fg = c.mint, bg = c.surface, bold = true },
  CursorLine = { bg = c.surface }, CursorLineNr = { fg = c.mint, bold = true },
  LineNr = { fg = '#536477' }, SignColumn = { bg = c.bg },
  WinSeparator = { fg = c.raised }, Visual = { bg = '#33465b' },
  Search = { fg = c.bg, bg = c.yellow }, IncSearch = { fg = c.bg, bg = c.mint },
  CurSearch = { fg = c.bg, bg = c.orange }, MatchParen = { fg = c.yellow, bold = true, underline = true },
  Pmenu = { fg = c.fg, bg = c.surface }, PmenuSel = { fg = c.bg, bg = c.mint, bold = true },
  PmenuSbar = { bg = c.raised }, PmenuThumb = { bg = c.muted },
  StatusLine = { fg = c.fg, bg = c.raised }, StatusLineNC = { fg = c.muted, bg = c.surface },
  TabLine = { fg = c.muted, bg = c.surface }, TabLineSel = { fg = c.mint, bg = c.raised, bold = true },
  TabLineFill = { bg = c.bg }, NonText = { fg = '#425369' }, Whitespace = { fg = '#35465b' },
  Comment = { fg = c.muted, italic = true }, Constant = { fg = c.orange },
  String = { fg = c.mint }, Character = { fg = c.mint }, Number = { fg = c.orange },
  Boolean = { fg = c.orange }, Identifier = { fg = c.fg }, Function = { fg = c.blue },
  Statement = { fg = c.purple }, Keyword = { fg = c.purple }, Operator = { fg = c.blue },
  PreProc = { fg = c.yellow }, Type = { fg = c.yellow }, Special = { fg = c.blue },
  Delimiter = { fg = c.muted }, Error = { fg = c.red }, Todo = { fg = c.bg, bg = c.yellow, bold = true },
  Directory = { fg = c.blue }, Title = { fg = c.mint, bold = true }, NvTitle = { fg = c.mint, bold = true },
  DiagnosticError = { fg = c.red }, DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue }, DiagnosticHint = { fg = c.mint },
  DiagnosticUnderlineError = { sp = c.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = c.yellow, undercurl = true },
  DiffAdd = { bg = '#223d38' }, DiffChange = { bg = '#26384e' },
  DiffDelete = { fg = c.red, bg = '#422b35' }, DiffText = { bg = '#374e6c' },
  MiniDiffSignAdd = { fg = c.mint }, MiniDiffSignChange = { fg = c.blue }, MiniDiffSignDelete = { fg = c.red },
  MiniPickMatchCurrent = { bg = c.raised }, MiniPickMatchRanges = { fg = c.mint, bold = true },
  MiniStatuslineModeNormal = { fg = c.bg, bg = c.mint, bold = true },
  MiniStatuslineModeInsert = { fg = c.bg, bg = c.blue, bold = true },
  MiniStatuslineModeVisual = { fg = c.bg, bg = c.purple, bold = true },
  MiniStatuslineModeReplace = { fg = c.bg, bg = c.red, bold = true },
}
for name, value in pairs(groups) do vim.api.nvim_set_hl(0, name, value) end
for name, target in pairs({
  ['@variable'] = 'Identifier', ['@variable.builtin'] = 'Special', ['@function'] = 'Function',
  ['@function.builtin'] = 'Special', ['@keyword'] = 'Keyword', ['@string'] = 'String',
  ['@type'] = 'Type', ['@property'] = 'Identifier', ['@comment'] = 'Comment',
  ['@markup.heading'] = 'Title', ['@markup.link'] = 'Underlined',
}) do vim.api.nvim_set_hl(0, name, { link = target }) end
