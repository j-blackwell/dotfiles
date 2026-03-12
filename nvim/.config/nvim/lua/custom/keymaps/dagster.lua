local function goto_asset()
	local function_name = vim.fn.expand("<cword>")

	local base_url = "http://127.0.0.1:3000/assets?asset-selection=key%3A%22%2A"
	local url = base_url .. function_name .. "%22"
	local command = "xdg-open '" .. url .. "'"

	vim.fn.system(command)
	print("Opening search page for asset: " .. function_name)
end

local function goto_asset_prod()
	local function_name = vim.fn.expand("<cword>")

	local base_url = "https://ember-climate.dagster.plus/prod/selection/all-assets/assets?asset-selection=key%3A%22%2A"
	local url = base_url .. function_name .. "%22"
	local command = "xdg-open '" .. url .. "'"

	vim.fn.system(command)
	print("Opening search page for asset: " .. function_name)
end

local function switch_asset_transformation()
	local root = vim.fn.getcwd()
	local current_file = vim.api.nvim_buf_get_name(0)

	-- Relative path from project root
	local relative_path = current_file:sub(#root + 2)
	local target_file = ""
	if relative_path:match("assets_") then
		target_file = relative_path:gsub("assets_", "transformations_")
	elseif relative_path:match("transformations_") then
		target_file = relative_path:gsub("transformations_", "assets_")
	else
		print("Not in an assets or transformations directory")
		return
	end
	local absolute_target = root .. "/" .. target_file
	if vim.fn.filereadable(absolute_target) == 1 then
		vim.cmd("edit " .. absolute_target)
	else
		local confirm = vim.fn.confirm("Target file does not exist. Create it?", "&Yes\n&No", 2)
		if confirm == 1 then
			-- Ensure directory exists
			vim.fn.mkdir(vim.fn.fnamemodify(absolute_target, ":h"), "p")
			vim.cmd("edit " .. absolute_target)
			vim.cmd("write")
		end
	end
end

vim.api.nvim_create_user_command("DagsterSwitchTransformationAndAsset", switch_asset_transformation, {})
vim.api.nvim_create_user_command("DagsterGoToAsset", goto_asset, {})
vim.api.nvim_create_user_command("DagsterGoToAssetProd", goto_asset_prod, {})
return {}
