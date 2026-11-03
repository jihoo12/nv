"""Seed isolated tests with explicitly supplied, pinned plugin checkouts."""
import json
import os
from pathlib import Path
import shutil
import subprocess

root = Path(os.environ['NV_TEST_ROOT'])
specs = json.loads((root / 'plugins-lock.json').read_text())
for name, env in [('mini.nvim', 'NV_TEST_MINI_SOURCE'), ('mason.nvim', 'NV_TEST_MASON_SOURCE'),
                  ('nvim-treesitter', 'NV_TEST_TREESITTER_SOURCE')]:
    source = os.environ.get(env)
    if not source:
        continue
    head = subprocess.check_output(['git', '-C', source, 'rev-parse', 'HEAD'], text=True).strip()
    assert head == specs[name]['commit'], f'{name} test checkout differs from lockfile'
    target = Path(os.environ['XDG_DATA_HOME']) / 'nv' / 'plugins' / f'{name}-{head}'
    shutil.copytree(source, target)
