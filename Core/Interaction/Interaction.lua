-- RPE/Core/Interaction.lua
-- Defines an Interaction — a set of player options available when targeting an NPC.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Interaction
---@field id string             -- unique identifier for this interaction
---@field target string         -- NPC id or title this interaction applies to
---@field options table[]       -- list of options { label="Talk", action="OPEN_SHOP", args={...} }
local Interaction = {}
Interaction.__index = Interaction
RPE.Core.Interaction = Interaction

---Create a new Interaction definition.
---@param id string
---@param target string
---@param opts table|nil
function Interaction:New(id, target, opts)
    assert(type(id) == "string" and id ~= "", "Interaction id required")
    assert(type(target) == "string" and target ~= "", "Interaction target must be a string")
    opts = opts or {}

    local o = setmetatable({
        id      = id,
        target  = target,
        options = type(opts.options) == "table" and opts.options or {},
    }, self)
    return o
end

---Add a player-selectable option.
---@param label string
---@param action string
---@param args table|nil
function Interaction:AddOption(label, action, args)
    self.options = self.options or {}
    table.insert(self.options, {
        label = label,
        action = action,
        args = args or {},
    })
end

---Return whether this interaction applies to the given NPC.
---@param npcId string|number
---@param npcTitle string|nil
---@return boolean
function Interaction:Matches(npcId, npcTitle)
    local target = tostring(self.target or "")
    local idStr  = npcId and tostring(npcId) or ""
    local title  = npcTitle or ""
    return (target == idStr) or (target == title)
end

function Interaction:ToTable()
    return {
        id      = self.id,
        target  = self.target,
        options = self.options,
    }
end

function Interaction.FromTable(t)
    assert(type(t) == "table", "Interaction.FromTable expects table")
    return Interaction:New(t.id, t.target, {
        options = t.options,
    })
end

return Interaction
