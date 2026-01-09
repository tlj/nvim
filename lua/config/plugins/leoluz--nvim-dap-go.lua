return {
	src = "https://github.com/leoluz/nvim-dap-go",
	after = { "mfussenegger/nvim-dap" },
	setup = function()
		require("dap-go").setup({
			dap_configurations = {
				{
					type = "go",
					name = "Debug Workspace (arguments)",
					request = "launch",
					program = "${workspaceFolder}",
					outputMode = "remote",
					args = function()
						local args_string = vim.fn.input("Arguments: ")
						return vim.split(args_string, " +")
					end,
				},
			},
		})
	end,
}
