-- RPE_UI/Prefabs/TraitEntry.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement          = RPE_UI.Elements.FrameElement
local HorizontalLayoutGroup = RPE_UI.Elements.HorizontalLayoutGroup
local Text                  = RPE_UI.Elements.Text

---@class TraitEntry: FrameElement
---@field icon Texture
---@field name Text
---@field auraId string|nil
local TraitEntry = setmetatable({}, { __index = FrameElement })
TraitEntry.__index = TraitEntry
RPE_UI.Prefabs.TraitEntry = TraitEntry

function TraitEntry:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "TraitEntry:New requires opts.parent")

    local width     = opts.width or 180
    local height    = opts.height or 24
    local iconSize  = opts.iconSize or 20
    local auraId    = opts.auraId or nil
    local onClick   = opts.onClick

    local f = CreateFrame("Frame", name, opts.parent.frame or UIParent)
    f:SetSize(width, height)

    -- === Highlight texture ===
    local hl = f:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08) -- white tint, 8% alpha
    hl:Hide()

    f:SetScript("OnEnter", function() hl:Show() end)
    f:SetScript("OnLeave", function() hl:Hide() end)

    ---@type TraitEntry
    local o = FrameElement.New(self, "TraitEntry", f, opts.parent)
    o.auraId = auraId

    -- Horizontal layout
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

    -- Icon
    local iconContainer = CreateFrame("Frame", nil, hGroup.frame)
    iconContainer:SetSize(iconSize, iconSize)
    local ic = iconContainer:CreateTexture(nil, "ARTWORK")
    ic:SetAllPoints()
    if opts.icon then ic:SetTexture(opts.icon) end
    o.icon = ic
    local iconElement = FrameElement.New(FrameElement, "IconFrame", iconContainer, hGroup)
    hGroup:Add(iconElement)

    -- Name (with optional subtitle for racial/class traits)
    local nameWidth = width - iconSize - (2 * hGroup.spacingX)
    
    -- Check if this is a racial or class trait
    local traitType = nil  -- "Racial" or "Class"
    if auraId then
        local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
        if AuraRegistry then
            local auraDef = AuraRegistry:Get(auraId)
            if auraDef and auraDef.tags then
                for _, tag in ipairs(auraDef.tags) do
                    if type(tag) == "string" then
                        local tagLower = tag:lower()
                        if tagLower:sub(1, 5) == "race:" then
                            traitType = "Racial"
                            break
                        elseif tagLower:sub(1, 6) == "class:" then
                            traitType = "Class"
                            break
                        end
                    end
                end
            end
        end
    end
    
    if traitType then
        -- Use a vertical group for name + subtitle
        local nameGroup = RPE_UI.Elements and RPE_UI.Elements.VerticalLayoutGroup and RPE_UI.Elements.VerticalLayoutGroup:New(name .. "_NameGroup", {
            parent = hGroup,
            autoSize = false,
            width = nameWidth,
            height = height,
            alignV = "TOP",
            alignH = "LEFT",
            spacingY = 0,
            paddingTop = 0,
            paddingBottom = 0,
        }) or nil
        
        if nameGroup then
            o.name = Text:New(name .. "_Name", {
                parent = nameGroup,
                width = nameWidth,
                height = 12,
                text = opts.label or "",
                fontTemplate = "GameFontNormalSmall",
            })
            o.name.fs:ClearAllPoints()
            o.name.fs:SetPoint("LEFT", o.name.frame, "LEFT", 0, 0)
            o.name.fs:SetJustifyH("LEFT")
            nameGroup:Add(o.name)
            
            local subtitle = Text:New(name .. "_Subtitle", {
                parent = nameGroup,
                width = nameWidth,
                height = 10,
                text = "(" .. traitType .. ")",
                fontTemplate = "GameFontNormalSmall",
            })
            subtitle.fs:ClearAllPoints()
            subtitle.fs:SetPoint("LEFT", subtitle.frame, "LEFT", 0, 0)
            subtitle.fs:SetJustifyH("LEFT")
            
            -- Apply textMuted color (0.75, 0.75, 0.80) - do this after positioning
            -- Use a short delay to ensure fontstring is fully initialized
            C_Timer.After(0, function()
                if subtitle.fs then
                    subtitle.fs:SetTextColor(0.75, 0.75, 0.80, 1.00)
                end
            end)
            
            nameGroup:Add(subtitle)
            
            hGroup:Add(nameGroup)
        else
            -- Fallback if VerticalLayoutGroup isn't available
            o.name = Text:New(name .. "_Name", {
                parent = hGroup,
                width = nameWidth,
                height = height,
                text = opts.label or "",
                fontTemplate = "GameFontNormalSmall",
            })
            o.name.fs:ClearAllPoints()
            o.name.fs:SetPoint("LEFT", o.name.frame, "LEFT", 0, 0)
            o.name.fs:SetJustifyH("LEFT")
            hGroup:Add(o.name)
        end
    else
        -- Non-racial trait: just show the name normally
        o.name = Text:New(name .. "_Name", {
            parent = hGroup,
            width = nameWidth,
            height = height,
            text = opts.label or "",
            fontTemplate = "GameFontNormalSmall",
        })
        o.name.fs:ClearAllPoints()
        o.name.fs:SetPoint("LEFT", o.name.frame, "LEFT", 0, 0)
        o.name.fs:SetJustifyH("LEFT")
        hGroup:Add(o.name)
    end

    f:SetScript("OnEnter", function()
        hl:Show()
        if not auraId then return end
        local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
        if not AuraRegistry then return end
        local auraDef = AuraRegistry:Get(auraId)
        if not auraDef then return end
        
        -- Use RPE.Common:ShowTooltip for consistent tooltip display
        if RPE and RPE.Common and RPE.Common.ShowTooltip then
            RPE.Common:ShowTooltip(f, {
                title = auraDef.name or auraId,
                titleColor = { 1, 1, 1 },
                lines = auraDef.description and { { text = auraDef.description } } or {},
            })
        end
    end)
    f:SetScript("OnLeave", function() hl:Hide(); if RPE and RPE.Common and RPE.Common.HideTooltip then RPE.Common:HideTooltip() end end)

    -- Click handler
    if onClick then
        f:SetScript("OnMouseDown", function()
            onClick()
        end)
    end

    return o
end

function TraitEntry:SetIcon(path) if path then self.icon:SetTexture(path) end end
function TraitEntry:SetLabel(t)   self.name:SetText(t or "") end

return TraitEntry
