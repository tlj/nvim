-- Enable a list of LSPs  which we have pre-installed on the system
-- and have configuration for in the lsp/ folder.
if vim.fn.has("nvim-0.11") == 1 then
	vim.lsp.enable({ "luals", "gopls", "yamlls", "jsonls", "intelephense" })

	vim.lsp.config("*", { root_markers = { ".git" } })

	local hover = vim.lsp.buf.hover
	---@diagnostic disable-next-line: duplicate-set-field
	vim.lsp.buf.hover = function() return hover({ border = "rounded" }) end

	local signature_help = vim.lsp.buf.signature_help
	---@diagnostic disable-next-line: duplicate-set-field
	vim.lsp.buf.signature_help = function() return signature_help({ border = "rounded" }) end
else
	vim.notify("LSP not enabled because of nvim < 0.11")
end

-- Create autocommands for setting up keymaps and diagnostics when
-- the LSP has been loaded.
local lspgroup = vim.api.nvim_create_augroup("lsp", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = lspgroup,
	callback = function(args)
		-- Get the detaching client
		local bufnr = args.buf

		-- Set up keymaps
		vim.keymap.set(
			"n",
			"gl",
			'<cmd>lua vim.diagnostic.open_float(0, { scope = "line" })<cr>',
			{ buffer = bufnr, desc = "Show diagnostics" }
		)
		vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", { buffer = bufnr, desc = "Rename" })
		vim.keymap.set("n", "<leader>ga", "<cmd>lua vim.lsp.buf.code_action()<cr>", { buffer = bufnr, desc = "Code actions" })

		-- Set up diagnostics
		local signs = require("config.icons").lsp.diagnostic.signs
		local diagnostic_config = {
			virtual_text = { current_line = true },
			virtual_lines = false, -- { current_line = true },
			underline = true,
			update_in_insert = false,
			float = {
				border = "single",
			},
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = signs.Error,
					[vim.diagnostic.severity.WARN] = signs.Warn,
					[vim.diagnostic.severity.HINT] = signs.Hint,
					[vim.diagnostic.severity.INFO] = signs.Info,
				},
				numhl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
					[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
					[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
				},
				texthl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
					[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
					[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
				},
				linehl = {}, -- No line highlighting
			},
		}

		vim.diagnostic.config(diagnostic_config)
		vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, diagnostic_config)
		vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
			local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
			pcall(vim.diagnostic.reset, ns)
			return true
		end
	end,
})
