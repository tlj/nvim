return {
	"coder/claudecode.nvim",
	{
		requires = { "folke/snacks.nvim" },
		events = { "UIEnter" },
		setup = function() require("claudecode").setup() end,
		keys = {
			["<leader>ac"] = { cmd = "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
			["<leader>af"] = { cmd = "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
			["<leader>ar"] = { cmd = "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
			["<leader>aC"] = { cmd = "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
			["<leader>ab"] = { cmd = "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
			["<leader>as"] = { cmd = "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
			-- Diff management
			["<leader>aa"] = { cmd = "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
			["<leader>ad"] = { cmd = "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		},
	},
}
