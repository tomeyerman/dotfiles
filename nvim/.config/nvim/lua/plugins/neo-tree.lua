return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons", -- optional, but recommended
		"antosha417/nvim-lsp-file-operations",
		"s1n7ax/nvim-window-picker",
		"folke/snacks.nvim",
	},
	lazy = false,
	config = function()
		vim.keymap.set("n", "<leader>n", ":Neotree toggle filesystem reveal left<CR>", { desc = "Toggle NeoTree" })
	end,
}
