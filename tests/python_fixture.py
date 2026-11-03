"""Install a local wheel into two real venvs without accessing a package index."""
import csv
import io
from pathlib import Path
import subprocess
import sys
import zipfile

base = Path(sys.argv[1])
for label in ('a', 'b'):
    project = base / f'project {label}'
    project.mkdir(parents=True, exist_ok=True)
    (project / 'pyproject.toml').write_text(f'[project]\nname = "nv-test-{label}"\nversion = "0.0.1"\n')
    module = f'nv_venv_library_{label}'
    (project / 'app.py').write_text(f'import {module}\nvalue = {module}.answer()\n')
    subprocess.run([sys.executable, '-m', 'venv', str(project / '.venv')], check=True, capture_output=True)
    dist = f'{module}-1.0.dist-info'
    files = {
        f'{module}/__init__.py': 'def answer() -> int:\n    return 42\n',
        f'{module}/py.typed': '',
        f'{dist}/METADATA': f'Metadata-Version: 2.1\nName: {module}\nVersion: 1.0\n',
        f'{dist}/WHEEL': 'Wheel-Version: 1.0\nGenerator: nv-test\nRoot-Is-Purelib: true\nTag: py3-none-any\n',
    }
    record = io.StringIO()
    writer = csv.writer(record, lineterminator='\n')
    writer.writerows((name, '', '') for name in [*files, f'{dist}/RECORD'])
    files[f'{dist}/RECORD'] = record.getvalue()
    wheel = base / f'{module}-1.0-py3-none-any.whl'
    with zipfile.ZipFile(wheel, 'w') as archive:
        for name, content in files.items():
            archive.writestr(name, content)
    subprocess.run([str(project / '.venv/bin/python'), '-m', 'pip', 'install', '--no-index', '--no-deps',
                    '--disable-pip-version-check', str(wheel)], check=True, capture_output=True)
