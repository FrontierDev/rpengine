-- RPE/Core/AuraTriggers.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local SpellActions = assert(RPE.Core.SpellActions, "SpellActions required")

---@class AuraTriggers
---@field listeners table<string, table<integer, fun(ctx:table, sourceId:number, targetId:number, extra?:table)>>>
---@field nextId integer
local AuraTriggers = {
    listeners = {},  -- event -> list of functions
    nextId = 1,      -- unique handle id
}
RPE.Core.AuraTriggers = AuraTriggers

---@alias AuraTriggerHandle integer

--- Subscribe a callback to a trigger event.
--- @param event string              -- e.g. "ON_HIT"
--- @param fn fun(ctx:table, sourceId:number, targetId:number, extra?:table)
--- @return AuraTriggerHandle handle
function AuraTriggers:On(event, fn)
    assert(type(event) == "string", "Trigger event name must be string")
    assert(type(fn) == "function", "Trigger listener must be a function")
    self.listeners[event] = self.listeners[event] or {}
    local id = self.nextId
    self.nextId = self.nextId + 1
    self.listeners[event][id] = fn

    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[AuraTriggers] Registered listener for event '%s' (id %d)"):format(event, id))
    end

    return id
end

--- Unsubscribe a listener by handle.
--- @param event string
--- @param handle AuraTriggerHandle
function AuraTriggers:Off(event, handle)
    local list = self.listeners[event]
    if list and list[handle] then
        list[handle] = nil

        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[AuraTriggers] Unregistered listener %d from event '%s'"):format(handle, event))
        end
    end
end

--- Emit a trigger event (e.g. ON_HIT).
--- @param event string
--- @param ctx table
--- @param sourceId number
--- @param targetId number
--- @param extra table|nil
function AuraTriggers:Emit(event, ctx, sourceId, targetId, extra)
    local list = self.listeners[event]
    
    local listCount = 0
    if list then
        for _ in pairs(list) do listCount = listCount + 1 end
    end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[AuraTriggers] Emitting '%s' (source=%s, target=%s) to %d listener(s)"):format(
            event, tostring(sourceId), tostring(targetId), listCount))
    end

    -- Execute registered individual aura trigger callbacks
    if list then
        for _, fn in pairs(list) do
            if type(fn) == "function" then
                local ok, err = pcall(fn, ctx, sourceId, targetId, extra)
                if not ok and RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal("|cffff5555AuraTriggers listener error:|r " .. tostring(err))
                end
            end
        end
    end

    -- Also trigger via AuraManager for trigger event actions
    if RPE.Core.ActiveEvent and RPE.Core.ActiveEvent._auraManager then
        RPE.Core.ActiveEvent._auraManager:TriggerEvent(event, ctx, sourceId, targetId, extra)
    end
end

--- Register triggers from an aura definition.
--- Called from AuraManager:_onApplied(aura)
--- @param aura Aura
--- @return table<string, AuraTriggerHandle> map of event → handle
function AuraTriggers:RegisterFromAura(aura)
    local def = aura.def or {}
    if not def.triggers then return nil end

    local snapshot = aura.snapshot or {}
    local casterProfile = snapshot.profile
    local auraEventHandles = {}

    for _, trig in ipairs(def.triggers) do
        if trig.event and trig.action and trig.action.key then
            local eventName = trig.event
            local action = trig.action
            local args = action.args or {}
            local targetSpec = (action.targets and action.targets.ref) or "target"
            local auraId = aura.id
            local sourceId = aura.sourceId  -- Capture at registration time
            local targetId = aura.targetId

            local handle = self:On(eventName, function(ctx, eventSourceId, eventTargetId, extra)
                -- Check if this event is for the right unit based on event type
                -- For ON_HIT_TAKEN / *_TAKEN events: aura triggers when ITS TARGET unit is the one taking damage
                -- For other events: aura triggers when the event source matches the aura's source
                local shouldExecute = false
                if eventName:find("TAKEN") then
                    -- This aura triggers when targetId (unit the aura is on) takes damage
                    shouldExecute = (tonumber(eventTargetId) == tonumber(targetId))
                else
                    -- This aura triggers when its source deals damage/does something
                    shouldExecute = (tonumber(eventSourceId) == tonumber(sourceId))
                end
                
                if not shouldExecute then return end
                
                -- For ON_HIT and similar, verify the aura is still active
                if RPE.Core.ActiveEvent and RPE.Core.ActiveEvent._auraManager then
                    local auraManager = RPE.Core.ActiveEvent._auraManager
                    local stillActive = auraManager:Has(targetId, auraId)
                    if not stillActive then
                        if RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal(("[AuraTriggers] Aura '%s' no longer active, skipping trigger"):format(auraId))
                        end
                        return
                    end
                end

                local targets = {}
                local specUpper = (targetSpec or "TARGET"):upper()
                if specUpper == "SOURCE" or specUpper == "SELF" then
                    targets = { eventTargetId }
                elseif specUpper == "TARGET" then
                    targets = { eventSourceId }
                elseif specUpper == "BOTH" then
                    targets = { eventSourceId, eventTargetId }
                else
                    return
                end

                local runtimeArgs = {}
                for k, v in pairs(args) do runtimeArgs[k] = v end
                for k, v in pairs(snapshot) do runtimeArgs[k] = v end

                local cast = {
                    caster = eventSourceId,
                    profile = casterProfile,
                }

                if RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal(("[AuraTriggers] Aura '%s' triggered action '%s' on %d target(s) [%s]"):format(
                        auraId or "?", action.key, #targets, table.concat(targets, ", ")))
                end

                local ok, err = pcall(function()
                    if action.key == "GAIN_RESOURCE" then
                        -- Handle GAIN_RESOURCE action: add to current value
                        local Resources = RPE.Core and RPE.Core.Resources
                        if Resources then
                            local resourceId = runtimeArgs.resourceId
                            local amount = tonumber(runtimeArgs.amount) or 0
                            if RPE.Debug and RPE.Debug.Internal then
                                RPE.Debug:Internal(("[AuraTriggers] GAIN_RESOURCE: resourceId=%s, amount=%s"):format(
                                    tostring(resourceId), tostring(runtimeArgs.amount)))
                            end
                            if resourceId and amount > 0 then
                                local cur, max = Resources:Get(resourceId)
                                local newValue = math.min(cur + amount, max)
                                Resources:Set(resourceId, newValue)
                                if RPE.Debug and RPE.Debug.Internal then
                                    RPE.Debug:Internal(("[AuraTriggers] Gained %d %s (now %d/%d)"):format(amount, resourceId, newValue, max))
                                end
                            end
                        end
                    elseif action.key == "DAMAGE" then
                        -- Handle DAMAGE action from aura trigger
                        local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
                        if Broadcast then
                            local amount = 0
                            if type(runtimeArgs.amount) == "string" and RPE.Core.Formula then
                                amount = tonumber(RPE.Core.Formula:Roll(runtimeArgs.amount, casterProfile)) or 0
                            else
                                amount = tonumber(runtimeArgs.amount or 0)
                            end
                            amount = math.max(0, math.floor(amount))
                            if amount > 0 then
                                local school = runtimeArgs.school or "Physical"
                                for _, targetId in ipairs(targets) do
                                    Broadcast:Damage(eventSourceId, {
                                        { target = targetId, amount = amount, school = school }
                                    }, nil, { isFromAuraTrigger = true })
                                end
                            end
                        end
                    else
                        SpellActions:Run(action.key, ctx or {}, cast, targets, runtimeArgs)
                    end
                end)

                if not ok and RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal("|cffff5555AuraTriggers action error:|r " .. tostring(err))
                end
            end)

            auraEventHandles[eventName] = handle
        end
    end

    return auraEventHandles
end

--- Unregister previously registered aura triggers.
--- @param handles table<string, AuraTriggerHandle>
function AuraTriggers:Unregister(handles)
    if not handles then return end
    for event, id in pairs(handles) do
        self:Off(event, id)
    end
end

return AuraTriggers
