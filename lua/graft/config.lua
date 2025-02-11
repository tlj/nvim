local M = {}

local defaults = {
	root_dir = vim.fn.stdpath("data") .. "/site", -- config for dotfiles repo, data for ~/.local/share/nvim/site
	pack_dir = "pack/graft/opt/",
	submodules = false,
	install = false,
	debug = false,
	start = {},
	opt = {},
}

function M.setup(opts) M.config = vim.tbl_deep_extend("force", defaults, opts or {}) end

return M
