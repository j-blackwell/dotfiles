function Linemode:mtime_iso()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		return ""
	end
	return os.date("%Y-%m-%d %H:%M", time)
end

require("zoxide"):setup({
	update_db = true,
})

require("recycle-bin"):setup()
