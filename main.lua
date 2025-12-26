-- // CONFIGURATION //
local github_user = "beroshade"
local github_repo = "sixrose-assets"
local github_branch = "main"
local folderName = "sixrose_assets"
local EXT = ".mp3" 

-- This list now matches your GitHub screenshot exactly
local RequiredFiles = {
    "CashRegister.mp3", "Chip.mp3", "HoHoHo.mp3", "Hypercharge.mp3", 
    "Kick1.mp3", "Kick2.mp3", "Kick3.mp3", "Mariocoin.mp3", 
    "McXP.mp3", "Powershot.mp3", "Snap.mp3", "SoftBellSparkle.mp3", 
    "Sonic.mp3", "SqueakyToy.mp3", "Switch.mp3", "swoosh.mp3"
}

-- // AUTO-DOWNLOADER //
if not isfolder(folderName) then
    makefolder(folderName)
end

local baseUrl = "https://raw.githubusercontent.com/"..github_user.."/"..github_repo.."/"..github_branch.."/"

for _, fileName in ipairs(RequiredFiles) do
    local filePath = folderName .. "/" .. fileName
    if not isfile(filePath) then
        print("Downloading missing asset: " .. fileName)
        local success, content = pcall(function()
            return game:HttpGet(baseUrl .. fileName)
        end)
        
        if success and content and content ~= "404: Not Found" then
            writefile(filePath, content)
        else
            warn("Failed to download " .. fileName)
        end
    end
end

-- // MAIN LOGIC //
local RunService = game:GetService("RunService")
local handledSounds = {}
local lastPlayedIndices = {}

local netSounds = {
    {file = "SqueakyToy", vol = 5.0},
    {file = "SoftBellSparkle", vol = 5.5},
    {file = "Sonic", vol = 5.0},
    {file = "Snap", vol = 10.0}, 
    {file = "Switch", vol = 5.0},
    {file = "McXP", vol = 5.0},
    {file = "Mariocoin", vol = 5.0},
    {file = "Hypercharge", vol = 10.0},
    {file = "HoHoHo", vol = 2.0},
    {file = "CashRegister", vol = 3.0} -- Added this based on your screenshot
}

local function getBalancedNetSound()
    local availableIndices = {}
    for i = 1, #netSounds do
        local isRecentlyPlayed = false
        for _, lastIndex in ipairs(lastPlayedIndices) do
            if i == lastIndex then isRecentlyPlayed = true break end
        end
        if not isRecentlyPlayed then table.insert(availableIndices, i) end
    end
    local chosenIndex = availableIndices[math.random(1, #availableIndices)]
    table.insert(lastPlayedIndices, chosenIndex)
    if #lastPlayedIndices > 2 then table.remove(lastPlayedIndices, 1) end
    return netSounds[chosenIndex]
end

local muteOnlyList = {
    ["GroundSlam1"] = true,
    ["One Punch Man Punch Sound Effect"] = true,
    ["SLIDESFX"] = true,
    ["cloth-shuffle2"] = true,
    ["DistortionSoundEffect"] = true,
    ["EqualizerSoundEffect"] = true,
    ["whistleSFX"] = true,
    ["notification_sound_previs1"] = true
}

local function handleSound(sound)
    if not sound:IsA("Sound") then return end
    if handledSounds[sound] then return end
    handledSounds[sound] = true
    
    local name = sound.Name
    local isKick = string.match(name, "^Kick(%d+)")
    local isHeavier = string.match(name, "^heavierKick(%d+)")
    
    local fileName = nil
    local targetVol = 2.0 
    
    if name == "NetSFX" then
        local picked = getBalancedNetSound()
        fileName = picked.file .. EXT
        targetVol = picked.vol
    elseif name == "HeavyKick" then
        fileName = "Powershot" .. EXT
        targetVol = 5.0
    elseif isHeavier then
        fileName = "Chip" .. EXT
        targetVol = 3.0
    elseif name == "woosh" then
        fileName = "swoosh" .. EXT
        targetVol = 3.0
    elseif isKick then
        local num = tonumber(isKick)
        local myFileNumber = ((num - 1) % 3) + 1
        fileName = "Kick" .. myFileNumber .. EXT
    end

    if not fileName and muteOnlyList[name] then
        RunService.Stepped:Connect(function()
            if sound and sound.Parent then sound.Volume = 0 end
        end)
        return
    end

    if fileName then
        sound.Volume = 0
        local customSound = Instance.new("Sound")
        customSound.Name = "Custom_" .. name
        customSound.Looped = false
        
        -- Using pcall for getcustomasset in case the file hasn't finished writing
        local success, asset = pcall(function()
            return getcustomasset(folderName .. "/" .. fileName)
        end)
        
        if success then
            customSound.SoundId = asset
            customSound.Parent = sound.Parent
            customSound.Volume = targetVol

            local lastState = false
            local debounce = false

            local connection
            connection = RunService.Stepped:Connect(function()
                if not sound or not sound.Parent then
                    if customSound then customSound:Destroy() end
                    handledSounds[sound] = nil
                    connection:Disconnect()
                    return
                end

                if name == "woosh" then
                    local parent = sound.Parent
                    local heavierFound = false
                    if parent then
                        for _, child in ipairs(parent:GetChildren()) do
                            if string.match(child.Name, "^heavierKick") and child:IsA("Sound") and child.Playing then
                                heavierFound = true
                                break
                            end
                        end
                    end
                    
                    if heavierFound then
                        sound.Volume = 0
                        customSound.Volume = 0
                        if customSound.IsPlaying then customSound:Stop() end
                        return 
                    else
                        customSound.Volume = targetVol
                    end
                end

                sound.Volume = 0 
                
                if sound.Playing and not lastState and not debounce then
                    debounce = true
                    if name == "NetSFX" then
                        local picked = getBalancedNetSound()
                        customSound.SoundId = getcustomasset(folderName .. "/" .. picked.file .. EXT)
                        customSound.Volume = picked.vol
                    end
                    customSound.PlaybackSpeed = sound.PlaybackSpeed
                    customSound.TimePosition = 0
                    customSound:Play()
                    task.delay(0.05, function() debounce = false end)
                elseif not sound.Playing and lastState then
                    customSound:Stop()
                end
                lastState = sound.Playing
            end)
        end
    end
end

workspace.DescendantAdded:Connect(handleSound)
for _, v in ipairs(workspace:GetDescendants()) do
    handleSound(v)
end
