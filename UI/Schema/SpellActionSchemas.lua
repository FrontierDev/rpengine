-- RPE/Core/SpellActionSchemas.lua
-- Central UI schema for spell action args used by the Spell Editor.
-- Keeps per-action fields small and explicit. Every action gets a 'targets' field.

RPE       = RPE or {}
RPE.Core  = RPE.Core or {}

local Schemas = {}
RPE.Core.SpellActionSchemas = Schemas

local COMMON = {
    targets = {
        id        = "targets",
        label     = "Targets",
        type      = "target_spec",
        required  = true,
        default   = { targeter = "PRECAST" },
    },
}

-- Shared lists - use damage schools from Common
local Common = RPE.Common or {}
local SCHOOLS = Common.DamageSchools or { "Physical","Fire","Ice","Lightning","Holy","Shadow","Arcane","Poison","Psychic","Nature" }

-- DAMAGE ---------------------------------------------------------------------
Schemas.DAMAGE = {
    key    = "DAMAGE",
    fields = {
        { id="amount",      label="Amount",       type="input",   required=true,  placeholder="$stat.MELEE_AP$ + 1d6" },
        { id="perRank",     label="Per Rank",     type="input",  required=false, placeholder="1d4" },
        { id="school",      label="School",       type="input",   required=false, placeholder="e.g. Physical, Fire, Ice" },
        { id="requiresHit", label="Requires Hit", type="checkbox", default=true },
        { id="hitModifier",  label="Hit Modifier",  type="input",   required=false, scope="action",
            placeholder="$stat.MELEE_HIT$"   },
        { id="hitThreshold", label="Hit Threshold(s)", type="input",
            scope="action", parse="csv",
            placeholder="$stat.DODGE$, $stat.PARRY$, $stat.BLOCK$"
        },
        { id="critModifier", label="Crit Modifier (%)", type="input", required=false, scope="action",
            placeholder="$stat.SPELL_CRIT$ or 5 (for 5%)" },
        { id="critMult",     label="Crit Multiplier",   type="input", required=false, scope="action",
            placeholder="$stat.CRIT_MULTIPLIER$ or 2 (default)" },
        { id="threat",      label="Threat",       type="input",  required=false,  placeholder="1" },
    },
}

-- HEAL -----------------------------------------------------------------------
Schemas.HEAL = {
    key    = "HEAL",
    fields = {
        { id="amount",  label="Amount",  type="input",  required=true, placeholder="e.g. 2d4+WIS or 6" },
        { id="perRank", label="Per Rank", type="number", required=false, min=0, max=9999, step=1, default=0 },
        { id="critModifier", label="Crit Modifier (%)", type="input", required=false, scope="action",
            placeholder="$stat.SPELL_CRIT$ or 5 (for 5%)" },
        { id="critMult",     label="Crit Multiplier",   type="input", required=false, scope="action",
            placeholder="$stat.CRIT_MULTIPLIER$ or 2 (default)" },
    },
}

-- APPLY_AURA -----------------------------------------------------------------
Schemas.APPLY_AURA = {
    key    = "APPLY_AURA",
    fields = {
        { id="auraId",  label="Aura ID", type="lookup", pattern="^aura%-[a-fA-F0-9]+$", required=true, placeholder="e.g. aura-c6e847e7" },
        { id="perRank", label="Per Rank", type="number", required=false, min=0, max=9999, step=1, default=0 },
    },
}

-- REDUCE_COOLDOWN ------------------------------------------------------------
Schemas.REDUCE_COOLDOWN = {
    key    = "REDUCE_COOLDOWN",
    fields = {
        { id="spellId", label="Spell ID", type="input",  required=true,  placeholder="e.g. HEALING_WORD" },
        { id="amount",  label="Amount",   type="number", required=true,  min=1, max=100, step=1, default=1 },
    },
}

-- SUMMON ----------------------------------------------------------------------
Schemas.SUMMON = {
    key    = "SUMMON",
    fields = {
        { id="npcId",     label="NPC ID",    type="lookup", pattern="^NPC%-[a-fA-F0-9]+$", required=true, placeholder="e.g. NPC-5e9204c0" },
    },
}

-- HIDE -----------------------------------------------------------------------
Schemas.HIDE = {
    key    = "HIDE",
    fields = {
        -- HIDE has no arguments; it hides the caster unit
    },
}

-- GAIN_RESOURCE -----------------------------------------------------------------------
Schemas.GAIN_RESOURCE = {
    key    = "GAIN_RESOURCE",
    fields = {
        { id="auraId",   label="Resource ID", type="input", required=true, placeholder="e.g. MANA or STAM" },
        { id="amount",   label="Amount",      type="input", required=true, placeholder="e.g. 5 or 1d4+STAT" },
    },
}

-- REMOVE_AURA ----------------------------------------------------------------
Schemas.REMOVE_AURA = {
    key    = "REMOVE_AURA",
    fields = {
        { id="auraId", label="Aura ID", type="input", required=true },
    },
}

-- SHIELD ---------------------------------------------------------------------
Schemas.SHIELD = {
    key    = "SHIELD",
    fields = {
        { id="amount",  label="Amount",  type="input",  required=true, placeholder="e.g. 10 or 1d10+PROF" },
        { id="perRank", label="Per Rank", type="number", required=false, min=0, max=9999, step=1, default=0 },
        { id="duration", label="Duration (turns)", type="number", required=false, min=1, max=100, step=1, default=1 },
    },
}

-- INTERRUPT ---------------------------------------------------------------
Schemas.INTERRUPT = {
    key    = "INTERRUPT",
    fields = {
        -- INTERRUPT has no arguments; it interrupts the target unit's spell casting
    },
}

-- TEAM_RESOURCE -----------------------------------------------------------
Schemas.TEAM_RESOURCE = {
    key    = "TEAM_RESOURCE",
    fields = {
        { id="amount", label="Amount", type="input", required=true, placeholder="e.g. 5 or 1d6+STAT" },
    },
}

-- RESURRECT ---------------------------------------------------------------
Schemas.RESURRECT = {
    key    = "RESURRECT",
    fields = {
        -- RESURRECT has no arguments; it revives dead targets to 10% HP
    },
}

-- ---------------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------------

function Schemas:Get(key)
    local def = self[key]
    if not def or type(def) ~= "table" then return nil end
    local out = { key = def.key or key, fields = {} }
    if def.fields then
        for i = 1, #def.fields do out.fields[i] = def.fields[i] end
    end
    out.fields[#out.fields+1] = COMMON.targets
    return out
end

function Schemas:AllKeys()
    local keys = {}
    for k, v in pairs(self) do
        if type(v) == "table" and v.key == k then keys[#keys+1] = k end
    end
    table.sort(keys)
    return keys
end

return Schemas
