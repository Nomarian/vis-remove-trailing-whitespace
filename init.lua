
--[[
Synopsis:
	Runs x/%s$/d

Use:
	require"vis.remove_trailing_whitespace"() -- runs Setup()
	/RETURN/ for details
	Setup() also registers wstrip as a command

Bugs:
	Subscribing with vis:command leads to core dump (vis 0.9)
	Selection messes up sometimes

Untested:
	Ranges
--]]

local M = {}

local _G, string = _G, string
local vis = _G.vis
local mt = {
	__index = _G
	-- function (_,k)
		-- vis:info(
			-- Format("Please set Key[%s] in trailing whitespace module",k)
		-- )
		-- return _G[k]
	-- end
}
local _ENV = setmetatable(M, mt)

--------------------- EDIT

local Cmd = function ()
	vis:command":x/[\t ]+$/d"
end

local PerLine = function -- true --
-- EOL agnostic
(
	file -- table --
	,lines -- table? --
	,from -- number? --
	,to -- number? --
)
	lines = lines or file.lines
	for i=from or 1, to or #lines do
		local t,c = lines[i]:gsub("[\t ]+$","")
		if c>0 then lines[i] = t end
	end
	return true
end

-- Manually do it instead of command
-- This is necessary because vis:command fails
local Manual = function (file)
	local lines = file.lines

	-- pattern doesn't match last line, perline checks/changes the line directly
	PerLine(file, lines, #lines)

	local size = file.size
	local sel = vis.win.selection
	local line = sel.line
	if line then -- sometimes its nil?
		local text, changes = file:content(0,size):gsub("[\t ]+(\r?\n)","%1")
		if changes>0 then
			local col = sel.col
			file:delete(0, size)
			file:insert(0, text)
			sel:to(line, col)
		end
	elseif file:content(0,size):find"[\t ]+\r?\n" then
		PerLine(file, lines, 1, #lines-1)
	end
	return true
end

--------------------- REGISTER

local events = vis.events
local Subscribe = function ()
	events.subscribe(events.FILE_SAVE_PRE, Manual)
end

local CommandRegister do
	local Command = function (argv, force, win, selection, range)
		Manual(win.file)
		return true
	end
	CommandRegister = function()
		vis:command_register("wstrip", Command
			, "Strips EOL whitespace from current file"
		)
	end
end

local Setup = function()
	Subscribe()
	CommandRegister()
end

--------------------- RETURN
M.Setup = Setup
M.Subscribe = Subscribe
M.F = Manual
M.Cmd = Cmd
M.Register = CommandRegister

mt.__call = Setup
return M
