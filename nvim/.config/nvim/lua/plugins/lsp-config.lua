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
                ensure_installed = { "lua_ls", "bashls", "powershell_es", "rust_analyzer", "gopls" }
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            --local lspconfig = require("lspconfig")
            --vim.lsp.config['lua_ls'].setup({})
            --lspconfig.bashls.setup({})
            --lspconfig.powershell_es.setup({})
            --lspconfig.rust_analyzer.setup({})
            vim.lsp.enable('lua_ls')  -- Enable Lua language server for neovim config files
            vim.lsp.enable('bashls')   -- Enable Bash language server
            vim.lsp.enable('powershell_es')  -- Enable PowerShell language server
            vim.lsp.enable('rust_analyzer')  -- Enable Rust language server
            vim.lsp.enable('gopls')
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    -- Buffer local mappings
                    local opts = { buffer = ev.buf }

                    -- Go to definition
                    vim.keymap.set('n', 'grd', vim.lsp.buf.definition, { desc = 'Go to Definition', buffer = ev.buf })
                    -- Go to type definition
                    vim.keymap.set('n', 'grD', vim.lsp.buf.type_definition, { desc = 'Go to Type Definition', buffer = ev.buf })
                    -- Go to implementation
                    vim.keymap.set('n', 'gri', vim.lsp.buf.implementation, { desc = 'Go to Implementation', buffer = ev.buf })
                    -- Hover documentation
                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Documentation', buffer = ev.buf })
                    -- Show references
                    --vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Show References', buffer = ev.buf })
                    -- Rename symbol
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename Symbol', buffer = ev.buf })
                    -- Code actions
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Actions', buffer = ev.buf })
                    -- Format buffer
                    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, { desc = 'Format Buffer', buffer = ev.buf })
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
