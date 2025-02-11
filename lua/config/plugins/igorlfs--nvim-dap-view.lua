return {
	"igorlfs/nvim-dap-view",
	after = { "mfussenegger/nvim-dap" },
	settings = {
		windows = {
			terminal = {
				hide = { "delve" },
			},
		},
	},
	setup = function(settings)
		require("dap-view").setup(settings)
		local dap, dapview = require("dap"), require("dap-view")
		dap.listeners.after.event_initialized["dap-view"] = function()
			vim.notify("Debug session started.")
			dapview.open()
		end
		dap.listeners.before.event_terminated["dap-view"] = function()
			vim.notify("Debug session stopped.")
			dapview.close()
		end
		dap.listeners.before.event_exited["dap-view"] = function()
			vim.notify("Debug session stopped.")
			dapview.close()
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "dap-view" },
			callback = function(event)
				vim.bo[event.buf].buflisted = false
				vim.keymap.set("n", "q", "<cmd>require('dap-view').close()<cr>", { buffer = event.buf, silent = true })
			end,
		})
	end,

	keys = {
		["<leader>dap"] = { cmd = "<cmd>DapViewToggle<cr>", desc = "DapView Toggle" },
		["<leader>dw"] = { cmd = "<cmd>DapViewWatch<CR>", desc = "DapView Add to Watch" },
	},
}
