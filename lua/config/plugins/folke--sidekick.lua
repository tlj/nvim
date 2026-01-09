return {
	src = "https://github.com/folke/sidekick.nvim",
	data = {
		setup = function()
			require("sidekick").setup({
				cli = {
					mux = {
						enabled = true,
						backend = "tmux",
					},
				},
			})
		end,
		keys = {
			["<tab>"] = {
				cmd = function()
					if not require("sidekick").nes_jump_or_apply() then return "<Tab>" end
				end,
				desc = "Ask Opencode",
			},
			["<space>ac"] = {
				cmd = function() require("sidekick.cli").toggle({ name = "copilot", focus = "true" }) end,
				desc = "Ask Copilot",
			},
			["<space>ap"] = {
				cmd = function() require("sidekick.cli").prompt() end,
				mode = { "n", "x" },
				desc = "Sidekick Select Prompt",
			},
			["<space>av"] = {
				cmd = function() require("sidekick.cli").send({ msg = "{selection}" }) end,
				mode = { "x" },
				desc = "Sidekick Visual Selection",
			},
			["<space>as"] = {
				cmd = function() require("sidekick.cli").select() end,
				mode = { "n" },
				desc = "Select Cli",
			},
			["<space>at"] = {
				cmd = function() require("sidekick.cli").send({ msg = "{this}" }) end,
				mode = { "x", "n" },
				desc = "Toggle Test",
			},
			["<space>af"] = {
				cmd = function() require("sidekick.cli").send({ msg = "{file}" }) end,
				mode = { "x", "n" },
				desc = "Send File",
			},
			["<space>aa"] = {
				cmd = function() require("sidekick.cli").toggle() end,
				mode = { "n" },
				desc = "Sidekick toggle",
			},
			["<c-.>"] = {
				cmd = function() require("sidekick.cli").toggle() end,
				mode = { "n", "t", "i", "x" },
				desc = "Sidekick toggle",
			},
		},
	},
}
