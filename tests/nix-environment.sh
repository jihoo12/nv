#!/bin/sh
set -eu
: "${NV_TEST_NIX_PYRIGHT:?Set to a Nix profile/store output containing bin/pyright-langserver}"
: "${NV_TEST_NIX_PYTHON:?Set to a python.withPackages output containing requests}"
export NV_TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NV_NIX_TEST_TMP=$(mktemp -d)
trap 'rm -rf "$NV_NIX_TEST_TMP"' EXIT HUP INT TERM
export XDG_DATA_HOME="$NV_NIX_TEST_TMP/data"
export XDG_STATE_HOME="$NV_NIX_TEST_TMP/state"
export XDG_CACHE_HOME="$NV_NIX_TEST_TMP/cache"
export XDG_CONFIG_HOME="$NV_NIX_TEST_TMP/config"
export PATH="$NV_TEST_NIX_PYTHON/bin:$PATH"
export NIX_PROFILES="${NIX_PROFILES:-} $NV_TEST_NIX_PYRIGHT"
export NV_USE_NIX=1
unset VIRTUAL_ENV CONDA_PREFIX NV_OFFLINE
python3 "$NV_TEST_ROOT/tests/seed.py"
"$NV_TEST_ROOT/bin/nv" --headless \
  --cmd "lua package.preload.user=function() return {tools={formatters=false},treesitter={auto_install=false}} end" \
  -c "lua dofile(vim.g.nv_root..'/tests/nix-environment.lua')"
