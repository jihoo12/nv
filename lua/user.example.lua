-- Copy this file to lua/user.lua. That file is ignored by Git.
return {
  theme = 'nv',
  icons = false, -- Set true if your terminal uses a Nerd Font.
  python = {
    auto_detect = true, -- Active virtualenv, project .venv/venv, Conda, then caller/Nix Python.
    -- interpreter = '/path/to/venv/bin/python',
    -- interpreter = function(root) return root .. '/.venv/bin/python' end,
  },
  tools = {
    auto_install = true,
    formatters = true,
    ensure_installed = {}, -- e.g. { 'lua-language-server', 'stylua' } for startup installation
    servers = {}, -- custom server name -> Mason package, or false to skip management
  },
  treesitter = {
    auto_install = true,
    ensure_installed = {}, -- e.g. { 'lua', 'python', 'markdown' }
  },
  servers = {
    -- pyright = false,
    -- lua_ls = { settings = { Lua = { diagnostics = { globals = { 'vim', 'describe', 'it' } } } } },
    -- custom = { cmd = { 'your-language-server', '--stdio' }, filetypes = { 'yourtype' }, root_markers = { '.git' } },
  },
  setup = function()
    -- vim.opt.relativenumber = false
    -- require('nv.actions').formatters.rust = { 'rustfmt', '--emit', 'stdout', '--edition', '2024' }
    -- vim.keymap.set('n', '<leader>x', '<cmd>write<cr>', { desc = 'My command' })
  end,
}
