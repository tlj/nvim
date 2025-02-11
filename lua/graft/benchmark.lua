local M = {
	timings = {},
	start_times = {},
}

M.start_timer = function(label) M.start_times[label] = vim.loop.hrtime() end

M.stop_timer = function(label)
	local elapsed = (vim.loop.hrtime() - M.start_times[label]) / 1000000 -- Convert to milliseconds
	M.timings[label] = elapsed
end

return M
