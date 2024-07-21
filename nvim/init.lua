-- Set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = false

-- Configuration options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus' -- Sync clipboard
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Basic Keymaps

vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev) -- Go to previous diagnostic message
vim.keymap.set('n', ']d', vim.diagnostic.goto_next) -- Go to next diagnostic message
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float) -- Show diagnostic error messages
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist) -- Open diagnostic quickfix list

-- File tree with leader+e shortcut
vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>:Neotree float<CR>', {})
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>') -- Exit terminal mode

-- Easier split navigation with CTRL+<hjkl>
vim.keymap.set('n', '<C-h>', '<C-w><C-h>') -- Move focus left window
vim.keymap.set('n', '<C-l>', '<C-w><C-l>') -- Move focus right window
vim.keymap.set('n', '<C-j>', '<C-w><C-j>') -- Move focus lower window
vim.keymap.set('n', '<C-k>', '<C-w><C-k>') -- Move focus upper window

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Install lazy.nvim plugin manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end
vim.opt.rtp:prepend(lazypath)

-- Configure and install plugins
-- all plugins are returned by plugins.lua file
require('lazy').setup 'plugins'

-- Customizations
-- Relative line numbers as white
function LineNumberColors()
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#FFFFFF' })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#FFFFFF' })
end

LineNumberColors()

-- Comments with green color
vim.api.nvim_set_hl(0, 'Comment', { fg = '#ACEE2A' })
vim.api.nvim_set_hl(0, '@comment', { link = 'Comment' })
