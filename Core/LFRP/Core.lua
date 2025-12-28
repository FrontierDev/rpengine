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
    -- Check if player has auto-rejoin enabled
    local ProfileDB = RPE and RPE.Profile and RPE.Profile.DB
    if ProfileDB then
        local profile = ProfileDB.GetOrCreateActive()
        if profile and profile:GetAutoRejoinLFRP() then
            -- Player has auto-rejoin enabled
            RPE.Core.LFRP.IsInitialized = true
            
            local Comms = RPE.Core.LFRP.Comms
            if Comms then
                -- Step 1: Leave the last channel if one was saved (player auto-rejoined it on login)
                local lastChannel = ProfileDB.GetLastLFRPChannel()
                if lastChannel and lastChannel ~= "" then
                    ChatFrame1EditBox:SetText("/leave " .. lastChannel)
                    ChatEdit_SendText(ChatFrame1EditBox, 0)
                    
                    -- Step 2: Clear the saved channel
                    ProfileDB.SetLastLFRPChannel(nil)
                end
                
                -- Step 3: After a delay, initialize system (which joins current date-based channel)
                C_Timer.After(1, function()
                    Comms:JoinLFRPChannel()
                    
                    -- Start broadcasting with saved settings
                    C_Timer.After(1.5, function()
                        if Comms and Comms.StartBroadcasting then
                            Comms:StartBroadcasting(function()
                                local LFRPSettingsSheet = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.LFRPSettingsSheet
                                if LFRPSettingsSheet and LFRPSettingsSheet.SerializeSettingsFromProfile then
                                    return LFRPSettingsSheet.SerializeSettingsFromProfile(profile)
                                end
                                return {}
                            end)
                        end
                    end)
                end)
            end
            
            if RPE.Debug then
                RPE.Debug:Print("[LFRP] Auto-rejoin enabled. Initializing LFRP system.")
            end
            return
        end
    end
    
    -- LFRP starts disabled - user must press Enable button to activate
    -- Channel joining is deferred until Enable button is pressed in LFRPWindow
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
