# Captured configuration inventory

This is the missing-config capture stage, using Ubuntu 24.04 and GNOME Shell 46
as the reference. These additions are snapshots, not an installer. Existing live
symlinks are preserved; new files have not been linked or applied. No packages,
extensions, services, or browser preferences were changed during capture.

## File destinations

Destinations below are relative to the target user's home unless stated otherwise.
Back up existing destinations before eventually installing these files.

| Repository source | Destination | Notes |
| --- | --- | --- |
| `.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt configuration |
| `scripts/rofi-double-ctrl` | `~/.local/bin/rofi-double-ctrl` | X11 only; Python 3, libX11, libXi, Rofi |
| `scripts/rofi-powermenu` | `~/.local/bin/rofi-powermenu` | Current live launcher; separate from `rofi/powermenu.sh` |
| `scripts/hardware/lg-input` | `~/.local/bin/lg-input` | Optional LG DDC helper; needs ddcutil, i2c-tools and device permissions |
| `autostart/rofi-double-ctrl.desktop` | `~/.config/autostart/rofi-double-ctrl.desktop` | Snapshot contains reference-machine Exec path; render it at installation |
| `doom/{init,config,packages}.el` | `~/.config/doom/` | Requires Doom Emacs and its package setup |
| `code/settings.json` | `~/.config/Code/User/settings.json` | Existing bindings remain in `code_keybinds.json` |
| `code/extensions.txt` | No direct file destination | Unique installed extension IDs; versions are not pinned |
| `zed/settings.json` | `~/.config/zed/settings.json` | SSH connections/project paths omitted |
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
in `shell/dependencies.json`; this is an inventory, not a dependency installer.

## GNOME settings

These are selected, readable dconf snapshots. They capture explicit overrides,
except `shell.dconf`, which also records effective Shell keybinding values.
Defaults may differ on other GNOME versions. Missing schemas and incompatible
extensions must be handled by the future installer before settings are applied.
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
the future installer must detect profiles and ask which one to manage. The CSS
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

## Remaining portability work

- Build setup/update/backup/rollback tooling and a source-to-destination manifest.
- Prompt for Notebook and optional toolchain/license paths; store answers locally.
- Resolve hard-coded paths in current Zsh, tmux, Neovim, autostart, and GNOME commands.
- Install and verify shell, tmux, Neovim, editor, font, and extension dependencies.
- Account for GNOME versions, application IDs, and X11 versus Wayland.
- Resolve `focus@scaryrawr.github.io`: present in the enabled list but absent from
  the inspected user and system extension directories.
- Notebook contents, task files, proprietary tools, licenses, and browser personal
  data remain outside Git and need separate migration/synchronization.
- Vendor-generated proprietary application launchers and unrelated URL handlers
  were not copied; their installation paths must come from their installers.

The shell currently references missing `~/update.sh` and `~/scripts/llm.py` files;
there were no source files at those paths to capture.
