return {
	"linux-cultist/venv-selector.nvim",
	branch = "regexp",
	cmd = "VenvSelect",
	opts = function(_, opts)
		return vim.tbl_deep_extend("force", opts, {
			name = {
				"venv",
				".venv",
				"env",
				".env",
			},
		})
	end,
	keys = { { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select [V]irtualEnv", ft = "python" } },
}
