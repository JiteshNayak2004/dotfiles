# Portable defaults. Proprietary tools and license paths belong in local machine.json
# (path_dirs/env), or ~/.config/dotfiles/local.zsh for shell-specific customization.
typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)
export PATH
