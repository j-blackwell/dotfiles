return {
	"folke/flash.nvim",
	vscode = true,
	event = "VeryLazy",
	opts = {
		modes = {
			search = { enabled = true },
		},
		rainbow = {
			enabled = true,
			shade = 5,
		},
		highlight = {
			backdrop = true,
			groups = {
				match = "FlashMatch",
				current = "FlashCurrent",
				backdrop = "FlashBackdrop",
				label = "FlashLabel",
			},
		},
	},
	keys = {
		{
			"S",
			mode = { "n", "x", "o" },
			function()
				require("flash").treesitter()
			end,
			desc = "Flash Treesitter",
		},
		{
			"r",
			mode = "o",
			function()
				require("flash").remote()
			end,
			desc = "Remote Flash",
		},
		{
			"R",
			mode = { "o", "x" },
			function()
				require("flash").treesitter_search()
			end,
			desc = "Treesitter Search",
		},
		{
			"<c-s>",
			mode = { "c" },
			function()
				require("flash").toggle()
			end,
			desc = "Toggle Flash Search",
		},
	},
	config = function(_, opts)
		-- Apply highlight groups
		vim.api.nvim_command("hi clear FlashMatch")
		vim.api.nvim_command("hi clear FlashCurrent")
		vim.api.nvim_command("hi clear FlashLabel")

		vim.api.nvim_command("hi FlashMatch guibg=#4A47A3 guifg=#B8B5FF")
		vim.api.nvim_command("hi FlashCurrent guibg=#456268 guifg=#D0E8F2")
		vim.api.nvim_command("hi FlashLabel guibg=#c9366b guifg=#EEF5FF")

		-- Properly initialize flash.nvim
		require("flash").setup(opts)
	end,
}
