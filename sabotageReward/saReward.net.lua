----------------------------------------
-- Author: RedbeanW -- License: GPLv3 --
----------------------------------------
-------- STAND WITH OPEN SOURCE --------
----------------------------------------
-- 插件版本，请勿修改
plugin_version = '1.0.4'
-- 载入库
if (tool:IfFile('./ilua/lib/json.lua') == false) then
    print('[saReward] Where is my json library??!!')
    return false
end
json = require('./ilua/lib/json')
-- 载入配置文件
if (tool:IfFile('./ilua/saReward/config.json') == false) then
    print('[saReward] Where is my config file??!!]')
    return false
end
cfg = json.decode(tool:ReadAllText('./ilua/saReward/config.json'))
mu_desBlock = cfg.data.multiple.desBlock
mu_killMob = cfg.data.multiple.killMob
sb_desBlock = cfg.data.scoreboard.desBlock
sb_killMob = cfg.data.scoreboard.killMob
probability = cfg.config.probability
allow_animal = cfg.config.allow_animal
-- Others
probability = probability * 100
-- 功能函数
function desBlock(b)
    math.randomseed(os.time())
    if (math.random(1, 100) <= probability) then
        mc:runcmd('scoreboard players add "' .. b.playername .. '" ' .. sb_desBlock .. ' ' .. tostring(mu_desBlock))
    end
end
function killMob(c)
    math.randomseed(os.time())
    if (math.random(1, 100) <= probability) then
        uuid = luaapi:GetUUID(c.srcname)
        if (uuid ~= nil) then
            mc:runcmd('scoreboard players add "' .. c.srcname .. '" ' .. sb_killMob .. ' ' .. tostring(mu_killMob))
        end
    end
end
-- 注册监听
luaapi:Listen('onMobDie', killMob)
luaapi:Listen('onDestroyBlock', desBlock)
print('[saReward] plugin loaded! VER:' .. plugin_version)