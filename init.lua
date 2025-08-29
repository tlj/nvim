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
local mapopts = { silent = true }
local augroup = vim.api.nvim_create_augroup("tlj.cfg", { clear = true })

vim.pack.add({
	"https://github.com/luisiacc/gruvbox-baby",
	"https://github.com/alexghergh/nvim-tmux-navigation",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/j-hui/fidget.nvim",
	"https://github.com/zbirenbaum/copilot.lua",
	"https://github.com/giuxtaposition/blink-cmp-copilot",
	"https://github.com/rafamadriz/friendly-snippets",
	{ src = "https://github.com/Saghen/blink.cmp", version = "v1.0.0" },
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/Yu-Leo/blame-column.nvim",
})

local function setup_gruvbox()
	-- Set up colorscheme
	vim.g.gruvbox_baby_use_original_palette = true
	vim.g.gruvbox_baby_background_color = "medium"
	vim.g.gruvbox_baby_comment_style = "italic"
	vim.g.gruvbox_baby_keyword_style = "NONE"
	vim.g.gruvbox_baby_transparent_mode = false
	vim.cmd("colorscheme gruvbox-baby")
end

local function setup_tmux_navigation()
	require("nvim-tmux-navigation").setup({
		disable_when_zoomed = true,
		keybindings = { left = "<C-h>", down = "<C-j>", up = "<C-k>", right = "<C-l>" },
	})
end

local function setup_oil()
	require("nvim-web-devicons").setup({ color_icons = true })
	require("oil").setup({})
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "oil" },
		callback = function(event)
			vim.bo[event.buf].buflisted = false
			vim.b.prev_buf = vim.fn.bufnr("#")

			map("n", "q", function()
				local prev_buf = vim.b.prev_buf
				require("oil").close()
				if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then vim.api.nvim_set_current_buf(prev_buf) end
			end, { buffer = event.buf, silent = true })
		end,
	})
	map("n", "<leader>tt", function() require("oil").open() end, mapopts)
end

local function setup_snacks()
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

	map("n", "<leader><space>", "<cmd>lua require'snacks'.picker.smart()<cr>", { silent = true, desc = "Smart files " })
	map("n", "<leader>ff", "<cmd>lua require'snacks'.picker.files()<cr>", { silent = true, desc = "Find files" })
	map("n", "<leader>fe", "<cmd>lua require'snacks'.picker.exporer()<cr>", { silent = true, desc = "File explorer" })
	map("n", "<leader>fg", "<cmd>lua require'snacks'.picker.grep()<cr>", { silent = true, desc = "Grep" })
	map("n", "<leader>*", "<cmd>lua require'snacks'.picker.grep_word()<cr>", { silent = true, desc = "Grep for current word" })

	map("n", "<leader>rr", "<cmd>lua require'snacks'.picker.resume()<cr>", { silent = true, desc = "Resume picker" })
	map("n", "<leader>rh", "<cmd>lua require'snacks'.picker.help()<cr>", { silent = true, desc = "Help pages" })
	map("n", "<leader>fb", "<cmd>lua require'snacks'.picker.buffers()<cr>", { silent = true, desc = "Buffers" })
	map("n", "<leader>q:", "<cmd>lua require'snacks'.picker.buffers()<cr>", { silent = true, desc = "Command history" })

	map("n", "gd", "<cmd>lua require'snacks'.picker.lsp_definitions()<cr>", { silent = true, desc = "LSP Definitions" })
	map("n", "gD", "<cmd>lua require'snacks'.picker.lsp_declarations()<cr>", { silent = true, desc = "LSP Declarations" })
	map("n", "gr", "<cmd>lua require'snacks'.picker.lsp_references()<cr>", { silent = true, desc = "LSP References" })
	map("n", "gI", "<cmd>lua require'snacks'.picker.lsp_implementations()<cr>", { silent = true, desc = "LSP Implementations" })
	map("n", "gi", "<cmd>lua require'snacks'.picker.lsp_implementations()<cr>", { silent = true, desc = "LSP Implementations" })
	map("n", "gy", "<cmd>lua require'snacks'.picker.lsp_type_definitions()<cr>", { silent = true, desc = "LSP Type definitions" })

	map("n", "gl", "<cmd>lua require'snacks'.picker.diagnostics_buffer()<cr>", { silent = true, desc = "LSP Document Diagnostics" })
	map("n", "gj", "<cmd>lua require'snacks'.picker.jumps()<cr>", { silent = true, desc = "LSP Jumps" })
end

local function setup_treesitter()
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"bash",
			"comment",
			"diff",
			"gitignore",
			"go",
			"gowork",
			"gomod",
			"gosum",
			"gotmpl",
			"help",
			"html",
			"javascript",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"php",
			"sql",
			"yaml",
			"vim",
			"ruby",
		}, -- one of "all", "language", or a list of languages
		highlight = {
			enable = true, -- false will disable the whole extension
			disable = {}, -- list of language that will be disabled
		},
		sync_install = false,
		auto_install = true,
		ignore_install = { "help" },
		indent = { enable = true },
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<C-space>",
				node_incremental = "<C-space>",
				scope_incremental = false,
				node_decremental = "<bs>",
			},
		},
	})
	vim.api.nvim_create_autocmd("PackChanged", { -- update treesitter parsers/queries with plugin updates
		group = augroup,
		callback = function(ev)
			local spec = ev.data.spec
			if spec and spec.name == "nvim-treesitter" and ev.data.kind == "update" then
				vim.schedule(function() require("nvim-treesitter").update() end)
			end
		end,
	})
end

local function setup_conform()
	require("conform").setup({
		log_level = vim.log.levels.DEBUG,
		formatters_by_ft = {
			go = { "goimports" },
			lua = { "stylua" },
			sh = { "shfmt" },
			markdown = { "mdformat" },
			ts = { "prettier" },
		},
		formatters = {
			shfmt = { preprend_args = { "-i", "2" } },
		},
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end

			local autoformat_filetypes = { "lua", "go", "json" }
			local filetype = vim.bo[bufnr].filetype

			if vim.tbl_contains(autoformat_filetypes, filetype) then return { timeout_ms = 500, lsp_format = "fallback" } end
		end,
	})

	vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

	vim.api.nvim_create_user_command("FormatDisable", function(args)
		if args.bang then
			-- FormatDisable! will disable formatting just for this buffer
			vim.b.disable_autoformat = true
		else
			vim.g.disable_autoformat = true
		end
	end, { desc = "Disable autoformat-on-save", bang = true })

	vim.api.nvim_create_user_command("FormatEnable", function()
		vim.b.disable_autoformat = false
		vim.g.disable_autoformat = false
	end, { desc = "Enable autoformat-on-save" })

	map(
		"n",
		"<leader>oo",
		function() require("conform").format({ async = false, lsp_fallback = false }) end,
		{ silent = true, desc = "Format buffer" }
	)
end

local function setup_lsp()
	require("fidget").setup()
	require("copilot").setup({
		suggestion = {
			enabled = false,
			auto_trigger = true,
		},
		panel = { enabled = false },
	})

	require("blink.cmp").setup({
		keymap = {
			preset = "default",
			["<CR>"] = { "accept", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-d>"] = { "select_prev", "fallback" },
		},

		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},

		completion = {
			list = {
				selection = {
					preselect = false,
					auto_insert = false,
				},
			},
			keyword = {
				range = "full",
			},
			accept = {
				auto_brackets = {
					enabled = true,
				},
			},
			menu = {
				border = "single",
				auto_show = true,
				draw = {
					treesitter = { "lsp" },
					columns = {
						{ "label", "label_description", gap = 1 },
						{ "kind_icon", "kind" },
						{ "source_name" },
					},
				},
			},
			documentation = {
				auto_show = true,
			},
			ghost_text = {
				enabled = true,
			},
		},

		fuzzy = {
			-- controls which sorts to use and in which order, falling back to the next sort if the first one returns nil
			-- you may pass a function instead of a string to customize the sorting
			sorts = { "score", "kind", "label" },
		},

		sources = {
			providers = {
				copilot = { name = "copilot", module = "blink-cmp-copilot" },
			},
			default = { "copilot", "lsp", "path", "snippets", "buffer" },
		},
	})
end

local function setup_git()
	require("gitsigns").setup({
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function gitmap(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end

			-- navigation
			gitmap("n", "]c", function()
				if vim.wo.diff then return "]c" end
				vim.schedule(function() gs.next_hunk() end)
				return "<Ignore>"
			end, { expr = true, desc = "Next git hunk" })

			gitmap("n", "[c", function()
				if vim.wo.diff then return "[c" end
				vim.schedule(function() gs.prev_hunk() end)
				return "<Ignore>"
			end, { expr = true, desc = "Prev git hunk" })

			-- Actions
			gitmap({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
			gitmap({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
			gitmap("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
			gitmap("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
			gitmap("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
			gitmap("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
			gitmap("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
			gitmap("n", "<leader>hB", gs.toggle_current_line_blame, { desc = "Toggle current line blame" })
			gitmap("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
			gitmap("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff this" })
			gitmap("n", "<leader>he", gs.toggle_deleted, { desc = "Toggle deleted" })

			-- Text object
			gitmap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
		end,
	})

	require("blame-column").setup()
	map("n", "<leader>bs", "<cmd>BlameColumnToggle<cr>", { silent = true, desc = "Blame column" })
end

setup_gruvbox()
setup_tmux_navigation()
setup_lsp()
setup_treesitter()
setup_oil()
setup_conform()
setup_snacks()
setup_git()

-- 		{
-- 			"folke/which-key.nvim",
-- 			{
-- 				setup = function() require("which-key").setup() end,
-- 				events = { "VimEnter" },
-- 			},
-- 		},
-- 	},
-- 	opt = {
-- 		--
-- 		-- Git stuff
-- 		graft.include("sindrets/diffview.nvim"),
-- 		--
-- 		-- search and replace
-- 		graft.include("MagicDuck/grug-far"),
-- 		--
-- 		-- dap debugger
-- 		graft.include("mfussenegger/nvim-dap"),
-- 		graft.include("rcarriga--nvim-dap-ui.lua"),
-- 		graft.include("leoluz/nvim-dap-go"),
-- 		--
-- 		-- -- Markdown
-- 		{
-- 			"MeanderingProgrammer/render-markdown.nvim",
-- 			{
-- 				ft = { "markdown", "Avante" },
-- 				requires = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
-- 				setup = function()
-- 					require("render-markdown").setup({
-- 						file_types = { "markdown", "Avante" },
-- 					})
-- 				end,
-- 			},
-- 		},
-- 		--
-- 		-- Quickfix improvements
-- 		{
-- 			"stevearc/quicker.nvim",
-- 			{
-- 				ft = { "qf" },
-- 				keys = {
-- 					[">"] = { cmd = function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end },
-- 					["<"] = { cmd = function() require("quicker").collapse() end },
-- 				},
-- 			},
-- 		},
-- 		--
-- 		-- Testing
-- 		graft.include("nvim-neotest/neotest"),
-- 	},
-- })
