local json = require("./ilua/GUI/dkjson")
local function formtest(a)
	local data = {}
	local formlist = {}
	formlist[1] = '1格'
	formlist[2] = '2格'
	data[1] = json.encode(formlist)
	GUI('simple',luaapi:GetUUID(a.playername),data)
end
luaapi:Listen('onDestroyBlock',formtest)