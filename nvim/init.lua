-- ╭────────────────────────────────────────────────────────────────────────────╮
-- │                          LEADER AND KEYBINDINGS                            │
-- ╰────────────────────────────────────────────────────────────────────────────╯
vim.g.mapleader = ' '

-- Basic mappings
vim.keymap.set('n', '<leader>w', ':w<cr>', { noremap = true })
vim.keymap.set('n', '<leader>q', ':q<cr>', { noremap = true }) -- Suspend to background
vim.keymap.set('n', '<leader>e', ':e ', { noremap = true })
vim.keymap.set('n', '<leader>s', ':! ', { noremap = true })
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
-- g synonym for grep 
vim.api.nvim_set_keymap('n', '<leader>g', ':FzfLua live_grep_native<CR>', { noremap = true, silent = true })
-- o synonym for objects 
vim.api.nvim_set_keymap('n', '<leader>o', ':FzfLua lsp_document_symbols<CR>', { noremap = true, silent = true })
-- wo synonym for workspace objects 
vim.api.nvim_set_keymap('n', '<leader>O', ':FzfLua lsp_live_workspace_symbols<CR>', { noremap = true, silent = true })
-- wo synonym for recent search
vim.api.nvim_set_keymap('n', '<C-s>', ':FzfLua search_history<CR>', { noremap = true, silent = true })
-- wo synonym for recent history
vim.api.nvim_set_keymap('n', '<C-h>', ':FzfLua command_history<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', ':FzfLua buffers<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-h>', ':FzfLua<CR>', { noremap = true })
vim.keymap.set('n', '<M-p>', ':FzfLua oldfiles<CR>', { noremap = true })
vim.keymap.set('n', '<M-d>', ':FzfLua zoxide<CR>', { noremap = true })
-- Cycle to the next tab (Meta + j)
vim.keymap.set('n', '<M-j>', ':tabnext<CR>', { noremap = true, silent = true, desc = 'Next Tab' })

-- Cycle to the previous tab (Meta + k)
vim.keymap.set('n', '<M-k>', ':tabprevious<CR>', { noremap = true, silent = true, desc = 'Previous Tab' })


-- Map <leader>1 .. <leader>9 to tab switching
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, i .. "gt", {
    noremap = true,
    silent = true,
    desc = "Go to tab " .. i,
  })
end
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
  'NeogitOrg/neogit';
  { 'iamcco/markdown-preview.nvim', build = 'npx --yes yarn@1.22.22 --cwd app install --frozen-lockfile' };
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
local actions = require("fzf-lua.actions")

require('fzf-lua').setup({
  -- Disable previewer for buffers
  buffers = {
    previewer = false
  },

  actions = {
    files = {
      true,
      ["ctrl-q"] = actions.file_sel_to_qf,
    },
    grep = {
      ["ctrl-q"] = actions.file_sel_to_qf,
    },
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
  "~/.scratchpad.txt",

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

local session_dir = vim.fn.stdpath("config") .. "/sessions"
local active_session

local function session_name(name)
  name = vim.trim(name or "")
  if name == "" or not name:match("^[%w._-]+$") then
    vim.notify("Session names may contain only letters, numbers, dot, dash, and underscore", vim.log.levels.ERROR)
    return nil
  end
  return name
end

local function session_path(name)
  name = session_name(name)
  return name and (session_dir .. "/" .. name .. ".vim") or nil
end

local function session_names()
  local names = {}
  for _, path in ipairs(vim.fn.globpath(session_dir, "*.vim", false, true)) do
    names[#names + 1] = vim.fn.fnamemodify(path, ":t:r")
  end
  table.sort(names)
  return names
end

local function has_modified_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].modified then return true end
  end
  return false
end

local function save_session(name)
  local path = session_path(name)
  if not path then return false end
  vim.fn.mkdir(session_dir, "p")
  vim.cmd("mksession! " .. vim.fn.fnameescape(path))
  active_session = name
  vim.notify("Saved session: " .. name)
  return true
end

local function load_session(name)
  if has_modified_buffers() then
    vim.notify("Save or discard modified buffers before loading a session", vim.log.levels.WARN)
    return false
  end
  local path = session_path(name)
  if not path or vim.fn.filereadable(path) == 0 then return false end
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
  if not ok then
    local message = tostring(err):match("^[^\n]+") or "unknown error"
    vim.notify("Failed to load session " .. name .. ": " .. message, vim.log.levels.ERROR)
    return false
  end
  return true
end

local function prompt_new_session()
  local default_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t"):gsub("[^%w._-]", "-")
  vim.ui.input({ prompt = "Session name: ", default = default_name }, function(name)
    if name then save_session(name) end
  end)
end

local open_sessions
open_sessions = function()
  require("fzf-lua").fzf_exec(session_names(), {
    prompt = "Sessions> ",
    previewer = false,
    fzf_opts = {
      ["--header"] = "Enter: load  Ctrl-n: new  Ctrl-x: delete",
    },
    actions = {
      ["enter"] = function(selected)
        if selected[1] then load_session(selected[1]) end
      end,
      ["ctrl-n"] = function()
        vim.schedule(prompt_new_session)
      end,
      ["ctrl-x"] = function(selected)
        local name = selected[1]
        local path = name and session_path(name)
        if not path then return end
        local choices = table.concat({ "&Delete", "&Cancel" }, string.char(10))
        if vim.fn.confirm("Delete session " .. name .. "?", choices, 2) == 1 then
          vim.fn.delete(path)
          if active_session == name then active_session = nil end
          vim.schedule(open_sessions)
        end
      end,
    },
  })
end

vim.api.nvim_create_autocmd("SessionLoadPost", {
  callback = function()
    local path = vim.fs.normalize(vim.v.this_session)
    if vim.fn.fnamemodify(path, ":h") == vim.fs.normalize(session_dir) then
      active_session = vim.fn.fnamemodify(path, ":t:r")
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if not active_session then return end
    local path = session_path(active_session)
    if path then vim.cmd("mksession! " .. vim.fn.fnameescape(path)) end
  end,
})

vim.opt.sessionoptions:remove({ "blank", "help", "terminal" })
vim.api.nvim_create_user_command("Sessions", open_sessions, { desc = "Manage Neovim sessions" })

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

-- :rough - open/create rough note for today
vim.api.nvim_create_user_command('Rough', function(opts)
  local note_dir = '/home/jitesh/Desktop/Notebook/ROUGH'
  local date = os.date('%Y-%m-%d')
  local base_name = 'ROUGH_' .. date
  local pattern = base_name .. '*.md'

  -- Find existing files for today
  local files = vim.fn.glob(note_dir .. '/' .. pattern, false, true)
  local existing_count = #files

  -- Determine next index
  local index = 1
  if existing_count > 0 then
    local max_index = 0
    for _, f in ipairs(files) do
      local name = vim.fn.fnamemodify(f, ':t:r')
      local idx = name:match(base_name .. '_(%d+)$')
      if idx then
        local n = tonumber(idx)
        if n > max_index then max_index = n end
      else
        -- File without index (e.g., ROUGH_YYYY-MM-DD.md), treat as index 0
        -- so next file will be _1.md
        max_index = math.max(max_index, 0)
      end
    end
    index = max_index + 1
  end

  local filename
  if opts.args == 'new' then
    if existing_count == 0 then
      filename = note_dir .. '/' .. base_name .. '.md'
    else
      filename = note_dir .. '/' .. base_name .. '_' .. index .. '.md'
    end
  else
    -- :rough - open existing, or create if none
    if existing_count == 0 then
      filename = note_dir .. '/' .. base_name .. '.md'
      vim.loop.fs_write(vim.loop.fs_open(filename, 'w', 438), '', 0)
    else
      -- If the latest file (index-1) doesn't exist, create it;
      -- otherwise open the latest existing file
      local candidate_index = index - 1
      if candidate_index >= 1 then
        latest_file = note_dir .. '/' .. base_name .. '_' .. candidate_index .. '.md'
      else
        latest_file = note_dir .. '/' .. base_name .. '.md'
      end
      -- If the candidate file doesn't exist, use index (create new indexed file)
      if vim.loop.fs_stat(latest_file) == nil then
        -- Candidate doesn't exist, so create new file with current index
        filename = note_dir .. '/' .. base_name .. '_' .. index .. '.md'
      else
        -- Candidate exists, open it
        filename = latest_file
      end
    end
  end

  vim.cmd('edit ' .. filename)
end, { nargs = '?', complete = function() return { 'new' } end, desc = 'Open/create rough note for today' })

-- :rough new - create new rough note
vim.api.nvim_create_user_command('RoughNew', function()
  vim.cmd('Rough new')
end, { desc = 'Create a new rough note for today' })

local notes_dir = '/home/jitesh/Desktop/Notebook'

-- :note - Fuzzy find files or directories depending on whether an argument is provided
vim.api.nvim_create_user_command('Note', function(opts)
  local arg = opts.args and vim.trim(opts.args) or ''

  if arg == '' then
    -- CASE 1: No arguments provided -> Fuzzy find ALL FILES in Notebook (any depth)
    local items = vim.fn.systemlist(string.format('find %s -type f 2>/dev/null', vim.fn.shellescape(notes_dir)))

    require('fzf-lua').fzf_exec(items, {
      prompt = 'Notes (Files)> ',
      previewer = true,
      actions = {
        ['default'] = function(selected)
          if #selected > 0 then
            local file_path = vim.fn.substitute(selected[1], '^%s*', '', '')
            vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
          end
        end,
      },
    })
  else
    -- CASE 2: Filename provided -> Fuzzy find ALL DIRECTORIES in Notebook (any depth)
    local items = vim.fn.systemlist(string.format('find %s -type d 2>/dev/null', vim.fn.shellescape(notes_dir)))

    require('fzf-lua').fzf_exec(items, {
      prompt = 'Notes (Dirs for "' .. arg .. '")> ',
      previewer = false,
      actions = {
        ['default'] = function(selected)
          if #selected > 0 then
            local selected_dir = vim.fn.substitute(selected[1], '^%s*', '', ''):gsub('/$', '')
            local full_path = selected_dir .. '/' .. arg
            vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
          end
        end,
      },
    })
  end
end, { nargs = '?', complete = 'file', desc = 'Fuzzy find notebook files or directories to create/open notes' })

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


