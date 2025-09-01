return {
	src = "https://github.com/stevearc/quicker.nvim",
	data = {
		setup = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "qf",
				callback = function(event)
					vim.keymap.set(
						"n",
						">",
						function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end,
						{ buffer = event.buf, silent = true }
					)
					vim.keymap.set("n", "<", function() require("quicker").collapse() end, { buffer = event.buf, silent = true })
				end,
			})
		end,
	},
}
