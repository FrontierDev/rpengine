-- RPE/Core/Movement.lua
-- Tracks the local player's movement during their turn
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Movement
---@field isTracking boolean          -- Whether currently tracking movement
---@field totalDistance number        -- Total distance moved this turn
---@field maxDistance number          -- Maximum allowed distance for turn
---@field playerX number|nil          -- Last recorded X position
---@field playerY number|nil          -- Last recorded Y position
---@field multiplierTurn number       -- Current turn's movement multiplier
---@field storedMovement number       -- Stored movement from temporary reduction
local Movement = {
    isTracking = false,
    totalDistance = 0,
    maxDistance = 0,
    playerX = nil,
    playerY = nil,
    multiplierTurn = 1,
    storedMovement = 0
}
RPE.Core.Movement = Movement

-- === Helpers ===

local function GetPlayerPosition()
    local x, y = UnitPosition("player")
    return x, y
end

local function CheckDistance()
    if not Movement.isTracking then return end

    local newX, newY = GetPlayerPosition()
    if newX and newY then
        if Movement.playerX and Movement.playerY then
            local distance = math.sqrt((newX - Movement.playerX)^2 + (newY - Movement.playerY)^2)
            Movement.totalDistance = Movement.totalDistance + distance

            -- Update UI if callback exists
            if Movement.OnDistanceUpdate then
                Movement:OnDistanceUpdate(Movement.maxDistance - Movement.totalDistance, Movement.maxDistance)
            end

            if Movement.totalDistance >= Movement.maxDistance then
                if RPE.Debug then
                    RPE.Debug:Warning("You cannot run any further this turn!")
                end
                Movement:EndTracking()
                return
            end
        end
        Movement.playerX, Movement.playerY = newX, newY
    end
    C_Timer.After(1, CheckDistance) -- Schedule the next check in 1 second
end

-- === Public API ===

--- Check if currently tracking movement
---@return boolean
function Movement:IsTracking()
    return self.isTracking
end

--- Get current distance traveled this turn
---@return number
function Movement:GetTraveledDistance()
    return self.totalDistance
end

--- Get remaining distance allowed
---@return number
function Movement:GetRemainingDistance()
    return math.max(0, self.maxDistance - self.totalDistance)
end

--- Set the maximum distance allowed for this turn
---@param distance number
function Movement:SetMaxDistance(distance)
    self.maxDistance = distance
    if not self.isTracking then
        self:BeginTracking()
    end
end

--- Multiply the current max distance
---@param multiplier number
function Movement:MultiplyMaxDistance(multiplier)
    multiplier = tonumber(multiplier) or 1
    self.multiplierTurn = self.multiplierTurn * multiplier
    self.maxDistance = self.maxDistance * multiplier

    if not self.isTracking then
        self:BeginTracking()
    end
end

--- Temporarily reduce movement distance by a multiplier
---@param multiplier number The multiplier to apply (0.5 = half distance)
function Movement:TemporarilyReduce(multiplier)
    multiplier = tonumber(multiplier) or 1
    self.storedMovement = self.storedMovement + (self.maxDistance * (1 - multiplier))
    self:MultiplyMaxDistance(multiplier)
end

--- Restore movement distance from temporary reduction
function Movement:Restore()
    self.maxDistance = self.maxDistance + self.storedMovement
    self.storedMovement = 0
end

--- Refresh max distance based on speed stats
function Movement:RefreshMaxDistance()
    local speed = 0
    
    -- Try to get speed from the active player profile
    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
    if profile then
        speed = tonumber(profile:GetStatValue("SPEED")) or 0
    end
    
    -- Default to 30 if still 0 (reasonable default movement distance)
    if speed == 0 then
        speed = 30
    end
    
    self.maxDistance = speed * self.multiplierTurn
end

--- Begin tracking player movement
function Movement:BeginTracking()
    -- Don't track if movement system is disabled
    if not (RPE.ActiveRules and RPE.ActiveRules:Get("use_movement", false)) then
        return
    end
    
    self.totalDistance = 0
    self.multiplierTurn = 1
    self.storedMovement = 0
    self:RefreshMaxDistance()
    self.playerX, self.playerY = GetPlayerPosition()
    self.isTracking = true
    CheckDistance()
end

--- End tracking player movement
function Movement:EndTracking()
    self.isTracking = false
end

--- Called at the start of the player's turn
--- Initializes movement tracking with speed-based distance
function Movement:OnPlayerTurnStart()
    self:BeginTracking()
end

--- Called at the end of the player's turn
--- Cleans up movement tracking
function Movement:OnPlayerTurnEnd()
    self:EndTracking()
end

--- Optional callback when distance updates
--- Can be overridden to update UI
---@param remaining number
---@param maximum number
function Movement:OnDistanceUpdate(remaining, maximum)
    -- Override in subclasses or assign callback
end

return Movement
