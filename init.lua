-- NV: small, predictable, and yours.
local root = vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2))
vim.opt.rtp:prepend(root)
vim.g.nv_root = root
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

if vim.fn.has('nvim-0.12') == 0 then
  vim.api.nvim_err_writeln('NV requires Neovim 0.12 or newer (current Tree-sitter support).')
  return
end

local defaults = {
  theme = 'nv',
  icons = false,
  servers = {},
  tools = { enabled = true, auto_install = true, formatters = true, ensure_installed = {}, servers = {} },
  treesitter = { enabled = true, auto_install = true, ensure_installed = {} },
  setup = function() end,
}
local ok, user = pcall(require, 'user')
if not ok and not tostring(user):match("module 'user' not found") then error(user) end
local config = vim.tbl_deep_extend('force', defaults, ok and user or {})
require('nv.config').options = config

require('nv.options')
vim.cmd.colorscheme(config.theme)
require('nv.actions').setup()
require('nv.terminal').setup()
local installed = require('nv.bootstrap').load()
if installed then require('nv.plugins').setup() end
require('nv.tools').setup(config.tools)
require('nv.lsp').setup(config.servers)
require('nv.treesitter').setup(config.treesitter)
require('nv.keymaps').setup(installed)
require('nv.dashboard').setup()
config.setup()
