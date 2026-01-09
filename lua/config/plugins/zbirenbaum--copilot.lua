return {
	src = "https://github.com/zbirenbaum/copilot.lua",
	data = {
		setup = function()
			require("copilot").setup({
				suggestion = {
					enabled = false,
					auto_trigger = true,
				},
				panel = { enabled = false },
			})
		end,
	},
}
