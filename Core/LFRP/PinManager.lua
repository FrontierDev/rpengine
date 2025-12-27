-- LFRP/PinManager.lua - Manages pin creation and display on the world map

RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.LFRP = RPE.Core.LFRP or {}

---@class LFRPPinManager
local PinManager = {}
PinManager.__index = PinManager
RPE.Core.LFRP.PinManager = PinManager

local locationData = {}
local pinInstances = {}
local dataChangeCallbacks = {}

-- Cluster threshold in map coordinates (0-100 scale)
local CLUSTER_DISTANCE_THRESHOLD = 5

--- Register a callback to be called when location data changes
function PinManager:OnDataChange(callback)
    if type(callback) == "function" then
        table.insert(dataChangeCallbacks, callback)
    end
end

--- Notify all callbacks that data has changed
local function _notifyDataChange()
    for _, callback in ipairs(dataChangeCallbacks) do
        if type(callback) == "function" then
            local ok, err = pcall(callback)
            if not ok then
                RPE.Debug:Error("Error in LFRP data change callback: " .. tostring(err))
            end
        end
    end
end

--- Add a pin to the world map at the specified location
function PinManager:AddPin(mapID, x, y, icon, name, sender, broadcastLocation)
    broadcastLocation = broadcastLocation ~= false  -- default true
    
    -- Normalize sender to full name format (Name-Realm)
    if not sender:find("-") then
        sender = sender .. "-" .. (GetRealmName() or "")
        sender = sender:gsub("%s+", "")
    end
    
    -- Update existing pin if sender already has one
    for i, poi in ipairs(locationData) do
        if poi.sender == sender then
            locationData[i] = {
                position = CreateVector2D(x, y),
                icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\rpe.png",
                name = name,
                mapID = mapID,
                sender = sender,
                lastUpdate = GetTime(),
                broadcastLocation = broadcastLocation,
                lastBroadcastLocationTrue = GetTime(),  -- Track creation time; will update if broadcastLocation changes
                iAm = poi.iAm,
                lookingFor = poi.lookingFor,
                recruiting = poi.recruiting,
                approachable = poi.approachable,
            }
            self:RefreshAllData(WorldMapFrame)
            return
        end
    end
    
    -- Add new pin for this sender
    local poiInfo = {
        position = CreateVector2D(x, y),
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\rpe.png",
        name = name,
        mapID = mapID,
        sender = sender,
        lastUpdate = GetTime(),
        broadcastLocation = broadcastLocation,
        lastBroadcastLocationTrue = GetTime(),  -- Track creation time
        addonVersion = "unknown",
        dev = false,
        eventName = "",
    }
    table.insert(locationData, poiInfo)
    self:RefreshAllData(WorldMapFrame)
    _notifyDataChange()
end

--- Update a player's LFRP settings for their pin
function PinManager:UpdatePlayerSettings(senderName, settings)
    for i, poi in ipairs(locationData) do
        if poi.sender == senderName then
            poi.trpName = settings.trpName or ""
            poi.guildName = settings.guildName or ""
            poi.iAm = settings.iAm or {}
            poi.lookingFor = settings.lookingFor or {}
            poi.recruiting = settings.recruiting or 0
            poi.approachable = settings.approachable or 0
            poi.broadcastLocation = settings.broadcastLocation ~= false  -- default true
            poi.addonVersion = settings.addonVersion or "unknown"
            poi.dev = settings.dev or false
            poi.eventName = (settings.eventName and settings.eventName ~= "") and settings.eventName or ""
            -- Track the last time we received broadcastLocation=true
            if poi.broadcastLocation then
                poi.lastBroadcastLocationTrue = GetTime()
            end
            self:RefreshAllData(WorldMapFrame)
            _notifyDataChange()
            return
        end
    end
end

--- Remove all pins from the map
function PinManager:RemoveAllData()
    for i, pin in ipairs(pinInstances) do
        if pin and pin.frame then
            pin.frame:Hide()
            pin.frame = nil
        end
    end
    pinInstances = {}
end

--- Calculate distance between two positions (in 0-100 coordinates)
local function _distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--- Build clusters from visible locationData (filtered by current map)
local function _buildClusters(currentMapID)
    local clusters = {}
    local assigned = {}  -- Track which indices have been assigned to a cluster
    
    -- Get all visible pois on the current map
    local visiblePois = {}
    for i, poi in ipairs(locationData) do
        if poi.broadcastLocation and poi.mapID == currentMapID then
            table.insert(visiblePois, { index = i, poi = poi })
        end
    end
    
    -- Build clusters
    for idx, entry in ipairs(visiblePois) do
        if not assigned[entry.index] then
            local cluster = { members = {} }
            local x, y = entry.poi.position:GetXY()
            
            -- Add this poi to the cluster
            table.insert(cluster.members, entry.poi)
            assigned[entry.index] = true
            
            -- Find nearby pois within threshold
            for otherIdx, otherEntry in ipairs(visiblePois) do
                if not assigned[otherEntry.index] then
                    local ox, oy = otherEntry.poi.position:GetXY()
                    local dist = _distance(x, y, ox, oy)
                    
                    if dist <= CLUSTER_DISTANCE_THRESHOLD then
                        table.insert(cluster.members, otherEntry.poi)
                        assigned[otherEntry.index] = true
                    end
                end
            end
            
            table.insert(clusters, cluster)
        end
    end
    
    return clusters
end

--- Calculate center of mass for a cluster
local function _getCenterOfMass(cluster)
    local sumX, sumY = 0, 0
    for _, poi in ipairs(cluster.members) do
        local x, y = poi.position:GetXY()
        sumX = sumX + x
        sumY = sumY + y
    end
    local count = #cluster.members
    return sumX / count, sumY / count
end

--- Refresh all displayed pins on the map
function PinManager:RefreshAllData(map)
    self:RemoveAllData()
    
    if not locationData or #locationData == 0 then
        return
    end
    
    if not map then
        map = WorldMapFrame
    end
    
    -- Get the scroll container where pins are displayed
    local scrollContainer = map.ScrollContainer
    if not scrollContainer then
        return
    end
    
    local child = scrollContainer.Child
    if not child then
        return
    end
    
    -- Get PinLFRP at runtime
    local PinLFRP = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.PinLFRP
    if not PinLFRP then
        return
    end
    
    -- Get the current map ID from the world map
    local currentMapID = map:GetMapID()
    if not currentMapID then
        return
    end
    
    -- Build clusters filtered by current map
    local clusters = _buildClusters(currentMapID)
    
    for clusterIdx, cluster in ipairs(clusters) do
        -- Calculate center of mass
        local cx, cy = _getCenterOfMass(cluster)
        
        -- Normalize 0-100 coordinates to 0-1
        local nx, ny = cx / 100, cy / 100
        
        -- Create cluster pin
        local frameName = "LFRP_Cluster_" .. clusterIdx
        local pin = PinLFRP:New(frameName, {
            cluster = cluster,  -- Store cluster info
            currentPlayerIndex = 1,  -- Track which player's tooltip to show
        })
        if pin and pin.frame then
            -- Parent to the scroll container's child frame
            pin.frame:SetParent(child)
            pin.frame:SetFrameStrata("MEDIUM")
            pin.frame:SetFrameLevel(100)
            
            -- Position using normalized coordinates relative to child
            local offsetX = nx * child:GetWidth()
            local offsetY = ny * child:GetHeight()
            
            pin.frame:SetPoint("CENTER", child, "TOPLEFT", offsetX, -offsetY)
            pin.frame:Show()
            if pin.icon then
                pin.icon:Show()
            end
            table.insert(pinInstances, pin)
        end
    end
end

--- Hide all pins on the map
function PinManager:HidePins()
    for _, pin in ipairs(pinInstances) do
        if pin and pin.frame then
            pin.frame:Hide()
        end
    end
end

--- Show all pins on the map
function PinManager:ShowPins()
    for _, pin in ipairs(pinInstances) do
        if pin and pin.frame then
            pin.frame:Show()
        end
    end
end

--- Clear all pins and data
function PinManager:ClearPins()
    locationData = {}
    self:RemoveAllData()
end

--- Remove a pin by sender name
function PinManager:RemovePinBySender(senderName)
    for i = #locationData, 1, -1 do
        if locationData[i].sender == senderName then
            table.remove(locationData, i)
        end
    end
    self:RefreshAllData(WorldMapFrame)
end

--- Remove stale pins (older than timeoutSeconds)
--- Only removes pins if broadcastLocation was never true, or hasn't been true for timeoutSeconds
function PinManager:RemoveStaleData(timeoutSeconds)
    timeoutSeconds = timeoutSeconds or 45
    local now = GetTime()
    
    local hadRemoval = false
    for i = #locationData, 1, -1 do
        local poi = locationData[i]
        -- Skip own player's location (no sender)
        if poi.sender then
            -- If broadcastLocation was never set to true, or it's been >timeout since it was true
            local lastTrue = poi.lastBroadcastLocationTrue
            if not lastTrue or (now - lastTrue) > timeoutSeconds then
                RPE.Debug:Internal(string.format("[LFRP.PinManager] Removing stale pin for %s", poi.sender))
                table.remove(locationData, i)
                hadRemoval = true
            end
        end
    end
    
    if hadRemoval then
        self:RefreshAllData(WorldMapFrame)
        _notifyDataChange()
    end
end

--- Get location data (for browsing/display)
function PinManager:GetLocationData()
    return locationData
end

return PinManager
