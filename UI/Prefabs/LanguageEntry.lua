-- RPE_UI/Prefabs/LanguageEntry.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement          = RPE_UI.Elements.FrameElement
local HorizontalLayoutGroup = RPE_UI.Elements.HorizontalLayoutGroup
local VerticalLayoutGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text                  = RPE_UI.Elements.Text

---@class LanguageEntry: FrameElement
---@field icon Texture
---@field name Text
---@field skill Text
---@field progressBar Texture
---@field languageName string
---@field skillLevel number
local LanguageEntry = setmetatable({}, { __index = FrameElement })
LanguageEntry.__index = LanguageEntry
RPE_UI.Prefabs.LanguageEntry = LanguageEntry

local function getSkillColor(skillLevel)
    -- skillLevel is 1-300, max is 300
    local pct = skillLevel / 300
    
    if pct < 0.2 then
        -- Red
        return { 0.95, 0.55, 0.55 }
    elseif pct < 0.4 then
        -- Orange
        return { 0.95, 0.75, 0.55 }
    elseif pct < 0.6 then
        -- Yellow
        return { 0.95, 0.95, 0.55 }
    elseif pct < 0.99 then
        -- Green
        return { 0.55, 0.95, 0.65 }
    else
        -- Perfect (300): Grey
        return { 0.75, 0.75, 0.80 }
    end
end

function LanguageEntry:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "LanguageEntry:New requires opts.parent")

    local width       = opts.width or 220
    local height      = opts.height or 24
    local iconSize    = opts.iconSize or 20
    local languageName = opts.languageName or ""
    local skillLevel  = opts.skillLevel or 0

    local f = CreateFrame("Frame", name, opts.parent.frame or UIParent)
    f:SetSize(width, height)

    -- === Highlight texture ===
    local hl = f:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08) -- white tint, 8% alpha
    hl:Hide()

    -- Hover-over effect (disabled by default, enabled only for special buttons like "Learn Language")
    if opts.isButton then
        f:SetScript("OnEnter", function() hl:Show() end)
        f:SetScript("OnLeave", function() hl:Hide() end)
    end

    -- Enable click handling if onClick is provided
    if opts.onClick then
        f:EnableMouse(true)
        f:SetScript("OnMouseUp", opts.onClick)
    end

    ---@type LanguageEntry
    local o = FrameElement.New(self, "LanguageEntry", f, opts.parent)
    o.languageName = languageName
    o.skillLevel = skillLevel
    o.skillLevel = skillLevel

    -- Horizontal layout (icon + vertical content group)
    local hGroup = HorizontalLayoutGroup:New(name .. "_HGroup", {
        parent        = o,
        autoSize      = false,
        width         = width,
        height        = height,
        alignV        = "CENTER",
        spacingX      = 6,
        paddingLeft   = 0,
        paddingRight  = 0,
        paddingTop    = 0,
        paddingBottom = 0,
    })
    o:AddChild(hGroup)

    -- Icon (language icon)
    local iconContainer = CreateFrame("Frame", nil, hGroup.frame)
    iconContainer:SetSize(iconSize, iconSize)
    local ic = iconContainer:CreateTexture(nil, "ARTWORK")
    ic:SetAllPoints()
    if opts.icon then ic:SetTexture(opts.icon) end
    o.icon = ic
    local iconElement = FrameElement.New(FrameElement, "IconFrame", iconContainer, hGroup)
    hGroup:Add(iconElement)

    -- Vertical content group (name/skill + progress bar)
    local contentWidth = width - iconSize - (2 * hGroup.spacingX)
    local contentGroup = VerticalLayoutGroup:New(name .. "_ContentGroup", {
        parent = hGroup,
        autoSize = false,
        width = contentWidth,
        height = height,
        alignV = "TOP",
        alignH = "LEFT",
        spacingY = 0,
        paddingTop = 0,
        paddingBottom = 0,
    })
    
    -- Top row: Name only
    local topRow = HorizontalLayoutGroup:New(name .. "_TopRow", {
        parent = contentGroup,
        autoSize = false,
        width = contentWidth,
        height = 12,
        alignV = "CENTER",
        alignH = "LEFT",
        spacingX = 0,
        paddingLeft = 0,
        paddingRight = 0,
    })
    contentGroup:Add(topRow)
    
    -- Name (left-aligned, takes up space)
    local nameText = Text:New(name .. "_Name", {
        parent = topRow,
        text   = languageName,
        width  = contentWidth,
        height = 12,
        fontTemplate = "GameFontNormalSmall",
    })
    nameText.fs:ClearAllPoints()
    nameText.fs:SetPoint("LEFT", nameText.frame, "LEFT", 0, 0)
    nameText.fs:SetJustifyH("LEFT")
    topRow:Add(nameText)
    o.name = nameText

    -- Progress bar row with skill level above right end
    local barRowContainer = CreateFrame("Frame", nil, contentGroup.frame)
    barRowContainer:SetSize(contentWidth, 16)  -- room for skill level + progress bar
    
    local barRowElement = FrameElement.New(FrameElement, "BarRow", barRowContainer, contentGroup)
    contentGroup:Add(barRowElement)
    
    -- Remove button (left side, only for non-default languages)
    local removeBtn = nil
    if opts.onRemove and not opts.isDefaultLanguage then
        local removeFrame = CreateFrame("Button", name .. "_RemoveBtn", barRowContainer)
        removeFrame:SetSize(12, 12)
        removeFrame:SetPoint("RIGHT", barRowContainer, "LEFT", -6, 0)
        
        -- Create an X texture for the remove button
        local removeTexture = removeFrame:CreateTexture(nil, "ARTWORK")
        removeTexture:SetAllPoints()
        removeTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        
        -- Make the button clickable with hover effect
        removeFrame:EnableMouse(true)
        removeFrame:SetScript("OnEnter", function(self)
            --removeTexture:SetColorTexture(0.9, 0.3, 0.3, 1.0)  -- Red on hover
        end)
        removeFrame:SetScript("OnLeave", function(self)
            --  removeTexture:SetColorTexture(0.5, 0.5, 0.5, 0.6)  -- Grey normally
        end)
        removeFrame:SetScript("OnMouseUp", function()
            opts.onRemove()
        end)
        
        removeBtn = FrameElement.New(FrameElement, "RemoveBtn", removeFrame, barRowElement)
        barRowElement:AddChild(removeBtn)
        o.removeBtn = removeBtn
    end
    
    -- Skill level (right-aligned, above progress bar)
    local skillColor = getSkillColor(skillLevel)
    local skillFrame = CreateFrame("Frame", name .. "_SkillFrame", barRowContainer)
    skillFrame:SetSize(40, 12)
    skillFrame:SetPoint("RIGHT", barRowContainer, "RIGHT", 0, 4)  -- positioned above the bar
    
    local skillFS = skillFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    skillFS:SetPoint("RIGHT", skillFrame, "RIGHT", 0, 11)
    skillFS:SetText(tostring(skillLevel))
    skillFS:SetTextColor(skillColor[1], skillColor[2], skillColor[3], 1.0)
    skillFS:SetJustifyH("RIGHT")
    
    -- Wrap it in a FrameElement for consistency
    ---@type any
    local skillElement = FrameElement.New(FrameElement, "SkillText", skillFrame, barRowElement)
    skillElement.fs = skillFS  -- Store reference to fontstring
    skillElement.SetText = function(self, text) self.fs:SetText(text) end
    o.skill = skillElement
    
    -- Hide skill and progress bar if this is a button entry
    if opts.isButton then
        skillFrame:Hide()
        barRowContainer:Hide()
    end

    -- Progress bar background
    local progressBg = CreateFrame("Frame", nil, barRowContainer)
    local barLeft = 0  -- Adjust left position if remove button exists
    progressBg:SetSize(contentWidth - barLeft, 4)
    progressBg:SetPoint("LEFT", barRowContainer, "LEFT", barLeft, 0)
    progressBg:SetPoint("RIGHT", barRowContainer, "RIGHT", 0, 0)
    progressBg:SetHeight(4)
    
    local bgTex = progressBg:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Progress bar fill
    local progressBar = progressBg:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
    local barWidth = (skillLevel / 300) * (contentWidth - barLeft)
    progressBar:SetSize(barWidth, 4)
    
    local r, g, b, a = RPE_UI.Colors and RPE_UI.Colors.Get("progress_xp") or 0.45, 0.30, 0.65, 0.9
    if r then
        progressBar:SetColorTexture(r, g, b, a)
    else
        progressBar:SetColorTexture(0.45, 0.30, 0.65, 0.9)
    end
    o.progressBar = progressBar
    
    local progressElement = FrameElement.New(FrameElement, "ProgressFrame", progressBg, barRowElement)
    barRowElement:AddChild(progressElement)

    hGroup:Add(contentGroup)

    return o
end

function LanguageEntry:SetIcon(path)
    if path then self.icon:SetTexture(path) end
end

function LanguageEntry:SetLabel(t)
    if self.name and self.name.SetText then
        self.name:SetText(t or "")
    end
end

function LanguageEntry:SetSkill(skillLevel)
    if self.skill and self.skill.SetText then
        self.skill:SetText(tostring(skillLevel or 0))
    end
end

return LanguageEntry
