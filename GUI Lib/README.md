# 使用方法
1. 在ilua文件夹创建GUI文件夹

2. 把写好的表单json放进去

3. 表单变量请用"$+(数字)"替代

# 调用方法

```lua
GUI('simple',luaapi:GetUUID(a.playername),data)
 --这会调用GUI文件夹的simple.json文件作为表单
```