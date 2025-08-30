-- paths to check for project.godot file
local paths_to_check = { "/", "/../" }
local is_godot_project = false
local godot_project_path = ""
local cwd = vim.fn.getcwd()

-- iterate over paths and check
if vim.uv.fs_stat(cwd .. "project.godot") then
	is_godot_project = true
	godot_project_path = cwd
end

-- check if server is already running in godot project path
local is_server_running = vim.uv.fs_stat(godot_project_path .. "/neovim.pipe")
-- start server, if not already running
if is_godot_project and not is_server_running then vim.fn.serverstart(godot_project_path .. "/neovim.pipe") end
