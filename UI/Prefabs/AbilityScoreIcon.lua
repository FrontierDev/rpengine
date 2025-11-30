-- RPE_UI/Prefabs/AbilityScoreIcon.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local IconButton   = RPE_UI.Elements.IconButton
local Text         = RPE_UI.Elements.Text

---@class AbilityScoreIcon: IconButton
---@field abbr Text
---@field score Text
---@field mod Text
local AbilityScoreIcon = setmetatable({}, { __index = IconButton })
AbilityScoreIcon.__index = AbilityScoreIcon
RPE_UI.Prefabs.AbilityScoreIcon = AbilityScoreIcon

function AbilityScoreIcon:New(name, opts)
    opts = opts or {}
    opts.width  = opts.width  or 48
    opts.height = opts.height or 48

    ---@type AbilityScoreIcon
    local o = IconButton.New(self, name, opts)

    -- Top: Abbreviation (e.g., "STR")
    o.abbr = Text:New(name .. "_Abbr", {
        parent = o,
        text = opts.abbr or "",
        fontTemplate = "GameFontNormalSmall",
        textPoint = "TOP",
        textY = -2,
    })
    o.abbr:SetAllPoints(o.frame)  -- <<< ensure anchor space matches the button

    -- Center: Score (e.g., "16")
    o.score = Text:New(name .. "_Score", {
        parent = o,
        text = opts.score or "",
        fontTemplate = "GameFontHighlightLarge",
        textPoint = "CENTER",
    })
    o.score:SetAllPoints(o.frame)

    -- Bottom: Modifier (e.g., "+3")
    o.mod = Text:New(name .. "_Mod", {
        parent = o,
        text = opts.mod or "",
        fontTemplate = "GameFontNormalSmall",
        textPoint = "BOTTOM",
        textY = 2,
    })
    o.mod:SetAllPoints(o.frame)

    return o
end

function AbilityScoreIcon:SetAbbr(t)  self.abbr:SetText(t) end
function AbilityScoreIcon:SetScore(t) self.score:SetText(t) end
function AbilityScoreIcon:SetMod(t)   self.mod:SetText(t) end
function AbilityScoreIcon:SetIcon(t)  IconButton.SetIcon(self, t) end

return AbilityScoreIcon
