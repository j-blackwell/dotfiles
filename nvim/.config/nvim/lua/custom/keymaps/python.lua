-- Helper function to find the workspace root
local function find_workspace_root()
	local markers = { ".git", "pyproject.toml", "setup.py", "requirements.txt", ".python-version" }
	local current_dir = vim.fn.expand("%:p:h")

	while current_dir ~= "/" do
		for _, marker in ipairs(markers) do
			if
				vim.fn.isdirectory(current_dir .. "/" .. marker) == 1
				or vim.fn.filereadable(current_dir .. "/" .. marker) == 1
			then
				return current_dir
			end
		end
		current_dir = vim.fn.fnamemodify(current_dir, ":h")
	end

	return vim.fn.getcwd() -- fallback to current working directory
end

-- Convert file path to Python import path
local function path_to_import(file_path, workspace_root)
	-- Remove workspace root from file path
	local relative_path = file_path:gsub("^" .. vim.pesc(workspace_root) .. "/", "")

	-- Remove .py extension
	relative_path = relative_path:gsub("%.py$", "")

	-- Replace path separators with dots
	local import_path = relative_path:gsub("/", ".")

	-- Remove __init__ from the end if present
	import_path = import_path:gsub("%.__init__$", "")

	return import_path
end

-- Get symbol at cursor using treesitter
local function get_symbol_at_cursor()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local node = ts_utils.get_node_at_cursor()

	if not node then
		return nil
	end

	-- Look for function_definition, class_definition, or identifier
	local symbol_types = {
		"function_definition",
		"class_definition",
		"identifier",
	}

	local current = node
	while current do
		local node_type = current:type()

		if vim.tbl_contains(symbol_types, node_type) then
			if node_type == "function_definition" or node_type == "class_definition" then
				-- Get the name node (first child that's an identifier)
				for child in current:iter_children() do
					if child:type() == "identifier" then
						return ts_utils.get_node_text(child)[1]
					end
				end
			elseif node_type == "identifier" then
				return ts_utils.get_node_text(current)[1]
			end
		end

		current = current:parent()
	end

	return nil
end

-- Main function to copy import path
local function copy_import_path()
	local current_file = vim.fn.expand("%:p")

	-- Check if it's a Python file
	if not current_file:match("%.py$") then
		vim.notify("Not a Python file", vim.log.levels.WARN)
		return
	end

	local workspace_root = find_workspace_root()
	local base_import = path_to_import(current_file, workspace_root)

	-- Try to get symbol at cursor
	local symbol = get_symbol_at_cursor()

	local full_import_path
	if symbol then
		full_import_path = base_import .. ":" .. symbol
		vim.notify("Copied import path with symbol: " .. full_import_path, vim.log.levels.INFO)
	else
		full_import_path = base_import
		vim.notify("Copied module import path: " .. full_import_path, vim.log.levels.INFO)
	end

	-- Copy to system clipboard
	vim.fn.setreg("+", full_import_path)
	vim.fn.setreg('"', full_import_path)
end

-- Copy just the module path (without symbol)
local function copy_module_path()
	local current_file = vim.fn.expand("%:p")

	if not current_file:match("%.py$") then
		vim.notify("Not a Python file", vim.log.levels.WARN)
		return
	end

	local workspace_root = find_workspace_root()
	local import_path = path_to_import(current_file, workspace_root)

	vim.fn.setreg("+", import_path)
	vim.fn.setreg('"', import_path)
	vim.notify("Copied module path: " .. import_path, vim.log.levels.INFO)
end

-- Generate import statement
local function get_import_statement()
	local current_file = vim.fn.expand("%:p")

	if not current_file:match("%.py$") then
		vim.notify("Not a Python file", vim.log.levels.WARN)
		return
	end

	local workspace_root = find_workspace_root()
	local base_import = path_to_import(current_file, workspace_root)
	local symbol = get_symbol_at_cursor()

	local import_statement
	if symbol then
		import_statement = "from " .. base_import .. " import " .. symbol
	else
		import_statement = "import " .. base_import
	end
	return import_statement
end

local function copy_import_statement()
	local import_statement = get_import_statement()
	vim.fn.setreg("+", import_statement)
	vim.fn.setreg('"', import_statement)
	vim.notify("Copied import statement: " .. import_statement, vim.log.levels.INFO)
end

local function slime_send_import_statement()
	local import_statement = get_import_statement()
	vim.fn["slime#send"](import_statement .. "\r")
end

vim.api.nvim_create_user_command("PythonImportStatement", copy_import_statement, {})
vim.api.nvim_create_user_command("PythonImportPath", copy_import_path, {})
vim.api.nvim_create_user_command("PythonModulePath", copy_module_path, {})
vim.api.nvim_create_user_command("PythonSlimeSendImportStatement", slime_send_import_statement, {})
return {}
