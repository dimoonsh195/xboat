-- by dimoonsh == github dimoonsh195 --
if game.PlaceId ~= 537413528 then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "[Xboat] ERROR", Text = "This script only works in Build A Boat For Treasure", Duration = 5
    })
    return
end
print("XBOAT | v 2.5.7 | by dimoonsh")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

hideP, showP = nil, nil
bindActions = {}

BlocksFolder = workspace:FindFirstChild("Blocks") or workspace:FindFirstChild("Block")
BlockData = player:FindFirstChild("Data")

-- utils
function getBlockID(n)
    if BlockData then local c = BlockData:FindFirstChild(n); if c then return c.Value end end
    return 0
end
function getPlayerZone(plr)
    for _, zone in pairs(workspace:GetChildren()) do
        if zone:FindFirstChild("TeamColor") and zone.TeamColor.Value == plr.TeamColor then return zone end
    end
end
function equipAllTools()
    local ch = player.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local names = {"BuildingTool","PaintingTool","PropertiesTool","ScalingTool","DeleteTool","TrowelTool","BindTool"}
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            for _, bn in ipairs(names) do
                if tool.Name == bn then
                    pcall(function() hum:EquipTool(tool) end)
                    break
                end
            end
        end
    end
    task.wait(0.1)
end
function strCF(s)
    if type(s) ~= "string" then return nil end
    local c = {}
    for v in s:gmatch("[^,]+") do local n = tonumber(v:match("^%s*(.-)%s*$")); if n then table.insert(c, n) end end
    if #c >= 12 then return CFrame.new(table.unpack(c)) end
    return nil
end
function strV3(s)
    if type(s) == "table" then
        if s.X and s.Y and s.Z then return s end
        return Vector3.new(tonumber(s[1]) or 0, tonumber(s[2]) or 0, tonumber(s[3]) or 0)
    elseif type(s) == "string" then
        local nums = {}
        for v in s:gmatch("[^,]+") do local n = tonumber(v:match("^%s*(.-)%s*$")); if n then table.insert(nums, n) end end
        if #nums >= 3 then return Vector3.new(nums[1], nums[2], nums[3]) end
    end
    return Vector3.zero
end
function strCol(s)
    if type(s) ~= "string" then return Color3.new(1,1,1) end
    local c = {}; for v in s:gmatch("[^,]+") do table.insert(c, tonumber(v) or 1) end
    if #c >= 3 then
        local r,g,b = c[1],c[2],c[3]
        if r > 1 or g > 1 or b > 1 then r=r/255; g=g/255; b=b/255 end
        return Color3.new(math.clamp(r,0,1), math.clamp(g,0,1), math.clamp(b,0,1))
    end
    return Color3.new(1,1,1)
end
function getBlockCF(bi)
    if bi.CFrame then
        if type(bi.CFrame) == "string" then local cf = strCF(bi.CFrame); if cf then return cf end
        elseif type(bi.CFrame) == "table" and #bi.CFrame >= 12 then return CFrame.new(table.unpack(bi.CFrame)) end
    end
    local p = bi.Position or bi.position or bi.Pos or bi.pos
    if p then
        local pos = strV3(p)
        local r = bi.Rotation or bi.rotation or bi.Rot or bi.rot
        if r then
            local rot = strV3(r)
            return CFrame.new(pos) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
        end
        return CFrame.new(pos)
    end
    return CFrame.new(0,0,0)
end

-- auto build engine
function pasteBuild(data, cb)
    if not data or not next(data) then return false end
    local myZone = getPlayerZone(player)
    if not myZone then warn("[XBOAT] Не удалось найти зону игрока"); return false end

    equipAllTools()
    local ch = player.Character
    if not ch then warn("[XBOAT] Нет персонажа"); return false end

    local buildingTool = ch:FindFirstChild("BuildingTool") or player.Backpack:FindFirstChild("BuildingTool")
    if not buildingTool then warn("[XBOAT] Нет BuildingTool"); return false end
    local placeRF = buildingTool:FindFirstChild("RF")
    if not placeRF then warn("[XBOAT] Нет BuildingTool.RF"); return false end

    local scaleRF = ch:FindFirstChild("ScalingTool") and ch.ScalingTool:FindFirstChild("RF")
    local paintRF = ch:FindFirstChild("PaintingTool") and ch.PaintingTool:FindFirstChild("RF")
    local propRF = ch:FindFirstChild("PropertiesTool") and ch.PropertiesTool:FindFirstChild("SetPropertieRF")

    local total = 0
    for _, b in pairs(data) do total = total + #b end
    if total == 0 then warn("[XBOAT] Нет блоков для постройки"); return false end

    local placed, failed = 0, 0
    for bn, blocks in pairs(data) do
        for _, bi in ipairs(blocks) do
            if not ch or not ch.Parent then break end

            local worldCF = getBlockCF(bi)
            local localCF = myZone.CFrame:ToObjectSpace(worldCF)

            local args = {
                bn,
                getBlockID(bn),
                myZone,
                localCF,
                true,
                worldCF,
                false
            }

            local ok = pcall(function()
                placeRF:InvokeServer(table.unpack(args))
            end)

            if not ok then
                failed = failed + 1
                warn("[XBOAT] Ошибка при установке блока " .. bn .. " (ID " .. getBlockID(bn) .. ")")
            else
                placed = placed + 1
            end

            if placed % 30 == 0 and cb then
                cb(("Установлено %d/%d (ошибок: %d)"):format(placed, total, failed))
            end
            task.wait(0.05)
        end
    end

    task.wait(2)
    local folder = BlocksFolder and BlocksFolder:FindFirstChild(player.Name)
    if not folder then warn("[XBOAT] Папка с блоками не найдена, пропускаем пост-обработку"); return placed > 0 end

    local list = folder:GetChildren()
    local idx = 1
    for bn, blocks in pairs(data) do
        for _, bi in ipairs(blocks) do
            local b = list[idx]
            idx = idx + 1
            if b and b:FindFirstChild("PPart") then
                local worldCF = getBlockCF(bi)
                local size = bi.Size and strV3(bi.Size) or Vector3.new(4,4,4)
                local col = bi.Col and strCol(bi.Col) or Color3.new(1,1,1)

                if scaleRF then pcall(function() scaleRF:InvokeServer(b, size, worldCF) end) end
                if paintRF then pcall(function() paintRF:InvokeServer({{b, col}}) end) end
                if propRF then
                    if bi.Transparency ~= nil then
                        pcall(function() propRF:InvokeServer("Transparency", {b}, tostring(math.floor((bi.Transparency or 0)*100))) end)
                    end
                    if bi.CanCollide == false and b.PPart.CanCollide then
                        pcall(function() propRF:InvokeServer("Collision", {b}) end)
                    end
                end
            end
        end
    end

    if cb then
        cb(("Готово! Установлено: %d, Ошибок: %d"):format(placed, failed))
    end
    return placed > 0
end

-- vars
accF, accO, accB = Color3.fromRGB(229,233,255), Color3.fromRGB(255,255,255), Color3.fromRGB(22,31,36)
flying, flySpeed, bodyVel, bodyGyr = false, 50, nil, nil
wsVal, wsOn, noclipOn, noclipConn = 16, false, false, nil
espOn, espB, espH, espS = false, false, false, false
wallColor, espObj, skelData = Color3.fromRGB(255,60,60), {}, {}
fbOn = false
origFOV = camera.FieldOfView
origL = {Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd, FogColor=Lighting.FogColor}
MAX_FS, MAX_WS, MIN_FS, MIN_WS = 2000, 1000, 10, 16
PINE_PRICE = 80
sVol = 0.5
sCache = {}
rStroke = nil
pickerRefresh = {}

-- fling
emoteFlingOn, emoteFlingTrack = false, nil
lastFlingTime = 0
FIRE_COOLDOWN = 0.5
flingDuration = 2
antiFlingOn, antiFlingConn = false, nil
lastSafeCF = nil
isRecovering = false
presetIndex = 1
PresetAnims = {
    {"Dropkick", "133566007754001"},
    {"Dropkicking [TRENDY]", "90717656419568"},
    {"Tenna Kick", "118139885865308"},
    {"MMA Kick", "88347541858075"},
    {"Slap", "108225134235478"},
    {"Slap2", "78221709455150"},
    {"Push", "135890160317037"},
    {"Push2", "82070755455634"},
}

-- jump
infJumpOn = false
infJumpConn = nil
_unloading = false

-- antiafk
antiAfkOn = false
antiAfkConn = nil
ANTI_AFK_INTERVAL = 300

-- fonts
fontList = {
    {name="Gotham",     font=Enum.Font.Gotham},
    {name="Code",       font=Enum.Font.Code},
    {name="GothamBold", font=Enum.Font.GothamBold},
}
fontIndex = 2

-- cfg
_loadedCfg = nil
_loadedBinds = nil
_loadedFontName = nil
_loadedEmoteId = nil
_loadedFlingDuration = nil
_loadedFov = nil

-- lang
curLang = "en"
Str = {
    en = {
        main="Main", player="Player", visuals="Visuals", build="Build", babft="Babft", binds="Binds", settings="Settings",
        fly="Fly", noclip="Noclip", ws="WalkSpeed", antifling="AntiFling", infjump="Infinite Jump",
        wallhack="Wallhack", box="Box", highlight="Highlight", skeleton="Skeleton", fullbright="Fullbright",
        sweetfarm="Candyfarm", autofarm="Autofarm (VIP recommended)", antiafk="Anti-AFK",
        fly_on="Fly: On", fly_off="Fly: Off", fly_speed="Fly speed: ", ws_speed="WalkSpeed: ", ws_off=" (Off)", apply_ws="Apply WalkSpeed", reset_ws="Reset WalkSpeed",
        noclip_on="Noclip: On", noclip_off="Noclip: Off",
        wallhack_on="Wallhack: On", wallhack_off="Wallhack: Off", box_on="Box: On", box_off="Box: Off", hl_on="Hl: On", hl_off="Hl: Off", skel_on="Skel: On", skel_off="Skel: Off",
        fov="FOV: ", day="Day", sunset="Sunset", night="Night", fullbright_on="Fullbright: On", fullbright_off="Fullbright: Off", reset_vis="Reset visuals",
        pine_shop="Pinetree shop", gold=" gold", buy_pine="Buy pine trees", sweetfarm_on="Candyfarm: On", sweetfarm_off="Candyfarm: Off", only_halloween="only halloween",
        autofarm_on="Autofarm: On", autofarm_off="Autofarm: Off", reset="Reset", auto_build="Auto build",
        antiafk_on="Anti-AFK: On", antiafk_off="Anti-AFK: Off",
        save="Save ", load="Load ", unload="Unload script", sound="Sound: ", language="Language:", file="file: ", ok="[OK]", err="[ERR]", search="Search...",
        accent_lbl="Accent", outline_lbl="Outline", background_lbl="Background", wall_lbl="Wall color",
        binds_info="Click a button, then press a key. Esc cancels.",
        bind_clear="Clear all binds", bind_unbound="Unbound", bind_press="Press key...",
        bind_set="Bound", bind_cleared="All binds cleared", bind_cleared_n="Removed all binds (Menu kept on Tab)",
        cycle_preset="Next Preset", fling_duration="Duration:", font_lbl="Font:"
    },
    ru = {
        main="Главная", player="Игрок", visuals="Визуалы", build="Постройка", babft="Babft", binds="Бинды", settings="Настройки",
        fly="Полет", noclip="Noclip", ws="Скорость", antifling="AntiFling", infjump="Бесконечный прыжок",
        wallhack="Wallhack", box="Box", highlight="Highlight", skeleton="Skeleton", fullbright="Fullbright",
        sweetfarm="Кэндифарм", autofarm="Автофарм (VIP recommended)", antiafk="Anti-AFK",
        fly_on="Полет: Вкл", fly_off="Полет: Выкл", fly_speed="Скорость полета: ", ws_speed="Скорость ходьбы: ", ws_off=" (Выкл)", apply_ws="Применить скорость", reset_ws="Сбросить скорость",
        noclip_on="Noclip: Вкл", noclip_off="Noclip: Выкл",
        wallhack_on="Wallhack: Вкл", wallhack_off="Wallhack: Выкл", box_on="Box: Вкл", box_off="Box: Выкл", hl_on="Hl: Вкл", hl_off="Hl: Выкл", skel_on="Skel: Вкл", skel_off="Skel: Выкл",
        fov="FOV: ", day="День", sunset="Закат", night="Ночь", fullbright_on="Fullbright: Вкл", fullbright_off="Fullbright: Выкл", reset_vis="Сбросить визуалы",
        pine_shop="Магазин ели", gold=" золота", buy_pine="Купить ели", sweetfarm_on="Кэндифарм: Вкл", sweetfarm_off="Кэндифарм: Выкл", only_halloween="только хэллоуин",
        autofarm_on="Автофарм: Вкл", autofarm_off="Автофарм: Выкл", reset="Ресет", auto_build="Авто-постройка",
        antiafk_on="Anti-AFK: Вкл", antiafk_off="Anti-AFK: Выкл",
        save="Сохранить ", load="Загрузить ", unload="Выгрузить", sound="Звук: ", language="Язык:", file="файл: ", ok="[ОК]", err="[ОШИБКА]", search="Поиск...",
        accent_lbl="Акцент", outline_lbl="Обводка", background_lbl="Фон", wall_lbl="Цвет Wallhack",
        binds_info="Нажми кнопку, потом клавишу. Esc отменяет.",
        bind_clear="Очистить все бинды", bind_unbound="Не задан", bind_press="Жми клавишу...",
        bind_set="Забинжено", bind_cleared="Все бинды очищены", bind_cleared_n="Удалены все бинды (Menu на Tab)",
        cycle_preset="Следующий пресет", fling_duration="Длительность:", font_lbl="Шрифт:"
    },
    zh = {
        main="主页", player="玩家", visuals="视觉", build="建造", babft="Babft", binds="绑定", settings="设置",
        fly="飞行", noclip="穿墙", ws="速度", antifling="防甩", infjump="无限跳跃",
        wallhack="透视", box="方框", highlight="高亮", skeleton="骨骼", fullbright="全亮",
        sweetfarm="糖果农场", autofarm="自动农场 (推荐VIP)", antiafk="防挂机",
        fly_on="飞行:开", fly_off="飞行:关", fly_speed="飞行速度: ", ws_speed="行走速度: ", ws_off=" (关)", apply_ws="应用速度", reset_ws="重置速度",
        noclip_on="穿墙:开", noclip_off="穿墙:关",
        wallhack_on="透视:开", wallhack_off="透视:关", box_on="方框:开", box_off="方框:关", hl_on="高亮:开", hl_off="高亮:关", skel_on="骨骼:开", skel_off="骨骼:关",
        fov="视场: ", day="白天", sunset="日落", night="夜晚", fullbright_on="全亮:开", fullbright_off="全亮:关", reset_vis="重置视觉",
        pine_shop="松树商店", gold=" 金币", buy_pine="购买松树", sweetfarm_on="糖果农场:开", sweetfarm_off="糖果农场:关", only_halloween="仅万圣节",
        autofarm_on="自动农场:开", autofarm_off="自动农场:关", reset="重置", auto_build="自动建造",
        antiafk_on="防挂机:开", antiafk_off="防挂机:关",
        save="保存 ", load="加载 ", unload="卸载脚本", sound="音量: ", language="语言:", file="文件: ", ok="[好]", err="[错]", search="搜索...",
        accent_lbl="强调色", outline_lbl="描边", background_lbl="背景", wall_lbl="透视颜色",
        binds_info="点击按钮然后按键，Esc取消。",
        bind_clear="清除所有绑定", bind_unbound="未绑定", bind_press="按键...",
        bind_set="已绑定", bind_cleared="所有绑定已清除", bind_cleared_n="已清除所有绑定（菜单仍为Tab）",
        cycle_preset="下一个预设", fling_duration="时长:", font_lbl="字体:"
    }
}
function T(k) return Str[curLang][k] or Str.en[k] or k end

lE = {tabs={}, btns={}, labels={}, sliders={}, misc={}}
sFills, sBgs, kStrokes = {}, {}, {}
CFG = {"xboat_1.json", "xboat_2.json", "xboat_3.json"}

-- sound
function snd(n, p)
    if sVol <= 0 then return end
    local s = sCache[n]
    if not s then s = Instance.new("Sound"); s.SoundId = "rbxassetid://6895079853"; s.Parent = SoundService; sCache[n] = s end
    s.Volume = sVol; if p then s.PlaybackSpeed = p end
    pcall(function() s:Play() end)
end

-- save/load
function saveCfg(i)
    if type(writefile) ~= "function" or not CFG[i] then return false end
    local bindData = {}
    if bindState and bindState.binds then
        for name, key in pairs(bindState.binds) do
            if typeof(key) == "EnumItem" then bindData[name] = key.Name end
        end
    end
    local togglesData = {
        wsOn=wsOn, noclipOn=noclipOn, espOn=espOn, espB=espB, espH=espH, espS=espS,
        fbOn=fbOn, antiFlingOn=antiFlingOn, infJumpOn=infJumpOn,
        sFarm=sFarm, farm=_G_Farm, antiAfk=antiAfkOn,
    }
    local d = {
        accentFill={accF.R,accF.G,accF.B}, accentOutline={accO.R,accO.G,accO.B}, accentBg={accB.R,accB.G,accB.B},
        wallColor={wallColor.R, wallColor.G, wallColor.B},
        flySpeed=flySpeed, walkSpeedValue=wsVal, soundVolume=sVol,
        fovValue=camera.FieldOfView, flingDuration=flingDuration,
        language=curLang,
        fontName=fontList[fontIndex] and fontList[fontIndex].name or "Code",
        emoteAnimId = emoteIdBox and emoteIdBox.Text or "",
        toggles=togglesData,
        binds=bindData,
    }
    local ok, js = pcall(function() return HttpService:JSONEncode(d) end)
    if ok then return pcall(writefile, CFG[i], js) end
    return false
end

function loadCfg(i)
    _loadedCfg = nil; _loadedBinds = nil; _loadedFontName = nil; _loadedEmoteId = nil; _loadedFlingDuration = nil; _loadedFov = nil
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not CFG[i] or not isfile(CFG[i]) then return false end
    local ok, raw = pcall(readfile, CFG[i]); if not ok or not raw then return false end
    local okD, d = pcall(function() return HttpService:JSONDecode(raw) end); if not okD or type(d) ~= "table" then return false end
    local function c(t, cur) if type(t)=="table" and t[1] then return Color3.new(t[1],t[2],t[3]) end return cur end
    accF, accO, accB = c(d.accentFill,accF), c(d.accentOutline,accO), c(d.accentBg,accB)
    wallColor = c(d.wallColor, wallColor)
    if tonumber(d.flySpeed) then flySpeed = math.clamp(d.flySpeed,MIN_FS,MAX_FS) end
    if tonumber(d.walkSpeedValue) then wsVal = math.clamp(d.walkSpeedValue,MIN_WS,MAX_WS) end
    if tonumber(d.soundVolume) then sVol = math.clamp(d.soundVolume,0,1) end
    if type(d.language) == "string" and Str[d.language] then curLang = d.language end
    if type(d.fontName) == "string" then _loadedFontName = d.fontName end
    if type(d.emoteAnimId) == "string" then _loadedEmoteId = d.emoteAnimId end
    if tonumber(d.flingDuration) then _loadedFlingDuration = math.clamp(math.floor(d.flingDuration),1,2) end
    if tonumber(d.fovValue) then _loadedFov = math.clamp(d.fovValue,70,120) end
    if type(d.binds) == "table" then _loadedBinds = d.binds end
    if type(d.toggles) == "table" then _loadedCfg = d.toggles end
    for _, e in pairs(espObj) do
        if e.highlight and e.highlight.Parent then e.highlight.FillColor = wallColor; e.highlight.OutlineColor = wallColor end
        if e.box and e.box.Parent then e.box.Color3 = wallColor end
    end
    for _, s in pairs(skelData) do for _, i in ipairs(s.lines) do if i.line then i.line.Color = wallColor end end end
    return true
end
for i = 1, #CFG do if loadCfg(i) then break end end

-- colors
function br(c,a) return Color3.new(math.clamp(c.R+a,0,1),math.clamp(c.G+a,0,1),math.clamp(c.B+a,0,1)) end
function dr(c,a) return Color3.new(math.clamp(c.R-a,0,1),math.clamp(c.G-a,0,1),math.clamp(c.B-a,0,1)) end
function lum(c) return 0.299*c.R+0.587*c.G+0.114*c.B end
function txtC(c) return lum(c)>0.6 and Color3.fromRGB(30,22,10) or Color3.new(1,1,1) end
function txtBg() return lum(accB)>0.55 and Color3.fromRGB(55,42,20) or Color3.fromRGB(235,235,240) end
function cStroke(c) return lum(c)>0.5 and Color3.fromRGB(40,40,40) or Color3.fromRGB(210,210,210) end
function offC() return lum(accB)>0.55 and dr(accB,0.1) or br(accB,0.1) end
function tabOffC() return lum(accB)>0.55 and dr(accB,0.08) or br(accB,0.08) end
function grad(o,c1,c2,r)
    local g = o:FindFirstChildOfClass("UIGradient")
    if not g then g = Instance.new("UIGradient"); g.Parent = o end
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c2)})
    g.Rotation = r or 90
end

if CoreGui:FindFirstChild("XboatGui") then CoreGui.XboatGui:Destroy() end
if CoreGui:FindFirstChild("XboatLoading") then CoreGui.XboatLoading:Destroy() end
if CoreGui:FindFirstChild("XboatNotify") then CoreGui.XboatNotify:Destroy() end
if CoreGui:FindFirstChild("XboatCursor") then CoreGui.XboatCursor:Destroy() end
if CoreGui:FindFirstChild("XboatColorPicker") then CoreGui.XboatColorPicker:Destroy() end
if CoreGui:FindFirstChild("XboatLock") then CoreGui.XboatLock:Destroy() end

FH, FB = Enum.Font.Code, Enum.Font.Code
LD = 2.0

-- cursor
cursorGui = Instance.new("ScreenGui"); cursorGui.Name = "XboatCursor"; cursorGui.ResetOnSpawn = false; cursorGui.DisplayOrder = 1000; cursorGui.IgnoreGuiInset = true; cursorGui.Enabled = false; cursorGui.Parent = CoreGui
cursorFrame = Instance.new("Frame"); cursorFrame.Size = UDim2.new(0,18,0,18); cursorFrame.BackgroundTransparency = 1; cursorFrame.BorderSizePixel = 0; cursorFrame.ZIndex = 100; cursorFrame.Parent = cursorGui
cursorH = Instance.new("Frame"); cursorH.Size = UDim2.new(1,0,0,2); cursorH.Position = UDim2.new(0,0,0.5,-1); cursorH.BackgroundColor3 = Color3.new(1,1,1); cursorH.BorderSizePixel = 0; cursorH.ZIndex = 101; cursorH.Parent = cursorFrame
cursorHs = Instance.new("UIStroke", cursorH); cursorHs.Color = Color3.new(0,0,0); cursorHs.Thickness = 1; cursorHs.Transparency = 0.3
cursorV = Instance.new("Frame"); cursorV.Size = UDim2.new(0,2,1,0); cursorV.Position = UDim2.new(0.5,-1,0,0); cursorV.BackgroundColor3 = Color3.new(1,1,1); cursorV.BorderSizePixel = 0; cursorV.ZIndex = 101; cursorV.Parent = cursorFrame
cursorVs = Instance.new("UIStroke", cursorV); cursorVs.Color = Color3.new(0,0,0); cursorVs.Thickness = 1; cursorVs.Transparency = 0.3

-- loading
lGui = Instance.new("ScreenGui"); lGui.Name = "XboatLoading"; lGui.ResetOnSpawn = false; lGui.DisplayOrder = 999; lGui.IgnoreGuiInset = true; lGui.Parent = CoreGui
lOverlay = Instance.new("Frame")
lOverlay.Size = UDim2.new(1,0,1,0)
lOverlay.BackgroundColor3 = Color3.new(0,0,0)
lOverlay.BackgroundTransparency = 1
lOverlay.BorderSizePixel = 0
lOverlay.ZIndex = 0
lOverlay.Parent = lGui
TweenService:Create(lOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()

lBg = Instance.new("Frame")
lBg.AnchorPoint = Vector2.new(0.5, 0.5)
lBg.Position = UDim2.new(0.5, 0, 0.5, 0)
lBg.Size = UDim2.new(0, 320, 0, 130)
lBg.BackgroundColor3 = accB
lBg.BorderSizePixel = 0
lBg.ZIndex = 1
lBg.Parent = lGui
lBgScale = Instance.new("UIScale")
lBgScale.Scale = 0.3
lBgScale.Parent = lBg
TweenService:Create(lBgScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

Instance.new("UICorner",lBg).CornerRadius = UDim.new(0,10)
lStr = Instance.new("UIStroke",lBg); lStr.Color = accO; lStr.Thickness = 2
grad(lBg, br(accB,0.04), dr(accB,0.04), 135)

task.spawn(function()
    task.wait(0.4)
    while lGui and lGui.Parent and lStr and lStr.Parent do
        pcall(function() TweenService:Create(lStr, TweenInfo.new(0.4), {Thickness = 4}):Play() end)
        task.wait(0.4)
        if not (lGui and lGui.Parent) then break end
        pcall(function() TweenService:Create(lStr, TweenInfo.new(0.4), {Thickness = 2}):Play() end)
        task.wait(0.4)
    end
end)

lT = Instance.new("TextLabel"); lT.Size = UDim2.new(1,0,0,36); lT.Position = UDim2.new(0,0,0,10); lT.BackgroundTransparency = 1; lT.Text = "XBOAT"; lT.TextColor3 = accF; lT.Font = FH; lT.TextSize = 32; lT.Parent = lBg
grad(lT, accF, accO, 90)
lS = Instance.new("TextLabel"); lS.Size = UDim2.new(1,0,0,18); lS.Position = UDim2.new(0,0,0,44); lS.BackgroundTransparency = 1; lS.Text = "Loading | by:dimoonsh | v 2.5.7"; lS.TextColor3 = accO; lS.Font = FB; lS.TextSize = 13; lS.Parent = lBg
lBBg = Instance.new("Frame"); lBBg.Size = UDim2.new(1,-40,0,9); lBBg.Position = UDim2.new(0,20,0,72); lBBg.BackgroundColor3 = br(accB,0.12); lBBg.BorderSizePixel = 0; lBBg.Parent = lBg
Instance.new("UICorner",lBBg).CornerRadius = UDim.new(1,0)
lBF = Instance.new("Frame"); lBF.Size = UDim2.new(0,0,1,0); lBF.BackgroundColor3 = accF; lBF.BorderSizePixel = 0; lBF.Parent = lBBg
Instance.new("UICorner",lBF).CornerRadius = UDim.new(1,0)
grad(lBF, br(accF,0.2), accF, 0)
lP = Instance.new("TextLabel"); lP.Size = UDim2.new(1,0,0,18); lP.Position = UDim2.new(0,0,0,94); lP.BackgroundTransparency = 1; lP.Text = "0%"; lP.TextColor3 = accO; lP.Font = FB; lP.TextSize = 14; lP.Parent = lBg
TweenService:Create(lBF, TweenInfo.new(LD, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=UDim2.new(1,0,1,0)}):Play()
task.spawn(function()
    local st = tick()
    while tick()-st < LD do lP.Text = math.min(100, math.floor(((tick()-st)/LD)*100)).."%"; task.wait(0.05) end
    lP.Text = "100%"
end)

-- gui
Gui = Instance.new("ScreenGui"); Gui.Name = "XboatGui"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = true; Gui.DisplayOrder = 100; Gui.Enabled = false; Gui.Parent = CoreGui
MF = Instance.new("Frame"); MF.Size = UDim2.new(0,580,0,580); MF.Position = UDim2.new(0,20,0,40); MF.BackgroundColor3 = accB; MF.BorderSizePixel = 0; MF.Active = true; MF.Visible = false; MF.ClipsDescendants = true; MF.Parent = Gui
grad(MF, br(accB,0.03), dr(accB,0.04), 135)
Instance.new("UICorner",MF).CornerRadius = UDim.new(0,6)
mStr = Instance.new("UIStroke",MF); mStr.Color = accO; mStr.Thickness = 1
ttl = Instance.new("TextLabel"); ttl.Size = UDim2.new(1,0,0,36); ttl.BackgroundTransparency = 1; ttl.Text = "  XBOAT"; ttl.TextColor3 = accO; ttl.Font = FH; ttl.TextSize = 20; ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = MF
grad(ttl, accO, dr(accO,0.15), 90)
hBtn = Instance.new("TextButton"); hBtn.Size = UDim2.new(0,28,0,28); hBtn.Position = UDim2.new(1,-32,0,4); hBtn.BackgroundColor3 = dr(accB,0.06); hBtn.Text = "-"; hBtn.TextColor3 = accO; hBtn.Font = FH; hBtn.TextSize = 16; hBtn.BorderSizePixel = 0; hBtn.AutoButtonColor = false; hBtn.ZIndex = 5; hBtn.Parent = MF
Instance.new("UICorner",hBtn).CornerRadius = UDim.new(0,4)
sBar = Instance.new("Frame"); sBar.Size = UDim2.new(1,-8,0,26); sBar.Position = UDim2.new(0,4,0,38); sBar.BackgroundColor3 = dr(accB,0.06); sBar.BorderSizePixel = 0; sBar.Parent = MF
Instance.new("UICorner",sBar).CornerRadius = UDim.new(0,4)
searchBox = Instance.new("TextBox"); searchBox.Size = UDim2.new(1,-8,1,0); searchBox.Position = UDim2.new(0,4,0,0); searchBox.BackgroundTransparency = 1; searchBox.PlaceholderText = T("search"); searchBox.Text = ""; searchBox.TextColor3 = txtBg(); searchBox.PlaceholderColor3 = Color3.fromRGB(120,120,120); searchBox.Font = FB; searchBox.TextSize = 13; searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false; searchBox.Parent = sBar
sBarF = Instance.new("Frame"); sBarF.Size = UDim2.new(0,128,0,540); sBarF.Position = UDim2.new(0,0,0,38); sBarF.BackgroundTransparency = 1; sBarF.Parent = MF

tKeys = {"main","player","visuals","build","babft","binds","settings"}
tEmoji = {}
tBtns, tFrames = {}, {}
curTab = "main"

for i, k in ipairs(tKeys) do
    local isLocked = (k == "build")
    
    local b = Instance.new("TextButton"); b.Size = UDim2.new(1,-8,0,40); b.Position = UDim2.new(0,4,0,4+(i-1)*46); b.BackgroundTransparency = 1; b.Text = ""; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.Parent = sBarF
    
    local bg = Instance.new("Frame"); bg.Name = "BG"; bg.Size = UDim2.new(1,0,1,0); bg.BorderSizePixel = 0; bg.ZIndex = 1; bg.Parent = b
    
    if isLocked then
        bg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    else
        bg.BackgroundColor3 = tabOffC()
        grad(bg, br(tabOffC(),0.03), tabOffC(), 90)
    end
    Instance.new("UICorner",bg).CornerRadius = UDim.new(0,4)
    
    local icon = Instance.new("TextLabel"); icon.Name = "ICON"; icon.Size = UDim2.new(0,20,0,20); icon.Position = UDim2.new(0,6,0.5,-10); icon.BackgroundTransparency = 1; icon.Text = tEmoji[k] or "•"; icon.Font = FH; icon.TextSize = 16; icon.ZIndex = 2; icon.Parent = b
    
    local l = Instance.new("TextLabel"); l.Name = "LBL"; l.Size = UDim2.new(1,-30,1,0); l.Position = UDim2.new(0,30,0,0); l.BackgroundTransparency = 1; l.Text = T(k); l.Font = FH; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 2; l.Parent = b
    
    if isLocked then
        icon.TextColor3 = Color3.fromRGB(100, 100, 110)
        l.TextColor3 = Color3.fromRGB(100, 100, 110)
    else
        icon.TextColor3 = Color3.new(1,1,1)
        l.TextColor3 = txtBg()
        b.MouseEnter:Connect(function() if curTab ~= k then TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=br(tabOffC(),0.06)}):Play() end end)
        b.MouseLeave:Connect(function() if curTab ~= k then TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=tabOffC()}):Play() end end)
    end
    
    lE.tabs[k] = l
    tBtns[k] = b
end

cArea = Instance.new("Frame"); cArea.Size = UDim2.new(1,-138,0,500); cArea.Position = UDim2.new(0,133,0,70); cArea.BackgroundTransparency = 1; cArea.ClipsDescendants = true; cArea.Parent = MF
for _, k in ipairs(tKeys) do
    local f = Instance.new("ScrollingFrame")
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.CanvasSize = UDim2.new(0,0,0,(k=="settings" and 450 or (k=="binds" and 550 or (k=="babft" and 480 or 400))))
    f.ScrollBarThickness = 4
    f.ScrollBarImageColor3 = accF
    f.ScrollBarImageTransparency = 0.3
    f.ScrollingDirection = Enum.ScrollingDirection.Y
    f.ElasticBehavior = Enum.ElasticBehavior.Never
    f.Visible = (k=="main")
    f.ClipsDescendants = true
    f.Parent = cArea
    tFrames[k] = f
end

-- colorpicker
colorGui = Instance.new("ScreenGui")
colorGui.Name = "XboatColorPicker"
colorGui.ResetOnSpawn = false
colorGui.DisplayOrder = 150
colorGui.Parent = CoreGui

colorWin = Instance.new("Frame")
colorWin.Size = UDim2.new(0, 260, 0, 320)
colorWin.Position = UDim2.new(0.5, -130, 0.5, -160)
colorWin.BackgroundColor3 = accB
colorWin.BorderSizePixel = 0
colorWin.Active = true
colorWin.Visible = false
colorWin.Parent = colorGui
Instance.new("UICorner", colorWin).CornerRadius = UDim.new(0, 6)
cPickStroke = Instance.new("UIStroke", colorWin)
cPickStroke.Color = accO
cPickStroke.Thickness = 2

cHeader = Instance.new("TextButton")
cHeader.Size = UDim2.new(1, 0, 0, 30)
cHeader.BackgroundColor3 = dr(accB, 0.05)
cHeader.Text = "  Color Picker"
cHeader.TextColor3 = accF
cHeader.Font = FH
cHeader.TextSize = 14
cHeader.TextXAlignment = Enum.TextXAlignment.Left
cHeader.BorderSizePixel = 0
cHeader.Parent = colorWin
Instance.new("UICorner", cHeader).CornerRadius = UDim.new(0, 6)

cCloseBtn = Instance.new("TextButton")
cCloseBtn.Size = UDim2.new(0, 22, 0, 22)
cCloseBtn.Position = UDim2.new(1, -26, 0, 4)
cCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
cCloseBtn.Text = "X"
cCloseBtn.TextColor3 = Color3.new(1,1,1)
cCloseBtn.Font = FH
cCloseBtn.TextSize = 12
cCloseBtn.BorderSizePixel = 0
cCloseBtn.Parent = colorWin
Instance.new("UICorner", cCloseBtn).CornerRadius = UDim.new(0, 4)

cPreview = Instance.new("Frame")
cPreview.Size = UDim2.new(1, -20, 0, 30)
cPreview.Position = UDim2.new(0, 10, 0, 38)
cPreview.BackgroundColor3 = Color3.new(1,1,1)
cPreview.BorderSizePixel = 0
cPreview.Parent = colorWin
Instance.new("UICorner", cPreview).CornerRadius = UDim.new(0, 4)
cPrevStroke = Instance.new("UIStroke", cPreview)
cPrevStroke.Color = Color3.new(0,0,0)
cPrevStroke.Thickness = 1

cModeBtn = Instance.new("TextButton")
cModeBtn.Size = UDim2.new(1, -20, 0, 24)
cModeBtn.Position = UDim2.new(0, 10, 0, 76)
cModeBtn.BackgroundColor3 = dr(accB, 0.1)
cModeBtn.Text = "Mode: RGB"
cModeBtn.TextColor3 = txtBg()
cModeBtn.Font = FH
cModeBtn.TextSize = 13
cModeBtn.BorderSizePixel = 0
cModeBtn.Parent = colorWin
Instance.new("UICorner", cModeBtn).CornerRadius = UDim.new(0, 4)

cSliderFrame = Instance.new("Frame")
cSliderFrame.Size = UDim2.new(1, 0, 0, 160)
cSliderFrame.Position = UDim2.new(0, 0, 0, 110)
cSliderFrame.BackgroundTransparency = 1
cSliderFrame.Parent = colorWin

local function createColorSlider(parent, yPos, name)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -20, 0, 25)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0, 15, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = txtBg()
    lbl.Font = FH
    lbl.TextSize = 12
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, -50, 0, 8)
    track.Position = UDim2.new(0, 20, 0.5, -4)
    track.BackgroundColor3 = Color3.new(1,1,1)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local grad = Instance.new("UIGradient", track)
    grad.Rotation = 0
    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0, 12, 0, 12)
    thumb.Position = UDim2.new(0, 0, 0.5, -6)
    thumb.BackgroundColor3 = Color3.new(1,1,1)
    thumb.BorderSizePixel = 0
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", thumb).Color = Color3.new(0,0,0)
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0, 25, 1, 0)
    valLbl.Position = UDim2.new(1, -25, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = "0"
    valLbl.TextColor3 = txtBg()
    valLbl.Font = FH
    valLbl.TextSize = 12
    return {row=row, track=track, thumb=thumb, grad=grad, valLbl=valLbl, lbl=lbl}
end

rSlider = createColorSlider(cSliderFrame, 5, "R")
gSlider = createColorSlider(cSliderFrame, 35, "G")
bSlider = createColorSlider(cSliderFrame, 65, "B")
hSlider = createColorSlider(cSliderFrame, 5, "H")
sSlider = createColorSlider(cSliderFrame, 35, "S")
vSlider = createColorSlider(cSliderFrame, 65, "V")

local isRGB = true
local currentColor = Color3.new(1,1,1)
local activeSwatch, activeSwatchStroke, activeSetC, activeOnChanged

local function updateSliderUI()
    local h, s, v = Color3.toHSV(currentColor)
    local r, g, b = currentColor.R * 255, currentColor.G * 255, currentColor.B * 255
    if isRGB then
        rSlider.row.Visible = true; gSlider.row.Visible = true; bSlider.row.Visible = true
        hSlider.row.Visible = false; sSlider.row.Visible = false; vSlider.row.Visible = false
        rSlider.thumb.Position = UDim2.new(r / 255, -6, 0.5, -6)
        rSlider.valLbl.Text = tostring(math.floor(r))
        rSlider.grad.Color = ColorSequence.new(Color3.fromRGB(0, g, b), Color3.fromRGB(255, g, b))
        gSlider.thumb.Position = UDim2.new(g / 255, -6, 0.5, -6)
        gSlider.valLbl.Text = tostring(math.floor(g))
        gSlider.grad.Color = ColorSequence.new(Color3.fromRGB(r, 0, b), Color3.fromRGB(r, 255, b))
        bSlider.thumb.Position = UDim2.new(b / 255, -6, 0.5, -6)
        bSlider.valLbl.Text = tostring(math.floor(b))
        bSlider.grad.Color = ColorSequence.new(Color3.fromRGB(r, g, 0), Color3.fromRGB(r, g, 255))
    else
        rSlider.row.Visible = false; gSlider.row.Visible = false; bSlider.row.Visible = false
        hSlider.row.Visible = true; sSlider.row.Visible = true; vSlider.row.Visible = true
        hSlider.thumb.Position = UDim2.new(h, -6, 0.5, -6)
        hSlider.valLbl.Text = tostring(math.floor(h * 360))
        hSlider.grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
        })
        sSlider.thumb.Position = UDim2.new(s, -6, 0.5, -6)
        sSlider.valLbl.Text = tostring(math.floor(s * 100))
        sSlider.grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
        vSlider.thumb.Position = UDim2.new(v, -6, 0.5, -6)
        vSlider.valLbl.Text = tostring(math.floor(v * 100))
        vSlider.grad.Color = ColorSequence.new(Color3.fromHSV(h, s, 0), Color3.fromHSV(h, s, 1))
    end
end

local function setColorFromUI()
    if isRGB then
        local r = rSlider.thumb.Position.X.Scale
        local g = gSlider.thumb.Position.X.Scale
        local b = bSlider.thumb.Position.X.Scale
        currentColor = Color3.new(r, g, b)
    else
        local h = hSlider.thumb.Position.X.Scale
        local s = sSlider.thumb.Position.X.Scale
        local v = vSlider.thumb.Position.X.Scale
        currentColor = Color3.fromHSV(h, s, v)
    end
    cPreview.BackgroundColor3 = currentColor
    cPrevStroke.Color = cStroke(currentColor)
    if activeSwatch then
        activeSwatch.BackgroundColor3 = currentColor
        if activeSwatchStroke then activeSwatchStroke.Color = cStroke(currentColor) end
    end
    if activeSetC then activeSetC(currentColor) end
    if activeOnChanged then activeOnChanged(currentColor) end
end

local function setupSliderInput(slider)
    local dragging = false
    local function update(mouseX)
        local absPos = slider.track.AbsolutePosition
        local absSize = slider.track.AbsoluteSize
        local rel = math.clamp((mouseX - absPos.X) / absSize.X, 0, 1)
        slider.thumb.Position = UDim2.new(rel, -6, 0.5, -6)
        setColorFromUI()
        updateSliderUI()
    end
    slider.track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

for _, s in ipairs({rSlider, gSlider, bSlider, hSlider, sSlider, vSlider}) do
    setupSliderInput(s)
end

local function openColorPicker(initialColor, swatch, swatchStroke, setC, onChanged)
    currentColor = initialColor
    activeSwatch = swatch
    activeSwatchStroke = swatchStroke
    activeSetC = setC
    activeOnChanged = onChanged
    colorWin.Visible = true
    updateSliderUI()
    local mouse = UIS:GetMouseLocation()
    local posX = math.clamp(mouse.X - 130, 0, workspace.CurrentCamera.ViewportSize.X - 260)
    local posY = math.clamp(mouse.Y - 160, 0, workspace.CurrentCamera.ViewportSize.Y - 320)
    colorWin.Position = UDim2.new(0, posX, 0, posY)
end

cCloseBtn.MouseButton1Click:Connect(function() colorWin.Visible = false end)
cModeBtn.MouseButton1Click:Connect(function()
    isRGB = not isRGB
    cModeBtn.Text = "Mode: " .. (isRGB and "RGB" or "HSV")
    updateSliderUI()
end)

local draggingWindow = false
local dragStart, startPos
cHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true
        dragStart = input.Position
        startPos = colorWin.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        colorWin.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = false
    end
end)

function makeColorBtn(parent, y, labelKey, getC, setC, onChanged)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(0, 430, 0, 32)
    cont.Position = UDim2.new(0, 4, 0, y)
    cont.BackgroundTransparency = 1
    cont.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = T(labelKey)
    lbl.TextColor3 = txtBg()
    lbl.Font = FH
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 34, 0, 18)
    swatch.Position = UDim2.new(1, -38, 0.5, -9)
    swatch.BackgroundColor3 = getC()
    swatch.BorderSizePixel = 0
    swatch.Parent = cont
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)
    local swStroke = Instance.new("UIStroke", swatch)
    swStroke.Color = cStroke(getC())
    swStroke.Thickness = 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = cont
    btn.MouseButton1Click:Connect(function()
        snd("click")
        openColorPicker(getC(), swatch, swStroke, setC, onChanged)
    end)
    return {container = cont, refresh = function()
        swatch.BackgroundColor3 = getC()
        swStroke.Color = cStroke(getC())
    end, label = lbl}
end

pickerRefresh.accent = function() if pkAcc then pkAcc.refresh() end end
pickerRefresh.outline = function() if pkOut then pkOut.refresh() end end
pickerRefresh.background = function() if pkBg then pkBg.refresh() end end
pickerRefresh.wall = function() if pkWall then pkWall.refresh() end end

-- helpers
function mkBtn(p, t, y, w, k)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0,w or 430,0,38); b.Position = UDim2.new(0,4,0,y); b.BackgroundTransparency = 1; b.Text = ""; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.Parent = p
    local bg = Instance.new("Frame"); bg.Name = "BG"; bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = offC(); bg.BorderSizePixel = 0; bg.ZIndex = 1; bg.Parent = b
    Instance.new("UICorner",bg).CornerRadius = UDim.new(0,4)
    grad(bg, br(offC(),0.03), offC(), 90)
    local l = Instance.new("TextLabel"); l.Name = "LBL"; l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1; l.Text = t; l.TextColor3 = txtBg(); l.Font = FH; l.TextSize = 16; l.ZIndex = 2; l.Parent = b
    if k then lE.btns[b] = {key=k, isOn=false} end
    b.MouseEnter:Connect(function() if b:GetAttribute("IsOn") ~= true then TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=br(offC(),0.06)}):Play() end end)
    b.MouseLeave:Connect(function() if b:GetAttribute("IsOn") ~= true then TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=offC()}):Play() end end)
    return b
end
function mkFlatBtn(p, t, x, y, w, h, c, k)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0,w,0,h or 34); b.Position = UDim2.new(0,x,0,y); b.BackgroundColor3 = c or dr(accB,0.1); b.Text = t; b.TextColor3 = txtC(c or accB); b.Font = FH; b.TextSize = 14; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.Parent = p
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,4)
    if k then lE.btns[b] = {key=k, isOn=false} end
    return b
end
function mkToggle(p, t, y, w, k, labelKey)
    local h = Instance.new("TextButton")
    h.Size = UDim2.new(0, w or 430, 0, 32)
    h.Position = UDim2.new(0, 4, 0, y)
    h.BackgroundTransparency = 1
    h.Text = ""
    h.AutoButtonColor = false
    h.BorderSizePixel = 0
    h.Parent = p
    local l = Instance.new("TextLabel")
    l.Name = "LBL"
    l.Size = UDim2.new(1, -50, 1, 0)
    l.Position = UDim2.new(0, 4, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = txtBg()
    l.Font = FH
    l.TextSize = 15
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = h
    local track = Instance.new("Frame")
    track.Name = "TRACK"
    track.Size = UDim2.new(0, 34, 0, 18)
    track.Position = UDim2.new(1, -38, 0.5, -9)
    track.BackgroundColor3 = offC()
    track.BorderSizePixel = 0
    track.Parent = h
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    grad(track, br(offC(), 0.03), offC(), 90)
    local knob = Instance.new("Frame")
    knob.Name = "KNOB"
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    if k then lE.btns[h] = {key=k, isOn=false, isToggle=true, track=track, knob=knob, labelKey=labelKey or k} end
    return h
end
function refTog(btn, state, onK, offK)
    btn:SetAttribute("IsOn", state)
    local info = lE.btns[btn]
    if info then info.isOn = state; info.onKey = onK; info.offKey = offK end
    if info and info.isToggle then
        if info.track then
            if state then
                TweenService:Create(info.track, TweenInfo.new(0.15), {BackgroundColor3=accF}):Play()
                grad(info.track, br(accF,0.15), accF, 90)
            else
                TweenService:Create(info.track, TweenInfo.new(0.15), {BackgroundColor3=offC()}):Play()
                grad(info.track, br(offC(),0.03), offC(), 90)
            end
        end
        if info.knob then
            if state then
                TweenService:Create(info.knob, TweenInfo.new(0.15), {Position=UDim2.new(1, -16, 0.5, -7)}):Play()
            else
                TweenService:Create(info.knob, TweenInfo.new(0.15), {Position=UDim2.new(0, 2, 0.5, -7)}):Play()
            end
        end
        return
    end
    local bg, l = btn:FindFirstChild("BG"), btn:FindFirstChild("LBL")
    if l then l.Text = state and T(onK) or T(offK) end
    if bg then
        if state then TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=accF}):Play(); grad(bg, br(accF,0.15), accF, 90); if l then l.TextColor3 = txtC(accF) end
        else local o = offC(); TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=o}):Play(); grad(bg, br(o,0.03), o, 90); if l then l.TextColor3 = txtBg() end end
    end
end

-- notify
NotifyGui = Instance.new("ScreenGui"); NotifyGui.Name = "XboatNotify"; NotifyGui.ResetOnSpawn = false; NotifyGui.DisplayOrder = 200; NotifyGui.IgnoreGuiInset = true; NotifyGui.Parent = CoreGui
NotifyHolder = Instance.new("Frame"); NotifyHolder.Name = "Holder"; NotifyHolder.Size = UDim2.new(0,280,1,-20); NotifyHolder.Position = UDim2.new(1,-290,0,10); NotifyHolder.BackgroundTransparency = 1; NotifyHolder.Parent = NotifyGui

function notify(title, text, dur, isOn)
    dur = dur or 3
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,52); f.BackgroundColor3 = accB; f.BackgroundTransparency = 0.05; f.BorderSizePixel = 0; f.Parent = NotifyHolder
    f.Position = UDim2.new(1,300,0,0)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)
    local st = Instance.new("UIStroke", f)
    st.Color = isOn == true and Color3.fromRGB(80,220,120) or isOn == false and Color3.fromRGB(240,90,90) or accO
    st.Thickness = 2
    local ac = Instance.new("Frame", f); ac.Size = UDim2.new(0,4,1,-8); ac.Position = UDim2.new(0,4,0,4); ac.BackgroundColor3 = st.Color; ac.BorderSizePixel = 0
    Instance.new("UICorner", ac).CornerRadius = UDim.new(1,0)
    local tl = Instance.new("TextLabel", f); tl.Size = UDim2.new(1,-20,0,22); tl.Position = UDim2.new(0,14,0,4); tl.BackgroundTransparency = 1; tl.Text = title; tl.TextColor3 = accF; tl.Font = FH; tl.TextSize = 15; tl.TextXAlignment = Enum.TextXAlignment.Left
    local dl = Instance.new("TextLabel", f); dl.Size = UDim2.new(1,-20,0,18); dl.Position = UDim2.new(0,14,0,26); dl.BackgroundTransparency = 1; dl.Text = text; dl.TextColor3 = txtBg(); dl.Font = FB; dl.TextSize = 13; dl.TextXAlignment = Enum.TextXAlignment.Left
    if sVol > 0 then
        local s = Instance.new("Sound"); s.SoundId = "rbxassetid://6895079853"; s.Volume = sVol; s.PlaybackSpeed = isOn == false and 0.8 or 1.2; s.Parent = SoundService
        task.delay(2, function() if s then s:Destroy() end end)
        pcall(function() s:Play() end)
    end
    pcall(function() TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position=UDim2.new(0,0,0,0)}):Play() end)
    task.delay(dur, function()
        pcall(function()
            if f and f.Parent then
                local out = TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position=UDim2.new(1,300,0,0), BackgroundTransparency=1})
                for _, c in ipairs(f:GetDescendants()) do
                    if c:IsA("TextLabel") then TweenService:Create(c, TweenInfo.new(0.3), {TextTransparency=1}):Play()
                    elseif c:IsA("Frame") and c ~= f then TweenService:Create(c, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
                    elseif c:IsA("UIStroke") then TweenService:Create(c, TweenInfo.new(0.3), {Transparency=1}):Play() end
                end
                out:Play()
                task.wait(0.35)
                if f then f:Destroy() end
            end
        end)
    end)
end
function notifyToggle(name, state)
    local ok = state and "[+]" or "[-]"
    local st = state and (curLang == "ru" and ": Вкл" or curLang == "zh" and ": 开" or ": On") or (curLang == "ru" and ": Выкл" or curLang == "zh" and ": 关" or ": Off")
    pcall(function() notify("XBOAT", ok .. " " .. name .. st, 3, state) end)
end

function applyFont(fontEnum)
    FH = fontEnum
    FB = fontEnum
    for _, g in ipairs({Gui, NotifyGui, colorGui}) do
        if g then
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton") then
                    pcall(function() d.Font = fontEnum end)
                end
            end
        end
    end
end

function applyAccent()
    if MF then
        MF.BackgroundColor3 = accB; grad(MF, br(accB,0.03), dr(accB,0.04), 135)
        mStr.Color = accO; ttl.TextColor3 = accO; grad(ttl, accO, dr(accO,0.15), 90)
        hBtn.BackgroundColor3 = dr(accB,0.06); hBtn.TextColor3 = accO; sBar.BackgroundColor3 = dr(accB,0.06); searchBox.TextColor3 = txtBg()
    end
    if lBg then lBg.BackgroundColor3 = accB; lStr.Color = accO; lT.TextColor3 = accF; lS.TextColor3 = accO; lP.TextColor3 = accO end
    for k, b in pairs(tBtns) do
        local bg, l = b:FindFirstChild("BG"), b:FindFirstChild("LBL")
        if bg and l then
            if k == "build" then
                bg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                l.TextColor3 = Color3.fromRGB(100, 100, 110)
            else
                if curTab == k then bg.BackgroundColor3 = accF; grad(bg, br(accF,0.15), accF, 90); l.TextColor3 = txtC(accF)
                else bg.BackgroundColor3 = tabOffC(); grad(bg, br(tabOffC(),0.03), tabOffC(), 90); l.TextColor3 = txtBg() end
            end
        end
    end
    for b, d in pairs(lE.btns) do
        if d.isToggle then
            if d.track then
                if d.isOn then d.track.BackgroundColor3 = accF; grad(d.track, br(accF,0.15), accF, 90)
                else d.track.BackgroundColor3 = offC(); grad(d.track, br(offC(),0.03), offC(), 90) end
            end
            local l = b:FindFirstChild("LBL")
            if l then l.TextColor3 = txtBg() end
        else
            local bg, l = b:FindFirstChild("BG"), b:FindFirstChild("LBL")
            if bg and l then
                if d.isOn then bg.BackgroundColor3 = accF; grad(bg, br(accF,0.15), accF, 90); l.TextColor3 = txtC(accF)
                else bg.BackgroundColor3 = offC(); grad(bg, br(offC(),0.03), offC(), 90); l.TextColor3 = txtBg() end
            elseif b:IsA("TextButton") and b.BackgroundColor3 then
                b.TextColor3 = txtC(b.BackgroundColor3)
            end
        end
    end
    for _, s in ipairs(sFills) do if s then s.BackgroundColor3 = accF; grad(s, br(accF,0.15), accF, 0) end end
    for _, s in ipairs(sBgs) do if s then s.BackgroundColor3 = offC(); grad(s, br(offC(),0.03), offC(), 90) end end
    if restoreBtn then restoreBtn.BackgroundColor3 = accF; restoreBtn.TextColor3 = txtC(accF) end
    if rStroke then rStroke.Color = accO end
    if updateDurBtns then pcall(updateDurBtns) end
    if upLangBtn then pcall(upLangBtn) end
    if fontBtn then pcall(function() fontBtn.BackgroundColor3 = dr(accB,0.12); fontBtn.TextColor3 = txtBg() end) end
    if colorWin then 
        colorWin.BackgroundColor3 = accB
        cPickStroke.Color = accO
        cHeader.BackgroundColor3 = dr(accB, 0.05)
        cHeader.TextColor3 = accF
        cModeBtn.BackgroundColor3 = dr(accB, 0.1)
        cModeBtn.TextColor3 = txtBg()
        for _, s in ipairs({rSlider, gSlider, bSlider, hSlider, sSlider, vSlider}) do
            if s then
                s.lbl.TextColor3 = txtBg()
                s.valLbl.TextColor3 = txtBg()
            end
        end
    end
end

function upLang(lang)
    curLang = lang
    for k, l in pairs(lE.tabs) do 
        l.Text = T(k) 
        if k == "build" then 
            l.TextColor3 = Color3.fromRGB(100, 100, 110) 
        end 
    end
    for b, d in pairs(lE.btns) do
        local l = b:FindFirstChild("LBL")
        if d.isToggle then
            if l and d.labelKey then l.Text = T(d.labelKey) end
        else
            if l then if d.onKey and d.offKey then l.Text = d.isOn and T(d.onKey) or T(d.offKey) elseif d.key then l.Text = T(d.key) end
            elseif d.key then b.Text = T(d.key) end
        end
    end
    for o, k in pairs(lE.labels) do if o:IsA("TextLabel") and o.Parent then o.Text = T(k) end end
    for o, k in pairs(lE.sliders) do
        if k == "fly" then o.Text = T("fly_speed")..flySpeed
        elseif k == "ws" then o.Text = T("ws_speed")..wsVal..(wsOn and "" or T("ws_off"))
        elseif k == "fov" then o.Text = T("fov")..math.floor(camera.FieldOfView)
        elseif k == "sound" then o.Text = T("sound")..math.floor(sVol*100).."%" end
    end
    for o, k in pairs(lE.misc) do
        if o and o.Parent then
            if k == "halloween" then o.Text = T("only_halloween")
            elseif k == "pine_cost" then local q = tonumber(o:GetAttribute("Amt")) or 0; o.Text = (math.floor(q)*PINE_PRICE)..T("gold")
            elseif k == "binds_info" then o.Text = T("binds_info") end
        end
    end
    if searchBox then searchBox.PlaceholderText = T("search") end
    if cycleBtn then
        local cl = cycleBtn:FindFirstChild("LBL")
        if cl then cl.Text = T("cycle_preset") else cycleBtn.Text = T("cycle_preset") end
    end
    if fontBtn then fontBtn.Text = T("font_lbl") .. " " .. (fontList[fontIndex] and fontList[fontIndex].name or "Code") end
end

function setTab(k)
    if curTab == k then return end
    if k == "build" then return end
    local oF, nF = tFrames[curTab], tFrames[k]
    snd("tab")
    if oF then TweenService:Create(oF, TweenInfo.new(0.12), {BackgroundTransparency=1}):Play(); task.delay(0.12, function() oF.Visible = false end) end
    nF.Visible = true
    for _, d in ipairs(nF:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextBox") then d.TextTransparency = 1; TweenService:Create(d, TweenInfo.new(0.2), {TextTransparency=0}):Play() end end
    curTab = k
    for kk, b in pairs(tBtns) do
        local bg, l = b:FindFirstChild("BG"), b:FindFirstChild("LBL")
        if bg then
            if kk == "build" then
                bg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                if l then l.TextColor3 = Color3.fromRGB(100, 100, 110) end
            elseif kk == k then TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=accF}):Play(); grad(bg, br(accF,0.15), accF, 90); if l then l.TextColor3 = txtC(accF) end
            else local tOff = tabOffC(); TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundColor3=tOff}):Play(); grad(bg, br(tOff,0.03), tOff, 90); if l then l.TextColor3 = txtBg() end end
        end
    end
end
for k, b in pairs(tBtns) do b.MouseButton1Click:Connect(function() setTab(k) end) end
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = searchBox.Text:lower()
    for _, b in ipairs(tBtns) do local l = b:FindFirstChild("LBL"); b.Visible = (q == "") or (l and l.Text:lower():find(q) ~= nil) end
end)

-- main
mainTab = tFrames["main"]
mainTitle = Instance.new("TextLabel")
mainTitle.Size = UDim2.new(1,-8,0,40)
mainTitle.Position = UDim2.new(0,4,0,20)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "XBOAT v 2.5.7"
mainTitle.TextColor3 = accF
mainTitle.Font = FH
mainTitle.TextSize = 28
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Parent = mainTab
grad(mainTitle, accF, accO, 90)

mainBy = Instance.new("TextLabel")
mainBy.Size = UDim2.new(1,-8,0,24)
mainBy.Position = UDim2.new(0,4,0,64)
mainBy.BackgroundTransparency = 1
mainBy.Text = "By : dimoonsh"
mainBy.TextColor3 = txtBg()
mainBy.Font = FB
mainBy.TextSize = 18
mainBy.TextXAlignment = Enum.TextXAlignment.Left
mainBy.Parent = mainTab

mainFor = Instance.new("TextLabel")
mainFor.Size = UDim2.new(1,-8,0,24)
mainFor.Position = UDim2.new(0,4,0,92)
mainFor.BackgroundTransparency = 1
mainFor.Text = "For Build A Boat For Treasure"
mainFor.TextColor3 = txtBg()
mainFor.Font = FB
mainFor.TextSize = 16
mainFor.TextXAlignment = Enum.TextXAlignment.Left
mainFor.Parent = mainTab

mainHi = Instance.new("TextLabel")
mainHi.Size = UDim2.new(1,-8,0,60)
mainHi.Position = UDim2.new(0,4,0,140)
mainHi.BackgroundTransparency = 1
mainHi.Text = "Welcome to XBOAT!\nUse the tabs on the left to configure features."
mainHi.TextColor3 = txtBg()
mainHi.Font = FB
mainHi.TextSize = 14
mainHi.TextWrapped = true
mainHi.TextXAlignment = Enum.TextXAlignment.Left
mainHi.TextYAlignment = Enum.TextYAlignment.Top
mainHi.Parent = mainTab

codeLbl = Instance.new("TextLabel")
codeLbl.Size = UDim2.new(1,-8,0,20)
codeLbl.Position = UDim2.new(0,4,0,210)
codeLbl.BackgroundTransparency = 1
codeLbl.Text = "Enter Code"
codeLbl.TextColor3 = txtBg()
codeLbl.Font = FH
codeLbl.TextSize = 15
codeLbl.TextXAlignment = Enum.TextXAlignment.Left
codeLbl.Parent = mainTab

codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(1,-8,0,34)
codeBox.Position = UDim2.new(0,4,0,234)
codeBox.BackgroundColor3 = Color3.fromRGB(235,250,255)
codeBox.TextColor3 = Color3.fromRGB(20,40,80)
codeBox.PlaceholderText = "Enter code..."
codeBox.Text = ""
codeBox.TextSize = 14
codeBox.Font = FB
codeBox.ClearTextOnFocus = false
codeBox.BorderSizePixel = 0
codeBox.Parent = mainTab
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 6)

enterCodeBtn = mkBtn(mainTab, "Apply Code", 280, 430)
enterCodeBtn.MouseButton1Click:Connect(function()
    snd("click")
    local code = codeBox.Text:match("^%s*(.-)%s*$")
    if code == "" then
        notify("XBOAT", "Enter a code first", 2, false)
        return
    end
    if code == "xconsole" then
        codeBox.Text = ""
        notify("XBOAT", "Loading console...", 2, true)
        task.spawn(function()
            local ok, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/dimoonsh195/xconsole/main/console.lua"))()
            end)
            if not ok then
                notify("XBOAT", "Console error: " .. tostring(err), 4, false)
                warn("[XBOAT] Console load error: " .. tostring(err))
            else
                notify("XBOAT", "Console loaded!", 2, true)
            end
        end)
    else
        notify("XBOAT", "Invalid code: " .. code, 2, false)
    end
end)

-- player
pTab = tFrames["player"]
tFBtn = mkToggle(pTab, T("fly"), 0, 430, "fly")
sLbl = Instance.new("TextLabel"); sLbl.Size = UDim2.new(1,-8,0,20); sLbl.Position = UDim2.new(0,4,0,40); sLbl.BackgroundTransparency = 1; sLbl.TextColor3 = txtBg(); sLbl.Font = FB; sLbl.TextSize = 15; sLbl.TextXAlignment = Enum.TextXAlignment.Left; sLbl.Parent = pTab
lE.sliders[sLbl] = "fly"
fSlBg = Instance.new("Frame"); fSlBg.Size = UDim2.new(1,-16,0,10); fSlBg.Position = UDim2.new(0,4,0,64); fSlBg.BackgroundColor3 = offC(); fSlBg.BorderSizePixel = 0; fSlBg.Parent = pTab
Instance.new("UICorner",fSlBg).CornerRadius = UDim.new(1,0); grad(fSlBg, br(offC(),0.03), offC(), 90)
fSlF = Instance.new("Frame"); fSlF.Size = UDim2.new(0,0,1,0); fSlF.BackgroundColor3 = accF; fSlF.BorderSizePixel = 0; fSlF.Parent = fSlBg
Instance.new("UICorner",fSlF).CornerRadius = UDim.new(1,0); grad(fSlF, br(accF,0.15), accF, 0)
fSlK = Instance.new("Frame"); fSlK.Size = UDim2.new(0,14,0,14); fSlK.Position = UDim2.new(0,-7,0.5,-7); fSlK.BackgroundColor3 = Color3.new(1,1,1); fSlK.BorderSizePixel = 0; fSlK.ZIndex = 3; fSlK.Parent = fSlBg
Instance.new("UICorner",fSlK).CornerRadius = UDim.new(1,0)
wLbl = Instance.new("TextLabel"); wLbl.Size = UDim2.new(1,-8,0,20); wLbl.Position = UDim2.new(0,4,0,86); wLbl.BackgroundTransparency = 1; wLbl.TextColor3 = txtBg(); wLbl.Font = FB; wLbl.TextSize = 15; wLbl.TextXAlignment = Enum.TextXAlignment.Left; wLbl.Parent = pTab
lE.sliders[wLbl] = "ws"
wSlBg = Instance.new("Frame"); wSlBg.Size = UDim2.new(1,-16,0,10); wSlBg.Position = UDim2.new(0,4,0,110); wSlBg.BackgroundColor3 = offC(); wSlBg.BorderSizePixel = 0; wSlBg.Parent = pTab
Instance.new("UICorner",wSlBg).CornerRadius = UDim.new(1,0); grad(wSlBg, br(offC(),0.03), offC(), 90)
wSlF = Instance.new("Frame"); wSlF.Size = UDim2.new(0,0,1,0); wSlF.BackgroundColor3 = accF; wSlF.BorderSizePixel = 0; wSlF.Parent = wSlBg
Instance.new("UICorner",wSlF).CornerRadius = UDim.new(1,0); grad(wSlF, br(accF,0.15), accF, 0)
wSlK = Instance.new("Frame"); wSlK.Size = UDim2.new(0,14,0,14); wSlK.Position = UDim2.new(0,-7,0.5,-7); wSlK.BackgroundColor3 = Color3.new(1,1,1); wSlK.BorderSizePixel = 0; wSlK.ZIndex = 3; wSlK.Parent = wSlBg
Instance.new("UICorner",wSlK).CornerRadius = UDim.new(1,0)
tWB = mkToggle(pTab, T("ws"), 132, 430, "ws")
tNB = mkToggle(pTab, T("noclip"), 170, 430, "noclip")
dFS, dWS = false, false
function upFS(f) f = math.clamp(f,0,1); flySpeed = math.floor(MIN_FS+(MAX_FS-MIN_FS)*f); fSlF.Size = UDim2.new(f,0,1,0); fSlK.Position = UDim2.new(f,-7,0.5,-7); sLbl.Text = T("fly_speed")..flySpeed end
fSlBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dFS = true; upFS((i.Position.X-fSlBg.AbsolutePosition.X)/fSlBg.AbsoluteSize.X) end end)
function upWS(f) f = math.clamp(f,0,1); wsVal = math.floor(MIN_WS+(MAX_WS-MIN_WS)*f); wSlF.Size = UDim2.new(f,0,1,0); wSlK.Position = UDim2.new(f,-7,0.5,-7); wLbl.Text = T("ws_speed")..wsVal..(wsOn and "" or T("ws_off")) end
wSlBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dWS = true; upWS((i.Position.X-wSlBg.AbsolutePosition.X)/wSlBg.AbsoluteSize.X) end end)
sFills[1] = fSlF; sFills[2] = wSlF; sBgs[1] = fSlBg; sBgs[2] = wSlBg

tEFBtn = mkBtn(pTab, "Fling!", 212, 430)
emoteIdBox = Instance.new("TextBox")
emoteIdBox.Size = UDim2.new(1,-8,0,34)
emoteIdBox.Position = UDim2.new(0,4,0,258)
emoteIdBox.BackgroundColor3 = Color3.fromRGB(235,250,255)
emoteIdBox.TextColor3 = Color3.fromRGB(20,40,80)
emoteIdBox.PlaceholderText = "Animation ID"
emoteIdBox.Text = PresetAnims[1][2]
emoteIdBox.TextSize = 14
emoteIdBox.Font = FB
emoteIdBox.ClearTextOnFocus = false
emoteIdBox.BorderSizePixel = 0
emoteIdBox.Parent = pTab
Instance.new("UICorner", emoteIdBox).CornerRadius = UDim.new(0,6)

cycleBtn = mkFlatBtn(pTab, T("cycle_preset"), 4, 300, 210, 38, dr(accB,0.12), "cycle_preset")
cycleBtn.TextColor3 = txtBg()
cycleBtn.MouseButton1Click:Connect(function()
    snd("click")
    presetIndex = presetIndex % #PresetAnims + 1
    local preset = PresetAnims[presetIndex]
    emoteIdBox.Text = preset[2]
    notify("XBOAT", preset[1] .. " -> " .. preset[2], 2)
end)

tAfBtn = mkToggle(pTab, T("antifling"), 300, 210, "antifling")
tAfBtn.Position = UDim2.new(0,220,0,300)

durLbl = Instance.new("TextLabel")
durLbl.Size = UDim2.new(0,200,0,32)
durLbl.Position = UDim2.new(0,4,0,350)
durLbl.BackgroundTransparency = 1
durLbl.TextColor3 = txtBg()
durLbl.Font = FH
durLbl.TextSize = 15
durLbl.TextXAlignment = Enum.TextXAlignment.Left
durLbl.TextYAlignment = Enum.TextYAlignment.Center
durLbl.Text = T("fling_duration")
durLbl.Parent = pTab
lE.labels[durLbl] = "fling_duration"

dur1Btn = mkFlatBtn(pTab, "1s", 210, 350, 100, 32, accB)
dur2Btn = mkFlatBtn(pTab, "2s", 320, 350, 100, 32, accB)

function updateDurBtns()
    if not (dur1Btn and dur2Btn) then return end
    if flingDuration == 1 then
        dur1Btn.BackgroundColor3 = accF; dur1Btn.TextColor3 = txtC(accF)
        dur2Btn.BackgroundColor3 = dr(accB,0.12); dur2Btn.TextColor3 = txtBg()
    else
        dur1Btn.BackgroundColor3 = dr(accB,0.12); dur1Btn.TextColor3 = txtBg()
        dur2Btn.BackgroundColor3 = accF; dur2Btn.TextColor3 = txtC(accF)
    end
end
dur1Btn.MouseButton1Click:Connect(function() flingDuration = 1; updateDurBtns(); snd("click") end)
dur2Btn.MouseButton1Click:Connect(function() flingDuration = 2; updateDurBtns(); snd("click") end)
updateDurBtns()

tIJBtn = mkToggle(pTab, T("infjump"), 392, 430, "infjump")

-- visuals
vTab = tFrames["visuals"]
tWlB = mkToggle(vTab, T("wallhack"), 0, 430, "wallhack")
tBxB = mkToggle(vTab, T("box"), 42, 138, "box"); tBxB.Position = UDim2.new(0,4,0,42)
tHlB = mkToggle(vTab, T("highlight"), 42, 138, "highlight"); tHlB.Position = UDim2.new(0,148,0,42)
tSkB = mkToggle(vTab, T("skeleton"), 42, 138, "skeleton"); tSkB.Position = UDim2.new(0,292,0,42)

function onWallColorChanged(c)
    for _, e in pairs(espObj) do
        if e.highlight and e.highlight.Parent then e.highlight.FillColor = c; e.highlight.OutlineColor = c end
        if e.box and e.box.Parent then e.box.Color3 = c end
    end
    for _, s in pairs(skelData) do for _, i in ipairs(s.lines) do if i.line then i.line.Color = c end end end
end

pkWall = makeColorBtn(vTab, 86, "wall_lbl", function() return wallColor end, function(c) wallColor = c end, onWallColorChanged)
lE.labels[pkWall.label] = "wall_lbl"

fLbl = Instance.new("TextLabel"); fLbl.Size = UDim2.new(1,-8,0,20); fLbl.Position = UDim2.new(0,4,0,124); fLbl.BackgroundTransparency = 1; fLbl.TextColor3 = txtBg(); fLbl.Font = FB; fLbl.TextSize = 15; fLbl.TextXAlignment = Enum.TextXAlignment.Left; fLbl.Parent = vTab
lE.sliders[fLbl] = "fov"
fSlBg2 = Instance.new("Frame"); fSlBg2.Size = UDim2.new(1,-16,0,10); fSlBg2.Position = UDim2.new(0,4,0,148); fSlBg2.BackgroundColor3 = offC(); fSlBg2.BorderSizePixel = 0; fSlBg2.Parent = vTab
Instance.new("UICorner",fSlBg2).CornerRadius = UDim.new(1,0); grad(fSlBg2, br(offC(),0.03), offC(), 90)
fSlF2 = Instance.new("Frame"); fSlF2.Size = UDim2.new(0,0,1,0); fSlF2.BackgroundColor3 = accF; fSlF2.BorderSizePixel = 0; fSlF2.Parent = fSlBg2
Instance.new("UICorner",fSlF2).CornerRadius = UDim.new(1,0); grad(fSlF2, br(accF,0.15), accF, 0)
fSlK2 = Instance.new("Frame"); fSlK2.Size = UDim2.new(0,14,0,14); fSlK2.Position = UDim2.new(0,-7,0.5,-7); fSlK2.BackgroundColor3 = Color3.new(1,1,1); fSlK2.BorderSizePixel = 0; fSlK2.ZIndex = 3; fSlK2.Parent = fSlBg2
Instance.new("UICorner",fSlK2).CornerRadius = UDim.new(1,0)
MIN_FOV, MAX_FOV = 70, 120
dFov = false
function upFov(f) f = math.clamp(f,0,1); local fov = math.floor(MIN_FOV+(MAX_FOV-MIN_FOV)*f); fSlF2.Size = UDim2.new(f,0,1,0); fSlK2.Position = UDim2.new(f,-7,0.5,-7); fLbl.Text = T("fov")..fov; camera.FieldOfView = fov end
fSlBg2.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dFov = true; upFov((i.Position.X-fSlBg2.AbsolutePosition.X)/fSlBg2.AbsoluteSize.X) end end)
sFills[3] = fSlF2; sBgs[3] = fSlBg2

tPres = {{n="day",t=12}, {n="sunset",t=18}, {n="night",t=0}}
for i, p in ipairs(tPres) do
    local b = mkFlatBtn(vTab, "", 4+(i-1)*146, 180, 138, 36, dr(accB,0.12), p.n)
    b.TextColor3 = txtBg()
    b.MouseButton1Click:Connect(function() Lighting.ClockTime = p.t; snd("click") end)
end
fBBtn = mkToggle(vTab, T("fullbright"), 230, 430, "fullbright")
rVBtn = mkBtn(vTab, "", 270, 430, "reset_vis")

-- build
bTab = tFrames["build"]
bTitle = Instance.new("TextLabel"); bTitle.Size = UDim2.new(1,-8,0,20); bTitle.Position = UDim2.new(0,4,0,0); bTitle.BackgroundTransparency = 1; bTitle.Text = "Auto build (Lua Asu)"; bTitle.TextColor3 = txtBg(); bTitle.Font = FH; bTitle.TextSize = 15; bTitle.TextXAlignment = Enum.TextXAlignment.Left; bTitle.Parent = bTab
buildFileBox = Instance.new("TextBox"); buildFileBox.Size = UDim2.new(1,-8,0,34); buildFileBox.Position = UDim2.new(0,4,0,24); buildFileBox.BackgroundColor3 = Color3.fromRGB(235,250,255); buildFileBox.TextColor3 = Color3.fromRGB(20,40,80); buildFileBox.PlaceholderText = "Имя файла (tank)"; buildFileBox.Text = "tank"; buildFileBox.TextSize = 15; buildFileBox.Font = FB; buildFileBox.ClearTextOnFocus = false; buildFileBox.BorderSizePixel = 0; buildFileBox.Parent = bTab
Instance.new("UICorner",buildFileBox).CornerRadius = UDim.new(0,6)
buildStatusLbl = Instance.new("TextLabel"); buildStatusLbl.Size = UDim2.new(1,-8,0,20); buildStatusLbl.Position = UDim2.new(0,4,0,62); buildStatusLbl.BackgroundTransparency = 1; buildStatusLbl.Text = "Status: Ready"; buildStatusLbl.TextColor3 = Color3.fromRGB(150,200,150); buildStatusLbl.Font = FB; buildStatusLbl.TextSize = 14; buildStatusLbl.TextXAlignment = Enum.TextXAlignment.Left; buildStatusLbl.Parent = bTab

function parseAsuLua(raw)
    if type(raw) ~= "string" then return nil, "Пустой файл" end
    local hasList = raw:find("LP_LIST") or raw:find("LP_List"); local hasBuild = raw:find("LP_BUILD") or raw:find("LP_Build")
    if not hasList and not hasBuild then return nil, "Это не файл Asu" end
    local bm = raw:match("LP_BUILD%s*(%b{})") or raw:match("LP_Build%s*(%b{})")
    if bm then
        local okB, data = pcall(function() return HttpService:JSONDecode(bm) end)
        if okB and type(data) == "table" and next(data) then
            local result, total = {}, 0
            for bn, list in pairs(data) do
                if type(list) == "table" and #list > 0 then
                    result[bn] = {}
                    for _, bi in ipairs(list) do
                        local pos = bi.Position or {0,0,0}; local rot = bi.Rotation or {0,0,0}; local size = bi.Size or {4,4,4}; local col = bi.Color or {1,1,1}
                        local cf = CFrame.new(pos[1] or 0, pos[2] or 0, pos[3] or 0) * CFrame.Angles(math.rad(rot[1] or 0), math.rad(rot[2] or 0), math.rad(rot[3] or 0))
                        table.insert(result[bn], {CFrame = table.concat({cf.X, cf.Y, cf.Z, cf:GetComponents()}, ","), Size = table.concat({size[1] or 4, size[2] or 4, size[3] or 4}, ","), Col = table.concat({col[1] or 1, col[2] or 1, col[3] or 1}, ",")})
                        total = total + 1
                    end
                end
            end
            if total > 0 then return result, "Asu Build (" .. total .. ")" end
        end
    end
    return nil, "LP_BUILD не найден"
end

buildBtn = mkBtn(bTab, "", 100, 430, "auto_build")
buildBtn:FindFirstChild("LBL").Text = T("auto_build")
buildBtn.MouseButton1Click:Connect(function()
    snd("click")
    local fname = buildFileBox.Text:match("^%s*(.-)%s*$")
    if fname == "" then buildStatusLbl.Text = "Введи имя файла!" return end
    local raw = nil
    for _, ext in ipairs({".Build",".build",".lua",".txt",""}) do
        if type(isfile) == "function" and isfile(fname..ext) then raw = readfile(fname..ext); break end
    end
    if not raw then buildStatusLbl.Text = "Файл не найден: "..fname; return end
    buildStatusLbl.Text = "Парсинг..."
    local data, info = parseAsuLua(raw)
    if not data then buildStatusLbl.Text = tostring(info); return end
    buildStatusLbl.Text = info.." - строим..."
    buildStatusLbl.TextColor3 = Color3.fromRGB(150,200,150)
    task.spawn(function()
        local ok = pasteBuild(data, function(msg) buildStatusLbl.Text = msg end)
        buildStatusLbl.Text = ok and "Готово!" or "Ошибка"
        notify("XBOAT", ok and "Build finished" or "Build failed", 3, ok)
    end)
end)

-- babft
babftTab = tFrames["babft"]
pTtl = Instance.new("TextLabel"); pTtl.Size = UDim2.new(1,-8,0,20); pTtl.Position = UDim2.new(0,4,0,0); pTtl.BackgroundTransparency = 1; pTtl.TextColor3 = txtBg(); pTtl.Font = FH; pTtl.TextSize = 15; pTtl.TextXAlignment = Enum.TextXAlignment.Left; pTtl.Parent = babftTab
lE.labels[pTtl] = "pine_shop"
pBox = Instance.new("TextBox"); pBox.Size = UDim2.new(1,-8,0,34); pBox.Position = UDim2.new(0,4,0,24); pBox.BackgroundColor3 = Color3.fromRGB(235,250,255); pBox.TextColor3 = Color3.fromRGB(20,40,80); pBox.PlaceholderText = "Amount"; pBox.Text = "1"; pBox.TextSize = 15; pBox.Font = FB; pBox.ClearTextOnFocus = false; pBox.BorderSizePixel = 0; pBox.Parent = babftTab
Instance.new("UICorner",pBox).CornerRadius = UDim.new(0,6)
pCost = Instance.new("TextLabel"); pCost.Size = UDim2.new(1,-8,0,20); pCost.Position = UDim2.new(0,4,0,62); pCost.BackgroundTransparency = 1; pCost.TextColor3 = Color3.fromRGB(255,235,90); pCost.Font = FH; pCost.TextSize = 14; pCost.TextXAlignment = Enum.TextXAlignment.Left; pCost.Parent = babftTab
lE.misc[pCost] = "pine_cost"
function upPCost() local q = tonumber(pBox.Text) or 0; pCost:SetAttribute("Amt", q); pCost.Text = (math.floor(q)*PINE_PRICE)..T("gold") end
pBox:GetPropertyChangedSignal("Text"):Connect(upPCost)
pBBtn = mkFlatBtn(babftTab, "", 4, 88, 210, 34, accF, "buy_pine")
pBBtn.TextColor3 = txtC(accF)
pBBtn.MouseButton1Click:Connect(function() snd("click"); local q = tonumber(pBox.Text); if q and q > 0 then local ev = workspace:FindFirstChild("ItemBoughtFromShop"); if ev then pcall(function() ev:InvokeServer("PineTree", math.floor(q)) end) end end end)

sFarm = false
sBtn = mkToggle(babftTab, T("sweetfarm"), 132, 430, "sweetfarm")
function toggleSweetfarm()
    snd("toggle"); sFarm = not sFarm; refTog(sBtn, sFarm, "sweetfarm_on", "sweetfarm_off"); notifyToggle("Candyfarm", sFarm)
    if sFarm then task.spawn(function()
        while sFarm do
            local hs = workspace:FindFirstChild("Houses"); local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hs and hrp then
                local doors = {}
                for _, h in ipairs(hs:GetDescendants()) do if string.find(h.Name, "TrickOrTreat") then for _, c in ipairs(h:GetDescendants()) do if string.find(c.Name:lower(), "door") then table.insert(doors, c) end end end end
                if #doors == 0 then for _, c in ipairs(hs:GetDescendants()) do if string.find(c.Name:lower(), "door") then table.insert(doors, c) end end end
                if #doors > 0 then
                    local d = doors[math.random(1, #doors)]; local dp = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart", true)
                    if dp then hrp.CFrame = CFrame.lookAt(dp.Position + dp.CFrame.LookVector*2.5, dp.Position); task.wait(2.5) end
                end
            end
            task.wait(35)
        end
    end) end
end
sBtn.MouseButton1Click:Connect(toggleSweetfarm)
bindActions["Candyfarm"] = toggleSweetfarm

_G_Farm = false
aFBtn = mkToggle(babftTab, "Autofarm (VIP recommended)", 170, 430, "autofarm")
_farmPart = nil

function toggleAutofarm()
    snd("toggle"); _G_Farm = not _G_Farm
    refTog(aFBtn, _G_Farm, "autofarm_on", "autofarm_off")
    notifyToggle("Autofarm", _G_Farm)
    if not _G_Farm then
        if _farmPart then _farmPart:Destroy(); _farmPart = nil end
        return
    end
    task.spawn(function()
        local allPoints = {
            Vector3.new(167.38, 4.45, 959.95),
            Vector3.new(-49.48, 70.15, 1799.98),
            Vector3.new(-51.60, 54.59, 2515.21),
            Vector3.new(-51.05, 42.76, 3300.45),
            Vector3.new(-51.84, 57.03, 4154.18),
            Vector3.new(-54.91, 82.28, 4948.50),
            Vector3.new(-51.33, 47.09, 5622.30),
            Vector3.new(-51.68, 10.89, 6372.07),
            Vector3.new(-47.99, 45.78, 7288.07),
            Vector3.new(-46.84, 35.22, 7987.97),
            Vector3.new(-49.87, 24.58, 8550.94),
            Vector3.new(-55.8, -359.3, 9496.0),
        }
        local points = {
            allPoints[1], allPoints[2], allPoints[3], allPoints[4], allPoints[5], allPoints[6], 
            allPoints[12],
            allPoints[7], allPoints[8], allPoints[9], allPoints[10], allPoints[11]
        }
        local LOCATION_WAIT = 2.7
        while _G_Farm do
            local char, hrp, hum
            while _G_Farm do
                char = player.Character
                hrp = char and char:FindFirstChild("HumanoidRootPart")
                hum = char and char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then break end
                task.wait(0.3)
            end
            if not _G_Farm then break end
            for i = 1, #points do
                if not _G_Farm then break end
                char = player.Character
                hrp = char and char:FindFirstChild("HumanoidRootPart")
                hum = char and char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then break end
                local pos = points[i]
                if not _farmPart or not _farmPart.Parent then
                    _farmPart = Instance.new("Part")
                    _farmPart.Name = "XBOAT_FarmPart"
                    _farmPart.Anchored = true
                    _farmPart.CanCollide = true
                    _farmPart.Size = Vector3.new(15, 2, 15)
                    _farmPart.Color = Color3.fromRGB(0, 0, 0)
                    _farmPart.Transparency = 0.5
                    _farmPart.Parent = workspace
                end
                _farmPart.Position = Vector3.new(pos.X, pos.Y - 1, pos.Z)
                local targetCF = CFrame.new(pos + Vector3.new(0, 3, 0))
                pcall(function() char:PivotTo(targetCF) end)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(LOCATION_WAIT)
            end
            if not _G_Farm then break end
            local claim = workspace:FindFirstChild("ClaimRiverResultsGold")
            if claim then pcall(function() claim:FireServer() end) end
            task.wait(6)
        end
        if _farmPart then _farmPart:Destroy(); _farmPart = nil end
    end)
end
aFBtn.MouseButton1Click:Connect(toggleAutofarm)
bindActions["Autofarm"] = toggleAutofarm

-- antiafk
aAfkBtn = mkToggle(babftTab, T("antiafk"), 208, 430, "antiafk")
function toggleAntiAfk()
    if _unloading then return end
    snd("toggle")
    antiAfkOn = not antiAfkOn
    refTog(aAfkBtn, antiAfkOn, "antiafk_on", "antiafk_off")
    notifyToggle("Anti-AFK", antiAfkOn)
    if antiAfkOn then
        if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
        task.spawn(function()
            while antiAfkOn and not _unloading do
                task.wait(ANTI_AFK_INTERVAL)
                if not antiAfkOn or _unloading then break end
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                end
            end
        end)
    end
end
aAfkBtn.MouseButton1Click:Connect(toggleAntiAfk)
bindActions["Anti-AFK"] = toggleAntiAfk

-- binds
bindsTab = tFrames["binds"]
bindList = {
    {name = "Menu"},
    {name = "Fly",           btn = tFBtn},
    {name = "Noclip",        btn = tNB},
    {name = "Emote Fling",   btn = tEFBtn},
    {name = "AntiFling",     btn = tAfBtn},
    {name = "Infinite Jump", btn = tIJBtn},
    {name = "Fullbright",    btn = fBBtn},
    {name = "Wallhack",      btn = tWlB},
    {name = "Box",           btn = tBxB},
    {name = "Highlight",     btn = tHlB},
    {name = "Skeleton",      btn = tSkB},
    {name = "Candyfarm",     btn = sBtn},
    {name = "Autofarm",      btn = aFBtn},
    {name = "Anti-AFK",      btn = aAfkBtn},
}
bindState = { assigning = nil, binds = { ["Menu"] = Enum.KeyCode.Tab } }
bindBtnRefs = {}
bindActions["Menu"] = function() if MF.Visible then hideP() else showP() end end

infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1,-8,0,20); infoLbl.Position = UDim2.new(0,4,0,0); infoLbl.BackgroundTransparency = 1
infoLbl.TextColor3 = txtBg(); infoLbl.Font = FB; infoLbl.TextSize = 12
infoLbl.TextXAlignment = Enum.TextXAlignment.Left; infoLbl.Parent = bindsTab
lE.misc[infoLbl] = "binds_info"

for i, entry in ipairs(bindList) do
    local y = 26 + (i-1)*38
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-8,0,34); row.Position = UDim2.new(0,4,0,y)
    row.BackgroundColor3 = offC(); row.BorderSizePixel = 0; row.Parent = bindsTab
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,4)
    grad(row, br(offC(),0.03), offC(), 90)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,8,0,0); lbl.BackgroundTransparency = 1
    lbl.Text = entry.name; lbl.TextColor3 = txtBg(); lbl.Font = FH; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local kb = Instance.new("TextButton")
    kb.Size = UDim2.new(0,120,0,26); kb.Position = UDim2.new(1,-128,0.5,-13)
    kb.BackgroundColor3 = accF; kb.Text = T("bind_unbound"); kb.TextColor3 = txtC(accF)
    kb.Font = FH; kb.TextSize = 12; kb.BorderSizePixel = 0; kb.Parent = row
    Instance.new("UICorner",kb).CornerRadius = UDim.new(0,4)
    bindBtnRefs[entry.name] = kb
    if bindState.binds[entry.name] then
        kb.Text = bindState.binds[entry.name].Name
        kb.BackgroundColor3 = Color3.fromRGB(80,200,120)
        kb.TextColor3 = Color3.new(1,1,1)
    end
    kb.MouseButton1Click:Connect(function()
        bindState.assigning = {name = entry.name, btnRef = kb}
        kb.Text = T("bind_press")
        kb.BackgroundColor3 = Color3.fromRGB(255,200,60)
        kb.TextColor3 = Color3.fromRGB(30,22,10)
        notify("XBOAT", T("bind_press") .. " (" .. entry.name .. ") — Esc " .. (curLang == "ru" and "отмена" or curLang == "zh" and "取消" or "cancel"), 3)
    end)
end

clearBindsBtn = mkBtn(bindsTab, "", 26 + #bindList * 38 + 6, 430, "bind_clear")
clearBindsBtn:FindFirstChild("LBL").Text = T("bind_clear")
clearBindsBtn.MouseButton1Click:Connect(function()
    snd("click")
    bindState.binds = { ["Menu"] = Enum.KeyCode.Tab }
    for name, kb in pairs(bindBtnRefs) do
        if name == "Menu" then
            kb.Text = Enum.KeyCode.Tab.Name
            kb.BackgroundColor3 = Color3.fromRGB(80,200,120)
            kb.TextColor3 = Color3.new(1,1,1)
        else
            kb.Text = T("bind_unbound")
            kb.BackgroundColor3 = accF
            kb.TextColor3 = txtC(accF)
        end
    end
    notify("XBOAT", T("bind_cleared_n"), 3)
end)

UIS.InputBegan:Connect(function(input, gp)
    if bindState.assigning then
        local name = bindState.assigning.name
        local kb = bindState.assigning.btnRef
        if input.KeyCode == Enum.KeyCode.Escape then
            if bindState.binds[name] then
                kb.Text = bindState.binds[name].Name
                kb.BackgroundColor3 = Color3.fromRGB(80,200,120)
                kb.TextColor3 = Color3.new(1,1,1)
            else
                kb.Text = T("bind_unbound")
                kb.BackgroundColor3 = accF
                kb.TextColor3 = txtC(accF)
            end
            bindState.assigning = nil
            return
        end
        for otherName, otherKey in pairs(bindState.binds) do
            if otherKey == input.KeyCode and otherName ~= name then
                bindState.binds[otherName] = nil
                local otherKb = bindBtnRefs[otherName]
                if otherKb then
                    otherKb.Text = T("bind_unbound")
                    otherKb.BackgroundColor3 = accF
                    otherKb.TextColor3 = txtC(accF)
                end
            end
        end
        bindState.binds[name] = input.KeyCode
        kb.Text = input.KeyCode.Name
        kb.BackgroundColor3 = Color3.fromRGB(80,200,120)
        kb.TextColor3 = Color3.new(1,1,1)
        bindState.assigning = nil
        notify("XBOAT", name .. " -> " .. input.KeyCode.Name, 3, true)
        return
    end
    if gp then return end
    for name, kc in pairs(bindState.binds) do
        if input.KeyCode == kc then
            if bindActions[name] then
                pcall(bindActions[name])
            else
                for _, e in ipairs(bindList) do
                    if e.name == name and e.btn then
                        pcall(function() e.btn.MouseButton1Click:Fire() end)
                        break
                    end
                end
            end
            break
        end
    end
end)

-- settings
setTabFrame = tFrames["settings"]
lLbl = Instance.new("TextLabel"); lLbl.Size = UDim2.new(0,80,0,20); lLbl.Position = UDim2.new(0,4,0,0); lLbl.BackgroundTransparency = 1; lLbl.TextColor3 = txtBg(); lLbl.Font = FH; lLbl.TextSize = 15; lLbl.TextXAlignment = Enum.TextXAlignment.Left; lLbl.Parent = setTabFrame
lE.labels[lLbl] = "language"

lEnB = mkFlatBtn(setTabFrame, "EN", 4, 22, 136, 24, accB)
lRuB = mkFlatBtn(setTabFrame, "RU", 146, 22, 136, 24, accB)
lZhB = mkFlatBtn(setTabFrame, "中文", 288, 22, 136, 24, accB)

function upLangBtn()
    local function setBtn(b, active)
        if not b then return end
        if active then b.BackgroundColor3 = accF; b.TextColor3 = txtC(accF)
        else b.BackgroundColor3 = dr(accB,0.1); b.TextColor3 = txtBg() end
    end
    setBtn(lEnB, curLang == "en")
    setBtn(lRuB, curLang == "ru")
    setBtn(lZhB, curLang == "zh")
end
lEnB.MouseButton1Click:Connect(function() upLang("en"); upLangBtn() end)
lRuB.MouseButton1Click:Connect(function() upLang("ru"); upLangBtn() end)
lZhB.MouseButton1Click:Connect(function() upLang("zh"); upLangBtn() end)
upLangBtn()

pkAcc = makeColorBtn(setTabFrame, 52, "accent_lbl", function() return accF end, function(c) accF = c end, applyAccent)
lE.labels[pkAcc.label] = "accent_lbl"
pkOut = makeColorBtn(setTabFrame, 86, "outline_lbl", function() return accO end, function(c) accO = c end, applyAccent)
lE.labels[pkOut.label] = "outline_lbl"
pkBg = makeColorBtn(setTabFrame, 120, "background_lbl", function() return accB end, function(c) accB = c end, applyAccent)
lE.labels[pkBg.label] = "background_lbl"

sVLbl = Instance.new("TextLabel"); sVLbl.Size = UDim2.new(1,-8,0,20); sVLbl.Position = UDim2.new(0,4,0,154); sVLbl.BackgroundTransparency = 1; sVLbl.TextColor3 = txtBg(); sVLbl.Font = FB; sVLbl.TextSize = 15; sVLbl.TextXAlignment = Enum.TextXAlignment.Left; sVLbl.Parent = setTabFrame
lE.sliders[sVLbl] = "sound"
sSlBg = Instance.new("Frame"); sSlBg.Size = UDim2.new(1,-16,0,10); sSlBg.Position = UDim2.new(0,4,0,178); sSlBg.BackgroundColor3 = offC(); sSlBg.BorderSizePixel = 0; sSlBg.Parent = setTabFrame
Instance.new("UICorner",sSlBg).CornerRadius = UDim.new(1,0); grad(sSlBg, br(offC(),0.03), offC(), 90)
sSlF = Instance.new("Frame"); sSlF.Size = UDim2.new(sVol,0,1,0); sSlF.BackgroundColor3 = accF; sSlF.BorderSizePixel = 0; sSlF.Parent = sSlBg
Instance.new("UICorner",sSlF).CornerRadius = UDim.new(1,0); grad(sSlF, br(accF,0.15), accF, 0)
sSlK = Instance.new("Frame"); sSlK.Size = UDim2.new(0,14,0,14); sSlK.Position = UDim2.new(sVol,-7,0.5,-7); sSlK.BackgroundColor3 = Color3.new(1,1,1); sSlK.BorderSizePixel = 0; sSlK.ZIndex = 3; sSlK.Parent = sSlBg
Instance.new("UICorner",sSlK).CornerRadius = UDim.new(1,0)
function upSVol(f) f = math.clamp(f,0,1); sVol = f; sSlF.Size = UDim2.new(f,0,1,0); sSlK.Position = UDim2.new(f,-7,0.5,-7); sVLbl.Text = T("sound")..math.floor(f*100).."%" end
sSlBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local d = true; local function u(x) upSVol((x-sSlBg.AbsolutePosition.X)/sSlBg.AbsoluteSize.X) end; u(i.Position.X); local c1 = UIS.InputChanged:Connect(function(inp) if d and inp.UserInputType == Enum.UserInputType.MouseMovement then u(inp.Position.X) end end); local c2 = UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then d = false; c1:Disconnect(); c2:Disconnect() end end) end end)
sFills[4] = sSlF; sBgs[4] = sSlBg

fontBtn = mkFlatBtn(setTabFrame, T("font_lbl") .. " " .. fontList[fontIndex].name, 4, 200, 430, 32, dr(accB,0.12), "font")
fontBtn.TextColor3 = txtBg()
fontBtn.MouseButton1Click:Connect(function()
    snd("click")
    fontIndex = fontIndex % #fontList + 1
    applyFont(fontList[fontIndex].font)
    fontBtn.Text = T("font_lbl") .. " " .. fontList[fontIndex].name
end)

for i = 1, #CFG do
    local rY = 240 + (i-1)*44
    local sB = mkFlatBtn(setTabFrame, T("save")..i, 4, rY-2, 210, 32, accF, "save")
    sB.TextColor3 = txtC(accF)
    local lB = mkFlatBtn(setTabFrame, T("load")..i, 224, rY-2, 210, 32, dr(accB,0.12), "load")
    lB.TextColor3 = txtBg()
    sB.MouseButton1Click:Connect(function()
        if saveCfg(i) then notify("XBOAT", T("save")..i.." "..T("ok"), 2, true) else notify("XBOAT", T("err"), 2, false) end
    end)
    lB.MouseButton1Click:Connect(function()
        if loadCfg(i) then
            applyAccent(); upFS((flySpeed-MIN_FS)/(MAX_FS-MIN_FS)); upWS((wsVal-MIN_WS)/(MAX_WS-MIN_WS)); upSVol(sVol); upLang(curLang); upLangBtn()
            applyLoadedConfig()
            notify("XBOAT", T("load")..i.." "..T("ok"), 2, true)
        else notify("XBOAT", T("err"), 2, false) end
    end)
end
uBtn = mkBtn(setTabFrame, "", 380, 430, "unload")

-- hide / restore
isHidden = false
restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.new(0,56,0,56); restoreBtn.Position = UDim2.new(0,-80,0,60); restoreBtn.BackgroundColor3 = accF; restoreBtn.Text = "🚩"; restoreBtn.TextColor3 = txtC(accF); restoreBtn.Font = FH; restoreBtn.TextSize = 28; restoreBtn.BorderSizePixel = 0; restoreBtn.AutoButtonColor = false; restoreBtn.Visible = false; restoreBtn.ZIndex = 50; restoreBtn.Parent = Gui
Instance.new("UICorner",restoreBtn).CornerRadius = UDim.new(0,12)
rStroke = Instance.new("UIStroke",restoreBtn); rStroke.Color = accO; rStroke.Thickness = 2

hideP = function()
    if isHidden or _unloading then return end
    isHidden = true; snd("hide")
    colorWin.Visible = false
    TweenService:Create(MF, TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0,-620,0,40)}):Play()
    task.delay(0.25, function() MF.Visible = false; MF.Position = UDim2.new(0,20,0,40); restoreBtn.Visible = true; restoreBtn.Position = UDim2.new(0,-80,0,60); TweenService:Create(restoreBtn, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,20,0,60)}):Play() end)
end
showP = function()
    if not isHidden or _unloading then return end
    isHidden = false; snd("open")
    TweenService:Create(restoreBtn, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0,-80,0,60)}):Play()
    task.delay(0.2, function() restoreBtn.Visible = false end)
    MF.Position = UDim2.new(0,-620,0,40); MF.Visible = true
    TweenService:Create(MF, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,20,0,40)}):Play()
end
hBtn.MouseButton1Click:Connect(hideP)
restoreBtn.MouseButton1Click:Connect(showP)

-- drag
dg, dS, sP = false, nil, nil
ttl.InputBegan:Connect(function(i) if _unloading then return end; if i.UserInputType == Enum.UserInputType.MouseButton1 then if i.Position.X - MF.AbsolutePosition.X > MF.AbsoluteSize.X - 50 then return end; dg, dS, sP = true, i.Position, MF.Position end end)
UIS.InputChanged:Connect(function(i)
    if _unloading then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement then
        if dg then local d = i.Position - dS; MF.Position = UDim2.new(sP.X.Scale, sP.X.Offset+d.X, sP.Y.Scale, sP.Y.Offset+d.Y) end
        if dFS then upFS((i.Position.X-fSlBg.AbsolutePosition.X)/fSlBg.AbsoluteSize.X) end
        if dWS then upWS((i.Position.X-wSlBg.AbsolutePosition.X)/wSlBg.AbsoluteSize.X) end
        if dFov then upFov((i.Position.X-fSlBg2.AbsolutePosition.X)/fSlBg2.AbsoluteSize.X) end
    end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dg, dFS, dWS, dFov = false, false, false, false end end)
upFS((flySpeed-MIN_FS)/(MAX_FS-MIN_FS)); upWS((wsVal-MIN_WS)/(MAX_WS-MIN_WS)); upFov(0); upLang(curLang); applyAccent()
tFrames["main"].Visible = true
for k, b in pairs(tBtns) do
    local bg, l = b:FindFirstChild("BG"), b:FindFirstChild("LBL")
    if bg then
        if k == "build" then
            bg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            if l then l.TextColor3 = Color3.fromRGB(100, 100, 110) end
        elseif k == "main" then bg.BackgroundColor3 = accF; grad(bg, br(accF,0.15), accF, 90); if l then l.TextColor3 = txtC(accF) end
        else bg.BackgroundColor3 = tabOffC(); grad(bg, br(tabOffC(),0.03), tabOffC(), 90); if l then l.TextColor3 = txtBg() end end
    end
end

-- cursor loop
RunService.RenderStepped:Connect(function()
    if _unloading then
        if cursorGui.Enabled then cursorGui.Enabled = false end
        if not UIS.MouseIconEnabled then UIS.MouseIconEnabled = true end
        return
    end
    local mp = UIS:GetMouseLocation()
    local insideColorWin = false
    if colorWin and colorWin.Visible then
        local cap = colorWin.AbsolutePosition
        local cas = colorWin.AbsoluteSize
        insideColorWin = mp.X >= cap.X and mp.X <= cap.X + cas.X and mp.Y >= cap.Y and mp.Y <= cap.Y + cas.Y
    end
    if not Gui or not Gui.Enabled or not MF.Visible or isHidden then
        if cursorGui.Enabled then cursorGui.Enabled = false; UIS.MouseIconEnabled = true end
        return
    end
    local ap = MF.AbsolutePosition
    local as = MF.AbsoluteSize
    local inside = mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
    if inside and not insideColorWin then
        if not cursorGui.Enabled then cursorGui.Enabled = true; UIS.MouseIconEnabled = false end
        cursorFrame.Position = UDim2.new(0, mp.X - 9, 0, mp.Y - 9)
    else
        if cursorGui.Enabled then cursorGui.Enabled = false; UIS.MouseIconEnabled = true end
    end
end)

-- features
function startFly()
    local c = player.Character; if not c then return false end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return false end
    bodyVel = Instance.new("BodyVelocity"); bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5); bodyVel.Velocity = Vector3.zero; bodyVel.Parent = h
    bodyGyr = Instance.new("BodyGyro"); bodyGyr.MaxTorque = Vector3.new(1e5,1e5,1e5); bodyGyr.P = 3000; bodyGyr.CFrame = h.CFrame; bodyGyr.Parent = h
    flying = true; return true
end
function stopFly() flying = false; if bodyVel then bodyVel:Destroy(); bodyVel = nil end; if bodyGyr then bodyGyr:Destroy(); bodyGyr = nil end end

function toggleFly()
    if _unloading then return end
    snd("toggle")
    if flying then stopFly(); refTog(tFBtn, false, "fly_on", "fly_off"); notifyToggle("Fly", false)
    elseif startFly() then refTog(tFBtn, true, "fly_on", "fly_off"); notifyToggle("Fly", true) end
end
tFBtn.MouseButton1Click:Connect(toggleFly)
bindActions["Fly"] = toggleFly

RunService.RenderStepped:Connect(function()
    if not flying or not bodyVel or not bodyGyr then return end
    local c = player.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    local cf = camera.CFrame; local d = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then d += cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d += cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d -= Vector3.yAxis end
    bodyVel.Velocity = d * flySpeed
    if d.Magnitude > 0.01 then local f = Vector3.new(d.X,0,d.Z); if f.Magnitude > 0.01 then bodyGyr.CFrame = CFrame.lookAt(h.Position, h.Position+f.Unit) end end
end)

tWB.MouseButton1Click:Connect(function()
    if _unloading then return end
    snd("toggle"); wsOn = not wsOn; notifyToggle("WalkSpeed", wsOn)
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if wsOn then refTog(tWB, true, "reset_ws", "apply_ws"); if h then h.WalkSpeed = wsVal end; wLbl.Text = T("ws_speed")..wsVal
    else refTog(tWB, false, "reset_ws", "apply_ws"); if h then h.WalkSpeed = 16 end; wLbl.Text = T("ws_speed")..wsVal..T("ws_off") end
end)
wAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if not wsOn or _unloading then return end
    wAcc += dt; if wAcc < 0.2 then return end; wAcc = 0
    local c = player.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and math.abs(h.WalkSpeed-wsVal) > 0.5 then h.WalkSpeed = wsVal end
end)

function toggleNoclip()
    if _unloading then return end
    snd("toggle"); noclipOn = not noclipOn; refTog(tNB, noclipOn, "noclip_on", "noclip_off"); notifyToggle("Noclip", noclipOn)
    if noclipOn then
        noclipConn = RunService.Stepped:Connect(function() local c = player.Character; if not c then return end; for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = player.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end
tNB.MouseButton1Click:Connect(toggleNoclip)
bindActions["Noclip"] = toggleNoclip

function toggleInfiniteJump()
    if _unloading then return end
    snd("toggle")
    infJumpOn = not infJumpOn
    refTog(tIJBtn, infJumpOn, "infjump", "infjump")
    notifyToggle("Infinite Jump", infJumpOn)
    if infJumpOn then
        if infJumpConn then infJumpConn:Disconnect() end
        infJumpConn = UIS.JumpRequest:Connect(function()
            if not infJumpOn or _unloading then return end
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end
end
tIJBtn.MouseButton1Click:Connect(toggleInfiniteJump)
bindActions["Infinite Jump"] = toggleInfiniteJump

function fireEmoteFling()
    if _unloading then return end
    if emoteFlingOn then return end
    local now = tick()
    if now - lastFlingTime < FIRE_COOLDOWN then return end
    lastFlingTime = now
    local id = emoteIdBox.Text:match("%d+")
    if not id then notify("XBOAT", "Invalid animation ID", 2, false) return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not (hrp and hum) then notify("XBOAT", "No character", 2, false) return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local ok, track = pcall(function() return hum:LoadAnimation(anim) end)
    if not ok or not track then notify("XBOAT", "Failed to load animation", 2, false) return end
    snd("toggle")
    emoteFlingOn = true
    emoteFlingTrack = track
    track.Priority = Enum.AnimationPriority.Action
    track.Looped = false
    pcall(function() track:Play() end)
    notify("XBOAT", "Fling started for " .. flingDuration .. "s", 2, true)
    local lbl = tEFBtn:FindFirstChild("LBL")
    if lbl then lbl.Text = "Flinging... " .. flingDuration .. "s" end
    tEFBtn:SetAttribute("IsOn", true)
    task.spawn(function()
        local flip = 1
        local spd = math.clamp(flySpeed or 16, 16, 100)
        local endTime = tick() + flingDuration
        while emoteFlingOn and tick() < endTime do
            RunService.Heartbeat:Wait()
            local c = player.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildWhichIsA("Humanoid")
            if not (r and h) then break end
            local dir = h.MoveDirection
            flip = flip * -1
            r.AssemblyLinearVelocity = Vector3.new(100000 * flip, 0, 100000 * flip)
            r.AssemblyAngularVelocity = Vector3.new(100000 * flip, 100000 * flip, 100000 * flip)
            RunService.RenderStepped:Wait()
            if not emoteFlingOn or tick() >= endTime then break end
            if dir.Magnitude > 0 then
                r.AssemblyLinearVelocity = Vector3.new(dir.X * spd, -2, dir.Z * spd)
                r.Velocity = Vector3.new(dir.X * spd, -2, dir.Z * spd)
            else
                r.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
                r.Velocity = Vector3.new(0, -2, 0)
            end
            r.AssemblyAngularVelocity = Vector3.zero
            r.RotVelocity = Vector3.zero
        end
        emoteFlingOn = false
        if emoteFlingTrack then pcall(function() emoteFlingTrack:Stop() end) end
        emoteFlingTrack = nil
        if lbl then lbl.Text = "Fling!" end
        tEFBtn:SetAttribute("IsOn", false)
        notify("XBOAT", "Fling finished", 2, false)
    end)
end
tEFBtn.MouseButton1Click:Connect(fireEmoteFling)
bindActions["Emote Fling"] = fireEmoteFling

function toggleAntiFling()
    if _unloading then return end
    snd("toggle")
    antiFlingOn = not antiFlingOn
    refTog(tAfBtn, antiFlingOn, "antifling_on", "antifling_off")
    notifyToggle("AntiFling", antiFlingOn)
    if antiFlingOn then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            lastSafeCF = char.HumanoidRootPart.CFrame
        end
        if antiFlingConn then antiFlingConn:Disconnect() end
        antiFlingConn = RunService.Stepped:Connect(function(_, dt)
            if not antiFlingOn then return end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then
                local velocity = hrp.AssemblyLinearVelocity
                local rotVelocity = hrp.AssemblyAngularVelocity
                local mag = velocity.Magnitude
                local rotMag = rotVelocity.Magnitude
                if not lastSafeCF then lastSafeCF = hrp.CFrame end
                local isControlledMotion = rotMag < 60
                local currentState = humanoid:GetState()
                local isFalling = velocity.Y < -50 and (currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.FallingDown)
                local maxLinear = emoteFlingOn and 250 or 150
                local maxVerticalUp = 250
                local maxVerticalDown = -350
                if isControlledMotion then
                    maxLinear = 1000
                    maxVerticalUp = 800
                    if isFalling then maxVerticalDown = -5000 else maxVerticalDown = -800 end
                end
                local isFlinged = rotMag > 120 or velocity.Y > maxVerticalUp or velocity.Y < maxVerticalDown or mag > maxLinear
                if isFlinged then
                    isRecovering = true
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if lastSafeCF then hrp.CFrame = lastSafeCF end
                    if currentState == Enum.HumanoidStateType.Physics or currentState == Enum.HumanoidStateType.Ragdoll or currentState == Enum.HumanoidStateType.FallingDown then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        humanoid.PlatformStand = false
                        humanoid.Sit = false
                    end
                else
                    local distance = (hrp.Position - lastSafeCF.Position).Magnitude
                    if distance > 50 and mag < 100 and not isRecovering then
                        lastSafeCF = hrp.CFrame
                    end
                    if isControlledMotion and mag < 900 then
                        lastSafeCF = hrp.CFrame
                        isRecovering = false
                    end
                end
            end
        end)
    else
        if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
        lastSafeCF = nil
        isRecovering = false
    end
end
tAfBtn.MouseButton1Click:Connect(toggleAntiFling)
bindActions["AntiFling"] = toggleAntiFling

-- esp
DrawingAvailable = (type(Drawing) == "table" and type(Drawing.new) == "function")
r15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
r6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
function clrESP(p)
    local d = espObj[p]
    if d then if d.highlight and d.highlight.Parent then d.highlight:Destroy() end; if d.box and d.box.Parent then d.box:Destroy() end; espObj[p] = nil end
    local s = skelData[p]
    if s then for _, i in ipairs(s.lines) do pcall(function() i.line:Remove() end); pcall(function() i.line:Destroy() end) end; skelData[p] = nil end
end
function clrAllESP() for p in pairs(espObj) do clrESP(p) end; for p in pairs(skelData) do clrESP(p) end end
function appESP(p)
    if p == player then return end
    local c = p.Character; if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
    if espH then
        if not espObj[p] then espObj[p] = {} end
        if not espObj[p].highlight or not espObj[p].highlight.Parent then
            local hl = Instance.new("Highlight"); hl.Name = "XBOAT_HL"; hl.Adornee = c; hl.FillColor = wallColor; hl.FillTransparency = 0.5; hl.OutlineColor = wallColor; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = c; espObj[p].highlight = hl
        else espObj[p].highlight.FillColor = wallColor; espObj[p].highlight.OutlineColor = wallColor end
    end
    if espB then
        if not espObj[p] then espObj[p] = {} end
        if not espObj[p].box or not espObj[p].box.Parent then
            local b = Instance.new("BoxHandleAdornment"); b.Name = "XBOAT_BOX"; b.Adornee = h; b.Size = Vector3.new(2,3,1); b.Color3 = wallColor; b.AlwaysOnTop = true; b.Transparency = 0.3; b.ZIndex = 5; b.Parent = h; espObj[p].box = b
        else espObj[p].box.Color3 = wallColor end
    end
    if espS and DrawingAvailable then
        if skelData[p] then clrESP(p) end
        local bn = c:FindFirstChild("UpperTorso") and r15 or r6; local ls = {}
        for _, b in ipairs(bn) do local ln = Drawing.new("Line"); ln.Visible = false; ln.Color = wallColor; ln.Thickness = 1.5; ln.Transparency = 1; table.insert(ls, {line=ln, partA=b[1], partB=b[2]}) end
        skelData[p] = {lines=ls}
    end
end
function refESP() if not espOn then return end; for _, p in ipairs(Players:GetPlayers()) do appESP(p) end end
skelCache = setmetatable({}, {__mode="k"})
RunService.RenderStepped:Connect(function()
    if not espOn or not espS or not DrawingAvailable then return end
    for p, s in pairs(skelData) do
        local c = p.Character
        if c then
            local cc = skelCache[p]; if not cc or cc.char ~= c then cc = {char=c, parts={}}; skelCache[p] = cc end
            for _, i in ipairs(s.lines) do
                local pA = cc.parts[i.partA] or c:FindFirstChild(i.partA); cc.parts[i.partA] = pA
                local pB = cc.parts[i.partB] or c:FindFirstChild(i.partB); cc.parts[i.partB] = pB
                if pA and pB and pA.Parent and pB.Parent then
                    local sA, onA = camera:WorldToViewportPoint(pA.Position); local sB, onB = camera:WorldToViewportPoint(pB.Position)
                    if onA and onB then i.line.Visible = true; i.line.From = Vector2.new(sA.X,sA.Y); i.line.To = Vector2.new(sB.X,sB.Y); i.line.Color = wallColor
                    else i.line.Visible = false end
                else i.line.Visible = false end
            end
        else skelCache[p] = nil; for _, i in ipairs(s.lines) do i.line.Visible = false end end
    end
end)

function toggleWallhack()
    if _unloading then return end
    snd("toggle"); espOn = not espOn; refTog(tWlB, espOn, "wallhack_on", "wallhack_off")
    if espOn then refESP() else clrAllESP() end; notifyToggle("Wallhack", espOn)
end
tWlB.MouseButton1Click:Connect(toggleWallhack)
bindActions["Wallhack"] = toggleWallhack

function toggleBox()
    if _unloading then return end
    snd("toggle"); espB = not espB; refTog(tBxB, espB, "box_on", "box_off")
    if espOn then for p, d in pairs(espObj) do if d.box and d.box.Parent then d.box:Destroy() end; d.box = nil end; refESP() end
    notifyToggle("Box", espB)
end
tBxB.MouseButton1Click:Connect(toggleBox)
bindActions["Box"] = toggleBox

function toggleHighlight()
    if _unloading then return end
    snd("toggle"); espH = not espH; refTog(tHlB, espH, "hl_on", "hl_off")
    if espOn then for p, d in pairs(espObj) do if d.highlight and d.highlight.Parent then d.highlight:Destroy() end; d.highlight = nil end; refESP() end
    notifyToggle("Highlight", espH)
end
tHlB.MouseButton1Click:Connect(toggleHighlight)
bindActions["Highlight"] = toggleHighlight

function toggleSkeleton()
    if _unloading then return end
    if not DrawingAvailable then notify("XBOAT", "Drawing API unavailable", 3); return end
    snd("toggle"); espS = not espS; refTog(tSkB, espS, "skel_on", "skel_off")
    if espOn then for p in pairs(skelData) do clrESP(p) end; refESP() end
    notifyToggle("Skeleton", espS)
end
tSkB.MouseButton1Click:Connect(toggleSkeleton)
bindActions["Skeleton"] = toggleSkeleton

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() if espOn then task.wait(0.5); appESP(p) end end) end)
Players.PlayerRemoving:Connect(function(p) clrESP(p) end)

function toggleFullbright()
    if _unloading then return end
    snd("toggle"); fbOn = not fbOn; refTog(fBBtn, fbOn, "fullbright_on", "fullbright_off"); notifyToggle("Fullbright", fbOn)
    if fbOn then Lighting.Brightness = 5; Lighting.ClockTime = 12; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.Ambient = Color3.new(1,1,1); Lighting.FogEnd = 100000
    else Lighting.Brightness = origL.Brightness; Lighting.GlobalShadows = origL.GlobalShadows; Lighting.Ambient = origL.Ambient; Lighting.OutdoorAmbient = origL.OutdoorAmbient; Lighting.FogEnd = origL.FogEnd end
end
fBBtn.MouseButton1Click:Connect(toggleFullbright)
bindActions["Fullbright"] = toggleFullbright

rVBtn.MouseButton1Click:Connect(function()
    if _unloading then return end
    snd("click")
    Lighting.Ambient = origL.Ambient; Lighting.OutdoorAmbient = origL.OutdoorAmbient; Lighting.Brightness = origL.Brightness; Lighting.ClockTime = origL.ClockTime; Lighting.GlobalShadows = origL.GlobalShadows; Lighting.FogEnd = origL.FogEnd; Lighting.FogColor = origL.FogColor
    camera.FieldOfView = origFOV; fbOn = false; refTog(fBBtn, false, "fullbright_on", "fullbright_off"); upFov(0); notify("XBOAT", "Visuals reset", 2)
end)

function applyLoadedConfig()
    if _loadedFontName then
        for idx, f in ipairs(fontList) do
            if f.name == _loadedFontName then
                fontIndex = idx
                applyFont(f.font)
                break
            end
        end
        if fontBtn then fontBtn.Text = T("font_lbl") .. " " .. fontList[fontIndex].name end
    end
    if _loadedEmoteId and _loadedEmoteId ~= "" and emoteIdBox then
        emoteIdBox.Text = _loadedEmoteId
    end
    if _loadedFlingDuration then
        flingDuration = _loadedFlingDuration
        updateDurBtns()
    end
    if _loadedFov then
        local f = math.clamp((_loadedFov - MIN_FOV) / (MAX_FOV - MIN_FOV), 0, 1)
        upFov(f)
    end
    if _loadedBinds then
        for name, keyName in pairs(_loadedBinds) do
            local kc = Enum.KeyCode[keyName]
            if kc then
                bindState.binds[name] = kc
                local kb = bindBtnRefs[name]
                if kb then
                    kb.Text = keyName
                    kb.BackgroundColor3 = Color3.fromRGB(80,200,120)
                    kb.TextColor3 = Color3.new(1,1,1)
                end
            end
        end
    end
    if _loadedCfg then
        if _loadedCfg.wsOn and not wsOn then tWB.MouseButton1Click:Fire() end
        if _loadedCfg.noclipOn and not noclipOn then tNB.MouseButton1Click:Fire() end
        if _loadedCfg.antiFlingOn and not antiFlingOn then tAfBtn.MouseButton1Click:Fire() end
        if _loadedCfg.infJumpOn and not infJumpOn then tIJBtn.MouseButton1Click:Fire() end
        if _loadedCfg.espOn and not espOn then tWlB.MouseButton1Click:Fire() end
        if _loadedCfg.espB and not espB then tBxB.MouseButton1Click:Fire() end
        if _loadedCfg.espH and not espH then tHlB.MouseButton1Click:Fire() end
        if _loadedCfg.espS and not espS then tSkB.MouseButton1Click:Fire() end
        if _loadedCfg.fbOn and not fbOn then fBBtn.MouseButton1Click:Fire() end
        if _loadedCfg.sFarm and not sFarm then sBtn.MouseButton1Click:Fire() end
        if _loadedCfg.farm and not _G_Farm then aFBtn.MouseButton1Click:Fire() end
        if _loadedCfg.antiAfk and not antiAfkOn then aAfkBtn.MouseButton1Click:Fire() end
    end
end

task.defer(function()
    if _loadedFontName or _loadedCfg or _loadedBinds or _loadedEmoteId or _loadedFlingDuration or _loadedFov then
        applyLoadedConfig()
    end
end)

-- unload
uBtn.MouseButton1Click:Connect(function()
    if _unloading then return end
    _unloading = true
    snd("click")
    sFarm = false; _G_Farm = false; stopFly()
    antiAfkOn = false
    if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
    emoteFlingOn = false
    if emoteFlingTrack then pcall(function() emoteFlingTrack:Stop() end); emoteFlingTrack = nil end
    antiFlingOn = false
    if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    infJumpOn = false
    if noclipConn then noclipConn:Disconnect() end
    clrAllESP()
    camera.FieldOfView = origFOV
    Lighting.Ambient = origL.Ambient; Lighting.OutdoorAmbient = origL.OutdoorAmbient; Lighting.Brightness = origL.Brightness; Lighting.ClockTime = origL.ClockTime; Lighting.GlobalShadows = origL.GlobalShadows; Lighting.FogEnd = origL.FogEnd; Lighting.FogColor = origL.FogColor
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and wsOn then h.WalkSpeed = 16 end
    UIS.MouseIconEnabled = true
    if cursorGui then cursorGui:Destroy() end
    if colorGui then colorGui:Destroy() end
    local uOverlay = Instance.new("Frame")
    uOverlay.Size = UDim2.new(1, 0, 1, 0)
    uOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    uOverlay.BackgroundTransparency = 1
    uOverlay.BorderSizePixel = 0
    uOverlay.ZIndex = 200
    uOverlay.Parent = Gui
    for _, c in ipairs(MF:GetDescendants()) do
        if c:IsA("TextLabel") or c:IsA("TextBox") then
            pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {TextTransparency = 1}):Play() end)
        elseif c:IsA("Frame") then
            pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play() end)
        elseif c:IsA("UIStroke") then
            pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {Transparency = 1}):Play() end)
        end
    end
    if NotifyGui then
        for _, c in ipairs(NotifyGui:GetDescendants()) do
            if c:IsA("TextLabel") then
                pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {TextTransparency = 1}):Play() end)
            elseif c:IsA("Frame") then
                pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play() end)
            elseif c:IsA("UIStroke") then
                pcall(function() TweenService:Create(c, TweenInfo.new(0.25), {Transparency = 1}):Play() end)
            end
        end
    end
    task.wait(0.3)
    TweenService:Create(uOverlay, TweenInfo.new(0.35), {BackgroundTransparency = 0.4}):Play()
    local uHolder = Instance.new("Frame")
    uHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    uHolder.Size = UDim2.new(0, 400, 0, 140)
    uHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    uHolder.BackgroundTransparency = 1
    uHolder.ZIndex = 201
    uHolder.Parent = uOverlay
    local uScale = Instance.new("UIScale")
    uScale.Scale = 0.4
    uScale.Parent = uHolder
    TweenService:Create(uScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    local uTxt = Instance.new("TextLabel")
    uTxt.Size = UDim2.new(1, 0, 0, 80)
    uTxt.Position = UDim2.new(0, 0, 0, 10)
    uTxt.BackgroundTransparency = 1
    uTxt.Text = "XBOAT"
    uTxt.TextColor3 = accF
    uTxt.Font = FH
    uTxt.TextSize = 64
    uTxt.TextTransparency = 1
    uTxt.ZIndex = 202
    uTxt.Parent = uHolder
    grad(uTxt, accF, accO, 90)
    local uSub = Instance.new("TextLabel")
    uSub.Size = UDim2.new(1, 0, 0, 30)
    uSub.Position = UDim2.new(0, 0, 0, 92)
    uSub.BackgroundTransparency = 1
    uSub.Text = "Unloaded | by: dimoonsh"
    uSub.TextColor3 = accO
    uSub.Font = FB
    uSub.TextSize = 18
    uSub.TextTransparency = 1
    uSub.ZIndex = 202
    uSub.Parent = uHolder
    TweenService:Create(uTxt, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(uSub, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    snd("toggle", 0.7)
    task.wait(0.8)
    TweenService:Create(uTxt, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(uSub, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(uOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    task.wait(0.4)
    if lGui then lGui:Destroy() end
    if NotifyGui then NotifyGui:Destroy() end
    if lockGui then lockGui:Destroy() end
    Gui:Destroy()
end)

player.CharacterAdded:Connect(function(c)
    if flying then stopFly(); refTog(tFBtn, false, "fly_on", "fly_off") end
    if emoteFlingOn then
        emoteFlingOn = false
        if emoteFlingTrack then pcall(function() emoteFlingTrack:Stop() end); emoteFlingTrack = nil end
        local lbl = tEFBtn:FindFirstChild("LBL")
        if lbl then lbl.Text = "Fling!" end
        tEFBtn:SetAttribute("IsOn", false)
    end
    task.wait(0.5)
    if wsOn then
        local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = wsVal end
    end
    if espOn then refESP() end
    if antiFlingOn then
        local hrp = c:WaitForChild("HumanoidRootPart", 5)
        if hrp then lastSafeCF = hrp.CFrame end
    end
end)

-- lock
VALID_KEY = "X95125D"

lockGui = Instance.new("ScreenGui")
lockGui.Name = "XboatLock"
lockGui.ResetOnSpawn = false
lockGui.DisplayOrder = 10000
lockGui.IgnoreGuiInset = true
lockGui.Enabled = false
lockGui.Parent = CoreGui

lockRoot = Instance.new("Frame")
lockRoot.Size = UDim2.new(1, 0, 1, 0)
lockRoot.Position = UDim2.new(0, 0, 0, 0)
lockRoot.BackgroundColor3 = Color3.new(0, 0, 0)
lockRoot.BackgroundTransparency = 0.45
lockRoot.BorderSizePixel = 0
lockRoot.ZIndex = 1
lockRoot.Parent = lockGui

lockBoxFrame = Instance.new("Frame")
lockBoxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
lockBoxFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
lockBoxFrame.Size = UDim2.new(0, 380, 0, 250)
lockBoxFrame.BackgroundColor3 = accB
lockBoxFrame.BorderSizePixel = 0
lockBoxFrame.ZIndex = 2
lockBoxFrame.Parent = lockRoot
Instance.new("UICorner", lockBoxFrame).CornerRadius = UDim.new(0, 10)
grad(lockBoxFrame, br(accB, 0.06), dr(accB, 0.04), 135)
lockStroke = Instance.new("UIStroke", lockBoxFrame)
lockStroke.Color = accO
lockStroke.Thickness = 2

lockTitle = Instance.new("TextLabel")
lockTitle.Size = UDim2.new(1, -20, 0, 34)
lockTitle.Position = UDim2.new(0, 10, 0, 12)
lockTitle.BackgroundTransparency = 1
lockTitle.Text = "XBOAT - Authentication"
lockTitle.TextColor3 = accF
lockTitle.Font = FH
lockTitle.TextSize = 20
lockTitle.ZIndex = 3
lockTitle.Parent = lockBoxFrame
grad(lockTitle, accF, accO, 90)

lockSubtitle = Instance.new("TextLabel")
lockSubtitle.Size = UDim2.new(1, -20, 0, 20)
lockSubtitle.Position = UDim2.new(0, 10, 0, 48)
lockSubtitle.BackgroundTransparency = 1
lockSubtitle.Text = "Enter your access key to continue"
lockSubtitle.TextColor3 = txtBg()
lockSubtitle.Font = FB
lockSubtitle.TextSize = 13
lockSubtitle.ZIndex = 3
lockSubtitle.Parent = lockBoxFrame

lockBox = Instance.new("TextBox")
lockBox.Size = UDim2.new(1, -40, 0, 40)
lockBox.Position = UDim2.new(0, 20, 0, 78)
lockBox.BackgroundColor3 = Color3.fromRGB(235, 250, 255)
lockBox.TextColor3 = Color3.fromRGB(20, 40, 80)
lockBox.PlaceholderText = "Enter key..."
lockBox.Text = ""
lockBox.TextSize = 16
lockBox.Font = FB
lockBox.ClearTextOnFocus = false
lockBox.BorderSizePixel = 0
lockBox.ZIndex = 3
lockBox.Parent = lockBoxFrame
Instance.new("UICorner", lockBox).CornerRadius = UDim.new(0, 6)

lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(1, -40, 0, 40)
lockBtn.Position = UDim2.new(0, 20, 0, 128)
lockBtn.BackgroundColor3 = accF
lockBtn.Text = "Unlock"
lockBtn.TextColor3 = txtC(accF)
lockBtn.Font = FH
lockBtn.TextSize = 16
lockBtn.BorderSizePixel = 0
lockBtn.AutoButtonColor = false
lockBtn.ZIndex = 3
lockBtn.Parent = lockBoxFrame
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

lockStatus = Instance.new("TextLabel")
lockStatus.Size = UDim2.new(1, -20, 0, 24)
lockStatus.Position = UDim2.new(0, 10, 0, 180)
lockStatus.BackgroundTransparency = 1
lockStatus.Text = ""
lockStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
lockStatus.Font = FB
lockStatus.TextSize = 14
lockStatus.ZIndex = 3
lockStatus.Parent = lockBoxFrame

lockHint = Instance.new("TextLabel")
lockHint.Size = UDim2.new(1, -20, 0, 18)
lockHint.Position = UDim2.new(0, 10, 0, 214)
lockHint.BackgroundTransparency = 1
lockHint.Text = "Press Enter to submit"
lockHint.TextColor3 = Color3.fromRGB(150, 150, 160)
lockHint.Font = FB
lockHint.TextSize = 11
lockHint.ZIndex = 3
lockHint.Parent = lockBoxFrame

function tryUnlock()
    local key = lockBox.Text:match("^%s*(.-)%s*$")
    if key == VALID_KEY then
        lockStatus.Text = "Access granted!"
        lockStatus.TextColor3 = Color3.fromRGB(100, 220, 120)
        snd("toggle")
        task.wait(0.35)
        if lockGui then lockGui:Destroy() end
        Gui.Enabled = true
        MF.Visible = true
        MF.Position = UDim2.new(0, -620, 0, 40)
        TweenService:Create(MF, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 20, 0, 40)}):Play()
        snd("toggle")
    else
        lockStatus.Text = "Invalid key. Try again."
        lockStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
        lockBox.Text = ""
        lockBox:CaptureFocus()
        snd("toggle", 0.6)
        local origPos = lockBoxFrame.Position
        task.spawn(function()
            for i = 1, 3 do
                TweenService:Create(lockBoxFrame, TweenInfo.new(0.05), {Position = UDim2.new(origPos.X.Scale, origPos.X.Offset - 10, origPos.Y.Scale, origPos.Y.Offset)}):Play()
                task.wait(0.05)
                TweenService:Create(lockBoxFrame, TweenInfo.new(0.05), {Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + 10, origPos.Y.Scale, origPos.Y.Offset)}):Play()
                task.wait(0.05)
            end
            TweenService:Create(lockBoxFrame, TweenInfo.new(0.05), {Position = origPos}):Play()
        end)
    end
end

lockBtn.MouseButton1Click:Connect(tryUnlock)
lockBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then tryUnlock() end
end)

task.delay(LD + 0.05, function()
    lP.Text = "100%"
    if lBgScale then TweenService:Create(lBgScale, TweenInfo.new(0.35), {Scale = 0.5}):Play() end
    local t = TweenService:Create(lBg, TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1})
    if lOverlay then TweenService:Create(lOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play() end
    for _, c in ipairs(lBg:GetDescendants()) do
        if c:IsA("TextLabel") then TweenService:Create(c, TweenInfo.new(0.4), {TextTransparency=1}):Play()
        elseif c:IsA("Frame") then TweenService:Create(c, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        elseif c:IsA("UIStroke") then TweenService:Create(c, TweenInfo.new(0.4), {Transparency=1}):Play() end
    end
    t:Play(); t.Completed:Wait()
    if lGui and lGui.Parent then lGui:Destroy() end
    lockGui.Enabled = true
    task.wait(0.2)
    lockBox:CaptureFocus()
    snd("toggle")
end)

-- by dimoonsh == github dimoonsh195 --
