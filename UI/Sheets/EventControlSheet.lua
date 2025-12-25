-- RPE_UI/Windows/EventControlSheet.lua
RPE             = RPE or {}
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.ActiveRules = RPE.ActiveRules
RPE.Core.ActiveEvent = RPE.Core.ActiveEvent

local Window       = RPE_UI.Elements.Window
local HGroup       = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup       = RPE_UI.Elements.VerticalLayoutGroup
local FrameElement = RPE_UI.Elements.FrameElement
local TextButton   = RPE_UI.Elements.TextButton
local Table        = RPE_UI.Elements.Table

-- Prefabs
local InventorySlot = RPE_UI.Prefabs.InventorySlot

---@class EventControlSheet
---@field Name string
---@field root Window
---@field sheet VGroup
---@field buttonRow HGroup
---@field slots InventorySlot[]
---@field startButton TextButton
---@field pushButton TextButton
---@field pushDatasetButton TextButton
---@field tickButton TextButton
local EventControlSheet = {}
_G.RPE_UI.Windows.EventControlSheet = EventControlSheet
EventControlSheet.__index = EventControlSheet
EventControlSheet.Name = "EventControlSheet"

-- Expose under RPE.Core.Windows too
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.EventControlSheet = self
end

-- Safely fetch the current EventSettingsSheet instance and values
local function _getSettings()
    local EW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.EventWindow
    local settingsSheet = EW and EW.pages and EW.pages["settings"] or nil
    local s = (settingsSheet and settingsSheet.settings) or {}

    -- Defaults
    local title   = (type(s.title) == "string" and s.title ~= "" and s.title) or "Untitled Event"
    local subtext = (type(s.subtext) == "string" and s.subtext) or ""
    local diff    = (type(s.difficulty) == "string" and s.difficulty) or "NORMAL"
    local turnOrderType = (type(s.turnOrderType) == "string" and s.turnOrderType) or "INITIATIVE"

    local teamNames = { "", "", "", "" }
    if type(s.teamNames) == "table" then
        for i = 1, 4 do
            local v = s.teamNames[i]
            teamNames[i] = (type(v) == "string" and v) or ""
        end
    end

    return {
        title         = title,
        subtext       = subtext,
        difficulty    = diff,
        turnOrderType = turnOrderType,
        teamNames     = teamNames,
    }
end

--- Build UI
---@param opts table
function EventControlSheet:BuildUI(opts)
    opts = opts or {}
    self.rows = opts.rows or 6
    self.cols = opts.cols or 8
    self.slots = {}
    self.statsPage = 1
    self.statsPageSize = 5
    self.statsVisible = false

    self.sheet = VGroup:New("RPE_ECS_Sheet", {
        parent = opts.parent,
        width  = 1,
        height = 1,
        point  = "TOP",
        relativePoint = "TOP",
        x = 0, y = 0,
        padding = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV = "TOP",
        alignH = "CENTER",
        autoSize = true,
    })

    self.buttonRow = HGroup:New("RPE_ECS_Button_Row", {
        parent = self.sheet,
        height = 1,
        width = 1,
        autoSize = true,
        spacingX = 12,
    })
    self.sheet:Add(self.buttonRow)

    self.buttonRow2 = HGroup:New("RPE_ECS_Button_Row2", {
        parent = self.sheet,
        height = 1,
        width = 1,
        autoSize = true,
        spacingX = 12,
    })
    self.sheet:Add(self.buttonRow2)

    self:DrawButtons()
    self:BuildStatsTable()

    if RPE_UI.Common then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

--- Create all control buttons
function EventControlSheet:DrawButtons()
    self.pushButton = TextButton:New("RPE_ECS_PushRuleset", {
        parent  = self.buttonRow,
        width   = 100,
        height  = 32,
        text    = "Sync Ruleset",
        noBorder = false,
        onClick = function()
            RPE.Core.Comms.Broadcast:SendActiveRulesetToSupergroup()
        end,
    })
    self.buttonRow:Add(self.pushButton)

    self.pushDatasetButton = TextButton:New("RPE_ECS_PushDataset", {
        parent  = self.buttonRow,
        width   = 100,
        height  = 32,
        text    = "Sync Dataset",
        noBorder = false,
        onClick = function()
            RPE.Core.Comms.Broadcast:SendActiveDatasetToSupergroup()
        end,
    })
    self.buttonRow:Add(self.pushDatasetButton)

    self.readyCheckButton = TextButton:New("RPE_ECS_ReadyCheck", {
        parent  = self.buttonRow,
        width   = 100,
        height  = 32,
        text    = "Ready Check",
        noBorder = false,
        onClick = function()
            RPE.Core.Comms.Request:CheckReady(
                function(answer, sender)
                    -- Just log the response without starting the event
                    RPE.Debug:Print(sender .. " is " .. (answer and "READY" or "NOT READY"))
                end,
                function(missing)
                    RPE.Debug:Print("Ready check timed out. Missing:")
                    for _, key in ipairs(missing) do RPE.Debug:Print(" - "..key) end
                end,
                10 -- seconds
            )
        end,
    })
    self.buttonRow:Add(self.readyCheckButton)

    self.startButton = TextButton:New("RPE_ECS_Start_End", {
        parent  = self.buttonRow2,
        width   = 100,
        height  = 32,
        noBorder = false,
    })
    self.buttonRow2:Add(self.startButton)

    self.tickButton = TextButton:New("RPE_ECS_Next_Tick", {
        parent  = self.buttonRow2,
        width   = 100,
        height  = 32,
        text    = "Next Tick",
        noBorder = false,
        onClick = function()
            if RPE.Core.ActiveEvent.turn > 0 then
                RPE.Core.ActiveEvent:Advance()
            end
        end,
    })
    self.buttonRow2:Add(self.tickButton)
    
    -- Store reference for later button text updates
    self._tickButton = self.tickButton

    self.intermissionButton = TextButton:New("RPE_ECS_Intermission", {
        parent  = self.buttonRow2,
        width   = 100,
        height  = 32,
        text    = "Intermission",
        noBorder = false,
        onClick = function()
            local ev = RPE.Core.ActiveEvent
            if ev then
                local newState = not (ev.isIntermission or false)
                RPE.Core.Comms.Broadcast:SendIntermission(newState)
            end
        end,
    })
    self.buttonRow2:Add(self.intermissionButton)

    self.statsToggleButton = TextButton:New("RPE_ECS_StatsToggle", {
        parent  = self.buttonRow2,
        width   = 100,
        height  = 32,
        text    = "Hide Stats",
        noBorder = false,
        onClick = function()
            self.statsVisible = not self.statsVisible
            self:UpdateStatsVisibility()
        end,
    })
    self.buttonRow2:Add(self.statsToggleButton)

    self:UpdateStartButton(false)
    self:UpdateTickButtonState()
end

--- Update Start/End Event button
---@param isRunning boolean
function EventControlSheet:UpdateStartButton(isRunning)
    -- Check if sync operations are in progress that would lock the start button
    local syncInProgress = false
    if RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast and RPE.Core.Comms.Broadcast._syncOperations then
        for _, syncOp in pairs(RPE.Core.Comms.Broadcast._syncOperations) do
            if syncOp.lockControls then
                syncInProgress = true
                break
            end
        end
    end
    
    if isRunning then
        self.startButton:SetText("End Event")
        self.startButton:SetOnClick(function()
            RPE.Core.ActiveEvent.EndEvent()
            self:UpdateStartButton(false)
            self:UpdateTickButtonState()
        end)
        self.startButton:Unlock()
    else
        self.startButton:SetText("Start Event")
        self.startButton:SetOnClick(function()
            self:StartEvent()
        end)
        
        -- Lock if hash mismatches exist (like Next Tick button behavior)
        if syncInProgress then
            self.startButton:Lock()
        else
            self.startButton:Unlock()
        end
    end
end

--- Lock/unlock Next Tick button based on event status
function EventControlSheet:UpdateTickButtonState()
    local ev = RPE.Core.ActiveEvent
    local isRunning = ev and ev.IsRunning and ev:IsRunning()
    
    -- Check if sync operations are in progress
    local syncInProgress = false
    if RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast and RPE.Core.Comms.Broadcast._syncOperations then
        syncInProgress = next(RPE.Core.Comms.Broadcast._syncOperations) ~= nil
    end
    
    if syncInProgress or not isRunning then
        self.tickButton:Lock()
    else
        self.tickButton:Unlock()
    end
end

--- Start event and update controls (uses Settings sheet values)
function EventControlSheet:StartEvent()
    local s = _getSettings()

    -- Build payload for ActiveEvent
    local payload = {
        name          = s.title,
        subtext       = s.subtext,     -- if your ActiveEvent wants/uses it
        difficulty    = s.difficulty,  -- "NORMAL"|"HEROIC"|"MYTHIC"
        turnOrderType = s.turnOrderType, -- "INITIATIVE"|"PHASE"|"BALANCED"
        teamNames     = {},            -- only include non-empty to avoid clutter
    }
    for i = 1, 4 do
        if s.teamNames[i] and s.teamNames[i] ~= "" then
            payload.teamNames[i] = s.teamNames[i]
        end
    end

    -- Start the event
    RPE.Core.ActiveEvent.StartEvent(payload)

    self:UpdateStartButton(true)
    self:UpdateTickButtonState()
end

--- Build the stats table
function EventControlSheet:BuildStatsTable()
    local Table = RPE_UI.Elements.Table
    if not Table then return end
    
    -- Stats table first
    self.statsTable = Table:New("RPE_ECS_StatsTable", {
        parent = self.sheet,
        width  = 390,
        height = 200,
        rowHeight = 18,
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -12,
    })
    
    self.statsTable:SetColumns({
        { key = "name",    title = "Unit",     width = 150 },
        { key = "damage",  title = "Dmg/Turn", width = 80 },
        { key = "healing", title = "Heal/Turn",width = 80 },
        { key = "threat",  title = "Threat",   width = 80 },
    })
    
    self.sheet:Add(self.statsTable)
    
    -- Stats controls group (below table)
    self.statsControlsGroup = HGroup:New("RPE_ECS_StatsControls", {
        parent = self.sheet,
        autoSize = true,
        spacingX = 12,
        alignH = "CENTER",
    })
    self.sheet:Add(self.statsControlsGroup)
    
    -- Previous page button
    self.statsPrevButton = TextButton:New("RPE_ECS_StatsPrev", {
        parent  = self.statsControlsGroup,
        width   = 60,
        height  = 24,
        text    = "Prev",
        noBorder = false,
        onClick = function()
            if self.statsPage > 1 then
                self.statsPage = self.statsPage - 1
                self:RefreshStatsTable()
            end
        end,
    })
    self.statsControlsGroup:Add(self.statsPrevButton)
    
    -- Page info text
    local Text = RPE_UI.Elements.Text
    if Text then
        self.statsPageText = Text:New("RPE_ECS_StatsPageText", {
            parent = self.statsControlsGroup,
            width = 80,
            height = 24,
            text = "Page 1",
            alignH = "CENTER",
            alignV = "CENTER",
        })
        self.statsControlsGroup:Add(self.statsPageText)
    end
    
    -- Next page button
    self.statsNextButton = TextButton:New("RPE_ECS_StatsNext", {
        parent  = self.statsControlsGroup,
        width   = 60,
        height  = 24,
        text    = "Next",
        noBorder = false,
        onClick = function()
            self.statsPage = self.statsPage + 1
            self:RefreshStatsTable()
        end,
    })
    self.statsControlsGroup:Add(self.statsNextButton)
    
    self:RefreshStatsTable()
    self:UpdateStatsVisibility()
end

--- Show or hide the stats table
function EventControlSheet:UpdateStatsVisibility()
    if not self.statsTable then return end
    
    if self.statsVisible then
        if self.statsTable and self.statsTable.frame then self.statsTable.frame:Show() end
        if self.statsControlsGroup and self.statsControlsGroup.frame then self.statsControlsGroup.frame:Show() end
        self.statsToggleButton:SetText("Hide Stats")
    else
        if self.statsTable and self.statsTable.frame then self.statsTable.frame:Hide() end
        if self.statsControlsGroup and self.statsControlsGroup.frame then self.statsControlsGroup.frame:Hide() end
        self.statsToggleButton:SetText("Show Stats")
    end
    
    -- Trigger EventWindow's own resize logic by refreshing the current tab
    if self.sheet then
        pcall(function() self.sheet:Layout() end)
        
        local EW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.EventWindow
        if EW and EW.ShowTab then
            -- Trigger the EventWindow's ShowTab for "control" to resize properly
            EW:ShowTab("control")
        end
    end
end

--- Refresh the stats table with current event data
function EventControlSheet:RefreshStatsTable()
    if not self.statsTable then return end
    
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units and ev.stats) then
        self.statsTable:SetRows({})
        self.statsTable:Refresh()
        if self.statsPageText then
            self.statsPageText:SetText("Page 0 of 0")
        end
        return
    end
    
    local rows = {}
    local currentTurn = math.max(1, (ev.turn or 1))
    
    -- Build rows from unit list (players only, no NPCs)
    for _, unit in pairs(ev.units) do
        if unit and unit.id and not unit.isNPC then
            local stats = ev.stats[unit.id] or {}
            local totalDamage = stats.damage or 0
            local totalHealing = stats.healing or 0
            local totalThreat = stats.threat or 0
            
            -- Calculate per-turn values
            local damagePerTurn = math.floor(totalDamage / currentTurn)
            local healingPerTurn = math.floor(totalHealing / currentTurn)
            local threatPerTurn = math.floor(totalThreat / currentTurn)
            
            -- Format unit name properly
            local Common = RPE and RPE.Common
            local displayName = (Common and Common.FormatUnitName) and Common:FormatUnitName(unit) or (unit.name or "Unknown")
            
            rows[#rows+1] = {
                name           = displayName,
                damage         = damagePerTurn,
                healing        = healingPerTurn,
                threat         = threatPerTurn,
                unitId         = unit.id,
                totalDamage    = totalDamage,
                totalHealing   = totalHealing,
                totalThreat    = totalThreat,
            }
        end
    end
    
    -- Sort by damage per turn (descending)
    table.sort(rows, function(a, b) return (a.damage or 0) > (b.damage or 0) end)
    
    -- Pagination
    local total = #rows
    local totalPages = math.max(1, math.ceil(total / self.statsPageSize))
    local startIdx = (self.statsPage - 1) * self.statsPageSize + 1
    if startIdx > total then
        self.statsPage = 1
        startIdx = 1
    end
    local endIdx = math.min(startIdx + self.statsPageSize - 1, total)
    local pageRows = {}
    for i = startIdx, endIdx do
        pageRows[#pageRows+1] = rows[i]
    end
    
    -- Update page text
    if self.statsPageText then
        self.statsPageText:SetText("Page " .. self.statsPage .. " of " .. totalPages)
    end
    
    -- Enable/disable navigation buttons
    if self.statsPrevButton then
        if self.statsPage > 1 then
            self.statsPrevButton:Unlock()
        else
            self.statsPrevButton:Lock()
        end
    end
    
    if self.statsNextButton then
        if self.statsPage < totalPages then
            self.statsNextButton:Unlock()
        else
            self.statsNextButton:Lock()
        end
    end
    
    self.statsTable:SetRows(pageRows)
    self.statsTable:Refresh()
    
    -- Add tooltips to each row
    local Common = RPE.Common
    local visibleRows = self.statsTable.rows or {}
    for i = 1, #pageRows do
        local data = pageRows[i]
        local row = visibleRows[i]
        
        if row and data then
            row:SetScript("OnEnter", function()
                local spec = {
                    title = data.name,
                    lines = {
                        { left = "Total Damage: " .. data.totalDamage },
                        { left = "Total Healing: " .. data.totalHealing },
                        { left = "Total Threat: " .. math.floor(data.totalThreat) },
                    }
                }
                if Common and Common.ShowTooltip then
                    Common:ShowTooltip(row, spec)
                end
            end)
            row:SetScript("OnLeave", function()
                if Common and Common.HideTooltip then
                    Common:HideTooltip()
                end
            end)
        end
    end
end

--- Refresh the entire UI state (useful when sync status changes)
function EventControlSheet:Refresh()
    local ev = RPE.Core.ActiveEvent
    local isRunning = ev and ev.IsRunning and ev:IsRunning()
    self:UpdateStartButton(isRunning)
    self:UpdateTickButtonState()
    self:UpdateTickButtonLabel()
    self:RefreshStatsTable()
end

--- Update the tick button text based on event type (non-combat uses "Update", others use "Next Tick")
function EventControlSheet:UpdateTickButtonLabel()
    local ev = RPE.Core.ActiveEvent
    if not (ev and self.tickButton) then return end
    
    local isNonCombat = (ev.turnOrderType == "NON-COMBAT")
    local buttonText = isNonCombat and "Update" or "Next Tick"
    
    if self.tickButton.SetText then
        self.tickButton:SetText(buttonText)
    end
end

--- Get sync status text for display
function EventControlSheet:GetSyncStatusText()
    if not (RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast and RPE.Core.Comms.Broadcast._syncOperations) then
        return ""
    end
    
    local syncOps = RPE.Core.Comms.Broadcast._syncOperations
    local count = 0
    local players = {}
    
    for playerKey, syncOp in pairs(syncOps) do
        count = count + 1
        table.insert(players, syncOp.playerName or playerKey)
    end
    
    if count == 0 then
        return ""
    elseif count == 1 then
        return "Syncing to " .. players[1] .. "..."
    else
        return string.format("Syncing to %d players...", count)
    end
end

--- Constructor
function EventControlSheet.New(opts)
    local self = setmetatable({}, EventControlSheet)
    self:BuildUI(opts or {})
    return self
end

return EventControlSheet
