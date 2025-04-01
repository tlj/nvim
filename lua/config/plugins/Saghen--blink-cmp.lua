return {
	"Saghen/blink.cmp",
	{
		requires = { "rafamadriz/friendly-snippets" },
		branch = "v1.0.0",
		events = { "VimEnter" },
		settings = {
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
		},
	},
}
