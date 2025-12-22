-- RPE/Profile/CharacterProfile.lua
-- Data class for character profiles (identified by their *name*).
-- Now stores stats as CharacterStat objects and serializes only base/category/min/max.
-- ALSO: stores inventory as { [itemId:string] = quantity:number }.

RPE = RPE or {}
RPE.Profile = RPE.Profile or {}

local CharacterStat = (RPE.Stats and RPE.Stats.CharacterStat) or error("CharacterStats.lua must load before CharacterProfile.lua")
---@class CharacterProfession
---@field id string             -- profession id, e.g. "Alchemy"
---@field level number          -- player’s level in the profession
---@field spec string           -- current specialization
---@field recipes string[]      -- list of known recipe IDs

local CharacterProfile = {}
CharacterProfile.__index = CharacterProfile
RPE.Profile.CharacterProfile = CharacterProfile

-- --- Internal helpers -------------------------------------------------------
local function normalizeStats(statsIn)
    -- Accepts nil, map<string, number>, or map<string, table> (serialized).
    local out = {}
    if type(statsIn) ~= "table" then return out end

    for key, v in pairs(statsIn) do
        if type(v) == "number" then
            -- Legacy: plain base value
            out[key] = CharacterStat:New(key, "PRIMARY", v)
        elseif type(v) == "table" then
            -- Serialized CharacterStat-style table
            out[key] = CharacterStat.FromTable(v)
        end
    end
    return out
end

local function normalizeProfessions(profIn)
    local function makeProf(id, existing)
        return {
            id     = id or (existing and existing.id) or "",
            level  = (existing and tonumber(existing.level)) or 0,
            learned = (existing and existing.learned) or (id and id ~= "" or false),
            spec   = (existing and existing.spec) or "",
            recipes= (existing and type(existing.recipes)=="table") and existing.recipes or {},
        }
    end

    local out = {}
    local p = type(profIn)=="table" and profIn or {}
    
    -- Preserve all existing professions from profIn
    for key, prof in pairs(p) do
        out[key] = makeProf(prof.id, prof)
    end
    
    -- Ensure utility professions exist (but don't overwrite if already present)
    if not out.cooking then
        out.cooking = makeProf("Cooking", p.cooking)
    end
    if not out.fishing then
        out.fishing = makeProf("Fishing", p.fishing)
    end
    if not out.firstaid then
        out.firstaid = makeProf("First Aid", p.firstaid)
    end
    
    return out
end

-- Accepts:
--  • nil
--  • map<string, number>  -> { ["potion"]=3, ["ore"]=12 }
--  • array of { id=string, qty=number }    -> { {id="potion", qty=3}, ... }
local function normalizeItems(itemsIn)
    local out = {}
    if type(itemsIn) ~= "table" then return out end

    -- Already in slot format?
    if itemsIn[1] and type(itemsIn[1]) == "table" then
        for i, slot in ipairs(itemsIn) do
            if type(slot.id) == "string" and tonumber(slot.qty) then
                local qty = math.max(0, math.floor(slot.qty))
                if qty > 0 then
                    table.insert(out, {
                        id   = slot.id,
                        qty  = qty,
                        mods = type(slot.mods)=="table" and slot.mods or {}
                    })
                end
            end
        end
    else
        -- Legacy: { id=qty } map → collapse into single slots
        for id, qty in pairs(itemsIn) do
            local n = math.max(0, math.floor(tonumber(qty) or 0))
            if n > 0 then
                table.insert(out, { id = tostring(id), qty = n, mods = {} })
            end
        end
    end
    return out
end


local function touch(self)
    self.updatedAt = time() or self.updatedAt
end

-- --- Construction -----------------------------------------------------------
--- Create a new in-memory profile object.
---@param name string
---@param opts table|nil  -- { stats, items, equipment, notes }
function CharacterProfile:New(name, opts)
    assert(type(name) == "string" and name ~= "", "CharacterProfile: name required")
    opts = opts or {}

    local now = time() or 0
    local o = setmetatable({
        name        = name,
        stats       = normalizeStats(opts.stats),
        items       = normalizeItems(opts.items),
        equipment   = opts.equipment or {},  -- slot → itemId
        traits      = opts.traits or {},     -- list of trait aura IDs
        languages   = opts.languages or {},  -- language name → skill level (1-300)
        race        = opts.race or nil,      -- selected race id
        class       = opts.class or nil,     -- selected class id
        notes       = opts.notes or nil,
        createdAt   = opts.createdAt or now,
        updatedAt   = opts.updatedAt or now,
        paletteName = (type(opts.paletteName) == "string" and opts.paletteName ~= "" and opts.paletteName) or "Default",
        professions = normalizeProfessions(opts.professions),
        spells      = opts.spells or {}, 
        actionBar   = opts.actionBar or {},
        resourceDisplaySettings = opts.resourceDisplaySettings or {},
        _initializing = true,  -- Flag to suppress UI callbacks during initialization
    }, self)
    
    -- Ensure resourceDisplaySettings has proper defaults if empty
    self:_InitializeResourceDisplaySettings()

    -- Normalize any saved item ids to canonical forms
    pcall(function()
        if type(o.NormalizeSavedIds) == "function" then pcall(o.NormalizeSavedIds, o) end
    end)

    o._initializing = false  -- Mark initialization complete
    return o
end

--- Convert any saved item ids in `items` and `equipment` to the registry's canonical id form.
function CharacterProfile:NormalizeSavedIds()
    local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
    if not reg or type(reg.Get) ~= "function" then return end

    -- Normalize inventory slot ids
    if type(self.items) == "table" then
        for _, slot in ipairs(self.items) do
            if slot and type(slot.id) == "string" then
                local obj = reg:Get(slot.id)
                if obj and obj.id then slot.id = obj.id end
            end
        end
    end

    -- Normalize equipment mapping
    if type(self.equipment) == "table" then
        for s, id in pairs(self.equipment) do
            if type(id) == "string" then
                local obj = reg:Get(id)
                if obj and obj.id then self.equipment[s] = obj.id end
            end
        end
    end
end

--- Normalize resource display settings, converting old array format to new {use, show} format.
--- Old format: resourceDisplaySettings[key] = ["HEALTH", "MANA", ...]
--- New format: resourceDisplaySettings[key] = {use: [...], show: [...]}
--- IMPORTANT: HEALTH is always added to show list if missing
function CharacterProfile:_NormalizeResourceSettings(datasetKey)
    if not self.resourceDisplaySettings then
        self.resourceDisplaySettings = {}
    end
    
    local settings = self.resourceDisplaySettings[datasetKey]
    
    -- If settings is nil, initialize as new format
    if settings == nil then
        self.resourceDisplaySettings[datasetKey] = { use = {}, show = { "HEALTH" } }
        return self.resourceDisplaySettings[datasetKey]
    end
    
    -- If settings is an array (old format), convert to new format
    if type(settings) == "table" and #settings > 0 and not settings.use and not settings.show then
        -- Old format detected: array of resources
        local oldArray = settings
        self.resourceDisplaySettings[datasetKey] = {
            use = {},  -- Old format didn't distinguish, so use stays empty (only always-used will be in use list)
            show = oldArray  -- Convert array to show list
        }
        return self.resourceDisplaySettings[datasetKey]
    end
    
    -- Already in new format or empty, ensure it has both keys and HEALTH in show
    if type(settings) == "table" then
        if not settings.use then settings.use = {} end
        if not settings.show then settings.show = {} end
        
        -- Ensure HEALTH is always in the show list
        local hasHealth = false
        for _, resId in ipairs(settings.show) do
            if resId == "HEALTH" then
                hasHealth = true
                break
            end
        end
        if not hasHealth then
            table.insert(settings.show, 1, "HEALTH")  -- Insert at beginning
        end
        
        return settings
    end
    
    -- Fallback: initialize as new format with HEALTH
    self.resourceDisplaySettings[datasetKey] = { use = {}, show = { "HEALTH" } }
    return self.resourceDisplaySettings[datasetKey]
end

--- Initialize resource display settings with defaults if needed
function CharacterProfile:_InitializeResourceDisplaySettings()
    if type(self.resourceDisplaySettings) ~= "table" then
        self.resourceDisplaySettings = {}
    end
    
    -- If no settings exist yet, create defaults
    local hasAnySettings = false
    for _ in pairs(self.resourceDisplaySettings) do
        hasAnySettings = true
        break
    end
    
    if not hasAnySettings then
        -- Set up a default for "none" (when no datasets are active)
        self.resourceDisplaySettings["none"] = {
            use = {},  -- Always-used resources are always in use (HEALTH, ACTION, BONUS_ACTION, REACTION)
            show = { "HEALTH", "MANA" }  -- Default bar display
        }
    else
        -- Normalize all existing settings to new format
        for key in pairs(self.resourceDisplaySettings) do
            self:_NormalizeResourceSettings(key)
        end
    end
end

---Initialize faction-specific languages if empty
function CharacterProfile:_InitializeLanguages()
    if type(self.languages) ~= "table" then
        self.languages = {}
    end
    
    -- Only initialize if languages table is empty
    if next(self.languages) == nil then
        -- Initialize with faction defaults
        local playerFaction = UnitFactionGroup("player")
        if playerFaction == "Alliance" then
            self.languages["Common"] = 300
        elseif playerFaction == "Horde" then
            self.languages["Orcish"] = 300
        end
    else
        RPE.Debug:Internal("Languages already initialized for profile: " .. (self.name or "?"))
    end
end

function CharacterProfile:RecalculateEquipmentStats()
    RPE.Debug:Internal(string.format("Recalculating equipment stats for profile: %s", self.name or "?"))

    -- Ensure the global structure exists
    RPE.Core.StatModifiers.equip = RPE.Core.StatModifiers.equip or {}

    -- Clear only this profile's equip mods (don't clobber other profiles)
    local pid = self.name
    RPE.Core.StatModifiers.equip[pid] = {}

    for slot, itemId in pairs(self.equipment or {}) do
        local item = RPE.Core.ItemRegistry and RPE.Core.ItemRegistry:Get(itemId)
        if item then
            -- Re-apply its equip mods into this profile's table
            for k, v in pairs(item.data or {}) do
                if type(k) == "string" and k:match("^stat%_") then
                    local statId = k:sub(6) -- strip "stat_"
                    local delta  = tonumber(v) or 0
                    if delta ~= 0 and RPE.Stats and RPE.Stats.Get then
                        local stat = RPE.Stats:Get(statId)
                        if stat then
                            -- Check ruleset
                            if RPE.ActiveRules and RPE.ActiveRules:IsStatEnabled(statId, stat.category) then
                                local mods = RPE.Core.StatModifiers.equip[pid]
                                mods[statId] = (mods[statId] or 0) + delta
                                -- Only trigger UI updates if we're not initializing
                                if not self._initializing and _G.RPE.Core.Windows.StatisticSheet then
                                    _G.RPE.Core.Windows.StatisticSheet.OnStatChanged(statId)
                                end
                            end
                        end
                    end
                end
            end
        else
            RPE.Debug:Error(string.format("Equipped item %s not found in ItemRegistry.", itemId))
        end
    end
end

-- --- Color Palette API --- --
function CharacterProfile:GetPaletteName()
    return self.paletteName or "Default"
end

function CharacterProfile:SetPaletteName(name)
    if type(name) ~= "string" or name == "" then return end
    self.paletteName = name
    self.updatedAt = time() or self.updatedAt
    -- Persist
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
        RPE.Profile.DB.SaveProfile(self)
    end
end

-- --- Stat API (object-based) -----------------------------------------------

--- Get or create a stat object using composite key sourceDataset.statId.
---@param statId string
---@param category StatCategory|nil
---@param sourceDataset string|nil
---@return CharacterStat

--- Get or create a stat object using composite key sourceDataset.statId.
--- If sourceDataset is nil, search active datasets in order and return the first found.
---@param statId string
---@param category StatCategory|nil
---@param sourceDataset string|nil
---@return CharacterStat|nil
function CharacterProfile:GetStat(statId, category, sourceDataset)
    assert(statId and type(statId) == "string", "GetStat: statId required")
    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not sourceDataset then
        -- Search active datasets in order
        local active = (DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter and DatasetDB:GetActiveNamesForCurrentCharacter()) or {}
        for _, ds in ipairs(active) do
            local key = ds .. "." .. statId
            local s = self.stats[key]
            if s then return s end
        end
        return nil
    else
        local key = sourceDataset .. "." .. statId
        local s = self.stats[key]
        if not s then
            s = CharacterStat:New(statId, category or "PRIMARY", 0)
            s.sourceDataset = sourceDataset
            self.stats[key] = s
        end
        return s
    end
end

--- Convenience: set base value (persisted).

function CharacterProfile:SetStatBase(statId, value, category, sourceDataset)
    local s = self:GetStat(statId, category, sourceDataset)
    s:SetBase(tonumber(value) or 0)
    touch(self)
end

--- Convenience: set equipment modifier (transient).

function CharacterProfile:SetStatEquipMod(statId, value, sourceDataset)
    local s = self:GetStat(statId, nil, sourceDataset)
    s:SetEquipMod(tonumber(value) or 0)
end

--- Convenience: set aura modifier (transient).

function CharacterProfile:SetStatAuraMod(statId, value, sourceDataset)
    local s = self:GetStat(statId, nil, sourceDataset)
    s:SetAuraMod(tonumber(value) or 0)
end

--- Convenience: effective value (clamped).


function CharacterProfile:GetStatValue(statId, sourceDataset)
    local stat = self:GetStat(statId, nil, sourceDataset)
    return stat and stat:GetValue(self) or 0
end

--- Clear all transient modifiers (equipment + auras).

function CharacterProfile:ClearTransientMods()
    for _, s in pairs(self.stats) do
        s:SetEquipMod(0)
        s:SetAuraMod(self, 0)
    end
end

--- Optional: export just base values for UI/debug.

function CharacterProfile:GetBaseStatTable()
    local t = {}
    for key, s in pairs(self.stats) do
        t[key] = s.base
    end
    return t
end

-- --- Inventory API (quantity-per-itemId) -----------------------------------
--- Get total quantity for an item id.
---@param itemId string
---@return number
function CharacterProfile:GetItemQty(itemId)
    local total = 0
    for _, slot in ipairs(self.items or {}) do
        if slot.id == itemId then
            total = total + (slot.qty or 0)
        end
    end
    return total
end


--- Set absolute quantity for an item id (0 removes).
---@param itemId string
---@param qty number
function CharacterProfile:SetItemQty(itemId, qty)
    local n = math.max(0, math.floor(tonumber(qty) or 0))
    self:ClearItem(itemId)
    if n > 0 then
        table.insert(self.items, { id = itemId, qty = n })
     
        touch(self)
    end
end

function CharacterProfile:ClearItem(itemId)
    local out = {}
    for _, slot in ipairs(self.items or {}) do
        if slot.id ~= itemId then
            table.insert(out, slot)
        end
    end
    self.items = out
 
end


--- Add quantity (negative to subtract). Returns new total quantity of that item.
---@param itemId string
---@param delta number
---@param maxStackOverride number|nil -- optional override (defaults to item’s own maxStack or 9999)
---@return number newQty
function CharacterProfile:AddItem(itemId, delta, maxStackOverride)
    local d = math.floor(tonumber(delta) or 0)
    if d == 0 then return self:GetItemQty(itemId) end

    -- Look up item definition
    local itemDef = RPE.Core.ItemRegistry and RPE.Core.ItemRegistry:Get(itemId)
    local maxStack
    if itemDef then
        if itemDef:IsStackable() then
            maxStack = maxStackOverride or itemDef:GetStackLimit()
        else
            maxStack = 1
        end
    else
        -- Fallback if not in registry (shouldn’t happen, but be safe)
        RPE.Debug:Error("[CharacterProfile:AddItem] Failed to get item definition from the registry.")
        maxStack = maxStackOverride or 9999
    end

    -- Adding items
    if d > 0 then
        -- Fill existing stacks
        for _, slot in ipairs(self.items) do
            if slot.id == itemId and slot.qty < maxStack then
                local add = math.min(d, maxStack - slot.qty)
                slot.qty = slot.qty + add
                d = d - add
                if d <= 0 then break end
            end
        end

        -- Any remainder → new stacks
        while d > 0 do
            local add = math.min(d, maxStack)
            table.insert(self.items, { id = itemId, qty = add })
            d = d - add
        end

    else
        -- Removing items: consume stacks in reverse order
        local need = -d
        for i = #self.items, 1, -1 do
            local slot = self.items[i]
            if slot.id == itemId then
                local take = math.min(slot.qty, need)
                slot.qty = slot.qty - take
                need = need - take
                if slot.qty <= 0 then table.remove(self.items, i) end
                if need <= 0 then break end
            end
        end
    end

    touch(self)
    RPE.Profile.DB.SaveProfile(self)
    RPE.Core.Windows.ProfessionSheet:Refresh()
    RPE.Core.Windows.InventorySheet:Refresh()

    -- Refresh action bar button states (requirements may depend on inventory)
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    -- Refresh player unit widget (inventory change affects stat displays)
    local playerWidget = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
    if playerWidget and playerWidget.Refresh and not playerWidget._inTemporaryMode then
        playerWidget:Refresh()
    end

    return self:GetItemQty(itemId)
end



--- Remove up to 'qty' of the item. Returns actually removed amount.
---@param itemId string
---@param qty number
---@return number removed
function CharacterProfile:RemoveItem(itemId, qty)
    local want = math.max(0, math.floor(tonumber(qty) or 0))
    if want == 0 then return 0 end

    local removed = 0
    for i = #self.items, 1, -1 do
        local slot = self.items[i]
        if slot.id == itemId then
            local take = math.min(slot.qty, want - removed)
            slot.qty = slot.qty - take
            removed = removed + take
            if slot.qty <= 0 then table.remove(self.items, i) end
            if removed >= want then break end
        end
    end

    if removed > 0 then
        touch(self)
        RPE.Profile.DB.SaveProfile(self)
        RPE.Core.Windows.ProfessionSheet:Refresh()
    end

    return removed
end


--- True if the player owns at least 'qty' of itemId (default 1).
function CharacterProfile:HasItem(itemId, qty)
    qty = math.max(1, math.floor(tonumber(qty or 1) or 1))
    return self:GetItemQty(itemId) >= qty
end

--- Consume 'qty' if available; returns boolean success.
function CharacterProfile:ConsumeItem(itemId, qty)
    if self:HasItem(itemId, qty) then
        self:RemoveItem(itemId, qty)
        return true
    end
    return false
end

--- Iterate items: fn(itemId, qty) -> if returns false, break.
function CharacterProfile:ForEachItem(fn)
    if type(fn) ~= "function" then return end
    for _, slot in ipairs(self.items or {}) do
        if fn(slot.id, slot.qty) == false then break end
    end
end

--- Clear all items.
function CharacterProfile:ClearItems()
    if self.items and next(self.items) ~= nil then
        self.items = {}
        touch(self)
    end
end

--- Get mods applied to an item slot.
---@param index number
---@return table
function CharacterProfile:GetItemMods(index)
    local slot = self.items[index]
    return slot and slot.mods or {}
end

--- Apply or update a mod on a specific slot.
---@param index number
---@param modKey string
---@param modData any
function CharacterProfile:SetItemMod(index, modKey, modData)
    local slot = self.items[index]
    if slot then
        slot.mods = slot.mods or {}
        slot.mods[modKey] = modData
        touch(self)
        RPE.Profile.DB.SaveProfile(self)
    end
end

--- Remove a mod from a slot.
function CharacterProfile:ClearItemMod(index, modKey)
    local slot = self.items[index]
    if slot and slot.mods then
        slot.mods[modKey] = nil
        touch(self)
        RPE.Profile.DB.SaveProfile(self)
    end
end

function Item:ApplyMods(mods)
    if not mods then return self end
    for k,v in pairs(mods) do
        -- e.g. store enchant/gem ids inside data
        self:SetDataKey(k, v)
    end
    return self
end

-- --- Equipment API (slot → itemId, synced with inventory) -------------------

--- Get the item id equipped in a slot.
---@param slot string
---@return string|nil
function CharacterProfile:GetEquipped(slot)
    return self.equipment and self.equipment[slot] or nil
end
--- Internal: apply all stat equip mods from an item.
local function applyEquipMods(item, sign, mods)
    -- base item stats
    if item and item.data then
        for k, v in pairs(item.data) do
            if type(k) == "string" and k:match("^stat%_") then
                local statId = k:sub(6)
                local delta  = tonumber(v) or 0
                if delta ~= 0 and RPE.Stats and RPE.Stats.Get then
                    local stat = RPE.Stats:Get(statId)
                    if stat and (not RPE.ActiveRules or RPE.ActiveRules:IsStatEnabled(statId, stat.category)) then
                        -- Read current equip mod from storage, not from stat object
                        local profile = RPE.Profile.DB.GetOrCreateActive()
                        local pid = profile and profile.name
                        local currentMod = 0
                        if pid then
                            RPE.Core.StatModifiers.equip[pid] = RPE.Core.StatModifiers.equip[pid] or {}
                            currentMod = RPE.Core.StatModifiers.equip[pid][statId] or 0
                        end
                        stat:SetEquipMod(currentMod + (delta * sign))
                    end
                end
            end
        end
    end

    -- attached mods (gems, enchants)
    if mods then
        for modKey, modData in pairs(mods) do
            if type(modData) == "table" then
                for k, v in pairs(modData) do
                    if type(k) == "string" and k:match("^stat%_") then
                        local statId = k:sub(6)
                        local delta  = tonumber(v) or 0
                        if delta ~= 0 and RPE.Stats and RPE.Stats.Get then
                            local stat = RPE.Stats:Get(statId)
                            if stat and (not RPE.ActiveRules or RPE.ActiveRules:IsStatEnabled(statId, stat.category)) then
                                -- Read current equip mod from storage, not from stat object
                                local profile = RPE.Profile.DB.GetOrCreateActive()
                                local pid = profile and profile.name
                                local currentMod = 0
                                if pid then
                                    RPE.Core.StatModifiers.equip[pid] = RPE.Core.StatModifiers.equip[pid] or {}
                                    currentMod = RPE.Core.StatModifiers.equip[pid][statId] or 0
                                end
                                stat:SetEquipMod(currentMod + (delta * sign))
                            end
                        end
                    end
                end
            end
        end
    end
end


--- Equip an item into a slot.
---@param slot string
---@param itemId string
---@param onLoad boolean|false
---@return string|nil replacedItemId
function CharacterProfile:Equip(slot, itemId, onLoad)
    if not slot or slot == "" then return nil end
    if not self.equipment then self.equipment = {} end

    local item = RPE.Core.ItemRegistry and RPE.Core.ItemRegistry:Get(itemId)
    if not item then
        RPE.Debug:Error(string.format("ItemRegistry not available or item not found: %s", itemId))
        return nil -- unknown item
    end

    -- If the item defines a required slot, enforce it
    local requiredSlot = item.data and item.data.slot
    if requiredSlot and requiredSlot ~= slot then
        RPE.Debug:Error(string.format("Item %s cannot be equipped into slot %s (requires %s)", itemId, slot, requiredSlot))
        return nil -- wrong slot for this item
    end

    -- Must own at least one to equip
    if (not self:HasItem(itemId, 1)) and (not onLoad) then
        RPE.Debug:Error(string.format("Cannot equip item %s: not in inventory", itemId))
        return nil
    end

    local prevId = self.equipment[slot]
    local prevItem = prevId and (RPE.Core.ItemRegistry and RPE.Core.ItemRegistry:Get(prevId)) or nil

    -- IMPORTANT: Find exact inventory slot for the new item BEFORE modifying inventory
    local newItemSlotIndex = nil
    local newMods
    for idx, invSlot in ipairs(self.items) do
        if invSlot.id == itemId then
            newItemSlotIndex = idx
            newMods = invSlot.mods
            break
        end
    end

    -- Find exact inventory slot for old item BEFORE modifying inventory
    local oldItemSlotIndex = nil
    local oldMods
    if prevItem then
        for idx, invSlot in ipairs(self.items) do
            if invSlot.id == prevId then
                oldItemSlotIndex = idx
                oldMods = invSlot.mods
                break
            end
        end
    end

    -- Remove new item from inventory by exact index (not by search)
    if newItemSlotIndex then
        self.items[newItemSlotIndex].qty = self.items[newItemSlotIndex].qty - 1
        if self.items[newItemSlotIndex].qty <= 0 then
            table.remove(self.items, newItemSlotIndex)
        end
    end

    -- Unequip old: return it to inventory + remove its mods
    if prevItem then
        self:AddItem(prevId, 1)
        applyEquipMods(prevItem, -1, oldMods)
    end

    -- Equip the new item
    self.equipment[slot] = itemId

    applyEquipMods(item, 1, newMods)
    touch(self)
    RPE.Profile.DB.SaveProfile(self)
    
    -- Update the equipment pane
    RPE.Core.Windows.EquipmentSheet:Refresh()
    RPE.Core.Windows.InventorySheet:Refresh()

    -- Refresh action bar button states (requirements depend on equipment)
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    -- Refresh player unit widget (equipment change affects stat displays)
    local playerWidget = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
    if playerWidget and playerWidget.Refresh and not playerWidget._inTemporaryMode then
        playerWidget:Refresh()
    end

    return prevId
end

--- Unequip whatever is in the given slot and return it to inventory.
---@param slot string
---@return string|nil removedItemId
function CharacterProfile:Unequip(slot)
    if not slot or slot == "" then return nil end
    if not self.equipment then return nil end

    local oldId = self.equipment[slot]
    if oldId then
        -- IMPORTANT: Get the item definition first
        local oldItem = RPE.Core.ItemRegistry and RPE.Core.ItemRegistry:Get(oldId)
        
        -- Find exact inventory slot and mods BEFORE removing from equipment
        local oldMods
        if oldItem then
            for _, invSlot in ipairs(self.items) do
                if invSlot.id == oldId then
                    oldMods = invSlot.mods
                    break
                end
            end
        end
        
        -- Remove its equip mods FIRST (before adding back to inventory)
        if oldItem then
            applyEquipMods(oldItem, -1, oldMods)
        end
        
        -- Now remove from equipment and return to inventory
        self.equipment[slot] = nil
        self:AddItem(oldId, 1)

        touch(self)
    end

    RPE.Core.Windows.EquipmentSheet:Refresh()
    RPE.Core.Windows.InventorySheet:Refresh()

    -- Refresh action bar button states (equipment change may affect requirements)
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    -- Refresh player unit widget (equipment change affects stat displays)
    local playerWidget = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
    if playerWidget and playerWidget.Refresh and not playerWidget._inTemporaryMode then
        playerWidget:Refresh()
    end

    return oldId
end

--- Swap a slot’s item with a new one.
--- Returns { oldItemId, success }
---@param slot string
---@param itemId string
---@return string|nil, boolean
function CharacterProfile:Swap(slot, itemId)
    if not slot or slot == "" then return nil, false end
    if not itemId or itemId == "" then return nil, false end

    local current = self:GetEquipped(slot)
    if current == itemId then
        return current, false -- already equipped, no change
    end

    -- Unequip old (if any) → goes back to inventory
    local old = self:Unequip(slot)

    -- Try to equip new
    if self:HasItem(itemId, 1) then
        self:Equip(slot, itemId)
        return old, true
    else
        -- Failed to equip new one, put old back if there was one
        if old then
            self:Equip(slot, old)
        end
        return old, false
    end
end

--- Iterate equipment: fn(slot, itemId).
function CharacterProfile:ForEachEquipped(fn)
    if type(fn) ~= "function" then return end
    for slot, id in pairs(self.equipment or {}) do
        if fn(slot, id) == false then break end
    end
end

-------------------------------------------------------------------------------
-- Traits API (permanent aura-based traits)
-------------------------------------------------------------------------------

--- Add a trait (aura) to the profile.
---@param auraId string
function CharacterProfile:AddTrait(auraId)
    if not auraId or auraId == "" then return end
    for _, id in ipairs(self.traits or {}) do
        if id == auraId then return end  -- already present
    end
    
    -- Get aura definition to check if it's racial or class
    local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
    local isRacial = false
    local isClass = false
    
    if AuraRegistry then
        local auraDef = AuraRegistry:Get(auraId)
        if auraDef and auraDef.tags then
            for _, tag in ipairs(auraDef.tags) do
                if type(tag) == "string" then
                    local tagLower = tag:lower()
                    if tagLower:sub(1, 5) == "race:" then
                        isRacial = true
                        break
                    elseif tagLower:sub(1, 6) == "class:" then
                        isClass = true
                        break
                    end
                end
            end
        end
    end
    
    -- Count current traits by type
    local racialCount = 0
    local classCount = 0
    local genericCount = 0
    for _, traitId in ipairs(self.traits or {}) do
        local def = AuraRegistry and AuraRegistry:Get(traitId)
        if def and def.tags then
            local isTraitRacial = false
            local isTraitClass = false
            for _, tag in ipairs(def.tags) do
                if type(tag) == "string" then
                    local tagLower = tag:lower()
                    if tagLower:sub(1, 5) == "race:" then
                        isTraitRacial = true
                        break
                    elseif tagLower:sub(1, 6) == "class:" then
                        isTraitClass = true
                        break
                    end
                end
            end
            if isTraitRacial then
                racialCount = racialCount + 1
            elseif isTraitClass then
                classCount = classCount + 1
            else
                genericCount = genericCount + 1
            end
        else
            genericCount = genericCount + 1
        end
    end
    
    -- Check max_traits (overall limit for ANY traits)
    local maxTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits) or 0
    local totalTraits = #(self.traits or {})
    if maxTraits > 0 and totalTraits >= maxTraits then
        return  -- at max total capacity
    end
    
    -- Check type-specific limits
    if isRacial then
        local maxRacialTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits_racial) or 0
        if maxRacialTraits > 0 and racialCount >= maxRacialTraits then
            return  -- at max racial capacity
        end
    elseif isClass then
        local maxClassTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits_class) or 0
        if maxClassTraits > 0 and classCount >= maxClassTraits then
            return  -- at max class capacity
        end
    else
        -- Generic trait - check max_generic_traits
        local maxGenericTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_generic_traits) or 0
        if maxGenericTraits > 0 and genericCount >= maxGenericTraits then
            return  -- at max generic capacity
        end
    end
    
    self.traits = self.traits or {}
    table.insert(self.traits, auraId)
    touch(self)
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
        RPE.Profile.DB.SaveProfile(self)
    end
end

--- Remove a trait (aura) from the profile.
---@param auraId string
function CharacterProfile:RemoveTrait(auraId)
    if not auraId or not self.traits then return end
    for i = #self.traits, 1, -1 do
        if self.traits[i] == auraId then
            table.remove(self.traits, i)
            touch(self)
            if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                RPE.Profile.DB.SaveProfile(self)
            end
            return
        end
    end
end

--- Check if a trait is present.
---@param auraId string
---@return boolean
function CharacterProfile:HasTrait(auraId)
    if not auraId or not self.traits then return false end
    for _, id in ipairs(self.traits) do
        if id == auraId then return true end
    end
    return false
end

--- Get all trait aura IDs.
---@return string[]
function CharacterProfile:GetTraits()
    return self.traits or {}
end

-------------------------------------------------------------------------------
-- Spell Knowledge API
-------------------------------------------------------------------------------


-- In CharacterProfile.lua
function CharacterProfile:KnowsSpell(spellId, rank)
    if not self.spells then return false end
    local learnedRank = tonumber(self.spells[spellId])
    if not learnedRank then return false end
    if rank then
        return learnedRank >= rank
    end
    return true
end

function CharacterProfile:LearnSpell(spellId, rank)
    rank = tonumber(rank) or 1
    self.spells = self.spells or {}
    local prev = tonumber(self.spells[spellId]) or 0
    if rank > prev then
        self.spells[spellId] = rank
        RPE.Debug:Print(("Learned spell %s (Rank %d)"):format(spellId, rank))
        self.updatedAt = time()
        RPE.Profile.DB.SaveProfile(self)
    end
end

function CharacterProfile:GetSpellRank(spellId)
    if not self.spells then return 0 end
    return tonumber(self.spells[spellId]) or 0
end

function CharacterProfile:ClearSpells()
    self.spells = {}
    touch(self)
    RPE.Profile.DB.SaveProfile(self)
    RPE.Debug:Print("Cleared all spells")
end


-------------------------------------------------------------------------------
-- Profession / Recipe Knowledge API
-------------------------------------------------------------------------------

--- Mark a recipe as known for a profession.
---@param profession string  -- e.g. "Blacksmithing"
---@param recipeId string
function CharacterProfile:LearnRecipe(profession, recipeId)
    if type(profession) ~= "string" or profession == "" then return end
    if type(recipeId) ~= "string" or recipeId == "" then return end

    local profs = self.professions or {}
    local profKey = profession:lower()
    local prof = profs[profKey] or profs.profession1 or profs.profession2

    if not prof then
        RPE.Debug:Warning(("[Profile] Unknown profession '%s' on LearnRecipe."):format(profession))
        return
    end

    prof.recipes = prof.recipes or {}
    for _, id in ipairs(prof.recipes) do
        if id == recipeId then
            return -- already known
        end
    end

    table.insert(prof.recipes, recipeId)
    self.updatedAt = time()
    RPE.Profile.DB.SaveProfile(self)
    RPE.Debug:Print(("[Profile] Learned recipe %s for %s."):format(recipeId, profession))
end

--- Forget (unlearn) a recipe for a profession.
function CharacterProfile:UnlearnRecipe(profession, recipeId)
    if type(profession) ~= "string" or profession == "" then return end
    if type(recipeId) ~= "string" or recipeId == "" then return end

    local profs = self.professions or {}
    local profKey = profession:lower()
    local prof = profs[profKey] or profs.profession1 or profs.profession2
    if not (prof and prof.recipes) then return end

    local new = {}
    for _, id in ipairs(prof.recipes) do
        if id ~= recipeId then table.insert(new, id) end
    end
    prof.recipes = new
    self.updatedAt = time()
    RPE.Profile.DB.SaveProfile(self)
    RPE.Debug:Print(("[Profile] Unlearned recipe %s from %s."):format(recipeId, profession))
end

--- Check if a recipe is known.
---@param profession string
---@param recipeId string
---@return boolean
function CharacterProfile:KnowsRecipe(profession, recipeId)
    if type(profession) ~= "string" or profession == "" then return false end
    if type(recipeId) ~= "string" or recipeId == "" then return false end
    local profs = self.professions or {}
    local profKey = profession:lower()
    local prof = profs[profKey] or profs.profession1 or profs.profession2
    if not (prof and prof.recipes) then return false end

    for _, id in ipairs(prof.recipes) do
        if id == recipeId then return true end
    end
    return false
end

--- Return all known recipe IDs for a profession.
---@param profession string
---@return string[]
function CharacterProfile:GetKnownRecipes(profession)
    if type(profession) ~= "string" or profession == "" then return {} end
    local profs = self.professions or {}
    local profKey = profession:lower()
    local prof = profs[profKey] or profs.profession1 or profs.profession2
    if not (prof and type(prof.recipes) == "table") then return {} end
    return prof.recipes
end

--- Clear all professions from the character.
function CharacterProfile:ClearProfessions()
    self.professions = {}
end

-- --- Action Bar Handling. ----------------------------------------------------------

function CharacterProfile:SetActionBarSlot(index, spellId, rank)
    self.actionBar = self.actionBar or {}
    self.actionBar[index] = { spellId = spellId, rank = rank }
end

function CharacterProfile:GetActionBarSlot(index)
    return self.actionBar and self.actionBar[index]
end

function CharacterProfile:ClearActionBar()
    self.actionBar = {}
end

-- --- Serialization ----------------------------------------------------------
--- Serialize to a plain table for SavedVariables.
---@return table
function CharacterProfile:ToTable()
    local statsOut = {}
    for key, s in pairs(self.stats or {}) do
        statsOut[key] = s:ToTable()
    end

    local itemsOut = {}
    for _, slot in ipairs(self.items or {}) do
        if slot.qty and slot.qty > 0 then
            table.insert(itemsOut, {
                id   = slot.id,
                qty  = slot.qty,
                mods = (slot.mods and next(slot.mods)) and slot.mods or nil
            })
        end
    end

    local equipOut = {}
    for slot, id in pairs(self.equipment or {}) do
        if id and id ~= "" then equipOut[slot] = id end
    end

    local spellsOut = {}
    for spellId, rank in pairs(self.spells or {}) do
        if type(spellId) == "string" and tonumber(rank) then
            spellsOut[spellId] = tonumber(rank)
        end
    end

    return {
        name      = self.name,
        stats     = statsOut,
        items     = itemsOut,
        equipment = equipOut,
        traits    = self.traits or {},
        languages = self.languages or {},
        race      = self.race,
        class     = self.class,
        notes     = self.notes,
        createdAt = self.createdAt,
        updatedAt = self.updatedAt,
        paletteName = self.paletteName,
        professions = self.professions,
        spells      = spellsOut,
        actionBar = self.actionBar or {},
        resourceDisplaySettings = self.resourceDisplaySettings or {},
    }
end

function CharacterProfile.FromTable(t)
    assert(type(t) == "table", "FromTable: table required")
    return CharacterProfile:New(t.name or "", {
        stats     = type(t.stats) == "table" and t.stats or {},
        items     = type(t.items) == "table" and t.items or {},
        equipment = type(t.equipment) == "table" and t.equipment or {},
        traits    = type(t.traits) == "table" and t.traits or {},
        languages = type(t.languages) == "table" and t.languages or {},
        race      = t.race,
        class     = t.class,
        notes     = t.notes,
        createdAt = t.createdAt,
        updatedAt = t.updatedAt,
        paletteName = t.paletteName,
        professions = t.professions or {},
        spells      = t.spells or {}, 
        actionBar = t.actionBar or {},
        resourceDisplaySettings = type(t.resourceDisplaySettings) == "table" and t.resourceDisplaySettings or {},
    })
end

