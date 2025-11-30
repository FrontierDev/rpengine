-- RPE_UI/Prefabs/StatEntry.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement          = RPE_UI.Elements.FrameElement
local HorizontalLayoutGroup = RPE_UI.Elements.HorizontalLayoutGroup
local Text                  = RPE_UI.Elements.Text

---@class StatEntry: FrameElement
---@field icon Texture
---@field name Text
---@field mod  Text
local StatEntry = setmetatable({}, { __index = FrameElement })
StatEntry.__index = StatEntry
RPE_UI.Prefabs.StatEntry = StatEntry

function StatEntry:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "StatEntry:New requires opts.parent")

    local width     = opts.width or 180
    local height    = opts.height or 18
    local iconSize  = opts.iconSize or 16
    local modWidth  = opts.modWidth or 28
    local stat      = opts.stat or nil

    local f = CreateFrame("Frame", name, opts.parent.frame or UIParent)
    f:SetSize(width, height)

    -- === Highlight texture ===
    local hl = f:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08) -- white tint, 8% alpha
    hl:Hide()

    f:SetScript("OnEnter", function() hl:Show() end)
    f:SetScript("OnLeave", function() hl:Hide() end)

    ---@type StatEntry
    local o = FrameElement.New(self, "StatEntry", f, opts.parent)

    -- Horizontal layout
    local hGroup = HorizontalLayoutGroup:New(name .. "_HGroup", {
        parent        = o,
        autoSize      = false,
        width         = width,
        height        = height,
        alignV        = "CENTER",
        spacingX      = 4,
        paddingLeft   = 0,
        paddingRight  = 0,
        paddingTop    = 0,
        paddingBottom = 0,
    })
    o:AddChild(hGroup)

    -- Icon
    local iconContainer = CreateFrame("Frame", nil, hGroup.frame)
    iconContainer:SetSize(iconSize, iconSize)
    local ic = iconContainer:CreateTexture(nil, "ARTWORK")
    ic:SetAllPoints()
    if opts.icon then ic:SetTexture(opts.icon) end
    o.icon = ic
    local iconElement = FrameElement.New(FrameElement, "IconFrame", iconContainer, hGroup)
    hGroup:Add(iconElement)

    -- Name
    local nameWidth = width - iconSize - (2 * hGroup.spacingX) - modWidth - 4
    o.name = Text:New(name .. "_Name", {
        parent       = hGroup,
        width        = nameWidth,
        height       = height,
        text         = opts.label or "",
        fontTemplate = "GameFontNormalSmall",
    })
    -- Force fontstring flush-left
    o.name.fs:ClearAllPoints()
    o.name.fs:SetPoint("LEFT", o.name.frame, "LEFT", 0, 0)
    o.name.fs:SetJustifyH("LEFT")
    hGroup:Add(o.name)

    -- Modifier (right aligned)
    o.mod = Text:New(name .. "_Mod", {
        parent       = hGroup,
        width        = modWidth,
        height       = height,
        text         = opts.modifier or "",
        fontTemplate = "GameFontHighlightSmall",
        justifyH     = "RIGHT",
        textPoint    = "RIGHT",          -- anchor FS to the right edge
        textRelativePoint = "RIGHT",
        textX        = 0,
        textY        = 0,
    })

    -- Force flush-right
    o.mod.fs:ClearAllPoints()
    o.mod.fs:SetPoint("RIGHT", o.mod.frame, "RIGHT", 0, 0)
    o.mod.fs:SetJustifyH("RIGHT")
    hGroup:Add(o.mod)

    f:SetScript("OnEnter", function()
        hl:Show()
        if not opts.stat or not opts.stat.tooltip then return end
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        GameTooltip:AddLine(Common:ParseText(opts.stat.tooltip), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() hl:Hide(); GameTooltip:Hide() end)

    return o
end

function StatEntry:SetIcon(path) if path then self.icon:SetTexture(path) end end
function StatEntry:SetLabel(t)   self.name:SetText(t or "") end
function StatEntry:SetMod(t)     self.mod:SetText(t or "") end

return StatEntry
