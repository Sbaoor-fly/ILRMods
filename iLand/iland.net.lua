----------------------------------------
-- Author: RedbeanW -- License: GPLv3 --
----------------------------------------
-------【 交流QQ群：819566672 】--------
----------------------------------------
-- 插件版本，请勿修改
local plugin_version = '1.0.6'
-- 初始化变量
local beingNewLand_lic = {}
local beingNewLand_posA = {}
local beingNewLand_posB = {}
local beingNewLand_dim = {}
local beingNewLand_landprice = {}
local beingNewLand_nowMode = {}
local beingNewLand_formId={}
local TRS_Form={}
-- Check File and Load Library
if (tool:IfFile('./ilua/lib/json.lua') == false) then
    print('[iLand] Where is my json library??!!')
    return false
end
if (tool:IfFile('./ilua/iland/config.json') == false) then
    print('[iLand] Where is my config file??!!')
    return false
end
if (tool:IfFile('./ilua/xuiddb.net.lua') == false) then
    print('[iLand] Where is my depend plugin(xuiddb)??!!')
    return false
end
local json = require('./ilua/lib/json')
-- Encode Json File
cfg = json.decode(tool:ReadAllText('./ilua/iland/config.json'))
land_data = json.decode(tool:ReadAllText('./ilua/iland/data.json'))
land_owners = json.decode(tool:ReadAllText('./ilua/iland/owners.json'))
do --update configure file
	if(cfg.version==nil) then --version<1.0.4
		cfg.version={};cfg.version=103
		cfg.manager.operator={}
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\config.json',json.encode(cfg))
	end
	if(cfg.version==103) then
		cfg.version=106
		cfg.manager.allow_op_delete_land=nil
		for landId, val in pairs(land_data) do
			if(land_data[landId].range==nil) then
				land_data[landId]=nil
			end
		end
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\config.json',json.encode(cfg))
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
	end
end
-- Functions
function Event_PlayerMove(a)
	TRS_Form[a.playername].nowpos=a.XYZ
	TRS_Form[a.playername].nowdim=a.dimensionid
end
function Event_PlayerJoin(a)
	TRS_Form[a.playername]={}
end
function Event_PlayerLeft(a)
	local f = isValInList(beingNewLand_lic, playername)
    if (f == -1) then return end
	beingNewLand_lic[f]=-1 --cleanup
	beingNewLand_dim[f]=-1
	beingNewLand_landprice[f]=-1
	beingNewLand_nowMode[f]=-1
	beingNewLand_posA[f]=-1
	beingNewLand_posB[f]=-1
	beingNewLand_formId[f]=-1
end
function Monitor_CommandArrived(a)
    local uuid = luaapi:GetUUID(a.playername)
	local xuid = luaapi:GetXUID(a.playername)
    local key = string.gsub(a.cmd, ' ', '', 1)
	local land_count = ''
    if (string.len(key) == 5 and key == '/land') then
		if(land_owners[xuid]==nil) then
			land_count='0'
		else
			land_count=tostring(#land_owners[xuid])
		end
        mc:sendModalForm(uuid, 'Land v' .. plugin_version, '欢淫使用领地系统，宁现在有'..land_count..'块领地。\n今日地价：'..cfg.land_buy.price_ground..cfg.scoreboard.credit_name..'/平面格, '..cfg.land_buy.price_sky..cfg.scoreboard.credit_name..'/高', '爷知道了', '关闭')
        return false
    end
    if (string.len(key) > 5 and string.sub(key, 1, 5) == '/land') then
        key = string.sub(key, 6, string.len(key))
    else
        return true
    end
    --- COMMANDS ---
    if (key == 'new') then
        Func_Buy_getLicense(a.playername)
    end
    if (key == 'a') then
        Func_Buy_selectRange(a.playername, a.XYZ, a.dimensionid, 0)
    end
    if (key == 'b') then
        Func_Buy_selectRange(a.playername, a.XYZ, a.dimensionid, 1)
    end
    if (key == 'buy') then
        Func_Buy_createOrder(a.playername)
    end
	if (key == 'giveup') then
		Func_Buy_giveup(a.playername)
	end
	if (key == 'gui') then
		Func_Manager_open(a.playername)
	end
    return false
end
function Monitor_FormArrived(a)
	if(a.selected=='null') then return end
	if(a.selected=='false') then return end
	local xuid=luaapi:GetXUID(a.playername)
	local lid=TRS_Form[a.playername].landid --正在操作的landid
    local f = isValInList(beingNewLand_lic, a.playername)
	--- Buy Land ---
    if (f ~= -1) then
        Func_Buy_callback(f, a.formid, a.selected)
    end
	--- Mgr Land ---
	if(TRS_Form[a.playername].mgr==a.formid) then
		Func_Manager_callback(a.playername,a.selected)
		return
	end
	-- Land Perms ---
	-- [1]null     [2]PlaceBlock [3]DestoryBlock [4]openChest [5]Attack 
	-- [6]DropItem [7]PickupItem [8]UseItem      [9]null      [10]Explode
	if(TRS_Form[a.playername].lperm==a.formid) then
		local result=json.decode(a.selected)
		land_data[lid].setting.allow_destory=result[3]
		land_data[lid].setting.allow_place=result[2]
		land_data[lid].setting.allow_exploding=result[10]
		land_data[lid].setting.allow_attack=result[5]
		land_data[lid].setting.allow_open_chest=result[4]
		land_data[lid].setting.allow_pickupitem=result[7]
		land_data[lid].setting.allow_dropitem=result[6]
		land_data[lid].setting.allow_use_item=result[8]
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
		mc:runcmd('title "' .. a.playername .. '" actionbar 成功')
	end
	--- Del Land ---
	if(TRS_Form[a.playername].delland==a.formid) then
		mc:runcmd('scoreboard players add "' .. a.playername .. '" ' .. cfg.scoreboard.name .. ' ' .. TRS_Form[a.playername].landvalue)
		land_data[lid]=nil
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\owners.json',json.encode(land_owners))
		mc:runcmd('title "' .. a.playername .. '" actionbar 成功')
	end
	--- Land Trust ---
	if(TRS_Form[a.playername].ltrust==a.formid) then
		-- [1]null [2]true [3]0 [4]false [5]0
		local result=json.decode(a.selected)
		if(result[2]==true) then
			local x=luaapi:GetXUID(TRS_Form[a.playername].online[result[3]+1])
			local n=#land_data[lid].setting.share+1
			if(luaapi:GetXUID(a.playername)==x) then
				mc:runcmd('title "' .. a.playername .. '" actionbar 不能将您自己添加到信任列表中')
				return
			end
			if(isValInList(land_data[lid].setting.share,x)~=-1) then
				mc:runcmd('title "' .. a.playername .. '" actionbar 该玩家已存在于信任列表中')
				return
			end
			land_data[lid].setting.share[n]=x
			tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
			mc:runcmd('title "' .. a.playername .. '" actionbar 成功')
		end
		if(result[4]==true) then
			if(#land_data[lid].setting.share==0) then return end 
			local x=land_data[lid].setting.share[result[5]+1]
			table.remove(land_data[lid].setting.share,isValInList(land_data[lid].setting.share,x))
			tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
			mc:runcmd('title "' .. a.playername .. '" actionbar 成功')
		end
	end
	--- Land Tag ---
	if(TRS_Form[a.playername].ltag==a.formid) then
		local result=json.decode(a.selected)
		if(string.find(result[2],'"',1)~=nil or string.find(result[2],'\\',1)~=nil or string.find(result[2],',',1)~=nil) then --防止有nt玩家搞事
			mc:runcmd('title "' .. a.playername .. '" actionbar NMSL')
			return
		end
		local btag=string.find(lid,'_')
		local wdnmd=lid
		if(btag~=nil) then
			wdnmd=string.sub(lid,0,btag-1)
		end
		local tag=wdnmd..'_'..result[2]
		land_data[tag]=deepcopy(land_data[lid])
		land_data[lid]=nil
		table.insert(land_owners[xuid],#land_owners[xuid]+1,tag)
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
		tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\owners.json',json.encode(land_owners))
		mc:runcmd('title "' .. a.playername .. '" actionbar 成功')
	end
end
function Func_Buy_giveup(playername)
	local f = isValInList(beingNewLand_lic, playername)
    if (f == -1) then
        mc:runcmd('title "' .. playername .. '" actionbar 没有可以放弃的圈地许可')
        return
    end
	beingNewLand_lic[f]=-1 --cleanup
	beingNewLand_dim[f]=-1
	beingNewLand_landprice[f]=-1
	beingNewLand_nowMode[f]=-1
	beingNewLand_posA[f]=-1
	beingNewLand_posB[f]=-1
	beingNewLand_formId[f]=-1
	mc:runcmd('title "' .. playername .. '" actionbar 许可：'..f..' 已放弃')
end
function Func_Buy_createOrder(playername)
    local f = isValInList(beingNewLand_lic, playername) --用玩家名获取索引
    local uuid = luaapi:GetUUID(playername)
	local xuid = luaapi:GetXUID(playername)
    if (beingNewLand_nowMode[f] ~= 2) then
        mc:runcmd('title "' .. playername .. '" actionbar 购买失败！请按步骤圈地！')
        return
    end
    local length = math.abs(beingNewLand_posA[f].x - beingNewLand_posB[f].x)
    local width = math.abs(beingNewLand_posA[f].z - beingNewLand_posB[f].z)
    local height = math.abs(beingNewLand_posA[f].y - beingNewLand_posB[f].y)
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if(squ>cfg.land.land_max_square and isValInList(cfg.manager.operator,xuid)==-1) then
		mc:runcmd('title "' .. playername .. '" actionbar 所圈领地太大，请重新圈地。\n请使用“/land a”选择第一个点')
		beingNewLand_nowMode[f]=0
		return
	end
	if(squ<cfg.land.land_min_square and isValInList(cfg.manager.operator,xuid)==-1) then
		mc:runcmd('title "' .. playername .. '" actionbar 所圈领地太小，请重新圈地。\n请使用“/land a”选择第一个点')
		beingNewLand_nowMode[f]=0
		return
	end
	if(height<3) then
		mc:runcmd('title "' .. playername .. '" actionbar 三维圈地，高度至少在三格以上。\n请使用“/land a”选择第一个点')
		beingNewLand_nowMode[f]=0
		return
	end
	local edge=cubeGetEdge(beingNewLand_posA[f],beingNewLand_posB[f])
	for i=1,#edge do
		for landId, val in pairs(land_data) do
			if(land_data[landId].range==nil) then goto JUMPOUT_1 end --空land(deleted)直接跳过
			if(land_data[landId].range.dim~=beingNewLand_dim[f]) then goto JUMPOUT_1 end --维度不同直接跳过
			local s_pos={};s_pos.x=land_data[landId].range.start_x;s_pos.y=land_data[landId].range.start_y;s_pos.z=land_data[landId].range.start_z
			local e_pos={};e_pos.x=land_data[landId].range.end_x;e_pos.y=land_data[landId].range.end_y;e_pos.z=land_data[landId].range.end_z
			if(isPosInCube(edge[i],s_pos,e_pos)==true) then
				mc:runcmd('title "' .. playername .. '" actionbar 存在领地冲突，请重新圈地。\n请使用“/land a”选择第一个点')
				beingNewLand_nowMode[f]=0
				return
			end
			:: JUMPOUT_1 ::
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if(land_data[landId].range==nil) then goto JUMPOUT_2 end --空land(deleted)直接跳过
		if(land_data[landId].range.dim~=beingNewLand_dim[f]) then goto JUMPOUT_2 end --维度不同直接跳过
		s_pos={};e_pos={}
		s_pos.x=land_data[landId].range.start_x
		s_pos.y=land_data[landId].range.start_y
		s_pos.z=land_data[landId].range.start_z
		e_pos.x=land_data[landId].range.end_x
		e_pos.y=land_data[landId].range.end_y
		e_pos.z=land_data[landId].range.end_z
		edge=cubeGetEdge(s_pos,e_pos)
		for i=1,#edge do
			if(isPosInCube(edge[i],beingNewLand_posA[f],beingNewLand_posB[f])==true) then
				mc:runcmd('title "' .. playername .. '" actionbar 存在领地冲突，请重新圈地。\n请使用“/land a”选择第一个点')
				beingNewLand_nowMode[f]=0
				return
			end
		end
		:: JUMPOUT_2 ::
	end
	--- 购买
    beingNewLand_landprice[f] = math.floor(squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)
    beingNewLand_formId[f] = mc:sendModalForm(uuid,'领地购买','圈地成功！\n长\\宽\\高: ' ..length ..'\\' ..width..'\\' ..height..'格\n体积: ' ..vol..'块\n价格: ' ..beingNewLand_landprice[f] ..cfg.scoreboard.credit_name .. '\n钱包: ' .. mc:getscoreboard(uuid, cfg.scoreboard.name) .. cfg.scoreboard.credit_name,'购买','放弃')
end
function Func_Buy_selectRange(playername, xyz, dim, mode)
    local f = isValInList(beingNewLand_lic, playername)
    if (f == -1) then
        mc:runcmd('title "' .. playername .. '" actionbar 没有圈地许可!!\n请先使用“/land new”获取')
        return
    end
    if (mode == 0) then --posA
        if (mode ~= beingNewLand_nowMode[f]) then
            mc:runcmd('title "' .. playername .. '" actionbar 选点失败！请按步骤圈地！')
            return
        end
		beingNewLand_dim[f] = dim
		beingNewLand_posA[f] = xyz
		beingNewLand_posA[f].x=math.floor(beingNewLand_posA[f].x) --省函数...
		beingNewLand_posA[f].y=math.floor(beingNewLand_posA[f].y)-2
		beingNewLand_posA[f].z=math.floor(beingNewLand_posA[f].z)
		mc:runcmd('title "' ..playername .. '" actionbar DIM='..beingNewLand_dim[f]..'\nX=' .. beingNewLand_posA[f].x .. '\nY=' .. beingNewLand_posA[f].y .. '\nZ=' .. beingNewLand_posA[f].z ..'\n请使用“/land b”选定第二个点')
        beingNewLand_nowMode[f] = 1
    end
    if (mode == 1) then --posB
        if (mode ~= beingNewLand_nowMode[f]) then
            mc:runcmd('title "' .. playername .. '" actionbar 选点失败！请按步骤圈地！')
            return
        end
        if (dim ~= beingNewLand_dim[f]) then
            mc:runcmd('title "' .. playername .. '" actionbar 选点失败！禁止跨纬度选点！')
            return
        end
		beingNewLand_posB[f] = xyz
		beingNewLand_posB[f].x=math.floor(beingNewLand_posB[f].x)
		beingNewLand_posB[f].y=math.floor(beingNewLand_posB[f].y)-2
		beingNewLand_posB[f].z=math.floor(beingNewLand_posB[f].z)
		mc:runcmd('title "' ..playername .. '" actionbar DIM='..beingNewLand_dim[f]..'\nX=' .. beingNewLand_posB[f].x .. '\nY=' .. beingNewLand_posB[f].y .. '\nZ=' .. beingNewLand_posB[f].z ..'\n请使用“/land buy”创建订单')
        beingNewLand_nowMode[f] = 2
    end
end
function Func_Buy_getLicense(playername)
    if (isValInList(beingNewLand_lic, playername) ~= -1) then
        mc:runcmd('title "' .. playername .. '" actionbar 请勿重复请求!!\n请使用“/land a”选定第一个点')
        return
    end
	if(land_owners[luaapi:GetXUID(playername)]~=nil and isValInList(cfg.manager.operator,luaapi:GetXUID(playername))==-1) then
		if(#land_owners[luaapi:GetXUID(playername)]>cfg.land.player_max_lands) then
			mc:runcmd('title "' .. playername .. '" actionbar 你想当地主是吧，无产阶级是不能有这么多地的。')
			return
		end
	end
    mc:runcmd('title "' .. playername .. '" actionbar 已请求新建领地\n现在请输入命令“/land a”')
    local f = #beingNewLand_lic + 1
    table.insert(beingNewLand_lic, f, playername) --圈地许可
    table.insert(beingNewLand_posA, f, 0)         --坐标A
    table.insert(beingNewLand_posB, f, 0)         --坐标B
    table.insert(beingNewLand_dim, f, 0)          --维度
    table.insert(beingNewLand_landprice, f, 0)    --价格
    table.insert(beingNewLand_nowMode, f, 0)      --目前圈地模式
	table.insert(beingNewLand_formId,f , 0)       --表单传递
end
function Func_Buy_callback(a, b, c)
	if(b~=beingNewLand_formId[a]) then
		return
	end
	local playername = beingNewLand_lic[a]
    local uuid = luaapi:GetUUID(playername)
	local xuid = luaapi:GetXUID(playername)
    local player_credits = mc:getscoreboard(uuid, cfg.scoreboard.name)
    if (c ~= 'true') then
        mc:runcmd('title "' .. playername .. '" actionbar 交易未完成。您的领地购买订单已暂存，可重新用“/land buy”打开\n放弃此次购买请使用“/land giveup”')
        return
    end
    if (beingNewLand_landprice[a] > player_credits) then
        mc:runcmd('title "' .. playername .. '" actionbar 余额不足！\n您的领地购买订单已暂存，可重新用“/land buy”打开\n放弃此次购买请使用“/land giveup”')
        return
    else
        mc:runcmd('scoreboard players remove "' .. playername .. '" ' .. cfg.scoreboard.name .. ' ' .. beingNewLand_landprice[a])
    end
    mc:runcmd('title "' .. playername .. '" actionbar 购买成功！\n正在为您注册领地...')
	math.randomseed(os.time())
	landId='id'..tostring(math.random(100000,999999))
	land_data[landId]={}
	land_data[landId].range={}
	land_data[landId].setting={}
	land_data[landId].range.start_x=beingNewLand_posA[a].x
	land_data[landId].range.start_z=beingNewLand_posA[a].z
	land_data[landId].range.start_y=beingNewLand_posA[a].y
	land_data[landId].range.end_x=beingNewLand_posB[a].x
	land_data[landId].range.end_z=beingNewLand_posB[a].z
	land_data[landId].range.end_y=beingNewLand_posB[a].y
	land_data[landId].range.dim=beingNewLand_dim[a]
	land_data[landId].setting.share={}
	land_data[landId].setting.allow_destory=false
	land_data[landId].setting.allow_place=false
	land_data[landId].setting.allow_exploding=false
	land_data[landId].setting.allow_attack=false
	land_data[landId].setting.allow_open_chest=false
	land_data[landId].setting.allow_pickupitem=false
	land_data[landId].setting.allow_dropitem=true
	land_data[landId].setting.allow_use_item=true
	tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\data.json',json.encode(land_data))
	if(land_owners[xuid]==nil) then
		land_owners[xuid]={}
	end
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	tool:WriteAllText(tool:WorkingPath()..'ilua\\iland\\owners.json',json.encode(land_owners))
	beingNewLand_lic[a]=-1 --cleanup
	beingNewLand_dim[a]=-1
	beingNewLand_landprice[a]=-1
	beingNewLand_nowMode[a]=-1
	beingNewLand_posA[a]=-1
	beingNewLand_posB[a]=-1
	beingNewLand_formId[a]=-1
	mc:runcmd('title "' .. playername .. '" actionbar 完成！\n尝试用“/land gui”管理您的领地！')
end
function Func_Manager_open(playername)
	local uuid=luaapi:GetUUID(playername)
	local xuid=luaapi:GetXUID(playername)
	local welcome='Welcome to use Land Manager.'
	lid=Func_GetlandFromPos(TRS_Form[playername].nowpos,TRS_Form[playername].nowdim)
	if(lid~=-1) then
		welcome=welcome..'\n您现在正在: §l'..lid..' §r上'
	end
	if(land_owners[xuid]~=nil) then
		if(#land_owners[xuid]==0) then
			mc:runcmd('title "' .. playername .. '" actionbar 你还没有领地哦，使用“/land new”开始创建一个吧！')
			return
		end
	else
		mc:runcmd('title "' .. playername .. '" actionbar 你还没有领地哦，使用“/land new”开始创建一个吧！')
		return
	end
	TRS_Form[playername].mgr = mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..welcome..'"},{"default":0,"steps":["查看领地信息","编辑领地权限","编辑信任名单","编辑领地Tag","删除领地"],"type":"step_slider","text":"选择要进行的操作"},{"default":0,"options":'..json.encode(land_owners[xuid])..',"type":"dropdown","text":"选择你要管理的领地"}],"type":"custom_form","title":"选择目标领地"}}]}')
end
function Func_Manager_callback(a,b) --a=playername b=selected
	local xuid=luaapi:GetXUID(a)
	local uuid=luaapi:GetUUID(a)
	local result=json.decode(b)
	TRS_Form[a].landid=land_owners[xuid][result[3]+1] --对应玩家正在操作的 landid
	if(result[2]==0) then --查看领地信息
	    local length = math.abs(land_data[TRS_Form[a].landid].range.start_x - land_data[TRS_Form[a].landid].range.end_x)
		local width = math.abs(land_data[TRS_Form[a].landid].range.start_z - land_data[TRS_Form[a].landid].range.end_z)
		local height = math.abs(land_data[TRS_Form[a].landid].range.start_y - land_data[TRS_Form[a].landid].range.end_y)
		local vol = length * width * height
		local squ = length * width
		mc:sendModalForm(uuid,'领地信息','所有者:'..a..'\n范围(range): '..land_data[TRS_Form[a].landid].range.start_x..','..land_data[TRS_Form[a].landid].range.start_y..','..land_data[TRS_Form[a].landid].range.start_z..' -> '..land_data[TRS_Form[a].landid].range.end_x..','..land_data[TRS_Form[a].landid].range.end_y..','..land_data[TRS_Form[a].landid].range.end_z..'\n长/宽/高: '..length..'/'..width..'/'..height..'\n底面积: '..squ..' 平方格    体积: '..vol..' 立方格','爷知道了','关闭')
	end
	if(result[2]==1) then --编辑领地权限
		local d=land_data[TRS_Form[a].landid].setting
		TRS_Form[a].lperm=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"编辑陌生人在领地内所拥有的权限"},{"default":'..tostring(d.allow_place)..',"type":"toggle","text":"允许放置方块"},{"default":'..tostring(d.allow_destory)..',"type":"toggle","text":"允许破坏方块"},{"default":'..tostring(d.allow_open_chest)..',"type":"toggle","text":"允许开箱子"},{"default":'..tostring(d.allow_attack)..',"type":"toggle","text":"允许攻击生物"},{"default":'..tostring(d.allow_dropitem)..',"type":"toggle","text":"允许丢物品"},{"default":'..tostring(d.allow_pickupitem)..',"type":"toggle","text":"允许捡起物品"},{"default":'..tostring(d.allow_use_item)..',"type":"toggle","text":"允许使用物品"},{"type":"label","text":"编辑领地内可以发生的事件"},{"default":'..tostring(d.allow_exploding)..',"type":"toggle","text":"允许爆炸"}],"type":"custom_form","title":"Land Perms"}')
	end
	if(result[2]==2) then --编辑信任名单
		TRS_Form[a].online = getOnLinePlayerList()
		local d={}
		for i=1,#land_data[TRS_Form[a].landid].setting.share do --复制share列表中的每个元素，至于为什么不能直接赋值......
			d[i]=land_data[TRS_Form[a].landid].setting.share[i]
		end
		for i, v in pairs(d) do
			d[i]=getPlayernameFromXUID(d[i])
		end
		TRS_Form[a].ltrust=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"打开欲操作项的开关，完成后提交。"},{"default":false,"type":"toggle","text":"添加受信任玩家\n受信任玩家将拥有所有领地权限，但不能进行权限编辑或删除领地。"},{"type":"dropdown","text":"选择一个玩家","default":0,"options":'..json.encode(TRS_Form[a].online)..'},{"default":false,"type":"toggle","text":"删除受信任玩家"},{"type":"dropdown","text":"选择一个玩家","default":0,"options":'..json.encode(d)..'}],"type":"custom_form","title":"Land Trust"}')
	end
	if(result[2]==3) then --领地tag
		TRS_Form[a].ltag=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"领地Tag有助于您区分多个领地，而不改变原有的领地配置"},{"placeholder":"tag here","default":"","type":"input","text":""}],"type":"custom_form","title":"Land Tag"}')
	end
	if(result[2]==4) then --删除领地
		local height = math.abs(land_data[TRS_Form[a].landid].range.start_y - land_data[TRS_Form[a].landid].range.end_y)
		local squ = math.abs(land_data[TRS_Form[a].landid].range.start_x - land_data[TRS_Form[a].landid].range.end_x) * math.abs(land_data[TRS_Form[a].landid].range.start_z - land_data[TRS_Form[a].landid].range.end_z)
		TRS_Form[a].landvalue=math.floor((squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)*cfg.land_buy.refund_rate)
		TRS_Form[a].delland=mc:sendModalForm(uuid,'删除领地','您确定要删除您的领地吗？\n'..'如果确定，您将得到'..TRS_Form[a].landvalue..cfg.scoreboard.credit_name..'退款。然后您的领地将失去保护，配置文件将立刻删除。','确定','取消')
	end
end
-- Minecraft 监听事件
function onDestroyBlock(e)
	local lid=Func_GetlandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_destory==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false	
end
function onAttack(e)
	local lid=Func_GetlandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_attack==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onUseItem(e)
	local lid=Func_GetlandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_use_item==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onPlacedBlock(e)
	local lid=Func_GetlandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_place==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onLevelExplode(e)
	local lid=Func_GetlandFromPos(e.position,e.dimensionid)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_exploding==true) then return end --权限允许
	return false
end
function onStartOpenChest(e)
	local lid=Func_GetlandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_open_chest==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onPickUpItem(e)
	local lid=Func_GetlandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_pickupitem==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onDropItem(e)
	local lid=Func_GetlandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_dropitem==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil) then if(isValInList(land_owners[xuid],lid)~=-1) then return end end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
-- 拓展功能函数
function Func_GetlandFromPos(pos,dim)
	for landId, val in pairs(land_data) do
		if(land_data[landId].range==nil) then goto JUMPOUT_4 end
		if(land_data[landId].range.dim~=dim) then goto JUMPOUT_4 end
		local s_pos={};s_pos.x=land_data[landId].range.start_x;s_pos.y=land_data[landId].range.start_y;s_pos.z=land_data[landId].range.start_z
		local e_pos={};e_pos.x=land_data[landId].range.end_x;e_pos.y=land_data[landId].range.end_y;e_pos.z=land_data[landId].range.end_z
		if(isPosInCube(pos,s_pos,e_pos)==true) then
			return landId
		end
		:: JUMPOUT_4 ::
	end
	return -1
end
function getOnLinePlayerList()
	local list = {}
	local ylist = json.decode(mc:getOnLinePlayers())
	for i=1, #ylist do
		list[i]=ylist[i].playername
	end
	return list
end
function cubeGetEdge(posA,posB)
	local edge={}
	local p=0
	-- [Debug] print(edge[p].x,edge[p].y,edge[p].z,' ',edge[p-1].x,edge[p-1].y,edge[p-1].z,' ',edge[p-2].x,edge[p-2].y,edge[p-2].z,' ',edge[p-3].x,edge[p-3].y,edge[p-3].z)
	for i=1,math.abs(math.abs(posA.y)-math.abs(posB.y))+1 do
		if(posA.y>posB.y) then
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-i;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-i;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-i;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-i;edge[p].z=posA.z
		else
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y+i-2;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y+i-2;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y+i-2;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y+i-2;edge[p].z=posA.z
		end
	end
	for i=1,math.abs(math.abs(posA.x)-math.abs(posB.x))+1 do
		if(posA.x>posB.x) then
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posA.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posB.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posA.y-1;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posB.y-1;edge[p].z=posB.z
		else
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posA.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posB.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posA.y-1;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posB.y-1;edge[p].z=posB.z
		end
	end
	for i=1,math.abs(math.abs(posA.z)-math.abs(posB.z))+1 do
		if(posA.z>posB.z) then
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-1;edge[p].z=posA.z-i+1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-1;edge[p].z=posA.z-i+1
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posB.y-1;edge[p].z=posA.z-i+1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posB.y-1;edge[p].z=posA.z-i+1
		else
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-1;edge[p].z=posA.z+i-1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-1;edge[p].z=posA.z+i-1
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posB.y-1;edge[p].z=posA.z+i-1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posB.y-1;edge[p].z=posA.z+i-1
		end
	end
	return edge
end
function isPosInCube(pos,posA,posB)
	if((pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x)==true) then
		if((pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y)==true) then
			if((pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z)==true) then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
function isValInList(list, value)
	for i, nowValue in pairs(list) do
        if nowValue == value then
            return i
        end
    end
    return -1
end
function deepcopy(orig) --参(chao)考(xi)自lua-users.org
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
-- 注册监听
luaapi:Listen('onInputCommand', Monitor_CommandArrived)
luaapi:Listen('onFormSelect', Monitor_FormArrived)
luaapi:Listen('onLoadName', Event_PlayerJoin)
luaapi:Listen('onPlayerLeft', Event_PlayerLeft)
luaapi:Listen('onMove',Event_PlayerMove)
luaapi:Listen('onDestroyBlock',onDestroyBlock)
luaapi:Listen('onAttack',onAttack)
luaapi:Listen('onUseItem',onUseItem)
luaapi:Listen('onPlacedBlock',onPlacedBlock)
luaapi:Listen('onLevelExplode',onLevelExplode)
luaapi:Listen('onStartOpenChest',onStartOpenChest)
luaapi:Listen('onDropItem',onDropItem)
luaapi:Listen('onPickUpItem',onPickUpItem)
mc:setCommandDescribe('land', '领地系统主命令')
mc:setCommandDescribe('land new', '创建一个新领地')
mc:setCommandDescribe('land giveup', '放弃没有创建完成的领地')
mc:setCommandDescribe('land a', '三维圈地，选取第一个点')
mc:setCommandDescribe('land b', '三维圈地，选取第二个点')
mc:setCommandDescribe('land buy', '购买刚圈好的地')
mc:setCommandDescribe('land gui', '打开领地管理界面')
print('[ILand] plugin loaded! VER:' .. plugin_version)