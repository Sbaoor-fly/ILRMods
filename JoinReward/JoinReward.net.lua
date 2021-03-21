local rwcfg = tool:IfFile('./plugins/ilua/JoinReward/items.json')
local plcfg = tool:IfFile('./plugins/ilua/JoinReward/data.txt')
local dddir = tool:IfDir('./plugins/ilua/JoinReward')
if (dddir == false) then
    tool:CreateDir('./plugins/ilua/JoinReward')
end
if (plcfg == false) then
    tool:WriteAllText('./plugins/ilua/JoinReward/data.txt','')
    tool:AppendAllText('./plugins/ilua/JoinReward/data.txt','[Players Information]')
end
if (rwcfg == false) then
    tool:WriteAllText('./plugins/ilua/JoinReward/items.json','{\n\t"items":[\n\t\t{\n\t\t\t"itemid":304,\n\t\t\t"itemaux":0,\n\t\t\t"count":1\n\t\t}\n\t]\n}')
end

local json = require("./plugins/ilua/Lib/dkjson")

local function PlayersJoin(a)
    local rwitem = json.decode(tool:ReadAllText('./plugins/ilua/JoinReward/items.json'))
    local plname = a.playername
    local uuid = luaapi:GetUUID(plname)
    local plcfg = tool:ReadAllText('./plugins/ilua/JoinReward/data.txt')
    local plist = {plcfg}
    local n = 1
    for key,value in pairs(plist) do
        local check = string.find(value,a.playername)
        if (check == nil) then
            tool:AppendAllText('./plugins/ilua/JoinReward/data.txt','\n'..plname)
            mc:sendText(uuid,'§e[JoinReward]§r §b欢淫新人 '..plname..' 加入服务器！奖励已发放！')
            repeat
                mc:addPlayerItem(uuid,(rwitem.items[n].itemid),(rwitem.items[n].itemaux),(rwitem.items[n].count))
                n = n+1
            until( n > 35 )
        else
            mc:sendText(uuid,'§e[JoinReward]§r §b玩家 '..plname..' 加入了服务器')
        break
        end
    end
end

luaapi:Listen('onLoadName',PlayersJoin)
local logo = [[

     ___         _        ______                                _ 
    |_  |       (_)       | ___ \                              | |
      | |  ___   _  _ __  | |_/ / ___ __      __ __ _  _ __  __| |
      | | / _ \ | || '_ \ |    / / _ \\ \ /\ / // _` || '__|/ _` |
  /\__/ /| (_) || || | | || |\ \|  __/ \ V  V /| (_| || |  | (_| |
  \____/  \___/ |_||_| |_|\_| \_|\___|  \_/\_/  \__,_||_|   \__,_|

]]
print(logo)
print('[INFO] [JoinReward] 进服奖励装载成功')
print('[INFO] [JoinReward] 作者：unlinus')
print('[INFO] [JoinReward] 版本：1.1.2')