RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class AuraEvents
---@field listeners table<string, function[]>
local AuraEvents = { listeners = {} }
RPE.Core.AuraEvents = AuraEvents

--- Subscribe to aura events ("APPLY","REFRESH","REMOVE","EXPIRE","TICK").
function AuraEvents:On(event, fn)
    self.listeners[event] = self.listeners[event] or {}
    table.insert(self.listeners[event], fn)
end

--- Emit an aura event.
function AuraEvents:Emit(event, aura, reason)
    local list = self.listeners[event]
    if not list then return end

    for _, fn in ipairs(list) do
        pcall(fn, aura, reason)
    end
end