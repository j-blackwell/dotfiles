local function run_git_clipboard_commands()
	local clipboard = table.concat(vim.fn.getreg("+", 1, true), "\n")

	local fetch_pattern = "^git fetch origin%s*$"
	local checkout_pattern = "^git checkout%s+([%w%-%._/]+)%s*$"

	local lines = {}
	for line in clipboard:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	if #lines == 2 and lines[1]:match(fetch_pattern) then
		local branch = lines[2]:match(checkout_pattern)
		if branch then
			vim.notify("Checking out branch: " .. branch, vim.log.levels.INFO)

			-- Run fetch, then checkout
			vim.fn.jobstart({ "git", "fetch", "origin" }, {
				stdout_buffered = true,
				stderr_buffered = true,
				on_exit = function(_, code)
					if code == 0 then
						vim.fn.jobstart({ "git", "checkout", branch }, {
							stdout_buffered = true,
							stderr_buffered = true,
							on_exit = function(_, checkout_code)
								if checkout_code == 0 then
									vim.notify("Checked out " .. branch, vim.log.levels.INFO)
								else
									vim.notify("Checkout failed for " .. branch, vim.log.levels.ERROR)
								end
							end,
						})
					else
						vim.notify("git fetch origin failed", vim.log.levels.ERROR)
					end
				end,
			})
		else
			vim.notify("Invalid checkout line in clipboard", vim.log.levels.ERROR)
		end
	else
		vim.notify("Clipboard doesn't match expected pattern", vim.log.levels.ERROR)
	end
end

vim.api.nvim_create_user_command("GitClipboardCheckout", run_git_clipboard_commands, {})
return {}
