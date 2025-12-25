-- RPE/Profile/Dataset.lua
-- Data class for a transferrable game dataset (items, spells, auras, NPCs, ...).
-- No external serialization libs assumed. A simple pluggable serializer is scaffolded below.

RPE = RPE or {}
RPE.Profile = RPE.Profile or {}

---@class Dataset
---@field name string
---@field version number
---@field author string
---@field notes string
---@field description string
---@field guid string
---@field createdAt number
---@field updatedAt number
---@field securityLevel string
---@field items table<string, any>
---@field spells table<string, any>
---@field auras table<string, any>
---@field npcs table<string, any>
---@field recipes table<string, any>
---@field extra table<string, table<string, any>>
---@field setupWizard table|nil
local Dataset = {}
Dataset.__index = Dataset
RPE.Profile.Dataset = Dataset

-- -------- helpers -----------------------------------------------------------

local function _now() return (type(time)=="function" and time()) or 0 end

local function _mkGuid(name)
    local salt = math.random(1, 2^31 - 1)
    return (tostring(name):gsub("[^%w_%-]", "")) .. "-" .. tostring(_now()) .. "-" .. tostring(salt)
end

local function _sortedKeys(t)
    local keys = {}
    for k in pairs(t or {}) do keys[#keys+1] = k end
    table.sort(keys)
    return keys
end

-- Minimal table dumper (strings/numbers/booleans/tables) for default serialization.
local function _dump(tbl, buf, indent)
    buf   = buf or {}
    indent = indent or ""
    local nextIndent = indent .. "  "
    table.insert(buf, "{")
    local first = true
    for _, k in ipairs(_sortedKeys(tbl)) do
        local v = tbl[k]
        if not first then table.insert(buf, ",") end
        first = false
        table.insert(buf, "\n" .. nextIndent .. "[")
        if type(k) == "string" then
            table.insert(buf, string.format("%q", k))
        else
            table.insert(buf, tostring(k))
        end
        table.insert(buf, "]=")
        local tv = type(v)
        if tv == "string" then
            table.insert(buf, string.format("%q", v))
        elseif tv == "number" or tv == "boolean" then
            table.insert(buf, tostring(v))
        elseif tv == "table" then
            _dump(v, buf, nextIndent)
        else
            -- unsupported -> stringify
            table.insert(buf, string.format("%q", tostring(v)))
        end
    end
    table.insert(buf, "\n" .. indent .. "}")
    return table.concat(buf)
end

-- Simple Adler-32-like checksum (no bitops needed).
local function _adler32(str)
    local MOD = 65521
    local a, b = 1, 0
    for i = 1, #str do
        a = (a + string.byte(str, i)) % MOD
        b = (b + a) % MOD
    end
    return b * 65536 + a
end

-- -------- pluggable serializer scaffold ------------------------------------
-- Default serializer uses the _dump() text and loadstring() to rehydrate.
-- You can replace this at runtime with Dataset.SetSerializer(encodeFn, decodeFn).

Dataset._SER = {
    method = "S1", -- simple method tag
    encode = function(tbl)                -- -> string
        return _dump(tbl)
    end,
    decode = function(s)                  -- -> table or nil, err
        local chunk, err = loadstring("return " .. s)
        if not chunk then return nil, "parse error: " .. tostring(err) end
        local ok, tbl = pcall(chunk)
        if not ok or type(tbl) ~= "table" then
            return nil, "eval failed"
        end
        return tbl
    end
}

function Dataset.SetSerializer(encodeFn, decodeFn, methodTag)
    assert(type(encodeFn) == "function", "encodeFn required")
    assert(type(decodeFn) == "function", "decodeFn required")
    Dataset._SER = {
        method = methodTag or "S1",
        encode = encodeFn,
        decode = decodeFn,
    }
end

-- -------- ctor --------------------------------------------------------------

---@param name string
---@param opts table|nil
function Dataset:New(name, opts)
    assert(type(name) == "string" and name ~= "", "Dataset: name required")
    opts = opts or {}
    local now = _now()
    local o = setmetatable({
        name      = name,
        version   = tonumber(opts.version) or 1,
        author    = opts.author or "",
        notes     = opts.notes or "",
        description = opts.description or "",
        guid      = opts.guid or _mkGuid(name),
        createdAt = tonumber(opts.createdAt) or now,
        updatedAt = tonumber(opts.updatedAt) or now,
        securityLevel = opts.securityLevel or "Open",

        items  = type(opts.items)  == "table" and opts.items  or {},
        spells = type(opts.spells) == "table" and opts.spells or {},
        auras  = type(opts.auras)  == "table" and opts.auras  or {},
        npcs   = type(opts.npcs)   == "table" and opts.npcs   or {},
        recipes = type(opts.recipes) == "table" and opts.recipes or {},
        extra  = type(opts.extra)  == "table" and opts.extra  or {},
        setupWizard = type(opts.setupWizard) == "table" and opts.setupWizard or nil,
    }, self)
    return o
end

-- -------- accessors ---------------------------------------------------------

function Dataset:Touch()
    self.updatedAt = _now()
end

function Dataset:GetCategory(category)
    if category == "items"  then return self.items end
    if category == "spells" then return self.spells end
    if category == "auras"  then return self.auras end
    if category == "npcs"   then return self.npcs end
    self.extra[category] = self.extra[category] or {}
    return self.extra[category]
end

function Dataset:Set(category, id, def)
    assert(type(id) == "string" and id ~= "", "Dataset:Set requires string id")
    local bucket = self:GetCategory(category)
    bucket[id] = def
    self:Touch()
end

function Dataset:Remove(category, id)
    local bucket = self:GetCategory(category)
    bucket[id] = nil
    self:Touch()
end

function Dataset:Counts()
    local function count(t) local n=0 for _ in pairs(t or {}) do n=n+1 end return n end
    local extraCount = 0
    for _, t in pairs(self.extra or {}) do for _ in pairs(t) do extraCount = extraCount + 1 end end
    return {
        items  = count(self.items),
        spells = count(self.spells),
        auras  = count(self.auras),
        npcs   = count(self.npcs),
        extra  = extraCount,
    }
end

-- Optional: push into registries if present
local function _applyBucket(bucket, registry)
    if not (bucket and registry) then return end
    if type(registry.Clear) == "function" then registry:Clear()
    elseif type(registry.Wipe) == "function" then registry:Wipe()
    elseif type(registry.Reset) == "function" then registry:Reset() end
    for id, def in pairs(bucket) do
        if type(registry.Register) == "function" then registry:Register(id, def)
        elseif type(registry.Set) == "function" then registry:Set(id, def)
        elseif type(registry.Add) == "function" then registry:Add(id, def) end
    end
end

function Dataset:ApplyToRegistries()
    _applyBucket(self.items,  RPE.Core and RPE.Core.ItemRegistry)
    _applyBucket(self.spells, RPE.Core and RPE.Core.SpellRegistry)
    _applyBucket(self.auras,  RPE.Core and RPE.Core.AuraRegistry)
    _applyBucket(self.npcs,   RPE.Core and RPE.Core.NPCRegistry)
    if self.extra and self.extra.stats then
        _applyBucket(self.extra.stats, RPE.Core and RPE.Core.StatRegistry)
    end
end

-- -------- checksum & (de)serialization -------------------------------------

function Dataset:Checksum()
    -- Stable-ish: hash the dumped table string.
    local dumped = _dump(self:ToTable())
    return _adler32(dumped)
end

function Dataset:ToTable()
    return {
        name      = self.name,
        version   = self.version,
        author    = self.author,
        notes     = self.notes,
        description = self.description,
        guid      = self.guid,
        createdAt = self.createdAt,
        updatedAt = self.updatedAt,
        securityLevel = self.securityLevel,
        items     = self.items,
        spells    = self.spells,
        auras     = self.auras,
        npcs      = self.npcs,
        recipes   = self.recipes,
        extra     = self.extra,
        setupWizard = self.setupWizard,
    }
end

function Dataset.FromTable(t)
    assert(type(t) == "table", "Dataset.FromTable: table required")
    return Dataset:New(t.name or "Dataset", t)
end

-- Wire-format: "RPE-DSET1:<METHOD>:<payload>"
function Dataset:ExportString()
    local payloadTbl = self:ToTable()
    local encoded = Dataset._SER.encode(payloadTbl)
    return "RPE-DSET1:" .. (Dataset._SER.method or "S1") .. ":" .. encoded
end

function Dataset.ImportString(s)
    if type(s) ~= "string" then return nil, "not a string" end
    local tag, method, payload = s:match("^(RPE%-DSET1):([A-Za-z0-9_]+):(.*)$")
    if tag ~= "RPE-DSET1" then return nil, "bad header" end
    -- For now we ignore the method tag except to assert it matches our current serializer.
    local tbl, err = Dataset._SER.decode(payload)
    if not tbl then return nil, err or "decode failed" end
    return Dataset.FromTable(tbl)
end

return Dataset
