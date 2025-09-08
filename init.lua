-- Set up some Neovim options, mappings and auto commands
require("config.options")
require("config.mappings")
require("config.autocmds")

-- Load my own embedded plugins
require("statusline").setup()
require("lazygit").setup()

-- enable LSP
require("config.lsp")

-- if neovim is started with a directory as an argument, change to that directory
if vim.fn.isdirectory(vim.v.argv[2]) == 1 then vim.api.nvim_set_current_dir(vim.v.argv[2]) end

local map = vim.keymap.set

vim.pack.add({
	{
		src = "https://github.com/luisiacc/gruvbox-baby",
		data = {
			setup = function()
				vim.g.gruvbox_baby_use_original_palette = true
				vim.g.gruvbox_baby_background_color = "medium"
				vim.g.gruvbox_baby_comment_style = "italic"
				vim.g.gruvbox_baby_keyword_style = "NONE"
				vim.g.gruvbox_baby_transparent_mode = false
				vim.cmd("colorscheme gruvbox-baby")
			end,
		},
	},
	require("config.plugins.alexghergh--nvim-tmux-navigation"),
	require("config.plugins.nvim-treesitter--nvim-treesitter"),
	require("config.plugins.nvim-treesitter--nvim-treesitter-textobjects"),
	"https://github.com/nvim-tree/nvim-web-devicons",
	require("config.plugins.stevearc--oil"),
	require("config.plugins.stevearc--conform"),
	require("config.plugins.stevearc--quicker"),
	{
		src = "https://github.com/j-hui/fidget.nvim",
		data = {
			setup = function() require("fidget").setup() end,
		},
	},
	require("config.plugins.zbirenbaum--copilot"),
	{
		src = "https://github.com/Yu-Leo/blame-column.nvim",
		data = {
			setup = function() require("blame-column").setup() end,
			keys = {
				["<leader>bs"] = { cmd = "<cmd>BlameColumnToggle<cr>", desc = "Blame column" },
			},
		},
	},
	require("config.plugins.NickvanDyke--opencode"),
	require("config.plugins.lewis6991--gitsigns"),
	require("config.plugins.sindrets--diffview"),
	require("config.plugins.folke--snacks"),
	require("config.plugins.magicduck--grug-far"),
	require("config.plugins.mfussenegger--nvim-dap"),
	"https://github.com/nvim-neotest/nvim-nio",
	require("config.plugins.rcarriga--nvim-dap-ui"),
	require("config.plugins.leoluz--nvim-dap-go"),
	"https://github.com/andythigpen/nvim-coverage",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/fredrikaverpil/neotest-golang",
	require("config.plugins.nvim-neotest--neotest"),
	"https://github.com/rafamadriz/friendly-snippets",
	"https://github.com/giuxtaposition/blink-cmp-copilot",
	require("config.plugins.Saghen--blink-cmp"),
	require("config.plugins.folke--flash"),
})

for _, package in ipairs(vim.pack.get()) do
	if package.active and package.spec.data then
		if package.spec.data.setup and type(package.spec.data.setup) == "function" then package.spec.data.setup() end
		if package.spec.data.keys and type(package.spec.data.keys) == "table" then
			for keys, keymap in pairs(package.spec.data.keys) do
				local mode = "n"
				if keymap.mode then mode = keymap.mode end
				map(mode, keys, keymap.cmd, { silent = true, desc = keymap.desc })
			end
		end
	end
end
