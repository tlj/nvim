local M = {
	plugins = {},
	root_plugins = {}, -- list
	loaded = {},
	installed = {},
}

local to_install = 0
local installed = 0

local benchmark = require("graft.benchmark")
local git = require("graft.git")
local config = require("graft.config")

---@class tlj.Plugin
---@field repo string The github repo path
---@field requires? (string|tlj.Plugin)[]
---@field setup? function
---@field settings? table
---@field auto_install? boolean Defaults to true
---@field pattern? string[] Patterns which are required for loading the plugin
---@field after? string[] Plugins which trigger loading of this plugin (list of repos)
---@field keys? table<string, {cmd:string|function, desc: string}> Keymaps with commands (string or function) and description
---@field ft? string[] Filetypes which will trigger loading of this plugin
---@field cmds? string[] A list of commands which will load the plugin
---@field events? string[] A list of events which will load the plugin
---@field build? string A command (vim cmd if it starts with :, system otherwise) to run after install
---@field version? string Version constraint (tag/branch). Use "*" or nil for default branch, "v1.2.3" for exact tag, "v1" or "v1.2" for prefix matching
---@field lazy? boolean

---@param arg string|tlj.Plugin
---@return tlj.Plugin
local function normalize_spec(arg)
	local spec = {}

	if type(arg) == "string" then
		spec.repo = arg
	elseif type(arg) == "table" then
		if type(arg[1]) == "string" then
			arg.repo = arg[1]
			arg[1] = nil
		end
		if type(arg[2]) == "function" then
			arg.setup = arg[2]
			arg[2] = nil
		end
		spec = arg
	else
		vim.notify("Argument to add() should be string or table.", vim.log.levels.ERROR)
	end

	return spec
end

-- Register plugins which this plugin will load after, through listening
-- to user events emitted by plugins being loaded
---@param spec tlj.Plugin
local function register_after(spec)
	for _, after in ipairs(spec.after or {}) do
		vim.api.nvim_create_autocmd("User", {
			group = M.autogroup,
			pattern = after,
			callback = function() M.load(spec.repo) end,
			once = true, -- we only need this to happen once
		})
	end
end

-- Register a proxy user command which will load the plugin and then
-- trigger the command on the plugin
---@param spec tlj.Plugin
M.register_cmds = function(spec)
	for _, cmd in ipairs(spec.cmds or {}) do
		-- Register a command for each given commands
		vim.api.nvim_create_user_command(cmd, function(args)
			-- When triggered, delete this command
			vim.api.nvim_del_user_command(cmd)

			-- Then load the plugin
			M.load(spec.repo)

			-- Then trigger the original command
			vim.cmd(string.format("%s %s", cmd, args.args))
		end, {
			nargs = "*",
		})
	end
end

-- Register filetypes which will trigger loading the plugin
---@param spec tlj.Plugin
M.register_ft = function(spec)
	if spec.ft then
		vim.api.nvim_create_autocmd("FileType", {
			group = M.autogroup,
			pattern = spec.ft,
			callback = function() M.load(spec.repo) end,
			once = true, -- we only need this to happen once
		})
	end
end

-- Register events which will trigger loading of the plugin
---@param spec tlj.Plugin
M.register_events = function(spec)
	if spec.events then
		vim.api.nvim_create_autocmd(spec.events, {
			group = M.autogroup,
			pattern = spec.pattern or "*",
			callback = function() M.load(spec.repo) end,
			once = true, -- we only need this to happen once
		})
	end
end

---@param arg string|tlj.Plugin
---@return tlj.Plugin
M.add = function(arg)
	local defaults = { auto_install = true }

	-- argument can be either just the repo path, or the
	-- full spec, so let's handle both.
	local spec = normalize_spec(arg)
	spec = vim.tbl_extend("force", defaults, spec)

	-- If repo is already registered, then ignore it
	if M.plugins[spec.repo] then return spec end

	M.plugins[spec.repo] = spec

	if spec.requires and type(spec.requires) == "table" then
		for _, req in ipairs(spec.requires) do
			M.add(req)
		end
	end

	M.register_cmds(spec)
	M.register_keys(spec)
	M.register_events(spec)
	M.register_ft(spec)

	-- -- Register plugins which will trigger the loading of this plugin
	register_after(spec)

	return spec
end

---@param repo string
---@return string
local function get_repo_require_path(repo)
	local name = repo:match("[^/]+$")
	return name:gsub("%.lua$", ""):gsub("%.nvim$", "")
end

M.debug = function(msg)
	-- if config.config.debug then vim.notify(msg, "info", { title = "Graft Debug" }) end
	if config.config.debug then vim.print(msg) end
end

-- Register keys which will load the plugin and trigger an action
---@param spec tlj.Plugin
M.register_keys = function(spec)
	if not spec.keys then return end

	for key, _ in pairs(spec.keys) do
		local callback = function()
			vim.keymap.del("n", key)
			M.load(spec.repo)
			local keys = vim.api.nvim_replace_termcodes(key, true, true, true)
			vim.api.nvim_feedkeys(keys, "m", false)
		end

		vim.keymap.set("n", key, callback, {})
	end
end

---@param repo string
M.load = function(repo)
	-- Don't load again if already loaded
	if M.loaded[repo] then return end
	M.loaded[repo] = vim.tbl_count(M.loaded) + 1

	---@type tlj.Plugin
	local spec = M.plugins[repo]
	if not spec then
		vim.notify("Did not find a registered repo " .. repo)
		return
	end

	benchmark.start_timer("load " .. repo)
	M.debug("Loading " .. repo .. ": " .. vim.inspect(spec.requires))

	-- If this plugin is not installed yet, let's just skip it
	if vim.fn.isdirectory(git.path(repo)) == 0 then
		if spec.auto_install then
			local success = M.install(repo)
			if not success then
				benchmark.stop_timer("load " .. repo)
				return
			end
		else
			benchmark.stop_timer("load " .. repo)
			return
		end
	end

	for _, req in ipairs(spec.requires or {}) do
		local req_spec = normalize_spec(req)
		M.debug(" * Requires " .. req_spec.repo)
		M.load(req_spec.repo)
	end

	-- Add the package to Neovim
	vim.cmd("packadd " .. git.repo_dir(repo))

	-- Run setup function if it exists
	if spec.setup and type(spec.setup) == "function" then
		M.debug(" * Running setup() on " .. spec.repo .. ".")
		spec.setup(spec.settings or {})
	else
		-- Let's just make a guess at the correct setup name
		local require_path = get_repo_require_path(spec.repo)
		local ok, p = pcall(require, require_path)
		if ok and type(p.setup) == "function" then
			p.setup(spec.settings or {})
		else
			M.debug(" * Failed calling setup() on " .. spec.repo .. ". require passed: " .. vim.inspect(ok) .. ". path " .. require_path)
		end
	end

	-- Setup keymaps from config
	for key, opts in pairs(spec.keys or {}) do
		M.debug(" * Setting keymap " .. key)
		vim.keymap.set("n", key, opts.cmd, { desc = opts.desc or "", noremap = false, silent = true })
	end

	if M.installed[spec.repo] then
		if spec.build then
			if spec.build:match("^:") ~= nil then
				M.debug(" * Building with nvim command " .. spec.build)
				vim.cmd(spec.build)
			else
				M.debug(" * Building with system command " .. spec.build)
				local prev_dir = vim.fn.getcwd()
				vim.cmd("cd " .. git.path(repo))
				vim.fn.system(spec.build)
				vim.cmd("cd " .. prev_dir)
			end
		end
	end

	-- Trigger an event saying plugin is loaded, so other plugins
	-- which are waiting for us can trigger.
	vim.api.nvim_exec_autocmds("User", { pattern = spec.repo })

	benchmark.stop_timer("load " .. repo)
end

local function url(repo) return "https://github.com/" .. repo end

-- Check if a tag matches a version constraint
---@param tag string The git tag to check
---@param version string The version constraint
---@return boolean
local function matches_version(tag, version) return require("graft.git").matches_constraint(tag, version) end

-- Get the appropriate git ref based on version constraint
---@param repo string The repository
---@param version? string The version constraint
---@return string? ref The git ref to use
local function get_version_ref(repo, version)
	if not version or version == "*" then
		return nil -- Use default branch
	end

	-- Try exact tag/branch first
	local cmd = { "ls-remote", "--refs", url(repo) }
	local success, output = git.run(cmd)
	if not success then return nil end

	local refs = {}
	for _, line in ipairs(output) do
		local hash, ref = line:match("([%x]+)%s+(.+)")
		if hash and ref then refs[ref] = hash end
	end

	-- Check for exact tag match
	if refs["refs/tags/" .. version] then return version end

	-- Check for matching version prefix in tags
	local matching_tags = {}
	for ref, _ in pairs(refs) do
		local tag = ref:match("^refs/tags/(.+)$")
		if tag and matches_version(tag, version) then table.insert(matching_tags, tag) end
	end

	-- Sort tags to get the latest matching version
	table.sort(matching_tags, function(a, b)
		-- This is a simple version comparison, might need to be more sophisticated
		return a > b
	end)

	return matching_tags[1] or version
end

-- Update status in neovim without user input
---@param msg string
local function show_status(msg)
	vim.cmd.redraw()
	vim.cmd.echo("'" .. msg .. "'")
end

-- Ensure plugin is installed
---@param repo string
---@return boolean
M.install = function(repo)
	benchmark.start_timer("install " .. repo)
	vim.fn.mkdir(config.config.root_dir .. "/" .. config.config.pack_dir, "p")
	if vim.fn.isdirectory(git.path(repo)) == 0 then
		installed = installed + 1
		show_status(string.format("[%d/%d] Installing plugin %s...", installed, to_install, repo))

		local version_ref = get_version_ref(repo, M.plugins[repo].version)
		local cmd = {}
		if config.config.submodules then
			cmd = { "submodule", "add", "-f" }
			if version_ref then cmd = vim.list_extend(cmd, { "-b", version_ref }) end
			cmd = vim.list_extend(cmd, { url(repo), git.pack_dir(repo) })
		else
			cmd = { "clone", "--depth", "1" }
			if version_ref then cmd = vim.list_extend(cmd, { "-b", version_ref }) end
			cmd = vim.list_extend(cmd, { url(repo), git.pack_dir(repo) })
		end

		local success, output = git.run(cmd)
		if not success then
			local hasnotify, notify = pcall(require, "notify")
			if hasnotify then
				notify(vim.list_extend({ repo .. ": Error: " }, output), "error", { title = "Plugins", timeout = 5000 })
			else
				vim.notify("Error installing " .. repo .. ".")
			end
			benchmark.stop_timer("install " .. repo)
			return false
		end

		M.installed[repo] = true
	end

	benchmark.stop_timer("install " .. repo)
	return true
end

---@param dir string The repo directory to remove
M.uninstall = function(dir)
	show_status(string.format("Uninstalling %s...", dir))

	if config.config.submodules then
		git.run({ "submodule", "deinit", "-f", dir })
		git.run({ "rm", "-f", dir })
	else
		local rmdir = config.config.root_dir .. "/" .. dir
		vim.notify("Removing " .. rmdir)
		vim.fn.delete(rmdir, "rf")
	end
end

M.update_all = function()
	for repo, _ in pairs(M.plugins) do
		M.update(repo)
	end
end

M.update = function(repo, callbacks)
	if config.config.submodules then
		-- TODO: Add submodules support
	else
		callbacks = callbacks or {}
		local spec = M.plugins[repo]

		git.update(git.path(repo), spec.version, {
			async = true,
			on_success = callbacks.on_success,
			on_failure = callbacks.on_failure,
		})
	end
end

-- Remove any plugins in our pack_dir which are not defined in our list of plugins
M.cleanup = function()
	benchmark.start_timer("cleanup")
	local desired = {}
	for _, spec in pairs(M.plugins) do
		local dir = git.pack_dir(spec.repo)
		if dir ~= nil then table.insert(desired, dir) end
	end

	local full_pack_dir = config.config.root_dir .. "/" .. config.config.pack_dir
	if vim.fn.isdirectory(full_pack_dir) == 1 then
		local handle = vim.loop.fs_scandir(full_pack_dir)
		if handle then
			while true do
				local name, ftype = vim.loop.fs_scandir_next(handle)
				if not name then break end
				if ftype == "directory" then
					local dir = config.config.pack_dir .. name
					if not vim.tbl_contains(desired, dir) then M.uninstall(dir) end
				end
			end
		end
	end
	benchmark.stop_timer("cleanup")
end

---@param arg string|tlj.Plugin
M.opt = function(arg) M.add(arg) end

---@param arg string|tlj.Plugin
M.start = function(arg)
	local spec = M.add(arg)

	if spec.repo ~= nil and spec.repo ~= "" then
		table.insert(M.root_plugins, spec.repo)
		M.load(spec.repo)
	end
end

M.sync = function()
	vim.schedule(function()
		for _, repo in pairs(M.root_plugins) do
			if vim.fn.isdirectory(git.path(repo)) == 0 then to_install = to_install + 1 end
		end

		-- for _, repo in pairs(M.root_plugins) do
		-- 	local spec = M.plugins[repo]
		-- 	if not spec.after then M.load(repo) end
		-- end

		benchmark.start_timer("helptags")
		vim.cmd("helptags ALL")
		benchmark.stop_timer("helptags")

		M.cleanup()
	end)
end

M.setup = function(opts)
	config.setup(opts)

	for _, p in ipairs(config.config.start) do
		M.start(p)
	end

	for _, p in ipairs(config.config.opt) do
		M.opt(p)
	end

	if config.config.install then
		for repo, _ in pairs(M.plugins) do
			M.install(repo)
		end
	end

	vim.api.nvim_create_user_command("GraftUpdate", function() require("graft").update_all() end, {})
	vim.api.nvim_create_user_command("GraftSync", function() require("graft").sync() end, {})
	vim.api.nvim_create_user_command("GraftTimings", function() require("graft.ui").show_timings() end, {})
	vim.api.nvim_create_user_command("GraftInfo", function() require("graft.ui").show_plugin_info() end, {})

	vim.api.nvim_create_autocmd("VimEnter", {
		group = M.autogroup,
		callback = M.sync,
		once = true,
	})
end

---@param name string
---@return string
local function normalize_require_name(name)
	-- First remove .lua or .nvim extension if present
	name = name:gsub("%.lua$", ""):gsub("%.nvim$", "")
	-- Then replace remaining dots with dashes
	name = name:gsub("%.", "-")
	return name
end

-- Include a spec file with a plugin definition
---@param repo string
M.include = function(repo)
	-- change the slash to -- for filename
	local f = git.repo_dir(repo)
	-- remove extension and add the load path
	local fp = "config/plugins/" .. normalize_require_name(f)

	-- try to load it
	local hasspec, spec = pcall(require, fp)
	if not hasspec then
		vim.notify("Could not include " .. fp .. ".lua", vim.log.levels.ERROR)
		return
	end

	return spec
end

return M
