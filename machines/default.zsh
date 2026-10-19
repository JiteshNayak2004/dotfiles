# Machine-specific settings for the work machine. Used as the fallback when
# no machines/<hostname>.zsh matches, so an existing checkout keeps behaving
# exactly as before this split. No secrets here; credentials live in
# ~/.config/zsh/dotfiles-secrets.zsh (untracked, machine-local).

export PATH="$PATH:/home/jitesh/Desktop/incore/tools/riscv/bin"
export PATH="$PATH:~/.cargo/bin:$PATH"
export PATH="/home/jitesh/Downloads/surfer/surfer_linux:$PATH"
export PATH="$PATH:/opt/bsc/bin"
# export PATH="$PATH:/usr/bin/iverilog"
export PATH="$PATH:/home/jitesh/Desktop/incore/WORKSPACE/abc"

# export PATH="$PATH:/usr/bin/verilator"
# export PATH="$PATH:/usr/local/bin/ctags"
# export PATH="$PATH:/opt/nvim-linux64/bin"
# export PATH="$PATH:/home/jitesh/.local/bin"
export PATH="$PATH:/home/jitesh/Desktop/incore/fpga_software/Vivado/2024.2/bin"

export SG_LICENSE_PATH=/home/jitesh/Desktop/incore/dev_1.lic # including the dev.lic in the path


export NG_LICENSE_PATH=/home/jitesh/Desktop/incore/dev_1.lic

export VERIFIC_LICENSE_FILE=/home/jitesh/Desktop/incore/verific_251112.license

# Verific 2026-03-12 install
export VERIFIC_INSTALL_DIR="$HOME/.local/lib/verific"
export LD_LIBRARY_PATH="$VERIFIC_INSTALL_DIR:$LD_LIBRARY_PATH"
export PYTHONPATH="$VERIFIC_INSTALL_DIR:$PYTHONPATH"
export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libtcl8.6.so"
export SG_LICENSE_PATH="/home/jitesh/Desktop/incore/dev_1.lic"

# This machine builds venvs with python3.10
export VENV_PYTHON=python3.10

# GTKWave — disable GTK overlay scrollbars and software compositing to fix
# waveform scroll jitter (GTK3 redraws the entire widget on each scroll event
# when the compositing backend is active).
export GTK_OVERLAY_SCROLLING=0
export GDK_RENDERING=image
