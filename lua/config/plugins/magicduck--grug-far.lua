return {
	"MagicDuck/grug-far.nvim",
	{
		cmds = { "GrugFar" },
		-- branch = "1.5.4",
		settings = {
			headerMaxWidth = 80,
		},
		keys = {
			["<leader>rs"] = {
				cmd = function()
					local grug = require("grug-far")
					local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
					grug.grug_far({
						transient = true,
						prefills = {
							filesFilter = ext and ext ~= "" and "*." .. ext or nil,
						},
					})
				end,
				mode = { "n", "v" },
				desc = "Search and replace",
			},
		},
	},
}
