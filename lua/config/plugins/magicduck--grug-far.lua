return {
	src = "https://github.com/MagicDuck/grug-far.nvim",
	data = {
		setup = function()
			require("grug-far").setup({
				headerMaxWidth = 80,
			})
		end,
		keys = {
			["<leader>rs"] = {
				cmd = "<cmd>GrugFar<cr>",
				mode = { "n", "v" },
				desc = "Search and replace",
			},
		},
	},
}
