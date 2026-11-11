# NV

**English** | [한국어](README.ko.md)

A small Neovim distribution you can understand and customize. A dark navy theme with mint accents,
native LSP, and automatic language tooling. Editing features come from mini.nvim, package installation
from Mason, and parser management from nvim-treesitter. The dashboard, theme, bootstrapper, language
configuration, formatter runner, terminal, and health checks live in this repository.

## Start

On Linux or macOS, run from the checkout:

```sh
./bin/nv
./bin/nv path/to/file
```

NV requires **Neovim 0.12 or newer**, matching the maintained nvim-treesitter main branch.
The first launch downloads pinned plugins. Opening a supported file installs its missing language
server, formatter, and parser in the background. LSP and highlighting attach when installation
finishes, without restarting the editor.

`bin/nv` uses `NVIM_APPNAME=nv` to keep configuration, data, state, and cache separate from your
existing Neovim setup. The checkout is the configuration source; no copying into `~/.config/nvim`
is necessary. Add this repository's `bin` directory to PATH to run `nv` anywhere. Keep the launcher
in the checkout rather than copying it elsewhere.

When Nix is installed and basic runtime tools are missing, the launcher prepares Neovim, a C
compiler, GNU tar, Node.js/npm, Python, Go, and other prerequisites using `runtime/flake.lock`.
Packages are cached by Nix and do not replace system packages. Only `runtime/` is used as the flake
source. `NV_USE_NIX=1` forces the runtime; `NV_USE_NIX=0` disables it.

Without Nix, provide Neovim 0.12+, Git, curl, GNU tar (`gtar` on macOS), gzip, unzip, and a C compiler.
npm-based servers need Node.js/npm, Black needs Python 3 with venv support, and gopls needs Go.
The Tree-sitter CLI is installed from its official binary through Mason if absent or too old.

## Features

- Fuzzy file, buffer, recent-file, help, diagnostic, and keymap pickers; project text search.
- Column-based file explorer: create, rename, or delete entries by editing, then apply with `=`.
- LSP completion, signature help, definitions, references, rename, code actions, diagnostics, and inlay hints.
- Tree-sitter highlighting and automatic parser installation, with syntax highlighting as a fallback.
- Pairs, text objects, surrounds, selection movement, alignment, and argument split/join.
- Native commenting, Git changes, diff overlays, commits, and hunk search.
- Statusline, buffer tabs, key hints, TODO and color-code highlighting.
- Asynchronous formatting that discards stale results, optional format on save, a persistent floating
  terminal, undo history, and cursor restoration.
- Tree-sitter folds (all open by default; `za` toggles, `zM` / `zR` close / open all).

No special font is required. Enable glyph icons only when using a Nerd Font. Debuggers and AI tools
are not bundled.

## Keys

**Space** is the leader. Pause after pressing it to see available keys.

| Key | Action |
| --- | --- |
| `Space ff` / `Space fg` | Project files / project text |
| `Space fb` / `Space fr` | Open buffers / recent files |
| `Space fw` / `Space f.` | Word under cursor in project / reopen last picker |
| `Space fh` / `Space fk` | Help / keymaps |
| `Space fd` / `Space e` | Diagnostics / file explorer |
| `Space w` / `Space q` | Save / close window, confirming unsaved changes |
| `Space bn` / `Space bp` / `Space bd` | Next / previous / close buffer |
| `Space cf` | Format buffer; inspect and save the result |
| `Space cr` / `Space ca` | Rename / code action (also on a selection) |
| `Space cs` / `Space cS` | Document symbols / workspace symbols |
| `Space cd` / `Space cq` | Line diagnostics / diagnostics quickfix list |
| `Space ch` | Toggle inlay hints |
| `gd` / `gr` / `gi` / `gy` / `K` | Definition / references / implementation / type definition / documentation |
| `[d` / `]d` | Previous / next diagnostic |
| `Space gg` / `Space gl` | Git status / commits |
| `Space gf` / `Space gh` / `Space gd` | Git files / hunks / diff overlay |
| `[h` / `]h` | Previous / next Git hunk |
| `Space t` / `Ctrl-\` in Normal mode | Toggle floating terminal |
| `Ctrl-\ Ctrl-\` in terminal | Hide terminal |
| `Ctrl-\ Ctrl-n` in terminal | Terminal Normal mode |
| `Ctrl-h/j/k/l` | Move between windows |
| `Space y` / `Space p` | System clipboard copy / paste |
| `Space un` / `Space uw` / `Space uh` | Relative numbers / wrapping / health check |
| `Space uf` | Toggle format on save for this session |
| `Space ud` / `Space uD` | Toggle diagnostics everywhere / in this buffer |
| `Tab` in Insert mode | Accept the highlighted completion, or the first one; `Ctrl-n/p` to choose |
| `sa` / `sd` / `sr` | Add / delete / replace surround |
| `Alt-h/j/k/l` | Move line or selection |
| `gS` / `ga` | Split/join arguments / align |

LSP keys are available after a server attaches. References, implementations, and symbols open in
a picker. Neovim's built-in `grn` / `gra` / `grr` / `gri` / `grt` / `grx` are removed, because they
would make `gr` wait for a further key; the keys above replace them. In a picker, type to filter, use `Ctrl-n/p` to move,
`Enter` to open, `Esc` to close, and `Tab` to toggle preview. Use `g?` in the explorer and
`:help mini.surround` for editing details. Live grep needs ripgrep (`rg`); file search can fall back
to other tools. Clipboard support depends on your platform's provider; see `:checkhealth vim.provider`.

## Language tools

Open a file to prepare its tools. Existing executables from your environment are reused; missing
ones are installed into NV's Mason directory. Concurrent requests for one package share one install.

| Language | Language server | Formatter |
| --- | --- | --- |
| Lua | lua-language-server | StyLua |
| Python | Pyright | Black |
| JavaScript / TypeScript / JSX / TSX | typescript-language-server | Prettier |
| Go | gopls | gofmt from the Go runtime |
| Rust | rust-analyzer | rustfmt from your Rust toolchain, or LSP when supported |
| C / C++ | clangd | LSP formatting |
| Shell | bash-language-server | LSP formatting when supported |
| Nix | nixd, otherwise nil, if your environment provides one | nixfmt from your environment |
| JSON / HTML / CSS / YAML / Markdown | Add a server if needed | Prettier |

Server and formatter commands are looked up when a file of their type first opens, not at startup,
and lookups are cached. A tool you install while NV is running is picked up within a couple of
seconds; `:NvToolsInstall` forces a fresh search.

Parsers follow the filetype, including TSX, JSX, and shell aliases. Parser dependencies are installed
together. Parsers marked unmaintained or unsupported upstream are excluded from automatic installs.
Parser binaries and queries are stored by the nvim-treesitter commit to keep revisions together.

Use these commands to inspect or retry:

```vim
:NvHealth         " Runtime, tool paths, Python environment, and parser status
:Mason            " Tool installation UI
:MasonLog         " Tool installation log
:TSLog            " Parser installation log
:NvToolsInstall   " Install/retry tools for open buffers and configured startup tools
```

A failed install is not retried on every file switch. Fix its cause and run `:NvToolsInstall`.
Installed language tools are updated explicitly through `:Mason`. External formatters use stdin/stdout,
edit the buffer, and do not save it. If you edit during formatting, the outdated result is discarded.
With `format_on_save = true`, the buffer is formatted just before each write, waiting up to three
seconds; a failed or missing formatter never blocks the save. Set `vim.b.nv_format_on_save = false`
to exempt a buffer.
If no external formatter is available, NV uses one attached LSP with formatting support.

## Nix and existing tools

NV resolves caller/dev-shell tools and Nix profile executables before its own runtime and Mason.
The launcher's internal `nix develop` preserves the caller's tool search path and `PYTHONPATH`
separately, so bootstrapping editor dependencies does not hide your existing servers or Python.
Resolved server and formatter commands use absolute executable paths.

Non-login shells also discover `~/.nix-profile/bin`, XDG Nix profile links/backing profiles, NixOS user/system profiles,
and profiles listed in `NIX_PROFILES`. NV does not scan `/nix/store` or evaluate arbitrary project
shells. For dependencies available only in a project shell, launch NV from that shell:

```sh
nix develop
/path/to/nv/bin/nv app.py
# direnv's activated environment works as well.
```

`:NvHealth` reports the selected server paths and whether they resolve into the Nix store or Mason.
Explicit absolute server commands in `lua/user.lua` remain supported.
For profile locations, see the official [Nix profiles reference](https://nix.dev/manual/nix/stable/command-ref/files/profiles.html).

## Python environments and installed libraries

NV selects a Python interpreter for each project in this order:

1. A project-specific selection made with `:NvPython /path/to/python`.
2. `python.interpreter` in user settings, then an explicit LSP `settings.python.pythonPath`.
3. An activated `VIRTUAL_ENV`.
4. The project's `.venv`, then `venv`.
5. An activated `CONDA_PREFIX`.
6. Python from the caller PATH/Nix profiles, then the editor runtime.

Both `python` and `python3` are checked in PATH order. Virtualenv symlinks are preserved so the
interpreter keeps its environment identity. Pyright receives `python.pythonPath` for that workspace
and queries it for library search paths. This covers pip/uv-created virtualenvs and Nix Python
environments such as `python.withPackages`. NV does not install project libraries for you.

```sh
python3 -m venv .venv
.venv/bin/python -m pip install requests
/path/to/nv/bin/nv app.py
# Or activate an existing environment before launching:
. /path/to/venv/bin/activate
/path/to/nv/bin/nv app.py
```

Inside NV:

```vim
:NvPython                          " Show interpreter, source, and project
:NvPython /path/to/venv/bin/python  " Select an interpreter or venv directory
:NvPython auto                     " Clear this project's manual selection
```

Selections last for the editor session. Changing one updates that project's running Pyright client;
other workspaces retain their own environments. Python formatting first looks in the selected
interpreter's bin directory. Newly created floating terminals receive the selected environment too;
an existing terminal keeps its original process environment. When its shell exits, the terminal
closes and the next toggle starts a new one.

Project Pyright configuration remains authoritative. Pyright's static-analysis limitations still
apply, including executable import hooks used by some editable installs. See its official
[environment and import resolution documentation](https://github.com/microsoft/pyright/blob/main/docs/import-resolution.md).
Use path-based editable installs or explicit analysis paths when your package relies on such hooks.

## Customize

```sh
cp lua/user.example.lua lua/user.lua
```

`lua/user.lua` is ignored by Git. For example:

```lua
return {
  icons = true,
  format_on_save = true,
  python = {
    auto_detect = true,
    -- interpreter = function(root) return root .. '/.venv/bin/python' end,
  },
  tools = {
    auto_install = true,
    formatters = true,
    ensure_installed = { 'lua-language-server', 'stylua' },
  },
  treesitter = { auto_install = true, ensure_installed = { 'lua', 'python' } },
  servers = {
    pyright = { settings = { python = { analysis = { typeCheckingMode = 'basic' } } } },
    -- lua_ls = { cmd = { '/path/to/nix/profile/bin/lua-language-server' } },
  },
  setup = function()
    vim.opt.relativenumber = false
    require('nv.actions').formatters.rust = { 'rustfmt', '--emit', 'stdout', '--edition', '2024' }
  end,
}
```

Add a server with `cmd`, `filetypes`, and `root_markers`. Map it to a Mason package with
`tools.servers = { custom = 'package-name' }` if you want automatic installation. A custom command
does not trigger installation of an unrelated default package. Set `servers.pyright = false` to
disable its installation and activation. `tools.auto_install = false` and
`treesitter.auto_install = false` reuse installed tools without automatic downloads; `enabled = false`
also disables loading that manager plugin.

Customize `require('nv.actions').formatters[filetype]` with a command array. `$FILE` is replaced by
the current filename, and buffer contents are passed on stdin. Rust formatting defaults to edition
2021; set 2024 as above when needed.

## Offline mode

```sh
NV_OFFLINE=1 ./bin/nv
```

Installed plugins, tools, and parsers are reused. Downloads, registry refreshes, and automatic Nix
runtime preparation are skipped. If you need the Nix runtime offline, enter the cached runtime shell
first. An unprepared offline launch still provides core editing, the theme, and available tools.

## Dependencies and updates

Plugin repositories and maintenance status were checked on 2026-11-03; all three are unarchived.
Exact commits are recorded in `plugins-lock.json`.

| Plugin | Pin | Last observed push |
| --- | --- | --- |
| [mini.nvim](https://github.com/nvim-mini/mini.nvim) | v0.18.0 / `1345d191` (stable) | 2026-10-30 |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | v2.3.1 / `2a6940af` | 2026-06-19 |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | main / `0195cd62` | 2026-11-02 |

The maintained nvim-treesitter API and Neovim's `vim.lsp.config` / `vim.lsp.enable` are used.
Plugins do not update on startup. Review upstream changes and maintenance, update the matching
lockfile entry's commit and version, and restart to install that revision. Reverting the lockfile
reuses the previous cached revision. Mason uses registry versions on first install and stores install
receipts; pinning editor plugins does not pin external language tools. The optional Nix runtime has
its own lockfile under `runtime/`.

## Tests

```sh
sh tests/run.sh
# Offline with exact pinned plugin checkouts:
NV_OFFLINE=1 \
NV_TEST_MINI_SOURCE=/path/to/mini.nvim \
NV_TEST_MASON_SOURCE=/path/to/mason.nvim \
NV_TEST_TREESITTER_SOURCE=/path/to/nvim-treesitter sh tests/run.sh
# Actual downloads, parser builds, LSP attachment, Python library resolution, and offline reuse:
sh tests/auto-install.sh
# Optional real Nix integration (Pyright output and Python with requests):
NV_TEST_NIX_PYRIGHT=/path/to/pyright-profile \
NV_TEST_NIX_PYTHON=/path/to/python-with-requests sh tests/nix-environment.sh
```

Tests use temporary XDG directories. Python 3 and Git are required. Deterministic checks cover startup,
plugins, a real mock LSP connection, formatter success/failure/stale edits, terminal reuse, dashboard
options, health, format on save, terminal restart, lookup caching, bootstrap failure cleanup, install deduplication, opt-outs, environment selection,
and offline mode. The download test checks Lua, Python, TypeScript, TSX, the managed Tree-sitter CLI,
and definition lookup of locally pip-installed libraries in two project virtualenvs, including live
interpreter changes. It then repeats using installed data offline.
The optional Nix test checks that a profile-installed Pyright and a caller `python.withPackages`
environment survive the editor runtime bootstrap and resolve the installed requests library.

CI runs on Neovim 0.12.0 and stable. Entry point: `init.lua`; implementation: `lua/nv/`;
theme: `colors/nv.lua`; optional runtime: `runtime/`.
