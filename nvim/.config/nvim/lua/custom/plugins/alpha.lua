return {
	"goolord/alpha-nvim",
	-- Off in the scratch call note (custom/scratchnote.lua): no session restore/save, no dashboard.
	cond = vim.env.SCRATCHNOTE == nil,
	dependencies = { "echasnovski/mini.icons" },
	config = function()
		require("alpha").setup(require("alpha.themes.dashboard").config)
	end,
}
