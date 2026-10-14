return {
	"RRethy/vim-illuminate",
	config = function()
		-- Upstream calls the deprecated `vim.region` whenever it exists (nvim 0.12+ warns).
		-- Force its `getregionpos` code path instead.
		local hl = require("illuminate.highlight")
		local ns = vim.api.nvim_create_namespace("illuminate.highlight")
		local kind_hl = {
			[vim.lsp.protocol.DocumentHighlightKind.Read] = "IlluminatedWordRead",
			[vim.lsp.protocol.DocumentHighlightKind.Write] = "IlluminatedWordWrite",
		}
		hl.range = function(bufnr, start, finish, kind)
			local region = vim.fn.getregionpos(
				{ bufnr, start[1] + 1, start[2] + 1 },
				{ bufnr, finish[1] + 1, finish[2] + 1 },
				{ type = "v", exclusive = true }
			)
			for _, segment in ipairs(region) do
				local start_pos, finish_pos = unpack(segment)
				vim.api.nvim_buf_set_extmark(bufnr, ns, start_pos[2] - 1, start_pos[3] - 1, {
					hl_group = kind_hl[kind] or "IlluminatedWordText",
					end_col = finish_pos[3],
					priority = 199,
					strict = false,
				})
			end
		end

		-- default configuration
		require("illuminate").configure({
			-- providers: provider used to get references in the buffer, ordered by priority
			providers = {
				"lsp",
				"treesitter",
				"regex",
			},
			-- delay: delay in milliseconds
			delay = 100,
			-- filetype_overrides: filetype specific overrides.
			-- The keys are strings to represent the filetype while the values are tables that
			-- supports the same keys passed to .configure except for filetypes_denylist and filetypes_allowlist
			filetype_overrides = {},
			-- filetypes_denylist: filetypes to not illuminate, this overrides filetypes_allowlist
			filetypes_denylist = {
				"dirbuf",
				"dirvish",
				"fugitive",
			},
			-- filetypes_allowlist: filetypes to illuminate, this is overridden by filetypes_denylist
			-- You must set filetypes_denylist = {} to override the defaults to allow filetypes_allowlist to take effect
			filetypes_allowlist = {},
			-- modes_denylist: modes to not illuminate, this overrides modes_allowlist
			-- See `:help mode()` for possible values
			modes_denylist = {},
			-- modes_allowlist: modes to illuminate, this is overridden by modes_denylist
			-- See `:help mode()` for possible values
			modes_allowlist = {},
			-- providers_regex_syntax_denylist: syntax to not illuminate, this overrides providers_regex_syntax_allowlist
			-- Only applies to the 'regex' provider
			-- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
			providers_regex_syntax_denylist = {},
			-- providers_regex_syntax_allowlist: syntax to illuminate, this is overridden by providers_regex_syntax_denylist
			-- Only applies to the 'regex' provider
			-- Use :echom synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
			providers_regex_syntax_allowlist = {},
			-- under_cursor: whether or not to illuminate under the cursor
			under_cursor = true,
			-- large_file_cutoff: number of lines at which to use large_file_config
			-- The `under_cursor` option is disabled when this cutoff is hit
			large_file_cutoff = nil,
			-- large_file_config: config to use for large files (based on large_file_cutoff).
			-- Supports the same keys passed to .configure
			-- If nil, vim-illuminate will be disabled for large files.
			large_file_overrides = nil,
			-- min_count_to_highlight: minimum number of matches required to perform highlighting
			min_count_to_highlight = 1,
			-- should_enable: a callback that overrides all other settings to
			-- enable/disable illumination. This will be called a lot so don't do
			-- anything expensive in it.
			should_enable = function(bufnr)
				return true
			end,
			-- case_insensitive_regex: sets regex case sensitivity
			case_insensitive_regex = false,
		})
	end,
}
