-- Optional: supply Nix Pyright and python.withPackages profiles via environment.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = pcall(function()
        local root = vim.fn.stdpath('state') .. '/nix-python-project'
        vim.fn.mkdir(root, 'p')
        vim.fn.writefile({ '[project]', 'name = "nv-nix-test"', 'version = "0.0.1"' }, root .. '/pyproject.toml')
        vim.fn.writefile({ 'import requests', 'response = requests.get' }, root .. '/app.py')
        vim.cmd.edit(vim.fn.fnameescape(root .. '/app.py'))
        local buf = vim.api.nvim_get_current_buf()
        local client
        assert(vim.wait(20000, function()
          client = vim.lsp.get_clients({ bufnr = buf, name = 'pyright' })[1]
          return client ~= nil
        end, 50), 'Nix Pyright did not attach')
        local environment = require('nv.environment')
        assert(environment.source(client.config.cmd[1]) == 'Nix', 'Mason/runtime shadowed Nix Pyright')
        assert(client.config.cmd[1] == vim.env.NV_TEST_NIX_PYRIGHT .. '/bin/pyright-langserver', 'wrong Pyright command')
        assert(client.settings.python.pythonPath == vim.env.NV_TEST_NIX_PYTHON .. '/bin/python', 'caller Nix Python was lost')
        local run = vim.system({ client.settings.python.pythonPath, '-c', 'import requests; print(requests.__file__)' }, { text = true }):wait()
        assert(run.code == 0, 'Nix Python could not import requests: ' .. tostring(run.stderr))
        local target
        assert(vim.wait(20000, function()
          local response = client:request_sync('textDocument/definition', {
            textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = 10 },
          }, 2000, buf)
          local locations = response and response.result
          local location = locations and (locations[1] or locations)
          local uri = location and (location.uri or location.targetUri)
          target = uri and vim.uri_to_fname(uri)
          return target and environment.source(target) == 'Nix' and target:find('/requests/', 1, true)
        end, 100), 'Pyright did not resolve requests from Nix Python: ' .. tostring(target))
        print('PASS: Nix Pyright overrides Mason; caller python.withPackages libraries resolve after runtime bootstrap')
      end)
      if not ok then print(err); vim.cmd('cquit 1') else vim.cmd('qa!') end
    end)
  end,
})
