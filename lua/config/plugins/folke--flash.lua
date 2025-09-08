return {
	src = "https://github.com/folke/flash.nvim",
	data = {
		setup = function() require("flash").setup() end,
		keys = {
			["s"] = { mode = { "n", "x", "o" }, cmd = function() require("flash").jump() end, desc = "Flash" },
		},
	},
}
