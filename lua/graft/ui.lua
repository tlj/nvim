local M = {}

local git = require("graft.git")
local graft = require("graft")

local show_details = false

-- Status indicators for updates
M.update_status = {
	unchecked = " ", -- Initial state, not checked yet
	checking = "󰑮", -- Currently checking for updates
	pending = "󰇚", -- Update is available
	updating = "󰑮", -- Currently updating
	success = "󰄬", -- Up to date
	error = "󰅚", -- Error occurred
}

-- Store update statuses
M.updates = {}

local function setup_syntax(bufnr)
	-- Clear existing syntax for the specific buffer
	vim.api.nvim_buf_clear_namespace(bufnr, 0, 0, -1)

	-- Define syntax matches for the specific buffer
	local syntax_cmds = {
		["GraftPluginNumber"] = [[\v^\#\d+]],
		["GraftRepoName"] = [[\v\S+/\S+]], -- Match any non-whitespace before and after /
		["GraftLoadTime"] = [[\v\d+\.\d+ms]],
		["GraftGitHash"] = [[\v[a-f0-9]{7}]],
		["GraftGitDate"] = [[\v\d{4}-\d{2}-\d{2}]],
		["GraftVersion"] = [[\vv:[^\s]+]], -- Match version tags
		["GraftRef"] = [[\vref:[^\s]+]], -- Match ref names
		["GraftDepsTree"] = [[\v└─]],
		["GraftDepsLabel"] = [[\v(after|required by):]],
	}

	-- Create a new namespace for our matches
	-- local ns_id = vim.api.nvim_create_namespace("graft_syntax")

	-- Add the matches using the new API
	for group, pattern in pairs(syntax_cmds) do
		vim.fn.matchadd(group, pattern)
	end

	-- Set highlights using gruvbox-baby colors
	local colors = {
		forest_green = "#a9b665",
		soft_yellow = "#d8a657",
		light_blue = "#7daea3",
		clean_green = "#89b482",
		orange = "#e78a4e",
		medium_gray = "#7c6f64",
		light_red = "#ea6962",
	}

	-- Link to custom highlight groups with gruvbox-baby colors
	vim.api.nvim_set_hl(0, "GraftPluginNumber", { fg = colors.light_blue, bold = true })
	vim.api.nvim_set_hl(0, "GraftRepoName", { fg = colors.forest_green })
	vim.api.nvim_set_hl(0, "GraftLoadTime", { fg = colors.orange })
	vim.api.nvim_set_hl(0, "GraftGitHash", { fg = colors.soft_yellow })
	vim.api.nvim_set_hl(0, "GraftGitDate", { fg = colors.clean_green })
	vim.api.nvim_set_hl(0, "GraftVersion", { fg = colors.forest_green, bold = true })
	vim.api.nvim_set_hl(0, "GraftRef", { fg = colors.orange, bold = true })
	vim.api.nvim_set_hl(0, "GraftDepsTree", { fg = colors.medium_gray })
	vim.api.nvim_set_hl(0, "GraftDepsLabel", { fg = colors.light_red, bold = true })
end

local function build_reverse_deps()
	local reverse_deps = {}
	for repo, spec in pairs(graft.plugins) do
		if spec.requires then
			for _, req in ipairs(spec.requires) do
				local req_repo = type(req) == "string" and req or req.repo
				reverse_deps[req_repo] = reverse_deps[req_repo] or {}
				table.insert(reverse_deps[req_repo], repo)
			end
		end
	end
	return reverse_deps
end

function M.check_updates(plugin_path, repo, callback)
	local function check_version_update(cb)
		local spec = graft.plugins[repo]
		if not spec.version then
			cb(false)
			return
		end

		-- Get current tag
		vim.fn.jobstart({ "git", "-C", plugin_path, "describe", "--tags", "--exact-match" }, {
			stdout_buffered = true,
			on_stdout = function(_, current_tag)
				current_tag = current_tag and current_tag[1]

				-- Get all remote tags
				vim.fn.jobstart({ "git", "-C", plugin_path, "tag", "-l" }, {
					stdout_buffered = true,
					on_stdout = function(_, tags)
						if not tags then
							cb(false)
							return
						end

						local newest_matching_tag = git.get_newest_matching_tag(plugin_path, spec.version)

						-- Compare with current tag
						if
							newest_matching_tag
							and (not current_tag or (newest_matching_tag ~= current_tag and newest_matching_tag ~= current_tag:gsub("^v", "")))
						then
							-- Get the date of the new tag
							vim.fn.jobstart({ "git", "-C", plugin_path, "log", "-1", "--format=%cd", "--date=short", newest_matching_tag }, {
								stdout_buffered = true,
								on_stdout = function(_, date_output)
									local date = date_output and date_output[1] or ""
									cb(true, { type = "version", new_version = newest_matching_tag, date = date })
								end,
							})
						else
							cb(false)
						end
					end,
				})
			end,
		})
	end

	-- Run git fetch asynchronously
	vim.fn.jobstart({ "git", "-C", plugin_path, "fetch" }, {
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				vim.schedule(function() callback(false) end)
				return
			end

			if graft.plugins[repo].version then
				-- For version-constrained plugins, check for new matching tags
				check_version_update(callback)
			else
				-- For branch-following plugins, check if we're behind
				vim.fn.jobstart({ "git", "-C", plugin_path, "status", "-sb" }, {
					stdout_buffered = true,
					on_stdout = function(_, data)
						if data and data[1] and data[1]:match("behind") then
							-- Get the latest commit info
							vim.fn.jobstart({ "git", "-C", plugin_path, "log", "..@{u}", "-1", "--format=%h %cd", "--date=short" }, {
								stdout_buffered = true,
								on_stdout = function(_, commit_data)
									if commit_data and commit_data[1] then
										local hash, date = commit_data[1]:match("(%w+)%s+(.+)")
										vim.schedule(function() callback(true, { type = "commit", new_hash = hash, date = date }) end)
									else
										vim.schedule(function() callback(false) end)
									end
								end,
							})
						else
							vim.schedule(function() callback(false) end)
						end
					end,
					on_exit = function(_, exit_code)
						if exit_code ~= 0 then vim.schedule(function() callback(false) end) end
					end,
				})
			end
		end,
	})
end

M.show_plugin_info = function()
	local function get_git_info(repo, plugin_path)
		-- If plugin has a version constraint, show the current tag/version
		if graft.plugins[repo].version then
			-- Get all tags pointing to the current commit
			local success, output = git.run({ "tag", "--points-at", "HEAD" }, {
				root_dir = plugin_path,
			})

			if success and #output > 0 then
				-- Filter tags to match our version constraint
				local version_constraint = graft.plugins[repo].version
				for _, tag in ipairs(output) do
					-- If we have an exact version match, use it
					if tag == version_constraint then return "v:" .. tag end
					-- If we have a prefix match (e.g. v1 matches v1.2.3)
					if version_constraint ~= "*" and tag:find("^" .. version_constraint:gsub("%.", "%.")) then return "v:" .. tag end
				end
				-- If we didn't find a matching tag but have tags, show the first one
				return "v:" .. output[1]
			end

			-- If no exact tag, get the current ref name
			success, output = git.run({ "rev-parse", "--abbrev-ref", "HEAD" }, {
				root_dir = plugin_path,
			})
			if success and output[1] then
				return "ref:" .. output[1] -- Prefix with ref: to indicate branch/ref
			end
		end

		-- Default behavior for branch-following plugins
		local success, output = git.run({ "log", "-1", "--format=%h %cd", "--date=short" }, {
			root_dir = plugin_path,
		})
		if success and output[1] then return output[1] end
		return "No git info available"
	end

	local function create_plugin_info()
		local output = {}
		local sorted = {}
		local rev_deps = build_reverse_deps()
		local benchmark = require("graft.benchmark")

		-- Clear any existing update status when recreating the window
		-- M.updates = {}

		for repo, spec in pairs(graft.plugins) do
			local plugin_path = git.path(repo)
			if vim.fn.isdirectory(plugin_path) == 1 then
				local git_info = get_git_info(repo, plugin_path)
				local load_time = benchmark.timings["load " .. repo] or 0

				local after_deps = spec.after and "after: " .. table.concat(spec.after, ", ") or nil
				local required_by = rev_deps[repo] and "required by: " .. table.concat(rev_deps[repo], ", ") or nil

				table.insert(sorted, {
					repo = repo,
					time = load_time,
					git_info = git_info,
					after_deps = after_deps,
					required_by = required_by,
					load_order = graft.loaded[repo] or math.huge,
				})
			end
		end

		table.sort(sorted, function(a, b) return a.load_order < b.load_order end)

		-- Calculate max lengths for column alignment
		local max_repo_length = 0
		for _, item in ipairs(sorted) do
			max_repo_length = math.max(max_repo_length, #item.repo)
		end
		max_repo_length = max_repo_length + 2

		-- Add header
		local header = string.format(" %-50s  %8s  %-32s  %-27s", "Repo", "Time", "Current", "Update")
		table.insert(output, header)
		-- Add separator line
		table.insert(output, string.rep("─", #header + 2))

		for _, item in ipairs(sorted) do
			local update_data = M.updates[item.repo]
			local status = type(update_data) == "table" and update_data.status or update_data
			local status_indicator = M.update_status[status or "unchecked"]

			-- Format current version/hash info
			local current_info = item.git_info
			if current_info:match("^v:") then
				-- For version-controlled plugins
				current_info = current_info:gsub("^v:", "")
			elseif current_info:match("^ref:") then
				-- For ref-controlled plugins
				current_info = current_info:gsub("^ref:", "")
			else
				-- For commit hash + date format
				local hash, date = current_info:match("(%w+)%s+(.+)")
				if hash and date then current_info = string.format("%s (%s)", hash, date) end
			end

			-- Format update info (if available)
			local update_info = "─"
			if type(M.updates[item.repo]) == "table" then
				if update_data.status == "pending" then
					if update_data.type == "version" then
						update_info = update_data.new_version .. " (" .. update_data.date .. ")"
					elseif update_data.type == "commit" then
						update_info = update_data.new_hash .. " (" .. update_data.date .. ")"
					end
				elseif update_data.status == "updating" then
					update_info = "Updating..."
				elseif update_data.status == "error" then
					update_info = "Update failed"
				end
			end

			-- Truncate repo name if it's too long
			local repo_display = item.repo
			if #repo_display > 50 then repo_display = "..." .. repo_display:sub(-47) end

			-- Truncate current_info if it's too long
			if #current_info > 32 then current_info = current_info:sub(1, 29) .. "..." end

			-- Truncate update_info if it's too long
			if #update_info > 27 then update_info = update_info:sub(1, 24) .. "..." end

			local base_info =
				string.format("%s %-50s  %6.2fms  %-32s  %-27s", status_indicator, repo_display, item.time, current_info, update_info)
			table.insert(output, " " .. base_info)

			if show_details then
				if item.after_deps then table.insert(output, "     └─ " .. item.after_deps) end
				if item.required_by then table.insert(output, "     └─ " .. item.required_by) end
			end
		end

		return output, max_repo_length
	end

	local function refresh_window(buf, win)
		local output, max_repo_length = create_plugin_info()
		-- Calculate minimum required width for each column
		local time_col = 10 -- "  Time  " column
		local status_col = 2 -- Status indicator
		local update_col = 30 -- Update status column
		local current_col = 35 -- Current version/hash info
		local padding = 8 -- Extra padding for spacing and borders

		-- Calculate available width
		local max_available_width = vim.o.columns - 4
		local min_repo_width = 30 -- Minimum width for repo column

		-- Calculate ideal repo column width (with truncation if needed)
		local repo_col = math.min(max_repo_length, 50) -- Cap repo column at 50 chars

		-- Calculate total width
		local width = math.min(repo_col + time_col + status_col + update_col + current_col + padding, max_available_width)

		-- Ensure minimum reasonable width
		width = math.max(width, 100)
		local height = math.min(#output, math.floor(vim.o.lines * 0.8))

		-- Update window size and position
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		vim.api.nvim_win_set_config(win, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
		})

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
		vim.bo[buf].modifiable = false
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local output, max_repo_length = create_plugin_info()
	local width = math.min(math.max(80, max_repo_length + 50), vim.o.columns - 4)
	local height = math.min(#output, math.floor(vim.o.lines * 0.8))
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Plugin Information ",
		title_pos = "center",
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)

	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "graft-info"
	vim.wo[win].wrap = false

	-- Set up keymaps
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
	vim.keymap.set("n", "r", function()
		-- Only proceed if the window still exists
		if not vim.api.nvim_win_is_valid(win) then return end

		-- Reset all update statuses and start checking
		M.updates = {}
		for repo, _ in pairs(graft.plugins) do
			local plugin_path = git.path(repo)
			if vim.fn.isdirectory(plugin_path) == 1 then M.updates[repo] = { status = "checking" } end
		end

		-- Show initial checking status
		refresh_window(buf, win)

		-- Start checking updates
		for repo, _ in pairs(M.updates) do
			local plugin_path = git.path(repo)
			M.check_updates(plugin_path, repo, function(needs_update, update_info)
				if vim.api.nvim_win_is_valid(win) then
					if needs_update then
						M.updates[repo] = vim.tbl_extend("force", update_info, { status = "pending" })
					else
						M.updates[repo] = { status = "success" }
					end
					refresh_window(buf, win)
				end
			end)
		end
	end, { buffer = buf, silent = true, desc = "Check for updates" })

	vim.keymap.set("n", "U", function()
		-- Update all plugins that need updates
		for repo, update_data in pairs(M.updates) do
			if type(update_data) == "table" and update_data.status == "pending" then
				M.updates[repo] = { status = "updating" }
				refresh_window(buf, win)

				graft.update(repo, {
					on_success = function()
						M.updates[repo] = { status = "success" }
						vim.schedule(function() refresh_window(buf, win) end)
					end,
					on_failure = function()
						M.updates[repo] = { status = "error" }
						vim.schedule(function() refresh_window(buf, win) end)
					end,
				})
			end
		end
	end, { buffer = buf, silent = true, desc = "Update all plugins" })
	-- Add toggle details keybinding
	vim.keymap.set("n", "d", function()
		if vim.api.nvim_win_is_valid(win) then
			show_details = not show_details
			refresh_window(buf, win)
		end
	end, { buffer = buf, silent = true, desc = "Toggle details" })

	setup_syntax(buf)

	-- Add syntax highlighting for status indicators
	vim.cmd([[
		syn match GraftHeader /\v^[ ](Repo|Time|Current|Update)/ contained containedin=.*
		syn match GraftHeaderLine /\v^[ ]─+$/ contained containedin=.*
		syn match GraftStatusUnchecked / / contained containedin=.*
		syn match GraftStatusChecking /󰑮/ contained containedin=.*
		syn match GraftStatusPending /󰇚/ contained containedin=.*
		syn match GraftStatusUpdating /󰑮/ contained containedin=.*
		syn match GraftStatusSuccess /󰄬/ contained containedin=.*
		syn match GraftStatusError /󰅚/ contained containedin=.*
		
		hi GraftHeader guifg=#7dcfff gui=bold
		hi GraftHeaderLine guifg=#565f89
		hi GraftStatusUnchecked guifg=#565f89
		hi GraftStatusChecking guifg=#7aa2f7
		hi GraftStatusPending guifg=#e0af68
		hi GraftStatusUpdating guifg=#7aa2f7
		hi GraftStatusSuccess guifg=#9ece6a
		hi GraftStatusError guifg=#f7768e
		hi GraftStatusPending guifg=#e0af68
		hi GraftStatusUpdating guifg=#7aa2f7
		hi GraftStatusSuccess guifg=#9ece6a
		hi GraftStatusError guifg=#f7768e
	]])
end

return M
