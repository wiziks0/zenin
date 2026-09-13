-- ZENIN CHEAT v8.0 (с системой ключей + HWID)
-- RShift - меню | ПКМ - настройки | Backspace - сброс бинда | LCtrl - лазание по стенам

if _G.ZeninCheat then return end
_G.ZeninCheat = true

local P = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HS = game:GetService("HttpService")
local VU = game:GetService("VirtualUser")
local LP = P.LocalPlayer
local Cam = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

local FIREBASE_URL = "https://zenin-keys-default-rtdb.firebaseio.com"
local KEY_FILE = "ZeninKey.json"

-- ========== HWID ==========
local function getHWID()
    local ok, id
    if syn and syn.get_hwid then ok, id = pcall(syn.get_hwid); if ok and id then return id end end
    if krnl_gethwid then ok, id = pcall(krnl_gethwid); if ok and id then return id end end
    if gethwid then ok, id = pcall(gethwid); if ok and id then return id end end
    if fluxus and fluxus.get_hwid then ok, id = pcall(fluxus.get_hwid); if ok and id then return id end end
    ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok and id then return id end
    return "UNKNOWN_" .. tostring(math.random(100000, 999999))
end

-- ========== HTTP ==========
local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok then return res end
    ok, res = pcall(function() return request({Url = url, Method = "GET"}).Body end)
    if ok then return res end
    return nil
end

local function httpPut(url, body)
    return pcall(function()
        request({
            Url = url, Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
end

-- ========== ПРОВЕРКА КЛЮЧА ==========
local function CheckKey(key, hwid)
    if not key or key == "" then return false, "Введите ключ" end
    local url = FIREBASE_URL .. "/keys/" .. key .. ".json"
    local res = httpGet(url)
    if not res then return false, "Нет соединения с сервером" end
    if res == "null" or res == "" then return false, "Неверный ключ" end

    local ok, data = pcall(function() return HS:JSONDecode(res) end)
    if not ok or type(data) ~= "table" then return false, "Ошибка базы данных" end

    if data.expires and data.expires > 0 then
        if os.time() > data.expires then return false, "Срок действия ключа истёк" end
    end

    if data.hwid and data.hwid ~= "" and data.hwid ~= "null" then
        if data.hwid ~= hwid then return false, "Ключ привязан к другому ПК" end
    else
        httpPut(FIREBASE_URL .. "/keys/" .. key .. "/hwid.json", '"' .. hwid .. '"')
    end
    return true, "OK"
end

local function SaveKey(key)
    if writefile then
        pcall(function() writefile(KEY_FILE, HS:JSONEncode({key = key})) end)
    end
end

local function LoadKey()
    if readfile and isfile and isfile(KEY_FILE) then
        local ok, data = pcall(function() return HS:JSONDecode(readfile(KEY_FILE)) end)
        if ok and data and data.key then return data.key end
    end
    return nil
end

-- ========== ЗАГРУЗКА ЧИТА ==========
local function StartCheat()
    -- ===================== ТЕЛО ЧИТА =====================
    local CFG_FILE = "ZeninCheat_Configs.json"
    local WM_FILE = "ZeninWM_Pos.json"
    local KB_FILE = "ZeninKB_Pos.json"

    local function LoadCfgs()
        if not (writefile and readfile and isfile) then return {} end
        if isfile(CFG_FILE) then
            local ok, d = pcall(function() return HS:JSONDecode(readfile(CFG_FILE)) end)
            if ok and type(d) == "table" then return d end
        end
        return {}
    end
    local function SaveCfgs(c)
        if not writefile then return end
        local ok, e = pcall(function() return HS:JSONEncode(c) end)
        if ok then pcall(function() writefile(CFG_FILE, e) end) end
    end
    local function LoadWMPos()
        if not (readfile and isfile and isfile(WM_FILE)) then return {} end
        local ok, d = pcall(function() return HS:JSONDecode(readfile(WM_FILE)) end)
        if ok and type(d) == "table" then return d end
        return {}
    end
    local function SaveWMPos(t)
        if not writefile then return end
        local ok, e = pcall(function() return HS:JSONEncode(t) end)
        if ok then pcall(function() writefile(WM_FILE, e) end) end
    end
    local function LoadKBPos()
        if not (readfile and isfile and isfile(KB_FILE)) then return {} end
        local ok, d = pcall(function() return HS:JSONDecode(readfile(KB_FILE)) end)
        if ok and type(d) == "table" then return d end
        return {}
    end
    local function SaveKBPos(t)
        if not writefile then return end
        local ok, e = pcall(function() return HS:JSONEncode(t) end)
        if ok then pcall(function() writefile(KB_FILE, e) end) end
    end

    local Cfgs = LoadCfgs()
    local CurCfg = "default"
    local WMPos = LoadWMPos()
    local KBPos = LoadKBPos()

    local S = {
        Fly = false, FlySpd = 50, InfJump = false,
        ESP = false, TeamCheck = true, HB = false, HBSize = 20,
        Spd = false, SpdVal = 16,
        ESPCol = Color3.fromRGB(255, 60, 90), ESPFill = 0,
        HBCol = Color3.fromRGB(255, 60, 90), HBTrans = 0.3,
        Graphics = false,
        GfxIntensity = 100, GfxBrightness = 50, GfxContrast = 50, GfxSaturation = 50,
        Spider = false, SpiderSpd = 30, SpiderKey = Enum.KeyCode.LeftControl,
        Invis = false, ClickTP = false,
        ClickTPBind = Enum.UserInputType.MouseWheel,
        WorldColor = false,
        WorldColorValue = Color3.fromRGB(255, 255, 255),
        KeybindsHUD = true,
        TPPlayers = false,
        SelectedPlayer = nil,
    }

    local B = {Fly=nil,HB=nil,ESP=nil,InfJump=nil,TeamCheck=nil,Spd=nil,Graphics=nil,Spider=nil,Invis=nil,ClickTP=nil,WorldColor=nil,TPPlayers=nil}
    local BindMode, BindTarget = false, nil
    local BindBtns = {}
    local BV, BG = nil, nil
    local SpiderBV = nil
    local ESPCache, HBCache = {}, {}
    local Conns = {}

    local invisRunning = false
    local InvisTrack = {}
    local InvisFix, InvisDied
    local TurnVisible, GoInvisible
    local clickTPBindConn = nil

    local AC = Color3.fromRGB(255, 60, 90)
    local AC2 = Color3.fromRGB(180, 40, 255)
    local BGD = Color3.fromRGB(12, 12, 22)
    local BGM = Color3.fromRGB(22, 22, 38)
    local BGL = Color3.fromRGB(30, 30, 50)
    local TXT = Color3.fromRGB(235, 235, 245)
    local TXD = Color3.fromRGB(150, 150, 170)

    local GE = {toggles = {}, sliders = {}, colors = {}}
    local function RegToggle(k, btn, knob, glow, getter) if k then GE.toggles[k] = {btn=btn, knob=knob, glow=glow, getter=getter} end end
    local function RegSlider(n, f) if n then GE.sliders[n] = {setValue=f} end end
    local function RegColor(n, f) if n then GE.colors[n] = {setColor=f} end end

    local function UpdToggle(k, st)
        local t = GE.toggles[k]; if not t then return end
        TS:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = st and Color3.fromRGB(40,180,100) or Color3.fromRGB(60,60,80)}):Play()
        TS:Create(t.knob, TweenInfo.new(0.2), {Position = st and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11)}):Play()
        TS:Create(t.glow, TweenInfo.new(0.2), {Color = st and Color3.fromRGB(80,255,140) or Color3.fromRGB(100,100,130), Transparency = st and 0 or 0.5}):Play()
    end

    local function isTM(p)
        if not S.TeamCheck then return false end
        local t = LP.Team; return t and p.Team and p.Team == t
    end

    -- FLY
    local function EnFly()
        local c = LP.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        if BV then BV:Destroy() end; if BG then BG:Destroy() end
        BV = Instance.new("BodyVelocity", r); BV.MaxForce = Vector3.new(9e9,9e9,9e9)
        BG = Instance.new("BodyGyro", r); BG.MaxTorque = Vector3.new(9e9,9e9,9e9); BG.P = 1000; BG.D = 50; BG.CFrame = r.CFrame
    end
    local function DisFly()
        if BV then BV:Destroy(); BV = nil end
        if BG then BG:Destroy(); BG = nil end
    end
    local function TgFly() S.Fly = not S.Fly; if S.Fly then EnFly() else DisFly() end end

    -- SPIDER
    local function IsNearWall()
        local c = LP.Character; if not c then return false, nil end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return false, nil end
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {c}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local dirs = {Cam.CFrame.LookVector, -Cam.CFrame.LookVector, -Cam.CFrame.RightVector, Cam.CFrame.RightVector}
        for _, dir in ipairs(dirs) do
            local ray = workspace:Raycast(r.Position, dir * 3.5, params)
            if ray then return true, ray.Normal end
        end
        return false, nil
    end
    local function EnSpider()
        local c = LP.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        if SpiderBV then SpiderBV:Destroy() end
        SpiderBV = Instance.new("BodyVelocity")
        SpiderBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        SpiderBV.Velocity = Vector3.new(0, 0, 0)
        SpiderBV.Parent = r
    end
    local function DisSpider() if SpiderBV then SpiderBV:Destroy(); SpiderBV = nil end end
    local function TgSpider() S.Spider = not S.Spider; if S.Spider then EnSpider() else DisSpider() end end

    -- INVISIBLE
    TurnVisible = function()
        if not invisRunning then return end
        local Clone  = InvisTrack.Clone
        local Orig   = InvisTrack.Orig
        if not Clone or not Orig then invisRunning = false; InvisTrack = {}; return end
        pcall(function() if InvisFix then InvisFix:Disconnect() end end)
        pcall(function() if InvisDied then InvisDied:Disconnect() end end)
        local cloneHRP = Clone:FindFirstChild("HumanoidRootPart")
        local origHRP  = Orig:FindFirstChild("HumanoidRootPart")
        local newCF = cloneHRP and cloneHRP.CFrame or InvisTrack.CF
        local savedVel, savedRotVel
        if cloneHRP then savedVel = cloneHRP.Velocity; savedRotVel = cloneHRP.RotVelocity end
        if origHRP and newCF then
            origHRP.CFrame = newCF
            if savedVel then origHRP.Velocity = savedVel end
            if savedRotVel then origHRP.RotVelocity = savedRotVel end
        end
        if Orig.Parent == Lighting then Orig.Parent = workspace end
        pcall(function() Clone:Destroy() end)
        pcall(function() LP.Character = Orig; Orig.Parent = workspace end)
        pcall(function()
            local h = Orig:FindFirstChildOfClass("Humanoid")
            if h then workspace.CurrentCamera.CameraSubject = h end
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end)
        invisRunning = false
        InvisTrack = {}
        if S.Invis then S.Invis = false; if GE.toggles["Invis"] then UpdToggle("Invis", false) end end
        print("[ZENIN] Invisible: ты снова видим")
    end

    GoInvisible = function()
        if invisRunning then return end
        invisRunning = true
        local speaker = LP
        local tries = 0
        while not speaker.Character and tries < 50 do task.wait(0.1); tries = tries + 1 end
        local Character = speaker.Character
        if not Character then invisRunning = false return end
        if not Character:FindFirstChild("HumanoidRootPart") then Character:WaitForChild("HumanoidRootPart", 5) end
        if not Character:FindFirstChild("HumanoidRootPart") then invisRunning = false return end
        Character.Archivable = true
        local InvisibleCharacter = Character:Clone()
        InvisibleCharacter.Parent = Lighting
        InvisibleCharacter.Name = ""
        InvisTrack.Clone = InvisibleCharacter
        InvisTrack.Orig = Character
        local Void = workspace.FallenPartsDestroyHeight
        local IsInteger = tostring(Void):find("-") ~= nil
        InvisFix = RS.Stepped:Connect(function()
            pcall(function()
                local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                InvisTrack.CF = hrp.CFrame
                local Y = hrp.Position.Y
                if (IsInteger and Y <= Void) or (not IsInteger and Y >= Void) then TurnVisible() end
            end)
        end)
        for _, v in pairs(InvisibleCharacter:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" then v.Transparency = 1 else v.Transparency = 0.5 end
            end
        end
        local h = InvisibleCharacter:FindFirstChildOfClass("Humanoid")
        if h then InvisDied = h.Died:Connect(function() TurnVisible() end) end
        local CF_1 = Character.HumanoidRootPart.CFrame
        InvisTrack.CF = CF_1
        Character:MoveTo(Vector3.new(0, math.pi * 1000000, 0))
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        task.wait(0.2)
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        Character.Parent = Lighting
        InvisibleCharacter.Parent = workspace
        InvisibleCharacter.HumanoidRootPart.CFrame = CF_1
        speaker.Character = InvisibleCharacter
        pcall(function()
            workspace.CurrentCamera.CameraSubject = InvisibleCharacter:FindFirstChildWhichIsA("Humanoid")
            workspace.CurrentCamera.CameraType = "Custom"
        end)
        pcall(function()
            if InvisibleCharacter:FindFirstChild("Animate") then
                InvisibleCharacter.Animate.Disabled = true
                InvisibleCharacter.Animate.Disabled = false
            end
        end)
        print("[ZENIN] Invisible: ты теперь невидим")
    end

    local function TgInvis()
        S.Invis = not S.Invis
        if S.Invis then GoInvisible() else TurnVisible() end
    end

    -- CLICK TP
    local function StopClickTP()
        if clickTPBindConn then pcall(function() clickTPBindConn:Disconnect() end); clickTPBindConn = nil end
    end

    local function DoTeleport()
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local mouse = LP:GetMouse()
        local hit = mouse.Hit
        if hit then
            hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
            pcall(function() hrp.Velocity = Vector3.new(0,0,0); hrp.RotVelocity = Vector3.new(0,0,0) end)
        end
    end

    local function StartClickTP()
        StopClickTP()
        clickTPBindConn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if not S.ClickTPBind then return end
            local match = false
            local bind = S.ClickTPBind
            if typeof(bind) == "EnumItem" then
                if bind.EnumType == Enum.UserInputType then match = input.UserInputType == bind
                elseif bind.EnumType == Enum.KeyCode then match = input.KeyCode == bind end
            end
            if match then DoTeleport(); if KB_Flash then KB_Flash("ClickTP") end end
        end)
        table.insert(Conns, clickTPBindConn)
    end

    local function TgClickTP()
        S.ClickTP = not S.ClickTP
        if S.ClickTP then StartClickTP() else print("[ZENIN] Click TP выключен") end
    end

    -- TP PLAYERS
    local function GetAlivePlayers()
        local list = {}
        for _, p in ipairs(P:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(list, p) end
            end
        end
        return list
    end

    local function TeleportToPlayer(target)
        if not target or not target.Character then return end
        local myChar = LP.Character; if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart"); if not targetHRP then return end
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        pcall(function() myHRP.Velocity = Vector3.new(0,0,0); myHRP.RotVelocity = Vector3.new(0,0,0) end)
        S.SelectedPlayer = target.Name
        if KB_Flash then KB_Flash("TPPlayers") end
    end

    local function TgTPPlayers() S.TPPlayers = not S.TPPlayers end

    -- ESP
    local function CrESP(p)
        if ESPCache[p] or not p.Character or isTM(p) then return end
        local h = Instance.new("Highlight", p.Character)
        h.Name = "ESP"; h.Adornee = p.Character
        h.FillColor = S.ESPCol; h.OutlineColor = S.ESPCol
        h.FillTransparency = S.ESPFill; h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        ESPCache[p] = h
    end
    local function RmESP(p) if ESPCache[p] then ESPCache[p]:Destroy(); ESPCache[p] = nil end end
    local function EnESP() for _, p in ipairs(P:GetPlayers()) do if p ~= LP and p.Character and not isTM(p) then CrESP(p) end end end
    local function DisESP() for p, h in pairs(ESPCache) do if h then h:Destroy() end end; ESPCache = {} end
    local function TgESP() S.ESP = not S.ESP; if S.ESP then EnESP() else DisESP() end end
    local function UpESPCol(c) S.ESPCol = c; for _, h in pairs(ESPCache) do if h then h.FillColor = c; h.OutlineColor = c end end end
    local function UpESPFill(v) S.ESPFill = v/100; for _, h in pairs(ESPCache) do if h then h.FillTransparency = S.ESPFill end end end

    -- HITBOX
    local function CrHB(p)
        if HBCache[p] or not p.Character or isTM(p) then return end
        local r = p.Character:FindFirstChild("HumanoidRootPart"); if not r then return end
        local os, oc, om, ot = r.Size, r.Color, r.Material, r.Transparency
        r.Size = Vector3.new(S.HBSize, S.HBSize, S.HBSize)
        r.Transparency = S.HBTrans; r.Color = S.HBCol
        r.BrickColor = BrickColor.new(S.HBCol); r.Material = Enum.Material.ForceField; r.CanCollide = false
        HBCache[p] = {R = r, OS = os, OC = oc, OM = om, OT = ot}
    end
    local function RmHB(p)
        if not HBCache[p] then return end
        local d = HBCache[p]
        if d.R and d.R.Parent then
            d.R.Size = d.OS or Vector3.new(2,2,2); d.R.Transparency = d.OT or 0
            d.R.Color = d.OC or Color3.fromRGB(255,255,255); d.R.Material = d.OM or Enum.Material.Plastic; d.R.CanCollide = true
        end
        HBCache[p] = nil
    end
    local function EnHB() for _, p in ipairs(P:GetPlayers()) do if p ~= LP and p.Character and not isTM(p) then CrHB(p) end end end
    local function DisHB() for p in pairs(HBCache) do RmHB(p) end; HBCache = {} end
    local function TgHB() S.HB = not S.HB; if S.HB then EnHB() else DisHB() end end
    local function UpHBSz(v) S.HBSize = v; for _, d in pairs(HBCache) do if d.R and d.R.Parent then d.R.Size = Vector3.new(v,v,v) end end end
    local function UpHBCol(c) S.HBCol = c; for _, d in pairs(HBCache) do if d.R and d.R.Parent then d.R.Color = c; d.R.BrickColor = BrickColor.new(c) end end end
    local function UpHBTr(v) S.HBTrans = v/100; for _, d in pairs(HBCache) do if d.R and d.R.Parent then d.R.Transparency = S.HBTrans end end end

    local function TgInfJump() S.InfJump = not S.InfJump end
    local function TgTC() S.TeamCheck = not S.TeamCheck; if S.ESP then DisESP() EnESP() end; if S.HB then DisHB() EnHB() end end

    -- SPEED
    local function ApSpd() local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = S.SpdVal end end
    local function RsSpd() local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = 16 end end
    local function TgSpd() S.Spd = not S.Spd; if S.Spd then ApSpd() else RsSpd() end end
    local function UpSpdV(v) S.SpdVal = v; if S.Spd then ApSpd() end end

    -- GRAPHICS
    local GfxCC, GfxBloom = nil, nil
    local function EnsureGfxInstances()
        if not GfxCC or not GfxCC.Parent then
            GfxCC = Instance.new("ColorCorrectionEffect"); GfxCC.Name = "ZeninGfxCC"; GfxCC.Parent = Lighting
        end
        if not GfxBloom or not GfxBloom.Parent then
            GfxBloom = Instance.new("BloomEffect"); GfxBloom.Name = "ZeninGfxBloom"; GfxBloom.Parent = Lighting
        end
    end
    local function ApplyGraphics()
        EnsureGfxInstances()
        if not S.Graphics or S.GfxIntensity <= 0 then
            GfxCC.Brightness = 0; GfxCC.Contrast = 0; GfxCC.Saturation = 0
            GfxBloom.Intensity = 0; GfxBloom.Size = 0; GfxBloom.Threshold = 2
            return
        end
        local inten = S.GfxIntensity / 100
        local br = (S.GfxBrightness - 50) / 100
        local ct = (S.GfxContrast - 50) / 100
        local st = (S.GfxSaturation - 50) / 50
        GfxCC.Brightness = br * inten * 2
        GfxCC.Contrast = ct * inten * 2
        GfxCC.Saturation = st * inten * 2
        GfxBloom.Intensity = inten * 0.6
        GfxBloom.Size = 24 * inten
        GfxBloom.Threshold = 1.2 - inten * 0.4
    end
    local function TgGraphics() S.Graphics = not S.Graphics; ApplyGraphics() end
    local function UpGfxIntensity(v) S.GfxIntensity = v; ApplyGraphics() end
    local function UpGfxBrightness(v) S.GfxBrightness = v; ApplyGraphics() end
    local function UpGfxContrast(v) S.GfxContrast = v; ApplyGraphics() end
    local function UpGfxSaturation(v) S.GfxSaturation = v; ApplyGraphics() end

    -- WORLD COLOR
    local WorldColorSky, WorldColorAtmos, WorldColorSaved = nil, nil, nil
    local function EnsureWorldColor()
        if not WorldColorSky or not WorldColorSky.Parent then
            WorldColorSky = Instance.new("Sky")
            WorldColorSky.Name = "ZeninWorldSky"; WorldColorSky.Parent = Lighting
            WorldColorSky.SkyboxBk = ""; WorldColorSky.SkyboxDn = ""; WorldColorSky.SkyboxFt = ""
            WorldColorSky.SkyboxLf = ""; WorldColorSky.SkyboxRt = ""; WorldColorSky.SkyboxUp = ""
            WorldColorSky.StarCount = 0
        end
        if not WorldColorAtmos or not WorldColorAtmos.Parent then
            WorldColorAtmos = Instance.new("Atmosphere")
            WorldColorAtmos.Name = "ZeninWorldAtmos"; WorldColorAtmos.Parent = Lighting
        end
    end
    local function SaveWorldColorState()
        if WorldColorSaved then return end
        WorldColorSaved = {
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
            ColorShift_Top = Lighting.ColorShift_Top, ColorShift_Bottom = Lighting.ColorShift_Bottom,
            Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
            FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
        }
    end
    local function RestoreWorldColorState()
        if not WorldColorSaved then return end
        pcall(function()
            Lighting.Ambient = WorldColorSaved.Ambient
            Lighting.OutdoorAmbient = WorldColorSaved.OutdoorAmbient
            Lighting.ColorShift_Top = WorldColorSaved.ColorShift_Top
            Lighting.ColorShift_Bottom = WorldColorSaved.ColorShift_Bottom
            Lighting.Brightness = WorldColorSaved.Brightness
            Lighting.ClockTime = WorldColorSaved.ClockTime
            Lighting.FogColor = WorldColorSaved.FogColor
            Lighting.FogStart = WorldColorSaved.FogStart
            Lighting.FogEnd = WorldColorSaved.FogEnd
            Lighting.GlobalShadows = WorldColorSaved.GlobalShadows
        end)
        WorldColorSaved = nil
    end
    local function ApplyWorldColor()
        EnsureWorldColor()
        if not S.WorldColor then
            if WorldColorSky then WorldColorSky.Enabled = false end
            if WorldColorAtmos then WorldColorAtmos.Enabled = false end
            RestoreWorldColorState()
            return
        end
        SaveWorldColorState()
        local c = S.WorldColorValue
        local cr, cg, cb = c.R, c.G, c.B
        pcall(function()
            Lighting.Ambient = Color3.new(cr*0.5, cg*0.5, cb*0.5)
            Lighting.OutdoorAmbient = Color3.new(cr*0.4, cg*0.4, cb*0.4)
            Lighting.ColorShift_Top = c
            Lighting.ColorShift_Bottom = Color3.new(cr*0.5, cg*0.5, cb*0.5)
            Lighting.Brightness = math.max(Lighting.Brightness, 2)
            Lighting.FogColor = c
            Lighting.FogStart = 0
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end)
        WorldColorAtmos.Enabled = true
        WorldColorAtmos.Density = 0.35
        WorldColorAtmos.Offset = 0
        WorldColorAtmos.Color = c
        WorldColorAtmos.Decay = Color3.new(cr*0.6, cg*0.6, cb*0.6)
        WorldColorAtmos.Glare = 0
        WorldColorAtmos.Haze = 2
        WorldColorSky.Enabled = true
        pcall(function()
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then terrain.WaterColor = c; terrain.WaterTransparency = 0.3 end
        end)
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(LP.Character or game) then
                    if not obj:GetAttribute("ZeninOrigColor") then obj:SetAttribute("ZeninOrigColor", obj.Color) end
                    local orig = obj:GetAttribute("ZeninOrigColor")
                    if orig then
                        obj.Color = Color3.new(
                            math.clamp(orig.R*cr*0.7 + cr*0.3, 0, 1),
                            math.clamp(orig.G*cg*0.7 + cg*0.3, 0, 1),
                            math.clamp(orig.B*cb*0.7 + cb*0.3, 0, 1)
                        )
                    end
                end
            end
        end)
    end
    local function TgWorldColor() S.WorldColor = not S.WorldColor; ApplyWorldColor() end
    local function SetWorldColor(c) S.WorldColorValue = c; if S.WorldColor then ApplyWorldColor() end end

    -- BINDS
    local function GetBN(k)
        if not k then return "НЕТ" end
        if typeof(k) == "EnumItem" then
            return (k.Name:gsub("KeyCode%.", ""):gsub("UserInputType%.", ""))
        end
        return tostring(k)
    end
    local function ApBind(k)
        if not BindTarget then return end
        if k == Enum.KeyCode.Backspace then
            B[BindTarget] = nil
            if BindBtns[BindTarget] then BindBtns[BindTarget].Text = "—"; BindBtns[BindTarget].TextColor3 = TXD end
            BindMode, BindTarget = false, nil
            if KB_Refresh then KB_Refresh() end
            return
        end
        B[BindTarget] = k
        if BindBtns[BindTarget] then BindBtns[BindTarget].Text = GetBN(k); BindBtns[BindTarget].TextColor3 = AC end
        BindMode, BindTarget = false, nil
        if KB_Refresh then KB_Refresh() end
    end

    local function GetBindToggleState(bindKey)
        if bindKey == "Fly" then return S.Fly end
        if bindKey == "HB" then return S.HB end
        if bindKey == "ESP" then return S.ESP end
        if bindKey == "InfJump" then return S.InfJump end
        if bindKey == "TeamCheck" then return S.TeamCheck end
        if bindKey == "Spd" then return S.Spd end
        if bindKey == "Graphics" then return S.Graphics end
        if bindKey == "Spider" then return S.Spider end
        if bindKey == "Invis" then return S.Invis end
        if bindKey == "ClickTP" then return S.ClickTP end
        if bindKey == "WorldColor" then return S.WorldColor end
        if bindKey == "TPPlayers" then return S.TPPlayers end
        return false
    end

    local function ChkBind(i)
        if BindMode then return end
        local k = i.KeyCode
        if B.Fly == k then TgFly() end
        if B.HB == k then TgHB() end
        if B.ESP == k then TgESP() end
        if B.InfJump == k then TgInfJump() end
        if B.TeamCheck == k then TgTC() end
        if B.Spd == k then TgSpd() end
        if B.Graphics == k then TgGraphics() end
        if B.Spider == k then TgSpider() end
        if B.Invis == k then TgInvis() end
        if B.ClickTP == k then TgClickTP() end
        if B.WorldColor == k then TgWorldColor() end
        if B.TPPlayers == k then TgTPPlayers() end
        if KB_UpdateStates then task.defer(KB_UpdateStates) end
    end

    -- SERIALIZE
    local function C2T(c) return {R=c.R, G=c.G, B=c.B} end
    local function T2C(t) if type(t) == "table" then return Color3.new(t.R or 0, t.G or 0, t.B or 0) end return Color3.fromRGB(255,60,90) end
    local function KN(k)
        if not k then return nil end
        if type(k) == "string" then return k end
        if typeof(k) == "EnumItem" then return k.Name end
        return nil
    end
    local function NK(n) if not n then return nil end; local ok, k = pcall(function() return Enum.KeyCode[n] end); if ok then return k end return nil end
    local function NUIT(n)
        if not n then return nil end
        local ok, v = pcall(function() return Enum.UserInputType[n] end)
        if ok and v then return v end
        local ok2, v2 = pcall(function() return Enum.KeyCode[n] end)
        if ok2 and v2 then return v2 end
        return nil
    end

    local function Ser()
        return {
            Fly = S.Fly, FlySpd = S.FlySpd, InfJump = S.InfJump, ESP = S.ESP, TeamCheck = S.TeamCheck,
            HB = S.HB, HBSize = S.HBSize, Spd = S.Spd, SpdVal = S.SpdVal,
            ESPCol = C2T(S.ESPCol), ESPFill = S.ESPFill, HBCol = C2T(S.HBCol), HBTrans = S.HBTrans,
            Graphics = S.Graphics, GfxIntensity = S.GfxIntensity,
            GfxBrightness = S.GfxBrightness, GfxContrast = S.GfxContrast, GfxSaturation = S.GfxSaturation,
            Spider = S.Spider, SpiderSpd = S.SpiderSpd,
            Invis = S.Invis, ClickTP = S.ClickTP, ClickTPBind = KN(S.ClickTPBind),
            WorldColor = S.WorldColor, WorldColorValue = C2T(S.WorldColorValue),
            KeybindsHUD = S.KeybindsHUD, TPPlayers = S.TPPlayers,
            Binds = {
                Fly=KN(B.Fly), HB=KN(B.HB), ESP=KN(B.ESP), InfJump=KN(B.InfJump),
                TeamCheck=KN(B.TeamCheck), Spd=KN(B.Spd), Graphics=KN(B.Graphics), Spider=KN(B.Spider),
                Invis=KN(B.Invis), ClickTP=KN(B.ClickTP), WorldColor=KN(B.WorldColor),
                TPPlayers=KN(B.TPPlayers)
            }
        }
    end

    local function ApCfg(d)
        if not d then return end
        if S.ESP then DisESP() end
        if S.HB then DisHB() end
        if S.Fly then DisFly() end
        if S.Spider then DisSpider() end
        if S.Spd then RsSpd() end
        if S.Invis and invisRunning then TurnVisible() end
        if S.ClickTP then StopClickTP() end
        if S.WorldColor then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local oc = obj:GetAttribute("ZeninOrigColor")
                        if oc then obj.Color = oc end
                    end
                end
            end)
            RestoreWorldColorState()
        end
        S.Fly = d.Fly or false; S.FlySpd = d.FlySpd or 50; S.InfJump = d.InfJump or false
        S.ESP = d.ESP or false; S.TeamCheck = d.TeamCheck ~= false
        S.HB = d.HB or false; S.HBSize = d.HBSize or 20
        S.Spd = d.Spd or false; S.SpdVal = d.SpdVal or 16
        S.ESPCol = T2C(d.ESPCol); S.ESPFill = d.ESPFill or 0
        S.HBCol = T2C(d.HBCol); S.HBTrans = d.HBTrans or 0.3
        S.Graphics = d.Graphics or false
        S.GfxIntensity = d.GfxIntensity or 100
        S.GfxBrightness = d.GfxBrightness or 50
        S.GfxContrast = d.GfxContrast or 50
        S.GfxSaturation = d.GfxSaturation or 50
        S.Spider = d.Spider or false
        S.SpiderSpd = d.SpiderSpd or 30
        S.Invis = d.Invis or false
        S.ClickTP = d.ClickTP or false
        S.ClickTPBind = NUIT(d.ClickTPBind)
        S.WorldColor = d.WorldColor or false
        if d.WorldColorValue then S.WorldColorValue = T2C(d.WorldColorValue) end
        if d.KeybindsHUD ~= nil then S.KeybindsHUD = d.KeybindsHUD end
        S.TPPlayers = d.TPPlayers or false
        if d.Binds then
            B.Fly = NK(d.Binds.Fly); B.HB = NK(d.Binds.HB); B.ESP = NK(d.Binds.ESP)
            B.InfJump = NK(d.Binds.InfJump); B.TeamCheck = NK(d.Binds.TeamCheck); B.Spd = NK(d.Binds.Spd)
            B.Graphics = NK(d.Binds.Graphics); B.Spider = NK(d.Binds.Spider)
            B.Invis = NK(d.Binds.Invis); B.ClickTP = NK(d.Binds.ClickTP)
            B.WorldColor = NK(d.Binds.WorldColor); B.TPPlayers = NK(d.Binds.TPPlayers)
            for k, btn in pairs(BindBtns) do
                if btn then local bd = B[k]; btn.Text = bd and GetBN(bd) or "—"; btn.TextColor3 = bd and AC or TXD end
            end
        end
        for k, t in pairs(GE.toggles) do UpdToggle(k, t.getter()) end
        if GE.sliders["Скорость полёта"] then GE.sliders["Скорость полёта"].setValue(S.FlySpd) end
        if GE.sliders["Размер хитбокса"] then GE.sliders["Размер хитбокса"].setValue(S.HBSize) end
        if GE.sliders["Прозрачность (%)"] then GE.sliders["Прозрачность (%)"].setValue(math.floor(S.HBTrans*100)) end
        if GE.sliders["Скорость бега"] then GE.sliders["Скорость бега"].setValue(S.SpdVal) end
        if GE.sliders["Заливка (%)"] then GE.sliders["Заливка (%)"].setValue(math.floor(S.ESPFill*100)) end
        if GE.sliders["Интенсивность (%)"] then GE.sliders["Интенсивность (%)"].setValue(S.GfxIntensity) end
        if GE.sliders["Яркость (%)"] then GE.sliders["Яркость (%)"].setValue(S.GfxBrightness) end
        if GE.sliders["Контрастность (%)"] then GE.sliders["Контрастность (%)"].setValue(S.GfxContrast) end
        if GE.sliders["Насыщенность (%)"] then GE.sliders["Насыщенность (%)"].setValue(S.GfxSaturation) end
        if GE.sliders["Скорость лазания"] then GE.sliders["Скорость лазания"].setValue(S.SpiderSpd) end
        if GE.colors["Цвет ESP"] then GE.colors["Цвет ESP"].setColor(S.ESPCol) end
        if GE.colors["Цвет хитбокса"] then GE.colors["Цвет хитбокса"].setColor(S.HBCol) end
        if GE.colors["Цвет мира"] then GE.colors["Цвет мира"].setColor(S.WorldColorValue) end
        if S.Fly then EnFly() end; if S.ESP then EnESP() end; if S.HB then EnHB() end
        if S.Spd then ApSpd() end; if S.Spider then EnSpider() end
        if S.Invis and not invisRunning then task.spawn(GoInvisible) end
        if S.ClickTP then StartClickTP() end
        ApplyGraphics(); ApplyWorldColor()
        if KB_Refresh then KB_Refresh() end
    end

    local function SvCfg(n) if not n or n == "" then return end; Cfgs[n] = Ser(); SaveCfgs(Cfgs); CurCfg = n end
    local function LdCfg(n) if not Cfgs[n] then return end; ApCfg(Cfgs[n]); CurCfg = n end
    local function DlCfg(n) if not Cfgs[n] then return end; Cfgs[n] = nil; SaveCfgs(Cfgs); if CurCfg == n then CurCfg = "default" end end

    table.insert(Conns, LP.Idled:connect(function()
        VU:Button2Down(Vector2.new(0,0), Cam.CFrame); task.wait(1); VU:Button2Up(Vector2.new(0,0), Cam.CFrame)
    end))

    -- GUI
    local SG = Instance.new("ScreenGui")
    SG.Name = "ZeninCheat"; SG.Parent = LP:WaitForChild("PlayerGui")
    SG.ResetOnSpawn = false; SG.IgnoreGuiInset = true
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.ClipToDeviceSafeArea = false
    SG.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None

    local MF = Instance.new("Frame", SG)
    MF.Size = UDim2.new(0, 420, 0, 620); MF.Position = UDim2.new(0.5, -210, 0.5, -310)
    MF.BackgroundColor3 = BGD; MF.BorderSizePixel = 0; MF.Visible = false; MF.ZIndex = 10; MF.ClipsDescendants = true
    Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 18)
    local MGr = Instance.new("UIGradient", MF)
    MGr.Rotation = 135
    MGr.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18,14,30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12,12,22)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22,14,32)),
    })

    local HD = Instance.new("Frame", MF)
    HD.Size = UDim2.new(1, 0, 0, 60); HD.BackgroundColor3 = BGD; HD.BorderSizePixel = 0; HD.ZIndex = 20
    Instance.new("UICorner", HD).CornerRadius = UDim.new(0, 18)
    local HG = Instance.new("UIGradient", HD)
    HG.Rotation = 90
    HG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28,18,42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14,14,26)),
    })

    local LB = Instance.new("Frame", HD)
    LB.Size = UDim2.new(0, 40, 0, 40); LB.Position = UDim2.new(0, 14, 0.5, -20)
    LB.BackgroundColor3 = AC; LB.BorderSizePixel = 0; LB.ZIndex = 22
    Instance.new("UICorner", LB).CornerRadius = UDim.new(0, 10)
    local LG = Instance.new("UIGradient", LB); LG.Rotation = 45
    LG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, AC), ColorSequenceKeypoint.new(1, AC2)})
    local LZ = Instance.new("TextLabel", LB)
    LZ.Size = UDim2.new(1, 0, 1, 0); LZ.BackgroundTransparency = 1; LZ.Text = "Z"
    LZ.TextColor3 = Color3.new(1,1,1); LZ.TextSize = 26; LZ.Font = Enum.Font.GothamBold; LZ.ZIndex = 23

    local TT = Instance.new("TextLabel", HD)
    TT.Size = UDim2.new(0.5, 0, 1, 0); TT.Position = UDim2.new(0, 66, 0, 0); TT.BackgroundTransparency = 1
    TT.Text = "ZENIN"; TT.TextColor3 = TXT; TT.TextSize = 22; TT.Font = Enum.Font.GothamBold
    TT.TextXAlignment = Enum.TextXAlignment.Left; TT.ZIndex = 22

    local CB = Instance.new("TextButton", HD)
    CB.Size = UDim2.new(0, 32, 0, 32); CB.Position = UDim2.new(1, -44, 0.5, -16)
    CB.Text = "X"; CB.TextColor3 = Color3.fromRGB(200,200,220); CB.TextSize = 16
    CB.Font = Enum.Font.GothamBold; CB.BackgroundColor3 = Color3.fromRGB(35,35,55)
    CB.BorderSizePixel = 0; CB.ZIndex = 22; CB.AutoButtonColor = false
    Instance.new("UICorner", CB).CornerRadius = UDim.new(0, 8)
    local CS = Instance.new("UIStroke", CB); CS.Color = Color3.fromRGB(80,80,110); CS.Thickness = 1; CS.Transparency = 0.5
    CB.MouseEnter:connect(function() TS:Create(CB, TweenInfo.new(0.15), {TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(180,30,50)}):Play(); TS:Create(CS, TweenInfo.new(0.15), {Color = AC, Transparency = 0}):Play() end)
    CB.MouseLeave:connect(function() TS:Create(CB, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,220), BackgroundColor3 = Color3.fromRGB(35,35,55)}):Play(); TS:Create(CS, TweenInfo.new(0.15), {Color = Color3.fromRGB(80,80,110), Transparency = 0.5}):Play() end)
    CB.MouseButton1Click:connect(function()
        TS:Create(MF, TweenInfo.new(0.2), {Size = UDim2.new(0, 420, 0, 0)}):Play()
        task.wait(0.2); MF.Visible = false; MF.Size = UDim2.new(0, 420, 0, 620)
    end)

    local CT = Instance.new("ScrollingFrame", MF)
    CT.Size = UDim2.new(1, -24, 1, -80); CT.Position = UDim2.new(0, 12, 0, 70)
    CT.BackgroundTransparency = 1; CT.ZIndex = 20; CT.BorderSizePixel = 0
    CT.ScrollBarThickness = 4; CT.ScrollBarImageColor3 = AC
    CT.CanvasSize = UDim2.new(0, 0, 0, 0); CT.AutomaticCanvasSize = Enum.AutomaticSize.Y
    CT.ScrollingDirection = Enum.ScrollingDirection.Y
    local LY = Instance.new("UIListLayout", CT)
    LY.SortOrder = Enum.SortOrder.LayoutOrder; LY.Padding = UDim.new(0, 6)
    local OC = 0
    local function NxO() OC = OC + 1; return OC end

    local function CrTg(txt, icon, bKey, get, set, cb, sBuild)
        local H = Instance.new("Frame", CT)
        H.Size = UDim2.new(1, -4, 0, 42); H.BackgroundTransparency = 1; H.ZIndex = 21; H.LayoutOrder = NxO()
        local F = Instance.new("Frame", H)
        F.Size = UDim2.new(1, 0, 0, 42); F.BackgroundColor3 = BGM; F.BackgroundTransparency = 0.3
        F.BorderSizePixel = 0; F.ZIndex = 21
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 10)
        local FS = Instance.new("UIStroke", F); FS.Color = Color3.fromRGB(60,60,90); FS.Thickness = 1; FS.Transparency = 0.5

        local IL = Instance.new("TextLabel", F)
        IL.Size = UDim2.new(0, 24, 0, 24); IL.Position = UDim2.new(0, 10, 0.5, -12)
        IL.BackgroundTransparency = 1; IL.Text = icon; IL.TextSize = 16; IL.Font = Enum.Font.GothamBold; IL.ZIndex = 22

        local L = Instance.new("TextLabel", F)
        L.Size = UDim2.new(0.4, 0, 1, 0); L.Position = UDim2.new(0, 40, 0, 0)
        L.BackgroundTransparency = 1; L.Text = txt; L.TextColor3 = TXT; L.TextSize = 14
        L.Font = Enum.Font.GothamBold; L.TextXAlignment = Enum.TextXAlignment.Left; L.ZIndex = 22

        local BB = Instance.new("TextButton", F)
        BB.Size = UDim2.new(0, 55, 0, 24); BB.Position = UDim2.new(0.52, 0, 0.5, -12)
        BB.Text = "—"; BB.TextColor3 = TXD; BB.TextSize = 12; BB.Font = Enum.Font.GothamBold
        BB.BackgroundColor3 = BGL; BB.BorderSizePixel = 0; BB.ZIndex = 22; BB.AutoButtonColor = false
        Instance.new("UICorner", BB).CornerRadius = UDim.new(0, 6)
        local BBS = Instance.new("UIStroke", BB); BBS.Color = Color3.fromRGB(80,80,110); BBS.Thickness = 1; BBS.Transparency = 0.5
        if bKey then BindBtns[bKey] = BB end
        BB.MouseButton1Click:connect(function()
            if not bKey then return end
            if BindMode and BindTarget == bKey then
                BindMode, BindTarget = false, nil
                BB.Text = B[bKey] and GetBN(B[bKey]) or "—"; BB.TextColor3 = B[bKey] and AC or TXD
            else
                BindMode, BindTarget = true, bKey
                BB.Text = "..."; BB.TextColor3 = Color3.fromRGB(80,255,140); BB.BackgroundColor3 = Color3.fromRGB(30,50,40)
            end
        end)

        local BTN = Instance.new("TextButton", F)
        BTN.Size = UDim2.new(0, 60, 0, 28); BTN.Position = UDim2.new(1, -70, 0.5, -14)
        BTN.Text = ""; BTN.BackgroundColor3 = get() and Color3.fromRGB(40,180,100) or Color3.fromRGB(60,60,80)
        BTN.BorderSizePixel = 0; BTN.ZIndex = 22; BTN.AutoButtonColor = false
        Instance.new("UICorner", BTN).CornerRadius = UDim.new(1, 0)

        local KN = Instance.new("Frame", BTN)
        KN.Size = UDim2.new(0, 22, 0, 22)
        KN.Position = get() and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11)
        KN.BackgroundColor3 = Color3.new(1,1,1); KN.BorderSizePixel = 0; KN.ZIndex = 23
        Instance.new("UICorner", KN).CornerRadius = UDim.new(1, 0)

        local BG2 = Instance.new("UIStroke", BTN)
        BG2.Color = get() and Color3.fromRGB(80,255,140) or Color3.fromRGB(100,100,130)
        BG2.Thickness = 1; BG2.Transparency = get() and 0 or 0.5

        local function upd(st)
            TS:Create(BTN, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = st and Color3.fromRGB(40,180,100) or Color3.fromRGB(60,60,80)}):Play()
            TS:Create(KN, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = st and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11)}):Play()
            TS:Create(BG2, TweenInfo.new(0.2), {Color = st and Color3.fromRGB(80,255,140) or Color3.fromRGB(100,100,130), Transparency = st and 0 or 0.5}):Play()
        end

        if bKey then RegToggle(bKey, BTN, KN, BG2, get) end

        BTN.MouseButton1Click:connect(function()
            set(not get()); upd(get()); if cb then cb() end
            if KB_Refresh then KB_Refresh() end
        end)

        if sBuild then
            local SF = Instance.new("Frame", H)
            SF.Size = UDim2.new(1, 0, 0, 0); SF.Position = UDim2.new(0, 0, 0, 46)
            SF.BackgroundColor3 = BGL; SF.BackgroundTransparency = 0.3; SF.BorderSizePixel = 0
            SF.Visible = false; SF.ZIndex = 25; SF.ClipsDescendants = true
            Instance.new("UICorner", SF).CornerRadius = UDim.new(0, 10)
            local SS2 = Instance.new("UIStroke", SF); SS2.Color = AC; SS2.Thickness = 1; SS2.Transparency = 0.5
            local tH = sBuild(SF)
            local isO = false
            local function TgS()
                isO = not isO
                if isO then
                    SF.Visible = true
                    TS:Create(H, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -4, 0, 42 + tH + 6)}):Play()
                    TS:Create(SF, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, tH)}):Play()
                else
                    TS:Create(H, TweenInfo.new(0.15), {Size = UDim2.new(1, -4, 0, 42)}):Play()
                    TS:Create(SF, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    task.wait(0.15); SF.Visible = false
                end
            end
            F.InputBegan:connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then TgS() end end)
            L.InputBegan:connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then TgS() end end)
            IL.InputBegan:connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then TgS() end end)
        end
        return H
    end

    local function CrSl(par, yO, lTxt, minV, maxV, defV, cb)
        local SL = Instance.new("TextLabel", par)
        SL.Size = UDim2.new(0.6, 0, 0, 20); SL.Position = UDim2.new(0, 12, 0, yO + 4)
        SL.BackgroundTransparency = 1; SL.Text = lTxt; SL.TextColor3 = TXT; SL.TextSize = 12
        SL.Font = Enum.Font.GothamBold; SL.TextXAlignment = Enum.TextXAlignment.Left; SL.ZIndex = 31

        local SV = Instance.new("TextLabel", par)
        SV.Size = UDim2.new(0.3, 0, 0, 20); SV.Position = UDim2.new(0.68, 0, 0, yO + 4)
        SV.BackgroundTransparency = 1; SV.Text = tostring(defV); SV.TextColor3 = AC; SV.TextSize = 12
        SV.Font = Enum.Font.GothamBold; SV.TextXAlignment = Enum.TextXAlignment.Right; SV.ZIndex = 31

        local SS = Instance.new("Frame", par)
        SS.Size = UDim2.new(1, -24, 0, 6); SS.Position = UDim2.new(0, 12, 0, yO + 32)
        SS.BackgroundColor3 = Color3.fromRGB(45,45,65); SS.BorderSizePixel = 0; SS.ZIndex = 31
        Instance.new("UICorner", SS).CornerRadius = UDim.new(1, 0)

        local pos = (defV - minV) / (maxV - minV)
        local SF = Instance.new("Frame", SS)
        SF.Size = UDim2.new(pos, 0, 1, 0); SF.BackgroundColor3 = AC; SF.BorderSizePixel = 0; SF.ZIndex = 32
        Instance.new("UICorner", SF).CornerRadius = UDim.new(1, 0)
        local SFG = Instance.new("UIGradient", SF)
        SFG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, AC), ColorSequenceKeypoint.new(1, AC2)})

        local SK = Instance.new("Frame", SS)
        SK.Size = UDim2.new(0, 14, 0, 14); SK.Position = UDim2.new(pos, -7, 0.5, -7)
        SK.BackgroundColor3 = Color3.new(1,1,1); SK.BorderSizePixel = 0; SK.ZIndex = 33
        Instance.new("UICorner", SK).CornerRadius = UDim.new(1, 0)
        local SKG = Instance.new("UIStroke", SK); SKG.Color = AC; SKG.Thickness = 1.5; SKG.Transparency = 0

        local drg = false
        local function UpS(mx)
            local p = math.clamp((mx - SS.AbsolutePosition.X) / SS.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + p * (maxV - minV) + 0.5)
            SV.Text = tostring(v); SF.Size = UDim2.new(p, 0, 1, 0); SK.Position = UDim2.new(p, -7, 0.5, -7)
            if cb then cb(v) end
        end
        local function SetV(v)
            v = math.clamp(v, minV, maxV)
            local p = (v - minV) / (maxV - minV)
            SV.Text = tostring(v); SF.Size = UDim2.new(p, 0, 1, 0); SK.Position = UDim2.new(p, -7, 0.5, -7)
        end
        if lTxt then RegSlider(lTxt, SetV) end

        SS.InputBegan:connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drg = true; UpS(i.Position.X) end end)
        SS.InputEnded:connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drg = false end end)
        SS.InputChanged:connect(function(i) if drg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then UpS(i.Position.X) end end)
    end

    local function CrCP(par, yO, lTxt, defC, cb)
        local CL = Instance.new("TextLabel", par)
        CL.Size = UDim2.new(0.6, 0, 0, 20); CL.Position = UDim2.new(0, 12, 0, yO + 4)
        CL.BackgroundTransparency = 1; CL.Text = lTxt; CL.TextColor3 = TXT; CL.TextSize = 12
        CL.Font = Enum.Font.GothamBold; CL.TextXAlignment = Enum.TextXAlignment.Left; CL.ZIndex = 31

        local PH = Instance.new("Frame", par)
        PH.Size = UDim2.new(1, -24, 0, 28); PH.Position = UDim2.new(0, 12, 0, yO + 26)
        PH.BackgroundTransparency = 1; PH.ZIndex = 31
        local LY2 = Instance.new("UIListLayout", PH)
        LY2.FillDirection = Enum.FillDirection.Horizontal; LY2.Padding = UDim.new(0, 4); LY2.SortOrder = Enum.SortOrder.LayoutOrder

        local CLRS = {
            Color3.fromRGB(255,60,90), Color3.fromRGB(255,170,0), Color3.fromRGB(80,255,140),
            Color3.fromRGB(0,170,255), Color3.fromRGB(180,40,255), Color3.fromRGB(255,255,255),
        }
        local CBs = {}
        for _, c in ipairs(CLRS) do
            local cbtn = Instance.new("TextButton", PH)
            cbtn.Size = UDim2.new(0, 28, 0, 28); cbtn.BackgroundColor3 = c; cbtn.Text = ""
            cbtn.BorderSizePixel = 0; cbtn.ZIndex = 32; cbtn.AutoButtonColor = false
            Instance.new("UICorner", cbtn).CornerRadius = UDim.new(1, 0)
            local CSt = Instance.new("UIStroke", cbtn)
            CSt.Color = Color3.new(1,1,1); CSt.Thickness = 2; CSt.Transparency = 0.7
            CBs[#CBs+1] = {btn=cbtn, color=c, stroke=CSt}
            cbtn.MouseButton1Click:connect(function()
                if cb then cb(c) end
                for _, o in ipairs(CBs) do o.stroke.Transparency = 0.7 end
                CSt.Transparency = 0
            end)
        end
        local function SetC(col)
            for _, o in ipairs(CBs) do
                if (o.color.R-col.R)^2 + (o.color.G-col.G)^2 + (o.color.B-col.B)^2 < 0.001 then
                    o.stroke.Transparency = 0
                else o.stroke.Transparency = 0.7 end
            end
        end
        if lTxt then RegColor(lTxt, SetC) end
    end

    local CO = Instance.new("Frame", MF)
    CO.Size = UDim2.new(1, 0, 1, 0); CO.BackgroundColor3 = BGD; CO.BackgroundTransparency = 0.05
    CO.BorderSizePixel = 0; CO.Visible = false; CO.ZIndex = 50
    Instance.new("UICorner", CO).CornerRadius = UDim.new(0, 18)

    local CT2 = Instance.new("TextLabel", CO)
    CT2.Size = UDim2.new(1, 0, 0, 50); CT2.BackgroundTransparency = 1; CT2.Text = "КОНФИГИ"
    CT2.TextColor3 = TXT; CT2.TextSize = 16; CT2.Font = Enum.Font.GothamBold; CT2.ZIndex = 51

    local CBB = Instance.new("TextButton", CO)
    CBB.Size = UDim2.new(0, 32, 0, 32); CBB.Position = UDim2.new(0, 14, 0, 9)
    CBB.Text = "<"; CBB.TextColor3 = Color3.fromRGB(200,200,220); CBB.TextSize = 16
    CBB.Font = Enum.Font.GothamBold; CBB.BackgroundColor3 = Color3.fromRGB(35,35,55)
    CBB.BorderSizePixel = 0; CBB.ZIndex = 52; CBB.AutoButtonColor = false
    Instance.new("UICorner", CBB).CornerRadius = UDim.new(0, 8)
    CBB.MouseButton1Click:connect(function() CO.Visible = false end)

    local CNB = Instance.new("TextBox", CO)
    CNB.Size = UDim2.new(1, -130, 0, 36); CNB.Position = UDim2.new(0, 14, 0, 60)
    CNB.BackgroundColor3 = BGL; CNB.BorderSizePixel = 0; CNB.Text = ""
    CNB.PlaceholderText = "Название конфига..."; CNB.PlaceholderColor3 = TXD
    CNB.TextColor3 = TXT; CNB.TextSize = 13; CNB.Font = Enum.Font.GothamBold; CNB.ZIndex = 52
    CNB.ClearTextOnFocus = false
    Instance.new("UICorner", CNB).CornerRadius = UDim.new(0, 8)

    local CSB = Instance.new("TextButton", CO)
    CSB.Size = UDim2.new(0, 100, 0, 36); CSB.Position = UDim2.new(1, -114, 0, 60)
    CSB.Text = "Сохранить"; CSB.TextColor3 = Color3.new(1,1,1); CSB.TextSize = 12
    CSB.Font = Enum.Font.GothamBold; CSB.BackgroundColor3 = Color3.fromRGB(40,180,100)
    CSB.BorderSizePixel = 0; CSB.ZIndex = 52; CSB.AutoButtonColor = false
    Instance.new("UICorner", CSB).CornerRadius = UDim.new(0, 8)

    local CLst = Instance.new("ScrollingFrame", CO)
    CLst.Size = UDim2.new(1, -28, 1, -170); CLst.Position = UDim2.new(0, 14, 0, 110)
    CLst.BackgroundColor3 = BGM; CLst.BackgroundTransparency = 0.5; CLst.BorderSizePixel = 0
    CLst.ScrollBarThickness = 4; CLst.ScrollBarImageColor3 = AC
    CLst.CanvasSize = UDim2.new(0, 0, 0, 0); CLst.AutomaticCanvasSize = Enum.AutomaticSize.Y
    CLst.ScrollingDirection = Enum.ScrollingDirection.Y; CLst.ZIndex = 52
    Instance.new("UICorner", CLst).CornerRadius = UDim.new(0, 10)
    local CLL = Instance.new("UIListLayout", CLst)
    CLL.SortOrder = Enum.SortOrder.LayoutOrder; CLL.Padding = UDim.new(0, 6)
    local CLP = Instance.new("UIPadding", CLst)
    CLP.PaddingTop = UDim.new(0, 6); CLP.PaddingLeft = UDim.new(0, 6)
    CLP.PaddingRight = UDim.new(0, 6); CLP.PaddingBottom = UDim.new(0, 6)

    local function RefCL()
        for _, ch in ipairs(CLst:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end
        local has = false
        for n, _ in pairs(Cfgs) do
            has = true
            local it = Instance.new("Frame", CLst)
            it.Size = UDim2.new(1, 0, 0, 40)
            it.BackgroundColor3 = n == CurCfg and Color3.fromRGB(50,30,45) or BGL
            it.BorderSizePixel = 0; it.ZIndex = 53
            Instance.new("UICorner", it).CornerRadius = UDim.new(0, 8)
            local iS = Instance.new("UIStroke", it)
            iS.Color = n == CurCfg and AC or Color3.fromRGB(60,60,90)
            iS.Thickness = 1; iS.Transparency = n == CurCfg and 0 or 0.5
            local iN = Instance.new("TextLabel", it)
            iN.Size = UDim2.new(1, -140, 1, 0); iN.Position = UDim2.new(0, 12, 0, 0)
            iN.BackgroundTransparency = 1; iN.Text = (n == CurCfg and "> " or "") .. n
            iN.TextColor3 = n == CurCfg and AC or TXT; iN.TextSize = 13
            iN.Font = Enum.Font.GothamBold; iN.TextXAlignment = Enum.TextXAlignment.Left; iN.ZIndex = 54
            local LBtn = Instance.new("TextButton", it)
            LBtn.Size = UDim2.new(0, 60, 0, 26); LBtn.Position = UDim2.new(1, -128, 0.5, -13)
            LBtn.Text = "Загрузить"; LBtn.TextColor3 = Color3.new(1,1,1); LBtn.TextSize = 11
            LBtn.Font = Enum.Font.GothamBold; LBtn.BackgroundColor3 = Color3.fromRGB(40,120,200)
            LBtn.BorderSizePixel = 0; LBtn.ZIndex = 54; LBtn.AutoButtonColor = false
            Instance.new("UICorner", LBtn).CornerRadius = UDim.new(0, 6)
            LBtn.MouseButton1Click:connect(function() LdCfg(n); RefCL() end)
            local DBtn = Instance.new("TextButton", it)
            DBtn.Size = UDim2.new(0, 26, 0, 26); DBtn.Position = UDim2.new(1, -34, 0.5, -13)
            DBtn.Text = "X"; DBtn.TextColor3 = Color3.new(1,1,1); DBtn.TextSize = 14
            DBtn.Font = Enum.Font.GothamBold; DBtn.BackgroundColor3 = Color3.fromRGB(180,30,50)
            DBtn.BorderSizePixel = 0; DBtn.ZIndex = 54; DBtn.AutoButtonColor = false
            Instance.new("UICorner", DBtn).CornerRadius = UDim.new(0, 6)
            DBtn.MouseButton1Click:connect(function() DlCfg(n); RefCL() end)
        end
        if not has then
            local EL = Instance.new("TextLabel", CLst)
            EL.Size = UDim2.new(1, 0, 0, 40); EL.BackgroundTransparency = 1
            EL.Text = "Нет конфигов. Создай первый!"; EL.TextColor3 = TXD; EL.TextSize = 12
            EL.Font = Enum.Font.GothamBold; EL.ZIndex = 53
        end
    end
    CSB.MouseButton1Click:connect(function()
        local n = CNB.Text
        if n and n ~= "" then SvCfg(n); CNB.Text = ""; RefCL() end
    end)

    -- TOGGLES
    CrTg("Fly", "✈️", "Fly", function() return S.Fly end, function(v) S.Fly = v end,
        function() if S.Fly then EnFly() else DisFly() end end,
        function(p) CrSl(p, 0, "Скорость полёта", 10, 500, S.FlySpd, function(v) S.FlySpd = v end); return 60 end)

    CrTg("Hitbox", "🎯", "HB", function() return S.HB end, function(v) S.HB = v end,
        function() if S.HB then EnHB() else DisHB() end end,
        function(p)
            CrSl(p, 0, "Размер хитбокса", 5, 200, S.HBSize, function(v) UpHBSz(v) end)
            CrCP(p, 62, "Цвет хитбокса", S.HBCol, function(c) UpHBCol(c) end)
            CrSl(p, 124, "Прозрачность (%)", 0, 100, math.floor(S.HBTrans*100), function(v) UpHBTr(v) end)
            return 184
        end)

    CrTg("SpeedHack", "⚡", "Spd", function() return S.Spd end, function(v) S.Spd = v end,
        function() if S.Spd then ApSpd() else RsSpd() end end,
        function(p) CrSl(p, 0, "Скорость бега", 16, 500, S.SpdVal, function(v) UpSpdV(v) end); return 60 end)

    CrTg("ESP", "🔷", "ESP", function() return S.ESP end, function(v) S.ESP = v end,
        function() if S.ESP then EnESP() else DisESP() end end,
        function(p)
            CrCP(p, 0, "Цвет ESP", S.ESPCol, function(c) UpESPCol(c) end)
            CrSl(p, 62, "Заливка (%)", 0, 100, math.floor(S.ESPFill*100), function(v) UpESPFill(v) end)
            return 122
        end)

    CrTg("Infinite Jump", "🦘", "InfJump", function() return S.InfJump end, function(v) S.InfJump = v end, nil, nil)

    CrTg("Spider", "🕷️", "Spider", function() return S.Spider end, function(v) S.Spider = v end,
        function() if S.Spider then EnSpider() else DisSpider() end end,
        function(p) CrSl(p, 0, "Скорость лазания", 10, 100, S.SpiderSpd, function(v) S.SpiderSpd = v end); return 60 end)

    CrTg("Invisible", "👻", "Invis", function() return S.Invis end, function(v) S.Invis = v end,
        function()
            if S.Invis then task.spawn(GoInvisible) else TurnVisible() end
        end, nil)

    CrTg("Click TP", "🖱️", "ClickTP", function() return S.ClickTP end, function(v) S.ClickTP = v end,
        function() if S.ClickTP then StartClickTP() else StopClickTP() end end,
        function(p)
            local BL = Instance.new("TextLabel", p)
            BL.Size = UDim2.new(0.6, 0, 0, 20); BL.Position = UDim2.new(0, 12, 0, 4)
            BL.BackgroundTransparency = 1; BL.Text = "Бинд на ТП"; BL.TextColor3 = TXT
            BL.TextSize = 12; BL.Font = Enum.Font.GothamBold
            BL.TextXAlignment = Enum.TextXAlignment.Left; BL.ZIndex = 31

            local bBtn = Instance.new("TextButton", p)
            bBtn.Size = UDim2.new(0, 100, 0, 26); bBtn.Position = UDim2.new(1, -112, 0, 2)
            bBtn.Text = S.ClickTPBind and GetBN(S.ClickTPBind) or "—"
            bBtn.TextColor3 = S.ClickTPBind and AC or TXD
            bBtn.TextSize = 12; bBtn.Font = Enum.Font.GothamBold
            bBtn.BackgroundColor3 = BGL; bBtn.BorderSizePixel = 0
            bBtn.ZIndex = 31; bBtn.AutoButtonColor = false
            Instance.new("UICorner", bBtn).CornerRadius = UDim.new(0, 6)

            local bMode = false
            bBtn.MouseButton1Click:Connect(function()
                bMode = not bMode
                bBtn.Text = bMode and "..." or (S.ClickTPBind and GetBN(S.ClickTPBind) or "—")
                bBtn.TextColor3 = bMode and Color3.fromRGB(80,255,140) or (S.ClickTPBind and AC or TXD)
            end)

            local bConn = UIS.InputBegan:Connect(function(input, gp)
                if not bMode then return end
                if gp and input.UserInputType == Enum.UserInputType.Keyboard then return end
                if input.KeyCode == Enum.KeyCode.Backspace then
                    S.ClickTPBind = nil
                    bBtn.Text = "—"; bBtn.TextColor3 = TXD; bMode = false
                    if KB_Refresh then KB_Refresh() end
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseWheel
                or input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    S.ClickTPBind = input.UserInputType
                    bBtn.Text = GetBN(input.UserInputType); bBtn.TextColor3 = AC; bMode = false
                    if KB_Refresh then KB_Refresh() end
                    return
                end
                if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                    S.ClickTPBind = input.KeyCode
                    bBtn.Text = GetBN(input.KeyCode); bBtn.TextColor3 = AC; bMode = false
                    if KB_Refresh then KB_Refresh() end
                end
            end)
            table.insert(Conns, bConn)
            return 50
        end)

    CrTg("TP Players", "🧭", "TPPlayers", function() return S.TPPlayers end, function(v) S.TPPlayers = v end, nil,
        function(p)
            local title = Instance.new("TextLabel", p)
            title.Size = UDim2.new(1, -24, 0, 18); title.Position = UDim2.new(0, 12, 0, 4)
            title.BackgroundTransparency = 1; title.Text = "Выбери игрока:"
            title.TextColor3 = TXT; title.TextSize = 11; title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = 31

            local rBtn = Instance.new("TextButton", p)
            rBtn.Size = UDim2.new(0, 70, 0, 22); rBtn.Position = UDim2.new(1, -82, 0, 2)
            rBtn.Text = "Обновить"; rBtn.TextColor3 = Color3.new(1,1,1); rBtn.TextSize = 11
            rBtn.Font = Enum.Font.GothamBold; rBtn.BackgroundColor3 = Color3.fromRGB(40,120,200)
            rBtn.BorderSizePixel = 0; rBtn.ZIndex = 31; rBtn.AutoButtonColor = false
            Instance.new("UICorner", rBtn).CornerRadius = UDim.new(0, 6)

            local curLbl = Instance.new("TextLabel", p)
            curLbl.Size = UDim2.new(1, -24, 0, 16); curLbl.Position = UDim2.new(0, 12, 0, 26)
            curLbl.BackgroundTransparency = 1
            curLbl.Text = "Выбран: " .. (S.SelectedPlayer or "никто")
            curLbl.TextColor3 = AC; curLbl.TextSize = 11; curLbl.Font = Enum.Font.GothamBold
            curLbl.TextXAlignment = Enum.TextXAlignment.Left; curLbl.ZIndex = 31

            local listFrame = Instance.new("ScrollingFrame", p)
            listFrame.Size = UDim2.new(1, -24, 0, 130); listFrame.Position = UDim2.new(0, 12, 0, 48)
            listFrame.BackgroundColor3 = BGM; listFrame.BackgroundTransparency = 0.4
            listFrame.BorderSizePixel = 0; listFrame.ScrollBarThickness = 4
            listFrame.ScrollBarImageColor3 = AC
            listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            listFrame.ScrollingDirection = Enum.ScrollingDirection.Y; listFrame.ZIndex = 31
            Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
            local ll = Instance.new("UIListLayout", listFrame)
            ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 4)
            local lp = Instance.new("UIPadding", listFrame)
            lp.PaddingTop = UDim.new(0, 4); lp.PaddingLeft = UDim.new(0, 4)
            lp.PaddingRight = UDim.new(0, 4); lp.PaddingBottom = UDim.new(0, 4)

            local function BuildList()
                for _, ch in ipairs(listFrame:GetChildren()) do
                    if ch:IsA("Frame") or ch:IsA("TextLabel") or ch:IsA("TextButton") then ch:Destroy() end
                end
                local players = GetAlivePlayers()
                if #players == 0 then
                    local e = Instance.new("TextLabel", listFrame)
                    e.Size = UDim2.new(1, 0, 0, 24); e.BackgroundTransparency = 1
                    e.Text = "Нет игроков"; e.TextColor3 = TXD; e.TextSize = 11
                    e.Font = Enum.Font.GothamBold; e.ZIndex = 32
                    return
                end
                for _, plr in ipairs(players) do
                    local row = Instance.new("Frame", listFrame)
                    row.Size = UDim2.new(1, 0, 0, 26)
                    row.BackgroundColor3 = (S.SelectedPlayer == plr.Name) and Color3.fromRGB(60,140,90) or BGL
                    row.BorderSizePixel = 0; row.ZIndex = 32
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

                    local nm = Instance.new("TextLabel", row)
                    nm.Size = UDim2.new(1, -80, 1, 0); nm.Position = UDim2.new(0, 8, 0, 0)
                    nm.BackgroundTransparency = 1; nm.Text = plr.Name
                    nm.TextColor3 = TXT; nm.TextSize = 11; nm.Font = Enum.Font.GothamBold
                    nm.TextXAlignment = Enum.TextXAlignment.Left; nm.ZIndex = 33

                    local tpB = Instance.new("TextButton", row)
                    tpB.Size = UDim2.new(0, 60, 0, 20); tpB.Position = UDim2.new(1, -66, 0.5, -10)
                    tpB.Text = "TP"; tpB.TextColor3 = Color3.new(1,1,1); tpB.TextSize = 11
                    tpB.Font = Enum.Font.GothamBold; tpB.BackgroundColor3 = Color3.fromRGB(40,120,200)
                    tpB.BorderSizePixel = 0; tpB.ZIndex = 33; tpB.AutoButtonColor = false
                    Instance.new("UICorner", tpB).CornerRadius = UDim.new(0, 6)
                    tpB.MouseButton1Click:Connect(function()
                        TeleportToPlayer(plr)
                        S.SelectedPlayer = plr.Name
                        curLbl.Text = "Выбран: " .. plr.Name
                        BuildList()
                    end)
                end
            end

            rBtn.MouseButton1Click:Connect(BuildList)
            BuildList()

            local updConn
            updConn = RS.Heartbeat:Connect(function()
                if not p.Parent or not p.Visible then
                    if updConn then updConn:Disconnect() end
                    return
                end
                if tick() - (p:GetAttribute("LastTPRefresh") or 0) >= 2 then
                    p:SetAttribute("LastTPRefresh", tick())
                    BuildList()
                end
            end)
            table.insert(Conns, updConn)
            return 190
        end)

    CrTg("Team Check", "👥", "TeamCheck", function() return S.TeamCheck end, function(v) S.TeamCheck = v end,
        function() if S.ESP then DisESP() EnESP() end; if S.HB then DisHB() EnHB() end end, nil)

    CrTg("Graphics", "🎨", "Graphics", function() return S.Graphics end, function(v) S.Graphics = v end,
        function() ApplyGraphics() end,
        function(p)
            CrSl(p, 0, "Интенсивность (%)", 0, 100, S.GfxIntensity, function(v) UpGfxIntensity(v) end)
            CrSl(p, 62, "Яркость (%)", 0, 100, S.GfxBrightness, function(v) UpGfxBrightness(v) end)
            CrSl(p, 124, "Контрастность (%)", 0, 100, S.GfxContrast, function(v) UpGfxContrast(v) end)
            CrSl(p, 186, "Насыщенность (%)", 0, 100, S.GfxSaturation, function(v) UpGfxSaturation(v) end)
            return 246
        end)

    CrTg("World Color", "🌈", "WorldColor", function() return S.WorldColor end, function(v) S.WorldColor = v end,
        function() ApplyWorldColor() end,
        function(p)
            CrCP(p, 0, "Цвет мира", S.WorldColorValue, function(c) SetWorldColor(c) end)
            return 62
        end)

    CrTg("Keybinds HUD", "⌨️", nil, function() return S.KeybindsHUD end, function(v) S.KeybindsHUD = v end,
        function() if KB_Refresh then KB_Refresh() end end, nil)

    local CFB = Instance.new("TextButton", CT)
    CFB.Size = UDim2.new(1, -4, 0, 42); CFB.Text = "CONFIGS"
    CFB.TextColor3 = Color3.new(1,1,1); CFB.TextSize = 13; CFB.Font = Enum.Font.GothamBold
    CFB.BackgroundColor3 = Color3.fromRGB(60,60,120); CFB.BorderSizePixel = 0
    CFB.ZIndex = 21; CFB.AutoButtonColor = false; CFB.LayoutOrder = NxO()
    Instance.new("UICorner", CFB).CornerRadius = UDim.new(0, 10)
    local CFG = Instance.new("UIGradient", CFB)
    CFG.Rotation = 90
    CFG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(80,60,180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(40,40,100))})
    CFB.MouseButton1Click:connect(function() CO.Visible = true; RefCL() end)

    local UB = Instance.new("TextButton", CT)
    UB.Size = UDim2.new(1, -4, 0, 42); UB.Text = "UNLOAD CHEAT"
    UB.TextColor3 = Color3.new(1,1,1); UB.TextSize = 13; UB.Font = Enum.Font.GothamBold
    UB.BackgroundColor3 = Color3.fromRGB(180,30,50); UB.BorderSizePixel = 0
    UB.ZIndex = 21; UB.AutoButtonColor = false; UB.LayoutOrder = NxO()
    Instance.new("UICorner", UB).CornerRadius = UDim.new(0, 10)
    local UG = Instance.new("UIGradient", UB)
    UG.Rotation = 90
    UG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(220,40,70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,20,50))})
    UB.MouseButton1Click:connect(function()
        DisFly(); DisESP(); DisHB(); DisSpider(); RsSpd()
        if invisRunning then pcall(TurnVisible) end
        pcall(StopClickTP)
        S.Graphics = false; S.GfxIntensity = 0
        ApplyGraphics()
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local oc = obj:GetAttribute("ZeninOrigColor")
                    if oc then obj.Color = oc end
                end
            end
        end)
        pcall(RestoreWorldColorState)
        if WorldColorSky then WorldColorSky:Destroy() end
        if WorldColorAtmos then WorldColorAtmos:Destroy() end
        for _, c in ipairs(Conns) do if c then c:Disconnect() end end
        SG:Destroy(); _G.ZeninCheat = false
    end)

    local OB = Instance.new("TextButton", SG)
    OB.Size = UDim2.new(0, 55, 0, 55); OB.Position = UDim2.new(1, -70, 1, -80)
    OB.Text = "Z"; OB.TextColor3 = Color3.fromRGB(255,60,60); OB.TextSize = 32
    OB.Font = Enum.Font.GothamBold; OB.BackgroundColor3 = Color3.fromRGB(15,15,25)
    OB.BorderSizePixel = 2; OB.BorderColor3 = Color3.fromRGB(255,60,60); OB.ZIndex = 100
    Instance.new("UICorner", OB).CornerRadius = UDim.new(1, 0)
    OB.MouseButton1Click:connect(function()
        if not MF.Visible then
            MF.Visible = true; MF.Size = UDim2.new(0, 420, 0, 0)
            TS:Create(MF, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 620)}):Play()
        else
            TS:Create(MF, TweenInfo.new(0.2), {Size = UDim2.new(0, 420, 0, 0)}):Play()
            task.wait(0.2); MF.Visible = false; MF.Size = UDim2.new(0, 420, 0, 620)
        end
    end)

    -- WATERMARK
    local WM = Instance.new("TextButton", SG)
    WM.Size = UDim2.new(0, 200, 0, 34); WM.BackgroundColor3 = BGD
    WM.BorderSizePixel = 0; WM.Text = ""; WM.AutoButtonColor = false; WM.Active = true
    WM.ZIndex = 300
    WM.Position = UDim2.new(0, WMPos.X or 20, 0, WMPos.Y or 20)
    Instance.new("UICorner", WM).CornerRadius = UDim.new(0, 10)
    local WMS = Instance.new("UIStroke", WM)
    WMS.Color = AC; WMS.Thickness = 1.5; WMS.Transparency = 0.3
    local WMG = Instance.new("UIGradient", WM); WMG.Rotation = 90
    WMG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22,16,34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12,12,22)),
    })
    local WMIcon = Instance.new("Frame", WM)
    WMIcon.Size = UDim2.new(0, 22, 0, 22); WMIcon.Position = UDim2.new(0, 8, 0.5, -11)
    WMIcon.BackgroundColor3 = AC; WMIcon.BorderSizePixel = 0; WMIcon.ZIndex = 302
    Instance.new("UICorner", WMIcon).CornerRadius = UDim.new(0, 6)
    local WMIconG = Instance.new("UIGradient", WMIcon); WMIconG.Rotation = 45
    WMIconG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, AC), ColorSequenceKeypoint.new(1, AC2)})
    local WMIconT = Instance.new("TextLabel", WMIcon)
    WMIconT.Size = UDim2.new(1, 0, 1, 0); WMIconT.BackgroundTransparency = 1
    WMIconT.Text = "Z"; WMIconT.TextColor3 = Color3.new(1,1,1); WMIconT.TextSize = 14
    WMIconT.Font = Enum.Font.GothamBold; WMIconT.ZIndex = 303
    local WMText = Instance.new("TextLabel", WM)
    WMText.Size = UDim2.new(0, 140, 1, 0); WMText.Position = UDim2.new(0, 36, 0, 0)
    WMText.BackgroundTransparency = 1; WMText.Text = "ZENIN | -- FPS | --:--:--"
    WMText.TextColor3 = TXT; WMText.TextSize = 12; WMText.Font = Enum.Font.GothamBold
    WMText.TextXAlignment = Enum.TextXAlignment.Left; WMText.ZIndex = 302
    local WMDot = Instance.new("Frame", WM)
    WMDot.Size = UDim2.new(0, 7, 0, 7); WMDot.Position = UDim2.new(1, -16, 0.5, -3.5)
    WMDot.BackgroundColor3 = Color3.fromRGB(80,255,140); WMDot.BorderSizePixel = 0; WMDot.ZIndex = 302
    Instance.new("UICorner", WMDot).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        local on = true
        while WM.Parent do
            TS:Create(WMDot, TweenInfo.new(0.6), {BackgroundTransparency = on and 0.6 or 0}):Play()
            on = not on
            task.wait(0.6)
        end
    end)

    local fpsValue = 0
    local mskTime = "--:--:--"

    task.spawn(function()
        local frames, last = 0, tick()
        while WM.Parent do
            frames = frames + 1
            local now = tick()
            if now - last >= 1 then fpsValue = frames; frames = 0; last = now end
            RS.RenderStepped:Wait()
        end
    end)

    task.spawn(function()
        while WM.Parent do
            local ok, t = pcall(function() return os.date("!%H:%M:%S", os.time() + 3 * 3600) end)
            if ok and t then mskTime = t end
            task.wait(1)
        end
    end)

    task.spawn(function()
        while WM.Parent do
            WMText.Text = "ZENIN | " .. fpsValue .. " FPS | " .. mskTime
            task.wait(1)
        end
    end)

    local wmDragging = false
    local wmDragStart, wmStartPos
    WM.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wmDragging = true; wmDragStart = input.Position; wmStartPos = WM.Position
        end
    end)
    WM.InputChanged:Connect(function(input)
        if wmDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - wmDragStart
            WM.Position = UDim2.new(wmStartPos.X.Scale, wmStartPos.X.Offset + delta.X, wmStartPos.Y.Scale, wmStartPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if wmDragging then wmDragging = false; SaveWMPos({ X = WM.Position.X.Offset, Y = WM.Position.Y.Offset }) end
        end
    end)
    WM.MouseEnter:Connect(function() TS:Create(WMS, TweenInfo.new(0.15), {Transparency = 0, Thickness = 2}):Play() end)
    WM.MouseLeave:Connect(function() if not wmDragging then TS:Create(WMS, TweenInfo.new(0.15), {Transparency = 0.3, Thickness = 1.5}):Play() end end)

    -- KEYBINDS HUD
    local KB = Instance.new("Frame", SG)
    KB.Name = "KeybindsHUD"
    KB.Size = UDim2.new(0, 220, 0, 40)
    KB.Position = UDim2.new(0, KBPos.X or 20, 0, KBPos.Y or 70)
    KB.BackgroundColor3 = BGD; KB.BorderSizePixel = 0
    KB.ZIndex = 250; KB.Visible = S.KeybindsHUD; KB.Active = true
    Instance.new("UICorner", KB).CornerRadius = UDim.new(0, 10)
    local KBG = Instance.new("UIGradient", KB); KBG.Rotation = 90
    KBG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 22)),
    })
    local KBTitle = Instance.new("TextLabel", KB)
    KBTitle.Size = UDim2.new(1, -30, 0, 22); KBTitle.Position = UDim2.new(0, 12, 0, 6)
    KBTitle.BackgroundTransparency = 1; KBTitle.Text = "KEYBINDS"
    KBTitle.TextColor3 = TXT; KBTitle.TextSize = 12; KBTitle.Font = Enum.Font.GothamBold
    KBTitle.TextXAlignment = Enum.TextXAlignment.Left; KBTitle.ZIndex = 252
    local KBDot = Instance.new("Frame", KB)
    KBDot.Size = UDim2.new(0, 7, 0, 7); KBDot.Position = UDim2.new(1, -16, 0, 13.5)
    KBDot.BackgroundColor3 = Color3.fromRGB(80, 255, 140); KBDot.BorderSizePixel = 0; KBDot.ZIndex = 252
    Instance.new("UICorner", KBDot).CornerRadius = UDim.new(1, 0)
    task.spawn(function()
        local on = true
        while KBDot.Parent do
            TS:Create(KBDot, TweenInfo.new(0.6), {BackgroundTransparency = on and 0.6 or 0}):Play()
            on = not on; task.wait(0.6)
        end
    end)

    local KBList = Instance.new("Frame", KB)
    KBList.Size = UDim2.new(1, -24, 1, -36); KBList.Position = UDim2.new(0, 12, 0, 32)
    KBList.BackgroundTransparency = 1; KBList.ZIndex = 251
    local KBLY = Instance.new("UIListLayout", KBList)
    KBLY.SortOrder = Enum.SortOrder.LayoutOrder; KBLY.Padding = UDim.new(0, 3)

    local KB_Rows = {}
    local KB_FlashTimers = {}

    local function KB_Clear()
        for _, data in pairs(KB_Rows) do
            if data and data.row and data.row.Parent then data.row:Destroy() end
        end
        KB_Rows = {}; KB_FlashTimers = {}
        for _, ch in ipairs(KBList:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end
    end

    local function KB_MakeRow(name, bind, isActive, bindKey, uniqueId)
        local row = Instance.new("Frame", KBList)
        row.Size = UDim2.new(1, 0, 0, 18)
        row.BackgroundTransparency = isActive and 0.8 or 1
        row.BackgroundColor3 = isActive and Color3.fromRGB(80, 255, 140) or BGD
        row.ZIndex = 252
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local dot = Instance.new("Frame", row)
        dot.Size = UDim2.new(0, 6, 0, 6); dot.Position = UDim2.new(0, 3, 0.5, -3)
        dot.BackgroundColor3 = isActive and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(90, 90, 110)
        dot.BorderSizePixel = 0; dot.ZIndex = 253
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local nl = Instance.new("TextLabel", row)
        nl.Size = UDim2.new(0.6, 0, 1, 0); nl.Position = UDim2.new(0, 14, 0, 0)
        nl.BackgroundTransparency = 1; nl.Text = name
        nl.TextColor3 = isActive and Color3.fromRGB(180, 255, 200) or TXT
        nl.TextSize = 11; nl.Font = Enum.Font.GothamBold
        nl.TextXAlignment = Enum.TextXAlignment.Left; nl.ZIndex = 253
        local bl = Instance.new("TextLabel", row)
        bl.Size = UDim2.new(0.35, 0, 1, 0); bl.Position = UDim2.new(0.62, 0, 0, 0)
        bl.BackgroundTransparency = 1; bl.Text = bind
        bl.TextColor3 = isActive and Color3.fromRGB(80, 255, 140) or AC
        bl.TextSize = 11; bl.Font = Enum.Font.GothamBold
        bl.TextXAlignment = Enum.TextXAlignment.Right; bl.ZIndex = 253
        KB_Rows[uniqueId or bindKey or name] = {row = row, dot = dot, nameLabel = nl, bindLabel = bl, isActive = isActive, bindKey = bindKey}
        return row
    end

    local function KB_Resize()
        local count = 0
        for _ in pairs(KB_Rows) do count = count + 1 end
        KB.Size = UDim2.new(0, 220, 0, math.max(40, 34 + count * 21 + 4))
    end

    KB_Refresh = function()
        if not KB or not KB.Parent then return end
        KB_Clear()
        local entries = {}
        if B.Fly then entries[#entries+1] = {"Fly", GetBN(B.Fly), "Fly"} end
        if B.HB then entries[#entries+1] = {"Hitbox", GetBN(B.HB), "HB"} end
        if B.ESP then entries[#entries+1] = {"ESP", GetBN(B.ESP), "ESP"} end
        if B.InfJump then entries[#entries+1] = {"Infinite Jump", GetBN(B.InfJump), "InfJump"} end
        if B.TeamCheck then entries[#entries+1] = {"Team Check", GetBN(B.TeamCheck), "TeamCheck"} end
        if B.Spd then entries[#entries+1] = {"SpeedHack", GetBN(B.Spd), "Spd"} end
        if B.Graphics then entries[#entries+1] = {"Graphics", GetBN(B.Graphics), "Graphics"} end
        if B.Spider then entries[#entries+1] = {"Spider", GetBN(B.Spider), "Spider"} end
        if B.Invis then entries[#entries+1] = {"Invisible", GetBN(B.Invis), "Invis"} end
        if B.ClickTP then entries[#entries+1] = {"Click TP", GetBN(B.ClickTP), "ClickTP"} end
        if B.WorldColor then entries[#entries+1] = {"World Color", GetBN(B.WorldColor), "WorldColor"} end
        if B.TPPlayers then entries[#entries+1] = {"TP Players", GetBN(B.TPPlayers), "TPPlayers"} end
        if #entries == 0 then
            local row = Instance.new("Frame", KBList)
            row.Size = UDim2.new(1, 0, 0, 18); row.BackgroundTransparency = 1; row.ZIndex = 252
            local dot = Instance.new("Frame", row)
            dot.Size = UDim2.new(0, 6, 0, 6); dot.Position = UDim2.new(0, 3, 0.5, -3)
            dot.BackgroundColor3 = Color3.fromRGB(90, 90, 110); dot.BorderSizePixel = 0; dot.ZIndex = 253
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            local nl = Instance.new("TextLabel", row)
            nl.Size = UDim2.new(1, -14, 1, 0); nl.Position = UDim2.new(0, 14, 0, 0)
            nl.BackgroundTransparency = 1; nl.Text = "Нет биндов"
            nl.TextColor3 = TXD; nl.TextSize = 11; nl.Font = Enum.Font.GothamBold
            nl.TextXAlignment = Enum.TextXAlignment.Left; nl.ZIndex = 253
            KB_Rows["__empty__"] = {row = row, dot = dot, nameLabel = nl, bindLabel = nil, isActive = false, bindKey = nil}
        else
            for _, e in ipairs(entries) do
                local active = GetBindToggleState(e[3])
                KB_MakeRow(e[1], e[2], active, e[3], e[3])
            end
        end
        KB.Visible = S.KeybindsHUD
        KB_Resize()
    end

    KB_UpdateStates = function()
        for _, data in pairs(KB_Rows) do
            if data and data.row and data.row.Parent and data.bindKey then
                local active = GetBindToggleState(data.bindKey)
                data.isActive = active
                data.row.BackgroundTransparency = active and 0.8 or 1
                data.row.BackgroundColor3 = active and Color3.fromRGB(80, 255, 140) or BGD
                if data.dot then data.dot.BackgroundColor3 = active and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(90, 90, 110) end
                data.nameLabel.TextColor3 = active and Color3.fromRGB(180, 255, 200) or TXT
                if data.bindLabel then data.bindLabel.TextColor3 = active and Color3.fromRGB(80, 255, 140) or AC end
            end
        end
    end

    KB_Flash = function(bindKey)
        local data = KB_Rows[bindKey]
        if not data or not data.row or not data.row.Parent then return end
        local row = data.row
        if KB_FlashTimers[bindKey] then KB_FlashTimers[bindKey]:Disconnect(); KB_FlashTimers[bindKey] = nil end
        row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        row.BackgroundTransparency = 0.4
        KB_FlashTimers[bindKey] = task.delay(0.15, function()
            if row and row.Parent and KB_UpdateStates then KB_UpdateStates() end
        end)
    end

    local kbDragging = false
    local kbDragStart, kbStartPos
    KB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            kbDragging = true; kbDragStart = input.Position; kbStartPos = KB.Position
        end
    end)
    KB.InputChanged:Connect(function(input)
        if kbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - kbDragStart
            KB.Position = UDim2.new(kbStartPos.X.Scale, kbStartPos.X.Offset + delta.X, kbStartPos.Y.Scale, kbStartPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if kbDragging then kbDragging = false; SaveKBPos({ X = KB.Position.X.Offset, Y = KB.Position.Y.Offset }) end
        end
    end)

    -- LOOPS
    table.insert(Conns, RS.RenderStepped:connect(function()
        if not S.Fly then return end
        local c = LP.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r or not BV then return end
        local d = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0,1,0) end
        BV.Velocity = d.Magnitude > 0 and d.Unit * S.FlySpd or Vector3.new(0,0,0)
        BG.CFrame = Cam.CFrame
    end))

    table.insert(Conns, RS.RenderStepped:connect(function()
        if not S.Spider then
            if SpiderBV then SpiderBV.Velocity = Vector3.new(0, 0, 0) end
            return
        end
        local c = LP.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not r or not h then return end
        if not SpiderBV or SpiderBV.Parent ~= r then EnSpider() end
        if not SpiderBV then return end
        local nearWall, wallNormal = IsNearWall()
        if nearWall and UIS:IsKeyDown(S.SpiderKey) then
            local sideVel = Vector3.new(0, 0, 0)
            if UIS:IsKeyDown(Enum.KeyCode.A) then sideVel = -Cam.CFrame.RightVector
            elseif UIS:IsKeyDown(Enum.KeyCode.D) then sideVel = Cam.CFrame.RightVector end
            local vertBoost = Vector3.new(0, 0, 0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then vertBoost = Vector3.new(0, S.SpiderSpd, 0)
            elseif UIS:IsKeyDown(Enum.KeyCode.S) then vertBoost = Vector3.new(0, -S.SpiderSpd, 0) end
            local pushToWall = -wallNormal * 10
            SpiderBV.Velocity = sideVel * S.SpiderSpd + vertBoost + pushToWall
            pcall(function() h:ChangeState(Enum.HumanoidStateType.Climbing) end)
        else
            SpiderBV.Velocity = Vector3.new(0, 0, 0)
        end
    end))

    table.insert(Conns, RS.Heartbeat:connect(function()
        if not S.Spd then return end
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h and h.WalkSpeed ~= S.SpdVal then h.WalkSpeed = S.SpdVal end
    end))

    table.insert(Conns, RS.RenderStepped:connect(function()
        if not S.ESP then return end
        for _, p in ipairs(P:GetPlayers()) do
            if p ~= LP and p.Character and not isTM(p) then
                if not ESPCache[p] then CrESP(p) end
            else RmESP(p) end
        end
    end))

    table.insert(Conns, RS.RenderStepped:connect(function()
        if not S.HB then return end
        for _, p in ipairs(P:GetPlayers()) do
            if p ~= LP and p.Character and not isTM(p) then
                if not HBCache[p] then CrHB(p) end
            else RmHB(p) end
        end
        for p in pairs(HBCache) do
            if not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 or isTM(p) then RmHB(p) end
        end
    end))

    table.insert(Conns, UIS.JumpRequest:connect(function()
        if S.InfJump then
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState("Jumping") end
        end
    end))

    table.insert(Conns, LP.CharacterAdded:connect(function()
        task.wait(0.5)
        if S.Fly then EnFly() end; if S.ESP then EnESP() end
        if S.HB then EnHB() end; if S.Spd then ApSpd() end
        if S.Spider then EnSpider() end
        if S.Invis and not invisRunning then task.spawn(GoInvisible) end
        if S.WorldColor then ApplyWorldColor() end
    end))

    local rsHeld = false
    table.insert(Conns, UIS.InputBegan:connect(function(i, gp)
        if i.KeyCode == Enum.KeyCode.RightShift then rsHeld = true end
        if gp then return end
        if CNB and CNB:IsFocused() then return end
        if BindMode then
            if i.UserInputType == Enum.UserInputType.MouseWheel then ApBind(Enum.UserInputType.MouseWheel); return end
            if i.KeyCode ~= Enum.KeyCode.Unknown then ApBind(i.KeyCode); return end
        end
        ChkBind(i)
    end))

    table.insert(Conns, UIS.InputEnded:connect(function(i, gp)
        if i.KeyCode == Enum.KeyCode.RightShift and rsHeld then
            rsHeld = false
            if not MF.Visible then
                MF.Visible = true; MF.Size = UDim2.new(0, 420, 0, 0)
                TS:Create(MF, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 620)}):Play()
            else
                TS:Create(MF, TweenInfo.new(0.2), {Size = UDim2.new(0, 420, 0, 0)}):Play()
                task.wait(0.2); MF.Visible = false; MF.Size = UDim2.new(0, 420, 0, 620)
            end
        end
    end))

    EnsureWorldColor()
    KB_Refresh()

    print("[ZENIN] Чит успешно загружен. Ключ: " .. tostring(LoadKey()))
    -- ================== КОНЕЦ ТЕЛА ЧИТА ==================
end

-- ========== ОКНО АКТИВАЦИИ ==========
local function ShowActivation()
    local SG = Instance.new("ScreenGui")
    SG.Name = "ZeninActivation"
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.Parent = LP:WaitForChild("PlayerGui")

    local BG = Instance.new("Frame", SG)
    BG.Size = UDim2.new(0, 400, 0, 280)
    BG.Position = UDim2.new(0.5, -200, 0.5, -140)
    BG.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    BG.BorderSizePixel = 0
    BG.ZIndex = 10
    Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 18)
    local BGS = Instance.new("UIStroke", BG)
    BGS.Color = Color3.fromRGB(255, 60, 90); BGS.Thickness = 1.5

    local Logo = Instance.new("Frame", BG)
    Logo.Size = UDim2.new(0, 50, 0, 50)
    Logo.Position = UDim2.new(0.5, -25, 0, 20)
    Logo.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
    Logo.BorderSizePixel = 0; Logo.ZIndex = 11
    Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 12)
    local LogoG = Instance.new("UIGradient", Logo)
    LogoG.Rotation = 45
    LogoG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 255)),
    })
    local LogoT = Instance.new("TextLabel", Logo)
    LogoT.Size = UDim2.new(1, 0, 1, 0); LogoT.BackgroundTransparency = 1
    LogoT.Text = "Z"; LogoT.TextColor3 = Color3.new(1,1,1); LogoT.TextSize = 30
    LogoT.Font = Enum.Font.GothamBold; LogoT.ZIndex = 12

    local Title = Instance.new("TextLabel", BG)
    Title.Size = UDim2.new(1, 0, 0, 26)
    Title.Position = UDim2.new(0, 0, 0, 78)
    Title.BackgroundTransparency = 1
    Title.Text = "ZENIN | АКТИВАЦИЯ"
    Title.TextColor3 = Color3.fromRGB(235, 235, 245)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold; Title.ZIndex = 11

    local Sub = Instance.new("TextLabel", BG)
    Sub.Size = UDim2.new(1, 0, 0, 18)
    Sub.Position = UDim2.new(0, 0, 0, 104)
    Sub.BackgroundTransparency = 1
    Sub.Text = "Введи ключ для доступа"
    Sub.TextColor3 = Color3.fromRGB(150, 150, 170)
    Sub.TextSize = 12
    Sub.Font = Enum.Font.Gotham; Sub.ZIndex = 11

    local Input = Instance.new("TextBox", BG)
    Input.Size = UDim2.new(1, -40, 0, 42)
    Input.Position = UDim2.new(0, 20, 0, 132)
    Input.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    Input.BorderSizePixel = 0
    Input.Text = ""
    Input.PlaceholderText = "ZENIN-XXXX-XXXX-XXXX"
    Input.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
    Input.TextColor3 = Color3.fromRGB(235, 235, 245)
    Input.TextSize = 13
    Input.Font = Enum.Font.GothamBold
    Input.ClearTextOnFocus = false
    Input.ZIndex = 11
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 8)

    local Status = Instance.new("TextLabel", BG)
    Status.Size = UDim2.new(1, -40, 0, 18)
    Status.Position = UDim2.new(0, 20, 0, 180)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 80, 80)
    Status.TextSize = 11
    Status.Font = Enum.Font.GothamBold
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.ZIndex = 11

    local Btn = Instance.new("TextButton", BG)
    Btn.Size = UDim2.new(1, -40, 0, 42)
    Btn.Position = UDim2.new(0, 20, 0, 210)
    Btn.BackgroundColor3 = Color3.fromRGB(255, 60, 90)
    Btn.BorderSizePixel = 0
    Btn.Text = "АКТИВИРОВАТЬ"
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.TextSize = 14
    Btn.Font = Enum.Font.GothamBold
    Btn.AutoButtonColor = false
    Btn.ZIndex = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    Btn.MouseEnter:Connect(function()
        TS:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 90, 120)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TS:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 60, 90)}):Play()
    end)

    local hwid = getHWID()
    print("[ZENIN] HWID: " .. hwid)

    local busy = false
    local function TryActivate()
        if busy then return end
        local key = Input.Text
        if key == "" then Status.Text = "Введи ключ"; return end
        busy = true
        Status.Text = "Проверка..."
        Status.TextColor3 = Color3.fromRGB(255, 200, 80)
        task.spawn(function()
            local ok, err = CheckKey(key, hwid)
            if ok then
                Status.Text = "Успешно! Запуск..."
                Status.TextColor3 = Color3.fromRGB(80, 255, 140)
                SaveKey(key)
                task.wait(0.6)
                SG:Destroy()
                StartCheat()
            else
                Status.Text = err or "Ошибка"
                Status.TextColor3 = Color3.fromRGB(255, 80, 80)
                busy = false
            end
        end)
    end

    Btn.MouseButton1Click:Connect(TryActivate)
    Input.FocusLost:Connect(function(enter)
        if enter then TryActivate() end
    end)
end

-- ========== ГЛАВНАЯ ЛОГИКА ==========
task.spawn(function()
    local savedKey = LoadKey()
    if savedKey then
        print("[ZENIN] Проверяем сохранённый ключ...")
        local ok, err = CheckKey(savedKey, getHWID())
        if ok then
            print("[ZENIN] Ключ валиден, запускаем чит.")
            StartCheat()
        else
            print("[ZENIN] Ключ невалиден: " .. tostring(err))
            if writefile then pcall(function() writefile(KEY_FILE, "") end) end
            ShowActivation()
        end
    else
        ShowActivation()
    end
end)
