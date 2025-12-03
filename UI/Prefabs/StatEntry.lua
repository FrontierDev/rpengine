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

    -- Click handler for advantage rolls
    f:EnableMouse(true)
    f:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and opts.stat then
            -- Perform a hit_roll with advantage/disadvantage based on stat
            local Advantage = RPE and RPE.Core and RPE.Core.Advantage
            local ProfileDB = RPE and RPE.Profile and RPE.Profile.DB

            if not (Advantage and ProfileDB) then
            return
            end

            local statName = opts.stat.name or opts.label or "Stat"
            local statId = opts.stat.id or statName:upper()
            local profile = ProfileDB.GetOrCreateActive()

            if not profile then return end

            -- Get the hit_roll formula from the active ruleset
            local hitRollFormula = "1d20"  -- default fallback
            if profile.ruleset then
            local RulesetProfile = RPE and RPE.Core and RPE.Core.RulesetProfile
            if RulesetProfile then
                local rulesetData = RulesetProfile:Get(profile.ruleset)
                if rulesetData and rulesetData.rules and rulesetData.rules.hit_roll then
                hitRollFormula = rulesetData.rules.hit_roll
                end
            end
            end

            -- Roll using hit_roll formula with stat's advantage/disadvantage
            local result = Advantage:Roll(hitRollFormula, profile, statId)

            -- Parse modifier from the mod text (e.g. "+3" or "-2")
            local modText = opts.modifier or "0"
            local modifier = tonumber(modText) or 0
            local total = result + modifier

            -- Format display with modifier
            local playerName = UnitName("player")
            local displayText
            if modifier ~= 0 then
                displayText = string.format("%s rolls %s: %d (%d + %d)", playerName, statName, total, result, modifier)
            else
                displayText = string.format("%s rolls %s: %d", playerName, statName, result)
            end

            -- Print result to chat
            local Broadcast = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
            local Debug = RPE and RPE.Debug
            
            if Broadcast then
                local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
                if playerId then
                    Broadcast:SendDiceMessage(playerId, playerName, displayText)
                elseif Debug then
                    -- Fallback to Debug:Dice if no active event
                    Debug:Dice(displayText)
                end
            elseif Debug then
                Debug:Dice(displayText)
            end
        end
    end)

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
