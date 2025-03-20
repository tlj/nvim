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

-- Graft is required. Install with:
-- git clone git@github.com:tlj/graft.nvim ~/.local/share/nvim/site/pack/graft/start/graft.nvim
local ok, graft = pcall(require, "graft")
if not ok then
	vim.notify("Graft is not installed")
	return
end

-- Use graft tools to automatically handle plugins
require("graft.git").setup({ install_plugins = true, remove_plugins = true })
require("graft.ui").setup()

-- Use the graft.include() method as shorthand for including a plugin spec defined
-- in the lua/config/plugins folder. Use this if the spec is more than ~5 lines
-- to keep the init file clean, but for smaller definitions we define them
-- here. We don't do automatic loading of spec files, since we want to be explicit
-- about what we load.
graft.setup({
	debug = false,
	start = {
		{ "tlj/graft.nvim", { setup = function() end, branch = "update" } },
		{
			-- Make sure graft is up to date
			-- gruvbox is objectively the best colorscheme, as it is not blue
			"luisiacc/gruvbox-baby",
			{
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

		-- treesitterk
		graft.include("nvim-treesitter/nvim-treesitter"),
		graft.include("nvim-treesitter/nvim-treesitter-textobjects"), -- extend treesitter

		-- folke/snacks - replaces pickers
		graft.include("folke/snacks.nvim"),

		{
			"folke/which-key.nvim",
			{
				setup = function() require("which-key").setup() end,
				events = { "VimEnter" },
			},
		},
	},
	opt = {
		{
			-- Icons for the plugins which require them - currently only Oil.nvim
			"nvim-tree/nvim-web-devicons",
			{
				settings = { color_icons = true },
			},
		},
		--
		-- LSP progress
		{
			"j-hui/fidget.nvim",
			{
				setup = function() require("fidget").setup() end,
				events = { "BufReadPost" },
			},
		},
		--
		-- AI stuff
		graft.include("zbirenbaum/copilot.lua"), -- for autocomplete
		graft.include("CopilotC-Nvim/CopilotChat.nvim"), -- for chat
		--
		-- completion
		{ "giuxtaposition/blink-cmp-copilot", { after = { "zbirenbaum/copilot.lua" } } },
		graft.include("Saghen/blink.cmp"),
		--
		-- Code formatting
		graft.include("stevearc/conform.nvim"),
		--
		-- Git stuff
		graft.include("lewis6991/gitsigns.nvim"),
		graft.include("sindrets/diffview.nvim"),
		{
			"Yu-Leo/blame-column.nvim",
			{
				setup = function() require("blame-column").setup() end,
				keys = { ["<leader>bs"] = { cmd = "<cmd>BlameColumnToggle<cr>", desc = "Blame column" } },
			},
		},
		--
		-- File management and fuzzy finding
		graft.include("stevearc/oil.nvim"), -- file management
		--
		-- TMUX navigation (ctrl-hjkl to switch between nvim and tmux
		graft.include("alexghergh/nvim-tmux-navigation"),
		--
		-- search and replace
		graft.include("MagicDuck/grug-far"),
		--
		-- -- treesitter
		-- graft.include("aaronik/treewalker.nvim"), -- navigate through elements on the same indent level
		--
		-- dap debugger
		graft.include("mfussenegger/nvim-dap"),
		graft.include("rcarriga--nvim-dap-ui.lua"),
		graft.include("leoluz/nvim-dap-go"),
		--
		-- -- Markdown
		{
			"MeanderingProgrammer/render-markdown.nvim",
			{
				ft = { "markdown", "Avante" },
				requires = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
				setup = function()
					require("render-markdown").setup({
						file_types = { "markdown", "Avante" },
					})
				end,
			},
		},
		--
		-- Quickfix improvements
		{
			"stevearc/quicker.nvim",
			{
				ft = { "qf" },
				keys = {
					[">"] = { cmd = function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end },
					["<"] = { cmd = function() require("quicker").collapse() end },
				},
			},
		},
		--
		-- Testing
		graft.include("nvim-neotest/neotest"),
		--
		-- AI
		graft.include("yetone/avante.nvim"),
	},
})
