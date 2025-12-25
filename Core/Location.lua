-- Location.lua
local Location = {}
_G.RPE.Core.Location = Location

--- Get the player's current location details
-- @return table with zone, x, y coordinates
function Location:GetPlayerLocation()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        return nil
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then
        return nil
    end

    local x, y = position:GetXY()
    
    return {
        zone = mapInfo.name,
        x = x * 100,
        y = y * 100,
        mapID = mapID,
    }
end

--- Get the player's location as a formatted string
-- @return string formatted as "Zone, X, Y"
function Location:GetPlayerLocationString()
    local loc = self:GetPlayerLocation()
    if not loc then
        return nil
    end
    return string.format("%s, %.3f, %.3f", loc.zone, loc.x, loc.y)
end

return Location
