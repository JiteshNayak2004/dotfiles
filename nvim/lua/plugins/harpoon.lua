return {
  'ThePrimeagen/harpoon',
  'nvim-lua/plenary.nvim',
  {
    'ThePrimeagen/harpoon',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('harpoon').setup {
        global_settings = {
          -- sets the marks upon calling `toggle` on the ui, instead of require `:w`.
          save_on_toggle = false,

          -- saves the harpoon file upon every change. disabling is unrecommended.
          save_on_change = true,

          -- sets harpoon to run the command immediately as it's passed to the terminal when calling `sendCommand`.
          enter_on_sendcmd = false,

          -- closes any tmux windows that harpoon creates when you close Neovim.
          tmux_autoclose_windows = false,

          -- filetypes that you want to prevent from adding to the harpoon list menu.
          excluded_filetypes = { 'harpoon' },

          -- set marks specific to each git branch inside git repository
          -- Each branch will have its own set of marked files
          mark_branch = true,

          -- enable tabline with harpoon marks
          tabline = false,
          tabline_prefix = '   ',
          tabline_suffix = '   ',
        },
      }

      -- Load Telescope extension for Harpoon
      require('telescope').load_extension 'harpoon'

      -- Key mappings for Harpoon
      vim.keymap.set('n', '<leader>hx', require('harpoon.mark').add_file, { desc = 'Mark file' })
      vim.keymap.set('n', '<leader>hn', require('harpoon.ui').nav_next, { desc = 'Navigate next' })
      vim.keymap.set('n', '<leader>hp', require('harpoon.ui').nav_prev, { desc = 'Navigate previous' })
      vim.keymap.set('n', '<leader>hm', ':Telescope harpoon marks<CR>', { desc = 'Show marks' })

      -- Which-key mappings for Harpoon
      require('which-key').register({
        h = {
          name = 'harpoon',
          x = { require('harpoon.mark').add_file, 'Mark file' },
          n = { require('harpoon.ui').nav_next, 'Next mark' },
          p = { require('harpoon.ui').nav_prev, 'Previous mark' },
        },
      }, { prefix = '<leader>' })
    end,
  },
}
