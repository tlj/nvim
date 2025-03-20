return {
	"sindrets/diffview.nvim",
	{
		setup = function(_)
			require("diffview").setup()

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "DiffviewFileHistory",
				callback = function(event) vim.keymap.set("n", "q", "<cmd>DiffviewClose<cr>", { buffer = event.buf, silent = true }) end,
			})
		end,
		keys = {
			["<leader>hl"] = { cmd = "<cmd>DiffviewFileHistory %<cr>", desc = "File git history" },
		},
	},
}
