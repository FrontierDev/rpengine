-- RPE/Core/ItemLevel.lua
-- Minimal ilvl calculator:
-- - Only includes stats whose CharacterStat.itemLevelWeight is a number.
-- - Respects ActiveRules:IsStatEnabled(statId, category).
-- - Linear sum by default; negatives ignored unless includeNegative=true.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local ItemLevel = {}
RPE.Core.ItemLevel = ItemLevel

local Rules = (_G.RPE and _G.RPE.ActiveRules) or _G.ActiveRules

local function statEnabled(statId, def)
    if Rules and Rules.IsStatEnabled then
        return Rules:IsStatEnabled(statId, def and def.category) ~= false
    end
    return true
end

--- Compute item level from an item table with stat_* keys using Classic exponents.
--- Uses per-stat `itemLevelWeight` as the StatMod. No slot modifiers.
--- ItemValue = ( Σ (|StatValue * StatMod| ^ 1.5) )^(2/3) / 100
--- Quality transform (Classic):
---   Uncommon: (ItemValue + 9.8) / 1.21
---   Rare:     (ItemValue + 4.2) / 1.42
---   Epic:     (ItemValue - 11.2) / 1.64
---   Legendary (extrapolated): (ItemValue - 21.7) / 1.86
--- If quality is unknown/other, we leave it as ItemValue.
--- @param item table
--- @param includeNegative boolean|nil  -- ignored (negatives clamped to 0 to avoid complex powers)
--- @return number ilvl, table breakdown
function ItemLevel:FromItem(item, includeNegative)
    local totalPow = 0
    local breakdown = {}

    -- Pull stats from item.data if present, otherwise from the item itself
    local src = (type(item) == "table" and (item.data or item)) or {}

    -- helper to find/normalize quality from the item (supports your lowercase dropdown strings)
    local function _extractQuality()
        -- prefer lowercase dropdown field names directly on src
        local q = src.rarity or src.quality or src.rarityChoice or src.rarity_name
                  or src.Rarity or src.Quality or src.itemQuality or src.ItemQuality
                  or item.rarity or item.quality

        -- unwrap common table shapes from UI widgets
        local function unwrap(v)
            if type(v) == "table" then
                if v.value ~= nil then return v.value end
                if v.selected ~= nil then return v.selected end
                if v.name ~= nil then return v.name end
                if v.id ~= nil then return v.id end
                if v[1] ~= nil then return v[1] end
            end
            return v
        end
        q = unwrap(q)

        -- fallback: scan shallow fields for anything named like *rarity* or *quality*
        if q == nil then
            for k, v in pairs(src) do
                if type(k) == "string" then
                    local lk = k:lower()
                    if lk:find("rarity", 1, true) or lk:find("quality", 1, true) then
                        q = unwrap(v); break
                    end
                end
            end
        end

        -- map to canonical tokens
        if type(q) == "string" then
            local m = {
                common    = "COMMON",
                uncommon  = "UNCOMMON",
                rare      = "RARE",
                epic      = "EPIC",
                legendary = "LEGENDARY",
                poor      = "POOR",
                white     = "COMMON",
                green     = "UNCOMMON",
                blue      = "RARE",
                purple    = "EPIC",
                orange    = "LEGENDARY",
                grey      = "POOR", gray = "POOR",
            }
            return m[q:lower()]
        elseif type(q) == "number" then
            -- supports 1-based dropdown indices or WoW-like 0..5—map both sanely
            local idx = q
            if idx >= 0 and idx <= 5 then
                -- WoW-like: 0=Poor,1=Common,2=Uncommon,3=Rare,4=Epic,5=Legendary
                local map = { [0]="POOR","COMMON","UNCOMMON","RARE","EPIC","LEGENDARY" }
                return map[idx]
            else
                -- assume 1-based list: 1..5 = Common..Legendary
                local list = { "COMMON","UNCOMMON","RARE","EPIC","LEGENDARY" }
                return list[idx]
            end
        end

        return nil
    end

    for k, v in pairs(src) do
        if type(k) == "string" then
            local rawId = k:match("^stat_([%w_]+)$")
            if rawId then
                local statId = rawId:upper()
                local amount = tonumber(v)
                if amount and amount ~= 0 then
                    -- Clamp negatives to avoid complex results with fractional powers
                    local amt = math.max(0, amount)

                    local def = RPE.Stats:Get(statId)
                    if def and type(def.itemLevelWeight) == "number" and statEnabled(statId, def) then
                        local mod  = def.itemLevelWeight
                        local term = (math.abs(amt * mod)) ^ 1.5
                        if term ~= 0 then
                            totalPow = totalPow + term
                            breakdown[statId] = (breakdown[statId] or 0) + term
                        end
                    end
                end
            end
        end
    end

    -- Base ItemValue (no slot mod)
    local itemValue = (totalPow > 0) and ((totalPow) ^ (2/3) / 100) or 0

    -- Determine quality from your dropdown strings (common/uncommon/rare/epic/legendary)
    local qual = _extractQuality()
    
    -- Apply quality transform (no slot mod)
    local ilvlFloat
    if qual == "UNCOMMON" then
        ilvlFloat = (itemValue + 9.8) / 1.21
    elseif qual == "RARE" then
        ilvlFloat = (itemValue + 4.2) / 1.42
    elseif qual == "EPIC" then
        ilvlFloat = (itemValue - 11.2) / 1.64
    elseif qual == "LEGENDARY" then
        -- Extrapolated from Uncommon/Rare/Epic
        ilvlFloat = (itemValue - 21.7) / 1.86
    else
        -- COMMON/POOR/unknown: leave as ItemValue
        ilvlFloat = itemValue
    end

    -- Round to nearest integer
    local ilvl = math.floor(ilvlFloat + 0.5)
    return ilvl, breakdown
end

return ItemLevel
