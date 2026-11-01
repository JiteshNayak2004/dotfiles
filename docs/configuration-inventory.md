# Captured configuration inventory

This is the missing-config capture stage, using Ubuntu 24.04 and GNOME Shell 46
as the reference. The capture snapshots now feed the repository-local `dotfiles` installer. See
[the setup guide](../README.md) for supported platforms, apply/update commands,
and rollback. Capture itself did not modify desktop or browser preferences.

## File destinations

Destinations below are relative to the target user's home unless stated otherwise.
Back up existing destinations before eventually installing these files.

| Repository source | Destination | Notes |
| --- | --- | --- |
| `.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt configuration |
| `scripts/rofi-double-ctrl` | `~/.local/bin/rofi-double-ctrl` | X11 only; Python 3, libX11, libXi, Rofi |
| `scripts/rofi-powermenu` | `~/.local/bin/rofi-powermenu` | Current live launcher; separate from `rofi/powermenu.sh` |
| `scripts/hardware/lg-input` | `~/.local/bin/lg-input` | Optional LG DDC helper; needs ddcutil, i2c-tools and device permissions |
| `autostart/rofi-double-ctrl.desktop` | `~/.config/autostart/rofi-double-ctrl.desktop` | Snapshot contains reference-machine Exec path; installer renders the target user path |
| `doom/{init,config,packages}.el` | `~/.config/doom/` | Requires Doom Emacs and its package setup |
| `code/settings.json` | `~/.config/Code/User/settings.json` | Existing bindings remain in `code_keybinds.json` |
| `code/extensions.txt` | No direct file destination | Unique installed extension IDs; versions are not pinned |
| `zed/settings.json` | `~/.config/zed/settings.json` | Shared preferences; installer preserves local SSH connections/project paths |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` | Editor preference |
| `git/config` | Include from `~/.gitconfig` | Diff preferences only; excludes user identity and credentials |
| `git/ignore` | `~/.config/git/ignore` | Global ignore rules |
| `qutebrowser/config.py` | `~/.config/qutebrowser/config.py` | Actual live config; generated autoconfig is not loaded by it and was excluded |
| `gtk-3.0/settings.ini` | `~/.config/gtk-3.0/settings.ini` | File-based GTK theme/font settings |
| `gnome/pop-shell/config.json` | `~/.config/pop-shell/config.json` | Optional Pop Shell rules; does not install/enable the extension |
| `firefox/user.js` | `<selected Firefox profile>/user.js` | Curated explicit preference overrides |
| `firefox/chrome/userChrome.css` | `<selected Firefox profile>/chrome/userChrome.css` | Active profile CSS; hides horizontal tabs |
| `firefox/extensions.json` | No direct file destination | User add-on inventory, not Firefox's internal extensions database |

The font referenced by Kitty is `JetBrainsMono NF Bold`; the current machine has
JetBrains Nerd Font files under `~/.local/share/fonts/JetbrainNerdFont`. Font
binaries are not vendored. Shared shell/plugin dependency revisions are recorded
in `shell/dependencies.json`; the installer uses these revisions when bootstrapping dependencies.

## GNOME settings

These are selected, readable dconf snapshots. They capture explicit overrides,
except `shell.dconf`, which also records effective Shell keybinding values.
Defaults may differ on other GNOME versions. Missing schemas and incompatible
extensions are checked or reported by the installer before settings are applied.
Do not restore the entire tree blindly on a different machine.

| Snapshot | dconf destination subtree |
| --- | --- |
| `gnome/wm.dconf` | `/org/gnome/desktop/wm/` |
| `gnome/mutter.dconf` | `/org/gnome/mutter/` |
| `gnome/media-keys.dconf` | `/org/gnome/settings-daemon/plugins/media-keys/` |
| `gnome/interface.dconf` | `/org/gnome/desktop/interface/` |
| `gnome/input-sources.dconf` | `/org/gnome/desktop/input-sources/` |
| `gnome/peripherals.dconf` | `/org/gnome/desktop/peripherals/` |
| `gnome/extensions.dconf` | `/org/gnome/shell/extensions/` |
| `gnome/shell.dconf` | `/org/gnome/shell/` |

`gnome/extensions.json` records installed UUIDs, versions when available, declared
GNOME compatibility, installation origin, and the enabled-list membership.
Enabled-list membership does not prove an extension is running successfully.
Extension binaries are not vendored; compatible releases must be installed.
ArcMenu's recent-app list/UI state/version notifier and Tiling Assistant's version
marker were excluded. Historical Pop Shell settings are retained even though the
extension is not in the enabled list.

Machine-specific or installation-dependent settings requiring special handling:

- `media-keys.dconf`: LG monitor shortcut and absolute helper paths.
- `peripherals.dconf`: reference mouse/touchpad preferences and keyboard state.
- `mutter.dconf`: experimental scaling feature selection.
- Auto Move Windows and Shell favorites: app IDs differ between Snap/native apps.
- GNOME theme/icon selections differ from the captured GTK 3 file. Both sources
  were preserved as found, without choosing a replacement.

## Firefox capture boundaries

The active-looking Snap profile was verified to contain the six captured user
add-ons and the selected CSS. A separate regular Firefox profile tree also exists;
setup detects profiles and asks which one to manage. The CSS
outside the Snap profile directory is not active profile CSS and was excluded.

Captured: user add-on IDs/observed versions, tab-hiding CSS, and an allowlist of
appearance/sidebar/tab preferences. Built-in Firefox add-ons were excluded.
The recorded add-on versions describe this machine; they are not install pins.
`user.js` overrides preferences at startup; it must be merged with any existing
user.js rather than blindly discarding unrelated preferences. Install/configure
Sidebery before using the CSS if you need a visible tab interface.

Still requires an extension-specific export and review before adding:

- Vimium custom mappings, search engines, and exclusion rules.
- Sidebery settings, panel configuration, custom styles, and shortcuts.
- Tampermonkey user scripts and settings; inspect scripts for credentials/private URLs.
- uBlock Origin custom filters/settings and Dark Reader custom settings.
- Firefox add-on shortcut customizations, if any.

Do not put full profile databases, prefs.js, cookies, logins, history, tabs, account
identifiers, extension storage databases, or unreviewed backup bundles in Git.
Private extension exports can be kept in ignored `firefox/private-exports/` until
reviewed. This directory is not a synchronization or backup mechanism.

## Remaining manual/installation-specific work

- Run the installer on the target machine, supplying its Notebook/profile paths.
- Install optional GUI applications and proprietary EDA tools using their installers.
- Review/export extension-specific Firefox settings listed above.
- Adjust Auto Move Windows and favorite app IDs if application packaging changes.
- `focus@scaryrawr.github.io` was absent during capture; dependency setup attempts
  a compatible download and reports availability rather than assuming it exists.
- Notebook contents, task files, licenses, and personal browser data remain outside Git.
- `~/scripts/llm.py` was absent on the source machine; its existing alias still
  requires that separately supplied script. `config_update` now uses the installer.
