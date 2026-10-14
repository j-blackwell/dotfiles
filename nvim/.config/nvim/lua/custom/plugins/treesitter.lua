return {
	{
		-- `main` is the maintained rewrite; `master` is frozen and breaks on nvim 0.12+
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.install({
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"vim",
				"vimdoc",
				"python",
			})

			-- Languages that keep vim regex highlighting alongside treesitter
			local regex_highlight = { ruby = true, python = true }
			-- Languages where treesitter indent is unreliable
			local no_ts_indent = { ruby = true, python = true }

			local function attach(buf, lang)
				if not pcall(vim.treesitter.start, buf, lang) then
					return
				end
				if regex_highlight[lang] then
					vim.bo[buf].syntax = "on"
				end
				if not no_ts_indent[lang] then
					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("custom-treesitter", { clear = true }),
				callback = function(args)
					local buf = args.buf
					local lang = vim.treesitter.language.get_lang(args.match)
					if not lang then
						return
					end
					if vim.treesitter.language.add(lang) then
						attach(buf, lang)
					elseif vim.tbl_contains(ts.get_available(), lang) then
						-- Auto-install missing parsers, then attach
						ts.install(lang):await(function()
							if vim.api.nvim_buf_is_valid(buf) then
								attach(buf, lang)
							end
						end)
					end
				end,
			})

			-- Incremental selection: nvim 0.12 has built-in `an` / `in` in visual mode
			vim.keymap.set("n", "gss", "van", { remap = true, desc = "Start treesitter selection" })
			vim.keymap.set("x", "gsi", "an", { remap = true, desc = "Expand treesitter selection" })
			vim.keymap.set("x", "gsd", "in", { remap = true, desc = "Shrink treesitter selection" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = { lookahead = true }, -- Automatically jump forward to textobj, similar to targets.vim
				move = { set_jumps = true }, -- whether to set jumps in the jumplist
			})

			local select = require("nvim-treesitter-textobjects.select")
			for key, query in pairs({
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			}) do
				vim.keymap.set({ "x", "o" }, key, function()
					select.select_textobject(query, "textobjects")
				end)
			end

			local move = require("nvim-treesitter-textobjects.move")
			for fn, maps in pairs({
				goto_next_start = { ["]f"] = "@function.outer", ["]]"] = "@class.outer" },
				goto_next_end = { ["]F"] = "@function.outer", ["]["] = "@class.outer" },
				goto_previous_start = { ["[f"] = "@function.outer", ["[["] = "@class.outer" },
				goto_previous_end = { ["[F"] = "@function.outer", ["[]"] = "@class.outer" },
			}) do
				for key, query in pairs(maps) do
					vim.keymap.set({ "n", "x", "o" }, key, function()
						move[fn](query, "textobjects")
					end)
				end
			end

			local swap = require("nvim-treesitter-textobjects.swap")
			vim.keymap.set("n", "<leader>a", function()
				swap.swap_next("@parameter.inner")
			end)
			vim.keymap.set("n", "<leader>A", function()
				swap.swap_previous("@parameter.inner")
			end)
		end,
	},
	{
		"michaeljsmith/vim-indent-object",
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				max_lines = 5, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 10, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
