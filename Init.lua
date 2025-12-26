-- RPEngine.lua
local ADDON_NAME = ...
local RPEngine = _G.RPE or {}
_G.RPE = RPEngine

-- Defaults
RPEngine.IsInitialised = false
RPEngine.AddonPrefix   = "RPE"
RPEngine.AddonName     = nil
RPEngine.AddonVersion  = nil

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
f:SetScript("OnEvent", function(_, event, loadedName)
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

    -- No longer need the listener
    f:UnregisterAllEvents()
end)
