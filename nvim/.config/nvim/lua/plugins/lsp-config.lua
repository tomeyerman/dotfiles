return 
{
    {
        "mason-org/mason.nvim",
        opts = {},
        config = function()
            require("mason").setup({
                registries = 
                {
                    "github:mason-org/mason-registry",
                    "github:Crashdummyy/mason-registry",
                },
            })
        end
    },
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {},
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "bashls", "powershell_es", "rust_analyzer" }
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup({})
            lspconfig.bashls.setup({})
            lspconfig.powershell_es.setup({})
            lspconfig.rust_analyzer.setup({})
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    -- Buffer local mappings
                    local opts = { buffer = ev.buf }

                    -- Go to definition
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    -- Go to type definition
                    vim.keymap.set('n', 'gD', vim.lsp.buf.type_definition, opts)
                    -- Go to implementation
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                    -- Hover documentation
                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                    -- Show references
                    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                    -- Rename symbol
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                    -- Code actions
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
                    -- Format buffer
                    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)

                    -- Diagnostics
                    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
                    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
                    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
                    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
                end,
            })
        end
    },
    {
        "seblyng/roslyn.nvim",
        ---@module 'roslyn.config'
        ---@type RoslynNvimConfig
        opts = {
            -- your configuration comes here; leave empty for default settings
        },
    },
    {
        "TheLeoP/powershell.nvim",
        ---@type powershell.user_config
        opts = {
        bundle_path = vim.fn.stdpath "data" .. "/mason/packages/powershell-editor-services"
        }
    }
}