"""Exercise updates against a local upstream; no external Git server is contacted."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-update-')
        self.root = Path(self.temp.name)
        self.home = self.root / 'home'
        self.home.mkdir()
        self.notebook = self.home / 'notes'
        self.notebook.mkdir()
        self.environment = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'), XDG_DATA_HOME=str(self.home / '.local/share'), XDG_STATE_HOME=str(self.home / '.local/state'), TMUX_TMPDIR=str(self.root / 'tmux'), GIT_CONFIG_GLOBAL='/dev/null', GIT_CONFIG_NOSYSTEM='1', GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.invalid', GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.invalid')
        self.upstream = self.root / 'remote.git'
        self.producer = self.root / 'producer'
        self.consumer = self.root / 'consumer'
        shutil.copytree(REPO, self.producer, ignore=shutil.ignore_patterns('.git', '__pycache__', '.venv', 'venv'))
        self.git(self.root, 'init', '--bare', str(self.upstream))
        self.git(self.producer, 'init', '-b', 'main')
        self.git(self.producer, 'add', '.')
        self.git(self.producer, '-c', 'commit.gpgsign=false', 'commit', '-m', 'Initial fixture')
        self.git(self.producer, 'remote', 'add', 'origin', str(self.upstream))
        self.git(self.producer, 'push', '-u', 'origin', 'main')
        self.git(self.root, 'clone', '-b', 'main', str(self.upstream), str(self.consumer))
        self.cli('setup', '--non-interactive', '--notebook', str(self.notebook), '--components', 'terminal')

    def tearDown(self):
        self.temp.cleanup()

    def git(self, cwd, *args):
        return subprocess.run(['git', '-C', str(cwd), *args], env=self.environment, check=True, text=True, capture_output=True)

    def cli(self, *args, check=True):
        return subprocess.run([str(self.consumer / 'dotfiles'), *args], env=self.environment, check=check, text=True, capture_output=True)

    def advance_upstream(self):
        script = self.producer / 'dotfiles'
        text = script.read_text().replace('    args = parser.parse_args()', '    args = parser.parse_args()\n    if args.command == "apply": print("UPDATED IMPLEMENTATION")')
        script.write_text(text)
        self.git(self.producer, 'add', 'dotfiles')
        self.git(self.producer, '-c', 'commit.gpgsign=false', 'commit', '-m', 'Update implementation')
        self.git(self.producer, 'push')

    def test_fast_forward_reexecutes_updated_implementation(self):
        self.advance_upstream()
        result = self.cli('update')
        self.assertIn('UPDATED IMPLEMENTATION', result.stdout)
        self.assertEqual(self.git(self.consumer, 'rev-parse', 'HEAD').stdout, self.git(self.producer, 'rev-parse', 'HEAD').stdout)

    def test_dependency_manifest_change_runs_updated_bootstrap(self):
        config_path = self.home / '.config/dotfiles/machine.json'
        import json
        config = json.loads(config_path.read_text())
        config['components'] = []  # No network dependencies needed in this fixture.
        config_path.write_text(json.dumps(config))
        manifest = self.producer / 'code/extensions.txt'
        manifest.write_text(manifest.read_text() + 'example.unused-extension\n')
        self.git(self.producer, 'add', 'code/extensions.txt')
        self.git(self.producer, '-c', 'commit.gpgsign=false', 'commit', '-m', 'Change dependency manifest')
        self.git(self.producer, 'push')
        result = self.cli('update')
        self.assertIn('Dependencies processed.', result.stdout)

    def test_dirty_checkout_stops_without_updating(self):
        self.advance_upstream()
        (self.consumer / 'kitty/kitty.conf').write_text('local edit\n')
        before = self.git(self.consumer, 'rev-parse', 'HEAD').stdout
        result = self.cli('update', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('local changes', result.stderr)
        self.assertEqual(self.git(self.consumer, 'rev-parse', 'HEAD').stdout, before)

    def test_diverged_branch_stops_without_applying_remote(self):
        self.advance_upstream()
        (self.consumer / 'local-change.txt').write_text('local commit')
        self.git(self.consumer, 'add', 'local-change.txt')
        self.git(self.consumer, '-c', 'commit.gpgsign=false', 'commit', '-m', 'Local divergent commit')
        before = self.git(self.consumer, 'rev-parse', 'HEAD').stdout
        result = self.cli('update', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('UPDATED IMPLEMENTATION', result.stdout)
        self.assertEqual(self.git(self.consumer, 'rev-parse', 'HEAD').stdout, before)
