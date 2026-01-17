-- // RoffaHub | REFACTORED VERSION //

--------------------------------------------------
-- CLEANUP GUARD (PREVENTS DOUBLE UI)
--------------------------------------------------
if _G.RoffaHubUI then
    _G.RoffaHubUI:Destroy()
    _G.RoffaHubUI = nil
end

-- // ASSET DOWNLOADER //
local folderName = "sixrose_assets"
if not isfolder(folderName) then makefolder(folderName) end
local RequiredFiles = {"CashRegister.mp3", "Chip.mp3", "HoHoHo.mp3", "Hypercharge.mp3", "Kick1.mp3", "Kick2.mp3", "Kick3.mp3", "Mariocoin.mp3", "McXP.mp3", "Powershot.mp3", "Snap.mp3", "SoftBellSparkle.mp3", "Sonic.mp3", "SqueakyToy.mp3", "Switch.mp3", "swoosh.mp3"}
for _, fileName in ipairs(RequiredFiles) do
    if not isfile(folderName .. "/" .. fileName) then
        pcall(function() writefile(folderName .. "/" .. fileName, game:HttpGet("https://raw.githubusercontent.com/beroshade/sixrose-assets/main/" .. fileName)) end)
    end
end

--------------------------------------------------
-- UI LIBRARY
--------------------------------------------------
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    theme = 'cherry',
    smoothDragging = false
})

ui.autoDisableToggles = false

--------------------------------------------------
-- GLOBAL TOGGLES & KEYBINDS
--------------------------------------------------
local Toggles = {
    InfiniteM12 = false,
    InstaShot = false,
    HBE = false,
    InstaFlick = false,
    DoubleTap = false,
    DribbleSpeed = false,
    InfiniteStamina = false
}

-- Changeable keybinds
local Keybinds = {
    InfiniteM12 = Enum.KeyCode.Z,
    InstaShot = Enum.KeyCode.G,
    InstaFlick = Enum.KeyCode.T,
    DoubleTap = Enum.KeyCode.P
}

--------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------
local window = ui.newWindow({
    text = 'RoffaHub',
    resize = true,
    size = Vector2.new(550, 420),
})

_G.RoffaHubUI = window.instance

-- RIGHT SHIFT TOGGLE
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        window.visible = not window.visible
    end
end)

local menu = window:addMenu({ text = 'Scripts' })
local extraMenu = window:addMenu({ text = 'Extra Scripts' })

--------------------------------------------------
-- EXTRA SCRIPTS SECTION
--------------------------------------------------
local extraSection = extraMenu:addSection({
    text = 'Extras',
    side = 'auto',
    showMinButton = false
})

----------------------------------------
-- Custom Sounds
----------------------------------------
local customSoundsEnabled = false

extraSection:addToggle({
    text = 'Custom Sounds',
    default = false
}, function(state)
    customSoundsEnabled = state
end)

-- Sound handling logic
local handledSounds = {}
local netSounds = {{file="SqueakyToy",vol=5.0},{file="SoftBellSparkle",vol=5.5},{file="Sonic",vol=5.0},{file="Snap",vol=10.0},{file="Switch",vol=5.0},{file="McXP",vol=5.0},{file="Mariocoin",vol=5.0},{file="Hypercharge",vol=10.0},{file="HoHoHo",vol=2.0},{file="CashRegister",vol=3.0}}
local soundDebounce = false

local function handleSound(sound)
    if not customSoundsEnabled or not sound:IsA("Sound") or soundDebounce then return end
    
    local name = sound.Name
    local fileName = nil
    local targetVol = 2.0 
    
    if name == "NetSFX" then
        local picked = netSounds[math.random(1, #netSounds)]
        fileName = picked.file .. ".mp3"
        targetVol = picked.vol
    elseif name == "HeavyKick" then
        fileName = "Powershot.mp3"
        targetVol = 5.0
    elseif string.match(name, "^heavierKick") then
        fileName = "Chip.mp3"
        targetVol = 3.0
    elseif name == "woosh" then
        fileName = "swoosh.mp3"
        targetVol = 3.0
    elseif string.match(name, "^Kick") then
        local num = tonumber(string.match(name, "%d+")) or 1
        fileName = "Kick" .. (((num - 1) % 3) + 1) .. ".mp3"
    end

    if fileName then
        soundDebounce = true
        sound.Volume = 0
        
        local custom = Instance.new("Sound")
        custom.Parent = sound.Parent
        pcall(function() 
            custom.SoundId = getcustomasset(folderName .. "/" .. fileName) 
        end)
        custom.Volume = targetVol
        custom:Play()
        
        custom.Ended:Connect(function()
            custom:Destroy()
        end)

        task.delay(0.15, function()
            soundDebounce = false
        end)
    end
end
workspace.DescendantAdded:Connect(handleSound)

----------------------------------------
-- Dribble Speed
----------------------------------------
extraSection:addToggle({
    text = 'Dribble Speed',
    default = false
}, function(state)
    Toggles.DribbleSpeed = state
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local PSSettings = ReplicatedStorage:WaitForChild("PSSettings")
local runSpeedMult = PSSettings:WaitForChild("RunSpeedMult")
local temp = Workspace:WaitForChild("Temp")

local conns, ballConns = {}, {}

local function clear(t)
    for _,c in ipairs(t) do pcall(function() c:Disconnect() end) end
    table.clear(t)
end

local function set(v)
    if Toggles.DribbleSpeed and runSpeedMult.Value ~= v then 
        runSpeedMult.Value = v 
    end
end

local function bind(h)
    clear(conns)
    set(h.Enabled and 1.15 or 1)
    table.insert(conns, h:GetPropertyChangedSignal("Enabled"):Connect(function()
        set(h.Enabled and 1.15 or 1)
    end))
end

local function watch(ball)
    clear(ballConns)
    table.insert(ballConns, ball.ChildAdded:Connect(function(c)
        if c.Name=="PossessionHighlight" then bind(c) end
    end))
end

watch(temp:WaitForChild("Ball"))
RunService.RenderStepped:Connect(function()
    local cam=workspace.CurrentCamera
    if cam and cam.FieldOfView>80 then cam.FieldOfView=80 end
end)

----------------------------------------
-- Interpolation Buttons (5-step increments)
----------------------------------------
local interpValues = {100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30, 25, 20, 15, 10, 5}

for _, value in ipairs(interpValues) do
    extraSection:addButton({ 
        text = value .. ' Interpolation', 
        style = 'large' 
    }, function()
        pcall(function() 
            setfflag("InterpolationMaxDelayMSec", tostring(value)) 
        end)
    end)
end

--------------------------------------------------
-- MAIN SCRIPT SECTION
--------------------------------------------------
local section = menu:addSection({
    text = 'Script Executor',
    side = 'auto',
    showMinButton = false
})

--------------------------------------------------
-- NOTIFICATION SYSTEM FOR KEYBIND CHANGES
--------------------------------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function createNotification(text, duration)
    duration = duration or 3
    
    -- Create notification GUI
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "KeybindNotification"
    notifGui.ResetOnSpawn = false
    notifGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    -- Fade in
    frame.BackgroundTransparency = 1
    label.TextTransparency = 1
    
    local tweenService = game:GetService("TweenService")
    local fadeIn = tweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.1})
    local fadeInText = tweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0})
    
    fadeIn:Play()
    fadeInText:Play()
    
    -- Wait and fade out
    task.wait(duration)
    
    local fadeOut = tweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1})
    local fadeOutText = tweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1})
    
    fadeOut:Play()
    fadeOutText:Play()
    
    fadeOut.Completed:Connect(function()
        notifGui:Destroy()
    end)
end

--------------------------------------------------
-- REFERENCES TO UI ELEMENTS (FOR UPDATING TEXT)
--------------------------------------------------
local infiniteM12Toggle = nil
local instaShotToggle = nil
local instaFlickToggle = nil
local doubleTapToggle = nil

--------------------------------------------------
-- UI TOGGLES WITH VISIBLE KEYBINDS
--------------------------------------------------
infiniteM12Toggle = section:addToggle({ 
    text = 'Infinite M1 / M2 [Z]' 
}, function(v)
    Toggles.InfiniteM12 = v
end)

section:addButton({ 
    text = 'Change M1/M2 Key', 
    style = 'small' 
}, function()
    local UIS = game:GetService("UserInputService")
    
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        -- Immediately disconnect after first key press
        conn:Disconnect()
        
        Keybinds.InfiniteM12 = input.KeyCode
        
        -- Update UI text
        if infiniteM12Toggle and infiniteM12Toggle.text then
            infiniteM12Toggle.text = 'Infinite M1 / M2 [' .. input.KeyCode.Name .. ']'
            if infiniteM12Toggle.label then
                infiniteM12Toggle.label.Text = infiniteM12Toggle.text
            end
        end
        
        createNotification("M1/M2 Key: " .. input.KeyCode.Name, 2)
    end)
end)

----------------------------------------
-- INSTA SHOT WITH CHANGEABLE KEYBIND
----------------------------------------
instaShotToggle = section:addToggle({ 
    text = 'Insta Shot [G]' 
}, function(v)
    Toggles.InstaShot = v
end)

section:addButton({ 
    text = 'Change Insta Shot Key', 
    style = 'small' 
}, function()
    local UIS = game:GetService("UserInputService")
    
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        -- Immediately disconnect after first key press
        conn:Disconnect()
        
        Keybinds.InstaShot = input.KeyCode
        
        -- Update UI text
        if instaShotToggle and instaShotToggle.text then
            instaShotToggle.text = 'Insta Shot [' .. input.KeyCode.Name .. ']'
            if instaShotToggle.label then
                instaShotToggle.label.Text = instaShotToggle.text
            end
        end
        
        createNotification("Insta Shot: " .. input.KeyCode.Name, 2)
    end)
end)

----------------------------------------
-- HBE (UI Toggle controls HBE, P controls visual sphere)
----------------------------------------
section:addToggle({ 
    text = 'HBE (Comma/Dot = Size, P = Visual)' 
}, function(v)
    Toggles.HBE = v
end)

----------------------------------------
-- INSTA FLICK WITH CHANGEABLE KEYBIND
----------------------------------------
instaFlickToggle = section:addToggle({ 
    text = 'Insta Flick [T]' 
}, function(v)
    Toggles.InstaFlick = v
end)

section:addButton({ 
    text = 'Change Insta Flick Key', 
    style = 'small' 
}, function()
    local UIS = game:GetService("UserInputService")
    
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        -- Immediately disconnect after first key press
        conn:Disconnect()
        
        Keybinds.InstaFlick = input.KeyCode
        
        -- Update UI text
        if instaFlickToggle and instaFlickToggle.text then
            instaFlickToggle.text = 'Insta Flick [' .. input.KeyCode.Name .. ']'
            if instaFlickToggle.label then
                instaFlickToggle.label.Text = instaFlickToggle.text
            end
        end
        
        createNotification("Insta Flick: " .. input.KeyCode.Name, 2)
    end)
end)

----------------------------------------
-- DOUBLE TAP WITH CHANGEABLE KEYBIND
----------------------------------------
doubleTapToggle = section:addToggle({ 
    text = 'Double Tap [P]' 
}, function(v)
    Toggles.DoubleTap = v
end)

section:addButton({ 
    text = 'Change Double Tap Key', 
    style = 'small' 
}, function()
    local UIS = game:GetService("UserInputService")
    
    local conn
    conn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        -- Immediately disconnect after first key press
        conn:Disconnect()
        
        Keybinds.DoubleTap = input.KeyCode
        
        -- Update UI text
        if doubleTapToggle and doubleTapToggle.text then
            doubleTapToggle.text = 'Double Tap [' .. input.KeyCode.Name .. ']'
            if doubleTapToggle.label then
                doubleTapToggle.label.Text = doubleTapToggle.text
            end
        end
        
        createNotification("Double Tap: " .. input.KeyCode.Name, 2)
    end)
end)

----------------------------------------
-- Infinite Stamina
----------------------------------------
section:addToggle({
    text = 'Infinite Stamina',
    style = 'large'
}, function(state)
    Toggles.InfiniteStamina = state
end)

--------------------------------------------------
-- INFINITE M1 / M2 LOGIC
--------------------------------------------------
do
    local Players = game:GetService('Players')
    local RunService = game:GetService('RunService')
    local UserInputService = game:GetService('UserInputService')
    local VirtualInputManager = game:GetService('VirtualInputManager')

    local player = Players.LocalPlayer
    local mouse = player:GetMouse()

    local triggerDistance = 5
    local clickDelay = 0.1
    local noKickCDActive = true
    local spamM1 = true
    local spamM2 = true

    local holdingZ = false

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Keybinds.InfiniteM12 then
            holdingZ = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Keybinds.InfiniteM12 then
            holdingZ = false
        end
    end)

    if noKickCDActive then
        RunService.Heartbeat:Connect(function()
            if not Toggles.InfiniteM12 then return end
            local char = player.Character
            if char and char:FindFirstChild('Status') and char.Status:FindFirstChild('KickCD') then
                char.Status.KickCD:Destroy()
            end
        end)
    end

    task.spawn(function()
        while true do
            task.wait(clickDelay)
            if not Toggles.InfiniteM12 then continue end
            if not holdingZ then continue end

            local temp = workspace:FindFirstChild('Temp')
            local ball = temp and temp:FindFirstChild('Ball')
            local char = player.Character
            local hrp = char and char:FindFirstChild('HumanoidRootPart')

            if not ball or not hrp then continue end
            if ball:FindFirstChild('PossessionHighlight') then continue end

            local distance = (ball.Position - hrp.Position).Magnitude
            if distance <= triggerDistance then
                if spamM1 then
                    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, nil, 1)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, nil, 1)
                end
                if spamM2 then
                    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 1, true, nil, 1)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 1, false, nil, 1)
                end
            end
        end
    end)
end

--------------------------------------------------
-- INSTA SHOT LOGIC (USES CHANGEABLE KEYBIND)
--------------------------------------------------
do
    local Players = game:GetService('Players')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local UserInputService = game:GetService('UserInputService')
    local Workspace = game:GetService('Workspace')

    local Knit = require(ReplicatedStorage.Packages.Knit)
    local KeyHandlerService = Knit.GetService('KeyHandlerService')
    local kickRemote = KeyHandlerService:GetKey('Kick')

    local animationId = 'rbxassetid://139333593369314'
    local lastActivation = 0
    local cooldown = 0.5

    local function playAnimation(character)
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass('Animator') or humanoid:WaitForChild('Animator')
        local animation = Instance.new('Animation')
        animation.AnimationId = animationId
        local track = animator:LoadAnimation(animation)
        track:Play()
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode ~= Keybinds.InstaShot then return end
        if not Toggles.InstaShot then return end
        
        -- Cooldown check to prevent spam
        local currentTime = tick()
        if currentTime - lastActivation < cooldown then return end
        lastActivation = currentTime

        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local root = character:FindFirstChild('HumanoidRootPart')
        if not root or not humanoid then return end

        local camera = Workspace.CurrentCamera
        local direction = camera.CFrame.LookVector * 145
        local ballFolder = Workspace:FindFirstChild('Temp')
        local ball = ballFolder and ballFolder:FindFirstChild('Ball')
        if not ball then return end

        local args = {
            direction, ball, false, true, 100, 'Right', root.CFrame, {}, false, false
        }

        kickRemote:FireServer(table.unpack(args))
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        playAnimation(character)
    end)
end

--------------------------------------------------
-- HBE LOGIC (UI Toggle = HBE On/Off, P = Visual Sphere Toggle)
--------------------------------------------------
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local showSphere = true
    local manualSize = 15
    local currentSize = 15
    local originalCreate = nil
    local visualizer = nil

    local function updateVisualizer()
        if not Toggles.HBE then
            if visualizer then visualizer.Visible = false end
            return
        end

        local tempFolder = Workspace:FindFirstChild("Temp")
        local ball = tempFolder and tempFolder:FindFirstChild("Ball")
        local highlight = ball and ball:FindFirstChild("PossessionHighlight")

        if not highlight then
            currentSize = 7
        else
            currentSize = manualSize
        end

        if not ball or not showSphere then
            if visualizer then visualizer.Visible = false end
            return
        end

        if not visualizer then
            visualizer = Instance.new("SphereHandleAdornment")
            visualizer.Name = "HitboxVisual"
            visualizer.Color3 = Color3.fromRGB(0, 170, 255)
            visualizer.Transparency = 0.7
            visualizer.AlwaysOnTop = true
            visualizer.ZIndex = 10
            visualizer.Parent = workspace
        end

        visualizer.Visible = true
        visualizer.Adornee = ball
        visualizer.Radius = currentSize / 2
    end

    local function hook()
        local module = require(ReplicatedStorage.Modules.HitboxHandler)
        if originalCreate then return end

        originalCreate = module.Create
        module.Create = function(config)
            if Toggles.HBE then
                config.size = Vector3.new(currentSize, currentSize, currentSize)
            end
            return originalCreate(config)
        end
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        if input.KeyCode == Enum.KeyCode.P then
            showSphere = not showSphere
            if not showSphere and visualizer then 
                visualizer.Visible = false 
            end
        elseif input.KeyCode == Enum.KeyCode.Comma then
            manualSize = manualSize + 1
        elseif input.KeyCode == Enum.KeyCode.Period then
            manualSize = math.max(1, manualSize - 1)
        end
    end)

    RunService.RenderStepped:Connect(updateVisualizer)
    hook()
end

--------------------------------------------------
-- INSTA FLICK LOGIC (USES CHANGEABLE KEYBIND)
--------------------------------------------------
do
    local Players = game:GetService('Players')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local UserInputService = game:GetService('UserInputService')

    local Knit = require(ReplicatedStorage.Packages.Knit)
    local KeyHandlerService = Knit.GetService('KeyHandlerService')
    local KickRemote = KeyHandlerService:GetKey('Kick')

    local player = Players.LocalPlayer
    local mouse = player:GetMouse()

    local animation = Instance.new('Animation')
    animation.AnimationId = 'rbxassetid://15134077897'
    
    local lastActivation = 0
    local cooldown = 0.5

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode ~= Keybinds.InstaFlick then return end
        if not Toggles.InstaFlick then return end
        
        -- Cooldown check to prevent spam
        local currentTime = tick()
        if currentTime - lastActivation < cooldown then return end
        lastActivation = currentTime

        local ballFolder = workspace:FindFirstChild('Temp')
        if not ballFolder then return end
        local ball = ballFolder:FindFirstChild('Ball')
        if not ball then return end

        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass('Animator') or Instance.new('Animator', humanoid)

        local animationTrack = animator:LoadAnimation(animation)
        animationTrack:Play()

        local camera = workspace.CurrentCamera
        local mouseRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
        local targetPos = mouseRay.Origin + mouseRay.Direction * 1000
        local direction = (targetPos - ball.Position).Unit
        local force = 40

        local args = {
            direction * force, ball, false, false, force, 'Left',
            CFrame.new(ball.Position, targetPos), {}, false, false
        }
        KickRemote:FireServer(table.unpack(args))
    end)
end

--------------------------------------------------
-- DOUBLE TAP (USES CHANGEABLE KEYBIND)
--------------------------------------------------
do
    local Players = game:GetService('Players')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local UserInputService = game:GetService('UserInputService')
    local VirtualInputManager = game:GetService('VirtualInputManager')
    local Knit = require(ReplicatedStorage.Packages.Knit)

    local KeyHandlerService = Knit.GetService('KeyHandlerService')
    local KickRemote = KeyHandlerService:GetKey('Kick')
    local TapInRemote = KeyHandlerService:GetKey('TapInHit')

    local player = Players.LocalPlayer

    local CHIP_FORCE = 37.63837890769355
    local CHIP_VECTOR = Vector3.new(33.2738037109375, 27.290828704833984, -27.609731674194336)
    local CHIP_CFRAME = CFrame.new(216.23738, 12.676937, -96.496208, 0.6732608,0,-0.7394051,0,1,0,0.7394051,0,0.6732608)
    local CHIP_ANIM_ID = 'rbxassetid://15134077897'

    local DTAP_FORCE = 27.13375797914341
    local DTAP_VECTOR = Vector3.new(14.2802124, 21.8535023, 32.024025)
    local DTAP_ANIM_ID = 'rbxassetid://16859143160'
    
    local lastActivation = 0
    local cooldown = 1.5

    local function getBall()
        local folder = workspace:FindFirstChild('Temp')
        return folder and folder:FindFirstChild('Ball')
    end

    local function playAnimation(id)
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass('Humanoid')
        local animator = hum and (hum:FindFirstChildOfClass('Animator') or Instance.new('Animator', hum))
        if not animator then return end
        local anim = Instance.new('Animation')
        anim.AnimationId = id
        animator:LoadAnimation(anim):Play()
    end

    local function alignVector(vec)
        local camDir = workspace.CurrentCamera.CFrame.LookVector
        local flat = Vector3.new(camDir.X,0,camDir.Z).Unit
        local mag = Vector3.new(vec.X,0,vec.Z).Magnitude
        return Vector3.new(flat.X*mag, vec.Y, flat.Z*mag)
    end

    UserInputService.InputBegan:Connect(function(i,gp)
        if gp or i.KeyCode ~= Keybinds.DoubleTap then return end
        if not Toggles.DoubleTap then return end
        
        -- Cooldown check to prevent spam
        local currentTime = tick()
        if currentTime - lastActivation < cooldown then return end
        lastActivation = currentTime

        local ball = getBall()
        if not ball then return end

        playAnimation(CHIP_ANIM_ID)
        KickRemote:FireServer(
            alignVector(CHIP_VECTOR), ball, false, false,
            CHIP_FORCE, "Left", CHIP_CFRAME, {}, false, false
        )

        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

        task.wait(0.2)
        playAnimation(DTAP_ANIM_ID)
        TapInRemote:FireServer(ball, false, DTAP_FORCE, alignVector(DTAP_VECTOR), 'Right')
    end)
end

--------------------------------------------------
-- INFINITE STAMINA LOGIC
--------------------------------------------------
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    local function getStats()
        local container = workspace:WaitForChild("CharacterContainer")
        local char = container:WaitForChild(player.Name)
        local stats = char:WaitForChild("Stats")
        return stats:WaitForChild("Stamina"), stats:WaitForChild("MaxStamina")
    end

    RunService.Heartbeat:Connect(function()
        if not Toggles.InfiniteStamina then return end
        pcall(function()
            local stamina, maxStamina = getStats()
            stamina.Value = maxStamina.Value
        end)
    end)
end

--------------------------------------------------
-- FINAL SAFETY
--------------------------------------------------
if getgenv().RoffaHubLoaded then
    warn("RoffaHub already loaded")
    return
end
getgenv().RoffaHubLoaded = true
