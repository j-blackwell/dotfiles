vim.api.nvim_create_autocmd("RecordingEnter", {
	group = vim.api.nvim_create_augroup("macro-status-line", { clear = true }),
	callback = function()
		local recording = vim.fn.reg_recording()
		local buf = vim.api.nvim_get_current_buf()
		local file = vim.api.nvim_buf_get_name(buf)
		local msg = "Recording macro [" .. recording .. "]"
		vim.notify(msg)
	end,
})
vim.api.nvim_create_autocmd("RecordingLeave", {
	group = "macro-status-line",
	callback = function()
		vim.notify("Recording macro stopped")
	end,
})
