return {
	{
		"mason-org/mason.nvim",
		opts = {},
		config = function()
			require("mason").setup({
				registries = {
					"github:mason-org/mason-registry",
					"github:Crashdummyy/mason-registry",
				},
			})
		end,
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
				ensure_installed = {
					"lua_ls",
					"bashls",
					"powershell_es",
					"rust_analyzer",
					"gopls",
					"basedpyright",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- vim.lsp.config("*", { capabilities = capabilities })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Buffer local mappings
					local opts = { buffer = ev.buf }

					-- Go to definition
					-- Go to type definition
					-- Go to implementation
					-- Hover documentation
					vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation", buffer = ev.buf })
					-- Show references
					--vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Show References', buffer = ev.buf })
					-- Rename symbol
					-- Code actions
					-- Format buffer
					-- vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, { desc = 'Format Buffer', buffer = ev.buf })
					-- Diagnostics
					vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
					vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
					vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
					vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
				end,
			})
		end,
	},
	{
		"TheLeoP/powershell.nvim",
		---@type powershell.user_config
		opts = {
			bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
		},
	},
}
