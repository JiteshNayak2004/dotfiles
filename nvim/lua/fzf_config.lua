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
-- Function to fuzzy search from a custom list of files
local function fuzzy_open_files()
  local files = {
    "~/.config/nvim/init.lua",
    "~/.config/kitty/kitty.conf",
    "~/.tmux.conf",
    "~/.zshrc",
    "~/.Todo.txt"
  }

  vim.fn["fzf#run"]({
    source = files,
    sink = function(selected)
      vim.cmd("edit " .. selected)
    end,
    options = vim.g.fzf_default_opts .. " --prompt='Files> '",
    down = vim.g.fzf_layout.down
  })
end


-- Map <leader>b to run the function in normal mode
vim.keymap.set('n', '<leader>b', fuzzy_open_files, { noremap = true, silent = true })

local fzf_opts = { options = vim.g.fzf_default_opts }

-- Create consistent minimal FZF commands
local fzf_remaps = {
  Files    = function() vim.fn["fzf#vim#files"]("", fzf_opts, 0) end,
  Rg       = function() vim.fn["fzf#vim#grep"]("", 1, fzf_opts, 0) end,
  Buffers  = function() vim.fn["fzf#vim#buffers"](fzf_opts, 0) end,
  Lines    = function() vim.fn["fzf#vim#lines"](fzf_opts, 0) end,
  BLines   = function() vim.fn["fzf#vim#blines"](fzf_opts, 0) end,
  Tags     = function() vim.fn["fzf#vim#tags"]("", fzf_opts, 0) end,
  BTags    = function() vim.fn["fzf#vim#btags"](fzf_opts, 0) end,
  Marks    = function() vim.fn["fzf#vim#marks"](fzf_opts, 0) end,
  Windows  = function() vim.fn["fzf#vim#windows"](fzf_opts, 0) end,
  History  = function() vim.fn["fzf#vim#command_history"](fzf_opts, 0) end,
  Commands = function() vim.fn["fzf#vim#commands"](fzf_opts, 0) end,
  Maps     = function() vim.fn["fzf#vim#maps"](fzf_opts, 0) end,
}

-- Register them as user commands
for name, fn in pairs(fzf_remaps) do
  vim.api.nvim_create_user_command(name, fn, {})
end

-- Redefine :Files with custom layout & style
vim.api.nvim_create_user_command("Files", function()
  vim.fn["fzf#vim#files"](
    "",
    { options = vim.g.fzf_default_opts },
    0
  )
end, {})

-- Redefine :Rg with custom layout & style
vim.api.nvim_create_user_command("Rg", function()
  vim.fn["fzf#vim#grep"](
    "",
    1,
    { options = vim.g.fzf_default_opts },
    0
  )
end, {})


