return {
	"stevearc/oil.nvim",
	{
		-- settings = {
		-- 	float = {
		-- 		max_width = 90,
		-- 		max_height = 30,
		-- 	},
		-- },
		cmds = { "Oil" },
		requires = { "nvim-tree/nvim-web-devicons" },
		setup = function(settings)
			require("oil").setup(settings)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "oil" },
				callback = function(event)
					vim.bo[event.buf].buflisted = false
					vim.b.prev_buf = vim.fn.bufnr("#")

					vim.keymap.set("n", "q", function()
						local prev_buf = vim.b.prev_buf
						require("oil").close()
						if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then vim.api.nvim_set_current_buf(prev_buf) end
					end, { buffer = event.buf, silent = true })
				end,
			})
		end,
		keys = {
			["<leader>tt"] = {
				cmd = function() require("oil").open() end,
				desc = "Oil file explorer",
			},
		},
	},
}
