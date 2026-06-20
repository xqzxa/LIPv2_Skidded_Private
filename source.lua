-- sane goated
local IsFilesystemSupported = true
function LdrCheckExecutor()
    if not identifyexecutor then return false end
    local execName, execVersion = identifyexecutor()
    if execName ~= "Volt" then print("[!] Recommended to use Volt for the best experience") end
    if not getgenv or not debug or typeof(debug) ~= "table" or not getconnections or typeof(getconnections) ~= "function" or not cloneref or typeof(cloneref) ~= "function" or not compareinstances or typeof(compareinstances) ~= "function" or not iscclosure or typeof(iscclosure) ~= "function" or not debug.getinfo or typeof(debug.getinfo) ~= "function" or not debug.getconstants or typeof(debug.getconstants) ~= "function" or not debug.getupvalue or typeof(debug.getupvalue) ~= "function" or not debug.getupvalues or typeof(debug.getupvalues) ~= "function" then return false end
    if not readfile or typeof(readfile) ~= "function" or not writefile or typeof(writefile) ~= "function" or not isfolder or typeof(isfolder) ~= "function" or not isfile or typeof(isfile) ~= "function" or not delfile or typeof(delfile) ~= "function" or not makefolder or typeof(makefolder) ~= "function" then
        IsFilesystemSupported = false
    end
    return true
end

if not LdrCheckExecutor() then return end
if getgenv().LIPV2_LOADED then return end

local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local ReplicatedFirst = cloneref(game:GetService("ReplicatedFirst"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Players = cloneref(game:GetService("Players"))
local Teams = cloneref(game:GetService("Teams"))
local HttpService = cloneref(game:GetService("HttpService"))
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat LocalPlayer = Players.LocalPlayer task.wait() until LocalPlayer
end

local BIG_MAGAMMO = 99999999999
local CHEAT_DIR = "LIP_V2"
local Constants = {
    ["CHEAT_DIR"] = "LIP_V2",
    ["GUN_MODS_PRESET_FILE_PATH"] = CHEAT_DIR.."/GunModsPreset.json",
    ["DEFAULT_GUN_MODS_PRESET"] = {
        ["UseDefaultTable"] = true,
        ["DefaultTable"] = { ["MagAmmo"] = BIG_MAGAMMO, ["FireRate"] = 0.0001, ["Spread"] = 0 },
        ["SPAS"] = { ["MagAmmo"] = BIG_MAGAMMO, ["FireRate"] = 0.01, ["Spread"] = 0 },
        ["DB Shotgun"] = { ["MagAmmo"] = 2, ["FireRate"] = 0.01, ["Spread"] = 0 },
        ["Quad Launcher"] = { ["MagAmmo"] = BIG_MAGAMMO, ["FireRate"] = 0.07, ["Spread"] = 0 }
    }
}
table.freeze(Constants)

local MovementSettings = {
    TPWalkEnabled = false,
    TPWalkSpeed = 2,  -- teleport step size per frame (higher = faster)
    FlyJumpEnabled = false,
    CharNoclipEnabled = false
}

-- New LoopSettings table for Spin Loop[cite: 11]
local LoopSettings = {
    SpinEnabled = false,
    SpinTargetName = "",
    SpinDistance = 5,
    SpinHeight = 0,
    SpinSpeed = 1,
    SpinAngle = 0,
    OriginalCFrame = nil  -- stores position before spin started
}

local GameDT = { BClient = nil, DataTable = nil, ActiveCharacterTable = nil, TimeEncode = nil, RemotesTable = nil }
local CheatDT = {
    VehicleAutoCorrectCam = true, MaxCameraZoom = 200, VehicleNoclipEnabled = false, VehicleNoclipPrevParts = {}, VehicleNoclipChecksConn = nil,
    FT = { Value = time(), Step = 1 }, GunModsEnabled = false, GunsModsFilterName = nil, GunModsMagammo = 999, GunModsFirerate = 0.01,
    GunModsAutomatize = true, GunModsSpread = 0, GunModsRemoveNegativeEffects = true, GunModsUsePresetInstead = true, GunModsPreset = nil, AntiTazeEnabled = false
}

local AimSettings = { Enabled = false, Keybind = Enum.KeyCode.Q, TeamCheck = true, WallCheck = true, FOV = 100, Smoothness = 2, AimHead = false }

local ESPSettings = {
    Enabled = false,
    Box = false,
    Health = false,
    Name = false,
    Tracers = false,
}
-- Stores drawing objects per player: { [player] = { Box, Health, Name, Tracer } }
local ESPObjects = {}

local MiscSettings = {
    AntiHeadsit = true,
    AntiFling = true,
    AntiBang = true,
    AntiSit = true,
    AntiSitConnection = nil,
}

-- Single TP state
local SingleTPState = {
    Active = false,
    Target = nil,
    OriginalCFrame = nil,  -- where we were before the TP
}

-- Anti-physics cache for fling/bang detection
local AntiPhysicsCache = { LastCFrame = nil }
local SpecSettings = { Enabled = false, Target = nil, Name = "" }

-- Player join alert watchlist — add/remove UserIDs here
local WatchList = {
    Enabled = false,
    Connection = nil,
    UserIds = {
        [1693103290] = true,  -- silezz
        [7502020457] = true,  -- sweet
        [336061882]  = true,  -- nuget
        [78206284]   = true,  -- deadcandle
        [1389391378] = true,  -- Ampsty1e
        [1215858332] = true,  -- UFO
    }
}
local TPSettings = { ToolActive = false, ActiveTool = nil, Connection = nil }
local TrollSettings = {
    SpinEnabled = false,
    SpinSpeed = 5,
    SpinAngle = 0,
}
local TeamSettings = { BackgroundSavedCFrame = nil, IsSwitching = false }

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false

-- Update FOV circle color to match local player's team color
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    local team = LocalPlayer.Team
    if team then
        FOVCircle.Color = team.TeamColor.Color
    else
        FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    end
end)



local Locations = {
    { Name = "Main Hall", Cords = Vector3.new(104.38, 1075.14, 60.65) },
    { Name = "Cafetaria", Cords = Vector3.new(130.32, 1075.92, -2.81) },
    { Name = "Cell Block", Cords = Vector3.new(106.97, 1073.39, 145.38) },
    { Name = "Yard", Cords = Vector3.new(-54.37, 1075.06, 237.34) },
    { Name = "Armory", Cords = Vector3.new(-37.97, 1083.43, 3.13) },
    { Name = "Prison Roof", Cords = Vector3.new(-9.69, 1119.88, 16.96) },
    { Name = "Front Gate", Cords = Vector3.new(-303.54, 1072.76, -6.10) },
    { Name = "WareHouse (Criminal base 1)", Cords = Vector3.new(-1451.65, 1083.61, 93.37) },
    { Name = "WareHouse Roof", Cords = Vector3.new(-1428.42, 1111.33, 80.17) },
    { Name = "Outpost (Criminal base 2)", Cords = Vector3.new(-650.52, 1054.74, -635.37) },
    { Name = "Outpost Roof", Cords = Vector3.new(-658.18, 1090.99, -634.69) },
    { Name = "Arms Store", Cords = Vector3.new(-1005.82, 1049.43, 170.54) },
    { Name = "Barn", Cords = Vector3.new(-1017.38, 1076.87, 397.64) },
    { Name = "China House thing", Cords = Vector3.new(-994.29, 1084.72, -198.58) },
    { Name = "Special Guns", Cords = Vector3.new(-137.43, 1197.38, -738.71) },
    { Name = "Factory", Cords = Vector3.new(-1153.58, 1061.36, -97.44) },
    { Name = "Free P90", Cords = Vector3.new(-21.78, 1035.00, 128.97) },
    { Name = "Flare Gun", Cords = Vector3.new(-1340.24, 1006.67, -444.25) }
}
local LocationNames = {}
local CordsLookup = {}
for _, data in ipairs(Locations) do
    table.insert(LocationNames, data.Name)
    CordsLookup[data.Name] = data.Cords
end

function IsATable(val) return val ~= nil and typeof(val) == "table" end
function ResetCharacter()
    if not LocalPlayer.Character then return end
    if not replicatesignal then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:TakeDamage(700) end
    else
        replicatesignal(LocalPlayer.Kill)
    end
end

local GetFakeTime = function()
    if time() > CheatDT.FT.Value then CheatDT.FT.Value = time() end
    CheatDT.FT.Value += CheatDT.FT.Step
    return CheatDT.FT.Value
end

function CheckFolder(path)
    if not IsFilesystemSupported then return false end
    if not isfolder(path) then if isfile(path) then delfile(path) end makefolder(path) end
    return true
end

function ReadFileToTable(path)
    if not isfile(path) then return nil end
    local success, content = pcall(readfile, path)
    if not success or not content or string.len(content) == 0 then return nil end
    local result = nil
    success, result = pcall(HttpService.JSONDecode, HttpService, content)
    if not success or not result then return nil end
    return result
end

function WriteTableToFile(path, tabl)
    if not tabl or typeof(tabl) ~= "table" then return false end
    if isfolder(path) then delfolder(path) end
    local success, content = pcall(HttpService.JSONEncode, HttpService, tabl)
    if not success or not content or string.len(content) == 0 then return false end
    local errMsg = nil
    success, errMsg = pcall(writefile, path, content)
    if not success then return false end
    return true
end

function InitGameDT()
    GameDT.BClient = ReplicatedFirst:WaitForChild("BClient")
    GameDT.CharacterInitialized = false
    return true
end

local InitCheatDT = function()
    CheckFolder(CHEAT_DIR)
    if isfolder(Constants.GUN_MODS_PRESET_FILE_PATH) then delfolder(Constants.GUN_MODS_PRESET_FILE_PATH) end
    if isfile(Constants.GUN_MODS_PRESET_FILE_PATH) then CheatDT.GunModsPreset = ReadFileToTable(Constants.GUN_MODS_PRESET_FILE_PATH) end
    if not CheatDT.GunModsPreset then
        CheatDT.GunModsPreset = Constants.DEFAULT_GUN_MODS_PRESET
        WriteTableToFile(Constants.GUN_MODS_PRESET_FILE_PATH, CheatDT.GunModsPreset)
    end
    return true
end

function IsCharacterExists() return LocalPlayer.Character ~= nil and GameDT.Character and GameDT.Character == LocalPlayer.Character and GameDT.Character.Parent end

local IsBCFunction = function(func)
    if not (func ~= nil and typeof(func) == "function" and not iscclosure(func)) then return false end
    local info = debug.getinfo(func)
    if not info or not info.source or not string.find(info.source, "BClient") then return false end
    return true
end

local IsValidDataTable = function(tabl)
    if not tabl or typeof(tabl) ~= "table" then return false end
    local isStudio = rawget(tabl, "IsStudio")
    local UIS = rawget(tabl, "UserInputService")
    local CAS = rawget(tabl, "ContextActionService")
    local RS = rawget(tabl, "RunService")
    local RbxPlayers = rawget(tabl, "RbxPlayers")
    local localPlr = rawget(tabl, "LocalPlayer")
    local plrCollisionGroupName = rawget(tabl, "PlayerCollisionGroupName")
    return typeof(isStudio) == "boolean" and isStudio == RS:IsStudio() and UIS and compareinstances(UIS, UserInputService) and CAS and CAS == game:GetService("ContextActionService") and RS and compareinstances(RS, RunService) and RbxPlayers and compareinstances(RbxPlayers, Players) and localPlr and localPlr == LocalPlayer and plrCollisionGroupName and (plrCollisionGroupName == (RS:IsStudio() and "Player" or "b"))
end

function IsValidRemotesTable(tabl)
    if not IsATable(tabl) then return false end
    return IsATable(rawget(tabl, "JoinTeam")) and IsATable(rawget(tabl, "SaveSettings")) and IsATable(rawget(tabl, "ReceiveTool")) and IsATable(rawget(tabl, "FirearmBullets")) and IsATable(rawget(tabl, "OnSoundReplicate")) and IsATable(rawget(tabl, "OnAnnouncement"))
end

local IsValidACDetectionCodesTable = function(tabl)
    if not IsATable(tabl) then return false end
    return rawget(tabl, "WalkSpeedInvalidRead") and typeof(rawget(tabl, "WalkSpeedInvalidRead")) == "number" and rawget(tabl, "WalkSpeedWriteHook") and typeof(rawget(tabl, "WalkSpeedWriteHook")) == "number" and rawget(tabl, "UnequipToolsHook") and typeof(rawget(tabl, "UnequipToolsHook")) == "number" and rawget(tabl, "FastTeleport") and typeof(rawget(tabl, "FastTeleport")) == "number"
end

local GetDataTable = function(fetchTimeout)
    if not fetchTimeout or typeof(fetchTimeout) ~= "number" or fetchTimeout < 0.5 then fetchTimeout = 15 end
    if not GameDT.DataTable then
        local startTime = tick()
        repeat
            if (tick() - startTime) >= fetchTimeout then break end
            for i,v in ipairs(getgc(false)) do
                if not IsBCFunction(v) then continue end
                local upvals = debug.getupvalues(v)
                if not upvals or #upvals ~= 2 then continue end
                if typeof(upvals[1]) ~= "table" or typeof(upvals[2]) ~= "function" or iscclosure(upvals[2]) then continue end
                local dataTable = upvals[1]
                if not IsValidDataTable(dataTable) then continue end
                GameDT.DataTable = dataTable
                break
            end
            task.wait()
        until GameDT.DataTable
    end
    return GameDT.DataTable
end

local GetTimeEncodeFuncFromDataTable = function(dataTable)
    if not dataTable then return nil end
    local gst = dataTable.GST
    if not gst or typeof(gst) ~= "function" then return nil end
    local upvals = debug.getupvalues(gst)
    if not upvals or #upvals < 1 or typeof(upvals[1]) ~= "function" then return nil end
    return upvals[1]
end

function GetSignalIterator(signal)
    if not signal or typeof(signal) ~= "table" then return nil end
    local connFunc = signal.Connect
    if not IsBCFunction(connFunc) then return nil end
    local upvals = debug.getupvalues(connFunc)
    if not upvals or #upvals ~= 1 then return nil end
    return upvals[1]
end

function GetSignalConnections(signal, includeDisabled)
    if not signal or typeof(signal) ~= "table" then return nil end
    local iter = GetSignalIterator(signal)
    local result = {}
    while iter do
        if not includeDisabled and not iter.connected then iter = iter.next continue end
        table.insert(result, iter)
        iter = iter.next
    end
    return result
end

local GetActiveItemReceiveCallbacks = function()
    if not IsCharacterExists() or not GameDT.ActiveCharacterTable then return nil end
    local fnReceiveItem = GameDT.ActiveCharacterTable.ReceiveItem
    if not fnReceiveItem or typeof(fnReceiveItem) ~= "function" or iscclosure(fnReceiveItem) then return nil end
    local upvals = debug.getupvalues(fnReceiveItem)
    if not upvals or #upvals < 1 or not IsATable(upvals[1]) then return nil end
    return upvals[1]
end

function OnCharacterInit(charTable) end

function OnCharacterAdded(char)
    local itemCallbacks = GetActiveItemReceiveCallbacks()
    if not itemCallbacks then return end
    local fnFirearmCallback = itemCallbacks.Firearm
    if not fnFirearmCallback then return end

    fnFirearmCallback = hookfunction(fnFirearmCallback, newcclosure(function(toolTable, gunStats)
        if not CheatDT.GunModsEnabled or not toolTable.Tool or not toolTable.Tool:IsA("Tool") or not (toolTable.Tool.Parent == LocalPlayer.Backpack or toolTable.Tool:IsDescendantOf(char)) then return fnFirearmCallback(toolTable, gunStats) end
        local filterCheck = CheatDT.GunModsUsePresetInstead or not CheatDT.GunsModsFilterName
        if not filterCheck then
            local elements = string.split(CheatDT.GunsModsFilterName, ";")
            if elements and #elements > 0 then
                for i,v in ipairs(elements) do
                    if string.lower(toolTable.Tool.Name) == string.lower(v) then filterCheck = true break end
                end
            end
        end
        
        if filterCheck then
            local statsTable = nil
            if CheatDT.GunModsUsePresetInstead and CheatDT.GunModsPreset then
                if CheatDT.GunModsPreset[toolTable.Tool.Name] then
                    statsTable = CheatDT.GunModsPreset[toolTable.Tool.Name]
                    if typeof(statsTable) ~= "table" then statsTable = nil end
                elseif CheatDT.GunModsPreset.UseDefaultTable then
                    statsTable = CheatDT.GunModsPreset.DefaultTable
                end
            end
            gunStats.magammo = statsTable and statsTable.MagAmmo or CheatDT.GunModsMagammo
            gunStats.firerate = statsTable and statsTable.FireRate or CheatDT.GunModsFirerate
            gunStats.spread = statsTable and statsTable.Spread or CheatDT.GunModsSpread
            if not gunStats.isauto and CheatDT.GunModsAutomatize then gunStats.isauto = true end
            if CheatDT.GunModsRemoveNegativeEffects then
                if gunStats.wseffect ~= nil and gunStats.wseffect < 0 then gunStats.wseffect = nil end
                if gunStats.aimwseffect ~= nil and gunStats.aimwseffect < 0 then gunStats.aimwseffect = nil end
                if gunStats.aimjpeffect ~= nil and gunStats.aimjpeffect < 0 then gunStats.aimjpeffect = nil end
            end
        end
        return fnFirearmCallback(toolTable, gunStats)
    end))

    local tazedConns = GetSignalConnections(GameDT.ActiveCharacterTable.Tazed)
    for i,v in ipairs(tazedConns) do
        local origFn = nil
        origFn = hookfunction(v.fn, newcclosure(function(...)
            if CheatDT.AntiTazeEnabled then return end
            return origFn(...)
        end))
    end
end

local AC_GetConnections = function(signal, includeEnabledOnly)
    local result = {}
    for i,v in ipairs(getconnections(signal)) do
        if not v.Function or iscclosure(v.Function) then continue end
        if includeEnabledOnly and not v.Enabled then continue end
        local info = debug.getinfo(v.Function)
        if not info or not info.source or not string.find(info.source, "BClient") then continue end
        table.insert(result, v)
    end
    return result
end

local AC_CustomAct = function(reason, optionalArg) end
local AC_GetCustomAct = function() return AC_CustomAct end

local AC_Load = function()
    if not GetDataTable(40) then error("Failed to find game's data") end
    GameDT.TimeEncode = GetTimeEncodeFuncFromDataTable(GameDT.DataTable)
    if not GameDT.TimeEncode then error("Failed to find game's data: noenc") end

    GameDT.DataTable.GST = function(timeToEncode) return GameDT.TimeEncode(timeToEncode or GetFakeTime()) end

    local charInitSignal = GameDT.DataTable.CharacterInit
    if not charInitSignal then error("No init signal found") end

    local charInitEntryFunc = nil
    for i,v in ipairs(GetSignalConnections(charInitSignal)) do
        if not v.fn or iscclosure(v.fn) then continue end
        local upvals = debug.getupvalues(v.fn)
        if not upvals or #upvals < 3 then continue end
        local acDetectionCodes = upvals[1]
        if not IsValidACDetectionCodesTable(acDetectionCodes) then continue end
        local remotesTable = upvals[2]
        if not IsValidRemotesTable(remotesTable) then continue end
        local dataTable1 = upvals[3]
        if dataTable1 ~= GameDT.DataTable then continue end
        charInitEntryFunc = v.fn
        GameDT.RemotesTable = remotesTable
        break
    end
    if not charInitEntryFunc then error("No cinit function found") end

    charInitEntryFunc = hookfunction(charInitEntryFunc, newcclosure(function(charTable)
        GameDT.ActiveCharacterTable = charTable
        charTable.gACT = AC_GetCustomAct
        charInitEntryFunc(charTable)
        OnCharacterInit(charTable)
    end))

    local ACDummy = { FireServer = function(...) end, InvokeServer = function(...) return nil end }
    GameDT.RemotesTable.ACTrigger = ACDummy
    GameDT.RemotesTable.ACCFrameChanged = ACDummy
    GameDT.RemotesTable.ACKickTrigger = ACDummy

    local searchResult = filtergc("function", { ["IgnoreExecutor"] = true, ["Constants"] = {"IsProne", "IsTazed", "IsRagdoll", "Animator", "gACT"} })
    if not searchResult or #searchResult ~= 1 then error("No initial function found") end

    local fnOnCharacterAdded = searchResult[1]
    if not fnOnCharacterAdded or typeof(fnOnCharacterAdded) ~= "function" then error("No initial function found: 0xC") end

    fnOnCharacterAdded = hookfunction(fnOnCharacterAdded, newcclosure(function(char)
        GameDT.Character = char
        GameDT.CharacterInitialized = false
        fnOnCharacterAdded(char)

        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
        local hrp = hum.RootPart or char:WaitForChild("HumanoidRootPart")

        searchResult = AC_GetConnections(char.DescendantAdded)
        local fnBodyMoverDescAdded = nil
        for i,v in ipairs(searchResult) do
            local constants = debug.getconstants(v.Function)
            if not table.find(constants, "BodyMover") then continue end
            fnBodyMoverDescAdded = v.Function
            break
        end

        searchResult = AC_GetConnections(hrp.ChildAdded)
        local disabledRootBodyMoverCheck = false
        for i,v in ipairs(searchResult) do
            local constants = debug.getconstants(v.Function)
            if not table.find(constants, "BodyMover") then continue end
            v:Disconnect()
            disabledRootBodyMoverCheck = true
            break
        end

        local checkerBodyGyro = debug.getupvalue(fnBodyMoverDescAdded, 1)
        GameDT.CheckerBodyGyro = cloneref(checkerBodyGyro)

        fnBodyMoverDescAdded = hookfunction(fnBodyMoverDescAdded, newcclosure(function(descendant)
            if compareinstances(descendant, checkerBodyGyro) then fnBodyMoverDescAdded(descendant) end
        end))

        GameDT.CharacterInitialized = true
        OnCharacterAdded(char)
    end))

    if LocalPlayer.Character then ResetCharacter() end
end

function SetupPlayerCamera()
    workspace.CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
        if not CheatDT.VehicleAutoCorrectCam or workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable then return end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Track
    end)
    LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
        if LocalPlayer.CameraMinZoomDistance > CheatDT.MaxCameraZoom then LocalPlayer.CameraMinZoomDistance = CheatDT.MaxCameraZoom end
        LocalPlayer.CameraMaxZoomDistance = CheatDT.MaxCameraZoom
    end)
    if LocalPlayer.CameraMinZoomDistance > CheatDT.MaxCameraZoom then LocalPlayer.CameraMinZoomDistance = CheatDT.MaxCameraZoom end
    LocalPlayer.CameraMaxZoomDistance = CheatDT.MaxCameraZoom
end

function SetVehicleNoclip(val)
    local char = LocalPlayer.Character
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") then return false end

    for k,v in pairs(CheatDT.VehicleNoclipPrevParts) do if k.Parent then k.CanCollide = v end end
    table.clear(CheatDT.VehicleNoclipPrevParts)

    local carModel = hum.SeatPart.Parent.Parent
    if CheatDT.VehicleNoclipChecksConn then
        if CheatDT.VehicleNoclipChecksConn.Connected then CheatDT.VehicleNoclipChecksConn:Disconnect() end
        CheatDT.VehicleNoclipChecksConn = nil
        for k,v in pairs(carModel:GetDescendants()) do
            if v:IsA("Seat") and v.Occupant then
                local t = v.Occupant.Parent:FindFirstChild("Torso")
                local h = v.Occupant.Parent:FindFirstChild("Head")
                if t then t.CanCollide = true end if h then h.CanCollide = true end
            end
        end
    end

    if val then
        for i,v in ipairs(carModel:GetDescendants()) do
            if v:IsA("BasePart") then CheatDT.VehicleNoclipPrevParts[v] = v.CanCollide v.CanCollide = false end
        end
        local torso = char:FindFirstChild("Torso")
        if torso then torso.CanCollide = false end
        local head = char:FindFirstChild("Head")
        if head then head.CanCollide = false end

        CheatDT.VehicleNoclipChecksConn = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not hum or hum.Health <= 0 or not hum.SeatPart or not hum.SeatPart:IsA("VehicleSeat") or not carModel or not carModel.Parent then return end
            for k,v in pairs(carModel:GetDescendants()) do
                if v:IsA("Seat") and v.Occupant then
                    local t = v.Occupant.Parent:FindFirstChild("Torso")
                    local h = v.Occupant.Parent:FindFirstChild("Head")
                    if t then t.CanCollide = false end if h then h.CanCollide = false end
                end
            end
        end)
    else
        local torso = char:FindFirstChild("Torso")
        if torso then torso.CanCollide = true end
        local head = char:FindFirstChild("Head")
        if head then head.CanCollide = true end
    end
    CheatDT.VehicleNoclipEnabled = val
    return true
end

local function TeleportToCords(cords)
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Character.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(cords)
    end
end

local function CleanUpTool()
    if TPSettings.Connection then TPSettings.Connection:Disconnect() TPSettings.Connection = nil end
    if TPSettings.ActiveTool then TPSettings.ActiveTool:Destroy() TPSettings.ActiveTool = nil end
    local existing = LocalPlayer.Backpack:FindFirstChild("TP Tool") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("TP Tool"))
    if existing then existing:Destroy() end
end

local function GiveToolInstance()
    CleanUpTool()
    local Tool = Instance.new("Tool")
    Tool.Name = "TP Tool"
    Tool.RequiresHandle = false
    TPSettings.Connection = Tool.Activated:Connect(function()
        local Mouse = LocalPlayer:GetMouse()
        if Mouse and Mouse.Hit then TeleportToCords(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end)
    Tool.Parent = LocalPlayer:WaitForChild("Backpack")
    TPSettings.ActiveTool = Tool
end

local function FireTeamChange(teamName)
    local targetTeam = Teams:FindFirstChild(teamName)
    local remote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteEvent")
    if targetTeam and remote then remote:FireServer(1, targetTeam) end
end

local function RestoreSavedPosition()
    if not TeamSettings.BackgroundSavedCFrame then TeamSettings.IsSwitching = false return end
    local endTime = tick() + 0.4
    while tick() < endTime do
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.CFrame = TeamSettings.BackgroundSavedCFrame
            end
        end
        task.wait(0.02)
    end
    TeamSettings.IsSwitching = false
end

local function GetTarget(name)
    if name == "" then return nil end
    for _, player in pairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), string.lower(name)) or string.find(string.lower(player.DisplayName), string.lower(name)) then
            return player
        end
    end
    return nil
end

-- Stores last world positions per player for velocity prediction
local AimPredictCache = {}

local function GetAimPart(character)
    if AimSettings.AimHead then
        return character:FindFirstChild("Head")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    else
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end
end

local function GetClosestPlayerToCursor()
    local closestTarget = nil
    local shortestDistance = AimSettings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if AimSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            if player.Character:FindFirstChildOfClass("ForceField") then continue end
            local aimPart = GetAimPart(player.Character)
            if aimPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance < shortestDistance then
                        if AimSettings.WallCheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                            local result = workspace:Raycast(Camera.CFrame.Position, (aimPart.Position - Camera.CFrame.Position).Unit * 1000, rayParams)
                            if result and result.Instance:IsDescendantOf(player.Character) then
                                closestTarget = aimPart
                                shortestDistance = distance
                            end
                        else
                            closestTarget = aimPart
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local function GetESPColor(player)
    -- Use the player's actual team color if they have one
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 60, 60)
end

local function CleanESPForPlayer(player)
    local objs = ESPObjects[player]
    if not objs then return end
    for _, drawing in pairs(objs) do
        if drawing and drawing.Remove then drawing:Remove() end
    end
    ESPObjects[player] = nil
end

local function UpdateESP()
    if not ESPSettings.Enabled then
        for player in pairs(ESPObjects) do CleanESPForPlayer(player) end
        return
    end

    -- Remove ESP for players who left
    for player in pairs(ESPObjects) do
        if not player.Parent then CleanESPForPlayer(player) end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        -- Skip teammates
        if player.Team and player.Team == LocalPlayer.Team then
            CleanESPForPlayer(player)
            continue
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not hrp or not hum or hum.Health <= 0 then
            CleanESPForPlayer(player)
            continue
        end

        -- Create drawing objects if they don't exist yet
        if not ESPObjects[player] then
            ESPObjects[player] = {
                Box     = Drawing.new("Square"),
                Health  = Drawing.new("Text"),
                Name    = Drawing.new("Text"),
                Tracer  = Drawing.new("Line"),
            }
            local o = ESPObjects[player]
            o.Box.Thickness = 1
            o.Box.Filled = false
            o.Box.Visible = false
            o.Health.Size = 11
            o.Health.Font = 2
            o.Health.Outline = true
            o.Health.Center = true
            o.Health.Visible = false
            o.Name.Size = 11
            o.Name.Font = 2
            o.Name.Outline = true
            o.Name.Center = true
            o.Name.Visible = false
            o.Tracer.Thickness = 1
            o.Tracer.Visible = false
        end

        local o = ESPObjects[player]
        local color = GetESPColor(player)
        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local topPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
        local botPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, -3, 0))

        if not onScreen then
            o.Box.Visible = false
            o.Health.Visible = false
            o.Name.Visible = false
            o.Tracer.Visible = false
            continue
        end

        local height = math.abs(topPos.Y - botPos.Y)
        local width = height * 0.6
        local x = screenPos.X - width / 2
        local y = topPos.Y  -- top of box

        -- Box
        o.Box.Color = color
        o.Box.Size = Vector2.new(width, height)
        o.Box.Position = Vector2.new(x, y)
        o.Box.Visible = ESPSettings.Box

        -- Name: sits just above the top of the box
        o.Name.Text = player.Name
        o.Name.Color = color
        o.Name.Position = Vector2.new(screenPos.X, y - 13)
        o.Name.Visible = ESPSettings.Name

        -- Health: sits above the name
        local hpPct = math.floor((hum.Health / hum.MaxHealth) * 100)
        local hpColor = Color3.fromRGB(math.floor(255 * (1 - hpPct/100)), math.floor(255 * (hpPct/100)), 0)
        o.Health.Text = tostring(hpPct) .. "%"
        o.Health.Color = hpColor
        o.Health.Position = Vector2.new(screenPos.X, y - 26)
        o.Health.Visible = ESPSettings.Health

        -- Tracer from bottom center of screen
        local vp = Camera.ViewportSize
        o.Tracer.From = Vector2.new(vp.X / 2, vp.Y)
        o.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
        o.Tracer.Color = color
        o.Tracer.Visible = ESPSettings.Tracers
    end
end


local function EnableAntiSit()
    -- Disable all existing seats once
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Seat") or v:IsA("VehicleSeat") then
            v.Disabled = true
        end
    end
    -- Watch for any new seats added and disable them immediately
    MiscSettings.AntiSitConnection = workspace.DescendantAdded:Connect(function(v)
        if not MiscSettings.AntiSit then return end
        if v:IsA("Seat") or v:IsA("VehicleSeat") then
            v.Disabled = true
        end
    end)
end

local function DisableAntiSit()
    if MiscSettings.AntiSitConnection then
        MiscSettings.AntiSitConnection:Disconnect()
        MiscSettings.AntiSitConnection = nil
    end
    -- Re-enable all seats
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Seat") or v:IsA("VehicleSeat") then
            v.Disabled = false
        end
    end
end

RunService.Heartbeat:Connect(function(deltaTime)

    -- TPWalk
    if MovementSettings.TPWalkEnabled then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (moveDir * MovementSettings.TPWalkSpeed)
                end
            end
        end
    end

    -- Single TP is a one-shot teleport handled in the UI dropdown callback, no Heartbeat logic needed

    -- Spin Loop with head lock
    if LoopSettings.SpinEnabled then
        local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if localHrp then
            local tPlayer = LoopSettings.SpinTargetName ~= "" and GetTarget(LoopSettings.SpinTargetName) or nil
            local targetValid = tPlayer
                and tPlayer.Character
                and tPlayer.Character:FindFirstChild("HumanoidRootPart")
                and not tPlayer.Character:FindFirstChildOfClass("ForceField")
                and tPlayer.Character:FindFirstChildOfClass("Humanoid")
                and tPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0

            if targetValid then
                if not LoopSettings.OriginalCFrame then
                    LoopSettings.OriginalCFrame = localHrp.CFrame
                end
                local targetHrp = tPlayer.Character.HumanoidRootPart
                LoopSettings.SpinAngle = LoopSettings.SpinAngle + (deltaTime * LoopSettings.SpinSpeed)
                local offset = CFrame.new(
                    math.cos(LoopSettings.SpinAngle) * LoopSettings.SpinDistance,
                    LoopSettings.SpinHeight,
                    math.sin(LoopSettings.SpinAngle) * LoopSettings.SpinDistance
                )
                localHrp.CFrame = targetHrp.CFrame * offset
                localHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                localHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                -- Head lock: aim at target's head while spinning (cursor lock must be off)
                if not AimSettings.Enabled and mousemoverel then
                    local head = tPlayer.Character:FindFirstChild("Head")
                        or tPlayer.Character:FindFirstChild("UpperTorso")
                        or targetHrp
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local dx = screenPos.X - mousePos.X
                        local dy = screenPos.Y - mousePos.Y
                        mousemoverel(dx / math.max(AimSettings.Smoothness, 1), dy / math.max(AimSettings.Smoothness, 1))
                    end
                end
            else
                -- Target dead, left, or has FF — return to original spot
                if LoopSettings.OriginalCFrame then
                    localHrp.CFrame = LoopSettings.OriginalCFrame
                    localHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    localHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    LoopSettings.OriginalCFrame = nil
                    LoopSettings.SpinAngle = 0
                end
            end
        end
    else
        LoopSettings.OriginalCFrame = nil
        LoopSettings.SpinAngle = 0
    end

    -- Troll Spin: spin the local player in place
    if TrollSettings.SpinEnabled then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                TrollSettings.SpinAngle = TrollSettings.SpinAngle + (deltaTime * TrollSettings.SpinSpeed * 10)
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(TrollSettings.SpinAngle), 0)
            end
        end
    end

    -- Anti-Headsit: every frame force Head.CanCollide = false
    -- Uses a ForceField trick: a local ForceField removes ALL collision including head-sits
    if MiscSettings.AntiHeadsit then
        local char = LocalPlayer.Character
        if char then
            -- If no local FF exists, create one (client-side only, invisible to server)
            if not char:FindFirstChild("AntiHeadsitFF") then
                local ff = Instance.new("ForceField")
                ff.Name = "AntiHeadsitFF"
                ff.Visible = false
                ff.Parent = char
            end
            -- Also force head CanCollide false as a belt-and-suspenders approach
            local head = char:FindFirstChild("Head")
            if head then head.CanCollide = false end
        end
    else
        -- Clean up the FF when disabled
        local char = LocalPlayer.Character
        if char then
            local ff = char:FindFirstChild("AntiHeadsitFF")
            if ff then ff:Destroy() end
        end
    end

    -- Anti-Bang: detect sudden horizontal velocity spike and zero it out
    -- Bangs work by applying a huge horizontal force — we watch for that specifically
    if MiscSettings.AntiBang then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                local horizontalSpeed = Vector2.new(vel.X, vel.Z).Magnitude
                -- Bang threshold: 80 studs/s horizontal is way above normal
                if horizontalSpeed > 80 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(vel.Y, 0), 0)
                    if AntiPhysicsCache.LastCFrame then
                        hrp.CFrame = AntiPhysicsCache.LastCFrame
                    end
                else
                    AntiPhysicsCache.LastCFrame = hrp.CFrame
                end
            end
        end
    end

    -- Anti-Fling: detect total velocity spike (includes vertical) and restore
    if MiscSettings.AntiFling then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local speed = hrp.AssemblyLinearVelocity.Magnitude
                if speed > 120 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    if AntiPhysicsCache.LastCFrame then
                        hrp.CFrame = AntiPhysicsCache.LastCFrame
                    end
                else
                    AntiPhysicsCache.LastCFrame = hrp.CFrame
                end
            end
        end
    end

end)

RunService.Stepped:Connect(function()
    if MovementSettings.CharNoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if MovementSettings.FlyJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not TeamSettings.IsSwitching then
            local Character = LocalPlayer.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                if Humanoid and Humanoid.Health > 0 then
                    TeamSettings.BackgroundSavedCFrame = Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if SpecSettings.Enabled then
        if SpecSettings.Target and SpecSettings.Target.Character and SpecSettings.Target.Character:FindFirstChild("Humanoid") then
            if Camera.CameraSubject ~= SpecSettings.Target.Character.Humanoid then
                Camera.CameraSubject = SpecSettings.Target.Character.Humanoid
            end
        end
    end

    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = AimSettings.FOV

    -- ESP
    UpdateESP()

    local target = nil
    if AimSettings.Enabled then
        target = GetClosestPlayerToCursor()
    end

    if target then
        local targetId = tostring(target)
        local lastPos = AimPredictCache[targetId]
        local currentPos = target.Position
        local predictedPos = currentPos
        if lastPos then
            local velocity = currentPos - lastPos
            predictedPos = currentPos + velocity
        end
        AimPredictCache[targetId] = currentPos

        local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
        if onScreen then
            if AimSettings.Enabled and mousemoverel then
                local dx = targetScreenPos.X - mousePos.X
                local dy = targetScreenPos.Y - mousePos.Y
                local smooth = math.max(AimSettings.Smoothness, 1)
                local jitter = AimSettings.Smoothness * 0.3
                local jx = (math.random() - 0.5) * jitter
                local jy = (math.random() - 0.5) * jitter
                local dist = math.sqrt(dx*dx + dy*dy)
                local ease = math.min(dist / 20, 1)
                local stepX = (dx / smooth + jx) * ease
                local stepY = (dy / smooth + jy) * ease
                mousemoverel(stepX, stepY)
            end
        end
    else
        table.clear(AimPredictCache)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        SetVehicleNoclip(not CheatDT.VehicleNoclipEnabled)
    elseif input.KeyCode == AimSettings.Keybind then
        AimSettings.Enabled = not AimSettings.Enabled
        FOVCircle.Visible = AimSettings.Enabled
        if getgenv().AimLockToggleUI then getgenv().AimLockToggleUI(AimSettings.Enabled) end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if TPSettings.ToolActive then GiveToolInstance() else CleanUpTool() end
end)

-- Watch list: connects/disconnects PlayerAdded listener
local function WatchListConnect()
    if WatchList.Connection then WatchList.Connection:Disconnect() WatchList.Connection = nil end
    WatchList.Connection = Players.PlayerAdded:Connect(function(player)
        if not WatchList.Enabled then return end
        if WatchList.UserIds[player.UserId] then
            -- Fire notification via ImGuiLib if UI is loaded
            if ImGuiLib then
                ImGuiLib:Notify({
                    Title = "!! Watched Player Joined !!",
                    Message = player.Name .. " (" .. player.DisplayName .. ") | ID: " .. tostring(player.UserId),
                    Duration = 8,
                    Color = Color3.fromRGB(255, 60, 60)
                })
            end
        end
    end)
end

local ImGuiLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/xqzxa/ImGuiLib/main/source.lua"))()

function StartUI()
    local Window = ImGuiLib:CreateWindow({ Title = "LIP V2 + Skidded | [Private]", Size = Vector2.new(340, 650) }) -- Resized window for new options[cite: 11]

    local GunModsHeader = Window:CreateHeader({ Name = "Gun Modify" })
    local CombatHeader = Window:CreateHeader({ Name = "Cursor Lock" })
    local MovementHeader = Window:CreateHeader({ Name = "Movement" })
    local TeleportHeader = Window:CreateHeader({ Name = "Teleport" })
    local SpectateHeader = Window:CreateHeader({ Name = "Spectate" })
    local TeamsHeader = Window:CreateHeader({ Name = "Teams" })
    local MiscHeader = Window:CreateHeader({ Name = "Misc Options" })

    CombatHeader:CreateToggle({
        Name = "Cursor Lock (Keybind: Q)", Default = AimSettings.Enabled,
        Callback = function(state)
            AimSettings.Enabled = state
            FOVCircle.Visible = state
            ImGuiLib:Notify({ Title = "Cursor Lock", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(30, 120, 215) or Color3.fromRGB(200, 80, 80) })
        end
    })
    getgenv().AimLockToggleUI = function(state) end 
    CombatHeader:CreateToggle({ Name = "Aim Head", Default = AimSettings.AimHead, Callback = function(state) AimSettings.AimHead = state ImGuiLib:Notify({ Title = "Aim Head", Message = state and "Targeting head" or "Targeting torso", Duration = 2, Color = Color3.fromRGB(255, 160, 50) }) end })
    CombatHeader:CreateToggle({ Name = "Wall Check", Default = AimSettings.WallCheck, Callback = function(state) AimSettings.WallCheck = state end })
    CombatHeader:CreateToggle({ Name = "Team Check", Default = AimSettings.TeamCheck, Callback = function(state) AimSettings.TeamCheck = state end })

    CombatHeader:CreateSlider({ Name = "FOV Size", Min = 10, Max = 600, Default = AimSettings.FOV, Callback = function(val) AimSettings.FOV = val end })
    CombatHeader:CreateSlider({ Name = "Aim Smoothness", Min = 1, Max = 10, Default = AimSettings.Smoothness, Callback = function(val) AimSettings.Smoothness = val end })

    MovementHeader:CreateToggle({ Name = "TPWalk Enabled", Default = MovementSettings.TPWalkEnabled, Callback = function(state) MovementSettings.TPWalkEnabled = state ImGuiLib:Notify({ Title = "TPWalk", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) }) end })
    MovementHeader:CreateSlider({ Name = "TPWalk Speed", Min = 1, Max = 20, Default = 2, Callback = function(val) MovementSettings.TPWalkSpeed = val end })
    MovementHeader:CreateToggle({ Name = "FlyJump", Default = MovementSettings.FlyJumpEnabled, Callback = function(state) MovementSettings.FlyJumpEnabled = state ImGuiLib:Notify({ Title = "FlyJump", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) }) end })
    MovementHeader:CreateToggle({ Name = "Noclip", Default = MovementSettings.CharNoclipEnabled, Callback = function(state) MovementSettings.CharNoclipEnabled = state ImGuiLib:Notify({ Title = "Noclip", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) }) end })
    MovementHeader:CreateToggle({ Name = "Vehicle Noclip (Keybind: V)", Default = CheatDT.VehicleNoclipEnabled, Callback = function(state) SetVehicleNoclip(state) end })
    MovementHeader:CreateToggle({ Name = "Anti-Taze", Default = CheatDT.AntiTazeEnabled, Callback = function(state) CheatDT.AntiTazeEnabled = state ImGuiLib:Notify({ Title = "Anti-Taze", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) }) end })
    -- Teleport section
    TeleportHeader:CreateDropdown({
        Name = "Place Teleport", Options = LocationNames, Default = LocationNames[1] or "None",
        Callback = function(selection) if CordsLookup[selection] then TeleportToCords(CordsLookup[selection]) ImGuiLib:Notify({ Title = "Teleport", Message = "Teleported to " .. selection, Duration = 2, Color = Color3.fromRGB(30, 120, 215) }) end end
    })
    TeleportHeader:CreatePlayerDropdown({
        Name = "Target Player Teleport",
        Callback = function(playerName)
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                TeleportToCords(targetPlayer.Character.HumanoidRootPart.Position)
                ImGuiLib:Notify({ Title = "Teleport", Message = "TP'd to " .. playerName, Duration = 2, Color = Color3.fromRGB(30, 120, 215) })
            end
        end
    })
    TeleportHeader:CreateToggle({
        Name = "Equip Teleport Tool", Default = TPSettings.ToolActive,
        Callback = function(state) TPSettings.ToolActive = state if state then GiveToolInstance() else CleanUpTool() end end
    })

    -- Spin Loop Options
    local SpinTargetLabel = TeleportHeader:CreateLabel({ Text = "Spin Target: None", Color = Color3.fromRGB(150, 150, 150) })
    TeleportHeader:CreateTextBox({ Name = "Spin Target Name", Placeholder = "Username...", Callback = function(val)
        LoopSettings.SpinTargetName = val
        if val ~= "" then
            SpinTargetLabel:SetText("Spin Target: " .. val)
            SpinTargetLabel:SetColor(Color3.fromRGB(80, 200, 120))
        else
            SpinTargetLabel:SetText("Spin Target: None")
            SpinTargetLabel:SetColor(Color3.fromRGB(150, 150, 150))
        end
    end })
    TeleportHeader:CreateToggle({ Name = "Enable Spin Loop", Default = false, Callback = function(state)
        LoopSettings.SpinEnabled = state
        ImGuiLib:Notify({ Title = "Spin Loop", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    TeleportHeader:CreateSlider({ Name = "Spin Speed", Min = 1, Max = 10, Default = 1, Callback = function(val) LoopSettings.SpinSpeed = val end })
    TeleportHeader:CreateSlider({ Name = "Spin Distance", Min = 1, Max = 50, Default = 5, Callback = function(val) LoopSettings.SpinDistance = val end })
    TeleportHeader:CreateSlider({ Name = "Spin Height", Min = -20, Max = 20, Default = 0, Callback = function(val) LoopSettings.SpinHeight = val end })

    -- Spectate section
    local SpecLabel = SpectateHeader:CreateLabel({ Text = "Spectating: None", Color = Color3.fromRGB(150, 150, 150) })
    SpectateHeader:CreateTextBox({ Name = "Spectate Target", Placeholder = "Enter name...", Callback = function(val)
        SpecSettings.Name = val
        if SpecSettings.Enabled then SpecSettings.Target = GetTarget(SpecSettings.Name) end
        if val ~= "" then
            SpecLabel:SetText("Spectating: " .. val)
            SpecLabel:SetColor(Color3.fromRGB(80, 200, 120))
        else
            SpecLabel:SetText("Spectating: None")
            SpecLabel:SetColor(Color3.fromRGB(150, 150, 150))
        end
    end })
    SpectateHeader:CreateToggle({
        Name = "Enable Spectating", Default = false,
        Callback = function(state) SpecSettings.Enabled = state if state then SpecSettings.Target = GetTarget(SpecSettings.Name) if SpecSettings.Target and SpecSettings.Target.Character then Camera.CameraSubject = SpecSettings.Target.Character:FindFirstChild("Humanoid") end else Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or nil end ImGuiLib:Notify({ Title = "Spectate", Message = state and ("Spectating " .. (SpecSettings.Name ~= "" and SpecSettings.Name or "nobody")) or "Stopped", Duration = 2, Color = state and Color3.fromRGB(30, 120, 215) or Color3.fromRGB(200, 80, 80) }) end
    })
    SpectateHeader:CreateButton({ Name = "Copy User Info", Callback = function()
        local target = GetTarget(SpecSettings.Name)
        if not target then
            ImGuiLib:Notify({ Title = "User Info", Message = "No target set or found", Duration = 3, Color = Color3.fromRGB(200, 80, 80) })
            return
        end
        local info = "Username: " .. target.Name .. " | Display Name: " .. target.DisplayName .. " | User ID: " .. tostring(target.UserId)
        setclipboard(info)
        ImGuiLib:Notify({ Title = "User Info Copied", Message = target.Name .. " | " .. target.DisplayName .. " | " .. tostring(target.UserId), Duration = 4, Color = Color3.fromRGB(30, 120, 215) })
    end })

    -- Teams section
    TeamsHeader:CreateButton({ Name = "Fast Switch: Prisoners", Callback = function() TeamSettings.IsSwitching = true FireTeamChange("Neutral") task.wait(0.05) FireTeamChange("Prisoners") task.spawn(RestoreSavedPosition) end })
    local actualGuardTeam = Teams:FindFirstChild("Guards") or Teams:FindFirstChild("Police")
    if actualGuardTeam then
        TeamsHeader:CreateButton({ Name = "Fast Switch: " .. actualGuardTeam.Name, Callback = function() TeamSettings.IsSwitching = true FireTeamChange("Neutral") task.wait(0.05) FireTeamChange(actualGuardTeam.Name) task.spawn(RestoreSavedPosition) end })
    end

    GunModsHeader:CreateToggle({ Name = "Enabled", Default = CheatDT.GunModsEnabled, Callback = function(state) CheatDT.GunModsEnabled = state ImGuiLib:Notify({ Title = "Gun Mods", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) }) end })
    GunModsHeader:CreateToggle({ Name = "Use Preset", Default = CheatDT.GunModsUsePresetInstead, Callback = function(state) CheatDT.GunModsUsePresetInstead = state end })
    GunModsHeader:CreateSlider({ Name = "Magazine Ammo", Min = 1, Max = 99999999999, Default = 99999999999, Callback = function(val) CheatDT.GunModsMagammo = val end })
    GunModsHeader:CreateSlider({ Name = "Fire Rate (Lower = Faster)", Min = 1, Max = 100, Default = 1, Callback = function(val) CheatDT.GunModsFirerate = val / 100 end })
    GunModsHeader:CreateToggle({ Name = "Make Automatic", Default = CheatDT.GunModsAutomatize, Callback = function(state) CheatDT.GunModsAutomatize = state end })
    GunModsHeader:CreateToggle({ Name = "Remove Negative Effects", Default = CheatDT.GunModsRemoveNegativeEffects, Callback = function(state) CheatDT.GunModsRemoveNegativeEffects = state end })
    GunModsHeader:CreateSlider({ Name = "Spread", Min = 0, Max = 100, Default = 0, Callback = function(val) CheatDT.GunModsSpread = val / 100 end })
    GunModsHeader:CreateSlider({ Name = "FOV (Zoom)", Min = 10, Max = 120, Default = 70, Callback = function(val)
        workspace.CurrentCamera.FieldOfView = val
    end })

    MiscHeader:CreateToggle({ Name = "Anti Sit", Default = true, Callback = function(state)
        MiscSettings.AntiSit = state
        if state then EnableAntiSit() else DisableAntiSit() end
        ImGuiLib:Notify({ Title = "Anti Sit", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    MiscHeader:CreateToggle({ Name = "Anti Headsit", Default = true, Callback = function(state)
        MiscSettings.AntiHeadsit = state
        -- Clean up FF immediately when turned off
        if not state and LocalPlayer.Character then
            local ff = LocalPlayer.Character:FindFirstChild("AntiHeadsitFF")
            if ff then ff:Destroy() end
        end
        ImGuiLib:Notify({ Title = "Anti Headsit", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    MiscHeader:CreateToggle({ Name = "Anti Bang", Default = true, Callback = function(state)
        MiscSettings.AntiBang = state
        AntiPhysicsCache.LastCFrame = nil
        ImGuiLib:Notify({ Title = "Anti Bang", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    MiscHeader:CreateToggle({ Name = "Anti Fling", Default = true, Callback = function(state)
        MiscSettings.AntiFling = state
        AntiPhysicsCache.LastCFrame = nil
        ImGuiLib:Notify({ Title = "Anti Fling", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    MiscHeader:CreateButton({ Name = "Copy Server Link", Callback = function()
        local placeId = game.PlaceId
        local jobId = game.JobId
        local link = "roblox://experiences/start?placeId=" .. tostring(placeId) .. "&gameInstanceId=" .. tostring(jobId)
        setclipboard(link)
        ImGuiLib:Notify({ Title = "Server Link", Message = "Copied to clipboard!", Duration = 3, Color = Color3.fromRGB(30, 120, 215) })
    end })
    MiscHeader:CreateButton({ Name = "Rejoin Server", Callback = function()
        ImGuiLib:Notify({ Title = "Rejoin", Message = "Rejoining server...", Duration = 2, Color = Color3.fromRGB(255, 160, 50) })
        task.wait(0.5)
        local placeId = game.PlaceId
        local jobId = game.JobId
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(placeId, jobId, Players.LocalPlayer)
    end })
    -- Player Join Alert
    MiscHeader:CreateToggle({ Name = "Staff Join Alert", Default = true, Callback = function(state)
        WatchList.Enabled = state
        if state then
            WatchListConnect()
            ImGuiLib:Notify({ Title = "Join Alert", Message = "Watching for " .. (next(WatchList.UserIds) and "your watchlist" or "nobody yet — add IDs below"), Duration = 3, Color = Color3.fromRGB(255, 160, 50) })
        else
            if WatchList.Connection then WatchList.Connection:Disconnect() WatchList.Connection = nil end
            ImGuiLib:Notify({ Title = "Join Alert", Message = "Disabled", Duration = 2, Color = Color3.fromRGB(200, 80, 80) })
        end
    end })
    MiscHeader:CreateButton({ Name = "Check Watchlist in Server Now", Callback = function()
        local found = {}
        for _, player in pairs(Players:GetPlayers()) do
            if WatchList.UserIds[player.UserId] then
                table.insert(found, player.Name .. " (" .. tostring(player.UserId) .. ")")
            end
        end
        if #found > 0 then
            ImGuiLib:Notify({ Title = "Watchlist — In Server", Message = table.concat(found, ", "), Duration = 6, Color = Color3.fromRGB(255, 60, 60) })
        else
            ImGuiLib:Notify({ Title = "Watchlist — In Server", Message = "None of your watched players are here", Duration = 3, Color = Color3.fromRGB(80, 200, 120) })
        end
    end })
    local VisualsHeader = Window:CreateHeader({ Name = "Visuals" })
    VisualsHeader:CreateToggle({ Name = "ESP Enabled", Default = false, Callback = function(state)
        ESPSettings.Enabled = state
        if not state then for player in pairs(ESPObjects) do CleanESPForPlayer(player) end end
        ImGuiLib:Notify({ Title = "ESP", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    VisualsHeader:CreateToggle({ Name = "Box", Default = false, Callback = function(state)
        ESPSettings.Box = state
    end })
    VisualsHeader:CreateToggle({ Name = "Health", Default = false, Callback = function(state)
        ESPSettings.Health = state
    end })
    VisualsHeader:CreateToggle({ Name = "Name", Default = false, Callback = function(state)
        ESPSettings.Name = state
    end })
    VisualsHeader:CreateToggle({ Name = "Tracers", Default = false, Callback = function(state)
        ESPSettings.Tracers = state
    end })

    local TrollHeader = Window:CreateHeader({ Name = "Troll" })
    TrollHeader:CreateToggle({ Name = "Spin", Default = false, Callback = function(state)
        TrollSettings.SpinEnabled = state
        TrollSettings.SpinAngle = 0
        ImGuiLib:Notify({ Title = "Troll Spin", Message = state and "Enabled" or "Disabled", Duration = 2, Color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(200, 80, 80) })
    end })
    TrollHeader:CreateSlider({ Name = "Spin Speed", Min = 1, Max = 20, Default = 5, Callback = function(val)
        TrollSettings.SpinSpeed = val
    end })

    local ScriptsHeader = Window:CreateHeader({ Name = "Scripts" })
    ScriptsHeader:CreateButton({ Name = "Infinite Yield", Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        ImGuiLib:Notify({ Title = "Scripts", Message = "Infinite Yield loaded!", Duration = 3, Color = Color3.fromRGB(80, 200, 120) })
    end })
    ScriptsHeader:CreateButton({ Name = "Dex++", Callback = function()
        loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
        ImGuiLib:Notify({ Title = "Scripts", Message = "Dex++ loaded!", Duration = 3, Color = Color3.fromRGB(80, 200, 120) })
    end })
    ScriptsHeader:CreateButton({ Name = "Remote Spy (SimpleSpy V3)", Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
        ImGuiLib:Notify({ Title = "Scripts", Message = "Remote Spy loaded!", Duration = 3, Color = Color3.fromRGB(80, 200, 120) })
    end })
    MiscHeader:CreateToggle({ Name = "Vehicle Cam Auto-Correct", Default = CheatDT.VehicleAutoCorrectCam, Callback = function(state) CheatDT.VehicleAutoCorrectCam = state end })
    MiscHeader:CreateSlider({
        Name = "Camera Max Zoom", Min = 10, Max = 1000, Default = 200,
        Callback = function(val) CheatDT.MaxCameraZoom = val if LocalPlayer.CameraMinZoomDistance > val then LocalPlayer.CameraMinZoomDistance = val end LocalPlayer.CameraMaxZoomDistance = val end
    })
end

if not InitGameDT() or not InitCheatDT() then return end
local success, status = pcall(AC_Load)
if not success then return end

SetupPlayerCamera()
EnableAntiSit()  -- auto-enable on start since AntiSit defaults to true
pcall(StartUI)

getgenv().LIPV2_LOADED = true
