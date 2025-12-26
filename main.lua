-- HakaiseHub Script Executor
-- FULL ORIGINAL RESTORED WITH UI FIXES

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
-- GLOBAL TOGGLES (PERMISSION GATES)
--------------------------------------------------
local Toggles = {
    InfiniteM12 = false,
    InstaShot = false,
    HBE = false,
    InstaFlick = false,
    DoubleTap = false,       -- used in part 2
    AutoTopBins = false,     -- used in part 2
    DribbleSpeed = false,    -- used in part 2
    InfiniteStamina = false -- used in part 2
}

--------------------------------------------------
-- MAIN WINDOW (FIXED TOGGLE)
--------------------------------------------------
local window = ui.newWindow({
    text = 'HakaiseHub',
    resize = true,
    size = Vector2.new(550, 376),
})

-- RIGHT SHIFT TOGGLE ADDED HERE
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        window.visible = not window.visible
    end
end)

local menu = window:addMenu({ text = 'Scripts' })

-- EXTRA SCRIPTS MENU (FIXED)
local extraMenu = window:addMenu({ text = 'Extra Scripts' })

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
    if state then
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/beroshade/sixrose-assets/main/main.lua"
        ))()
    end
end)


----------------------------------------
-- Dribble Speed
----------------------------------------
local dribbleEnabled = false

extraSection:addToggle({
    text = 'Dribble Speed',
    default = false
}, function(state)
    dribbleEnabled = state
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
    if runSpeedMult.Value ~= v then runSpeedMult.Value = v end
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
-- Auto Top Bins (FIXED UI VISIBILITY)
----------------------------------------
_G.AutoBinsEnabled = false

-- We create the UI here but keep it DISABLED until the toggle is clicked
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local binsGui = Instance.new("ScreenGui")
binsGui.Name = "AutoBinsIndicator"
binsGui.ResetOnSpawn = false
binsGui.Enabled = false -- Start hidden
binsGui.Parent = playerGui

extraSection:addToggle({
    text = 'Auto Top Bins',
    default = false
}, function(state)
    _G.AutoBinsEnabled = state
    binsGui.Enabled = state -- Only shows when enabled
end)

----------------------------------------
-- Interpolation (NO TOGGLES)
----------------------------------------
extraSection:addButton({ text='15 Interpolation', style='large' }, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec","15") end)
end)

extraSection:addButton({ text='25 Interpolation', style='large' }, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec","25") end)
end)

extraSection:addButton({ text='45 Interpolation', style='large' }, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec","45") end)
end)

extraSection:addButton({ text='55 Interpolation', style='large' }, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec","55") end)
end)

local section = menu:addSection({
    text = 'Script Executor',
    side = 'auto',
    showMinButton = false
})

--------------------------------------------------
-- UI TOGGLES (NO INTERPOLATION HERE)
--------------------------------------------------
section:addToggle({ text = 'Infinite M1 / M2 (Z)' }, function(v)
    Toggles.InfiniteM12 = v
end)

section:addToggle({ text = 'Insta Shot (G)' }, function(v)
    Toggles.InstaShot = v
end)

section:addToggle({ text = 'HBE (0 / H / M / N)' }, function(v)
    Toggles.HBE = v
end)

section:addToggle({ text = 'Insta Flick (T)' }, function(v)
    Toggles.InstaFlick = v
end)

----------------------------------------
-- Infinite Stamina (PASTE HERE)
----------------------------------------

section:addToggle({
    text = 'Infinite Stamina',
    style = 'large'
}, function(state)
    Toggles.InfiniteStamina = state
end)

Toggles.InfiniteStamina = false

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
        local stamina, maxStamina = getStats()
        stamina.Value = maxStamina.Value
    end)
end
--------------------------------------------------
-- INFINITE M1 / M2 (ORIGINAL LOGIC, GATED)
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
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Z then
            holdingZ = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Z then
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
-- INSTA SHOT (ORIGINAL, GATED)
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
        if input.KeyCode ~= Enum.KeyCode.G then return end
        if not Toggles.InstaShot then return end

        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local root = character:FindFirstChild('HumanoidRootPart')
        if not root or not humanoid then return end

        local camera = Workspace.CurrentCamera
        local direction = camera.CFrame.LookVector * 200
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
-- HBE (FULL ORIGINAL SCRIPT, UI GATED)
--------------------------------------------------
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local scriptActive = true
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

        if not ball or not scriptActive or not showSphere then
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
            if Toggles.HBE and scriptActive then
                config.size = Vector3.new(currentSize, currentSize, currentSize)
            end
            return originalCreate(config)
        end
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not Toggles.HBE then return end

        if input.KeyCode == Enum.KeyCode.Zero then
            scriptActive = not scriptActive
        elseif input.KeyCode == Enum.KeyCode.H then
            showSphere = not showSphere
            if not showSphere and visualizer then visualizer.Visible = false end
        elseif input.KeyCode == Enum.KeyCode.M then
            manualSize = manualSize + 1
        elseif input.KeyCode == Enum.KeyCode.N then
            manualSize = math.max(1, manualSize - 1)
        end
    end)

    RunService.RenderStepped:Connect(updateVisualizer)
    hook()
end

--------------------------------------------------
-- INSTA FLICK (ORIGINAL, GATED)
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

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode ~= Enum.KeyCode.T then return end
        if not Toggles.InstaFlick then return end

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
-- DOUBLE TAP (P) — FULL ORIGINAL, UI GATED
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
    local inputKey = Enum.KeyCode.P

    local CHIP_FORCE = 37.63837890769355
    local CHIP_VECTOR = Vector3.new(33.2738037109375, 27.290828704833984, -27.609731674194336)
    local CHIP_CFRAME = CFrame.new(216.23738, 12.676937, -96.496208, 0.6732608,0,-0.7394051,0,1,0,0.7394051,0,0.6732608)
    local CHIP_ANIM_ID = 'rbxassetid://15134077897'

    local DTAP_FORCE = 27.13375797914341
    local DTAP_VECTOR = Vector3.new(14.2802124, 21.8535023, 32.024025)
    local DTAP_ANIM_ID = 'rbxassetid://16859143160'

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
        if gp or i.KeyCode ~= inputKey then return end
        if not Toggles.DoubleTap then return end

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
-- AUTO TOP BINS — FULL SCRIPT (UI FIXED)
--------------------------------------------------
_G.AutoBinsEnabled = _G.AutoBinsEnabled or false

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local Knit = require(ReplicatedStorage.Packages.Knit)
    task.spawn(function()
        pcall(function()
            Knit.OnStart():await()
        end)
    end)

    local KeyHandlerService = Knit.GetService("KeyHandlerService")
    local kickRemote = KeyHandlerService:GetKey("Kick")

    -- SETTINGS
    local FIRE_RANGE = 7
    local COOLDOWN = 1

    -- STATE
    local topEnabled = false
    local bottomEnabled = false
    local lastFire = 0

    -- UI INDICATOR (ALREADY CREATED IN TOP BINS SECTION ABOVE)
    local gui = binsGui

    local function mkLocal(y, text)
        local l = Instance.new("TextLabel")
        l.Parent = gui
        l.Size = UDim2.new(0, 100, 0, 26)
        l.Position = UDim2.new(1, -110, 0, y)
        l.BackgroundTransparency = 0.5
        l.BackgroundColor3 = Color3.new(0, 0, 0)
        l.TextScaled = true
        l.Font = Enum.Font.SourceSansBold
        l.Text = text
        return l
    end

    local topLbl = mkLocal(8, "TOP OFF")
    local botLbl = mkLocal(40, "BOT OFF")

    local function update()
        topLbl.Text = topEnabled and "TOP ON" or "TOP OFF"
        topLbl.TextColor3 = topEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

        botLbl.Text = bottomEnabled and "BOT ON" or "BOT OFF"
        botLbl.TextColor3 = bottomEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    end
    update()

    -- HELPERS
    local function getBall()
        local temp = Workspace:FindFirstChild("Temp")
        return temp and temp:FindFirstChild("Ball")
    end

    local function getField()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name == "Field" and v:FindFirstChild("GoalboxHome") then
                return v
            end
        end
    end

    local function getTarget(parts)
        local cam = Workspace.CurrentCamera
        local best, bestScore

        for _, p in ipairs(parts) do
            if p and p:IsA("BasePart") then
                local dir = (p.Position - cam.CFrame.Position).Unit
                local score = cam.CFrame.LookVector:Dot(dir)
                if not bestScore or score > bestScore then
                    bestScore = score
                    best = p
                end
            end
        end
        return best
    end

    local function getTopTarget()
        local f = getField()
        if not f then return end
        return getTarget({
            f.GoalboxHome:FindFirstChild("TOP RIGHT"),
            f.GoalboxHome:FindFirstChild("TOP LEFT"),
            f.GoalboxAway:FindFirstChild("TOP RIGHT"),
            f.GoalboxAway:FindFirstChild("TOP LEFT")
        })
    end

    local function getBottomTarget()
        local f = getField()
        if not f then return end
        return getTarget({
            f.GoalboxHome:FindFirstChild("BOTTOM RIGHT"),
            f.GoalboxHome:FindFirstChild("BOTTOM LEFT"),
            f.GoalboxAway:FindFirstChild("BOTTOM RIGHT"),
            f.GoalboxAway:FindFirstChild("BOTTOM LEFT")
        })
    end

    -- FIRE LOGIC
    local function fire(getTargetFunc)
        if not _G.AutoBinsEnabled then return end
        if tick() - lastFire < COOLDOWN then return end
        lastFire = tick()

        local ball = getBall()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not ball or not hrp or not hum then return end

        local target = getTargetFunc()
        if not target then return end

        -- FORCE CAMERA AIM
        local cam = Workspace.CurrentCamera
        cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)

        -- ALIGN CHARACTER
        hrp.CFrame = CFrame.new(
            hrp.Position,
            Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)
        )

        -- PLAY KICK ANIMATION
        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://118838549576967"
        animator:LoadAnimation(anim):Play()

        local dir = (target.Position - hrp.Position).Unit
        local side = hrp.CFrame.RightVector:Dot(ball.Position - hrp.Position) > 0 and "Right" or "Left"

        kickRemote:FireServer(
            dir * 200,
            ball,
            false,
            true,
            140,
            side,
            hrp.CFrame,
            { Enum.KeyCode.One },
            false,
            false
        )

        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    -- RENDER LOOP
    RunService.RenderStepped:Connect(function()
        if not _G.AutoBinsEnabled then return end

        local ball = getBall()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not ball or not hrp then return end
        if (ball.Position - hrp.Position).Magnitude > FIRE_RANGE then return end

        if topEnabled then
            fire(getTopTarget)
        elseif bottomEnabled then
            fire(getBottomTarget)
        end
    end)

    -- KEYBINDS
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not _G.AutoBinsEnabled then return end

        if input.KeyCode == Enum.KeyCode.One then
            topEnabled = not topEnabled
            bottomEnabled = false
            update()
        elseif input.KeyCode == Enum.KeyCode.Two then
            bottomEnabled = not bottomEnabled
            topEnabled = false
            update()
        end
    end)
end



--------------------------------------------------
-- DRIBBLE SPEED — FULL ORIGINAL, UI GATED
--------------------------------------------------
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")

    local runSpeedMult = ReplicatedStorage.PSSettings.RunSpeedMult
    local temp = Workspace.Temp

    local function set(v)
        if Toggles.DribbleSpeed then runSpeedMult.Value = v end
    end

    local function watch(ball)
        ball.ChildAdded:Connect(function(c)
            if c.Name=="PossessionHighlight" then set(1.15) end
        end)
        ball.ChildRemoved:Connect(function(c)
            if c.Name=="PossessionHighlight" then set(1) end
        end)
    end

    task.spawn(function()
        while true do
            local b=temp:WaitForChild("Ball")
            watch(b)
            b.AncestryChanged:Wait()
            set(1)
        end
    end)
end

--------------------------------------------------
-- INFINITE STAMINA — FULL ORIGINAL, UI GATED
--------------------------------------------------
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    RunService.Heartbeat:Connect(function()
        if not Toggles.InfiniteStamina then return end
        local stats = workspace.CharacterContainer[player.Name].Stats
        stats.Stamina.Value = stats.MaxStamina.Value
    end)
end
--------------------------------------------------
-- INTERPOLATION (BUTTONS ONLY — NO TOGGLES)
--------------------------------------------------
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local interpModule = require(ReplicatedStorage.Modules.InterpolationHandler)

    local interpSection = menu:addSection({
        text = "Interpolation",
        side = "auto",
        showMinButton = false
    })

    interpSection:addButton({ text = "Interpolation: Legit" }, function()
        interpModule.SetInterpolation(0.08)
    end)

    interpSection:addButton({ text = "Interpolation: Semi" }, function()
        interpModule.SetInterpolation(0.03)
    end)

    interpSection:addButton({ text = "Interpolation: Aggressive" }, function()
        interpModule.SetInterpolation(0)
    end)
end

--------------------------------------------------
-- UI INDICATOR SYNC (ON / OFF VISUAL SAFETY)
--------------------------------------------------
do
    -- This ensures toggles never desync visually
    for name, _ in pairs(Toggles) do
        Toggles[name] = Toggles[name] or false
    end
end

--------------------------------------------------
-- FINAL SAFETY WRAP
--------------------------------------------------
do
    -- Prevent duplicate execution if script is re-run
    if getgenv().HakaiseHubLoaded then
        warn("HakaiseHub already loaded")
        return
    end
    getgenv().HakaiseHubLoaded = true
end
------------------------------------------------
-- RESTORED FEATURES (PART 4)
------------------------------------------------

----------------------------------------
-- Custom Sounds
----------------------------------------
section:addButton({
    text = 'Custom Sounds',
    style = 'large'
}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/beroshade/sixrose-assets/main/main.lua"))()
end)

----------------------------------------
-- Dribble Speed
----------------------------------------
section:addButton({
    text = 'Dribble Speed',
    style = 'large'
}, function()
    loadstring([[ 
-- Dribble Speed (Full Working Version)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PSSettings = ReplicatedStorage:WaitForChild("PSSettings")
local runSpeedMult = PSSettings:WaitForChild("RunSpeedMult")
local temp = Workspace:WaitForChild("Temp")

local connections = {}
local ballConnections = {}

local function clear(tbl)
    for _, c in ipairs(tbl) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(tbl)
end

local function setSpeed(v)
    if runSpeedMult.Value ~= v then
        runSpeedMult.Value = v
    end
end

local function bindHighlight(inst)
    clear(connections)
    setSpeed(inst.Enabled and 1.15 or 1)

    table.insert(connections, inst:GetPropertyChangedSignal("Enabled"):Connect(function()
        setSpeed(inst.Enabled and 1.15 or 1)
    end))

    table.insert(connections, inst.AncestryChanged:Connect(function(_, p)
        if not p then
            clear(connections)
            setSpeed(1)
        end
    end))
end

local function watchBall(ball)
    clear(ballConnections)
    clear(connections)

    table.insert(ballConnections, ball.ChildAdded:Connect(function(c)
        if c.Name == "PossessionHighlight" then
            bindHighlight(c)
        end
    end))

    table.insert(ballConnections, ball.ChildRemoved:Connect(function(c)
        if c.Name == "PossessionHighlight" then
            clear(connections)
            setSpeed(1)
        end
    end))

    local h = ball:FindFirstChild("PossessionHighlight")
    if h then bindHighlight(h) else setSpeed(1) end

    table.insert(ballConnections, ball.AncestryChanged:Connect(function(_, p)
        if not p then
            clear(ballConnections)
            clear(connections)
            setSpeed(1)
            watchBall(temp:WaitForChild("Ball"))
        end
    end))
end

watchBall(temp:WaitForChild("Ball"))

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if cam and cam.FieldOfView > 80 then
        cam.FieldOfView = 80
    end
end)
]])()
end)


----------------------------------------
-- Auto Top Bins (UI ENABLED + KEYBINDS)
----------------------------------------
section:addButton({
    text = 'Auto Top Bins',
    style = 'large'
}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/your-autobins-source-here.lua"))()
end)

----------------------------------------
-- Interpolation (NO TOGGLES)
----------------------------------------
section:addButton({
    text = '15 Interpolation',
    style = 'large'
}, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec", "15") end)
end)

section:addButton({
    text = '25 Interpolation',
    style = 'large'
}, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec", "25") end)
end)

section:addButton({
    text = '45 Interpolation',
    style = 'large'
}, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec", "45") end)
end)

section:addButton({
    text = '55 Interpolation',
    style = 'large'
}, function()
    pcall(function() setfflag("InterpolationMaxDelayMSec", "55") end)
end)
-- RE-OPEN MAIN SECTION (REQUIRED)
local window = ui.windows[1]
local menu = window.menus[1]

local section = menu:addSection({
    text = 'Script Executor (Extra)',
    side = 'auto',
    showMinButton = false
})
----------------------------------------
-- Custom Sounds
----------------------------------------
section:addButton({
    text = 'Custom Sounds',
    style = 'large'
}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/beroshade/sixrose-assets/main/main.lua"))()
end)

----------------------------------------
-- Dribble Speed
----------------------------------------
section:addButton({
    text = 'Dribble Speed'
}, function() 
    -- Handled by toggle logic above
end)
