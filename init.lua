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

vim.pack.add({
	require("config.plugins.luisiacc--gruvbox-baby"),
	require("config.plugins.alexghergh--nvim-tmux-navigation"),
	require("config.plugins.nvim-treesitter--nvim-treesitter"),
	require("config.plugins.nvim-treesitter--nvim-treesitter-textobjects"),
	"https://github.com/nvim-tree/nvim-web-devicons",
	require("config.plugins.stevearc--oil"),
	require("config.plugins.stevearc--conform"),
	require("config.plugins.stevearc--quicker"),
	require("config.plugins.j-hui--fidget"),
	require("config.plugins.zbirenbaum--copilot"),
	require("config.plugins.Yu-Leo--blame-column"),
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
	require("config.plugins.mistweaverco--kulala"),
	require("config.plugins.obsidian-nvim--obsidian"),
	require("config.plugins.folke--sidekick"),
})

require("config.plugin_loader").process_packs()
