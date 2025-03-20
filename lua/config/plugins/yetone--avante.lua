return {
	"yetone/avante.nvim",
	{
		events = { "UIEnter" },
		branch = "v0.0.23",
		build = "make",
		requires = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		setup = function()
			require("avante").setup()
		end,
	},
}
