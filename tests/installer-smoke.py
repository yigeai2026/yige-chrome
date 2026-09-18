"""Maintainer check: real trial ZIP, isolated local state, no browser/profile access.
Usage: python tests/installer-smoke.py [--package C:/path/to/trial.zip]
Requires Python 3.11+ and Windows PowerShell. Does not touch actual Codex config.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib

parser = argparse.ArgumentParser()
parser.add_argument('--package', type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
base = Path(tempfile.mkdtemp(prefix='yige-installer-test-')) / '\u4e2d\u6587 \u7a7a\u683c'
base.mkdir()
install = base / 'apps'
config_dir = base / 'codex'
config_dir.mkdir()
config = config_dir / 'config.toml'
original = '# existing user settings\nmodel = "fixture-model"\n[mcp_servers.other]\ncommand = "fixture-tool"\n'
config.write_text(original, encoding='utf-8')
env = dict(os.environ, LOCALAPPDATA=str(base / 'local'), YIGEAI_DATA_DIR=str(base / 'data'))

def run(extra=(), accept=True, install_root=install, package=args.package, expected=0):
    command = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(repo / 'install.ps1'),
               '-ConfigureCodex', '-InstallRoot', str(install_root), '-CodexConfigDirectory', str(config_dir)]
    if package is not None:
        command.extend(['-PackagePath', str(package.resolve())])
    if accept:
        command.append('-AcceptLicense')
    command.extend(extra)
    result = subprocess.run(command, env=env, capture_output=True, timeout=180)
    assert (result.returncode == 0) == (expected == 0), result.stderr.decode(errors='replace')
    return result

run(accept=False, expected=1)
assert config.read_text(encoding='utf-8') == original
run()
parsed = tomllib.loads(config.read_text(encoding='utf-8'))
assert parsed['model'] == 'fixture-model'
assert parsed['mcp_servers']['other']['command'] == 'fixture-tool'
entry = parsed['mcp_servers']['yigeai-chrome']
assert Path(entry['command']).is_file() and Path(entry['args'][0]).is_file()
assert entry['env']['YIGEAI_DATA_DIR'] == str(base / 'data').replace('\\', '/')
backups = list(config_dir.glob('config.toml.before-yige-*.bak'))
assert len(backups) == 1 and backups[0].read_text(encoding='utf-8') == original
skill = config_dir / 'skills/yigeai-chrome/SKILL.md'
assert skill.is_file()
token = json.loads((base / 'data/connection.json').read_text(encoding='utf-8'))['token']
first_config = config.read_bytes()
run()
assert config.read_bytes() == first_config
assert json.loads((base / 'data/connection.json').read_text(encoding='utf-8'))['token'] == token
assert len(list(config_dir.glob('config.toml.before-yige-*.bak'))) == 1
assert token not in config.read_text(encoding='utf-8')

# Never overwrite a custom existing MCP or skill. Exercise quoted and inline TOML.
for existing in ['[mcp_servers."yigeai-chrome"]\ncommand="custom"\n',
                 "[mcp_servers.'yigeai-chrome']\ncommand='custom'\n",
                 'mcp_servers = {other = {command = "custom"}}\n']:
    config.write_text(existing, encoding='utf-8')
    run(expected=1)
    assert config.read_text(encoding='utf-8') == existing
config.write_bytes(first_config)
skill.write_text('custom skill', encoding='utf-8')
run(expected=1)
assert skill.read_text(encoding='utf-8') == 'custom skill'
assert config.read_bytes() == first_config

# Tampered download must fail before executing setup or installing files.
config.write_text(original, encoding='utf-8')
bad = base / 'corrupt.zip'
bad.write_bytes(b'not the release')
run(install_root=base / 'bad-install', package=bad, expected=1)
assert not (base / 'bad-install').exists()
assert config.read_text(encoding='utf-8') == original
print(json.dumps({'passed': True, 'checks': ['license_required', 'real_package_install', 'config_preserved_and_backed_up',
    'valid_toml_and_skill', 'unicode_space_path', 'idempotent_pairing_and_config', 'quoted_and_inline_conflicts_preserved',
    'custom_skill_preserved', 'tampered_package_rejected'], 'isolatedDirectory': str(base)}, ensure_ascii=True))
