
--[[
Synopsis:
	Runs x/%s$/d

Use:
	require"vis.remove_trailing_whitespace".Subscribe()

Notes:
	vis:command"x/[	 ]+$/d" -> core dump, so dont
--]]

local M = {}

M.F = function (file)
	local lines = file.lines do
		local t,c = lines[#lines]:gsub("%s+$","")
		if c>0 then lines[#lines] = t end
	end
	if file:content(0,file.size):find"[ \t]\n" then
		for i=1, #lines do
			local t,c = lines[i]:gsub("%s+$","")
			if c>0 then lines[i] = t end
		end
	end
	return true
end

local vis = _G.vis
local events = vis.events
M.Subscribe = function ()
	events.subscribe(events.FILE_SAVE_PRE, M.F)
end

return M
