return {
	"yetone/avante.nvim",
	{
		events = { "BufReadPost" },
		build = "make",
		requires = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		setup = function()
			require("avante").setup({
				-- provider = "copilot",
			})
		end,
	},
}
