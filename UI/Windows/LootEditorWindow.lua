-- UI/Windows/LootEditorWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window   = RPE_UI.Elements.Window
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local HBorder  = RPE_UI.Elements.HorizontalBorder
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local Dropdown = RPE_UI.Elements.Dropdown
local Input    = RPE_UI.Elements.Input
local LootEditorEntry = RPE_UI.Prefabs.LootEditorEntry

-- Local helper to expose window globally
local function ExposeWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.LootEditorWindow = self
end

---@class LootEditorWindow
---@field root Window
---@field sheet VGroup
---@field list VGroup
---@field addBtn TextBtn
---@field LootEntries table
---@field settingsGroup VGroup
---@field distrTypeDropdown Dropdown
---@field distrType string
---@field _page number
---@field pageText Text
local LootEditorWindow = {}
_G.RPE_UI.Windows.LootEditorWindow = LootEditorWindow
LootEditorWindow.__index = LootEditorWindow
LootEditorWindow.Name = "LootEditorWindow"

function LootEditorWindow:BuildUI()
    -- Create root window
    self.root = Window:New("RPE_LootEditorWindow", {
        width  = 500,
        height = 450,
        point  = "CENTER",
        autoSize = false,
    })

    -- Top border (stretched full width)
    self.topBorder = HBorder:New("RPE_LootEditor_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 3)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 3)
    _G.RPE_UI.Colors.ApplyHighlight(self.topBorder)

    -- Bottom border (stretched full width)
    self.bottomBorder = HBorder:New("RPE_LootEditor_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 3,
        y             = 0,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, -3)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, -3)
    _G.RPE_UI.Colors.ApplyHighlight(self.bottomBorder)

    -- Expose globally
    ExposeWindow(self)

    -- Initialize entries list
    self.LootEntries = {}
    self._page = 1

    -- Create main sheet (VGroup) with the window as parent
    self.sheet = VGroup:New("RPE_LootEditor_Sheet", {
        parent   = self.root,
        width    = 1,
        height   = 1,
        point    = "TOP",
        relativePoint = "TOP",
        x        = 0,
        y        = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 10,
        alignV   = "TOP",
        alignH   = "CENTER",
        autoSize = true,
    })

    -- Title
    local title = Text:New("RPE_LootEditor_Title", {
        parent = self.sheet,
        text   = "Loot Distribution",
    })
    self.sheet:Add(title)

    -- Navigation bar with Add Item button
    local navWrap = HGroup:New("RPE_LootEditor_NavWrap", {
        parent   = self.sheet,
        width    = 1,
        height   = 1,
        spacingX = 8,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })

    self.addBtn = TextBtn:New("RPE_LootEditor_AddBtn", {
        parent  = navWrap,
        width   = 100,
        height  = 22,
        text    = "Add Loot",
        noBorder = true,
        onClick = function()
            self:AddLootEntry()
        end,
    })
    navWrap:Add(self.addBtn)

    -- Distribute button
    self.distributeBtn = TextBtn:New("RPE_LootEditor_DistributeBtn", {
        parent  = navWrap,
        width   = 100,
        height  = 22,
        text    = "Distribute",
        noBorder = true,
        onClick = function()
            self:StartDistribution()
        end,
    })
    navWrap:Add(self.distributeBtn)

    -- Close button
    self.closeBtn = TextBtn:New("RPE_LootEditor_CloseBtn", {
        parent  = navWrap,
        width   = 80,
        height  = 22,
        text    = "Close",
        noBorder = true,
        onClick = function()
            self:Hide()
        end,
    })
    navWrap:Add(self.closeBtn)

    -- Spacer
    local spacer = Text:New("RPE_LootEditor_Spacer", {
        parent  = navWrap,
        text    = "",
        width   = 1,
        height  = 1,
    })
    spacer.flex = 1
    navWrap:Add(spacer)

    self.sheet:Add(navWrap)

    -- Settings section (distribution type)
    self.settingsGroup = VGroup:New("RPE_LootEditor_Settings", {
        parent   = self.sheet,
        width    = 1,
        height   = 1,
        spacingY = 6,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.settingsGroup)

    -- Distribution type row
    local distrTypeRow = HGroup:New("RPE_LootEditor_DistrTypeRow", {
        parent   = self.settingsGroup,
        width    = 1,
        height   = 1,
        spacingX = 10,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.settingsGroup:Add(distrTypeRow)

    -- Distribution type label
    local distrTypeLabel = Text:New("RPE_LootEditor_DistrTypeLabel", {
        parent = distrTypeRow,
        text   = "Distribution Type:",
    })
    distrTypeRow:Add(distrTypeLabel)

    -- Distribution type dropdown
    self.distrType = "NEED BEFORE GREED"
    self.distrTypeDropdown = Dropdown:New("RPE_LootEditor_DistrTypeDropdown", {
        parent  = distrTypeRow,
        width   = 180,
        height  = 22,
        value   = self.distrType,
        choices = { "NEED BEFORE GREED", "BID" },
        onChanged = function(dd, value)
            self.distrType = value
        end,
    })
    distrTypeRow:Add(self.distrTypeDropdown)

    -- Timeout input row
    local timeoutRow = HGroup:New("RPE_LootEditor_TimeoutRow", {
        parent   = self.settingsGroup,
        width    = 1,
        height   = 1,
        spacingX = 10,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.settingsGroup:Add(timeoutRow)

    -- Timeout label
    local timeoutLabel = Text:New("RPE_LootEditor_TimeoutLabel", {
        parent = timeoutRow,
        text   = "Distribution Timeout (s):",
    })
    timeoutRow:Add(timeoutLabel)

    -- Timeout input
    self.distrTimeout = 60
    self.timeoutInput = Input:New("RPE_LootEditor_TimeoutInput", {
        parent  = timeoutRow,
        width   = 80,
        height  = 22,
        text    = "60",
        onChange = function(inputEl, text)
            local timeout = tonumber(text)
            if timeout and timeout > 0 then
                self.distrTimeout = timeout
            else
                self.distrTimeout = 60
            end
        end,
    })
    timeoutRow:Add(self.timeoutInput)

    -- List of loot entries
    self.list = VGroup:New("RPE_LootEditor_List", {
        parent   = self.sheet,
        width    = 1,
        height   = 1,
        spacingY = 4,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.list)

    -- Pagination controls (fixed at bottom of window)
    local pager = HGroup:New("RPE_LootEditor_Pager", {
        parent   = self.root,
        width    = 1,
        height   = 30,
        spacingX = 10,
        alignV   = "CENTER",
        alignH   = "CENTER",
        autoSize = false,
    })
    pager.frame:ClearAllPoints()
    pager.frame:SetPoint("BOTTOM", self.root.frame, "BOTTOM", 0, 10)
    pager.frame:SetSize(480, 30)

    local prevBtn = TextBtn:New("RPE_LootEditor_Prev", {
        parent = pager,
        width = 70,
        height = 22,
        text = "Prev",
        noBorder = true,
        onClick = function()
            self:SetPage(self._page - 1)
        end,
    })
    pager:Add(prevBtn)

    self.pageText = Text:New("RPE_LootEditor_PageText", {
        parent = pager,
        text = "Page 1 / 1",
        fontTemplate = "GameFontNormalSmall",
    })
    pager:Add(self.pageText)

    local nextBtn = TextBtn:New("RPE_LootEditor_Next", {
        parent = pager,
        width = 70,
        height = 22,
        text = "Next",
        noBorder = true,
        onClick = function()
            self:SetPage(self._page + 1)
        end,
    })
    pager:Add(nextBtn)

    self:UpdatePagination()
end

function LootEditorWindow:SetPage(page)
    local totalPages = math.max(1, math.ceil(#self.LootEntries / 8))
    self._page = math.max(1, math.min(page, totalPages))
    self:UpdatePagination()
end

function LootEditorWindow:UpdatePagination()
    local total = #self.LootEntries
    local perPage = 8
    local totalPages = math.max(1, math.ceil(total / perPage))
    self._page = math.max(1, math.min(self._page, totalPages))
    
    if self.pageText then
        self.pageText:SetText(("Page %d / %d"):format(self._page, totalPages))
    end
    
    -- Show/hide entries based on current page
    local startIdx = (self._page - 1) * perPage + 1
    local endIdx = math.min(startIdx + perPage - 1, total)
    
    for i, entry in ipairs(self.LootEntries) do
        if i >= startIdx and i <= endIdx then
            if entry.frame then entry.frame:Show() end
        else
            if entry.frame then entry.frame:Hide() end
        end
    end
end

function LootEditorWindow:AddLootEntry()
    if not LootEditorEntry then return end
    
    local index = #self.LootEntries + 1
    
    local entry = LootEditorEntry:New("RPE_LootEditorEntry_" .. index, {
        parent = self.list,
        width  = 500,
        height = 32,
    })
    
    entry.entryIndex = index
    
    -- Set up callbacks
    entry:SetOnMinusClick(function(e)
        if e.currentQuantity and e.currentQuantity > 1 then
            e:SetQuantity(e.currentQuantity - 1)
        end
    end)
    
    entry:SetOnPlusClick(function(e)
        e:SetQuantity((e.currentQuantity or 1) + 1)
    end)
    
    entry:SetOnDistributeClick(function(e)
        self:DistributeSingleItem(e)
    end)
    
    entry:SetOnCancelClick(function(e)
        if e.frame then e.frame:Hide() end
        for i, existingEntry in ipairs(self.LootEntries) do
            if existingEntry == e then
                table.remove(self.LootEntries, i)
                break
            end
        end
        self:UpdatePagination()
    end)
    
    table.insert(self.LootEntries, entry)
    self.list:Add(entry)
    
    -- Navigate to last page
    local totalPages = math.ceil(#self.LootEntries / 8)
    self:SetPage(totalPages)
end

function LootEditorWindow:Show()
    if not self.root then
        self:BuildUI()
    end
    if self.root.frame then
        self.root.frame:Show()
        self.root.frame:Raise()
    end
end

function LootEditorWindow:Hide()
    if self.root then
        self.root.frame:Hide()
    end
end

function LootEditorWindow:Toggle()
    if self.root and self.root.frame then
        if self.root.frame:IsVisible() then
            self:Hide()
        else
            self:Show()
        end
    end
end

function LootEditorWindow:StartDistribution()
    -- Get timeout from input field
    local timeout = 60
    if self.timeoutInput then
        local text = self.timeoutInput:GetText()
        if text and text ~= "" then
            timeout = tonumber(text) or 60
        end
    end
    if timeout <= 0 then
        timeout = 60
    end
    
    -- If no items to distribute, just return
    if #self.LootEntries == 0 then
        return
    end
    
    -- Lock the Distribute button
    if self.distributeBtn then
        self.distributeBtn:SetEnabled(false)
    end
    
    -- Initialize LootManager with all entries (it handles allReceive items internally)
    local LootManager = RPE.Core and RPE.Core.LootManager
    if LootManager then
        LootManager:StartDistribution(self.LootEntries, self.distrType, timeout)
    end
    
    -- Broadcast loot distribution to all players
    local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.DistributeLoot then
        Broadcast:DistributeLoot(self.LootEntries, self.distrType, timeout)
    end
    
    -- Show all progress bars (only for non-allReceive items)
    for _, entry in ipairs(self.LootEntries) do
        if not entry.allReceive and entry.ShowProgressBar then
            entry:ShowProgressBar()
        end
    end
    
    -- Cancel any existing ticker
    if self._distributionTicker then
        self._distributionTicker:Cancel()
        self._distributionTicker = nil
    end
    
    -- Start distribution timer
    local startTime = GetTime()
    local updateInterval = 0.05  -- Update every 50ms for smooth animation
    
    self._distributionTicker = C_Timer.NewTicker(updateInterval, function()
        local elapsed = GetTime() - startTime
        local progress = 100 - ((elapsed / timeout) * 100)
        
        if progress <= 0 then
            -- Distribution complete
            progress = 0
            
            -- Update all progress bars to 0
            for _, entry in ipairs(self.LootEntries) do
                if not entry.allReceive and entry.SetProgress then
                    entry:SetProgress(0)
                end
            end
            
            -- Cancel ticker
            if self._distributionTicker then
                self._distributionTicker:Cancel()
                self._distributionTicker = nil
            end
            
            -- Hide progress bars after a brief delay
            C_Timer.After(0.5, function()
                for _, entry in ipairs(self.LootEntries) do
                    if not entry.allReceive and entry.HideProgressBar then
                        entry:HideProgressBar()
                    end
                end
            end)
        else
            -- Update all progress bars
            for _, entry in ipairs(self.LootEntries) do
                if not entry.allReceive and entry.SetProgress then
                    entry:SetProgress(progress)
                end
            end
        end
    end)
end

function LootEditorWindow:DistributeSingleItem(entry)
    -- Get timeout from input field
    local timeout = 60
    if self.timeoutInput then
        local text = self.timeoutInput:GetText()
        if text and text ~= "" then
            timeout = tonumber(text) or 60
        end
    end
    if timeout <= 0 then
        timeout = 60
    end
    
    -- Create single-item array
    local singleEntry = { entry }
    
    -- Initialize LootManager with single entry (it handles allReceive items internally)
    local LootManager = RPE.Core and RPE.Core.LootManager
    if LootManager then
        LootManager:StartDistribution(singleEntry, self.distrType, timeout)
    end
    
    -- Broadcast single loot distribution
    local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.DistributeLoot then
        Broadcast:DistributeLoot(singleEntry, self.distrType, timeout)
    end
    
    -- Show progress bar for this entry only if it's not allReceive
    if not entry.allReceive and entry.ShowProgressBar then
        entry:ShowProgressBar()
    end
    
    -- Initialize single item tickers table if needed
    if not self._singleItemTickers then
        self._singleItemTickers = {}
    end
    
    -- Start progress animation for this entry (only if not allReceive)
    if not entry.allReceive then
        local startTime = GetTime()
        local updateInterval = 0.05
        local ticker
        
        ticker = C_Timer.NewTicker(updateInterval, function()
            local elapsed = GetTime() - startTime
            local progress = 100 - ((elapsed / timeout) * 100)
            
            if progress <= 0 then
                progress = 0
                if entry.SetProgress then
                    entry:SetProgress(0)
                end
                if ticker then
                    ticker:Cancel()
                    self._singleItemTickers[entry] = nil
                end
                
                -- Hide progress bar after a brief delay
                C_Timer.After(0.5, function()
                    if entry.HideProgressBar then
                        entry:HideProgressBar()
                    end
                end)
            else
                if entry.SetProgress then
                    entry:SetProgress(progress)
                end
            end
        end)
        
        -- Store the ticker so it can be cancelled if needed
        self._singleItemTickers[entry] = ticker
    end
end

function LootEditorWindow:OnDistributionComplete(distributedLootIds)
    -- Stop progress bars
    if self._distributionTicker then
        self._distributionTicker:Cancel()
        self._distributionTicker = nil
    end
    
    -- Stop any single item tickers
    if self._singleItemTickers then
        for entry, ticker in pairs(self._singleItemTickers) do
            if ticker then
                ticker:Cancel()
            end
        end
        self._singleItemTickers = {}
    end
    
    distributedLootIds = distributedLootIds or {}
    
    -- Build a lookup table for distributed lootIds
    local distributedLookup = {}
    for _, lootId in ipairs(distributedLootIds) do
        distributedLookup[tostring(lootId)] = true
    end
    
    -- Set all progress bars to 0
    for _, entry in ipairs(self.LootEntries) do
        if entry.SetProgress then
            entry:SetProgress(0)
        end
    end
    
    -- Hide progress bars and remove only distributed entries
    C_Timer.After(0.5, function()
        local remainingEntries = {}
        
        for _, entry in ipairs(self.LootEntries) do
            local lootId = entry.currentLootData and (entry.currentLootData.id or (entry.currentCategory == "currency" and entry.currentLootData.name and entry.currentLootData.name:lower()) or entry.currentCategory)
            local lootName = entry.currentLootData and entry.currentLootData.name or "Unknown"
            
            if entry.HideProgressBar then
                entry:HideProgressBar()
            end
            
            -- Only remove entries that were actually distributed
            if lootId and distributedLookup[tostring(lootId)] then
                RPE.Debug:Internal(string.format("[LootEditorWindow] Removing distributed entry: %s (%s)", lootName, tostring(lootId)))
                if entry.frame then
                    entry.frame:Hide()
                    entry.frame:SetParent(nil)
                end
            else
                RPE.Debug:Internal(string.format("[LootEditorWindow] Keeping entry: %s (%s)", lootName, tostring(lootId)))
                -- Keep this entry
                table.insert(remainingEntries, entry)
            end
        end
        
        -- Update the entries array with remaining items
        self.LootEntries = remainingEntries
        
        -- Update pagination
        self:UpdatePagination()
    end)
    
    -- Unlock the Distribute button
    if self.distributeBtn then
        self.distributeBtn:SetEnabled(true)
    end
end



function LootEditorWindow.New()
    local self = setmetatable({}, LootEditorWindow)
    self:BuildUI()
    return self
end

-- Global instance
function LootEditorWindow:GetInstance()
    if not _G.RPE_UI_LootEditorWindow_Instance then
        _G.RPE_UI_LootEditorWindow_Instance = LootEditorWindow.New()
    end
    return _G.RPE_UI_LootEditorWindow_Instance
end

return LootEditorWindow
