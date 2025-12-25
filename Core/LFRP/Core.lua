-- LFRP/Core.lua - Location-based Roleplay Core (Map provider lifecycle)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.LFRP = RPE.Core.LFRP or {}

local PinManager = RPE.Core.LFRP.PinManager
local Comms = RPE.Core.LFRP.Comms

---@class LFRPCore
local Core = CreateFromMixins(MapCanvasDataProviderMixin)
Core.__index = Core
RPE.Core.LFRP.Core = Core

--- Called when provider is added to the map
function Core:OnAdded(map)
    self.map = map
end

--- Called when provider is removed from the map
function Core:OnRemoved()
    self.map = nil
end

--- Get the map reference
function Core:GetMap()
    return self.map
end

--- Initialize the LFRP system
function Core:Initialize()
    if not WorldMapFrame then
        return
    end
    WorldMapFrame:AddDataProvider(self)
    self:RegisterLoginHandler()
end

--- Register the login and logout event handlers
function Core:RegisterLoginHandler()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            Core:OnPlayerLogin()
        elseif event == "PLAYER_LOGOUT" then
            Core:OnPlayerLogout()
        end
    end)
end

--- Called when player enters world
function Core:OnPlayerLogin()
    -- Initialize Comms FIRST to join channel and set up handlers
    -- Do NOT start periodic broadcast yet - user must enable LFRP first
    local CommsModule = RPE.Core.LFRP.Comms
    if CommsModule then
        CommsModule:InitializeChannelOnly()
    else
        RPE.Debug:Error("[LFRP.Core] Comms module not found!")
    end
    
    -- LFRP starts disabled - user must press Enable button to activate
    RPE.Core.LFRP.IsInitialized = false
end

--- Called when player logs out
function Core:OnPlayerLogout()
    local CommsModule = RPE.Core.LFRP.Comms
    if CommsModule then
        CommsModule:SendLocationRemoval()
    else
        RPE.Debug:Error("[LFRP.Core] Comms module not found!")
    end
end

--- Add player's location icon
function Core:AddPlayerLocationIcon()
    local Location = RPE and RPE.Core and RPE.Core.Location
    if not Location then
        return
    end

    local loc = Location:GetPlayerLocation()
    if not loc then
        return
    end
    
    local meName, meRealm = UnitName("player")
    local meFull = meName .. "-" .. (meRealm and meRealm ~= "" and meRealm or GetRealmName())
    meFull = meFull:gsub("%s+", "")
    
    if PinManager then
        PinManager:AddPin(loc.mapID, loc.x / 100, loc.y / 100, "Interface\\AddOns\\RPEngine\\UI\\Textures\\rpe.png", "Player Location", meFull)
    end
end

--- Called when map changes
function Core:OnMapChanged()
    if PinManager then
        PinManager:RefreshAllData(self:GetMap())
    end
end

-- Initialize on module load
Core:Initialize()

return Core
