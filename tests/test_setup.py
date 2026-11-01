"""Behavioral checks use isolated homes; no live configs or desktop settings change."""
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('dotfiles_setup', str(REPO / 'dotfiles'))
spec = importlib.util.spec_from_loader(loader.name, loader)
setup = importlib.util.module_from_spec(spec)
loader.exec_module(setup)


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles user's home ")
        self.home = Path(self.temp.name)
        self.config = self.home / '.config'
        self.data = self.home / '.local/share'
        self.state = self.home / '.local/state/dotfiles'
        self.notebook = self.home / 'different notebook'
        self.notebook.mkdir()
        self.paths = patch.multiple(setup, HOME=self.home, CONFIG=self.config, DATA=self.data, STATE=self.state)
        self.paths.start()
        self.quiet = contextlib.redirect_stdout(io.StringIO())
        self.quiet.__enter__()
        self.machine = {'notebook_dir': str(self.notebook), 'components': ['shell', 'terminal', 'nvim', 'editors', 'desktop', 'tasks']}

    def tearDown(self):
        self.quiet.__exit__(None, None, None)
        self.paths.stop()
        self.temp.cleanup()

    def test_apply_twice_and_rollback_preserves_existing_files_and_links(self):
        rc = self.home / '.zshrc'
        rc.write_text('original shell config\n')
        tmux = self.home / '.tmux.conf'
        tmux.symlink_to('missing-old-target')
        setup.apply(self.machine)
        self.assertEqual(rc.resolve(), REPO / 'backup_zshrc')
        self.assertEqual(setup.file_plan(self.machine), [])
        backup = next((self.state / 'backups').iterdir())
        setup.apply(self.machine)
        self.assertEqual(len(list((self.state / 'backups').iterdir())), 1)
        setup.restore(backup)
        self.assertEqual(rc.read_text(), 'original shell config\n')
        self.assertEqual(os.readlink(tmux), 'missing-old-target')
        self.assertFalse(os.path.lexists(self.home / '.p10k.zsh'))

    def test_dry_run_makes_no_files_or_backups(self):
        before = set(self.home.rglob('*'))
        setup.apply(self.machine, dry_run=True)
        self.assertEqual(before, set(self.home.rglob('*')))

    def test_preflight_conflict_prevents_partial_apply(self):
        (self.home / '.tmux.conf').mkdir()
        with self.assertRaisesRegex(ValueError, 'directory'):
            setup.apply(self.machine)
        self.assertFalse((self.home / '.zshrc').exists())
        self.assertFalse(self.state.exists())

    def test_refuses_writes_through_parent_symlink(self):
        outside = self.home / 'outside'
        outside.mkdir()
        self.config.mkdir()
        (self.config / 'kitty').symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'Parent directory is a symlink'):
            setup.apply(self.machine)
        self.assertEqual(list(outside.iterdir()), [])

    def test_rollback_protects_later_edits(self):
        setup.apply(self.machine)
        generated = self.config / 'dotfiles/env.zsh'
        generated.write_text('new local edit\n')
        backup = next((self.state / 'backups').iterdir())
        with self.assertRaisesRegex(ValueError, 'Changed since apply'):
            setup.restore(backup)
        self.assertEqual(generated.read_text(), 'new local edit\n')
        setup.restore(backup, force=True)
        self.assertFalse(generated.exists())

    def test_failure_restores_earlier_changes(self):
        rc = self.home / '.zshrc'
        rc.write_text('keep me')
        original = setup.Transaction.file
        calls = []
        def fail_on_second(transaction, *args, **kwargs):
            calls.append(1)
            if len(calls) == 2:
                raise OSError('simulated disk error')
            return original(transaction, *args, **kwargs)
        with patch.object(setup.Transaction, 'file', fail_on_second):
            with self.assertRaises(OSError):
                setup.apply(self.machine)
        self.assertEqual(rc.read_text(), 'keep me')
        self.assertFalse((self.home / '.p10k.zsh').exists())

    def test_binary_backups_restore_exact_bytes(self):
        path = self.home / 'addon.xpi'
        path.write_bytes(b'\x00\xfforiginal')
        transaction = setup.Transaction()
        transaction.file(path, content=b'\x01\xfereplacement')
        transaction.finish()
        setup.restore(transaction.folder)
        self.assertEqual(path.read_bytes(), b'\x00\xfforiginal')

    def test_notebook_and_tool_paths_survive_shell_quoting(self):
        extra = self.home / 'tools $dollar `tick`'
        extra.mkdir()
        self.machine.update(path_dirs=[str(extra)], env={'VENV_PYTHON': 'python3'})
        setup.apply(self.machine)
        command = 'source "$1"; printf "%s\\n%s\\n%s" "$NOTEBOOK_DIR" "$VENV_PYTHON" "$PATH"'
        result = subprocess.run(['zsh', '-f', '-c', command, 'zsh', str(self.config / 'dotfiles/env.zsh')], capture_output=True, text=True, check=True)
        lines = result.stdout.splitlines()
        self.assertEqual(lines[0], str(self.notebook))
        self.assertEqual(lines[1], 'python3')
        self.assertTrue(lines[2].startswith(str(extra) + ':'))
        self.assertEqual(json.loads((self.config / 'dotfiles/paths.json').read_text())['notebook_dir'], str(self.notebook))

    def test_zed_preserves_local_ssh_connections_in_jsonc(self):
        path = self.config / 'zed/settings.json'
        path.parent.mkdir(parents=True)
        path.write_text('// local comment\n{"ssh_connections": [{"host": "example.invalid", "paths": ["/local/project"]}], "theme": "old",}\n')
        setup.apply(self.machine)
        settings = json.loads(path.read_text())
        self.assertEqual(settings['ssh_connections'][0]['host'], 'example.invalid')
        self.assertEqual(settings['theme']['dark'], 'Ayu Dark')
        self.assertFalse(path.is_symlink())
        self.assertEqual(setup.file_plan(self.machine), [])
        self.assertEqual(setup.jsonc('{"url":"https://example.invalid/a,}",}'), {'url': 'https://example.invalid/a,}'})

    def test_firefox_merges_and_preserves_other_preferences(self):
        profile = self.home / 'browser profile'
        profile.mkdir()
        path = profile / 'user.js'
        path.write_text('user_pref("my.custom.pref", true);\n')
        # An unlocked .parentlock file is normal after Firefox exits.
        (profile / '.parentlock').touch()
        self.machine.update(components=['firefox'], firefox_profile=str(profile))
        setup.apply(self.machine)
        self.assertIn('my.custom.pref', path.read_text())
        self.assertEqual(path.read_text().count(setup.START), 1)
        self.assertEqual(setup.file_plan(self.machine), [])
        setup.restore(next((self.state / 'backups').iterdir()))
        self.assertEqual(path.read_text(), 'user_pref("my.custom.pref", true);\n')

    def test_live_firefox_lock_aborts_before_other_files_change(self):
        profile = self.home / 'browser'
        profile.mkdir()
        (profile / 'lock').symlink_to(f'127.0.0.1:+{os.getpid()}')
        self.machine.update(components=['shell', 'firefox'], firefox_profile=str(profile))
        with self.assertRaisesRegex(ValueError, 'Close Firefox'):
            setup.apply(self.machine)
        self.assertFalse((self.home / '.zshrc').exists())

    def test_managed_block_rejects_malformed_markers(self):
        with self.assertRaisesRegex(ValueError, 'Malformed'):
            setup.managed(setup.START + 'partial\n', 'new')

    def test_wayland_skips_double_ctrl_autostart(self):
        with patch.dict(os.environ, {'XDG_SESSION_TYPE': 'wayland'}):
            setup.apply(self.machine)
        self.assertFalse((self.config / 'autostart/rofi-double-ctrl.desktop').exists())
        self.assertFalse((self.home / '.local/bin/rofi-double-ctrl').exists())
        self.assertTrue((self.home / '.local/bin/rofi-powermenu').is_symlink())

    def test_tmux_config_reloads_without_invalid_bindings(self):
        setup.apply(self.machine)
        sockets = self.home / 'tmux-sockets'
        sockets.mkdir()
        environment = dict(os.environ, HOME=str(self.home), TMUX_TMPDIR=str(sockets), SHELL='/bin/sh')
        # Avoid unrelated TPM startup; this check covers our tmux command syntax.
        tpm = self.home / '.tmux/plugins/tpm/tpm'
        tpm.parent.mkdir(parents=True)
        tpm.write_text('#!/bin/sh\nexit 0\n')
        tpm.chmod(0o755)
        command = ['tmux', '-L', 'syntax-check']
        try:
            subprocess.run(command + ['-f', '/dev/null', 'new-session', '-d'], env=environment, check=True, capture_output=True)
            result = subprocess.run(command + ['source-file', str(REPO / '.tmux.conf')], env=environment, check=True, capture_output=True, text=True)
            self.assertEqual(result.stderr, '')
        finally:
            subprocess.run(command + ['kill-server'], env=environment, capture_output=True)

    def test_validation_rejects_reserved_variables_and_missing_paths(self):
        with self.assertRaisesRegex(ValueError, 'overriding HOME'):
            setup.validate(dict(self.machine, env={'HOME': '/other'}))
        with self.assertRaisesRegex(ValueError, 'existing directory'):
            setup.validate(dict(self.machine, notebook_dir='/nonexistent-notebook'))

    def test_profile_detection_uses_profiles_ini(self):
        root = self.home / 'snap/firefox/common/.mozilla/firefox'
        profile = root / 'arbitrary.default'
        profile.mkdir(parents=True)
        (root / 'profiles.ini').write_text('[Profile0]\nPath=arbitrary.default\nIsRelative=1\n')
        self.assertEqual(setup.profiles(), [profile])

    def test_cli_noninteractive_setup_uses_custom_home_and_xdg(self):
        environment = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.config), XDG_DATA_HOME=str(self.data), XDG_STATE_HOME=str(self.home / '.local/state'), TMUX_TMPDIR=str(self.home / 'tmux-sockets'))
        command = [str(REPO / 'dotfiles'), 'setup', '--non-interactive', '--notebook', str(self.notebook), '--components', 'shell,terminal,nvim']
        subprocess.run(command + ['--dry-run'], env=environment, check=True, capture_output=True)
        self.assertFalse(self.config.exists())
        subprocess.run(command, env=environment, check=True, capture_output=True)
        config = json.loads((self.config / 'dotfiles/machine.json').read_text())
        self.assertEqual(config['notebook_dir'], str(self.notebook))
        result = subprocess.run([str(REPO / 'dotfiles'), 'apply'], env=environment, check=True, capture_output=True, text=True)
        self.assertIn('Already consistent', result.stdout)
        backup = next((self.state / 'backups').iterdir())
        refused = subprocess.run([str(REPO / 'dotfiles'), 'rollback', backup.name, '--dry-run'], env=environment, capture_output=True)
        self.assertNotEqual(refused.returncode, 0)
        self.assertTrue((self.home / '.zshrc').is_symlink())


if __name__ == '__main__':
    unittest.main()
