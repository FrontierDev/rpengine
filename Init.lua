-- RPEngine.lua
local ADDON_NAME = ...
local RPEngine = _G.RPE or {}
_G.RPE = RPEngine

-- Defaults
RPEngine.IsInitialised = false
RPEngine.AddonPrefix   = "RPE"
RPEngine.AddonName     = nil
RPEngine.AddonVersion  = nil

-- List of RPE developers (names that should have dev=true)
RPEngine.Developers = {
    "Angrune",  -- example developer
}

-- Check if the current player is a developer
function RPEngine.IsCurrentPlayerDeveloper()
    local playerName = UnitName("player")
    
    if not playerName then return false end
    
    for _, devName in ipairs(RPEngine.Developers) do
        if playerName == devName then
            return true
        end
    end
    return false
end

-- Track if we've already warned about a version mismatch
RPEngine._versionWarningShown = false

-- Function to check and warn about addon version mismatches (fires only once per session)
function RPEngine.AddonVersionWarning(senderName, senderVersion)
    if RPEngine._versionWarningShown then
        return
    end
    
    if not senderVersion or senderVersion == "unknown" or senderVersion == "" then
        return
    end
    
    local localVersion = RPEngine.AddonVersion or "unknown"
    if not localVersion or localVersion == "unknown" or localVersion == senderVersion then
        return
    end
    
    -- Parse versions and compare
    local function parseVersion(versionStr)
        local parts = {}
        for part in versionStr:gmatch("[^%.]+") do
            table.insert(parts, tonumber(part) or 0)
        end
        return parts
    end
    
    local senderParts = parseVersion(senderVersion)
    local localParts = parseVersion(localVersion)
    
    -- Check if sender's version is newer
    local senderNewer = false
    for i = 1, math.max(#senderParts, #localParts) do
        local senderNum = senderParts[i] or 0
        local localNum = localParts[i] or 0
        if senderNum > localNum then
            senderNewer = true
            break
        elseif senderNum < localNum then
            break
        end
    end
    
    if senderNewer then
        RPEngine._versionWarningShown = true
        if RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning(string.format("RPE addon update available! Another user has v%s, you have v%s. Update your addon immediately to prevent issues from occurring.", senderVersion, localVersion))
        end
    end
end

-- Small helper for metadata (Retail + fallback)
local function GetMeta(name, field)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, field)
    else
        return GetAddOnMetadata(name, field)
    end
end

-- One-time init when our addon loads
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, loadedName)
    if event == "ADDON_LOADED" then
        if loadedName ~= ADDON_NAME then return end

        RPEngine.AddonName    = ADDON_NAME
        RPEngine.AddonVersion = GetMeta(ADDON_NAME, "Version") or "dev"

        -- Register addon message prefix
        C_ChatInfo.RegisterAddonMessagePrefix(RPEngine.AddonPrefix)

        -- Finish initialisation
        RPEngine.IsInitialised = true
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Print(("Loaded %s v%s"):format(RPEngine.AddonName, RPEngine.AddonVersion))
        end
    elseif event == "PLAYER_LOGIN" then
        -- Create persistent AuraManager at login (lasts entire session)
        if RPE.Core and RPE.Core.AuraManager and not RPE._auraManager then
            RPE._auraManager = RPE.Core.AuraManager.New(nil, true)  -- skipTraits=true, will apply them in ProfileDB.InitializeUI
        end
    end
end)
