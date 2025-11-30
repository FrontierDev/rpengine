-- RPE/Core/ItemUse.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Cooldowns = assert(RPE.Core.Cooldowns, "Cooldowns required")

---@class ItemUse
local ItemUse = {}
RPE.Core.ItemUse = ItemUse

--- Build a cooldown def from an item action or inventory entry.
--- Supports per-template, per-instance, shared groups, charges, and simple turns.
function ItemUse.BuildCooldownDef(a)
    -- a can be: action-bar entry, inventory slot descriptor, etc.
    -- Prefer instance key if you want per-instance cooldowns:
    local id =
        a.cdKey
        or (a.instanceGuid and ("ITEMINST:" .. a.instanceGuid))
        or ("ITEM:" .. tostring(a.itemId or a.id or "unknown"))

    return {
        id = id,
        cooldown = {
            turns        = tonumber(a.cdTurns or 0),
            charges      = tonumber(a.charges),
            rechargeTurns= tonumber(a.rechargeTurns or a.cdTurns),
            sharedGroup  = a.sharedGroup,       -- e.g. "POTION", "HEALTH_CONS"
            starts       = "onUse",             -- items generally start on successful use
        },
    }
end

--- Convenience wrappers
function ItemUse.IsReady(casterKey, a, turn)
    local def = ItemUse.BuildCooldownDef(a)
    local ok, why, code = Cooldowns:IsReady(casterKey, def, turn)
    return ok, why, code, def
end

function ItemUse.Start(casterKey, a, turn)
    local def = ItemUse.BuildCooldownDef(a)
    Cooldowns:Start(casterKey, def, turn)
    return def
end

function ItemUse.GetRemaining(casterKey, a, turn)
    return Cooldowns:GetRemaining(casterKey, ItemUse.BuildCooldownDef(a), turn)
end

-- Optional helper for bars:
function ItemUse.RefreshBarSlotCooldown(bar, index, casterKey, a, turn)
    if not (bar and index and a) then return end
    local remain = ItemUse.GetRemaining(casterKey, a, turn)
    bar:SetTurnCooldown(index, remain)
end

return ItemUse
