return {
	"benomahony/uv.nvim",
	opts = {
		auto_activate_venv = true,
		notify_activate_venv = true,
		keymaps = {
			prefix = "<leader>cv", -- Consistent with your previous venv-selector leader
		},
	},
	config = function(_, opts)
		require("uv").setup(opts)

		-- Ensure LSP is updated when venv is activated
		-- uv.nvim doesn't seem to have a public hook yet, so we listen for the internal activation event if possible
		-- or just use an autocommand on DirChanged/BufEnter
		vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
			pattern = "*.py",
			callback = function()
				local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
				if vim.fn.executable(venv_path) == 1 then
					local clients = vim.lsp.get_clients({ name = "ty" })
					for _, client in ipairs(clients) do
						client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
							python = {
								pythonPath = venv_path,
							},
						})
						client.notify("workspace/didChangeConfiguration", { settings = client.settings })
					end
				end
			end,
		})
	end,
}
