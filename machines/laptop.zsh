# Machine-specific settings for "laptop". No secrets here; credentials live
# in ~/.config/zsh/dotfiles-secrets.zsh (untracked, machine-local).

export PATH="$PATH:/home/jitesh/riscv/bin"
# export PATH="$PATH:/home/jitesh/riscv_binaries/ubuntu-toolchain-az/riscv_toolchain_ubuntu/bin"
# export PATH="$PATH:/home/jitesh/Desktop/work/incore/misc/bsc/bsc_install/bin"
export PATH="$PATH:/home/jitesh/Desktop/work/incore/misc/incore_bsv/bsc/bsc-main/inst/bin"
export PATH="$PATH:/usr/bin/iverilog"
export PATH="$PATH:/home/jitesh/binaries"
export PATH="$PATH:/usr/bin/verilator"
export PATH="$PATH:/usr/local/bin/ctags"
export PATH="$PATH:/opt/nvim-linux64/bin"
export PATH="$PATH:/home/jitesh/.local/bin"
# Emacs 29.4 (local build, Doom prerequisite) takes precedence over system emacs 27
export PATH="/home/jitesh/.local/bin:$PATH"
# Doom Emacs CLI
export PATH="/home/jitesh/.config/emacs/bin:$PATH"
export PATH="$PATH:/home/jitesh/applications/MentorGraphics_QuestaSim/install/questasim/linux_x86_64"
export LM_LICENSE_FILE="/home/jitesh/applications/MentorGraphics_QuestaSim/install/license.dat"

# Enable developer mode
export DEVICE_MANAGER_DEV=1

# Nerd-font mode for Powerlevel10k
POWERLEVEL9K_MODE="nerdfont-complete"
