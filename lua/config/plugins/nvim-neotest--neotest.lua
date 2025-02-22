return {
	"nvim-neotest/neotest",
	requires = {
		"andythigpen/nvim-coverage",
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"fredrikaverpil/neotest-golang",
	},
	setup = function()
		local neotest_golang_opts = {
			-- runner = "gotestsum",
			go_test_args = {
				"-v",
				"-race",
				"-count=1",
				"-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
			},
		}
		require("neotest").setup({
			adapters = {
				require("neotest-golang")(neotest_golang_opts),
			},
		})
		require("coverage").setup()
	end,
	keys = {
		["<leader>tf"] = { cmd = function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run tests for file" },
		["<leader>tn"] = { cmd = function() require("neotest").run.run() end, desc = "Run nearest test" },
		["<leader>td"] = { cmd = function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
		["<leader>to"] = { cmd = function() require("neotest").output_panel.open() end, desc = "Open output panel for tests" },
		["<leader>ts"] = { cmd = function() require("neotest").summary.open() end, desc = "Open summary panel for tests" },
		["<leader>tc"] = { cmd = "<cmd>Coverage<cr>", desc = "Open summary panel for tests" },
	},
}
