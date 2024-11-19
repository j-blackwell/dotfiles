local function map(mode, lhs, rhs, opts)
	vim.keymap.set(mode, lhs, rhs, opts or {})
end


return {
	map("n", "Q", "@qj", { desc = "Apply the 'q' macro and move to the next line" }),
	map("n", "J", "Vj", { desc = "Select next line in visual block mode" }),
	map("v", "J", "j", { desc = "Select next line in visual block mode" }),
	map(
		"n",
		"<Leader>bnp",
		":e ./playground/",
		{ desc = "Create a new buffer with a new file in the playground folder" }
	),
	map("n", "<Leader>d%", ":call delete(@%)<CR>:bp<bar>bd#<CR>", { desc = "[D]elete the file of the current buffer" }),
	map("n", "<Leader>bd", "<CMD>bd<CR>", { desc = "[B]uffer [d]elete" }),
	map("n", "<Leader>ba", "<CMD>bufdo bwipeout<CR>", { desc = "[B]uffer delete [a]ll" }),
	map("n", "<Leader>cL", ":LspStop<CR>:LspStart<CR>", { desc = "Restart the [L]SP" }),
	map("n", "<Leader>ll", ":Lazy<CR>", { desc = "Load [L]azy" }),
	map("n", "<S-h>", "<CMD>bprev<CR>", { desc = "Switch to previous buffer" }),
	map("n", "<S-l>", "<CMD>bnext<CR>", { desc = "Switch to next buffer" }),
	map("v", "<Leader>d", "yP", { desc = "[d]uplicate selection" }),
	map("n", "vag", "ggVG", { desc = "Entire file" }),
	map("n", "<Leader>rr", "diwcf=return <Esc>", { desc = "Replace assignment with return" }),
	map("n", "<Leader>ra", "ciw=<Esc>i", { desc = "Replace return with assignment" }),
	map("n", "<Leader>rd", "^sd\"f:r=", { desc = "Replace dictionary entry with assignment" }),
	map("i", "<C-u>", "", { desc = "Remove ctrl+u" }),
}
