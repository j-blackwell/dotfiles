return {
	"nvim-telescope/telescope.nvim",
	keys = {
		{
			"<leader>ff",
			function()
				require("telescope.builtin").find_files()
			end,
			desc = "[F]ind [F]iles",
		},
		{
			"<leader>fd",
			function()
				require("telescope.builtin").find_files({
					prompt_title = "Search for dotfiles or .config files",
					cwd = vim.fn.getcwd(),
					find_command = { "rg", "--files", "--hidden", "--glob", ".*", "--glob", "**/.config/**" },
					file_ignore_patterns = {},
					no_ignore = true,
				})
			end,
			desc = "[F]ind [d]otfiles or .config files",
		},
		{
			"<leader>ft",
			function()
				require("telescope.builtin").find_files({
					prompt_title = "Search for tmp_local files",
					cwd = string.format("%s/tmp_local", vim.fn.getcwd()),
					file_ignore_patterns = {},
					no_ignore = true,
				})
			end,
			desc = "[F]ind [t]mp_local files",
		},
		{
			"<leader>fT",
			function()
				require("telescope.builtin").find_files({
					prompt_title = "Search for tmp_local/storage_assets files",
					cwd = string.format("%s/tmp_local/storage_assets", vim.fn.getcwd()),
					file_ignore_patterns = {},
					no_ignore = true,
				})
			end,
			desc = "[F]ind [T]mp_local/storage_assets files",
		},
		{
			"<leader>fp",
			function()
				require("telescope.builtin").find_files({
					prompt_title = "Search for playground files",
					cwd = string.format("%s/playground", vim.fn.getcwd()),
					file_ignore_patterns = {},
					no_ignore = true,
				})
			end,
			desc = "[F]ind [p]layground files",
		},
		{
			"<leader>fs",
			function()
				require("telescope.builtin").find_files({
					prompt_title = "Search for nvim swap files",
					cwd = string.format("~/.local/share/nvim/swap"),
					file_ignore_patterns = {},
					no_ignore = true,
				})
			end,
			desc = "[F]ind nvim [s]wap files",
		},
	},
}
