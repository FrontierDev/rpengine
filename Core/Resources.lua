-- RPE/Core/Resources.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Resources
---@field pool table<string, number>  -- [resourceId] = current value
local Resources = { pool = {} }
RPE.Core.Resources = Resources

-- === Internal ===

local function getProfile()
    return RPE.Profile.DB.GetOrCreateActive()
end

-- === Public API ===

--- Initialize resource pool to 50% of max values (for testing recovery).
function Resources:Init()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end

    self.pool = {}
    for id, stat in pairs(profile.stats or {}) do
        if stat.category == "RESOURCE" then
            local maxVal = stat:GetMaxValue(profile)

            if (id == "HEALTH") or (id == "MANA") then
                self.pool[string.upper(id)] = maxVal
            else
                self.pool[string.upper(id)] = 0
            end
        end
    end
end

function Resources:Has(resId)
    local profile = getProfile()
    local has = self.pool[resId] ~= nil or false
    return has
end

--- Get current + max for a resource.
function Resources:Get(resId)
    local profile = getProfile()
    local cur = self.pool[resId] or 0
    local max = (profile.stats[resId] and profile.stats[resId]:GetMaxValue(profile)) or 0
    return cur, max
end

Resources._lastMax = Resources._lastMax or {}
function Resources:Set(resId, value)
    local profile = getProfile()
    if not profile then return 0, 0 end
    local key = string.upper(tostring(resId or "")); if key == "" then return 0, 0 end

    -- compute current max from profile (auras/gear already applied to profile stats)
    local max = (profile.stats[key] and profile.stats[key]:GetMaxValue(profile)) or 0
    local v   = math.floor(tonumber(value) or 0)
    if max > 0 then v = math.max(0, math.min(v, max)) else v = math.max(0, v) end

    local prev   = self.pool[key] or 0
    local prevMx = self._lastMax[key] or -1

    if v ~= prev then
        self.pool[key] = v
        if RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
           and RPE.Core.Windows.PlayerUnitWidget.Refresh then
            RPE.Core.Windows.PlayerUnitWidget:Refresh()
        end
    end

    -- remember latest max and broadcast if HP or Max changed
    local maxChanged = (max ~= prevMx)
    self._lastMax[key] = max

    if key == "HEALTH" and (v ~= prev or maxChanged) then
        local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if B and B.UpdateUnitHealth then B:UpdateUnitHealth(nil, v, max) end
    end

    return v, max
end

local function evalCostAmount(spell, cost, profile)
    local Formula = RPE and RPE.Core and RPE.Core.Formula
    if not Formula then return tonumber(cost.amount) or 0 end

    local base = cost.amount and Formula:Roll(cost.amount, profile) or 0
    local perVal = 0
    local rank = (spell and tonumber(spell.rank or 1)) or 1
    if cost.perRank and cost.perRank ~= "" and rank > 1 then
        perVal = (Formula:Roll(cost.perRank, profile) or 0) * (rank - 1)
    end
    return base + perVal
end

--- Can the player afford these costs?
function Resources:CanAfford(costs, spell, profile)
    profile = profile or RPE.Profile.DB.GetOrCreateActive()
    for _, c in ipairs(costs or {}) do
        local need
        if spell then
            need = evalCostAmount(spell, c, profile)
        else
            need = tonumber(c.amount) or 0 -- fallback
        end
        local cur = self.pool[string.upper(c.resource)] or 0
        if cur < need then
            return false
        end
    end
    return true
end


--- Spend resource costs for a given phase.
function Resources:Spend(costs, when, spell, profile)
    profile = profile or RPE.Profile.DB.GetOrCreateActive()
    local refresh = false
    for _, c in ipairs(costs or {}) do
        if not c.when or c.when == when then
            local amt = spell and evalCostAmount(spell, c, profile) or (tonumber(c.amount) or 0)
            local key = string.upper(c.resource)
            self.pool[key] = math.max(0, (self.pool[key] or 0) - amt)
            local max = (profile.stats[key] and profile.stats[key]:GetMaxValue(profile)) or 0
            -- RPE.Debug:Print(("Spent %s %s → %d/%d remaining"):format(
            --     tostring(amt), key, self.pool[key], max
            -- ))
            refresh = true
        end
    end
    if refresh then RPE.Core.Windows.PlayerUnitWidget:Refresh() end
end


--- Refund costs marked with refundOnInterrupt.
function Resources:Refund(costs, spell, profile)
    profile = profile or RPE.Profile.DB.GetOrCreateActive()
    local refresh = false
    for _, c in ipairs(costs or {}) do
        if c.refundOnInterrupt then
            local amt = evalCostAmount(spell, c, profile)
            local key = string.upper(c.resource)
            local max = profile.stats[key] and profile.stats[key]:GetMaxValue(profile) or 0
            self.pool[key] = math.min(max, (self.pool[key] or 0) + amt)
            refresh = true
        end
    end
    if refresh then RPE.Core.Windows.PlayerUnitWidget:Refresh() end
end

--- Regenerate each turn according to recovery.
function Resources:OnPlayerTurnStart()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then 
        RPE.Debug:Error("Resources:OnPlayerTurnStart() fired but profile was not found.")
        return 
    end

    local refresh = false
    for id, stat in pairs(profile.stats or {}) do
        if stat.category == "RESOURCE" then
            local cur, max = self.pool[id] or 0, stat:GetMaxValue(profile)
            local regen = stat:GetRecovery(profile) or 0

            if regen ~= 0 then
                -- Round to nearest integer before clamping
                local newVal = math.floor(cur + regen + 0.5)
                self.pool[id] = math.min(max, newVal)

                -- RPE.Debug:Print(string.format(
                --     "Recovered %s %s this turn. (Current: %s)",
                --     regen, stat.name, self.pool[id]
                -- ))

                if id == "HEALTH" then
                    local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if B and B.UpdateUnitHealth then
                        B:UpdateUnitHealth(nil, self.pool[id], max)
                    end
                end

                refresh = true
            end
        end
    end

    if refresh then RPE.Core.Windows.PlayerUnitWidget:Refresh() end
end
