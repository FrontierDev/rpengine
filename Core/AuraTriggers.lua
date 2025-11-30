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
    if not list then return end

    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[AuraTriggers] Emitting '%s' (source=%s, target=%s) to %d listener(s)"):format(
            event, tostring(sourceId), tostring(targetId), table.getn(list)))
    end

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

            local handle = self:On(eventName, function(ctx, sourceId, targetId, extra)
                if tonumber(sourceId) ~= tonumber(aura.sourceId) then return end

                local targets = {}
                if targetSpec == "SOURCE" or targetSpec == "self" then
                    targets = { sourceId }
                elseif targetSpec == "TARGET" or targetSpec == "target" then
                    targets = { targetId }
                elseif targetSpec == "both" then
                    targets = { sourceId, targetId }
                else
                    return
                end

                local runtimeArgs = {}
                for k, v in pairs(args) do runtimeArgs[k] = v end
                for k, v in pairs(snapshot) do runtimeArgs[k] = v end

                local cast = {
                    caster = sourceId,
                    profile = casterProfile,
                }

                if RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal(("[AuraTriggers] Aura '%s' triggered action '%s' on %d target(s) [%s]"):format(
                        def.id or "?", action.key, #targets, table.concat(targets, ", ")))
                end

                local ok, err = pcall(function()
                    SpellActions:Run(action.key, ctx or {}, cast, targets, runtimeArgs)
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
