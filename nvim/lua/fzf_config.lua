-- make fzf-vim minimal
vim.g.fzf_layout = { down = '~40%' }  -- Adjust the height of the fzf window
vim.g.fzf_preview_window = ''         -- Disable preview window to keep things minimal
-- Disable floating window behavior
vim.g.fzf_action = {
  ['ctrl-t'] = 'tab split',  -- Customize actions as needed
  ['ctrl-v'] = 'vsplit',
  ['ctrl-h'] = 'split',
}
vim.g.fzf_default_opts = '--no-sort --height 30% --border'  -- Minimal style

