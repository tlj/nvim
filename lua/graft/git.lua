local M = {}

local config = require("graft.config")

M.parse_git_result = function(obj)
	local output = {}
	local stdout = obj.stdout .. "\n" .. obj.stderr

	for line in stdout:gmatch("[^\n]+") do
		output[#output + 1] = line
	end

	return obj.code == 0, output
end

---@param args string[]
M.run = function(args, opts)
	local defaults = { root_dir = config.config.root_dir, async = false }
	opts = vim.tbl_deep_extend("force", defaults, opts or {})

	local cmd = { "git", "-C", opts.root_dir }

	vim.list_extend(cmd, args)

	if opts.async then
		vim.system(cmd, { text = true }, function(obj)
			local success, output = M.parse_git_result(obj)
			if success and type(opts.on_success) == "function" then opts.on_success(output) end
			if not success and type(opts.on_failure) == "function" then opts.on_failure(output) end
		end)
	else
		-- For non-async calls, we need to handle them differently in fast events
		if vim.in_fast_event() then
			vim.system(cmd, { text = true }, function(obj)
				local success, output = M.parse_git_result(obj)
				if success and type(opts.on_success) == "function" then opts.on_success(output) end
				if not success and type(opts.on_failure) == "function" then opts.on_failure(output) end
			end)
		else
			local result = vim.system(cmd, { text = true }, nil):wait()
			return M.parse_git_result(result)
		end
	end
end

---@param repo string
---@return string
M.repo_dir = function(repo)
	local dir = repo:gsub("/", "%-%-"):lower()
	return dir
end

---@param repo string
---@return string
M.pack_dir = function(repo) return config.config.pack_dir .. M.repo_dir(repo) end

---@param repo string
---@return string
M.path = function(repo) return config.config.root_dir .. "/" .. M.pack_dir(repo) end

-- Parse version string into components
M.parse_version = function(version)
	-- Remove 'v' prefix if present
	version = version:gsub("^v", "")
	local major, minor, patch, prerelease = version:match("(%d+)%.?(%d*)%.?(%d*)%-?([%w.]*)")
	return {
		major = tonumber(major) or 0,
		minor = tonumber(minor) or 0,
		patch = tonumber(patch) or 0,
		prerelease = prerelease or "",
	}
end

-- Compare two version strings
-- Returns true if v1 is greater than v2
M.compare_versions = function(v1, v2)
	local ver1 = M.parse_version(v1)
	local ver2 = M.parse_version(v2)

	-- Compare major.minor.patch
	if ver1.major ~= ver2.major then return ver1.major > ver2.major end
	if ver1.minor ~= ver2.minor then return ver1.minor > ver2.minor end
	if ver1.patch ~= ver2.patch then return ver1.patch > ver2.patch end

	-- If one has a prerelease and the other doesn't, the one without is greater
	if ver1.prerelease == "" and ver2.prerelease ~= "" then return true end
	if ver1.prerelease ~= "" and ver2.prerelease == "" then return false end

	-- If both have prereleases, compare them lexicographically
	return ver1.prerelease > ver2.prerelease
end

-- Check if a version matches a constraint
-- @param version string The version to check
-- @param constraint string The version constraint
-- @return boolean Whether the version matches the constraint
M.matches_constraint = function(version, constraint)
	if not constraint or constraint == "*" then return true end

	-- Exact match
	if version == constraint then return true end

	-- Remove 'v' prefix for comparison
	version = version:gsub("^v", "")
	constraint = constraint:gsub("^v", "")

	local v = M.parse_version(version)
	local c = M.parse_version(constraint)

	-- If constraint is just a major version (e.g., "2")
	if constraint:match("^%d+$") then return v.major == c.major and v.minor >= c.minor end

	-- If constraint is major.minor (e.g., "2.9")
	if constraint:match("^%d+%.%d+$") then return v.major == c.major and v.minor >= c.minor end

	-- If constraint is major.minor.patch (e.g., "2.9.0")
	if constraint:match("^%d+%.%d+%.%d+") then return v.major == c.major and v.minor >= c.minor and v.patch >= c.patch end

	return false
end

-- Get the newest available tag for a repo that matches the version constraint
-- @param package_dir string The repository path
-- @param version_constraint string Version constraint (prefix) or "*" for any version
-- @return string|nil The newest matching tag or nil if no matches found
M.get_newest_matching_tag = function(package_dir, version_constraint)
	if not version_constraint or version_constraint == "*" then
		-- Get all tags
		local success, tags = M.run({ "tag", "-l" }, { root_dir = package_dir })
		if not success or #tags == 0 then return nil end

		-- Sort tags by version and return newest
		table.sort(tags, function(a, b) return M.compare_versions(a, b) end)
		return tags[#tags]
	end

	-- Try exact tag/branch first
	local success, tags = M.run({ "tag", "-l" }, { root_dir = package_dir })
	if not success then return nil end

	-- Check for exact tag match
	for _, tag in ipairs(tags) do
		if tag == version_constraint then return tag end
	end

	-- Filter matching tags
	local matching_tags = {}
	for _, tag in ipairs(tags) do
		if M.matches_constraint(tag, version_constraint) then table.insert(matching_tags, tag) end
	end

	-- Sort matching tags by version
	table.sort(matching_tags, function(a, b) return M.compare_versions(a, b) end)

	-- Return the newest (last) matching tag
	return matching_tags[1]
end

---@param path string The path to the git repository
---@param version? string Optional version constraint
---@param opts? {async?: boolean, on_success?: function, on_failure?: function} Optional configuration
M.update = function(path, version, opts)
	opts = opts or {}

	if version and version ~= "*" then
		-- For versioned plugins, fetch and checkout the specific version
		if opts.async then
			-- Get all tags using M.run for consistency
			local newest_matching_tag = M.get_newest_matching_tag(path, version)
			local checkout_version = newest_matching_tag or version
			M.run({ "checkout", checkout_version }, {
				root_dir = path,
				async = true,
				on_success = function(output)
					if opts.on_success then opts.on_success(output) end
					vim.schedule(function() vim.notify(path .. " updated to " .. checkout_version) end)
				end,
				on_failure = opts.on_failure,
			})
		else
			-- Synchronous version
			local success = M.run({ "fetch", "--tags" }, { root_dir = path })
			if not success then return false end

			local success2, tags = M.run({ "tag", "-l" }, { root_dir = path })
			if not success2 then return false end
			local newest_matching_tag = M.find_newest_matching_tag(tags, version)
			return M.run({ "checkout", newest_matching_tag or version }, { root_dir = path })
		end
	else
		-- For non-versioned plugins, just pull
		if opts.async then
			M.run({ "pull", "--no-rebase" }, {
				root_dir = path,
				async = true,
				on_success = function(output)
					local updated = true
					for _, line in ipairs(output) do
						if line == "Already up to date." then updated = false end
					end
					if updated then vim.schedule(function() vim.notify(path .. " updated.") end) end
					if opts.on_success then opts.on_success(output) end
				end,
				on_failure = function(output)
					vim.schedule(
						function()
							vim.notify(path .. ": Error:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR, {
								title = "Plugins",
								timeout = 5000,
							})
						end
					)
					if opts.on_failure then opts.on_failure(output) end
				end,
			})
		else
			-- Synchronous version
			return M.run({ "pull", "--ff-only" }, { root_dir = path })
		end
	end
end

return M
