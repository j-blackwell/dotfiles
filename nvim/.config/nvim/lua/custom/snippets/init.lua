local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.s
local c = ls.choice_node
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node
local d = ls.dynamic_node

ls.add_snippets("python", {
	s(
		"duckdb",
		fmt(
			[[import {}.helpers.duckdb as db
{}]],
			{
				c(1, { t("ember_climate"), t("src") }),
				i(0),
			}
		)
	),
})

ls.add_snippets("python", {
	s(
		"filter",
		fmt([[filter(pl.col("{}"){})]], {
			i(1),
			i(2),
		})
	),
})
