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

--- Initialize resource pool to their base values from stat definitions.
function Resources:Init()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end

    self.pool = {}
    
    -- First, try to initialize from profile.stats
    local foundAny = false
    for id, stat in pairs(profile.stats or {}) do
        if stat.category == "RESOURCE" then
            local baseVal = stat:GetValue(profile)  -- Gets the full computed value (base + mods)
            self.pool[string.upper(id)] = baseVal
            foundAny = true
        end
    end
    
    -- Ensure always-used resources are always in the pool (even if not in profile.stats)
    -- HEALTH is always available; ACTION/BONUS_ACTION/REACTION only if allowed by rules
    if not self.pool["HEALTH"] then
        local stat = profile.stats and profile.stats["HEALTH"]
        if stat then
            self.pool["HEALTH"] = stat:GetValue(profile)
        else
            local StatRegistry = RPE.Core and RPE.Core.StatRegistry
            local statDef = StatRegistry and StatRegistry:Get("HEALTH")
            if statDef then
                self.pool["HEALTH"] = statDef.base or 0
            else
                self.pool["HEALTH"] = 100  -- Default HP
            end
        end
    end
    
    -- Check ActiveRules for ACTION, BONUS_ACTION, REACTION
    local ActiveRules = RPE.ActiveRules
    local actionLikeResources = { "ACTION", "BONUS_ACTION", "REACTION" }
    for _, resId in ipairs(actionLikeResources) do
        -- Only initialize if allowed by ruleset
        local allowed = ActiveRules and ActiveRules:IsStatEnabled(resId, "RESOURCE")
        if allowed and not self.pool[resId] then
            local stat = profile.stats and profile.stats[resId]
            if stat then
                self.pool[resId] = stat:GetValue(profile)
            else
                local StatRegistry = RPE.Core and RPE.Core.StatRegistry
                local statDef = StatRegistry and StatRegistry:Get(resId)
                if statDef then
                    self.pool[resId] = statDef.base or 0
                else
                    self.pool[resId] = 1  -- One action/bonus action/reaction per turn
                end
            end
        end
    end
    
    -- Fallback: if no resources found in profile.stats, initialize from StatRegistry definitions
    if not foundAny then
        local StatRegistry = RPE.Core and RPE.Core.StatRegistry
        if StatRegistry then
            local allStats = StatRegistry:All()
            for id, statDef in pairs(allStats or {}) do
                if statDef and statDef.category == "RESOURCE" then
                    local baseVal = statDef.base or 0
                    self.pool[string.upper(id)] = baseVal
                end
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
    
    -- Try to get stat from profile first
    local stat = profile and profile.stats and profile.stats[resId]
    local max = (stat and stat:GetMaxValue(profile)) or 0
    
    -- If max is 0 (stat missing), try to get it from StatRegistry definition
    if max == 0 then
        local StatRegistry = RPE.Core and RPE.Core.StatRegistry
        local statDef = StatRegistry and StatRegistry:Get(resId)
        if statDef and statDef.max then
            -- Get max value directly from definition
            if type(statDef.max) == "number" then
                max = statDef.max
            end
        end
    end
    
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
        -- Refresh the PlayerUnitWidget if it exists (it's a singleton instance)
        local PUW = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
        if PUW and PUW.Refresh then
            PUW:Refresh()
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(("[Resources:Set] Refreshed PlayerUnitWidget after %s change: %d -> %d"):format(key, prev, v))
            end
        end
    end

    -- remember latest max and broadcast if HP or Max changed
    local maxChanged = (max ~= prevMx)
    self._lastMax[key] = max

    if key == "HEALTH" and (v ~= prev or maxChanged) then
        local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
        if B and B.UpdateUnitHealth then
            -- Calculate total absorption from player's absorption shields
            local totalAbsorption = 0
            local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
            if ev then
                local localPlayerUnitId = ev:GetLocalPlayerUnitId()
                local localPlayerKey = ev.localPlayerKey
                if localPlayerKey and ev.units and ev.units[localPlayerKey] then
                    local playerUnit = ev.units[localPlayerKey]
                    if playerUnit.absorption then
                        for _, shield in pairs(playerUnit.absorption) do
                            if shield.amount then
                                totalAbsorption = totalAbsorption + shield.amount
                            end
                        end
                    end
                end
            end
            B:UpdateUnitHealth(nil, v, max, totalAbsorption)
        end
    end

    return v, max
end

--- Add to a resource's current value (clamped to max).
function Resources:Add(resId, amount)
    local cur, max = self:Get(resId)
    local newValue = math.min(cur + tonumber(amount or 0), max)
    return self:Set(resId, newValue)
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

--- Get the list of resources the player "uses" (checks for spell costs).
--- Always-used resources: HEALTH, ACTION, BONUS_ACTION, REACTION
function Resources:GetUsedResources(profile)
    profile = profile or RPE.Profile.DB.GetOrCreateActive()
    local usedSet = {}
    
    -- Get the 'use' list from profile settings (what the user has toggled on/off)
    local settings = {}
    if profile and profile.resourceDisplaySettings then
        local DatasetDB = RPE.Profile.DatasetDB
        local activeDatasets = DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter()
        local datasetKey = ""
        if activeDatasets and #activeDatasets > 0 then
            table.sort(activeDatasets)
            datasetKey = table.concat(activeDatasets, "|")
        else
            datasetKey = "none"
        end
        
        -- Normalize settings in case they're in old format
        settings = profile:_NormalizeResourceSettings(datasetKey)
    end
    
    -- If there's a use list, use it (it represents what the user has toggled on)
    if settings and settings.use and #settings.use > 0 then
        for _, resId in ipairs(settings.use) do
            usedSet[resId] = true
        end
    else
        -- If no custom use list, use defaults: HEALTH + action-like if allowed by rules
        usedSet["HEALTH"] = true
        
        local ActiveRules = RPE.ActiveRules
        if ActiveRules then
            local actionLikeResources = { "ACTION", "BONUS_ACTION", "REACTION" }
            for _, resId in ipairs(actionLikeResources) do
                local allowed = ActiveRules:IsStatEnabled(resId, "RESOURCE")
                if allowed then
                    usedSet[resId] = true
                end
            end
        else
            -- If no rules, include them by default
            usedSet["ACTION"] = true
            usedSet["BONUS_ACTION"] = true
            usedSet["REACTION"] = true
        end
    end
    
    return usedSet
end

--- Get the list of resources to display on the bar.
function Resources:GetDisplayedResources(profile)
    profile = profile or RPE.Profile.DB.GetOrCreateActive()
    
    local displayed = {}
    if profile and profile.resourceDisplaySettings then
        local DatasetDB = RPE.Profile.DatasetDB
        local activeDatasets = DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter()
        local datasetKey = ""
        if activeDatasets and #activeDatasets > 0 then
            table.sort(activeDatasets)
            datasetKey = table.concat(activeDatasets, "|")
        else
            datasetKey = "none"
        end
        
        -- Normalize settings in case they're in old format
        local settings = profile:_NormalizeResourceSettings(datasetKey)
        if settings and settings.show and #settings.show > 0 then
            displayed = settings.show
        end
    end
    
    -- If no custom display settings, use defaults
    if #displayed == 0 then
        displayed = { "HEALTH" }
        if profile and profile.stats and profile.stats["MANA"] then
            table.insert(displayed, "MANA")
        end
    end
    
    -- Filter out resources not allowed by ActiveRules
    local ActiveRules = RPE.ActiveRules
    local actionLikeResources = { "ACTION", "BONUS_ACTION", "REACTION" }
    local actionLikeSet = {}
    for _, resId in ipairs(actionLikeResources) do
        actionLikeSet[resId] = true
    end
    
    local filtered = {}
    for _, resId in ipairs(displayed) do
        -- Always show HEALTH; for action-like resources, check ActiveRules
        if resId == "HEALTH" or not actionLikeSet[resId] then
            table.insert(filtered, resId)
        elseif actionLikeSet[resId] then
            local allowed = ActiveRules and ActiveRules:IsStatEnabled(resId, "RESOURCE")
            if allowed then
                table.insert(filtered, resId)
            end
        end
    end
    
    return filtered
end

--- Can the player afford these costs (checking against 'used' resources)?
function Resources:CanAfford(costs, spell, profile)
    profile = profile or RPE.Profile.DB.GetOrCreateActive()
    local usedResources = self:GetUsedResources(profile)
    
    for _, c in ipairs(costs or {}) do
        local resId = string.upper(c.resource)
        
        -- Only check costs for resources the player "uses"
        if usedResources[resId] then
            local need
            if spell then
                need = evalCostAmount(spell, c, profile)
            else
                need = tonumber(c.amount) or 0 -- fallback
            end
            local cur = self.pool[resId] or 0
            if cur < need then
                return false
            end
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
    
    -- First, regenerate resources that are in profile.stats
    for id, stat in pairs(profile.stats or {}) do
        if stat.category == "RESOURCE" then
            local cur, max = self.pool[id] or 0, stat:GetMaxValue(profile)
            local regen = stat:GetRecovery(profile) or 0

            if regen ~= 0 then
                -- Round to nearest integer before clamping
                local newVal = math.floor(cur + regen + 0.5)
                self.pool[id] = math.min(max, newVal)

                if id == "HEALTH" then
                    local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if B and B.UpdateUnitHealth then
                        -- Calculate total absorption from player's absorption shields
                        local totalAbsorption = 0
                        local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
                        if ev then
                            local localPlayerKey = ev.localPlayerKey
                            if localPlayerKey and ev.units and ev.units[localPlayerKey] then
                                local playerUnit = ev.units[localPlayerKey]
                                if playerUnit.absorption then
                                    for _, shield in pairs(playerUnit.absorption) do
                                        if shield.amount then
                                            totalAbsorption = totalAbsorption + shield.amount
                                        end
                                    end
                                end
                            end
                        end
                        B:UpdateUnitHealth(nil, self.pool[id], max, totalAbsorption)
                    end
                end

                refresh = true
            end
        end
    end
    
    -- Handle always-used resources that might not be in profile.stats
    -- ACTION, BONUS_ACTION, REACTION restore to 1 per turn if allowed by rules
    local ActiveRules = RPE.ActiveRules
    local actionLikeResources = { "ACTION", "BONUS_ACTION", "REACTION" }
    for _, resId in ipairs(actionLikeResources) do
        -- Only regenerate if allowed by ruleset
        local allowed = ActiveRules and ActiveRules:IsStatEnabled(resId, "RESOURCE")
        if allowed then
            local cur = self.pool[resId] or 0
            local max = 1  -- ACTION/BONUS_ACTION/REACTION max out at 1
            if cur < max then
                self.pool[resId] = max
                refresh = true
            end
        end
    end

    if refresh then RPE.Core.Windows.PlayerUnitWidget:Refresh() end
end
