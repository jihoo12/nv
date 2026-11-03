#!/bin/sh
set -eu
export NV_TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NV_TEST_TMP=$(mktemp -d)
# This directory belongs solely to this test invocation.
trap 'rm -rf "$NV_TEST_TMP"' EXIT HUP INT TERM
export XDG_DATA_HOME="$NV_TEST_TMP/data"
export XDG_STATE_HOME="$NV_TEST_TMP/state"
export XDG_CACHE_HOME="$NV_TEST_TMP/cache"
export XDG_CONFIG_HOME="$NV_TEST_TMP/config"
export NVIM_APPNAME=nv
export NV_USE_NIX=0
NV_TEST_PIN=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mini.nvim"]["commit"])' "$NV_TEST_ROOT/plugins-lock.json")

# Reuse pinned checkouts for offline CI, or exercise first-install over the network.
python3 "$NV_TEST_ROOT/tests/seed.py"

nvim --headless -u NONE \
  -c "lua local ok,err=pcall(dofile,vim.env.NV_TEST_ROOT..'/tests/environment.lua'); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c 'qa!'

nvim --headless -u NONE \
  -c "lua local ok,err=pcall(dofile,vim.env.NV_TEST_ROOT..'/tests/tooling.lua'); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c 'qa!'

"$NV_TEST_ROOT/bin/nv" --headless \
  --cmd "lua package.preload.user=function() return {tools={auto_install=false},treesitter={auto_install=false}} end" \
  -c "lua local ok,err=pcall(dofile,vim.g.nv_root..'/tests/integration.lua'); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c 'qa!'

export NV_TEST_MINI_SOURCE="$XDG_DATA_HOME/nv/plugins/mini.nvim-$NV_TEST_PIN"
export XDG_DATA_HOME="$NV_TEST_TMP/bootstrap-data"
nvim --headless -u NONE \
  -c "lua local ok,err=pcall(dofile,vim.env.NV_TEST_ROOT..'/tests/bootstrap.lua'); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c 'qa!'

# A fresh app data directory must still boot without network or installed plugins.
export XDG_DATA_HOME="$NV_TEST_TMP/offline-data"
export NV_OFFLINE=1
"$NV_TEST_ROOT/bin/nv" --headless \
  -c "lua local ok,err=pcall(function() assert(MiniPick == nil); assert(vim.fn.exists(':NvFormat') == 2); assert(vim.g.colors_name == 'nv') end); if not ok then print(err); vim.cmd('cquit 1') end; print('PASS: offline core startup')" \
  -c 'qa!'
