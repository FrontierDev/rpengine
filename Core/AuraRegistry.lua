-- RPE/Core/AuraRegistry.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class AuraRegistry
---@field defs table<string, table>
---@field groups table<string, true>            -- unique groups seen
local AuraRegistry = { defs = {}, groups = {} }
RPE.Core.AuraRegistry = AuraRegistry

-- ===== Constants (authoring-time enums) =====
AuraRegistry.STACKING = {
    ADD_MAGNITUDE     = "ADD_MAGNITUDE",     -- add stacks, magnitude scales with stacks
    REFRESH_DURATION  = "REFRESH_DURATION",  -- re-apply resets full duration (keep stacks/magnitude)
    EXTEND_DURATION   = "EXTEND_DURATION",   -- add N turns (capped by optional max)
    REPLACE           = "REPLACE",           -- drop old instance(s), keep latest
}

AuraRegistry.CONFLICT = {
    NONE         = "NONE",         -- no exclusivity
    KEEP_HIGHER  = "KEEP_HIGHER",  -- within uniqueGroup choose higher magnitude
    KEEP_LATEST  = "KEEP_LATEST",  -- within uniqueGroup choose latest applied
    BLOCK_IF_PRESENT = "BLOCK_IF_PRESENT", -- if group present, block new
}

AuraRegistry.EXPIRE = {
    ON_OWNER_TURN_START = "ON_OWNER_TURN_START",
    ON_OWNER_TURN_END   = "ON_OWNER_TURN_END",
}

-- ===== API =====

function AuraRegistry:Init()
    if not self.defs then self.defs = {} end
    if not self.groups then self.groups = {} end
end

function AuraRegistry:Register(a, b)
    self:Init()

    local obj = nil
    if type(a) == "table" and a.id then
        -- direct Aura object
        obj = a
    elseif type(a) == "string" and type(b) == "table" then
        local src = {}
        for k, v in pairs(b) do src[k] = v end
        src.id = src.id or a

        if type(RPE.Core.Aura.FromTable) == "function" then
            local ok, s = pcall(RPE.Core.FromTable, src)
            if ok and s then obj = s end
        end

        if not obj then
            obj = src -- fallback: store raw table
        end
    else
        error("AuraRegistry:Register requires Aura or (id, defTable)")
    end

    assert(obj and obj.id, "AuraRegistry:Register: invalid object")
    self.defs[obj.id] = obj
end


function AuraRegistry:Get(id)
    self:Init()
    return self.defs[id]
end

---Return whether a group name is known.
---@param group string
---@return boolean
function AuraRegistry:HasGroup(group)
    return self.groups[group] or false
end

---Clear all definitions (used when reloading datasets).
function AuraRegistry:Clear()
    self.defs   = {}
    self.groups = {}
end

function AuraRegistry:RefreshFromActiveDatasets()
    self:Clear()
    local DB = RPE.Profile and RPE.Profile.DatasetDB
    local ds = DB and DB.LoadActiveForCurrentCharacter and DB.LoadActiveForCurrentCharacter()
    if not ds then return end
    for id, def in pairs(ds.auras or {}) do
        self:Register(id, def)
    end
end

function AuraRegistry:RefreshFromActiveDataset()
    return self:RefreshFromActiveDatasets()
end

-- Debug helper
SLASH_RPEAURAS1 = "/rpeauras"
SlashCmdList["RPEAURAS"] = function(msg)
    local AR = RPE and RPE.Core and RPE.Core.AuraRegistry
    if not AR then
        return
    end
    for id, def in pairs(AR.defs or {}) do
    end
end

return AuraRegistry

--[[
-- ===== Seed some default auras (starter set) =====
-- Call once at file load; pass true to force reseed (e.g., in tests/tools).
function AuraRegistry:SeedDefaults(force)
    if self._seeded and not force then return end
    self._seeded = true

    local AR = self

    -- 1) Minor Regeneration (HoT): small heal each turn, unique per caster
    AR:Register("HOT_REGEN_MINOR", {
        name         = "Regeneration",
        icon         = 134915,
        isHelpful    = true,
        description  = "Heals you each turn.",
        tags         = { "HEAL_OVER_TIME", "REGEN" },
        duration     = { turns = 3, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks    = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        uniqueByCaster = true,
        tick = {
            period  = 1, -- every turn
            -- Your SpellActions runner should handle HEAL
            actions = { { key = "HEAL", args = { amount = 6, school = "NATURE" } } },
        },
        modifiers    = {}, -- purely periodic
    })

    AR:Register("DOT_PYROBLAST", {
        name            = "Pyroblast Burn",
        icon            = 135826,            -- any burn icon
        isHelpful       = false,
        dispelType      = "MAGIC",           -- so it shows as a magic debuff
        tags            = { "FIRE", "BURN", "DOT" },
        duration        = { turns = 3, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks       = 1,
        stackingPolicy  = AR.STACKING.REFRESH_DURATION,
        uniqueByCaster  = true,
        tick = {
            period = 1,                      -- every turn (at owner’s turn start)
            actions = {
                { key = "DAMAGE", args = { school = "Fire" } }, -- amount comes from snapshot
            },
        },
        modifiers = {},                      -- pure DoT; no stat modifiers
    })

    -- 2) Minor Bleed (DoT): stacks up to 3, unique by caster, bleed-dispellable
    AR:Register("DOT_BLEED_MINOR", {
        name         = "Bleed",
        isHelpful    = false,
        dispelType   = "POISON",
        tags         = { "HARMFUL", "BLEED", "DOT" },
        duration     = { turns = 3, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks    = 3,
        stackingPolicy = AR.STACKING.ADD_MAGNITUDE, -- each reapply adds a stack, often refresh duration too
        uniqueByCaster = true,
        tick = {
            period  = 1,
            actions = { { key = "DAMAGE", args = { amount = 5, school = "PHYS" } } },
        },
        modifiers    = {}, -- periodic only; snapshotting left to runtime if you implement it
    })

    -- 3) Haste (minor): exclusive within "HASTE" group, keep higher
    AR:Register("HASTE_MINOR", {
        name           = "Haste (Minor)",
        isHelpful      = true,
        tags           = { "BUFF", "HASTE" },
        duration       = { turns = 3, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks      = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        uniqueGroup    = "HASTE",
        conflictPolicy = AR.CONFLICT.KEEP_HIGHER,
        modifiers      = {
            -- Your stat pipeline should interpret modes (e.g., PCT_ADD) and stat ids ("HASTE")
            { stat = "MELEE_AP", mode = "PCT_ADD", value = 100, snapshot = "DYNAMIC" },
        },
    })

    -- 4) Haste (major): same group; wins over minor due to higher magnitude
    AR:Register("HASTE_MAJOR", {
        name           = "Haste (Major)",
        isHelpful      = true,
        tags           = { "BUFF", "HASTE" },
        duration       = { turns = 2, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks      = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        uniqueGroup    = "HASTE",
        conflictPolicy = AR.CONFLICT.KEEP_HIGHER,
        modifiers      = {
            { stat = "HASTE", mode = "PCT_ADD", value = 25, snapshot = "DYNAMIC" },
        },
    })

    -- 5) Slow (minor): harmful magic, dispellable, reduces move speed
    AR:Register("SLOW_MINOR", {
        name           = "Slow",
        isHelpful      = false,
        dispelType     = "MAGIC",
        tags           = { "HARMFUL", "SLOW" },
        duration       = { turns = 2, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks      = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        modifiers      = {
            { stat = "MOVE_SPEED", mode = "PCT_ADD", value = -30, snapshot = "DYNAMIC" },
        },
    })

    -- 6) Vulnerability: increases damage taken from all sources
    AR:Register("VULNERABILITY", {
        name           = "Vulnerability",
        isHelpful      = false,
        dispelType     = "CURSE",
        tags           = { "HARMFUL", "DEBUFF" },
        duration       = { turns = 2, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks      = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        modifiers      = {
            { stat = "DAMAGE_TAKEN_PCT", mode = "PCT_ADD", value = 20, snapshot = "DYNAMIC" },
        },
    })

    -- 7) Fortify: reduces damage taken (defensive)
    AR:Register("FORTIFY", {
        name           = "Fortify",
        isHelpful      = true,
        tags           = { "BUFF", "DEFENSIVE" },
        duration       = { turns = 2, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks      = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        modifiers      = {
            { stat = "STA", mode = "ADD", value = 10, snapshot = "DYNAMIC" },
        },
        
        -- New: blocks incoming auras that match any of these
        immunity = {
            dispelTypes = { "BLEED", "POISON" },
            tags        = { "BURN", "SLOW" },
            ids         = { "DOT_PYROBLAST" },
            -- optional: helpful=false blocks harmful; harmful=false blocks helpful
            -- helpful = nil,
            -- harmful = nil,
        },
    })

    -- 8) Recently Healed (gating/internal): hidden, unpurgable, used to throttle effects
    AR:Register("RECENTLY_HEALED", {
        name         = "Recently Healed",
        isHelpful    = true,
        hidden       = true,
        unpurgable   = true,
        tags         = { "INTERNAL", "GATING" },
        duration     = { turns = 2, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks    = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        modifiers    = {},
    })

    -- 9) Root: prevents movement (your movement system should check for this tag/modifier)
    AR:Register("ROOT", {
        name           = "Root",
        isHelpful      = false,
        dispelType     = "MAGIC",
        tags           = { "HARMFUL", "CONTROL", "ROOT" },
        duration       = { turns = 1, expires = AR.EXPIRE.ON_OWNER_TURN_START },
        maxStacks      = 1,
        stackingPolicy = AR.STACKING.REFRESH_DURATION,
        -- If you drive movement via a stat flag, expose it here:
        -- { stat = "CAN_MOVE", mode = "SET_BOOL", value = 0 }
        modifiers      = {},
    })
end

-- Seed immediately on load
AuraRegistry:SeedDefaults()]]