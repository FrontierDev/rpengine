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

    local teamNames = { "", "", "", "" }
    if type(s.teamNames) == "table" then
        for i = 1, 4 do
            local v = s.teamNames[i]
            teamNames[i] = (type(v) == "string" and v) or ""
        end
    end

    return {
        title      = title,
        subtext    = subtext,
        difficulty = diff,
        teamNames  = teamNames,
    }
end

--- Build UI
---@param opts table
function EventControlSheet:BuildUI(opts)
    opts = opts or {}
    self.rows = opts.rows or 6
    self.cols = opts.cols or 8
    self.slots = {}

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

    self:DrawButtons()

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

    self.startButton = TextButton:New("RPE_ECS_Start_End", {
        parent  = self.buttonRow,
        width   = 100,
        height  = 32,
        noBorder = false,
    })
    self.buttonRow:Add(self.startButton)

    self.tickButton = TextButton:New("RPE_ECS_Next_Tick", {
        parent  = self.buttonRow,
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
    self.buttonRow:Add(self.tickButton)

    self:UpdateStartButton(false)
    self:UpdateTickButtonState()
end

--- Update Start/End Event button
---@param isRunning boolean
function EventControlSheet:UpdateStartButton(isRunning)
    if isRunning then
        self.startButton:SetText("End Event")
        self.startButton:SetOnClick(function()
            RPE.Core.ActiveEvent.EndEvent()
            self:UpdateStartButton(false)
            self:UpdateTickButtonState()
        end)
    else
        self.startButton:SetText("Start Event")
        self.startButton:SetOnClick(function()
            self:StartEvent()
        end)
    end
end

--- Lock/unlock Next Tick button based on event status
function EventControlSheet:UpdateTickButtonState()
    local ev = RPE.Core.ActiveEvent
    local isRunning = ev and ev.IsRunning and ev:IsRunning()
    if isRunning then
        self.tickButton:Unlock()
    else
        self.tickButton:Lock()
    end
end

--- Start event and update controls (uses Settings sheet values)
function EventControlSheet:StartEvent()
    local s = _getSettings()

    -- Build payload for ActiveEvent
    local payload = {
        name       = s.title,
        subtext    = s.subtext,     -- if your ActiveEvent wants/uses it
        difficulty = s.difficulty,  -- "NORMAL"|"HEROIC"|"MYTHIC"
        teamNames  = {},            -- only include non-empty to avoid clutter
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

--- Constructor
function EventControlSheet.New(opts)
    local self = setmetatable({}, EventControlSheet)
    self:BuildUI(opts or {})
    return self
end

return EventControlSheet
