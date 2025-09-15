-- Plugin loader: processes vim.pack.get() packages, runs setup and registers keys
local M = {}

local function safe_notify(msg, level) pcall(vim.notify, msg, level or vim.log.levels.WARN) end

local function register_keymap(map, lhs, rhs)
	local mode = "n"
	if rhs.mode then mode = rhs.mode end
	map(mode, lhs, rhs.cmd, { silent = true, desc = rhs.desc })
end

function M.process_packs(packs)
	packs = packs or vim.pack.get()
	local map = vim.keymap.set
	local processed = {}

	for _, package in ipairs(packs) do
		if package.active and package.spec and package.spec.data then
			local data = package.spec.data
			local pkg_name = package.name or package.spec.src or "<unknown>"

			if data.setup and type(data.setup) == "function" then
				local ok, err = pcall(data.setup)
				if not ok then safe_notify(string.format("plugin setup failed for %s: %s", pkg_name, err), vim.log.levels.ERROR) end
			end

			if data.build and type(data.build) == "function" then
				local augroup = vim.api.nvim_create_augroup("plugin_loader_" .. pkg_name:gsub("[^%w]", "_"), { clear = true })
				vim.api.nvim_create_autocmd("PackChanged", {
					group = augroup,
					callback = function(ev)
						local spec = ev.data.spec
						if spec and spec.name == package.name and ev.data.kind == "update" then
							vim.schedule(function()
								local ok, err = pcall(data.build)
								if not ok then safe_notify(string.format("plugin build failed for %s: %s", pkg_name, err), vim.log.levels.ERROR) end
							end)
						end
					end,
				})
			end

			if data.keys and type(data.keys) == "table" then
				for keys, keymap in pairs(data.keys) do
					local ok, err = pcall(register_keymap, map, keys, keymap)
					if not ok then safe_notify(string.format("failed to register key %s for %s: %s", keys, pkg_name, err)) end
				end
			end
			table.insert(processed, pkg_name)
		end
	end

	return processed
end

return M
