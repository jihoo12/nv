#!/bin/sh
set -eu
export NV_TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NV_AUTO_TMP=$(mktemp -d)
if [ "${NV_AUTO_TEST_KEEP:-0}" = 1 ]; then
  echo "Keeping test data at $NV_AUTO_TMP" >&2
else
  trap 'rm -rf "$NV_AUTO_TMP"' EXIT HUP INT TERM
fi
export XDG_DATA_HOME="$NV_AUTO_TMP/data"
export XDG_STATE_HOME="$NV_AUTO_TMP/state"
export XDG_CACHE_HOME="$NV_AUTO_TMP/cache"
export XDG_CONFIG_HOME="$NV_AUTO_TMP/config"
export NVIM_APPNAME=nv
unset NV_OFFLINE
python3 "$NV_TEST_ROOT/tests/seed.py"
"$NV_TEST_ROOT/bin/nv" --headless \
  -c "lua dofile(vim.g.nv_root..'/tests/auto-install.lua')"

# Reuse installed tools/parsers without any registry refresh or download.
export NV_OFFLINE=1
"$NV_TEST_ROOT/bin/nv" --headless \
  -c "lua dofile(vim.g.nv_root..'/tests/auto-install.lua')"
