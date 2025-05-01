local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local cmp = require('cmp')

-- Enhanced on_attach function with all your keybindings
local on_attach = function(client, bufnr)
    local bufopts = {noremap=true, silent=true, buffer=bufnr}
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<leader>p', vim.lsp.buf.format, bufopts)
    -- vim.keymap.set("n", "<leader>o", function()
    --   local params = { textDocument = vim.lsp.util.make_text_document_params() }
    --   vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result, ctx, _)
    --     if err or not result then return end
    --
    --     local items = vim.lsp.util.symbols_to_items(result, 0) or {}
    --     local fzf_items = {}
    --
    --     for _, item in ipairs(items) do
    --       local kind = vim.lsp.protocol.SymbolKind[item.kind] or "?"
    --       local display = string.format("%s [%s]", item.text, kind)
    --       table.insert(fzf_items, { display = display, location = item })
    --     end
    --
    --     vim.fn['fzf#run']({
    --       source = vim.tbl_map(function(i) return i.display end, fzf_items),
    --       sink = function(selected)
    --         for _, entry in ipairs(fzf_items) do
    --           if entry.display == selected then
    --             local loc = entry.location
    --             vim.cmd("e " .. loc.filename)
    --             vim.fn.cursor(loc.lnum, loc.col)
    --             break
    --           end
    --         end
    --       end,
    --       options = "--prompt='Symbols> ' --ansi --reverse --border",
    --       window = {
    --         width = 1,
    --         height = 0.4,
    --         yoffset = 1.0,
    --         xoffset = 0.5,
    --         border = 'sharp',
    --       },
    --     })
    --   end)
    -- end, { desc = "Fuzzy LSP document symbols (clean) with fzf" })
    --
    -- vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, bufopts)

end

-- Helper functions for completion
local has_words_before = function()
    unpack = unpack or table.unpack
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

-- Completion setup
cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn['vsnip#anonymous'](args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<c-space>'] = cmp.mapping.complete(),
        ['<c-e>'] = cmp.mapping.abort(),
        ['<cr>'] = cmp.mapping.confirm({select = true}),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif vim.fn['vsnip#available'](1) == 1 then
                feedkey('<Plug>(vsnip-expand-or-jump)', '')
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.fn['vsnip#jumpable'](-1) == 1 then
                feedkey('<Plug>(vsnip-jump-prev)', '')
            end
        end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'vsnip' },
        { name = 'path' },
    }),
})

-- Optimized Pyright (Python LSP)
lspconfig.pyright.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly", -- Only analyze open files for performance
        useLibraryCodeForTypes = false, -- Reduces processing for type inference
      },
    },
  },
})

-- Optimized Clangd (C/C++ LSP)
lspconfig.clangd.setup({
  cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed", "--header-insertion=never" },
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = {
    clangdFileStatus = false,  -- Disables workspace symbol indexing for speed
    fallbackFlags = { "-std=c++17" },
  },
})

-- Add any other LSP servers you need here
-- This ensures LSP is loaded at the end so you can still use nvim even if LSP has errors
