# dotfiles
collection of all my dotfiles to replicate setup 

gnome extensions i use actively
1. arcmenu
2. focus changer
3. improved workspace indicator
4. no overview at startup
5. remove alt+tab delay v2
6. awesome tiles
7. auto move windows
8. focus
9. go to last workspace
10. switcher
11. wintile


## Live configuration links

The active configs on this machine are symlinked to these repository files:

| Active path | Repository file |
| --- | --- |
| `~/.zshrc` | `backup_zshrc` |
| `~/.tmux.conf` | `.tmux.conf` |
| `~/.config/kitty/kitty.conf` | `kitty/kitty.conf` |
| `~/.config/nvim/init.lua` | `nvim/init.lua` |
| `~/.config/nvim/lua/lsp.lua` | `nvim/lua/lsp.lua` |
| `~/.config/Code/User/keybindings.json` | `code_keybinds.json` |

Edits through either path update the tracked file. Review with `git diff`, then
commit and push as usual. If an application replaces a symlink when saving,
restore that link before making further edits. Neovim session files are not linked.

Original live files are backed up under
`~/.local/state/dotfiles-backups/20261018-223633-676643/`.
The repository versions before importing live configs are preserved in commit
`cc2a0f7`. These links are local to this machine; cloning the repo does not create them.

Machine-local license keys are loaded from `~/.config/zsh/dotfiles-secrets.zsh`
and are not stored in this repository.
