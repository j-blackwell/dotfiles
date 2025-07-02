local function get_git_info()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return nil, "Not in a git repository"
	end

	local remote_url = vim.fn.systemlist("git config --get remote.origin.url")[1]
	if vim.v.shell_error ~= 0 then
		return nil, "No origin remote found"
	end

	local branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]
	if vim.v.shell_error ~= 0 then
		return nil, "Could not get current branch"
	end

	return {
		root = git_root,
		remote_url = remote_url,
		branch = branch,
	}
end

local function parse_github_url(remote_url)
	-- Handle both SSH and HTTPS formats
	local patterns = {
		"git@github%.com:([^/]+)/(.+)%.git", -- SSH format
		"https://github%.com/([^/]+)/(.+)%.git", -- HTTPS format
		"https://github%.com/([^/]+)/(.+)$", -- HTTPS without .git
	}

	for _, pattern in ipairs(patterns) do
		local owner, repo = remote_url:match(pattern)
		if owner and repo then
			return owner, repo
		end
	end

	return nil, nil
end

local function get_relative_path(file_path, git_root)
	-- Remove git root from file path to get relative path
	local relative = file_path:gsub("^" .. vim.pesc(git_root) .. "/", "")
	return relative
end

local function create_github_link()
	-- Get current buffer file path
	local file_path = vim.fn.expand("%:p")
	if file_path == "" then
		print("No file in current buffer")
		return
	end

	-- Get git information
	local git_info, err = get_git_info()
	if not git_info then
		print("Error: " .. err)
		return
	end

	-- Parse GitHub URL
	local owner, repo = parse_github_url(git_info.remote_url)
	if not owner or not repo then
		print("Error: Could not parse GitHub URL from remote: " .. git_info.remote_url)
		return
	end

	-- Get relative path
	local relative_path = get_relative_path(file_path, git_info.root)

	-- Get current line number (optional)
	local line_number = vim.fn.line(".")

	-- Construct GitHub URL
	local github_url = string.format(
		"https://github.com/%s/%s/blob/%s/%s#L%d",
		owner,
		repo,
		git_info.branch,
		relative_path,
		line_number
	)

	-- Copy to clipboard
	vim.fn.setreg("+", github_url)
	print("GitHub link copied to clipboard: " .. github_url)
end

-- Create a command to call this function
vim.api.nvim_create_user_command("GithubLink", create_github_link, {})
return {}
