return {
	vim.api.nvim_set_keymap("n", "Q", "@qj", { desc = "Apply the 'q' macro and move to the next line" }),
	vim.api.nvim_set_keymap("n", "J", "Vj", { desc = "Select next line in visual block mode" }),
	vim.api.nvim_set_keymap("v", "J", "j", { desc = "Select next line in visual block mode" }),
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>bnp",
		":e ./playground/",
		{ desc = "Create a new buffer with a new file in the playground folder" }
	),
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>d%",
		":call delete(@%)<CR>:bp<bar>bd#<CR>",
		{ desc = "Delete the file of the current buffer" }
	),
	vim.api.nvim_set_keymap("n", "<Leader>cL", ":LspStop<CR>:LspStart<CR>", { desc = "Restart the [L]SP" }),
	vim.api.nvim_set_keymap("n", "<Leader>ll", ":Lazy<CR>", { desc = "Load [L]azy" }),
	vim.api.nvim_set_keymap("n", "<Leader>bd", "<CMD>bd<CR>", { desc = "[D]elete buffer" }),
	vim.api.nvim_set_keymap("n", "<S-h>", "<CMD>bprev<CR>", { desc = "Switch to previous buffer" }),
	vim.api.nvim_set_keymap("n", "<S-l>", "<CMD>bnext<CR>", { desc = "Switch to next buffer" }),
}
