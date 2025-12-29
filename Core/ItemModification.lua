-- RPE/Core/ItemModification.lua
-- Handles applying modifications (enchants, gems, etc.) to equipment items.
-- Modifications are stored as data on inventory item slots.
-- When an item is equipped, its stored modifications are applied as stat bonuses.
-- Items must be in inventory (unequipped) to apply modifications.

RPE = RPE or {}
RPE.Core = RPE.Core or {}

local ItemModification = {}
RPE.Core.ItemModification = ItemModification

local ItemRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
local StatModifiers = _G.RPE and _G.RPE.Core and _G.RPE.Core.StatModifiers
local ActiveRules = _G.RPE and _G.RPE.ActiveRules

-- === Utility Functions ===

--- Extract stat bonuses from a modification item's data.
---@param modificationItem Item
---@return table -- { statId = bonusAmount, ... }
local function getModificationBonuses(modificationItem)
    if not modificationItem or not modificationItem.data then return {} end
    
    local bonuses = {}
    for key, value in pairs(modificationItem.data) do
        if type(key) == "string" and key:match("^stat_") then
            local statId = key:sub(6)  -- Remove "stat_" prefix
            bonuses[statId] = tonumber(value) or 0
        end
    end
    return bonuses
end

--- Normalize property for comparison (case-insensitive, trim whitespace).
---@param prop string|nil
---@return string
local function normalizeProp(prop)
    if not prop then return "" end
    return tostring(prop):lower():gsub("%s+", "")
end

--- Count existing modifications by tag on an item instance.
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the item
---@param tag string
---@return number count
local function countModsByTag(profile, instanceGuid, tag)
    -- Find the inventory slot with this instance GUID
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot or not invSlot.mods then return 0 end
    
    local count = 0
    for modKey, modData in pairs(invSlot.mods) do
        if type(modKey) == "string" and modKey:match("^mod_") and type(modData) == "table" then
            local modItemId = modData.itemId
            if modItemId then
                local modItem = ItemRegistry and ItemRegistry:Get(modItemId)
                if modItem and modItem.tags then
                    for _, modTag in ipairs(modItem.tags) do
                        if modTag == tag then
                            count = count + 1
                            break
                        end
                    end
                end
            end
        end
    end
    
    return count
end

--- Count existing gems of a specific socket type on an item instance.
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the item
---@param socketType string -- e.g., "red"
---@return number count
local function countGemsInSocket(profile, instanceGuid, socketType)
    -- Find the inventory slot with this instance GUID
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot or not invSlot.mods then return 0 end
    
    local normalizedType = normalizeProp(socketType)
    local count = 0
    
    for modKey, modData in pairs(invSlot.mods) do
        if type(modKey) == "string" and modKey:match("^mod_") and type(modData) == "table" then
            local modItemId = modData.itemId
            if modItemId then
                local modItem = ItemRegistry and ItemRegistry:Get(modItemId)
                if modItem and modItem.tags then
                    -- Check if this is a gem
                    local isGem = false
                    for _, tag in ipairs(modItem.tags) do
                        if tag == "gem" then
                            isGem = true
                            break
                        end
                    end
                    
                    if isGem and modItem.data and modItem.data.socket_type then
                        -- Check if this gem fits in the requested socket type
                        local gemTypes = {}
                        for gtype in modItem.data.socket_type:gmatch("[^,]+") do
                            local normalized = normalizeProp(gtype)
                            if normalized ~= "" then
                                gemTypes[normalized] = true
                            end
                        end
                        
                        if gemTypes[normalizedType] then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    
    return count
end

--- Check if a gem modification can fit into target item's sockets.
---@param gemItem Item -- the gem modification
---@param targetItem Item -- the item being modified
---@return boolean canFit
---@return string|nil reason
local function canGemFitInSockets(gemItem, targetItem)
    if not gemItem or not targetItem then return false, "Missing item data" end
    
    -- Gem must have socket_type
    local gemSocketType = gemItem.data and gemItem.data.socket_type
    if not gemSocketType then
        return false, "Gem modification must have socket_type"
    end
    
    -- Parse gem socket types (e.g., "red" or "red, blue")
    local gemTypes = {}
    for socketType in gemSocketType:gmatch("[^,]+") do
        local normalized = normalizeProp(socketType)
        if normalized ~= "" then
            gemTypes[normalized] = true
        end
    end
    
    if next(gemTypes) == nil then
        return false, "Gem socket_type is empty"
    end
    
    -- Target item must have socket capacity
    local socketMaps = {
        red       = "red_sockets",
        blue      = "blue_sockets",
        yellow    = "yellow_sockets",
        meta      = "meta_sockets",
        cogwheel  = "cog_sockets",
    }
    
    local hasAnySocket = false
    for gemType in pairs(gemTypes) do
        local socketKey = socketMaps[gemType]
        if socketKey then
            local count = tonumber(targetItem.data[socketKey]) or 0
            if count > 0 then
                hasAnySocket = true
                break
            end
        end
    end
    
    if not hasAnySocket then
        return false, "Item has no matching sockets for this gem"
    end
    
    return true
end

--- Check if a modification is compatible with a target item instance.
---@param modItem Item -- the modification item
---@param targetItem Item -- the item being modified
---@param profile CharacterProfile -- needed for tag/socket counts
---@param instanceGuid string -- the instance GUID of the target item
---@return boolean compatible
---@return string|nil reason -- error message if not compatible
local function isModificationCompatible(modItem, targetItem, profile, instanceGuid)
    if not modItem or not modItem.data or not targetItem or not targetItem.data then
        return false, "Missing item data"
    end
    
    -- Check slot compatibility
    local modSlot = modItem.data.slot
    local targetSlot = targetItem.data.slot
    
    if modSlot and targetSlot then
        if normalizeProp(modSlot) ~= normalizeProp(targetSlot) then
            return false, string.format(
                "Modification requires slot '%s' but item is in slot '%s'",
                modSlot, targetSlot
            )
        end
    elseif modSlot and not targetSlot then
        return false, string.format("Item must be equipped in slot '%s'", modSlot)
    end
    
    -- Check weaponType compatibility
    local modWeaponType = modItem.data.weaponType
    local targetWeaponType = targetItem.data.weaponType
    
    if modWeaponType and targetWeaponType then
        if normalizeProp(modWeaponType) ~= normalizeProp(targetWeaponType) then
            return false, string.format(
                "Modification requires weaponType '%s' but item is '%s'",
                modWeaponType, targetWeaponType
            )
        end
    elseif modWeaponType and not targetWeaponType then
        return false, string.format("Item must be weaponType '%s'", modWeaponType)
    end
    
    -- Check armorType compatibility
    local modArmorType = modItem.data.armorType
    local targetArmorType = targetItem.data.armorType
    
    if modArmorType and targetArmorType then
        if normalizeProp(modArmorType) ~= normalizeProp(targetArmorType) then
            return false, string.format(
                "Modification requires armorType '%s' but item is '%s'",
                modArmorType, targetArmorType
            )
        end
    elseif modArmorType and not targetArmorType then
        return false, string.format("Item must be armorType '%s'", modArmorType)
    end
    
    -- Check accessoryType compatibility
    local modAccessoryType = modItem.data.accessoryType
    local targetAccessoryType = targetItem.data.accessoryType
    
    if modAccessoryType and targetAccessoryType then
        if normalizeProp(modAccessoryType) ~= normalizeProp(targetAccessoryType) then
            return false, string.format(
                "Modification requires accessoryType '%s' but item is '%s'",
                modAccessoryType, targetAccessoryType
            )
        end
    elseif modAccessoryType and not targetAccessoryType then
        return false, string.format("Item must be accessoryType '%s'", modAccessoryType)
    end
    
    -- Check armorMaterial compatibility
    local modArmorMaterial = modItem.data.armorMaterial
    local targetArmorMaterial = targetItem.data.armorMaterial
    
    if modArmorMaterial and targetArmorMaterial then
        local normalizedMod = normalizeProp(modArmorMaterial)
        local normalizedTarget = normalizeProp(targetArmorMaterial)
        if normalizedMod ~= "any" and normalizedMod ~= normalizedTarget then
            return false, string.format(
                "Modification requires armorMaterial '%s' but item is '%s'",
                modArmorMaterial, targetArmorMaterial
            )
        end
    elseif modArmorMaterial and not targetArmorMaterial then
        return false, string.format("Item must be armorMaterial '%s'", modArmorMaterial)
    end
    
    -- Check hand compatibility (for weapons)
    local modHand = modItem.data.hand
    local targetHand = targetItem.data.hand
    
    if modHand and targetHand then
        if normalizeProp(modHand) ~= normalizeProp(targetHand) then
            return false, string.format(
                "Modification requires '%s' but item is '%s'",
                modHand, targetHand
            )
        end
    elseif modHand and not targetHand then
        return false, string.format("Item must be '%s'", modHand)
    end
    
    -- Check tag-based limits
    if modItem.tags and #modItem.tags > 0 then
        local primaryTag = modItem.tags[1]
        
        if primaryTag == "gem" then
            -- For gems, check socket compatibility
            local canFit, gemReason = canGemFitInSockets(modItem, targetItem)
            if not canFit then
                return false, gemReason
            end
            
            -- Also check if gem can fit in available sockets
            local gemSocketType = modItem.data.socket_type
            if gemSocketType then
                for socketType in gemSocketType:gmatch("[^,]+") do
                    local normalized = normalizeProp(socketType)
                    local socketKey = nil
                    
                    if normalized == "red" then socketKey = "red_sockets"
                    elseif normalized == "blue" then socketKey = "blue_sockets"
                    elseif normalized == "yellow" then socketKey = "yellow_sockets"
                    elseif normalized == "meta" then socketKey = "meta_sockets"
                    elseif normalized == "cogwheel" then socketKey = "cog_sockets"
                    end
                    
                    if socketKey then
                        local maxSockets = tonumber(targetItem.data[socketKey]) or 0
                        local usedSockets = countGemsInSocket(profile, instanceGuid, socketType)
                        
                        if usedSockets < maxSockets then
                            return true  -- Found an available socket
                        end
                    end
                end
                
                return false, "No available sockets for this gem"
            end
        else
            -- Non-gem: check max_[tag] limit
            -- Priority: item data > active rules > default (999)
            local maxKey = "max_" .. primaryTag
            local maxCount = tonumber(targetItem.data[maxKey])
            
            if not maxCount then
                -- Check ActiveRules if item didn't specify
                maxCount = tonumber(RPE.ActiveRules:Get(maxKey, 1))
            end
            
            -- Default to unlimited if neither item nor rules specify
            maxCount = maxCount or 1
            
            local currentCount = countModsByTag(profile, instanceGuid, primaryTag)
            
            if currentCount >= maxCount then
                return false, string.format(
                    "Cannot add more %s modifications (max: %d, current: %d)",
                    primaryTag, maxCount, currentCount
                )
            end
        end
    end
    
    return true
end

-- === Public API ===

--- Apply a modification to an item instance in inventory.
--- The item must be unequipped (in inventory) to apply modifications.
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the EQUIPMENT item (must be in inventory)
---@param modificationItemId string -- ID of the MODIFICATION item to apply
---@param modificationInstanceGuid string|nil -- instance GUID of the specific modification to consume (optional, for handling duplicates)
---@return boolean success
function ItemModification:ApplyModification(profile, instanceGuid, modificationItemId, modificationInstanceGuid)
    if not profile or not instanceGuid or not modificationItemId then
        RPE.Debug:Error("ItemModification:ApplyModification - missing parameters")
        return false
    end
    
    -- Verify the item instance is in inventory (NOT equipped)
    local invSlotIndex = nil
    local invSlot = nil
    for idx, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlotIndex = idx
            invSlot = slot
            break
        end
    end
    
    if not invSlotIndex then
        RPE.Debug:Error(string.format("ItemModification:ApplyModification - item not in inventory: %s", instanceGuid))
        return false
    end
    
    local itemId = invSlot.id
    
    -- Verify item is not currently equipped
    for _, eqItemId in pairs(profile.equipment or {}) do
        if eqItemId == itemId then
            RPE.Debug:Error(string.format("ItemModification:ApplyModification - item is currently equipped, unequip first: %s", itemId))
            return false
        end
    end
    
    local equippedItem = ItemRegistry and ItemRegistry:Get(itemId)
    if not equippedItem or equippedItem.category ~= "EQUIPMENT" then
        RPE.Debug:Error(string.format("ItemModification:ApplyModification - item must be EQUIPMENT category: %s", itemId))
        return false
    end
    
    -- Verify the modification item exists and is in inventory
    local modItem = ItemRegistry and ItemRegistry:Get(modificationItemId)
    if not modItem or modItem.category ~= "MODIFICATION" then
        RPE.Debug:Error(string.format("ItemModification:ApplyModification - modification item not found or invalid: %s", modificationItemId))
        return false
    end
    
    if not profile:HasItem(modificationItemId, 1) then
        RPE.Debug:Error(string.format("ItemModification:ApplyModification - modification item not in inventory: %s", modificationItemId))
        return false
    end
    
    -- Check compatibility (slot, hand, tags, and sockets)
    local compatible, reason = isModificationCompatible(modItem, equippedItem, profile, instanceGuid)
    if not compatible then
        RPE.Debug:Error(string.format("ItemModification:ApplyModification - incompatible: %s", reason or "unknown"))
        return false
    end
    
    -- Initialize mods table on the inventory slot if needed
    invSlot.mods = invSlot.mods or {}
    
    -- Generate a unique mod key for this application (allows multiple of same mod type)
    local modIndex = 1
    local modKey = "mod_" .. modificationItemId .. "_" .. modIndex
    while invSlot.mods[modKey] do
        modIndex = modIndex + 1
        modKey = "mod_" .. modificationItemId .. "_" .. modIndex
    end
    
    -- Store the modification on the inventory slot
    invSlot.mods[modKey] = {
        itemId = modificationItemId,
        appliedAt = time() or 0,
    }
    
    -- Consume one of the modification items from inventory
    -- If modificationInstanceGuid is provided, remove that specific instance
    if modificationInstanceGuid then
        for idx, slot in ipairs(profile.items or {}) do
            if slot.instanceGuid == modificationInstanceGuid then
                -- Decrement qty or remove the slot
                slot.qty = math.max(0, (slot.qty or 1) - 1)
                if slot.qty == 0 then
                    table.remove(profile.items, idx)
                end
                break
            end
        end
    else
        -- Fallback: remove by item ID (first one found)
        profile:RemoveItem(modificationItemId, 1)
    end
    
    -- Persist changes
    if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
        RPE.Profile.DB.SaveProfile(profile)
    end
    
    return true
end

--- Remove a modification from an item instance in inventory.
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the item
---@param modificationItemId string -- ID of the modification to remove
---@return boolean success
function ItemModification:RemoveModification(profile, instanceGuid, modificationItemId)
    if not profile or not instanceGuid or not modificationItemId then
        RPE.Debug:Error("ItemModification:RemoveModification - missing parameters")
        return false
    end
    
    -- Find the item instance in inventory
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot or not invSlot.mods then
        RPE.Debug:Warning(string.format("ItemModification:RemoveModification - item or mods not found: %s", instanceGuid))
        return false
    end
    
    -- Find a mod key matching this modification item ID (handles indexed keys like mod_itemid_1)
    local modKey = nil
    for key, modData in pairs(invSlot.mods) do
        if type(key) == "string" and key:match("^mod_") then
            local modItemId = modData.itemId
            if modItemId == modificationItemId then
                modKey = key
                break
            end
        end
    end
    
    if not modKey then
        RPE.Debug:Warning(string.format("ItemModification:RemoveModification - modification not found: %s", modificationItemId))
        return false
    end
    
    local modItem = ItemRegistry and ItemRegistry:Get(modificationItemId)
    if not modItem then
        RPE.Debug:Error(string.format("ItemModification:RemoveModification - modification item definition not found: %s", modificationItemId))
        return false
    end
    
    -- Remove from inventory slot
    invSlot.mods[modKey] = nil
    
    -- Persist changes
    if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
        RPE.Profile.DB.SaveProfile(profile)
    end
    
    return true
end

--- Get all modifications applied to an item instance (in inventory or equipped).
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the item
---@return table -- array of { itemId, name, bonuses, appliedAt, ... }
function ItemModification:GetAppliedModifications(profile, instanceGuid)
    if not profile or not instanceGuid then return {} end
    
    -- First, try to find the item instance in inventory
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    -- If not in inventory, try to find it in equipped slots
    local mods = nil
    if invSlot and invSlot.mods then
        mods = invSlot.mods
    else
        -- Check equipped slots by instance GUID
        if profile._equippedMods then
            mods = profile._equippedMods[instanceGuid]
        end
    end
    
    if not mods then return {} end
    
    local applied = {}
    
    for modKey, modData in pairs(mods) do
        if type(modKey) == "string" and modKey:match("^mod_") then
            local modItemId = modData.itemId or modKey:sub(5)
            local modItem = ItemRegistry and ItemRegistry:Get(modItemId)
            
            if modItem then
                table.insert(applied, {
                    modKey = modKey,
                    itemId = modItemId,
                    name = modItem.name,
                    description = modItem.description,
                    bonuses = getModificationBonuses(modItem),
                    appliedAt = modData.appliedAt or 0,
                    icon = modItem.icon,
                    rarity = modItem.rarity,
                })
            end
        end
    end
    
    return applied
end

--- Remove a modification by its specific modKey.
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the item
---@param modKey string -- the specific mod key (e.g., "mod_gemid_1")
---@param returnToInventory boolean -- whether to return the mod item to inventory (default true)
---@return boolean success
function ItemModification:RemoveModificationByKey(profile, instanceGuid, modKey, returnToInventory)
    if returnToInventory == nil then returnToInventory = true end
    if not profile or not instanceGuid or not modKey then
        RPE.Debug:Error("ItemModification:RemoveModificationByKey - missing parameters")
        return false
    end
    
    -- Find the item instance in inventory
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot or not invSlot.mods then
        RPE.Debug:Warning(string.format("ItemModification:RemoveModificationByKey - item or mods not found: %s", instanceGuid))
        return false
    end
    
    local modData = invSlot.mods[modKey]
    if not modData then
        RPE.Debug:Warning(string.format("ItemModification:RemoveModificationByKey - mod key not found: %s", modKey))
        return false
    end
    
    local modItemId = modData.itemId
    local modItem = ItemRegistry and ItemRegistry:Get(modItemId)
    if not modItem then
        RPE.Debug:Error(string.format("ItemModification:RemoveModificationByKey - modification item definition not found: %s", modItemId))
        return false
    end
    
    -- Remove from inventory slot
    invSlot.mods[modKey] = nil
    
    -- Persist changes
    if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
        RPE.Profile.DB.SaveProfile(profile)
    end
    
    return true
end

--- Check if a modification can be applied to an item instance (without applying it).
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the EQUIPMENT item
---@param modificationItemId string -- ID of the MODIFICATION item
---@return boolean canApply
---@return string|nil reason -- error message if cannot apply
function ItemModification:CanApplyModification(profile, instanceGuid, modificationItemId)
    if not profile or not instanceGuid or not modificationItemId then
        return false, "Missing parameters"
    end
    
    -- Find the item instance in inventory
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot then
        return false, "Item not in inventory"
    end
    
    local itemId = invSlot.id
    local equippedItem = ItemRegistry and ItemRegistry:Get(itemId)
    if not equippedItem or equippedItem.category ~= "EQUIPMENT" then
        return false, "Item must be EQUIPMENT category"
    end
    
    -- Verify the modification item exists
    local modItem = ItemRegistry and ItemRegistry:Get(modificationItemId)
    if not modItem or modItem.category ~= "MODIFICATION" then
        return false, "Modification item not found or invalid"
    end
    
    -- Check if player has the modification in inventory
    if not profile:HasItem(modificationItemId, 1) then
        return false, "Modification not in inventory"
    end
    
    -- Check compatibility (slot, hand, tags, and sockets)
    return isModificationCompatible(modItem, equippedItem, profile, instanceGuid)
end

--- Check if a modification is compatible with an item (ignoring inventory check).
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the EQUIPMENT item
---@param modificationItemId string -- ID of the MODIFICATION item
---@return boolean compatible
---@return string|nil reason -- error message if not compatible
function ItemModification:IsModificationCompatible(profile, instanceGuid, modificationItemId)
    if not profile or not instanceGuid or not modificationItemId then
        return false, "Missing parameters"
    end
    
    -- Find the item instance in inventory
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot then
        return false, "Item not in inventory"
    end
    
    local itemId = invSlot.id
    local equippedItem = ItemRegistry and ItemRegistry:Get(itemId)
    if not equippedItem or equippedItem.category ~= "EQUIPMENT" then
        return false, "Item must be EQUIPMENT category"
    end
    
    -- Verify the modification item exists
    local modItem = ItemRegistry and ItemRegistry:Get(modificationItemId)
    if not modItem or modItem.category ~= "MODIFICATION" then
        return false, "Modification item not found or invalid"
    end
    
    -- Check compatibility (slot, hand, tags, and sockets) - ignores inventory check
    return isModificationCompatible(modItem, equippedItem, profile, instanceGuid)
end

--- Check if a modification is applied to an item instance.
---@param profile CharacterProfile
---@param instanceGuid string
---@param modificationItemId string
---@return boolean
function ItemModification:HasModification(profile, instanceGuid, modificationItemId)
    if not profile or not instanceGuid or not modificationItemId then return false end
    
    -- Find the item instance in inventory
    local invSlot = nil
    for _, slot in ipairs(profile.items or {}) do
        if slot.instanceGuid == instanceGuid then
            invSlot = slot
            break
        end
    end
    
    if not invSlot or not invSlot.mods then return false end
    
    -- Check for any mod key that contains this modification item ID
    for modKey, modData in pairs(invSlot.mods) do
        if type(modKey) == "string" and modKey:match("^mod_") then
            if modData.itemId == modificationItemId then
                return true
            end
        end
    end
    return false
end

--- Get total stat bonuses from all applied modifications to an item instance.
---@param profile CharacterProfile
---@param instanceGuid string -- instance GUID of the item
---@return table -- { statId = totalBonus, ... }
function ItemModification:GetTotalModificationBonuses(profile, instanceGuid)
    if not profile or not instanceGuid then return {} end
    
    local applied = self:GetAppliedModifications(profile, instanceGuid)
    local totals = {}
    
    for _, modData in ipairs(applied) do
        for statId, bonus in pairs(modData.bonuses) do
            totals[statId] = (totals[statId] or 0) + bonus
        end
    end
    
    return totals
end

--- Clear all modifications from an item instance in inventory (returns them to inventory).
---@param profile CharacterProfile
---@param instanceGuid string
---@return number -- count of modifications removed
function ItemModification:ClearModifications(profile, instanceGuid)
    if not profile or not instanceGuid then return 0 end
    
    local applied = self:GetAppliedModifications(profile, instanceGuid)
    local count = 0
    
    for _, modData in ipairs(applied) do
        if self:RemoveModification(profile, instanceGuid, modData.itemId) then
            count = count + 1
        end
    end
    
    return count
end

--- Get modifications for an equipped item by its equipment slot.
---@param profile CharacterProfile
---@param slot string -- equipment slot (e.g., "mainhand")
---@return table -- array of { itemId, name, bonuses, appliedAt, ... }
function ItemModification:GetModificationsForEquippedSlot(profile, slot)
    if not profile or not slot then return {} end
    
    local equippedItemId = profile.equipment and profile.equipment[slot]
    if not equippedItemId then return {} end
    
    -- Get mods from equipped storage
    local mods = profile._equippedMods and profile._equippedMods[slot]
    if not mods then return {} end
    
    local applied = {}
    
    for modKey, modData in pairs(mods) do
        if type(modKey) == "string" and modKey:match("^mod_") then
            local modItemId = modData.itemId or modKey:sub(5)
            local modItem = ItemRegistry and ItemRegistry:Get(modItemId)
            
            if modItem then
                table.insert(applied, {
                    itemId = modItemId,
                    name = modItem.name,
                    description = modItem.description,
                    bonuses = getModificationBonuses(modItem),
                    appliedAt = modData.appliedAt or 0,
                    icon = modItem.icon,
                    rarity = modItem.rarity,
                })
            end
        end
    end
    
    return applied
end

