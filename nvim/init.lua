-- ╭────────────────────────────────────────────────────────────────────────────╮
-- │                          LEADER AND KEYBINDINGS                            │
-- ╰────────────────────────────────────────────────────────────────────────────╯
vim.g.mapleader = ' '

-- Basic mappings
vim.keymap.set('n', '<leader>w', ':w<cr>', { noremap = true })
vim.keymap.set('n', '<leader>q', ':q<cr>', { noremap = true }) -- Suspend to background
vim.keymap.set('n', '<leader>e', ':e ', { noremap = true })
vim.keymap.set('n', '<leader>s', ':! ', { noremap = true })
vim.keymap.set('n', '<M-p>', ':FzfLua<CR>', { noremap = true })
vim.keymap.set('n', '<leader>t', '<C-6>', { noremap = true })
vim.keymap.set('n', '<C-t>', ':tabnew .<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true, silent = true, desc = 'Select All' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>cd', ':lcd %:h<CR>', { noremap = true })

-- Window movement
vim.keymap.set('n', '<leader>h', '<C-w>h', { noremap = true })
vim.keymap.set('n', '<leader>j', '<C-w>j', { noremap = true })
vim.keymap.set('n', '<leader>k', '<C-w>k', { noremap = true })
vim.keymap.set('n', '<leader>l', '<C-w>l', { noremap = true })

-- FZF Mappings
vim.api.nvim_set_keymap('n', '<C-p>', ':FuzzyOpen<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>g', ':FzfLua live_grep_native<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>o', ':FzfLua lsp_document_symbols<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':FzfLua buffers<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-h>', ':FzfLua command_history<CR>', { noremap = true, silent = true })

-- ╭────────────────────────────────────────────────────────────────────────────╮
-- │                                 PLUGINS                                    │
-- ╰────────────────────────────────────────────────────────────────────────────╯
require('paq') {
  'savq/paq-nvim';
  'ishan9299/modus-theme-vim';
  'sainnhe/gruvbox-material';
  'rebelot/kanagawa.nvim';
  'windwp/nvim-autopairs';
  'FabijanZulj/blame.nvim';
  'sindrets/diffview.nvim';
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' };
  'junegunn/fzf';
  'ibhagwan/fzf-lua';
  -- 'NeogitOrg/neogit';
  'rbong/vim-flog';
  'neovim/nvim-lspconfig';
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-buffer';
  'hrsh7th/cmp-path';
  'hrsh7th/cmp-cmdline';
  'hrsh7th/cmp-vsnip';
  'hrsh7th/vim-vsnip';
  'tpope/vim-fugitive';
  'nvim-lua/plenary.nvim';
  -- 'justinmk/vim-dirvish';
  -- 'roginfarrer/vim-dirvish-dovish';
  'mtikekar/vim-bsv';
  'preservim/nerdtree';
  'lukas-reineke/indent-blankline.nvim';
  'projekt0n/github-nvim-theme';
  'cloudhead/neovim-fuzzy';
}


-- Plugin Configurations
require('fzf-lua').setup({
  -- Disable previewer for buffers
  buffers = {
    previewer = false
  },
})
require('nvim-autopairs').setup()
require('blame').setup({})
require('nvim-treesitter.configs').setup({ highlight = { enable = true } })
require("ibl").setup()
vim.keymap.set('n', '-', ':NERDTreeToggle<CR>', { noremap = true, desc = 'Toggle Neo-tree' })
vim.g.NERDTreeMinimalUI = 1
vim.g.NERDTreeWinSize = 35
vim.g.NERDTreeUseTCD = 1

-- Neogit setup
-- require('neogit').setup({
--   disable_hint = true,
--   disable_insert_on_commit = true,
--   disable_commit_confirmation = true,
--   kind = 'split',
--   graph_style = 'unicode',
--   auto_refresh = true,
--   disable_context_highlighting = true,
--   signs = { section = { "", "" }, item = { "", "" }, hunk = { "", "" } },
--   integrations = { diffview = true },
--   mappings = { status = { ["q"] = "Close" } },
-- })

-- ╭────────────────────────────────────────────────────────────────────────────╮
-- │                                 THEMES                                     │
-- ╰────────────────────────────────────────────────────────────────────────────╯
local override = require('github-theme.override')
local pure_black = '#000000'
override.groups = {
  all = {
    Normal = { bg = pure_black },
    NormalNC = { bg = pure_black },
    EndOfBuffer = { fg = pure_black },
    StatusLine = { fg = "#e6edf3", bg = "#333333", style = "" },
    StatusLineNC = { fg = "#8b949e", bg = "#161b22", style = "" },
  },
}
require('github-theme').setup({ override = override })
vim.cmd('colorscheme github_dark')

-- Uncomment to switch theme:
-- vim.cmd('colorscheme modus-vivendi')
-- require('kanagawa').setup({ transparent = true, colors = { theme = { all = { ui = { bg_gutter = "none" } } } } })
-- vim.cmd [[colorscheme kanagawa]]
-- vim.cmd [[colorscheme gruvbox-material]]

-- ╭────────────────────────────────────────────────────────────────────────────╮
-- │                           CUSTOM FZF PICKERS                               │
-- ╰────────────────────────────────────────────────────────────────────────────╯
local dotfiles = {
  "~/.config/nvim/init.lua",
  "~/.config/nvim/lua/fzf_config.lua",
  "~/.config/nvim/lua/lsp.lua",
  "~/.config/kitty/kitty.conf",
  "~/.tmux.conf",
  "~/.zshrc",
  "~/.Todo.txt",
}

local function open_dotfiles()
  require('fzf-lua').fzf_exec(dotfiles, {
    prompt = 'Dotfiles> ',
    previewer = false,
    actions = {
      ['default'] = function(selected)
        vim.cmd('edit ' .. vim.fn.expand(selected[1]))
      end
    },
  })
end
vim.keymap.set('n', '<M-b>', open_dotfiles, { desc = 'FZF: Open dotfiles' })

-- ╭────────────────────────────────────────────────────────────────────────────╮
-- │                                SETTINGS                                   │
-- ╰────────────────────────────────────────────────────────────────────────────╯
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.title = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.laststatus = 2
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.o.clipboard = "unnamedplus"

-- netrw settings
vim.g.netrw_liststyle = 0
vim.g.netrw_keepdir = 0
vim.g.netrw_banner = 0
vim.g.netrw_fastbrowse = 0

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Strip whitespace command
vim.api.nvim_create_user_command('Stripws', function()
  -- remove trailing whitespace first
  vim.cmd([[%s/\s\+$//e]])
end, { desc = 'Strip trailing whitespace and remove empty/whitespace-only lines' })

-- Highlight trailing whitespace
vim.cmd [[highlight ExtraWhitespace ctermbg=grey guibg=grey]]
vim.cmd [[match ExtraWhitespace /\s\+$/]]

-- LSP initialization (placed at end to ensure preferences are loaded)
require('lsp')
