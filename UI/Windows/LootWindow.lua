-- UI/Windows/LootWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window      = RPE_UI.Elements.Window
local VGroup      = RPE_UI.Elements.VerticalLayoutGroup
local HBorder     = RPE_UI.Elements.HorizontalBorder
local Text        = RPE_UI.Elements.Text
local TextButton  = RPE_UI.Elements.TextButton
local ProgressBar = RPE_UI.Prefabs.ProgressBar
local LootEntry   = RPE_UI.Prefabs.LootEntry

-- Local helper to expose window globally
local function ExposeWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.LootWindow = self
end

---@class LootWindow
---@field root Window
---@field sheet VGroup
---@field LootEntries table
---@field distributionType string
local LootWindow = {}
_G.RPE_UI.Windows.LootWindow = LootWindow
LootWindow.__index = LootWindow
LootWindow.Name = "LootWindow"

function LootWindow:BuildUI()
    -- Build title with icon
    local title = "Loot"
    if RPE and RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.RPE then
        title = RPE.Common.InlineIcons.RPE .. " Loot"
    end
    
    -- Create root window
    self.root = Window:New("RPE_LootWindow", {
        width  = 180,
        height = 50,
        point  = "CENTER",
        autoSize = true,
        title = title,
    })

    -- Top border (stretched full width)
    self.topBorder = HBorder:New("RPE_LootWindow_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    _G.RPE_UI.Colors.ApplyHighlight(self.topBorder)

    -- Bottom border (stretched full width)
    self.bottomBorder = HBorder:New("RPE_LootWindow_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    _G.RPE_UI.Colors.ApplyHighlight(self.bottomBorder)

    -- Expose globally
    ExposeWindow(self)

    -- Initialize entries list
    self.LootEntries = {}
    self.distributionType = "BID"

    -- Create main sheet (VGroup) with the window as parent
    self.sheet = VGroup:New("RPE_LootWindow_Sheet", {
        parent   = self.root,
        width    = 1,
        height   = 1,
        point    = "TOP",
        relativePoint = "TOP",
        x        = 0,
        y        = 0,
        padding  = { left = 4, right = 4, top = 4, bottom = 12 },
        spacingY = 4,
        alignV   = "TOP",
        alignH   = "CENTER",
        autoSize = true,
    })

    -- Title text
    local titleText = title
    self.titleText = Text:New("RPE_LootWindow_Title", {
        parent = self.sheet,
        text = titleText,
        fontTemplate = "GameFontNormal",
    })
    self.sheet:Add(self.titleText)

    -- List of loot entries (will be populated when showing loot)
    self.list = VGroup:New("RPE_LootWindow_List", {
        parent   = self.sheet,
        width    = 1,
        height   = 1,
        spacingY = 4,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.list)
    
    -- Bid points display (only shown in BID mode)
    self.bidPointsText = Text:New("RPE_LootWindow_BidPoints", {
        parent = self.sheet,
        text = "Bid Points Remaining: 0",
        fontTemplate = "GameFontNormal",
    })
    self.bidPointsText.frame:Hide()
    self.sheet:Add(self.bidPointsText)
    
    -- Confirm button
    self.confirmButton = TextButton:New("RPE_LootWindow_Confirm", {
        parent = self.sheet,
        width = 100,
        height = 30,
        text = "Confirm",
        onClick = function()
            self:OnConfirm()
        end,
    })
    self.sheet:Add(self.confirmButton)
    
    -- Progress bar for distribution timeout
    self.timeoutProgressBar = ProgressBar:New("RPE_LootWindow_TimeoutProgress", {
        parent = self.sheet,
        width = 180,
        height = 8,
        showLabel = true,
        text = "",
        style = "progress_default",
    })
    self.sheet:Add(self.timeoutProgressBar)
    
    -- Initialize bid tracking
    self.totalBidPoints = 0
    self.usedBidPoints = 0
    self.timeoutDuration = 0
    self.timeoutStartTime = 0
end

function LootWindow:AddLootEntry(lootData)
    if not LootEntry then return end
    
    local index = #self.LootEntries + 1
    
    -- Ensure lootData has the lootId stored
    if not lootData.lootId and lootData.id then
        lootData.lootId = lootData.id
    end
    
    local entry = LootEntry:New("RPE_LootEntry_" .. index, {
        parent = self.list,
        width  = 180,
        height = 40,
        distributionType = self.distributionType,
        lootData = lootData,
    })
    
    -- Hook bid increment/decrement to update bid points
    if self.distributionType == "BID" then
        local originalIncrement = entry.IncrementBid
        local originalDecrement = entry.DecrementBid
        
        entry.IncrementBid = function(self)
            local lootWindow = LootWindow:GetInstance()
            local remaining = lootWindow.totalBidPoints - lootWindow.usedBidPoints
            if remaining <= 0 then
                -- No bid points remaining
                return
            end
            
            local oldBid = self.currentBid
            originalIncrement(self)
            local newBid = self.currentBid
            if newBid > oldBid then
                lootWindow:UpdateBidPoints(1)
            end
        end
        
        entry.DecrementBid = function(self)
            local oldBid = self.currentBid
            originalDecrement(self)
            local newBid = self.currentBid
            if newBid < oldBid then
                LootWindow:GetInstance():UpdateBidPoints(-1)
            end
        end
    end
    
    table.insert(self.LootEntries, entry)
    self.list:Add(entry)
end

function LootWindow:ClearEntries()
    for _, entry in ipairs(self.LootEntries) do
        if entry.frame then
            entry.frame:Hide()
            entry.frame:SetParent(nil)
        end
    end
    self.LootEntries = {}
end

function LootWindow:SetDistributionType(distrType)
    self.distributionType = distrType or "BID"
end

function LootWindow:ReceiveDistribution(lootEntries, distrType, timeout)
    -- Clear existing entries
    self:ClearEntries()
    
    -- Set distribution type
    self:SetDistributionType(distrType)
    
    RPE.Debug:Internal("[LootWindow] ReceiveDistribution called with " .. #lootEntries .. " items, type: " .. tostring(distrType))
    
    -- Get local player key for checking restrictions
    local playerName = UnitName("player")
    local realm = GetRealmName():gsub("%s+", "")
    local localPlayerKey = (playerName .. "-" .. realm):lower()
    
    -- Get player's current profile for profession checks
    local playerProfile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
    RPE.Debug:Internal("[LootWindow] Got playerProfile: " .. tostring(not not playerProfile))
    
    -- Get RecipeRegistry for recipe lookups
    local RecipeRegistry = RPE.Core and RPE.Core.RecipeRegistry
    
    -- Add loot entries that the player can receive (excluding allReceive items since they're auto-resolved)
    local eligibleCount = 0
    for _, lootData in ipairs(lootEntries) do
        -- Skip allReceive items - they don't need bidding, already applied automatically
        if not lootData.allReceive then
            local canReceive = false
            
            if not next(lootData.restrictedPlayers) then
                -- No restrictions, everyone can receive
                canReceive = true
            elseif lootData.restrictedPlayers[localPlayerKey] then
                -- Player is in restricted list
                canReceive = true
            end
            
            -- Check if player can learn recipes
            if lootData.currentCategory == "recipe" or lootData.currentCategory == "recipes" then
                local recipeId = lootData.currentLootData.id or lootData.currentLootData.lootId
                local recipeName = lootData.currentLootData and lootData.currentLootData.name or "Unknown"
                RPE.Debug:Internal("[LootWindow] Checking recipe: " .. recipeName .. " (ID: " .. tostring(recipeId) .. ")")
                
                if recipeId and RecipeRegistry and playerProfile then
                    -- Look up recipe definition to get profession
                    local recipeDef = RecipeRegistry:Get(tostring(recipeId))
                    if recipeDef then
                        RPE.Debug:Internal("[LootWindow] Recipe found in registry")
                        if recipeDef.profession then
                            RPE.Debug:Internal("[LootWindow] Recipe requires profession: " .. tostring(recipeDef.profession))
                            -- Mark recipe as unlearnable if player doesn't have the profession
                            if not playerProfile:HasProfession(recipeDef.profession) then
                                RPE.Debug:Internal("[LootWindow] Player does NOT have " .. recipeDef.profession .. " - disabling buttons")
                                lootData.cannotLearn = true
                            else
                                RPE.Debug:Internal("[LootWindow] Player HAS " .. recipeDef.profession .. " - allowing learning")
                                lootData.cannotLearn = false
                            end
                        else
                            RPE.Debug:Internal("[LootWindow] Recipe has no profession defined")
                        end
                    else
                        RPE.Debug:Internal("[LootWindow] Recipe NOT found in registry")
                    end
                else
                    RPE.Debug:Internal("[LootWindow] Cannot verify profession - RecipeRegistry: " .. tostring(not not RecipeRegistry) .. ", ProfileDB: " .. tostring(not not playerProfile))
                end
            end
            
            if canReceive then
                RPE.Debug:Internal("[LootWindow] Adding loot entry: " .. tostring(lootData.currentLootData and lootData.currentLootData.name or "Unknown"))
                self:AddLootEntry(lootData)
                eligibleCount = eligibleCount + 1
            end
        end
    end
    
    -- If no items to roll on, don't show the window
    if eligibleCount == 0 then
        self:Hide()
        return
    end
    
    -- Initialize bid points (1 per item)
    self.totalBidPoints = eligibleCount
    self.usedBidPoints = 0
    self:UpdateBidPointsDisplay()
    
    -- Show/hide bid points based on distribution type
    if distrType == "BID" then
        self.bidPointsText.frame:Show()
    else
        self.bidPointsText.frame:Hide()
    end
    
    -- Start timeout timer
    self.timeoutDuration = timeout
    self.timeoutStartTime = GetTime()
    self:StartTimeoutProgress()
    
    -- Show the window
    self:Show()
end

function LootWindow:PositionRelativeToEditor()
    if not self.root or not self.root.frame then return end
    
    -- Check if LootEditorWindow is open
    local editorWindow = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.LootEditorWindow
    if editorWindow and editorWindow.root and editorWindow.root.frame and editorWindow.root.frame:IsVisible() then
        -- Anchor to the right of the editor window
        self.root.frame:ClearAllPoints()
        self.root.frame:SetPoint("LEFT", editorWindow.root.frame, "RIGHT", 10, 0)
    else
        -- Use saved position or default to center
        if not self._hasCustomPosition then
            self.root.frame:ClearAllPoints()
            self.root.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        -- Otherwise, frame keeps its last position
    end
end

function LootWindow:Show()
    if not self.root then
        self:BuildUI()
    end
    
    self:PositionRelativeToEditor()
    
    if self.root.frame then
        self.root.frame:Show()
        self.root.frame:Raise()
    end
    
    -- Track if user manually moves the window
    if not self._trackingMovement then
        self._trackingMovement = true
        local originalOnDragStop = self.root.frame:GetScript("OnDragStop")
        self.root.frame:SetScript("OnDragStop", function(frame)
            self._hasCustomPosition = true
            if originalOnDragStop then
                originalOnDragStop(frame)
            end
        end)
    end
end

function LootWindow:Hide()
    if self.root then
        self.root.frame:Hide()
    end
end

function LootWindow:UpdateBidPointsDisplay()
    if self.bidPointsText then
        local remaining = self.totalBidPoints - self.usedBidPoints
        self.bidPointsText:SetText(string.format("Bid Points Remaining: %d", remaining))
    end
end

function LootWindow:OnConfirm()
    -- Build choices array
    local choices = {}
    for i, entry in ipairs(self.LootEntries) do
        -- Handle both field naming conventions
        local lootId = entry.lootData and (entry.lootData.lootId or entry.lootData.id)
        if not lootId and entry.lootData and entry.lootData.currentLootData then
            lootId = entry.lootData.currentLootData.id
        end
        
        if lootId then
            if self.distributionType == "BID" then
                choices[#choices + 1] = {
                    lootId = lootId,
                    bid = entry.currentBid or 0,
                }
            else
                choices[#choices + 1] = {
                    lootId = lootId,
                    choice = entry.choice or "pass",
                }
            end
        end
    end
    
    -- Send choices to supergroup leader
    local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.SendLootChoice then
        Broadcast:SendLootChoice(choices, self.distributionType)
    end
    
    -- Stop timeout ticker
    if self.timeoutTicker then
        self.timeoutTicker:Cancel()
        self.timeoutTicker = nil
    end
    
    self:Hide()
end

function LootWindow:StartTimeoutProgress()
    if self.timeoutTicker then
        self.timeoutTicker:Cancel()
    end
    
    self.timeoutTicker = C_Timer.NewTicker(0.1, function()
        local elapsed = GetTime() - self.timeoutStartTime
        local remaining = math.max(0, self.timeoutDuration - elapsed)
        
        if self.timeoutProgressBar then
            self.timeoutProgressBar:SetValue(remaining, self.timeoutDuration)
            self.timeoutProgressBar:SetText(string.format("%.1fs remaining", remaining))
        end
        
        if remaining <= 0 then
            if self.timeoutTicker then
                self.timeoutTicker:Cancel()
                self.timeoutTicker = nil
            end
            -- Clear entries and close window when time runs out
            self:ClearEntries()
            self:Hide()
        end
    end)
end

function LootWindow:UpdateBidPoints(delta)
    self.usedBidPoints = self.usedBidPoints + delta
    self:UpdateBidPointsDisplay()
end

function LootWindow:Toggle()
    if self.root and self.root.frame then
        if self.root.frame:IsVisible() then
            self:Hide()
        else
            self:Show()
        end
    end
end

function LootWindow.New()
    local self = setmetatable({}, LootWindow)
    self:BuildUI()
    return self
end

-- Global instance
function LootWindow:GetInstance()
    if not _G.RPE_UI_LootWindow_Instance then
        _G.RPE_UI_LootWindow_Instance = LootWindow.New()
    end
    return _G.RPE_UI_LootWindow_Instance
end

return LootWindow
