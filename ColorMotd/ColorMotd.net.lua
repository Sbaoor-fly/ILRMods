local contxt = 'MOTD:\n - §2Dedicated Server\n - §2Dedicated Server\nTimeOut: 20\nMaintainMOTD: §4服务器维护中...\nMaintainKickCause: §4服务器维护中,请等待维护完成再进入服务器!'
if(not(tool:IfFile('./plugins/ColorMotd/config.yaml')))then
	tool:CreateDir('./plugins/ColorMotd')
	tool:WriteAllText('./plugins/ColorMotd/config.yaml',contxt)
end
local json = require ("./ilua/Lib/dkjson")
local config = json.decode(tool:YamlToJson(tool:ReadAllText('./plugins/ColorMotd/config.yaml')))
local motd = config['MOTD']
local ifkick = false
local function changemotd(sec)
	while(true)do
		tool:sleep(sec)
		if(ifkick)then
			mc:setServerMotd(config['MaintainMOTD'],true)
		else
			for k,v in pairs(motd)do
				mc:setServerMotd(v,true)
				tool:sleep(sec)
			end
		end
	end
end
tool:newthread(changemotd,tonumber(config['TimeOut']))
function serverMaintain(a)
	if(a.cmd == 'maintain')then
		if(ifkick)then
			print('[ColorMotd] 维护模式关闭')
			ifkick = false
			return false
		else
			print('[ColorMotd] 维护模式开启')
			ifkick = true
			return false
		end
	end
end
function reeeeepanick(a)
	if(ifkick)then
		mc:disconnectClient(luaapi:GetUUID(a.playername),config['MaintainKickCause'])
	end
end
luaapi:Listen('onRespawn',reeeeepanick)
luaapi:Listen('onServerCmd',serverMaintain)
print('[INFO] [CMOTD] load!')
print('[INFO] [CMOTD] 作者:Lition')