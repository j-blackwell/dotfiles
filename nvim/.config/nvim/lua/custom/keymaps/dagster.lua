local function goto_asset()
	local function_name = vim.fn.expand("<cword>")

	local base_url = "http://127.0.0.1:3000/assets?asset-selection=key%3A%22%2A"
	local url = base_url .. function_name .. "%2A%22"
	local command = "xdg-open '" .. url .. "'"

	vim.fn.system(command)
	print("Opening search page for asset: " .. function_name)
end

vim.api.nvim_create_user_command("DagsterGoToAsset", goto_asset, {})
return {}
