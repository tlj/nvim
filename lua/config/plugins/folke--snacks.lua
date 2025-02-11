return {
	"folke/snacks.nvim",
	version = "v2",
	setup = function()
		require("snacks").setup({
			notifier = { enabled = true },
			picker = {
				enabled = true,
				win = {
					input = {
						keys = {
							["<Esc>"] = { "close", mode = { "n", "i" } },
							["<alt-q>"] = { "qflist", mode = { "i", "n" } },
							["<alt-k>"] = { "qflist", mode = { "i", "n" } },
						},
					},
				},
			},
		})
	end,
	keys = {
		["<leader><space>"] = { cmd = "<cmd>lua require'snacks'.picker.smart()<cr>", desc = "Smart files" },
		["<leader>ff"] = { cmd = "<cmd>lua require'snacks'.picker.files()<cr>", desc = "Find files" },
		["<leader>fe"] = { cmd = "<cmd>lua require'snacks'.picker.explorer()<cr>", desc = "File explorer" },
		["<leader>fg"] = { cmd = "<cmd>lua require'snacks'.picker.grep()<cr>", desc = "Grep" },
		["<leader>*"] = { cmd = "<cmd>lua require'snacks'.picker.grep_word()<cr>", desc = "Grep for current word" },

		["<leader>rr"] = { cmd = "<cmd>lua require'snacks'.picker.resume()<cr>", desc = "Resume picker" },
		["<leader>fh"] = { cmd = "<cmd>lua require'snacks'.picker.help()<cr>", desc = "Help pages" },
		["<leader>fb"] = { cmd = "<cmd>lua require'snacks'.picker.buffers()<cr>", desc = "Buffers" },
		["<leader>q:"] = { cmd = "<cmd>lua require'snacks'.picker.command_history()<cr>", desc = "Command history" },

		["gd"] = { cmd = "<cmd>lua require'snacks'.picker.lsp_definitions()<cr>", desc = "Fzf Definitions" },
		["gD"] = { cmd = "<cmd>lua require'snacks'.picker.lsp_declarations()<cr>", desc = "Fzf Declarations" },
		["gr"] = { cmd = "<cmd>lua require'snacks'.picker.lsp_references()<cr>", desc = "Fzf References" },
		["gI"] = { cmd = "<cmd>lua require'snacks'.picker.lsp_implementations()<cr>", desc = "Fzf Implementations" },
		["gy"] = { cmd = "<cmd>lua require'snacks'.picker.lsp_type_definitions()<cr>", desc = "Fzf Type Definitions" },

		-- git
		-- ["<leader>gb"] = { cmd = "<cmd>lua require'snacks'.picker.git_branches()<cr>", desc = "Git Branches" },
		-- ["<leader>gl"] = { cmd = "<cmd>lua require'snacks'.picker.git_log()<cr>", desc = "Git Log" },
		-- ["<leader>gL"] = { cmd = "<cmd>lua require'snacks'.picker.git_log_line()<cr>", desc = "Git Log Line" },
		-- ["<leader>gs"] = { cmd = "<cmd>lua require'snacks'.picker.git_status()<cr>", desc = "Git Status" },
		-- ["<leader>gS"] = { cmd = "<cmd>lua require'snacks'.picker.git_stash()<cr>", desc = "Git Stash" },
		-- ["<leader>gd"] = { cmd = "<cmd>lua require'snacks'.picker.git_diff()<cr>", desc = "Git Diff (Hunks)" },
		-- ["<leader>gf"] = { cmd = "<cmd>lua require'snacks'.picker.git_log_file()<cr>", desc = "Git Log File" },

		-- diagnostics
		["<leader>gl"] = {
			cmd = "<cmd>lua require'snacks'.picker.diagnostics_buffer()<cr>",
			desc = "Fzf Document Diagnostics",
		},
		["<leader>gj"] = { cmd = "<cmd>lua require'snacks'.picker.jumps()<cr>", desc = "Fzf Jumps" },
	},
}
