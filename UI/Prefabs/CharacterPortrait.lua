-- RPE_UI/Prefabs/CharacterPortrait.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local Panel = RPE_UI.Elements.Panel
local Text  = RPE_UI.Elements.Text
local C     = RPE_UI.Colors

---@class CharacterPortrait: Panel
---@field portrait Texture
---@field name Text
---@field subtitle Text
---@field highlight Texture
local CharacterPortrait = setmetatable({}, { __index = Panel })
CharacterPortrait.__index = CharacterPortrait
RPE_UI.Prefabs.CharacterPortrait = CharacterPortrait

function CharacterPortrait:New(name, opts)
    opts = opts or {}
    opts.width  = opts.width  or 64
    opts.height = opts.height or 64

    ---@type CharacterPortrait
    local o = Panel.New(self, name, opts)

    -- Portrait texture
    o.portrait = o.frame:CreateTexture(nil, "ARTWORK")
    o.portrait:SetAllPoints(o.frame)
    o.portrait:SetTexCoord(0.00, 1.00, 0.00, 1.00)
    SetPortraitTexture(o.portrait, opts.unit or "player")

    -- Event listener to refresh portrait
    local f = CreateFrame("Frame", nil, o.frame)
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD" or unit == (opts.unit or "player") then
            SetPortraitTexture(o.portrait, opts.unit or "player")
        end
    end)

    -- Hover highlight overlay
    local hl = o.frame:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    C.ApplyHighlight(hl)       -- use palette highlight color
    hl:SetAlpha(0.25)
    hl:Hide()
    o.highlight = hl

    -- Make interactive
    o.frame:EnableMouse(true)
    o.frame:SetScript("OnEnter", function()
        o.highlight:Show()
    end)
    o.frame:SetScript("OnLeave", function()
        o.highlight:Hide()
    end)

    o.frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            local mainWin = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.MainWindow
            if mainWin and mainWin.Show then
                RPE_UI.Common:Toggle(mainWin)
            end
        end
    end)

    return o
end

function CharacterPortrait:UpdatePortrait(unit)
    SetPortraitTexture(self.portrait, unit or "player")
end

return CharacterPortrait
