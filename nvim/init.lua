vim.g.mapleader = ' '
vim.keymap.set('n', [[<leader>w]], [[:w<cr>]], {noremap=true})
vim.keymap.set('n', [[<leader>q]], [[<C-z>]], {noremap=true}) -- Suspend to background
vim.keymap.set('n', [[<leader>h]], [[<c-w>h]], {noremap=true})
vim.keymap.set('n', [[<leader>j]], [[<c-w>j]], {noremap=true})
vim.keymap.set('n', [[<leader>k]], [[<c-w>k]], {noremap=true})
vim.keymap.set('n', [[<leader>l]], [[<c-w>l]], {noremap=true})
vim.keymap.set('n', [[<leader>e]], [[:e ]], {noremap=true})
vim.keymap.set('n', [[<leader>s]], [[:! ]], {noremap=true})
vim.keymap.set('n', [[<leader>cd]], [[:lcd %:h<CR> ]], {noremap=true})
vim.keymap.set('n', [[<leader>t]], [[<C-6>]], {noremap=true})
vim.keymap.set('n', '<leader>m', ':Marks<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>f', ':Buffers<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-t>', ':tabnew .<CR>', { noremap = true, silent = true })

-- switching in and out of terminal
--vim.keymap.set("n", "<M-j>", "<C-z>", { noremap = true, silent = true })

vim.keymap.set("n", "<M-h>", ":sp .<CR>", { noremap = true, silent = true }) -- Horizontal split
vim.keymap.set("n", "<M-v>", ":vsp .<CR>", { noremap = true, silent = true }) -- Vertical split



-- Map <leader>f to fuzzy-search
vim.api.nvim_set_keymap('n', '<C-f>', ':Files<CR>', { noremap = true, silent = true })
-- Map <leader>g to fuzzy-grep
vim.api.nvim_set_keymap('n', '<leader>g', ':Rg<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-u>', '<C-u>zz', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<M-d>', '<C-d>zz', { noremap = true, silent = true })


vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')


require('paq') {
    'savq/paq-nvim';
    --'rebelot/kanagawa.nvim';
  'ishan9299/modus-theme-vim';
    'sainnhe/gruvbox-material';
    'rebelot/kanagawa.nvim';
    'windwp/nvim-autopairs';
    'FabijanZulj/blame.nvim';
    'sindrets/diffview.nvim';
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
    'junegunn/fzf.vim';
    'NeogitOrg/neogit';
    -- plenary and flog needed for neogit
    'rbong/vim-flog';
    'nvim-lua/plenary.nvim';
    'junegunn/fzf';
    'neovim/nvim-lspconfig';
    'hrsh7th/cmp-nvim-lsp';
    'hrsh7th/cmp-buffer';
    'hrsh7th/cmp-path';
    'hrsh7th/cmp-cmdline';
    'hrsh7th/nvim-cmp';
    'hrsh7th/cmp-vsnip';
    'hrsh7th/vim-vsnip';
    'tpope/vim-fugitive';
    -- below two plugins help in navigating directories
    'justinmk/vim-dirvish';
    -- dovish dependency trash <to delete files/folders>
    'roginfarrer/vim-dirvish-dovish';
    'lukas-reineke/indent-blankline.nvim';
}
--MODUS <HIGH BACKGROUND AND FOREGROUND CONSTRAST>
vim.cmd('colorscheme modus-vivendi') -- Dark
-- or
--vim.cmd('colorscheme modus-operandi') -- Light
-- or
-- require('kanagawa').setup({
--     transparent = true,
--     colors = {theme={all={ui={bg_gutter="none"}}}}
-- })
-- vim.cmd [[colorscheme kanagawa]]

--GRUVBOX<AESTHETIC>
-- vim.cmd [[set termguicolors]]
-- vim.g.gruvbox_material_better_performance = true
-- vim.g.gruvbox_material_enable_italic = true
-- vim.g.gruvbox_material_enable_bold = true
-- vim.g.gruvbox_material_background = 'hard'
-- vim.g.gruvbox_material_foreground = 'material'
-- vim.g.gruvbox_material_dim_inactive_windows = 0
-- vim.g.gruvbox_material_menu_selection_background = 'green'
-- vim.g.gruvbox_material_ui_contrast = 'high'
-- vim.g.gruvbox_material_transparent_background = 2
-- vim.cmd [[colorscheme gruvbox-material]]

require('nvim-autopairs').setup()
require('blame').setup({})
require('nvim-treesitter.configs').setup {
    highlight = {enable = true}
}
require('neogit').setup({
  disable_hint = true,  -- Disable hints for speed
  disable_insert_on_commit = True,  -- Keep commit behavior like Fugitive
  disable_commit_confirmation = true,
  kind = "split",
  graph_style = "unicode",
  auto_refresh=true,
  disable_context_highlighting = true,  -- Avoid unnecessary UI clutter
  signs = {
    section = { "", "" },  -- Remove section indicators
    item = { "", "" },  -- Remove item indicators
    hunk = { "", "" },  -- Remove hunk indicators
  },
  integrations = { diffview = true },  -- Keep Neogit simple
  mappings = { status = { ["q"] = "Close" } },  -- Allow quick quit like Fugitive
})
-- this if for indent lines for python files
require("ibl").setup()

vim.cmd [[highlight ExtraWhitespace ctermbg=grey guibg=grey]] -- highlight trailing whitespace
vim.cmd [[hi StatusLine ctermbg=Cyan ctermfg=Red]]
vim.cmd [[match ExtraWhitespace /\s\+$/]]
-- vim.cmd [[set cmdheight=0]]

--netrw  settings
-- use vim-dirvish to traverse thru file-history
-- use a for new file,A for new-dir,r for rename,dd for delete
-- advanced commands use :! command and then % to point to the
-- current buffer path and can then use tab to address the file
vim.g.netrw_liststyle = 0
vim.g.netrw_keepdir = 0
vim.g.netrw_banner = 0
vim.g.netrw_fastbrowse = 0

-- fzf settings
--vim.g.fzf_layout = { down = '40%' }
--vim.g.fzf_vim.preview_window = { "right,40%", "ctrl-/" }
-- search must be case insensitive
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.title = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
-- vim.opt.colorcolumn = '81'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.laststatus = 2
vim.opt.cursorline = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Customizations
-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  callback = function()
    vim.highlight.on_yank()
  end,
})
-- dotfiles access command
vim.cmd("command! Vimconf :e ~/.config/nvim/init.lua")
-- Todo access command
vim.cmd("command! Todo :e ~/.Todo.txt")
-- deleting whitespaces
vim.api.nvim_create_user_command('Stripws', function()
  vim.cmd('g/^[[:space:]]*$/d')
end, { desc = 'Remove empty and whitespace-only lines' })

-- -- LSP
--  local lspconfig = require('lspconfig')
--
-- -- Minimal on_attach function (removes unnecessary overhead)
-- local on_attach = function(client, bufnr)
--   local opts = { noremap=true, silent=true, buffer=bufnr }
--   -- Keybindings for LSP (Only essential ones)
--   vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
--   vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
-- end
--
-- -- Capabilities for better completion performance
-- local capabilities = require('cmp_nvim_lsp').default_capabilities()
--
-- -- Optimized Pyright (Python LSP)
-- lspconfig.pyright.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   settings = {
--     python = {
--       analysis = {
--         autoSearchPaths = true,
--         diagnosticMode = "openFilesOnly", -- Only analyze open files for performance
--         useLibraryCodeForTypes = false, -- Reduces processing for type inference
--       },
--     },
--   },
-- })
--
-- -- Optimized Clangd (C/C++ LSP)
-- lspconfig.clangd.setup({
--   cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed", "--header-insertion=never" },
--   on_attach = on_attach,
--   capabilities = capabilities,
--   init_options = {
--     clangdFileStatus = false,  -- Disables workspace symbol indexing for speed
--     fallbackFlags = { "-std=c++17" },
--   },
-- })
--
--
-- enable lsp at the end so i still get to use nvim with my preferences if lsp errors out on me
require('lsp')
require('fzf_config')
