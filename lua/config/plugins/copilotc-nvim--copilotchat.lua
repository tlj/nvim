return {
	"CopilotC-Nvim/CopilotChat.nvim",
	{
		cmds = { "CopilotChat", "CopilotChatOpen", "CopilotChatToggle" },
		requires = { "zbirenbaum/copilot.lua", "nvim-lua/plenary.nvim" },
		settings = {
			model = "claude-3.5-sonnet",
		},
		setup = function() require("CopilotChat").setup() end,
		build = "make tiktoken",
		keys = {
			["<leader>cco"] = { cmd = function() require("CopilotChat").open() end, desc = "CopilotChat" },
			["<leader>ccq"] = {
				cmd = function()
					local input = vim.fn.input("Quick Chat: ")
					if input ~= "" then
						require("lua.config.plugins.copilotc-nvim--copilotchat").ask(input, { selection = require("CopilotChat.select").buffer })
					end
				end,
				desc = "CopilotChat - Quick chat",
			},
			["<leader>ccp"] = {
				cmd = function()
					local actions = require("CopilotChat.actions")
					require("CopilotChat.integrations.fzflua").pick(actions.prompt_actions())
				end,
				desc = "CopilotChat - Prompt actions",
			},
		},
	},
}
