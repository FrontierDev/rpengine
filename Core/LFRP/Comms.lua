-- RPE/Core/LFRP/Comms.lua
RPE         = RPE or {}
RPE.Core    = RPE.Core or {}
RPE.Core.LFRP = RPE.Core.LFRP or {}

local Comms = RPE.Core.LFRP.Comms or {}
RPE.Core.LFRP.Comms = Comms

-- Get the channel name based on current date (lfrpe + DD/MM/YY in hex)
local function GetChannelName()
    local date = C_DateAndTime.GetCurrentCalendarTime()
    local day = string.format("%02X", date.monthDay)
    local month = string.format("%02X", date.month)
    local year = string.format("%02X", date.year % 100)
    return "lfrpe" .. day .. month .. year
end

-- Module state
local channelNumber = nil
local isChannelJoined = false
local isBroadcasting = false
local getSettingsCallback = nil

-- Initialize channel and handlers (called on login)
function Comms:InitializeChannelOnly()
    -- Attempt to join the channel
    self:JoinLFRPChannel()
    
    -- DO NOT start periodic broadcast - user must enable LFRP first
end

-- Start LFRP broadcasting (called when user enables)
function Comms:StartBroadcasting(getSettings)
    -- Store callback to get fresh settings each broadcast
    getSettingsCallback = getSettings
    isBroadcasting = true
    self:StartPeriodicBroadcast()
end

-- Stop LFRP broadcasting
function Comms:StopBroadcasting()
    isBroadcasting = false
    getSettingsCallback = nil
end

-- Join the LFRP channel (name based on current date in hex format)
function Comms:JoinLFRPChannel()
    local channelName = GetChannelName()
    -- Execute /join command with dynamic channel name
    ChatFrame1EditBox:SetText("/join " .. channelName)
    ChatEdit_SendText(ChatFrame1EditBox, 0)
    
    -- Wait a moment for the channel to be joined, then look it up
    C_Timer.After(0.5, function()
        local channelName = GetChannelName()
        -- Get list of channels (returns number, name, number, name, ...)
        local numChannels = select('#', GetChannelList())
        local i = 1
        while i <= numChannels do
            local chNum = select(i, GetChannelList())
            local chName = select(i + 1, GetChannelList())
            
            if chName and chName == channelName then
                channelNumber = chNum
                isChannelJoined = true
                Comms:TrySendHello()
                return
            end
            
            i = i + 2
        end
        
        -- Channel not found, try again in a moment
        C_Timer.After(0.5, function()
            Comms:JoinLFRPChannel()
        end)
    end)
end

-- Try to send "LFRP" hello signal if conditions are met (deprecated - just verify channel is ready)
function Comms:TrySendHello()
    if not isChannelJoined or not channelNumber then
        return
    end
    
    -- Just verify channel is ready - don't broadcast yet
    -- Broadcasting only happens when user enables LFRP
end

-- Send LFRP broadcasts (location and settings) to the rpelfrp channel
function Comms:SendLFRPBroadcast()
    if not isChannelJoined or not channelNumber then
        return
    end
    
    if not isBroadcasting or not getSettingsCallback then
        return
    end
    
    -- Get fresh settings (handle both callback functions and direct settings objects)
    local currentSettings
    if type(getSettingsCallback) == "function" then
        currentSettings = getSettingsCallback()
    else
        currentSettings = getSettingsCallback  -- direct settings table
    end
    
    if not currentSettings then
        return
    end
    
    local Location = RPE and RPE.Core and RPE.Core.Location
    local Broadcast = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    
    if not Location or not Broadcast then
        return
    end
    
    -- Get location
    local loc = Location:GetPlayerLocation()
    if loc then
        -- Send unified LFRP broadcast with location + settings in one message
        Broadcast:SendLFRPBroadcast(loc.mapID, loc.x, loc.y, currentSettings)
    end
end

-- Get the current channel number
function Comms:GetChannelNumber()
    return channelNumber
end

-- Check if channel is joined
function Comms:IsChannelJoined()
    return isChannelJoined
end

-- Send location removal broadcast on logout
function Comms:SendLocationRemoval()
    if not isChannelJoined or not channelNumber then
        return
    end
    
    local meName, meRealm = UnitName("player")
    local meFull = meName .. "-" .. (meRealm and meRealm ~= "" and meRealm or GetRealmName())
    meFull = meFull:gsub("%s+", "")
    
    local Broadcast = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast then
        Broadcast:SendLFRPLocationRemove(meFull)
    end
end

-- Start periodic location broadcasting (every 30 seconds)
function Comms:StartPeriodicBroadcast()
    local function BroadcastAndCleanup()
        -- Send current player location and settings
        if isChannelJoined and isBroadcasting then
            self:SendLFRPBroadcast()
        end
        
        -- Clean up stale pins (no broadcast in >45 seconds)
        local PinManager = RPE.Core and RPE.Core.LFRP and RPE.Core.LFRP.PinManager
        if PinManager then
            PinManager:RemoveStaleData(45)
        end
        
        -- Schedule next broadcast (only if still broadcasting)
        if isBroadcasting then
            C_Timer.After(30, BroadcastAndCleanup)
        end
    end
    
    -- Start the timer (delay first broadcast slightly to allow channel join)
    C_Timer.After(5, BroadcastAndCleanup)
end

-- Cleanup on unload
function Comms:Cleanup()
    -- Cleanup code here
end

return Comms
