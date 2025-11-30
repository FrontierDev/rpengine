-- Core.lua
local Core = {}
_G.RPE.Core = Core

RPE.Core.ImmersionMode = true

RPE.Core.Windows = RPE.Core.Windows or {}
RPE.Core.StatModifiers = {
    equip = {}, -- equip[profileId][statId] = number
    aura  = {}, -- aura[profileId][statId]  = number
}

-- Supergroup leadership flag (default solo => leader)
RPE.Core.isLeader = true

-- Blizzard party/raid leader takes precedence; otherwise use our supergroup flag.
function RPE.Core.IsLeader()
    if IsInRaid() or IsInGroup() then
        return UnitIsGroupLeader("player")
    end
    local v = RPE.Core.isLeader
    if v == nil then return true end
    return v and true or false
end