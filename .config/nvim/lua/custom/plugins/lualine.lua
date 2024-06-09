return {
	"nvim-lualine/lualine.nvim",
	opts = {},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	setup = function()
		require("lualine").setup({})
	end,
}
