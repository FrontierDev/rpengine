-- RPE/Core/SpellRequirements.lua
-- Spell requirement predicate evaluator.
-- Requirements can be strings in formats:
--   equip.SLOT - checks if player has any item equipped in SLOT
--   equip.SLOT.TYPE - checks if player has an item of TYPE in SLOT
--   inventory.ITEMID - checks if player has item ITEMID in inventory
--   requirement1 OR requirement2 - checks if at least one requirement passes

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class SpellRequirements
local SpellRequirements = {}
SpellRequirements.__index = SpellRequirements
RPE.Core.SpellRequirements = SpellRequirements

-- ===== Requirement String Evaluation =============================================

--- Check if player has item equipped in a slot.
--- Supports formats: "equip.SLOT" or "equip.SLOT.ITEMTYPE"
---@param ctx table - context with player unit info
---@param reqStr string - requirement string
---@return boolean ok, string? reason, string? code
local function check_equip(ctx, reqStr)
    -- Parse: equip.SLOT or equip.SLOT.TYPE
    local parts = {}
    for part in reqStr:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    if #parts < 2 then
        return false, "invalid equip format", "REQ_INVALID"
    end
    
    local slot = parts[2]:upper()
    local itemType = parts[3] and parts[3]:lower() or nil
    
    -- Get ItemRegistry to check equipped items
    local ItemRegistry = RPE and RPE.Core and RPE.Core.ItemRegistry
    if not ItemRegistry then
        return false, "ItemRegistry not available", "NO_REGISTRY"
    end
    
    -- Special case: "dual" means both mainhand and offhand equipped
    if slot == "DUAL" then
        local mh = ItemRegistry:GetEquipped("MAINHAND")
        local oh = ItemRegistry:GetEquipped("OFFHAND")
        if mh and oh then
            return true
        end
        return false, "not dual wielding", "NOT_DUAL"
    end
    
    -- Get the equipped item in the slot
    local equippedItem = ItemRegistry:GetEquipped(slot)
    if not equippedItem then
        return false, "no item equipped in " .. slot:lower(), "SLOT_EMPTY"
    end
    
    -- If no specific item type required, just check that slot is filled
    if not itemType then
        return true
    end
    
    -- Check if equipped item matches the required type
    local itemCategory = ""
    if equippedItem.data and equippedItem.data.weaponType then
        itemCategory = equippedItem.data.weaponType:lower()
    end
    if itemCategory == itemType then
        return true
    end
    
    return false, "equipped item is not " .. itemType, "WRONG_TYPE"
end

--- Check if player has a summoned unit of a specific type.
--- Format: "summoned.TYPE" (e.g., "summoned.Pet", "summoned.Minion")
---@param ctx table - context with event and caster info
---@param reqStr string - requirement string
---@return boolean ok, string? reason, string? code
local function check_summoned(ctx, reqStr)
    -- Parse: summoned.TYPE
    local parts = {}
    for part in reqStr:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    if #parts < 2 then
        return false, "invalid summoned format", "REQ_INVALID"
    end
    
    local requiredType = parts[2]:lower()
    
    -- Get the active event
    local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev.units) then
        return false, "event or units not available", "NO_EVENT"
    end
    
    -- Get the local player's unit ID
    local casterId = ev:GetLocalPlayerUnitId()
    if not casterId then
        return false, "caster not identified", "NO_CASTER"
    end
    
    -- Check if any unit was summoned by this caster and matches the type
    for _, unit in pairs(ev.units) do
        if unit.summonedBy and tonumber(unit.summonedBy) == tonumber(casterId) then
            local unitType = (unit.summonType or ""):lower()
            if unitType == requiredType then
                return true
            end
        end
    end
    
    return false, "no summoned unit of type " .. requiredType, "NO_SUMMONED"
end

--- Check if player has item in inventory.
--- Format: "inventory.ITEMID"
---@param ctx table - context with player inventory info
---@param reqStr string - requirement string
---@return boolean ok, string? reason, string? code
local function check_inventory(ctx, reqStr)
    -- Parse: inventory.ITEMID
    local parts = {}
    for part in reqStr:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    if #parts < 2 then
        return false, "invalid inventory format", "REQ_INVALID"
    end
    
    local itemId = parts[2]
    
    -- Get ItemRegistry to check inventory
    local ItemRegistry = RPE and RPE.Core and RPE.Core.ItemRegistry
    if not ItemRegistry then
        return false, "ItemRegistry not available", "NO_REGISTRY"
    end
    
    -- Try to get player profile for inventory check
    local profile = nil
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        local ok, p = pcall(RPE.Profile.DB.GetOrCreateActive)
        if ok and p then profile = p end
    end
    
    if not profile then
        return false, "profile not available", "NO_PROFILE"
    end
    
    -- Check if item exists in inventory
    -- Try profile:HasItem(itemId) if available
    if type(profile.HasItem) == "function" then
        local ok, hasIt = pcall(profile.HasItem, profile, itemId)
        if ok and hasIt then
            return true
        end
    end
    
    -- Try checking inventory table if available
    if type(profile.inventory) == "table" then
        for _, item in ipairs(profile.inventory) do
            if item and (item.id == itemId or tostring(item.id) == tostring(itemId)) then
                return true
            end
        end
    end
    
    return false, "item not in inventory", "NOT_IN_INVENTORY"
end

--- Check if the caster unit is hidden.
--- Format: "$hidden$"
---@param ctx table - context with caster unit info
---@param reqStr string - requirement string (expects "$hidden$")
---@return boolean ok, string? reason, string? code
local function check_hidden(ctx, reqStr)
    -- Get the caster unit from the active event
    local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
    if not ev then
        return false, "active event not available", "NO_EVENT"
    end
    
    -- Get the local player's unit ID
    local casterId = nil
    if ev.GetLocalPlayerUnitId and type(ev.GetLocalPlayerUnitId) == "function" then
        casterId = ev:GetLocalPlayerUnitId()
    end
    if not casterId then
        return false, "caster not identified", "NO_CASTER"
    end
    
    -- Find the caster unit
    local casterUnit = nil
    if ev.units then
        for _, unit in pairs(ev.units) do
            if unit.id == casterId then
                casterUnit = unit
                break
            end
        end
    end
    
    if not casterUnit then
        return false, "caster unit not found", "CASTER_NOT_FOUND"
    end
    
    -- Check if caster is hidden
    if casterUnit.hidden then
        return true
    end
    
    return false, "caster is not hidden", "NOT_HIDDEN"
end

--- Check if the caster does NOT have a summoned pet.
--- Format: "nosummoned"
---@param ctx table - context with caster unit info
---@param reqStr string - requirement string
---@return boolean ok, string? reason, string? code
local function check_no_summon(ctx, reqStr)
    -- Get the active event
    local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev.units) then
        return false, "event or units not available", "NO_EVENT"
    end
    
    -- Get the local player's unit ID
    local casterId = ev:GetLocalPlayerUnitId()
    if not casterId then
        return false, "caster not identified", "NO_CASTER"
    end
    
    -- Check if caster has a summoned unit of type "Pet"
    for _, unit in pairs(ev.units) do
        if unit.summonedBy and tonumber(unit.summonedBy) == tonumber(casterId) then
            return false, "caster has a pet", "HAS_PET"
        end
    end
    
    -- No pet found
    return true
end

--- Check if the caster is disengaged (not in combat).
--- Format: "disengaged"
---@param ctx table - context with caster unit info
---@param reqStr string - requirement string
---@return boolean ok, string? reason, string? code
local function check_disengaged(ctx, reqStr)
    -- Get the active event
    local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
    if not ev then
        return false, "active event not available", "NO_EVENT"
    end
    
    -- Get the local player's unit ID
    local casterId = nil
    if ev.GetLocalPlayerUnitId and type(ev.GetLocalPlayerUnitId) == "function" then
        casterId = ev:GetLocalPlayerUnitId()
    end
    if not casterId then
        return false, "caster not identified", "NO_CASTER"
    end
    
    -- Find the caster unit
    local casterUnit = nil
    if ev.units then
        for _, unit in pairs(ev.units) do
            if unit.id == casterId then
                casterUnit = unit
                break
            end
        end
    end
    
    if not casterUnit then
        return false, "caster unit not found", "CASTER_NOT_FOUND"
    end
    
    -- Check if caster is disengaged
    if casterUnit:IsDisengaged() then
        return true
    end
    
    return false, "caster is engaged in combat", "ENGAGED"
end

--- Evaluate a single requirement string.
---@param ctx table - context (player unit, equipment, inventory, etc.)
---@param reqStr string - requirement string to evaluate
---@return boolean ok, string? reason, string? code
function SpellRequirements:EvalRequirement(ctx, reqStr)
    if not reqStr or reqStr == "" then
        return true
    end
    
    reqStr = reqStr:match("^%s*(.-)%s*$") or reqStr  -- trim whitespace
    
    if reqStr:match("^equip%.") then
        return check_equip(ctx, reqStr)
    elseif reqStr:match("^summoned%.") then
        return check_summoned(ctx, reqStr)
    elseif reqStr:match("^inventory%.") then
        return check_inventory(ctx, reqStr)
    elseif reqStr == "hidden" then
        return check_hidden(ctx, reqStr)
    elseif reqStr == "disengaged" then
        return check_disengaged(ctx, reqStr)
    elseif reqStr == "nosummoned" then
        return check_no_summon(ctx, reqStr)
    else
        return false, "unknown requirement format "..tostring(reqStr), "REQ_UNKNOWN"
    end
end

--- Evaluate a requirement list (array of strings).
--- Each string can contain OR operators.
--- Returns true if ALL requirements pass (or if requirements list is empty).
---@param ctx table - context (player unit, equipment, inventory, etc.)
---@param requirements string[]|nil - array of requirement strings
---@return boolean ok, string? reason, string? code
function SpellRequirements:EvalRequirements(ctx, requirements)
    if not requirements or #requirements == 0 then
        return true
    end
    
    for _, reqStr in ipairs(requirements) do
        if type(reqStr) == "string" and reqStr ~= "" then
            -- Check for OR operators
            if reqStr:find(" OR ") then
                -- More reliable OR splitting
                local orSplit = {}
                local buffer = ""
                local i = 1
                while i <= #reqStr do
                    if i + 3 <= #reqStr and reqStr:sub(i, i+3) == " OR " then
                        if buffer ~= "" then
                            table.insert(orSplit, buffer)
                            buffer = ""
                        end
                        i = i + 4
                    else
                        buffer = buffer .. reqStr:sub(i, i)
                        i = i + 1
                    end
                end
                if buffer ~= "" then
                    table.insert(orSplit, buffer)
                end
                
                -- At least one OR clause must pass
                local anyPassed = false
                for _, orReq in ipairs(orSplit) do
                    local ok = self:EvalRequirement(ctx, orReq)
                    if ok then
                        anyPassed = true
                        break
                    end
                end
                
                if not anyPassed then
                    return false, "no requirement alternatives passed", "REQ_OR_FAILED"
                end
            else
                -- Single requirement - must pass
                local ok, reason, code = self:EvalRequirement(ctx, reqStr)
                if not ok then
                    return false, reason, code
                end
            end
        end
    end
    
    return true
end

-- ===== Backward Compatibility: Hardcoded Predicate Checks =====================

--- Backward compatibility: Evaluate hardcoded predicates.
--- Supports: HasResources, CooldownReady
---@param key string - predicate key
---@param ctx table|nil - context
---@param cast table|nil - cast info
---@param args table|nil - predicate arguments
---@return boolean ok, string? reason, string? code
function SpellRequirements:Eval(key, ctx, cast, args)
    ctx = ctx or {}
    args = args or {}
    
    if key == "HasResources" then
        if ctx.resources and ctx.resources.CanAfford then
            local costs = cast and cast._costSnapshot or (cast and cast.def and cast.def.costs) or {}
            return ctx.resources:CanAfford(costs), "insufficient resources", "NO_RES"
        end
        return true
    elseif key == "CooldownReady" then
        if ctx.cooldowns and ctx.cooldowns.IsReady and cast then
            return ctx.cooldowns:IsReady(cast.caster, cast.def), "cooldown", "CD_NOT_READY"
        end
        return true
    else
        return false, "unknown predicate "..tostring(key), "REQ_UNKNOWN"
    end
end

return SpellRequirements