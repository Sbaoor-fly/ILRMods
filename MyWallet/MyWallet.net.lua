function wallet_cmd(a)
    show = mc:getscoreboard(luaapi:GetUUID(a.playername),'money')
    if(a.cmd == '/wallet')then
        mc:sendModalForm(luaapi:GetUUID(a.playername),'账户余额查询','您的当前账户余额为：'..show,'爷知道了','爬')
        return false
    end
end
luaapi:Listen('onInputCommand',wallet_cmd)
mc:setCommandDescribe('wallet','账户余额查询')
print('[INFO] [Wallet] 余额查询装载成功')
print('[INFO] [Wallet] 作者：unlinus')
print('[INFO] [Wallet] 版本：1.0.0')