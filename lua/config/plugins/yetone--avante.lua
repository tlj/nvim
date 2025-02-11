return {
	"yetone/avante.nvim",
	build = "make",
	requires = {
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"hrsh7th/nvim-cmp",
		"nvim-tree/nvim-web-devicons",
	},
	setup = function()
		require("avante").setup({
			provider = "claude",
		})
	end,
}
