-- RPE/Core/HarvestNode.lua
RPE = RPE or {}
RPE.Core = RPE.Core or {}

local HarvestNode = {}
RPE.Core.HarvestNode = HarvestNode

-- Track last hovered node
local lastNodeName = nil
local lastTooltipUpdate = 0

-- Get item registry
local function getItemRegistry()
    local registry = RPE.Core and RPE.Core.ItemRegistry
    if not registry then 
        return nil
    end
    
    -- Check if registry is empty and try to refresh it
    local items = registry.All and registry:All() or registry._items or {}
    local isEmpty = true
    for _ in pairs(items) do
        isEmpty = false
        break
    end
    
    if isEmpty and registry.RefreshFromActiveDatasets then
        local count = registry:RefreshFromActiveDatasets()
    end
    
    return registry
end

-- Parse quantity range from tag like "0-3" or "2" 
local function parseQuantityRange(quantityStr)
    if not quantityStr or quantityStr == "" then
        return 1, 1 -- default to 1
    end
    
    local min, max = quantityStr:match("^(%d+)-(%d+)$")
    if min and max then
        return tonumber(min), tonumber(max)
    end
    
    local single = tonumber(quantityStr)
    if single then
        return single, single
    end
    
    return 1, 1 -- fallback
end

-- Find items that can drop from a specific node
local function getNodeDrops(nodeName)
    local itemRegistry = getItemRegistry()
    if not itemRegistry then 
        RPE.Debug:Warning("[HarvestNode] ItemRegistry not found")
        return {} 
    end
    
    local drops = {}
    local items = itemRegistry.All and itemRegistry:All() or itemRegistry._items or {}
    local nodeNameLower = nodeName:lower()
    
    for itemId, item in pairs(items) do
        if item and item.tags then
            for _, tag in ipairs(item.tags) do
                if type(tag) == "string" and tag:sub(1, 5) == "node:" then
                    -- Parse tag: "node:profession:nodeName:quantity"
                    local profession, nodeTag, quantity = tag:match("^node:([^:]+):([^:]+):?(.*)$")
                    if nodeTag and nodeTag:lower() == nodeNameLower then
                        local minQty, maxQty = parseQuantityRange(quantity)
                        table.insert(drops, {
                            item = item,
                            profession = profession,  -- Store profession from tag
                            minQuantity = minQty,
                            maxQuantity = maxQty
                        })
                    end
                end
            end
        end
    end
    
    return drops
end

-- Add item to player inventory (if system exists)
local function addToInventory(item, quantity)
    -- Get the active character profile
    local DB = RPE and RPE.Profile and RPE.Profile.DB
    if not DB then return end
    
    local profile = DB.GetOrCreateActive and DB:GetOrCreateActive()
    if not profile then return end
    
    if profile.AddItem then
        profile:AddItem(item.id, quantity)
    end
end

-- Determine which profession is required for a node
local function getRequiredProfession(nodeName, drops)
    -- Get profession from the first drop that matches (all should have same profession)
    if drops and #drops > 0 then
        return drops[1].profession
    end
    return nil
end

-- Check if player has the required profession
local function hasRequiredProfession(profession)
    if not profession then return true end -- No profession required
    
    local DB = RPE and RPE.Profile and RPE.Profile.DB
    if not DB then return false end
    
    local profile = DB.GetOrCreateActive and DB:GetOrCreateActive()
    if not profile then return false end
    
    -- Use the CharacterProfile helper method to check profession level
    return profile:HasProfession(profession)
end

-- Show floating combat text for harvest
local function showHarvestText(item, quantity)
    local fct = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.FloatingCombatText
    if not fct then return end
    
    -- Try to find or create a global FCT instance
    local harvestFCT = _G.RPE_HarvestFCT
    if not harvestFCT then
        harvestFCT = fct:New("RPE_HarvestFCT", {
            parent = WorldFrame,
            setAllPoints = true,
            direction = "UP",
            onlyWhenUIHidden = false,
            maxActive = 12,
            duration = 2.5,
            scrollDistance = 80,
            spawnRadiusMin = 40,
            spawnRadiusMax = 120,
            angleSpreadDeg = 45
        })
        _G.RPE_HarvestFCT = harvestFCT
    end
    
    local text = string.format("+%d %s", quantity, item.name or item.id)
    harvestFCT:AddText(text, {
        variant = "textBonus",
        icon = item.icon,
        x = math.random(-50, 50),
        y = math.random(-20, 20)
    })
end

-- Initialize the harvest system
function HarvestNode:Initialize()
    if self._initialized then return end
    self._initialized = true
    
    -- Create event frame
    local frame = CreateFrame("Frame", "RPE_HarvestNodeFrame")
    frame:RegisterEvent("LOOT_OPENED")
    self.frame = frame
    
    -- Hook GameTooltip to detect node names
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnUpdate", function(tooltip)
            local now = GetTime()
            if now - lastTooltipUpdate < 0.1 then return end
            lastTooltipUpdate = now
            
            if tooltip:IsShown() then
                local text = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
                if text and text ~= "" then
                    -- Check if this might be a harvestable node by looking for items with this node name
                    local drops = getNodeDrops(text)
                    if #drops > 0 then
                        lastNodeName = text
                        -- Add indicator to tooltip (only if not already there)
                        local hasIndicator = false
                        for i = 1, tooltip:NumLines() do
                            local line = _G["GameTooltipTextLeft" .. i]
                            if line and line:GetText() and line:GetText():find("Reagent Node") then
                                hasIndicator = true
                                break
                            end
                        end
                        if not hasIndicator then
                            tooltip:AddLine(" ")
                            local iconStr = (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.RPE) or ""
                            
                            -- Check profession and set color accordingly
                            local drops = getNodeDrops(text)
                            local profession = getRequiredProfession(text, drops)
                            local hasProfession = hasRequiredProfession(profession)
                            local r, g, b
                            if hasProfession then
                                -- Green for can harvest
                                r, g, b = 0.0, 1.0, 0.0
                            else
                                -- Red for cannot harvest
                                r, g, b = 1.0, 0.00, 0.00
                            end
                            
                            tooltip:AddLine(iconStr .. " Reagent Node", r, g, b)
                            
                            -- Add requirement text if profession is missing
                            if profession and not hasProfession then
                                local professionTitle = string.upper(string.sub(profession, 1, 1)) .. string.lower(string.sub(profession, 2))
                                tooltip:AddLine("(Requires RPE " .. professionTitle .. ")", r, g, b)
                            end
                            
                            tooltip:Show()
                        end
                    end
                end
            end
        end)
    end
    
    -- Handle loot events
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "LOOT_OPENED" then
            if lastNodeName then
                HarvestNode:ProcessNodeHarvest(lastNodeName)
                lastNodeName = nil -- Clear after processing
            end
        end
    end)
end

-- Process harvesting a node
function HarvestNode:ProcessNodeHarvest(nodeName)
    if not nodeName then return end
    
    local drops = getNodeDrops(nodeName)
    if #drops == 0 then return end
    
    -- Check if player has required profession for ANY of the drops
    local hasAllRequiredProfs = true
    local profession = nil
    for _, drop in ipairs(drops) do
        if drop.profession and not hasRequiredProfession(drop.profession) then
            hasAllRequiredProfs = false
            break
        end
        -- Store the first profession (all drops should have the same one)
        if not profession and drop.profession then
            profession = drop.profession
        end
    end
    
    -- If player lacks the profession, don't add items
    if not hasAllRequiredProfs then return end
    
    local DB = RPE and RPE.Profile and RPE.Profile.DB
    local profile = DB and DB.GetOrCreateActive and DB:GetOrCreateActive()
    
    for _, drop in ipairs(drops) do
        local quantity = math.random(drop.minQuantity, drop.maxQuantity)
        if quantity > 0 then
            -- Add to inventory
            addToInventory(drop.item, quantity)
            
            -- Show floating text
            showHarvestText(drop.item, quantity)
        end
    end
    
    -- Attempt profession level-up after successful harvest
    if profession and profile and profile.AttemptProfessionLevelUp then
        profile:AttemptProfessionLevelUp(profession)
    end
end

-- Auto-initialize when the module loads
C_Timer.After(5, function() -- Increased delay to allow for dataset loading
    HarvestNode:Initialize()
end)

-- Also listen for ItemRegistry refresh events
local function onItemRegistryRefresh()
    -- Registry refreshed
end

-- Try to register listener for ItemRegistry refresh
C_Timer.After(2, function()
    local registry = RPE.Core and RPE.Core.ItemRegistry
    if registry and registry._onRefresh then
        if not registry._onRefresh then registry._onRefresh = {} end
        table.insert(registry._onRefresh, onItemRegistryRefresh)
    end
end)

-- Test function - call this manually to debug
function HarvestNode:TestNodeDrops(nodeName)
    nodeName = nodeName or "Copper Vein"
    
    local itemRegistry = getItemRegistry()
    if not itemRegistry then return end
    
    local drops = getNodeDrops(nodeName)
    if #drops > 0 then
        self:ProcessNodeHarvest(nodeName)
    end
end

return HarvestNode