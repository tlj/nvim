-- Set up some Neovim options, mappings and auto commands
require("config.options")
require("config.mappings")
require("config.autocmds")

-- Load my own embedded plugins
require("statusline").setup()
require("lazygit").setup()

-- Use the include() method as shorthand for including a plugin spec defined
-- in the lua/config/plugins folder. Use this if the spec is more than ~5 lines
-- to keep the init file clean, but for smaller definitions we define them
-- here. We don't do automatic loading of spec files, since we want to be explicit
-- about what we load.
local include = require("graft").include
require("graft").setup({
	debug = false,
	start = {
		{
			-- gruvbox is objectively the best colorscheme, as it is not blue
			"luisiacc/gruvbox-baby",
			function()
				vim.g.gruvbox_baby_use_original_palette = true
				vim.g.gruvbox_baby_background_color = "medium"
				vim.g.gruvbox_baby_comment_style = "italic"
				vim.g.gruvbox_baby_keyword_style = "NONE"
				vim.g.gruvbox_baby_transparent_mode = false
				vim.cmd("colorscheme gruvbox-baby")
			end,
		},
		{
			-- pretty notifications - not strictly neccessary
			"rcarriga/nvim-notify",
			function()
				local notify = require("notify")
				notify.setup({ stages = "static" })
				vim.notify = notify
			end,
		},
		-- LSP completions for CMP
		-- Has to be loaded at startup so it can be used in v0.11 style lsp config
		"hrsh7th/cmp-nvim-lsp",
		-- treesitterk
		include("nvim-treesitter/nvim-treesitter"),
		include("nvim-treesitter/nvim-treesitter-textobjects"), -- extend treesitter
	},
	opt = {
		{
			-- Icons for the plugins which require them - currently only Oil.nvim
			"nvim-tree/nvim-web-devicons",
			settings = { color_icons = true },
		},

		-- AI stuff
		include("zbirenbaum/copilot.lua"), -- for autocomplete
		include("CopilotC-Nvim/CopilotChat.nvim"), -- for chat

		-- nvim-cmp stuff
		{
			"zbirenbaum/copilot-cmp",
			function(_) require("copilot_cmp").setup() end,
			after = { "zbirenbaum/copilot.lua" },
		},
		include("hrsh7th/nvim-cmp"),

		-- Code formatting
		include("stevearc/conform.nvim"),

		-- Git stuff
		include("lewis6991/gitsigns.nvim"),
		{
			"sindrets/diffview.nvim",
			setup = function(_)
				require("diffview").setup()

				vim.api.nvim_create_autocmd("FileType", {
					pattern = "DiffviewFileHistory",
					callback = function(event) vim.keymap.set("n", "q", "<cmd>DiffviewClose<cr>", { buffer = event.buf, silent = true }) end,
				})
			end,
			keys = {
				["<leader>hl"] = { cmd = "<cmd>DiffviewFileHistory %<cr>", desc = "File git history" },
			},
		},

		-- File management and fuzzy finding
		include("ibhagwan/fzf-lua"),
		include("stevearc/oil.nvim"), -- file management

		-- TMUX navigation (ctrl-hjkl to switch between nvim and tmux
		include("alexghergh/nvim-tmux-navigation"),

		-- search and replace
		include("MagicDuck/grug-far"),

		-- treesitter
		include("aaronik/treewalker.nvim"), -- navigate through elements on the same indent level

		-- dap debugger
		include("mfussenegger/nvim-dap"),
		{
			-- Forked from igorlfs/nvim-dap-view. Using the fork until some of my PRs are
			-- merged.
			"tlj/nvim-dap-view",
			after = { "mfussenegger/nvim-dap" },
			settings = {
				windows = {
					width = 1,
					position = "below",
				},
			},
			setup = function(settings)
				require("dap-view").setup(settings)
				local dap, dapview = require("dap"), require("dap-view")
				dap.listeners.after.event_initialized["dap-view"] = function()
					vim.notify("Debug session started.")
					dapview.open()
				end
				dap.listeners.before.event_terminated["dap-view"] = function()
					vim.notify("Debug session stopped.")
					dapview.close()
				end
				dap.listeners.before.event_exited["dap-view"] = function()
					vim.notify("Debug session stopped.")
					dapview.close()
				end
			end,
			keys = {
				["<leader>dap"] = { cmd = "<cmd>DapViewToggle<cr>", desc = "DapView Toggle" },
				["<leader>dw"] = { cmd = "<cmd>DapViewWatch<CR>", desc = "DapView Add to Watch" },
			},
		},
		-- include("theHamsta/nvim-dap-virtual-text"),
		include("leoluz/nvim-dap-go"),
		-- include("rcarriga/nvim-dap-ui"),

		-- Quickfix improvements
		{
			"stevearc/quicker.nvim",
			keys = {
				[">"] = { cmd = function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end },
				["<"] = { cmd = function() require("quicker").collapse() end },
			},
		},
	},
})

-- enable LSP
require("config.lsp")

-- if neovim is started with a directory as an argument, change to that directory
if vim.fn.isdirectory(vim.v.argv[2]) == 1 then vim.api.nvim_set_current_dir(vim.v.argv[2]) end
