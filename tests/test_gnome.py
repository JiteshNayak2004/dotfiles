"""Exercise settings using a private D-Bus session and temporary dconf database."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest


@unittest.skipUnless(shutil.which('dbus-run-session') and shutil.which('dconf') and shutil.which('gnome-shell'), 'GNOME tools required')
class GnomeIntegrationTests(unittest.TestCase):
    def test_apply_twice_and_restore_isolated_settings(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles gnome user's ") as directory:
            home = Path(directory)
            environment = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'), XDG_DATA_HOME=str(home / '.local/share'), XDG_STATE_HOME=str(home / '.local/state'), XDG_CURRENT_DESKTOP='GNOME')
            script = textwrap.dedent('''
                import contextlib, io, json, shlex, sys
                from gi.repository import GLib
                sys.path.insert(0, sys.argv[1])
                from test_setup import setup
                actual_output = setup.output
                installed = [item['uuid'] for item in json.loads((setup.REPO / 'gnome/extensions.json').read_text())['extensions'] if item['enabled']]
                def output(*args):
                    if args == ('gnome-extensions', 'list'):
                        return '\\n'.join(installed)
                    return actual_output(*args)
                setup.output = output
                notebook = setup.HOME / 'Notebook'
                notebook.mkdir()
                config = {'components': ['gnome'], 'notebook_dir': str(notebook)}
                key = '/org/gnome/desktop/wm/preferences/num-workspaces'
                assert actual_output('dconf', 'read', key) == ''
                with contextlib.redirect_stdout(io.StringIO()):
                    setup.apply(config)
                    assert setup.gnome_plan(config) == []
                    assert actual_output('dconf', 'read', key) == '9'
                    value = actual_output('dconf', 'read', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/command')
                    command = GLib.Variant.parse(None, value, None, None).unpack()
                    assert shlex.split(command)[0] == str(setup.HOME / '.local/bin/rofi-powermenu')
                    setup.restore(next((setup.STATE / 'backups').iterdir()))
                assert actual_output('dconf', 'read', key) == ''
            ''')
            result = subprocess.run(['dbus-run-session', '--', sys.executable, '-c', script, str(Path(__file__).parent)], env=environment, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
