-- Real downloads, builds, and LSP attachment. Opt-in network integration test.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = pcall(function()
        local workspace = vim.fn.stdpath('state') .. '/auto-install-project'
        vim.fn.mkdir(workspace .. '/.git', 'p')
        local cases = {
          { file = 'test.lua', ft = 'lua', lang = 'lua', server = 'lua_ls', formatter = 'stylua', text = 'local a = 1' },
          { file = 'test.py', ft = 'python', lang = 'python', server = 'pyright', formatter = 'black', text = 'a = 1' },
          { file = 'test.ts', ft = 'typescript', lang = 'typescript', server = 'ts_ls', formatter = 'prettier', text = 'const a = 1;' },
          { file = 'test.tsx', ft = 'typescriptreact', lang = 'tsx', server = 'ts_ls', formatter = 'prettier', text = 'const A = () => <div />;' },
        }
        for _, case in ipairs(cases) do
          vim.cmd.enew()
          vim.api.nvim_buf_set_name(0, workspace .. '/' .. case.file)
          vim.api.nvim_buf_set_lines(0, 0, -1, false, { case.text })
          local buf = vim.api.nvim_get_current_buf()
          vim.bo.filetype = case.ft
          local ready = vim.wait(120000, function()
            return vim.fn.executable(case.formatter) == 1
              and vim.uv.fs_stat(require('nv.treesitter').install_dir .. '/parser/' .. case.lang .. '.so') ~= nil
              and #vim.lsp.get_clients({ bufnr = buf, name = case.server }) > 0
              and vim.treesitter.highlighter.active[buf] ~= nil
          end, 50)
          assert(ready, case.ft .. ' automatic installation/attachment timed out: '
            .. vim.inspect({
              failures = require('nv.tools').failed,
              formatter = vim.fn.executable(case.formatter),
              parser = vim.uv.fs_stat(require('nv.treesitter').install_dir .. '/parser/' .. case.lang .. '.so') ~= nil,
              highlighter = vim.treesitter.highlighter.active[buf] ~= nil,
              clients = vim.tbl_map(function(c) return { name = c.name, initialized = c.initialized } end,
                vim.lsp.get_clients({ bufnr = buf, _uninitialized = true })),
              filetype = vim.bo[buf].filetype,
              start = { require('nv.treesitter').start(buf) },
            }))
          assert(vim.fn.maparg('<leader>cr', 'n') ~= '', 'LSP mappings not attached')
          print('PASS: downloaded ' .. case.ft .. ' server + formatter + parser; LSP and highlighting active')
          vim.bo.modified = false
        end
        local cli_ready = false
        require('nv.tools').ensure('tree-sitter-cli', function(success) cli_ready = success end)
        assert(vim.wait(60000, function() return cli_ready end, 50), 'Mason tree-sitter CLI installation failed')
        print('PASS: managed Tree-sitter CLI installed')
      end)
      if not ok then
        print(err)
        vim.cmd('cquit 1')
      else
        vim.cmd('qa!')
      end
    end)
  end,
})
