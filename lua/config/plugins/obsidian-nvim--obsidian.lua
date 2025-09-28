return {
	src = "https://github.com/obsidian-nvim/obsidian.nvim",
	data = {
		setup = function(_)
			require("obsidian").setup({
				legacy_commands = false,
				workspaces = {
					{
						name = "Private",
						path = "~/syncthing/Obsidian/",
					},
				},
			})
		end,
	},
}
