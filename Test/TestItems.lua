-- RPE/Profile/TestItems.lua
-- Debug harness to test CharacterProfile inventory persistence.

RPE = RPE
RPE.Profile = RPE.Profile

local DB = RPE.Profile.DB
local CharacterProfile = assert(RPE.Profile.CharacterProfile, "CharacterProfile must be loaded first")

local function printInventory(profile, header)
    local hadAny = false
    profile:ForEachItem(function(id, qty)
        hadAny = true
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    local profile = DB.GetOrCreateActive()

    -- Seed example items only if inventory is empty
    if not profile.items or not next(profile.items) then
        profile:AddItem("cursed_ring", 1)
        profile:AddItem("longsword", 1)

        DB.SaveProfile(profile)
    end

    printInventory(profile)

end)
