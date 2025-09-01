return {
	src = "https://github.com/NickvanDyke/opencode.nvim",
	data = {
		setup = function()
			vim.keymap.set("v", "oa", function() require("opencode").ask("@selection: ") end, { silent = true, desc = "Ask Opencode about this" })
			vim.keymap.set(
				{ "n", "v" },
				"op",
				function() require("opencode").select_prompt() end,
				{ silent = true, desc = "Select opencode prompt" }
			)
		end,
		keys = {
			["oA"] = { cmd = function() require("opencode").ask() end, desc = "Ask Opencode" },
			["oa"] = { cmd = function() require("opencode").ask("@cursor: ") end, desc = "Ask Opencode about this" },
			["ot"] = { cmd = function() require("opencode").toggle() end, desc = "Toggle embedded opencode" },
			["on"] = { cmd = function() require("opencode").command("session_new") end, desc = "New opencode session" },
			["oy"] = { cmd = function() require("opencode").command("messages_copy") end, desc = "Copy last opencode message" },
		},
	},
}
