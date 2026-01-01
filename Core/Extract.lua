-- RPE/Core/Extract.lua
-- General extraction system for breaking down items (disenchanting and prospecting)

RPE = RPE or {}
RPE.Core = RPE.Core or {}

---@class Extract
---@field ParseTag function
---@field Extract function
local Extract = {}
RPE.Core.Extract = Extract

-- Tag format: <extractionType>:reagentType:tier:minQty-maxQty:chance
-- Examples: 
--   disenchant:dust:0:1-3:0.5
--   prospect:roughgem:0:1-1:0.5
-- Meaning: extract into tier 0 reagent, 1-3 quantity, 50% chance

---Parse an extraction tag into its components
---@param tag string The tag to parse (e.g., "disenchant:dust:0:1-3:0.5" or "prospect:roughgem:0:1-1:0.5")
---@return table|nil tagInfo Table with fields: extractType, reagentType, tier, minQty, maxQty, chance
local function ParseTag(tag)
    if not tag or type(tag) ~= "string" then return nil end
    
    local parts = {}
    for part in tag:gmatch("[^:]+") do
        table.insert(parts, part)
    end
    
    if #parts < 5 then
        return nil
    end
    
    local extractType = parts[1]
    -- Only accept extraction tags (disenchant or prospect)
    if extractType ~= "disenchant" and extractType ~= "prospect" then
        return nil
    end
    
    local reagentType = parts[2]
    local tier = tonumber(parts[3])
    local qtyRange = parts[4]
    local chance = tonumber(parts[5])
    
    if not reagentType or not tier or not qtyRange or not chance then
        return nil
    end
    
    -- Parse quantity range (e.g., "1-3")
    local minQty, maxQty = qtyRange:match("(%d+)-(%d+)")
    minQty = tonumber(minQty)
    maxQty = tonumber(maxQty)
    
    if not minQty or not maxQty then
        return nil
    end
    
    return {
        extractType = extractType,
        reagentType = reagentType,
        tier = tier,
        minQty = minQty,
        maxQty = maxQty,
        chance = chance,
    }
end

---Find a reagent by type and tier
---@param reagentType string The reagent type (e.g., "dust", "roughgem")
---@param tier number The tier level
---@return string|nil reagentId The item ID of the reagent, or nil if not found
local function FindReagent(reagentType, tier)
    local Reagents = RPE.Data and RPE.Data.DefaultCommon and RPE.Data.DefaultCommon.REAGENTS
    if not Reagents then return nil end
    
    local matchingReagents = {}
    
    for itemId, reagent in pairs(Reagents) do
        if reagent.tags and reagent.data then
            local hasType = false
            local hasTier = false
            
            -- Check if reagent type is in tags
            for _, tag in ipairs(reagent.tags) do
                if tag == reagentType then
                    hasType = true
                    break
                end
            end
            
            -- Check if tier matches in data
            if reagent.data.tier == tier then
                hasTier = true
            end
            
            if hasType and hasTier then
                table.insert(matchingReagents, itemId)
            end
        end
    end
    
    if #matchingReagents == 0 then
        return nil
    end
    
    -- Randomly select from matching reagents
    return matchingReagents[math.random(#matchingReagents)]
end

---Perform extraction on an item (disenchanting or prospecting)
---@param item table The item object with tags
---@return table|nil result Table with fields: success (bool), reagentId (string), quantity (number), message (string)
function Extract:Extract(item)
    if not item or not item.tags then
        return {
            success = false,
            message = "Item cannot be extracted.",
        }
    end
    
    -- Collect all extraction tags (both disenchant and prospect) with their probabilities
    local extractOptions = {}
    local totalChance = 0
    local extractType = nil
    
    for _, tag in ipairs(item.tags) do
        local tagInfo = ParseTag(tag)
        if tagInfo then
            if not extractType then
                extractType = tagInfo.extractType
            end
            table.insert(extractOptions, tagInfo)
            totalChance = totalChance + tagInfo.chance
        end
    end
    
    if #extractOptions == 0 then
        return {
            success = false,
            message = "This item has no extraction information.",
        }
    end
    
    -- Pick one extraction option based on weighted probability
    local roll = math.random() * totalChance
    local runningTotal = 0
    local selectedTagInfo = nil
    
    for _, tagInfo in ipairs(extractOptions) do
        runningTotal = runningTotal + tagInfo.chance
        if roll <= runningTotal then
            selectedTagInfo = tagInfo
            break
        end
    end
    
    if not selectedTagInfo then
        selectedTagInfo = extractOptions[#extractOptions]
    end
    
    -- Find reagent
    local reagentId = FindReagent(selectedTagInfo.reagentType, selectedTagInfo.tier)
    if not reagentId then
        return {
            success = false,
            message = string.format("No tier %d %s reagent found in database.", selectedTagInfo.tier, selectedTagInfo.reagentType),
        }
    end
    
    -- Roll quantity
    local quantity = math.random(selectedTagInfo.minQty, selectedTagInfo.maxQty)
    
    local extractionVerb = selectedTagInfo.extractType == "disenchant" and "disenchanted" or "prospected"
    
    return {
        success = true,
        reagentId = reagentId,
        quantity = quantity,
        message = string.format("Successfully %s! Received %d x %s.", extractionVerb, quantity, item.name or "reagent"),
    }
end

---Export the parse function for testing
function Extract:ParseTag(tag)
    return ParseTag(tag)
end

return Extract
