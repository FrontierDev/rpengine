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

SLASH_RPETARGET1 = "/rpetarget"
SlashCmdList["RPETARGET"] = function(msg)
    local u = "target"
    if not UnitExists(u) or UnitIsPlayer(u) then
        return
    end

    -- Try to read NPC title from tooltip
    if not RPE_TempTooltip then
        RPE_TempTooltip = CreateFrame("GameTooltip", "RPE_TempTooltip", UIParent, "GameTooltipTemplate")
    end
    RPE_TempTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    RPE_TempTooltip:SetUnit(u)
    local title = _G["RPE_TempTooltipTextLeft2"] and _G["RPE_TempTooltipTextLeft2"]:GetText()
    RPE_TempTooltip:Hide()

    -- Base unit info
    local name  = UnitName(u) or "(unknown)"
    local guid  = UnitGUID(u) or "(no guid)"
    local id    = guid:match("-(%d+)-%x+$") or "?"
    local level = UnitLevel(u) or "??"
    local faction = UnitFactionGroup(u) or "(neutral)"
    local classif = UnitClassification(u) or "normal"
    local reaction = UnitReaction("player", u) or 0
    local health  = UnitHealth(u) or 0
    local healthMax = UnitHealthMax(u) or 0
    local dead    = UnitIsDead(u)
    local attackable = UnitCanAttack("player", u)
    local target  = UnitName(u .. "target") or "(none)"

end

