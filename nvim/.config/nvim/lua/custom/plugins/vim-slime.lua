local delimiter = "^# %%"
return {
	{
		"jpalardy/vim-slime",
		config = function()
			vim.g.slime_cell_delimiter = delimiter
			vim.g.slime_target = "tmux"
			vim.g.slime_bracketed_paste = 1 -- If using IPython
			vim.g.slime_default_config = {
				socket_name = "default",
				target_pane = "{right-of}", -- Adjust based on your tmux layout
			}
			vim.g.slime_dont_ask_default = 1 -- Don't ask for config every time
		end,
		keys = {
			{ "<C-C>c", string.format("<Plug>SlimeSendCell<BAR>/%s<CR><CR>", delimiter), desc = "Slime Send Cell" },
			{ "<C-C><C-C>", "<Plug>SlimeParagraphSend<CR>", desc = "Slime Send Paragraph" },
			{ "<C-C>l", "<Plug>SlimeLineSend<CR>", desc = "Slime Send Line" },
			{ "<C-C>i", '<Esc>2o<Esc>i# %%<Esc>F#""d0o<Esc>0""C', desc = "Create new cell (below current line)" },
			{ "<C-C><C-I>", '<Esc>2O<Esc>ki# %%<Esc>F#""d0o<Esc>0""C', desc = "Create new cell (above current line)" },
		},
	},
	{
		"klafyvel/vim-slime-cells",
		keys = {
			{ "<C-C>j", "<Plug>SlimeCellsNext", desc = "Go to next cell" },
			{ "<C-C>k", "<Plug>SlimeCellsPrev", desc = "Go to previous cell" },
		},
		config = function()
			vim.g.slime_cell_delimiter = delimiter
		end,
	},
}
