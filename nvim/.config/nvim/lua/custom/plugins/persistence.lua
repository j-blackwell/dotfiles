return {
	"folke/persistence.nvim",
	event = "VimEnter",
	config = function()
		require("persistence").setup({
			dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"),
			options = { "buffers", "curdir", "tabpages", "winsize" },
		})
	end,
	keys = {
		{
			"<leader>qs",
			[[<cmd>lua require("persistence").load()<cr>]],
			desc = "Restore the [s]aved session for the current directory",
		},
		{
			"<leader>ql",
			[[<cmd>lua require("persistence").load({ last = true })<cr>]],
			desc = "Restore the [l]ast session",
		},
		{
			"<leader>qd",
			[[<cmd>lua require("persistence").stop()<cr>]],
			desc = "Stop Persistence => [d]on't save the session on exit",
		},
	},
	init = function()
		-- Only restore the session when nvim is opened without file arguments
		if vim.fn.argc(-1) == 0 then
			require("persistence").load()
		end
	end,
}
