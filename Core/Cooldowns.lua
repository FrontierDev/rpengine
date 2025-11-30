-- RPE/Core/Cooldowns.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Cooldowns
---@field _store table<string, table<string, table>>  -- [casterKey][cdKey] = entry
---@field _bindings table<string, table[]>            -- [casterKey] = { {bar=<bar>} ... }
---@field _lastTurn integer
local Cooldowns = { _store = {}, _bindings = {}, _lastTurn = 0 }
Cooldowns.__index = Cooldowns
RPE.Core.Cooldowns = Cooldowns

-- Optional deps for bar refresh (safe if missing)
local SpellRegistry = RPE.Core.SpellRegistry
local ItemUse       = RPE.Core.ItemUse  -- may be nil if you haven't added item cooldowns yet

-- === Internal ===
local function getTurn(self) return self._lastTurn or 0 end
local function cdKeyFor(def)
    local cd = def and def.cooldown or {}
    if cd.sharedGroup and cd.sharedGroup ~= "" then return "G:" .. tostring(cd.sharedGroup) end
    return "S:" .. tostring(def.id or "?")
end
local function ensureEntry(self, caster, def)
    local casterKey = tostring(caster or "caster")
    local s = self._store[casterKey]; if not s then s = {}; self._store[casterKey] = s end
    local key = cdKeyFor(def)
    local e = s[key]
    if not e then
        local cd = def.cooldown or {}
        e = {
            readyTurn     = 0,
            maxCharges    = tonumber(cd.charges) or 0,
            rechargeTurns = tonumber(cd.rechargeTurns) or tonumber(cd.turns) or 0,
            recharges     = {},
        }
        s[key] = e
    end
    return e
end
local function pruneAndCountCharges(e, turn)
    if (e.maxCharges or 0) <= 0 then return 0, nil end
    local kept, nextReady = {}, nil
    for _, t in ipairs(e.recharges) do
        if t > turn then
            kept[#kept+1] = t
            if not nextReady or t < nextReady then nextReady = t end
        end
    end
    e.recharges = kept
    local active = #kept
    local available = math.max(0, (e.maxCharges or 0) - active)
    return available, nextReady
end

-- === Public: core timing ===
function Cooldowns:IsReady(caster, def, turn)
    if not def or not def.cooldown then return true end
    turn = tonumber(turn) or getTurn(self)
    local e = ensureEntry(self, caster, def)
    if (e.maxCharges or 0) > 0 then
        local avail = (select(1, pruneAndCountCharges(e, turn)))
        if avail >= 1 then return true end
        return false, "cooldown (no charges)", "CD_NOT_READY"
    else
        return (turn >= (e.readyTurn or 0)), "cooldown", "CD_NOT_READY"
    end
end

function Cooldowns:Start(caster, def, turn)
    if not def or not def.cooldown then return end
    turn = tonumber(turn) or getTurn(self)
    local cd = def.cooldown
    local e  = ensureEntry(self, caster, def)

    if (e.maxCharges or 0) > 0 then
        pruneAndCountCharges(e, turn)
        local recharge = tonumber(cd.rechargeTurns) or e.rechargeTurns or 0
        table.insert(e.recharges, turn + recharge)
    else
        local dur = tonumber(cd.turns) or 0
        e.readyTurn = turn + dur
    end

    -- compute the key that identifies this lockout (shared group OR specific id)
    local casterKey = tostring(caster or "caster")
    local cdKey     = cdKeyFor(def)
    local remain    = self:GetRemaining(caster, def, turn)

    -- push a precise update to widgets (they find the matching slot[s])
    self:_notifyBarsKey(casterKey, cdKey, remain)
end

function Cooldowns:GetRemaining(caster, def, turn)
    if not def or not def.cooldown then return 0 end
    turn = tonumber(turn) or getTurn(self)
    local e = ensureEntry(self, caster, def)
    if (e.maxCharges or 0) > 0 then
        local avail, nextReady = pruneAndCountCharges(e, turn)
        if avail >= 1 then return 0 end
        return math.max(0, (nextReady or turn) - turn)
    else
        return math.max(0, (e.readyTurn or 0) - turn)
    end
end


--- Reduce the remaining cooldown for a spell/group by `amount` turns (min 0).
---@param caster any
---@param def table|string  -- Spell def, or spellId; sharedGroup supported via def.cooldown.sharedGroup
---@param amount integer     -- turns to reduce
---@param turn integer|nil   -- current event turn
function Cooldowns:Reduce(caster, def, amount, turn)
    if type(def) == "string" then
        local reg = RPE.Core.SpellRegistry
        if reg and reg.Get then def = reg:Get(def) end
    end
    if not (def and def.cooldown) then return end

    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then return end

    turn = tonumber(turn) or getTurn(self)
    local e = ensureEntry(self, caster, def)

    if (e.maxCharges or 0) > 0 then
        -- Pull scheduled recharges sooner; any that cross 'turn' become available.
        local kept = {}
        for _, t in ipairs(e.recharges) do
            local nt = t - amount
            if nt > turn then
                kept[#kept+1] = nt
            end
            -- else: charge is back now; drop it from the list
        end
        table.sort(kept)
        e.recharges = kept
    else
        -- Simple lockout: bring readyTurn closer, but never before 'turn'
        e.readyTurn = math.max(turn, (e.readyTurn or turn) - amount)
    end

    -- Notify widgets the specific key changed
    local casterKey = tostring(caster or "caster")
    local cdKey     = cdKeyFor(def)
    local remain    = self:GetRemaining(caster, def, turn)

    if self._notifyBarsKey then
        self:_notifyBarsKey(casterKey, cdKey, remain)
    elseif self.RefreshBindingsFor then
        -- fallback if you're on the older path
        self:RefreshBindingsFor(casterKey, turn)
    end
end

-- === NEW: UI bindings & turn notifications ===
function Cooldowns:BindActionBar(casterKey, bar)
    casterKey = tostring(casterKey or "caster")
    self._bindings[casterKey] = self._bindings[casterKey] or {}
    -- avoid dup
    for _, b in ipairs(self._bindings[casterKey]) do if b.bar == bar then return end end
    table.insert(self._bindings[casterKey], { bar = bar })
    -- initial paint
    self:RefreshBindingsFor(casterKey, self._lastTurn or 0)
end

function Cooldowns:UnbindActionBar(bar)
    for ck, arr in pairs(self._bindings) do
        for i = #arr, 1, -1 do
            if arr[i].bar == bar then table.remove(arr, i) end
        end
        if #arr == 0 then self._bindings[ck] = nil end
    end
end


local function defForAction(a)
    if not a then return nil end
    -- Spells
    if a.spellId and SpellRegistry and SpellRegistry.Get then
        return SpellRegistry:Get(a.spellId)
    end
    -- Items (optional; only if ItemUse exists)
    if (a.type == "item" or a.itemId or a.id) and ItemUse and ItemUse.BuildCooldownDef then
        return ItemUse.BuildCooldownDef(a)
    end
    return nil
end

function Cooldowns:_refreshBar(bar, casterKey, turn)
    if not (bar and bar.SetTurnCooldown and bar.actions and bar.numSlots) then return end

    for i = 1, bar.numSlots do
        local a = bar.actions[i]
        local def = defForAction(a)
        if def and def.cooldown then
            local remain = self:GetRemaining(casterKey, def, turn)
            bar:SetTurnCooldown(i, remain)
        else
            bar:SetTurnCooldown(i, 0)
        end
    end
end

-- NEW: tell all bound bars for a caster about one cooldown key update
function Cooldowns:_notifyBarsKey(casterKey, cdKey, remaining)
    local casterKeyStr = tostring(casterKey or "caster")
    local list = self._bindings[casterKeyStr]
    if not list then return end
    for i, b in ipairs(list) do
        if b.bar and b.bar.ApplyCooldownKey then
            b.bar:ApplyCooldownKey(cdKey, remaining)
        end
    end
end

-- NEW: ask bars to fully refresh from Cooldowns (widget does the mapping)
function Cooldowns:_refreshBarsAll(casterKey, turn)
    local list = self._bindings[tostring(casterKey or "caster")]
    if not list then return end
    for _, b in ipairs(list) do
        if b.bar and b.bar.RefreshAllCooldowns then
            b.bar:RefreshAllCooldowns(casterKey, self, turn)
        end
    end
end


function Cooldowns:RefreshBindingsFor(casterKey, turn)
    local list = self._bindings[tostring(casterKey or "caster")]
    if not list then return end
    for _, b in ipairs(list) do 
        self:_refreshBar(b.bar, casterKey, turn) 
    end
end

--- Call this exactly once when the Event turn advances.
function Cooldowns:OnPlayerTickStart(newTurn)
    self._lastTurn = tonumber(newTurn) or (self._lastTurn or 0) + 1
    -- full repaint via widgets (they ask us per-slot)
    for casterKey, _ in pairs(self._bindings) do
        self:_refreshBarsAll(casterKey, self._lastTurn)
    end
end

return Cooldowns
