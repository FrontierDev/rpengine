-- RPE_UI/Windows/InteractionWidget.lua
-- Displays icon buttons for interaction options available on the target NPC.

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window   = RPE_UI.Elements.Window
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local IconBtn  = RPE_UI.Elements.IconButton
local C        = RPE_UI.Colors

local Executor = RPE.Core and RPE.Core.InteractionExecutor

---@class InteractionWidget
---@field root Window
---@field nameText Text
---@field titleText Text
---@field buttonGroup HGroup
---@field buttons IconButton[]
local InteractionWidget = {}
_G.RPE_UI.Windows.InteractionWidget = InteractionWidget
InteractionWidget.__index = InteractionWidget
InteractionWidget.Name = "InteractionWidget"

local ACTION_ICONS = {
    DIALOGUE = "Interface\\AddOns\\RPEngine\\UI\\Textures\\talk.png",
    SHOP     = "Interface\\AddOns\\RPEngine\\UI\\Textures\\shop.png",
    TRAIN    = "Interface\\AddOns\\RPEngine\\UI\\Textures\\train.png",
    AUCTION  = "Interface\\AddOns\\RPEngine\\UI\\Textures\\auction.png",
    SKIN     = "Interface\\AddOns\\RPEngine\\UI\\Textures\\skin.png",
    SALVAGE  = "Interface\\AddOns\\RPEngine\\UI\\Textures\\salvage.png",
    RAISE    = "Interface\\AddOns\\RPEngine\\UI\\Textures\\raise-dead.png",
}

-- ============================================================
-- Helpers
-- ============================================================

local function FadeInFrame(frame, duration)
    if not frame then return end
    frame:SetAlpha(0)
    frame:Show()
    UIFrameFadeIn(frame, duration or 0.25, 0, 1)
end

local function FadeOutFrame(frame, duration)
    if not frame then return end
    UIFrameFadeOut(frame, duration or 0.25, 1, 0)
    C_Timer.After(duration or 0.25, function()
        if frame and frame.Hide then frame:Hide() end
    end)
end

local function defaultIconForAction(action)
    if not action then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local key = tostring(action):upper()

    for k, path in pairs(ACTION_ICONS) do
        if key:find(k) then return path end
    end

    -- fallback generic icon
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end


-- ============================================================
-- UI Setup
-- ============================================================

function InteractionWidget:BuildUI(opts)
    opts = opts or {}
    self.name = "InteractionWidget"
    self.buttons = {}

    -- Root window
    self.root = Window:New("RPE_InteractionWidget_Window", {
        parent = UIParent,
        width = 1, height = 1,
        point = opts.point or "BOTTOM",
        pointRelative = opts.rel or "BOTTOM",
        x = opts.x or 0,
        y = opts.y or 220,
        autoSize = true,
        noBackground = true,
    })

    local f = self.root.frame
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(20)
    f:SetClampedToScreen(true)

    -- Vertical stack container (Name, Title, Buttons)
    self.stack = VGroup:New("RPE_InteractionWidget_Stack", {
        parent = self.root,
        autoSize = true,
        alignH = "CENTER",
        alignV = "TOP",
        spacingY = 4,
    })

    -- NPC Name
    self.nameText = Text:New("RPE_InteractionWidget_Name", {
        parent = self.stack,
        text = "",
        fontTemplate = "GameFontHighlightLarge",
        justifyH = "CENTER",
        width = 400,
        height = 24,
    })
    C.ApplyText(self.nameText.text, "text")

    -- NPC Title (muted color)
    self.titleText = Text:New("RPE_InteractionWidget_Title", {
        parent = self.stack,
        text = "",
        fontTemplate = "GameFontHighlightSmall",
        justifyH = "CENTER",
        width = 400,
        height = 18,
    })
    C.ApplyText(self.titleText.text, "textMuted")

    -- Horizontal group for icon buttons
    self.buttonGroup = HGroup:New("RPE_InteractionWidget_Buttons", {
        parent   = self.stack,
        autoSize = true,
        spacingX = 10,
        alignV   = "CENTER",
        alignH   = "CENTER",
        padding  = { left = 0, right = 0, top = 2, bottom = 0 },
    })

    self.root:Hide()

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
end

-- ============================================================
-- Behaviour
-- ============================================================

function InteractionWidget:ShowInteractions(interactions, npcName, npcTitle)
    if not (interactions and #interactions > 0) then
        self:Hide()
        return
    end

    -- Update NPC name + title
    if self.nameText then self.nameText:SetText(npcName or "") end
    if self.titleText then self.titleText:SetText(npcTitle or "") end

    -- Clear old buttons
    for _, btn in ipairs(self.buttons) do
        btn.frame:Hide()
        btn.frame:SetParent(nil)
    end
    self.buttons = {}

    -- Get NPC info once
    local guid = UnitGUID("target") or ""
    local npcId = guid:match("-(%d+)-%x+$") or ""
    local mapID = C_Map and C_Map.GetBestMapForUnit("player") or 0
    local creatureType = UnitCreatureType("target") or "(unknown)"
    local info = {
        id = npcId,
        title = npcTitle,
        name = npcName,
        creatureType = creatureType,
        mapID = mapID,
        guid = guid,
    }

    -- Flatten all options
    local allOpts = {}
    for _, inter in ipairs(interactions) do
        for _, opt in ipairs(inter.options or {}) do
            table.insert(allOpts, opt)
        end
    end

    -- Create icon buttons
    for i, opt in ipairs(allOpts) do
        local tex = opt.icon or defaultIconForAction(opt.action)
        local btn = IconBtn:New(("RPE_InteractionWidget_Button_%d"):format(i), {
            parent = self.buttonGroup,
            width  = 24,
            height = 24,
            icon   = tex,
            hasBackground = false, noBackground = true,
            hasBorder = false, noBorder = true,
            onClick = function()
                if Executor and Executor.Run then
                    Executor.Run(opt, "target")
                end
                self:Hide()
            end,
        })

        -- Tooltip
        local label = tostring(opt.label or "Interact")
        btn.frame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn.frame, "ANCHOR_TOP")
            GameTooltip:SetText(label, 1, 1, 1)
            if opt.description then
               GameTooltip:AddLine(opt.description, 0.8, 0.8, 0.8, true)
            end
            GameTooltip:Show()
        end)
        btn.frame:SetScript("OnLeave", GameTooltip_Hide)

        self.buttonGroup:Add(btn)
        table.insert(self.buttons, btn)
    end

    -- Center the stack on screen
    self.root.frame:ClearAllPoints()
    self.root.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)

    FadeInFrame(self.root.frame, 0.25)
    self.root:Show()
end


function InteractionWidget:Hide()
    if not self.root or not self.root.frame then return end
    FadeOutFrame(self.root.frame, 0.25)
end

function InteractionWidget:Clear()
    for _, btn in ipairs(self.buttons) do
        btn.frame:Hide()
        btn.frame:SetParent(nil)
    end
    self.buttons = {}
end

-- ============================================================
-- Constructor
-- ============================================================

function InteractionWidget.New(opts)
    local self = setmetatable({}, InteractionWidget)
    self:BuildUI(opts or {})
    return self
end

return InteractionWidget
