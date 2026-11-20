-- Scratch call note, started by ~/.local/bin/custom/scratchnote.py (SUPER+N) inside the
-- `scratchnote` tmux session. The note is an unnamed in-memory buffer (so a stray :w fails
-- with E32) until written with one of the buffer-local maps:
--   <leader>nw  write to the notes repo, stay open (no commit)
--   <leader>nc  write, commit that file, push in the background, close; then
--               scratchnote_actions.py offers its action items for Google Tasks
--   <leader>nd  close without saving (refuses once the note has been written)
--   <leader>nD  delete the written file (if any) and close
-- Closing nvim ends the tmux session, which closes the kitty window.

local M = {}

local dir = vim.env.SCRATCHNOTE_DIR
local name = vim.env.SCRATCHNOTE_NAME
local path = nil -- set once the note has been written

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "Scratch note" })
end

local function new_path()
	local candidate = string.format("%s/%s.md", dir, name)
	local n = 2
	while vim.uv.fs_stat(candidate) do
		candidate = string.format("%s/%s-%d.md", dir, name, n)
		n = n + 1
	end
	return candidate
end

local function write()
	if path then
		vim.cmd.write()
		return
	end
	vim.fn.mkdir(dir, "p")
	local target = new_path()
	vim.cmd.saveas(vim.fn.fnameescape(target))
	path = target
	notify("Written to " .. vim.fn.fnamemodify(path, ":~"))
end

local function git(args)
	local result = vim.system(vim.list_extend({ "git", "-C", dir }, args), { text = true }):wait()
	if result.code ~= 0 then
		error(vim.trim(result.stderr ~= "" and result.stderr or result.stdout), 0)
	end
	return vim.trim(result.stdout)
end

local function write_commit_close()
	write()
	local ok, err = pcall(function()
		local relative = vim.fs.relpath(git({ "rev-parse", "--show-toplevel" }), path)
		git({ "add", "--", path })
		git({ "commit", "-q", "-m", "add " .. relative, "--", path })
	end)
	if not ok then
		notify("Commit failed, note left open:\n" .. err, vim.log.levels.ERROR)
		return
	end
	-- Detached so the push outlives nvim and the tmux session closing.
	vim.fn.jobstart({
		"sh",
		"-c",
		"git pull -q --rebase --autostash && git push -q "
			.. "|| notify-send -a 'Scratch note' -u critical 'Push failed' \"$(pwd)\"",
	}, { cwd = dir, detach = true })
	-- scratchnote_actions.py runs after nvim exits and turns this note's actions into tasks.
	if vim.env.SCRATCHNOTE_COMMITTED then
		vim.fn.writefile({ path }, vim.env.SCRATCHNOTE_COMMITTED)
	end
	vim.cmd("qa!")
end

local function discard()
	if path then
		notify(
			"Note saved at " .. vim.fn.fnamemodify(path, ":~") .. ": <leader>nc to commit, <leader>nD to delete",
			vim.log.levels.WARN
		)
		return
	end
	vim.cmd("qa!")
end

local function delete_and_close()
	if path then
		os.remove(path)
	end
	vim.cmd("qa!")
end

function M.start()
	local buf = vim.api.nvim_get_current_buf()
	local header = vim.fn.readfile(vim.env.SCRATCHNOTE_HEADER)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
	-- Highlight with treesitter but leave 'filetype' empty while the buffer is unnamed:
	-- marksman crashes on an unnamed markdown buffer ("Invalid URI"). :saveas in write()
	-- detects the filetype once the note has a real .md path.
	vim.treesitter.start(buf, "markdown")
	vim.api.nvim_win_set_cursor(0, { #header, 0 })

	local function map(lhs, fn, desc)
		vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
	end
	map("<leader>nw", write, "Scratch [n]ote: [w]rite, stay open")
	map("<leader>nc", write_commit_close, "Scratch [n]ote: write, [c]ommit + push, close")
	map("<leader>nd", discard, "Scratch [n]ote: [d]iscard and close")
	map("<leader>nD", delete_and_close, "Scratch [n]ote: [D]elete written file and close")
end

return M
