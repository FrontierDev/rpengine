-- RPE_UI/Sheets/DashboardArmorySheet.lua
RPE             = RPE or {}
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local VGroup       = RPE_UI.Elements.VerticalLayoutGroup
local HGroup       = RPE_UI.Elements.HorizontalLayoutGroup
local Text         = RPE_UI.Elements.Text
local FrameElement = RPE_UI.Elements.FrameElement
local TextButton   = RPE_UI.Elements.TextButton
local C            = RPE_UI.Colors

---@class DashboardArmorySheet
---@field sheet VGroup
local DashboardArmorySheet = {}
_G.RPE_UI.Windows.DashboardArmorySheet = DashboardArmorySheet
DashboardArmorySheet.__index = DashboardArmorySheet
DashboardArmorySheet.Name = "DashboardArmorySheet"

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.DashboardArmorySheet = self
end

function DashboardArmorySheet:BuildUI(opts)
    opts = opts or {}

    self.sheet = VGroup:New("RPE_DAS_Sheet", {
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

    -- Header
    local header = Text:New("RPE_DAS_Header", {
        parent       = self.sheet,
        text         = "Armory",
        fontTemplate = "GameFontHighlightLarge",
        justifyH     = "CENTER",
    })
    C.ApplyText(header.fs, "text")
    self.sheet:Add(header)

    -- Placeholder content
    local placeholderText = Text:New("RPE_DAS_Placeholder", {
        parent       = self.sheet,
        text         = RPE.Common.InlineIcons.Warning .. " RPE Armory is not yet implemented.",
        fontTemplate = "GameFontNormal",
        justifyH     = "CENTER",
    })
    C.ApplyText(placeholderText.fs, "textMuted")
    self.sheet:Add(placeholderText)

    -- Example button row
    local buttonRow = HGroup:New("RPE_DAS_ButtonRow", {
        parent = self.sheet,
        height = 1,
        width = 1,
        autoSize = true,
        spacingX = 12,
        alignH = "CENTER",
    })
    self.sheet:Add(buttonRow)
    buttonRow:Hide()

    local exampleButton = TextButton:New("RPE_DAS_Example", {
        parent  = buttonRow,
        width   = 100,
        height  = 32,
        text    = "Example",
        noBorder = false,
        onClick = function()
            RPE.Debug:Print("Armory example button clicked")
        end,
    })
    buttonRow:Add(exampleButton)

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function DashboardArmorySheet.New(opts)
    local self = setmetatable({}, DashboardArmorySheet)
    self:BuildUI(opts or {})
    return self
end

return DashboardArmorySheet
