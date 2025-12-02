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

---@class CharacterProfile
---@field name string
---@field stats table<string, CharacterStat>   -- keyed by stat id
---@field items table<number, {id:string, qty:number, mods:table|nil}>
---@field equipment table<string, string>      -- equipment: keyed by slot, value = item id
---@field notes string|nil
---@field createdAt number
---@field updatedAt number
---@field paletteName string
---@field resourceDisplaySettings table<string, {use: string[], show: string[]}>  -- keyed by dataset combination; use = resources checked for spell costs, show = resources displayed
---@field professions {                       -- always present
---   cooking: CharacterProfession,
---   fishing: CharacterProfession,
---   firstaid: CharacterProfession,
---   profession1: CharacterProfession,       -- player-chosen
---   profession2: CharacterProfession }        -- player-chosen
local CharacterProfile = {}
CharacterProfile.__index = CharacterProfile
RPE.Profile.CharacterProfile = CharacterProfile

-- --- Internal helpers -------------------------------------------------------
local function normalizeStats(statsIn)
    -- Accepts nil, map<string, number>, or map<string, table> (serialized).
    local out = {}
    if type(statsIn) ~= "table" then return out end

    for id, v in pairs(statsIn) do
        if type(v) == "number" then
            -- Legacy: plain base value
            out[id] = CharacterStat:New(id, "PRIMARY", v)
        elseif type(v) == "table" then
            -- Serialized CharacterStat-style table
            out[id] = CharacterStat.FromTable(v)
        end
    end
    return out
end

local function normalizeProfessions(profIn)
    local function makeProf(id, existing)
        return {
            id     = id or (existing and existing.id) or "",
            level  = (existing and tonumber(existing.level)) or 0,
            spec   = (existing and existing.spec) or "",
            recipes= (existing and type(existing.recipes)=="table") and existing.recipes or {},
        }
    end

    local out = {}
    local p = type(profIn)=="table" and profIn or {}
    out.cooking     = makeProf("Cooking", p.cooking)
    out.fishing     = makeProf("Fishing", p.fishing)
    out.firstaid    = makeProf("First Aid", p.firstaid)
    out.profession1 = makeProf(p.profession1 and p.profession1.id or "", p.profession1)
    out.profession2 = makeProf(p.profession2 and p.profession2.id or "", p.profession2)
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
        notes       = opts.notes or nil,
        createdAt   = opts.createdAt or now,
        updatedAt   = opts.updatedAt or now,
        paletteName = (type(opts.paletteName) == "string" and opts.paletteName ~= "" and opts.paletteName) or "Default",
        professions = normalizeProfessions(opts.professions),
        spells      = opts.spells or {}, 
        actionBar   = opts.actionBar or {},
        resourceDisplaySettings = opts.resourceDisplaySettings or {},
    }, self)
    
    -- Ensure resourceDisplaySettings has proper defaults if empty
    self:_InitializeResourceDisplaySettings()

    return o
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


function CharacterProfile:RecalculateEquipmentStats()
    RPE.Debug:Internal(string.format("Recalculating equipment stats for profile: %s", self.name or "?"))

    -- Clear all existing equip mods
    RPE.Core.StatModifiers.equip = {}

    for slot, itemId in pairs(self.equipment or {}) do
        local item = RPE.Core.ItemRegistry and RPE.Core.ItemRegistry:Get(itemId)
        if item then
            -- Re-apply its equip mods
            for k, v in pairs(item.data or {}) do
                if type(k) == "string" and k:match("^stat%_") then
                    local statId = k:sub(6) -- strip "stat_"
                    local delta  = tonumber(v) or 0
                    if delta ~= 0 and RPE.Stats and RPE.Stats.Get then
                        local stat = RPE.Stats:Get(statId)
                        if stat then
                            -- Check ruleset
                            if RPE.ActiveRules and RPE.ActiveRules:IsStatEnabled(statId, stat.category) then
                                stat:SetEquipMod((stat.equipMod or 0) + delta)
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
--- Get or create a stat object.
---@param id string
---@param category StatCategory|nil
---@return CharacterStat
function CharacterProfile:GetStat(id, category)
    local s = self.stats[id]
    if not s then
        s = CharacterStat:New(id, category or "PRIMARY", 0)
        self.stats[id] = s
    end
    return s
end

--- Convenience: set base value (persisted).
function CharacterProfile:SetStatBase(id, value, category)
    local s = self:GetStat(id, category)
    s:SetBase(tonumber(value) or 0)
    touch(self)
end

--- Convenience: set equipment modifier (transient).
function CharacterProfile:SetStatEquipMod(id, value)
    local s = self:GetStat(id)
    s:SetEquipMod(tonumber(value) or 0)
end

--- Convenience: set aura modifier (transient).
function CharacterProfile:SetStatAuraMod(id, value)
    local s = self:GetStat(id)
    s:SetAuraMod(tonumber(value) or 0)
end

--- Convenience: effective value (clamped).
function CharacterProfile:GetStatValue(id)
    local s = self.stats[id]
    return s and s:GetValue(self) or 0
end

--- Clear all transient modifiers (equipment + auras).
function CharacterProfile:ClearTransientMods()
    for _, s in pairs(self.stats) do
        s:SetEquipMod(0)
        s:SetAuraMod(self, 0)   -- <<< pass profile
    end
end

--- Optional: export just base values for UI/debug.
function CharacterProfile:GetBaseStatTable()
    local t = {}
    for id, s in pairs(self.stats) do
        t[id] = s.base
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
    for id, s in pairs(self.stats or {}) do
        statsOut[id] = s:ToTable()
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

