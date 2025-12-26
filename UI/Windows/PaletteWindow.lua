-- RPE_UI/Windows/PaletteWindow.lua
RPE_UI        = RPE_UI or {}
RPE_UI.Windows = RPE_UI.Windows or {}

local Window = RPE_UI.Elements.Window
local VGroup = RPE_UI.Elements.VerticalLayoutGroup
local HGroup = RPE_UI.Elements.HorizontalLayoutGroup
local TextButton = RPE_UI.Elements.TextButton
local Text = RPE_UI.Elements.Text
local HBorder = RPE_UI.Elements.HorizontalBorder
local C = RPE_UI.Colors

---@class PaletteWindow: Window
---@field root Window
---@field sheet VGroup
---@field buttons TextButton[]
---@field paletteGrid VGroup
local PaletteWindow = {}
PaletteWindow.__index = PaletteWindow
RPE_UI.Windows.PaletteWindow = PaletteWindow

function PaletteWindow:New(opts)
    opts = opts or {}
    
    ---@type PaletteWindow
    local o = setmetatable({}, self)
    
    -- Create root window with autoSize
    o.root = Window:New("RPE_PaletteWindow", {
        parent = opts.parent,
        title = opts.title or "Palettes",
        width = 400,
        height = 250,
    })
    
    -- Top border
    o.topBorder = HBorder:New("RPE_PaletteWindow_TopBorder", {
        parent = o.root,
        stretch = true,
        thickness = 3,
        y = 0,
        layer = "BORDER",
    })
    o.topBorder.frame:ClearAllPoints()
    o.topBorder.frame:SetPoint("TOPLEFT", o.root.frame, "TOPLEFT", 0, 0)
    o.topBorder.frame:SetPoint("TOPRIGHT", o.root.frame, "TOPRIGHT", 0, 0)
    C.ApplyHighlight(o.topBorder)
    
    -- Bottom border
    o.bottomBorder = HBorder:New("RPE_PaletteWindow_BottomBorder", {
        parent = o.root,
        stretch = true,
        thickness = 3,
        y = 0,
        layer = "BORDER",
    })
    o.bottomBorder.frame:ClearAllPoints()
    o.bottomBorder.frame:SetPoint("BOTTOMLEFT", o.root.frame, "BOTTOMLEFT", 0, 0)
    o.bottomBorder.frame:SetPoint("BOTTOMRIGHT", o.root.frame, "BOTTOMRIGHT", 0, 0)
    C.ApplyHighlight(o.bottomBorder)
    
    o.buttons = {}
    
    -- Create main sheet (VGroup) with auto-sizing
    o.sheet = VGroup:New("RPE_PaletteWindow_Sheet", {
        parent = o.root,
        width = 1,
        height = 1,
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = 0,
        padding = { left = 4, right = 4, top = 24, bottom = 32 },
        spacingY = 4,
        alignV = "TOP",
        alignH = "CENTER",
        autoSize = true,
    })
    
    -- Title text
    local titleText = Text:New("RPE_PaletteWindow_Title", {
        parent = o.sheet,
        text = "Select a Palette",
        fontTemplate = "GameFontNormal",
    })
    o.sheet:Add(titleText)
    
    -- Container for grid (to enable column wrapping)
    o.paletteGrid = VGroup:New("RPE_PaletteWindow_Grid", {
        parent = o.sheet,
        width = 1,
        height = 1,
        spacingY = 4,
        spacingX = 4,
        alignV = "TOP",
        alignH = "LEFT",
        autoSize = true,
    })
    o.sheet:Add(o.paletteGrid)
    
    -- Get list of available palettes
    local palettes = C.ListPalettes()
    
    -- Create buttons in a 3-column grid using HGroups
    local COLS = 3
    local BUTTON_WIDTH = 120
    local BUTTON_HEIGHT = 28
    
    for idx, paletteName in ipairs(palettes) do
        local col = (idx - 1) % COLS
        
        -- Create a new row group if starting a new row
        if col == 0 then
            local rowGroup = HGroup:New("RPE_PaletteWindow_Row_" .. math.floor((idx - 1) / COLS), {
                parent = o.paletteGrid,
                width = 1,
                spacingX = 4,
                alignH = "LEFT",
                alignV = "TOP",
                autoSize = true,
            })
            o.paletteGrid:Add(rowGroup)
            o._currentRowGroup = rowGroup
        end
        
        local btn = TextButton:New("PaletteButton_" .. paletteName, {
            parent = o._currentRowGroup,
            text = paletteName,
            width = BUTTON_WIDTH,
            height = BUTTON_HEIGHT,
        })
        
        -- Capture paletteName in closure for click handler
        local pName = paletteName
        btn:SetOnClick(function()
            o:SelectPalette(pName)
        end)
        
        o._currentRowGroup:Add(btn)
        table.insert(o.buttons, btn)
    end
    
    -- Close button (top-right, like Clipboard)
    o.closeBtn = CreateFrame("Button", "RPE_PaletteWindow_CloseBtn", o.root.frame)
    o.closeBtn:SetSize(24, 24)
    o.closeBtn:SetPoint("TOPRIGHT", o.root.frame, "TOPRIGHT", -8, -8)
    o.closeBtn:SetText("×")
    o.closeBtn:SetNormalFontObject("GameFontHighlightLarge")
    o.closeBtn:GetFontString():SetTextColor(0.9, 0.9, 0.95, 1.0)
    
    local closeHover = o.closeBtn:CreateTexture(nil, "BACKGROUND")
    closeHover:SetAllPoints()
    closeHover:SetColorTexture(0.2, 0.2, 0.25, 0)
    o.closeBtn._hoverTex = closeHover
    
    o.closeBtn:SetScript("OnEnter", function(btn)
        btn._hoverTex:SetColorTexture(0.3, 0.3, 0.35, 0.5)
    end)
    o.closeBtn:SetScript("OnLeave", function(btn)
        btn._hoverTex:SetColorTexture(0.2, 0.2, 0.25, 0)
    end)
    o.closeBtn:SetScript("OnClick", function()
        o.root.frame:Hide()
    end)
    
    -- Register as palette consumer to update colors
    C.RegisterConsumer(o)
    
    return o
end

---Select and apply a palette, saving to profile
---@param paletteName string
function PaletteWindow:SelectPalette(paletteName)
    C.ApplyPalette(paletteName)
    
    -- Save to current profile
    local prof = RPE.Profile.DB.GetOrCreateActive()
    if prof then
        prof:SetPaletteName(paletteName)
        RPE.Profile.DB.SaveProfile(prof)
    end
end

---Update palette colors when theme changes (palette consumer)
function PaletteWindow:ApplyPalette()
    if self.topBorder then
        C.ApplyHighlight(self.topBorder)
    end
    if self.bottomBorder then
        C.ApplyHighlight(self.bottomBorder)
    end
end

return PaletteWindow
