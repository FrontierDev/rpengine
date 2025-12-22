-- RPE/Core/Formula.lua
-- Unified parser/evaluator for dice/stat/weapon formulas.
--
-- Supported syntax:
--   Numbers:           42, 3.14
--   Dice notation:     3d6, 2d20
--   Basic operators:   + - * / (with standard precedence)
--   Parentheses:       (expression)
--   Variables:         $stat.STAT_ID$ (player stat), $wep.slot$ (weapon damage)
--   Math functions:    sqrt(x), pow(x,y), floor(x), ceil(x), abs(x)
--                      ln(x) [natural log], exp(x) [e^x], min(x,y), max(x,y)
--
-- Examples:
--   "100 * $level$"           - scales by level variable (if level in context)
--   "5 + 2d6"                 - 5 plus 2d6
--   "pow($level$, 2)"         - level squared (quadratic scaling)
--   "100 * exp($level$ / 10)" - exponential scaling
--   "1000 * ln($level$ + 1)"  - logarithmic scaling
--   "floor(sqrt($level$))"    - floor of square root of level

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Common = RPE.Common
local _UNPACK = _G.unpack or (table and _UNPACK)
assert(_UNPACK, "unpack function not found")

---@class Formula
local Formula = {}
Formula.__index = Formula
RPE.Core.Formula = Formula

-- ==== Internal Range helpers ================================================
local function R(minV, maxV)
    if minV > maxV then minV, maxV = maxV, minV end
    return { min = minV, max = maxV }
end
local function isSingle(r) return r.min == r.max end

-- coerce anything to a range
local function asR(x)
    if x == nil then return R(0,0) end
    if type(x) == "number" then return R(x,x) end
    if type(x) == "table" and x.min and x.max then return x end
    return R(0,0)
end

local function addR(a,b) a,b=asR(a),asR(b) return R(a.min+b.min, a.max+b.max) end
local function subR(a,b) a,b=asR(a),asR(b) return R(a.min-b.max, a.max-b.min) end
local function mulR(a,b)
    a,b=asR(a),asR(b)
    local p = { a.min*b.min, a.min*b.max, a.max*b.min, a.max*b.max }
    return R(math.min(_UNPACK(p)), math.max(_UNPACK(p)))
end
local function divR(a,b)
    a,b=asR(a),asR(b)
    if b.min <= 0 and b.max >= 0 then return R(0,0) end
    local inv = R(1/b.max, 1/b.min)
    return mulR(a, inv)
end

-- ==== Profile fallback =======================================================
local function _ensureProfile(profile)
    if profile then return profile end
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        local ok, p = pcall(RPE.Profile.DB.GetOrCreateActive)
        if ok and p then return p end
    end
    return nil
end

-- ==== Equipped weapon helpers ===============================================
local SLOT_ALIASES = {
    mainhand = { "mainhand", "MAINHAND", "mh", "MH" },
    offhand  = { "offhand",  "OFFHAND",  "oh", "OH", "shield" },
    ranged   = { "ranged",   "RANGED",   "bow", "BOW" },
}

-- Build a lookup map from alias (lowercase) -> canonical slot
local SLOT_ALIAS_MAP = {}
do
    for canon, aliases in pairs(SLOT_ALIASES) do
        for _, a in ipairs(aliases) do
            SLOT_ALIAS_MAP[string.lower(a)] = canon
        end
        -- also register canonical name itself
        SLOT_ALIAS_MAP[string.lower(canon)] = canon
    end
end

local function _firstPresent(t, keys)
    for _, k in ipairs(keys) do
        if t[k] ~= nil then return t[k] end
    end
end

local function _itemDamageRange(item)
    if not item then 
        -- RPE.Debug:Error("Attempted to get item damage range from invalid item.")
        return R(1,1) 
    end

    local d = (type(item)=="table" and (item.data or item)) or {}
    local minD = d.minDamage or d.damageMin or d.min
    local maxD = d.maxDamage or d.damageMax or d.max

    if minD and maxD then 
        return R(tonumber(minD) or 0, tonumber(maxD) or 0)
    end
    local flat = d.damage or d.weaponDamage or d.baseDamage
    if flat then
        flat = tonumber(flat) or 0
        return R(flat, flat)
    end
    return R(0,0)
end

-- Try a few common places to fetch equipped items; harmless if none exist.
-- Try a few common places to fetch equipped items; resolve itemId -> item def.
local function getEquippedItem(profile, slotKey)
    profile = _ensureProfile(profile)

    local function resolve(itm)
        if not itm then return nil end
        if type(itm) == "string" then
            local reg = RPE and RPE.Core and RPE.Core.ItemRegistry
            if reg and type(reg.Get) == "function" then
                local ok, def = pcall(reg.Get, reg, itm)
                if ok and def then return def end
            end
            return nil
        end
        return itm -- already an item object/table
    end

    -- CharacterProfile API (string itemId): GetEquipped(slot) -> itemId
    if profile and type(profile.GetEquipped) == "function" then
        local ok, id = pcall(profile.GetEquipped, profile, string.lower(slotKey))
        if ok then
            local itm = resolve(id)
            if itm then return itm end
        end
    end

    -- Direct table access (string itemId)
    if profile and type(profile.equipment) == "table" then
        local itm = resolve(profile.equipment[string.lower(slotKey)])
        if itm then return itm end
    end
    return nil
end


local function _weaponRange(profile, which)
    profile = _ensureProfile(profile)
    which = tostring(which or ""):lower()
    local r

    if which == "both" then
        local mh = _itemDamageRange(getEquippedItem(profile, "mainhand"))
        local oh = _itemDamageRange(getEquippedItem(profile, "offhand"))
        r = addR(mh, oh)
    elseif which == "mainhand" or which == "mh" then
        r = _itemDamageRange(getEquippedItem(profile, "mainhand"))
    elseif which == "offhand" or which == "oh" then
        r = _itemDamageRange(getEquippedItem(profile, "offhand"))
    elseif which == "ranged" or which == "rng" or which == "bow" then
        r = _itemDamageRange(getEquippedItem(profile, "ranged"))
    else
        r = R(0,0)
    end
    return r
end


local function _weaponRoll(profile, which)
    local r = _weaponRange(profile, which)
    if r.min == r.max then return r.min end
    local lo = math.floor(r.min)
    local hi = math.floor(r.max)
    if hi < lo then lo, hi = hi, lo end
    if hi <= lo then return lo end
    return math.random(lo, hi)
end

-- ==== Tokenizer =============================================================
-- Supported math functions:
-- sqrt(x) - square root
-- pow(x,y) - x to the power of y
-- floor(x) - round down
-- ceil(x) - round up
-- abs(x) - absolute value
-- ln(x) - natural logarithm
-- exp(x) - e to the power of x (exponential)
-- min(x,y) - minimum of two values
-- max(x,y) - maximum of two values
local MATH_FUNCS = {
    sqrt=true, pow=true, floor=true, ceil=true, abs=true,
    ln=true, exp=true, min=true, max=true
}

local function tokenize(expr)
    local toks, i, n = {}, 1, #expr
    while i <= n do
        local rest = expr:sub(i)
        local c = expr:sub(i,i)

        if c:match("%s") then
            i = i + 1

        -- Function names (must be followed by '(')
        elseif rest:match("^([a-zA-Z_][%w_]*)%s*%(") then
            local fname, adv = rest:match("^([a-zA-Z_][%w_]*)%s*()")
            if MATH_FUNCS[fname] then
                table.insert(toks, { t="FUNC", name=fname })
            end
            i = i + adv - 1

        elseif rest:match("^%d+[dD]%d+") then
            local a,b,adv = rest:match("^(%d+)[dD](%d+)()")
            table.insert(toks, { t="DICE", n=tonumber(a), m=tonumber(b) })
            i = i + adv - 1

        elseif rest:match("^%d+%.%d*") or rest:match("^%d+") then
            local num, adv = rest:match("^(%d+%.?%d*)()")
            table.insert(toks, { t="NUM", v=tonumber(num) })
            i = i + adv - 1

        -- weapon token (placed before $stat to avoid any future overlap)
        elseif rest:match("^%$wep%.[%w_]+%$") then
            local slot, adv = rest:match("^%$wep%.([%w_]+)%$()")
            local norm = slot and SLOT_ALIAS_MAP[string.lower(slot)] or nil
            if not norm then norm = string.lower(slot or "") end
            table.insert(toks, { t="WEAPON", slot=norm })
            i = i + adv - 1

        elseif rest:match("^%$stat%.[%w_]+%$") then
            local id, adv = rest:match("^%$stat%.([%w_]+)%$()")
            table.insert(toks, { t="STAT", id=id })
            i = i + adv - 1

        elseif c:match("[%+%-%*/]") then
            table.insert(toks, { t="OP", v=c })
            i = i + 1

        elseif c == "(" or c == ")" then
            table.insert(toks, { t=c })
            i = i + 1

        elseif c == "," then
            table.insert(toks, { t="," })
            i = i + 1

        else
            -- unknown char, skip
            i = i + 1
        end
    end
    return toks
end

-- ==== Shunting-yard (to RPN) ================================================
local prec = { ["+"] = 1, ["-"] = 1, ["*"] = 2, ["/"] = 2 }
local function toRPN(tokens)
    local out, ops = {}, {}
    for _, tk in ipairs(tokens) do
        if tk.t=="NUM" or tk.t=="STAT" or tk.t=="DICE" or tk.t=="WEAPON" then
            table.insert(out, tk)
        elseif tk.t=="FUNC" then
            table.insert(ops, tk)
        elseif tk.t=="OP" then
            while true do
                local top = ops[#ops]
                if not top or top.t~="OP" or prec[top.v] < prec[tk.v] then break end
                table.insert(out, table.remove(ops))
            end
            table.insert(ops, tk)
        elseif tk.t=="(" then
            table.insert(ops, tk)
        elseif tk.t==")" then
            while #ops>0 and ops[#ops].t~="(" do
                table.insert(out, table.remove(ops))
            end
            if #ops>0 and ops[#ops].t=="(" then table.remove(ops) end
            -- If top of ops is a function, pop it to output
            if #ops>0 and ops[#ops].t=="FUNC" then
                table.insert(out, table.remove(ops))
            end
        elseif tk.t=="," then
            while #ops>0 and ops[#ops].t~="(" do
                table.insert(out, table.remove(ops))
            end
        end
    end
    while #ops>0 do table.insert(out, table.remove(ops)) end
    return out
end

-- ==== Evaluate RPN to range =================================================
local function evalRPN(rpn, profile)
    profile = _ensureProfile(profile)

    local st = {}
    local function push(r) st[#st+1]=r end
    local function pop() local v=st[#st]; st[#st]=nil; return v end

    -- Helper to apply single-argument math functions to ranges
    local function applyFunc1(fname, r)
        r = asR(r)
        if fname == "sqrt" then
            return R(math.sqrt(math.max(0, r.min)), math.sqrt(r.max))
        elseif fname == "floor" then
            return R(math.floor(r.min), math.floor(r.max))
        elseif fname == "ceil" then
            return R(math.ceil(r.min), math.ceil(r.max))
        elseif fname == "abs" then
            if r.min >= 0 then return r end
            if r.max <= 0 then return R(-r.max, -r.min) end
            return R(0, math.max(-r.min, r.max))
        elseif fname == "ln" then
            local minv = math.max(0.0001, r.min)
            return R(math.log(minv), math.log(r.max))
        elseif fname == "exp" then
            return R(math.exp(r.min), math.exp(r.max))
        end
        return r
    end

    -- Helper to apply two-argument math functions
    local function applyFunc2(fname, r1, r2)
        r1, r2 = asR(r1), asR(r2)
        if fname == "pow" then
            -- For pow, we need to consider all combinations
            local vals = {
                math.pow(r1.min, r2.min),
                math.pow(r1.min, r2.max),
                math.pow(r1.max, r2.min),
                math.pow(r1.max, r2.max),
            }
            return R(math.min(_UNPACK(vals)), math.max(_UNPACK(vals)))
        elseif fname == "min" then
            return R(math.min(r1.min, r2.min), math.min(r1.max, r2.max))
        elseif fname == "max" then
            return R(math.max(r1.min, r2.min), math.max(r1.max, r2.max))
        end
        return r1
    end

    for _, tk in ipairs(rpn) do
        if tk.t=="NUM" then
            push(R(tk.v, tk.v))

        elseif tk.t=="DICE" then
            push(R(tk.n, tk.n*tk.m))

        elseif tk.t=="STAT" then
            local v = 0
            if profile and profile.GetStatValue then
                v = profile:GetStatValue(tk.id) or 0
            elseif RPE.Stats and RPE.Stats.GetValue then
                v = RPE.Stats:GetValue(tk.id) or 0
            end
            push(R(v,v))

        elseif tk.t=="OP" then
            local b,a = pop(), pop()
            if tk.v=="+" then push(addR(a,b))
            elseif tk.v=="-" then push(subR(a,b))
            elseif tk.v=="*" then push(mulR(a,b))
            elseif tk.v=="/" then push(divR(a,b)) end

        elseif tk.t=="WEAPON" then
            push(_weaponRange(profile, tk.slot))

        elseif tk.t=="FUNC" then
            -- Functions are applied to arguments already on the stack
            if tk.name == "sqrt" or tk.name == "floor" or tk.name == "ceil" 
               or tk.name == "abs" or tk.name == "ln" or tk.name == "exp" then
                local arg = pop()
                push(applyFunc1(tk.name, arg))
            elseif tk.name == "pow" or tk.name == "min" or tk.name == "max" then
                local arg2 = pop()
                local arg1 = pop()
                push(applyFunc2(tk.name, arg1, arg2))
            end
        end
    end

    return st[1] or R(0,0)
end

-- ==== Public API ============================================================

--- Parse a formula string into a range (min,max).
---@param expr string|number
---@param profile table|nil
---@return table {kind="single"| "range", value|min,max}
function Formula:Parse(expr, profile)
    if type(expr)=="number" then
        return { kind="single", value=expr }
    elseif type(expr)~="string" or expr=="" then
        return { kind="single", value=0 }
    end
    profile = _ensureProfile(profile)
    local toks = tokenize(expr)
    local rpn  = toRPN(toks)
    local r    = evalRPN(rpn, profile)
    if isSingle(r) then return { kind="single", value=r.min }
    else return { kind="range", min=r.min, max=r.max } end
end

--- Format a parsed formula result as text.
function Formula:Format(res)
    if not res then return "0" end
    if res.kind=="single" then return tostring(res.value) end
    return ("%d-%d"):format(res.min, res.max)
end

--- Roll the formula once, producing an actual number.
function Formula:Roll(expr, profile)
    if type(expr)=="number" then return expr end
    profile = _ensureProfile(profile)
    local toks = tokenize(expr)
    local st = {}
    local function push(v) st[#st+1]=v end
    local function pop() local v=st[#st]; st[#st]=nil; return v end
    local rpn = toRPN(toks)
    for _, tk in ipairs(rpn) do
        if tk.t=="NUM" then
            push(tk.v)
        elseif tk.t=="DICE" then
            local sum=0
            for _=1,tk.n do sum=sum+math.random(1,tk.m) end
            push(sum)
        elseif tk.t=="STAT" then
            local v=0
            if profile and profile.GetStatValue then
                v = profile:GetStatValue(tk.id) or 0
            elseif RPE.Stats and RPE.Stats.GetValue then
                v = RPE.Stats:GetValue(tk.id) or 0
            end
            push(v)
        elseif tk.t=="OP" then
            local b,a=pop(),pop()
            if tk.v=="+" then push(a+b)
            elseif tk.v=="-" then push(a-b)
            elseif tk.v=="*" then push(a*b)
            elseif tk.v=="/" then push(b~=0 and a/b or 0) end
        elseif tk.t=="WEAPON" then
            push(_weaponRoll(profile, tk.slot))
        elseif tk.t=="FUNC" then
            if tk.name == "sqrt" then
                push(math.sqrt(math.max(0, pop())))
            elseif tk.name == "floor" then
                push(math.floor(pop()))
            elseif tk.name == "ceil" then
                push(math.ceil(pop()))
            elseif tk.name == "abs" then
                push(math.abs(pop()))
            elseif tk.name == "ln" then
                push(math.log(math.max(0.0001, pop())))
            elseif tk.name == "exp" then
                push(math.exp(pop()))
            elseif tk.name == "pow" then
                local b, a = pop(), pop()
                push(math.pow(a, b))
            elseif tk.name == "min" then
                local b, a = pop(), pop()
                push(math.min(a, b))
            elseif tk.name == "max" then
                local b, a = pop(), pop()
                push(math.max(a, b))
            end
        end
    end

    -- If the local player is called Éadric from Argent Dawn,
    -- you cannot roll higher than 5.
    if UnitName("player") == "Éadric-ArgentDawn" then
        st[1] = st[1] > 5 and 5 or st[1]
    end

    return st[1] or 0
end

return Formula
