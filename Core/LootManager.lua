-- Core/LootManager.lua
-- Handles loot distribution logic (tracking responses, resolving winners)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local LootManager = {}
RPE.Core.LootManager = LootManager

-- Active distribution state
LootManager.lootResponses = nil
LootManager.eligiblePlayersByLoot = nil
LootManager.lootResponsesComplete = false
LootManager.lootDistributionStartTime = nil
LootManager.lootDistributionTimeout = 60
LootManager.distributionType = nil
LootManager.lootEntries = nil

function LootManager:StartDistribution(lootEntries, distrType, timeout)
    -- Initialize tracking
    self.lootResponses = {}
    self.lootResponsesComplete = false
    self.lootDistributionStartTime = GetTime()
    self.lootDistributionTimeout = timeout or 60
    self.distributionType = distrType
    self.lootEntries = lootEntries
    
    -- Separate and handle allReceive items (auto-resolve)
    local itemsToDistribute = {}
    local autoResolvedIds = {}  -- Track auto-resolved items for completion callback
    for _, entry in ipairs(lootEntries) do
        if entry.allReceive then
            -- Auto-resolve: send to all eligible players
            local lootName = (entry.currentLootData and entry.currentLootData.name) or "Unknown"
            
            local lootId = entry.currentLootData and entry.currentLootData.id or entry.id or "unknown"
            local category = entry.currentCategory or "items"
            local quantity = entry.currentQuantity or 1
            local extraData = nil
            
            -- Build extra data based on category
            if category == "spell" or category == "spells" then
                extraData = tostring(quantity)
            elseif category == "recipe" or category == "recipes" then
                local RecipeRegistry = RPE.Core and RPE.Core.RecipeRegistry
                if RecipeRegistry then
                    local recipe = RecipeRegistry:Get(tostring(lootId))
                    if recipe and recipe.profession then
                        extraData = tostring(recipe.profession)
                    end
                end
            end
            
            -- Send broadcast with winnerKey="all"
            RPE.Core.Comms.Broadcast:SendLoot("all", lootId, lootName, category, quantity, extraData, "1")
            table.insert(autoResolvedIds, lootId)
        else
            table.insert(itemsToDistribute, entry)
        end
    end
    
    -- Store auto-resolved IDs for completion callback
    self.autoResolvedLootIds = autoResolvedIds
    
    -- If no items left to distribute, notify completion and return
    if #itemsToDistribute == 0 then
        -- Still need to call OnDistributionComplete so editor entries are removed
        if LootEditorWindow and LootEditorWindow.OnDistributionComplete then
            LootEditorWindow:OnDistributionComplete(autoResolvedIds)
        end
        return
    end
    
    -- Update lootEntries to only include items that need distribution
    self.lootEntries = itemsToDistribute
    
    -- Build eligible players list for each loot entry
    self.eligiblePlayersByLoot = {}
    for i, entry in ipairs(itemsToDistribute) do
        local lootId = entry.currentLootData and (entry.currentLootData.id or (entry.currentCategory == "currency" and entry.currentLootData.name and entry.currentLootData.name:lower()) or entry.currentCategory)
        if lootId then
            local eligiblePlayers = {}
            
            -- Get players from active event
            local event = RPE.Core.ActiveEvent
            if event and event.units then
                for key, unit in pairs(event.units) do
                    if not unit.isNPC then
                        local playerKey = unit.key or key
                        
                        -- Check restrictions
                        if entry.allReceive then
                            eligiblePlayers[playerKey] = true
                        elseif not next(entry.restrictedPlayers) then
                            eligiblePlayers[playerKey] = true
                        elseif entry.restrictedPlayers[playerKey] then
                            eligiblePlayers[playerKey] = true
                        end
                    end
                end
            end
            
            -- Fallback: if no event or no players found, use party/raid members
            if not next(eligiblePlayers) then
                -- Always include self
                local localKey = RPE.Comms.LocalPlayerKey()
                if entry.allReceive or not next(entry.restrictedPlayers) or entry.restrictedPlayers[localKey] then
                    eligiblePlayers[localKey] = true
                end
                
                -- Add party/raid members
                local numGroupMembers = GetNumGroupMembers()
                if numGroupMembers > 0 then
                    for i = 1, numGroupMembers do
                        local unit = IsInRaid() and "raid" .. i or "party" .. i
                        if UnitExists(unit) then
                            local name, realm = UnitName(unit)
                            if name then
                                realm = realm and realm ~= "" and realm or GetRealmName()
                                realm = realm:gsub("%s+", "")
                                local playerKey = (name .. "-" .. realm):lower()
                                
                                -- Check restrictions
                                if entry.allReceive then
                                    eligiblePlayers[playerKey] = true
                                elseif not next(entry.restrictedPlayers) then
                                    eligiblePlayers[playerKey] = true
                                elseif entry.restrictedPlayers[playerKey] then
                                    eligiblePlayers[playerKey] = true
                                end
                            end
                        end
                    end
                end
            end
            
            self.eligiblePlayersByLoot[lootId] = eligiblePlayers
        end
    end
    
    RPE.Debug:Internal("[LootManager] Started distribution: " .. #itemsToDistribute .. " items, " .. timeout .. "s timeout")
end

function LootManager:RecordLootChoice(playerKey, choices, distrType)
    -- Don't initialize here - StartDistribution should have already set everything up
    -- This function should only be called after StartDistribution has been called
    if not RPE.Core.IsLeader() then return end


    if not self.lootResponses then
        return
    end
    
    -- Normalize playerKey to lowercase for consistent comparison with eligible players
    playerKey = playerKey:lower()
    
    self.lootResponses[playerKey] = {
        choices = choices,
        distrType = distrType,
    }
    
    -- Check if all eligible players have responded
    local allResponded = true
    for lootId, eligiblePlayers in pairs(self.eligiblePlayersByLoot) do
        for playerKey, _ in pairs(eligiblePlayers) do
            if not self.lootResponses[playerKey] then
                allResponded = false
                break
            end
        end
        if not allResponded then break end
    end
    
    -- If all responded OR timeout occurred, resolve
    if allResponded or (GetTime() - self.lootDistributionStartTime) >= self.lootDistributionTimeout then
        self:ResolveLootDistribution()
    end
end

function LootManager:ResolveLootDistribution()
    if self.lootResponsesComplete then return end
    self.lootResponsesComplete = true
    
    -- Get loot entries from LootEditorWindow
    local LootEditorWindow = RPE.Core.Windows and RPE.Core.Windows.LootEditorWindow
    local lootEntries = self.lootEntries or (LootEditorWindow and LootEditorWindow.LootEntries) or {}
    
    -- Track which items were distributed (had winners)
    local distributedLootIds = {}
    
    -- Resolve each loot entry
    for i, entry in ipairs(lootEntries) do
        local lootId = entry.currentLootData and (entry.currentLootData.id or (entry.currentCategory == "currency" and entry.currentLootData.name and entry.currentLootData.name:lower()) or entry.currentCategory)
        local lootName = (entry.currentLootData and entry.currentLootData.name) or "Unknown"
        
        if lootId then
            -- Collect all choices for this loot
            local needRolls = {}
            local greedRolls = {}
            local bids = {}
        
            for playerKey, response in pairs(self.lootResponses) do
                for _, choice in ipairs(response.choices) do
                    if tostring(choice.lootId) == tostring(lootId) then
                        if self.distributionType == "BID" then
                            if choice.bid and choice.bid > 0 then
                                table.insert(bids, { playerKey = playerKey, bid = choice.bid })
                            end
                        else
                            if choice.choice == "need" then
                                table.insert(needRolls, { playerKey = playerKey, roll = math.random(1, 100) })
                            elseif choice.choice == "greed" then
                                table.insert(greedRolls, { playerKey = playerKey, roll = math.random(1, 100) })
                            end
                        end
                        break
                    end
                end
            end
            
            -- Determine winner
            local winner = nil
            local winnerRoll = nil
            local winnerBid = nil
            
            if self.distributionType == "BID" then
                -- Sort bids by amount (highest first), with random tiebreaker for equal bids
                table.sort(bids, function(a, b) 
                    if a.bid ~= b.bid then
                        return a.bid > b.bid
                    else
                        -- For tied bids, use a pseudo-random tiebreaker based on player keys
                        return math.random() > 0.5
                    end
                end)
                if #bids > 0 then
                    winner = bids[1].playerKey
                    winnerBid = bids[1].bid
                end
            else
                -- Need before greed: try need rolls first
                local rolls = (#needRolls > 0) and needRolls or greedRolls
                table.sort(rolls, function(a, b) return a.roll > b.roll end)
                if #rolls > 0 then
                    winner = rolls[1].playerKey
                    winnerRoll = rolls[1].roll
                end
            end
            
            -- Print result and send loot broadcast
            if winner then
                -- Mark this item as distributed
                table.insert(distributedLootIds, lootId)
                
                -- Send loot to winner via broadcast
                self:BroadcastLoot(winner, lootId, lootName, entry)
            else
                -- Nobody wants it - check loot_spare_items setting
                local RulesetDB = RPE.Profile and RPE.Profile.RulesetDB
                local spareAction = "nothing"
                if RulesetDB then
                    local rs = RulesetDB.LoadActiveForCurrentCharacter()
                    if rs and rs.rules then
                        spareAction = rs.rules.loot_spare_items or "nothing"
                    end
                end
            end
        end
    end
    
    -- Notify UI that distribution is complete, passing all distributed items (bidding + auto-resolved)
    if LootEditorWindow and LootEditorWindow.OnDistributionComplete then
        -- Combine bidding-distributed items with auto-resolved items
        local allDistributedIds = distributedLootIds
        if self.autoResolvedLootIds and next(self.autoResolvedLootIds) then
            for _, autoResolvedId in ipairs(self.autoResolvedLootIds) do
                table.insert(allDistributedIds, autoResolvedId)
            end
        end
        LootEditorWindow:OnDistributionComplete(allDistributedIds)
    end
    
    -- Clear tracking
    self.lootResponses = nil
    self.eligiblePlayersByLoot = nil
    self.lootEntries = nil
end

function LootManager:BroadcastLoot(winnerKey, lootId, lootName, entry)
    -- Build extra data based on category
    local category = entry.currentCategory or "items"
    local quantity = entry.currentQuantity or 1
    local extraData = nil
    
    if category == "spell" or category == "spells" then
        -- For spells, use quantity as the rank
        extraData = tostring(quantity)
    elseif category == "recipe" or category == "recipes" then
        -- For recipes, look up the profession from the recipe registry
        local RecipeRegistry = RPE.Core and RPE.Core.RecipeRegistry
        if RecipeRegistry then
            local recipe = RecipeRegistry:Get(tostring(lootId))
            if recipe and recipe.profession then
                extraData = tostring(recipe.profession)
            end
        end
    end
    
    RPE.Debug:Internal("[LootManager] Broadcasting SEND_LOOT: winner=" .. winnerKey .. ", loot=" .. tostring(lootId) .. ", category=" .. category .. ", qty=" .. quantity .. ", extraData=" .. tostring(extraData))
    
    -- Send via Broadcast method
    local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.SendLoot then
        -- Pass allReceive flag as 7th parameter
        local allReceive = entry.allReceive and "1" or "0"
        Broadcast:SendLoot(winnerKey, lootId, lootName, category, quantity, extraData, allReceive)
    end
end

function LootManager:Clear()
    self.lootResponses = nil
    self.eligiblePlayersByLoot = nil
    self.lootResponsesComplete = false
    self.lootDistributionStartTime = nil
    self.lootDistributionTimeout = 60
    self.distributionType = nil
    self.lootEntries = nil
end

return LootManager
