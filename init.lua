
--[[
Synopsis:
	Runs x/%s$/d

Use:
	/RETURN/ for details
	require"THIS MODULE"() -- runs Setup()
	Setup() also registers wstrip as a command
	M.ignore = { [?] = true } will not save if ? matches
	if ? is a dictionary, it should be an extension, file path, directory, filename
	if ? is an integer, its a function(vis.win.file, fullpath)
		returning true means ignore

Warning:
	Subscribing with vis:command leads to core dump (vis 0.9)

Bugs:
	Selection messes up sometimes
--]]

------------------------- ENV

local _G = _G
local vis = _G.vis
local env = {} for k,v in pairs(_G) do env[k] = v end
local mt = {
	__index = function (_,k)
		vis:info(
			string.format("Missing Key[%s] in trailing whitespace module",k)
		)
		return nil
	end
	,__newindex = function (t,k,v)
		error(string.format("ERROR: _G[%s]=%s",k,v),2)
	end
}
local _ENV = setmetatable(env, mt)


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
-- This is necessary because vis:command fails for some reason?
--[[ Design:
	if cursor/selection run a single gsub call
	if not, run PerLine, which loops each line doing a gsub.
	it also wipes out the selection sometimes. not our problem.
--]]
local Manual = function (file)
	local lines = file.lines

	-- pattern doesn't match last line, perline checks/changes the line directly
	PerLine(file, lines, #lines)

	local size = file.size
	local sel = vis.win.selection
	local line = sel.line
	if line then -- sometimes its nil?
		-- A single gsub call, this makes it faster than PerLine
		local text, changes = file:content(0,size):gsub("[\t ]+(\r?\n)","%1")
		if changes>0 then
			local col = sel.col
			file:delete(0, size) -- wipes out selection/ranges
			file:insert(0, text)
			sel:to(line, col) -- resets selection
		end
	elseif file:content(0,size):find"[\t ]+\r?\n" then
		PerLine(file, lines, 1, #lines-1)
	end
	return true
end


--------------------- REGISTER

local events = vis.events

-- Ignore path and file (mostly)
-- dict deals with path, extension, filename, basename
-- [natural_int] contains functions that receive (file,path)
local ignore = {}
-- TODO: hashbang, syntax
-- maybe use lexers.detect function on path and file content?

local function Subscriber(file, path)
	-- The point here is to return early and avoid running Manual()
	for _,F in ipairs(ignore) do
		if F(file, path) then return true end
	end
	if path and path~="" then
		if
			ignore[path] -- full path
			or ignore[path:match"^.*/"] -- directory
			or ignore[path:match"[^/]+$"] -- filename
			or ignore[path:match"[^.]+$"] -- extension
			or ignore[vis.win.syntax]
		then
			return true
		end
	end
	Manual(file)
	return true
end

local function Subscribe()
	events.subscribe(events.FILE_SAVE_PRE, Subscriber)
end

local function UnSubscribe()
	events.unsubscribe(events.FILE_SAVE_PRE, Subscriber)
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

return setmetatable(
{
	Setup = Setup
	, Subscribe = Subscribe
	, UnSubscribe = UnSubscribe
	, Command = Cmd
	, Register = CommandRegister
	, ignore = ignore
},{
	__call = Setup

	-- Bastardization of Nim's Style
	-- Case insensitive
	, __index = function (T,index)
		if type(index)=="string" then
			index = index:gsub("_",""):lower()
			for key, val in pairs(T) do
				if key:gsub("_",""):lower()==index then return val end
			end
		end
		return nil
	end

	, __newindex = function ()
		error"MODULE IS READ ONLY"
	end
})
