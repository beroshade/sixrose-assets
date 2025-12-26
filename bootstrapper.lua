local folderName = "sixrose_assets"
local github_user = "beroshade"
local github_repo = "sixrose-assets"

local RequiredFiles = {
    "CashRegister.mp3", "Chip.mp3", "HoHoHo.mp3", "Hypercharge.mp3", 
    "Kick1.mp3", "Kick2.mp3", "Kick3.mp3", "Mariocoin.mp3", 
    "McXP.mp3", "Powershot.mp3", "Snap.mp3", "SoftBellSparkle.mp3", 
    "Sonic.mp3", "SqueakyToy.mp3", "Switch.mp3", "swoosh.mp3"
}

if not isfolder(folderName) then makefolder(folderName) end

local baseUrl = "https://raw.githubusercontent.com/"..github_user.."/"..github_repo.."/main/"

-- Download assets
for _, fileName in ipairs(RequiredFiles) do
    if not isfile(folderName .. "/" .. fileName) then
        pcall(function()
            writefile(folderName .. "/" .. fileName, game:HttpGet(baseUrl .. fileName))
        end)
    end
end

-- Now run the main script
loadstring(game:HttpGet(baseUrl .. "main.lua"))()
