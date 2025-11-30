-- RPE_UI/Windows/BestiarySheet.lua
RPE             = RPE or {}
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.ActiveRules = RPE.ActiveRules
RPE.Core.ActiveEvent = RPE.Core.ActiveEvent

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local FrameElement = RPE_UI.Elements.FrameElement
local TextButton = RPE_UI.Elements.TextButton

-- Prefabs
local InventorySlot = RPE_UI.Prefabs.InventorySlot

---@class BestiarySheet
---@field Name string
---@field root Window
---@field grid VGroup
---@field slots InventorySlot[]
local BestiarySheet = {}
_G.RPE_UI.Windows.BestiarySheet = BestiarySheet
BestiarySheet.__index = BestiarySheet
BestiarySheet.Name = "BestiarySheet"

-- Expose under RPE.Core.Windows too
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.BestiarySheet = self
end

--- Build UI
---@param opts table
function BestiarySheet:BuildUI(opts)
    opts = opts or {}
    self.rows = opts.rows or 6
    self.cols = opts.cols or 8
    self.slots = {}

    self.sheet = VGroup:New("RPE_DBS_Sheet", {
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

    self.buttonRow = HGroup:New("RPE_DBS_Button_Row", {
        parent = self.sheet,
        height = 1,
        width = 1,
        autoSize = true,
        spacingX = 12,
    })
    self.sheet:Add(self.buttonRow)

    self:DrawButtons()

    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function BestiarySheet:DrawButtons()
    self.pushButton = TextButton:New("RPE_DBS_PushRuleset", {
        parent  = self.buttonRow,
        width   = 100,
        height  = 32,
        text    = "Sync Ruleset",
        noBorder = false,
        onClick = function()
            self.startButton:SetText("Start Event (ok)")
            RPE.Core.Comms.Broadcast:SendActiveRulesetToSupergroup()
        end,
    })
    self.buttonRow:Add(self.pushButton)

    self.startButton = TextButton:New("RPE_DBS_test_Start", {
        parent  = self.buttonRow,
        width   = 100,
        height  = 32,
        text    = "Start Event (??)",
        noBorder = false,
        onClick = function()
            RPE.Core.ActiveEvent.StartEvent({})
        end,
    })
    self.buttonRow:Add(self.startButton)

end

function BestiarySheet:StartEvent()
    -- Pass control to the actual event...
    RPE.Core.ActiveEvent.StartEvent({})
end

function BestiarySheet.New(opts)
    local self = setmetatable({}, BestiarySheet)
    self:BuildUI(opts or {})
    return self
end

return BestiarySheet
