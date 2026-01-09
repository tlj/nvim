-- Plugin config for Yu-Leo/blame-column.nvim
return {
	src = "https://github.com/mistweaverco/kulala.nvim",
	data = {
		setup = function()
			require("kulala").setup({
				global_keymaps = false,
				global_keymaps_prefix = "<leader>R",
				kulala_keymaps_prefix = "",
			})
		end,
		keys = {
			["<leader>Rs"] = { mode = { "n", "v" }, cmd = function() require("kulala").run() end, desc = "Send request" },
			["<leader>Rr"] = { mode = { "n", "v" }, cmd = function() require("kulala").replay() end, desc = "Replay request" },
		},
	},
}
