return {
	{
		"nvim-telescope/telescope.nvim",
		keys = {
			{
				"<leader>sf",
				function()
					require("telescope.builtin").find_files({
						prompt_title = "Find Files (Deprioritize Tests)",
						cwd = vim.fn.getcwd(),
						find_command = {
							"rg",
							"--files",
							"--sort",
							"path", -- Ensures a natural ordering (alphabetical, depth-based)
						},
						file_ignore_patterns = { "^tests/" }, -- Soft-ignore tests (pushed to the bottom)
					})
				end,
				desc = "[S]earch [F]iles",
			},
			{
				"<leader>fd",
				function()
					require("telescope.builtin").find_files({
						prompt_title = "Search for dotfiles or .config files",
						cwd = vim.fn.getcwd(),
						find_command = {
							"rg",
							"--files",
							"--hidden",
							"--no-ignore",
							"--glob",
							".*", -- Include dotfiles
							"--glob",
							"**/.*/**", -- Include .config directories
							"--glob",
							"!.git/*", -- Exclude .git directory
						},
					})
				end,
				desc = "[F]ind [d]otfiles or .config files",
			},
			{
				"<leader>sG",
				function()
					local telescope = require("telescope.builtin")
					local vimgrep_arguments = { unpack(require("telescope.config").values.vimgrep_arguments) }

					-- Add extra arguments for hidden files & dot directories
					vim.list_extend(vimgrep_arguments, {
						"--hidden",
						"--no-ignore",
						"--glob",
						"!.git/*", -- Exclude .git directory
						"--glob",
						".*", -- Include dotfiles
						"--glob",
						"**/.*/**", -- Include files inside hidden directories
					})

					telescope.live_grep({
						prompt_title = "Grep in dotfiles & hidden directories",
						cwd = vim.fn.getcwd(),
						vimgrep_arguments = vimgrep_arguments,
					})
				end,
				desc = "[s]earch using [G]rep in dotfiles or .config files",
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
						cwd = string.format("~/.local/state/nvim/swap"),
						find_command = { "rg", "--files", "--hidden", "--glob", ".*", "--glob", "**/.config/**" },
						file_ignore_patterns = {},
						no_ignore = true,
					})
				end,
				desc = "[F]ind nvim [s]wap files",
			},
			{
				"<leader>fa",
				function()
					require("telescope.builtin").find_files({
						prompt_title = "Search for github actions files",
						cwd = string.format("%s/.github", vim.fn.getcwd()),
						file_ignore_patterns = {},
						no_ignore = true,
					})
				end,
				desc = "[F]ind github [a]ction files",
			},
			{
				"<leader>fD",
				function()
					require("telescope.builtin").find_files({
						prompt_title = "Search for directories to open in oil.nvim",
						find_command = { "fd", "--type", "d" },
					})
				end,
				desc = "[F]ind [D]irectories",
			},
		},
	},
	{
		"nvim-telescope/telescope-frecency.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					frecency = {
						show_scores = true, -- Default: false
						-- If `true`, it shows confirmation dialog before any entries are removed from the DB
						-- If you want not to be bothered with such things and to remove stale results silently
						-- set db_safe_mode=false and auto_validate=true
						--
						-- This fixes an issue I had in which I couldn't close the floating
						-- window because I couldn't focus it
						db_safe_mode = false, -- Default: true
						-- If `true`, it removes stale entries count over than db_validate_threshold
						auto_validate = true, -- Default: true
						-- It will remove entries when stale ones exist more than this count
						db_validate_threshold = 10, -- Default: 10
						-- Show the path of the active filter before file paths.
						-- So if I'm in the `dotfiles-latest` directory it will show me that
						-- before the name of the file
						show_filter_column = false, -- Default: true
					},
				},
			})
			require("telescope").load_extension("frecency")
		end,
	},
}
