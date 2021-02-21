----------------------------------------
-- Author: RedbeanW -- License: GPLv3 --
----------------------------------------
-------【 交流QQ群：819566672 】--------
----------------------------------------
-- 插件版本，请勿修改
local plugin_version = '1.0.6'
-- Load library.
if (tool:IfFile('./ilua/lib/json.lua') == false) then
    print('[saReward] Where is my json library??!!')
    return
end
json = require('./ilua/lib/json')
-- Load configure.
if (tool:IfFile('./ilua/saReward/config.json') == false) then
    print('[saReward] Where is my config file??!!]')
    return
end
local cfg = json.decode(tool:ReadAllText('./ilua/saReward/config.json'))
if(cfg.version==nil) then print('[saReward] Old configuration file detected! Please carefully read the instructions for this version, the plugin is being closed...') return end
local probability_kill = cfg.config.kill.probability * 100
local probability_destroy = cfg.config.destroy.probability * 100
-- Function
function Event_DestroyBlock(b)
    math.randomseed(os.time())
	if(cfg.config.debug_mode==true) then print('[Debug][saReward] playerName = '..b.playername..' blockid = '..b.blockid) end
	if(cfg.config.destroy.reward_list==true) then if(isValInList(cfg.data.reward_list.destroy,b.blockid)==-1) then return end end
    if (math.random(1, 100) <= probability_destroy) then
        mc:runcmd('scoreboard players add "' .. b.playername .. '" ' .. cfg.data.scoreboard.destroy .. ' ' .. math.random(cfg.data.multiple.destroy[1],cfg.data.multiple.destroy[2]))
    end
end
function Event_MobDied(c)
	if(cfg.config.debug_mode==true) then print('[Debug][saReward] srcName = '..c.srcname..' mobtype = '..c.mobtype) end
	if(cfg.config.kill.reward_list==true) then if(isValInList(cfg.data.reward_list.kill,c.mobtype)==-1) then return end end
    math.randomseed(os.time())
	if (math.random(1, 100) <= probability_kill) then
		if(c.srctype=='entity.player.name') then mc:runcmd('scoreboard players add "' .. c.srcname .. '" ' .. cfg.data.scoreboard.kill .. ' ' .. math.random(cfg.data.multiple.kill[1],cfg.data.multiple.kill[2])) end
    end
end
-- Feature
function isValInList(list, value)
	for i, nowValue in pairs(list) do
        if nowValue == value then
            return i
        end
    end
    return -1
end
-- Register Listener
luaapi:Listen('onMobDie', Event_MobDied)
luaapi:Listen('onDestroyBlock', Event_DestroyBlock)
print('[saReward] plugin loaded! VER:' .. plugin_version)