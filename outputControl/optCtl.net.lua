----------------------------------------
-- Author: RedbeanW -- License: GPLv3 --
----------------------------------------
-------- STAND WITH OPEN SOURCE --------
----------------------------------------
-- 插件版本，请勿修改
local plugin_version = '1.0.1'
-- 载入库
if (tool:IfFile('./ilua/lib/json.lua') == false) then
    print('[optCtl] Where is my json library??!!')
    return false
end
json = require('./ilua/lib/json')
-- 载入配置文件
if (tool:IfFile('./ilua/optCtl/config.json') == false) then
    print('[optCtl] Where is my config file??!!]')
    return false
end
local list = json.decode(tool:ReadAllText('./ilua/optCtl/config.json'))
-- 功能函数
function cleanOutput(a)
    opt = a.output
    for i, m in ipairs(list) do
        if (string.find(opt, m, 0) ~= nil) then
            return false
        end
    end
end
-- 注册监听
luaapi:Listen('onServerCmdOutput', cleanOutput)
print('[optCtl] plugin loaded! VER:' .. plugin_version)
