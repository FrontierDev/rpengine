-- RPE_UI/Widgets/PlayerReactionWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Widgets  = RPE_UI.Widgets or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local Window        = RPE_UI.Elements.Window
local HGroup        = RPE_UI.Elements.HorizontalLayoutGroup
local FrameElement  = RPE_UI.Elements.FrameElement
local IconBtn       = RPE_UI.Elements.IconButton
local Text          = RPE_UI.Elements.Text
local C             = RPE_UI.Colors

local Common        = RPE and RPE.Common

---@class PlayerReactionWidget
---@field root Window
---@field content HGroup
---@field reactionHost FrameElement
---@field buttons table<number, IconBtn>
---@field reactions table<number, table>
---@field chrome Frame
---@field unitPortrait UnitPortrait|nil
---@field acResultText Text|nil
---@field acInfoText Text|nil
---@field thresholdText Text|nil
local PlayerReactionWidget = {}
_G.RPE_UI.Widgets.PlayerReactionWidget = PlayerReactionWidget
PlayerReactionWidget.__index = PlayerReactionWidget
PlayerReactionWidget.Name = "PlayerReactionWidget"

local function FadeInFrame(frame, duration)
    if not frame then return end
    frame:SetAlpha(0)
    frame:Show()
    UIFrameFadeIn(frame, duration or 0.25, 0, 1)
end

local function clamp(x, a, b)
    if x < a then return a elseif x > b then return b else return x end
end

-- ============ Button Management ============
function PlayerReactionWidget:_EnsureButton(index)
    if self.buttons[index] and self.buttons[index].frame then
        return self.buttons[index]
    end
    local btn = IconBtn:New(("RPE_PlayerReaction_Button_%d"):format(index), {
        parent = self.reactionHost,
        width = 32,
        height = 32,
        hasBackground = false, noBackground = true,
        hasBorder = false, noBorder = true,
    })
    self.buttons[index] = btn
    return btn
end

-- ============ Outline (Team-colored border) ============
local function CreateSquareOutline(parentFrame, colorGetter)
    local width = 2

    local top = parentFrame:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -width, width)
    top:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", width, width)
    top:SetHeight(width)

    local bottom = parentFrame:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", -width, -width)
    bottom:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", width, -width)
    bottom:SetHeight(width)

    local left = parentFrame:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -width, width)
    left:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", -width, -width)
    left:SetWidth(width)

    local right = parentFrame:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", width, width)
    right:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", width, -width)
    right:SetWidth(width)

    local function apply(team)
        local r,g,b,a = colorGetter(team)
        top:SetColorTexture(r, g, b, a)
        bottom:SetColorTexture(r, g, b, a)
        left:SetColorTexture(r, g, b, a)
        right:SetColorTexture(r, g, b, a)
    end

    return { top = top, bottom = bottom, left = left, right = right, Apply = apply }
end

local FALLBACK_TEAM_COLORS = {
    [1] = { 0.35, 0.65, 1.00, 1.00 }, -- blue
    [2] = { 1.00, 0.40, 0.35, 1.00 }, -- red
    [3] = { 0.40, 0.90, 0.45, 1.00 }, -- green
    [4] = { 0.75, 0.55, 1.00, 1.00 }, -- purple
}

local function GetTeamColor(team)
    team = tonumber(team or 1) or 1
    if C and C.Get then
        local r,g,b,a = C.Get("team"..team)
        if r ~= nil then
            return r,g,b,a
        end
    end
    local fb = FALLBACK_TEAM_COLORS[team] or FALLBACK_TEAM_COLORS[1]
    return fb[1], fb[2], fb[3], fb[4]
end

-- ============ Chrome ============
function PlayerReactionWidget:_EnsureChrome()
    if self.chrome and self.chrome:IsObjectType("Frame") then return end
    local parent = self.root and self.root.frame or UIParent
    local f = CreateFrame("Frame", "RPE_PlayerReaction_Chrome", parent)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((parent:GetFrameLevel() or 0) + 1)
    self.chrome = f
end

-- ============ Layout ============
function PlayerReactionWidget:Layout()
    local visibleCount = self.visibleSlots or 0
    local size = self.slotSize
    local gap = self.spacing

    -- Calculate total width based on visible buttons only
    local totalW = visibleCount > 0 and (visibleCount * size + (visibleCount - 1) * gap) or 0
    local totalH = size

    local startX = -totalW / 2 + size / 2
    
    -- Only layout visible buttons, hide the rest
    for i = 1, self.numSlots do
        local btn = self.buttons[i]
        if btn and btn.frame then
            if i <= visibleCount then
                btn.frame:ClearAllPoints()
                btn.frame:SetPoint("CENTER", self.reactionHost.frame, "CENTER", startX + (i - 1) * (size + gap), 0)
                btn:Show()
            else
                btn:Hide()
            end
        end
    end

    self:_EnsureChrome()
    local padX, padY = self.padX, self.padY
    -- Keep chrome at fixed width based on max slots to prevent shifting
    local maxW = self.numSlots * size + (self.numSlots - 1) * gap
    self.chrome:ClearAllPoints()
    self.chrome:SetPoint("CENTER", self.reactionHost.frame, "CENTER", 0, 0)
    self.chrome:SetSize(maxW + padX * 2, totalH + padY * 2)
end

-- ============ Public API ============
function PlayerReactionWidget:BuildUI(opts)
    opts = opts or {}
    self.numSlots = tonumber(opts.numSlots) or 6
    self.slotSize = tonumber(opts.slotSize) or 32
    self.spacing = tonumber(opts.spacing) or 4
    self.padX = tonumber(opts.padX) or 12
    self.padY = tonumber(opts.padY) or 10

    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_PlayerReaction_Window", {
        parent = parentFrame,
        width = 1,
        height = 1,
        autoSize = true,
        noBackground = true,
        hasBackground = false,
        point = "BOTTOM",
        pointRelative = "BOTTOM",
        x = 0,
        y = 250,
    })

    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale()
            f:SetScale(UIParent and UIParent:GetScale() or 1)
        end
        local function UpdateMouseForUIVisibility()
            f:EnableMouse(UIParent and UIParent:IsShown())
        end
        SyncScale()
        UpdateMouseForUIVisibility()
        UIParent:HookScript("OnShow", function()
            SyncScale()
            UpdateMouseForUIVisibility()
        end)
        UIParent:HookScript("OnHide", function()
            UpdateMouseForUIVisibility()
        end)

        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    self.content = HGroup:New("RPE_PlayerReaction_Content", {
        parent = self.root,
        autoSize = true,
        spacingX = self.spacing,
        alignV = "CENTER",
    })
    self.root:Add(self.content)

    self.reactionHostFrame = CreateFrame("Frame", "RPE_PlayerReaction_Host", self.content.frame)
    self.reactionHostFrame:SetAllPoints(self.content.frame)
    self.reactionHost = FrameElement:New("PlayerReactionHost", self.reactionHostFrame, self.content)

    -- Reaction icon display (left side)
    local reactionIconFrame = CreateFrame("Frame", "RPE_PlayerReaction_IconDisplay", self.root.frame)
    reactionIconFrame:SetSize(64, 64)
    reactionIconFrame:SetPoint("RIGHT", self.reactionHost.frame, "LEFT", -10, 0)
    
    local reactionIcon = reactionIconFrame:CreateTexture(nil, "BACKGROUND")
    reactionIcon:SetAllPoints()
    reactionIcon:SetTexture("Interface\\AddOns\\RPEngine\\UI\\Textures\\reaction.png")
    reactionIcon:SetVertexColor(0.6, 0.6, 0.6, 1)
    
    -- Threshold text overlay using Text element
    local thresholdText = Text:New("RPE_PlayerReaction_ThresholdText", {
        parent = self.root,
        point = "CENTER",
        relativeTo = reactionIconFrame,
        relativePoint = "CENTER",
        fontTemplate = "GameFontNormalLargeOutline",
        color = {1, 1, 1, 1},
        justifyH = "CENTER",
        justifyV = "MIDDLE",
    })
    
    -- AC result text (for AC hit system) - PASS/FAIL using Text element
    local acResultText = Text:New("RPE_PlayerReaction_ACResult", {
        parent = self.reactionHost,
        point = "CENTER",
        relativeTo = self.reactionHost.frame,
        relativePoint = "CENTER",
        y = 8,
        fontTemplate = "GameFontNormalLarge",
        justifyH = "CENTER",
    })
    
    -- AC info text (AC value in muted color) using Text element
    local acInfoText = Text:New("RPE_PlayerReaction_ACInfo", {
        parent = self.reactionHost,
        point = "TOP",
        relativeTo = acResultText.frame,
        relativePoint = "BOTTOM",
        y = -2,
        fontTemplate = "GameFontNormalSmall",
        color = C.palette.textMuted,
        justifyH = "CENTER",
    })
    
    self.reactionIconFrame = reactionIconFrame
    self.reactionIcon = reactionIcon
    self.thresholdText = thresholdText
    self.acResultText = acResultText
    self.acInfoText = acInfoText

    self:_EnsureChrome()

    self.buttons = {}
    self.reactions = {}

    for i = 1, self.numSlots do
        local btn = self:_EnsureButton(i)
        btn.frame:ClearAllPoints()
    end

    self:Layout()
    
    for i = 1, self.numSlots do
        self.buttons[i]:SetIcon(132269)
        if self.buttons[i].frame and self.buttons[i].frame.texture then
            self.buttons[i].frame.texture:SetVertexColor(0.6, 0.6, 0.6, 1)
        end
        self.buttons[i]:Show()
    end
    
    FadeInFrame(self.chrome, 0.25)
    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        -- RPE_UI.Common:RegisterWindow(self)
    end
end

function PlayerReactionWidget:ShowReactions(reactions)
    if not self.root then
        self:BuildUI()
    end

    -- Store the attack reaction 
    self.attackReaction = reactions

    -- Check if AC hit system (automatic, no player choice)
    if reactions and reactions.hitSystem == "ac" then
        -- Get player's AC stat
        local playerAC = 10  -- Default AC
        local Stats = RPE and RPE.Stats
        if Stats and Stats.GetValue then
            playerAC = Stats:GetValue("AC") or 10
        end
        
        -- For AC system, show PASS or FAIL based on hit result
        local isHit = reactions.attackRoll and (reactions.attackRoll >= playerAC)
        local resultText = isHit and "FAIL" or "PASS"
        local resultColor = isHit and C.palette.textMalus or C.palette.textBonus
        
        -- Hide all buttons
        for i = 1, self.numSlots do
            if self.buttons[i] then
                self.buttons[i]:Hide()
            end
        end
        
        -- Show AC result text (PASS/FAIL in color)
        self.acResultText:SetText(resultText)
        self.acResultText:SetColor(resultColor[1], resultColor[2], resultColor[3], resultColor[4])
        self.acResultText.frame:Show()
        
        -- Show AC info text (AC value in muted color)
        local acText = string.format("(AC %d)", playerAC)
        self.acInfoText:SetText(acText)
        self.acInfoText:SetColor(C.palette.textMuted[1], C.palette.textMuted[2], C.palette.textMuted[3], C.palette.textMuted[4])
        self.acInfoText.frame:Show()
        
        -- Update threshold display
        if reactions.attackRoll then
            self.thresholdText:SetText(tostring(reactions.attackRoll))
        end
        
        -- Update attacker portrait
        if reactions and reactions.caster then
            local attackerUnit = RPE.Common:FindUnitById(reactions.caster)
            if attackerUnit then
                if not self.unitPortrait then
                    local UnitPortrait = RPE_UI.Prefabs and RPE_UI.Prefabs.UnitPortrait
                    if UnitPortrait then
                        self.unitPortrait = UnitPortrait:New("RPE_PlayerReaction_AttackerPortrait", {
                            parent = self.root,
                            size = 50,
                            unit = attackerUnit,
                            noBackground = false,
                        })
                        self.unitPortrait.frame:SetPoint("LEFT", self.reactionHost.frame, "RIGHT", 20, -12)
                    end
                else
                    self.unitPortrait:SetUnit(attackerUnit)
                end
                if self.unitPortrait and self.unitPortrait.hp then
                    self.unitPortrait.hp:Hide()
                end
            end
        end
        
        self.visibleSlots = 0
        self:Layout()
        self.root:Show()
        if self.chrome then
            FadeInFrame(self.chrome, 0.2)
        end
        
        -- Auto-close after 1.5 seconds
        if self._acCloseTimer then
            self._acCloseTimer:Cancel()
        end
        self._acCloseTimer = C_Timer.After(3.0, function()
            local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
            if PlayerReaction and PlayerReaction.Complete then
                -- For AC mode: pass (isHit, playerAC, attackRoll, playerAC)
                -- isHit is whether the attack hits (attackRoll >= AC)
                -- The "roll" parameter should be the player's AC (their defense value)
                -- lhs should be attackRoll, rhs should be playerAC
                PlayerReaction:Complete(isHit, playerAC, reactions.attackRoll, playerAC)
            end
            self._acCloseTimer = nil
        end)
        return
    end

    -- Generate defense options based on hitSystem and available threshold stats
    local defenseOptions = {}
    
    -- Hide AC result text for non-AC cases
    if self.acResultText then
        self.acResultText.frame:Hide()
    end
    if self.acInfoText then
        self.acInfoText.frame:Hide()
    end
    
    if reactions and reactions.hitSystem then
        if reactions.hitSystem == "simple" then
            -- Simple: always show Dodge (DEFENCE) option
            local icon = 132092  -- Default icon
            local Stats = RPE and RPE.Stats
            if Stats and Stats.Get then
                local stat = Stats:Get("DEFENCE")
                if stat and stat.icon then
                    icon = stat.icon
                end
            end
            table.insert(defenseOptions, {
                icon = icon,
                defenseType = "simple",
                label = "Defence",
                handler = function() self:_handleSimpleDefense(reactions) end,
            })
        elseif reactions.hitSystem == "complex" then
            -- Complex: show defense options for each threshold stat sent by spell
            local thresholdStats = reactions.thresholdStats or {}
            
            for _, statId in ipairs(thresholdStats) do
                -- Get icon from stat definition if available
                local icon = 132093  -- Default icon
                local Stats = RPE and RPE.Stats
                if Stats and Stats.Get then
                    local stat = Stats:Get(statId)
                    if stat and stat.icon then
                        icon = stat.icon
                    end
                end
                
                table.insert(defenseOptions, {
                    icon = icon,
                    defenseType = "complex",
                    label = statId,  -- Use the stat ID as label
                    statId = statId,
                    handler = function() self:_handleComplexDefense(reactions, statId) end,
                })
            end
        end
        
        -- Pass defense (always available for simple and complex)
        if reactions.hitSystem == "simple" or reactions.hitSystem == "complex" then
            table.insert(defenseOptions, {
                icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\cancel.png",  -- Pass icon
                defenseType = "pass",
                label = "Pass",
                handler = function() self:_handlePassDefense(reactions) end,
            })
        end
    end

    -- Hide all buttons first
    for i = 1, self.numSlots do
        if self.buttons[i] then
            self.buttons[i]:Hide()
        end
    end

    -- Show only the defense options we have
    for i, defense in ipairs(defenseOptions) do
        if i <= self.numSlots then
            local btn = self:_EnsureButton(i)
            btn:SetOnClick(function()
                if defense.handler then
                    defense.handler()
                end
            end)
            btn:SetIcon(defense.icon)
            btn:SetColor(0.6, 0.6, 0.6, 1.00)
            
            -- Apply color tint to Pass button
            if defense.defenseType == "pass" then
                btn:SetColor(0.95, 0.55, 0.55, 1.00)
            end
            
            -- Add tooltip
            btn.frame:HookScript("OnEnter", function(frame)
                local spec = { title = "", lines = {} }
                
                -- Title: Action name
                if defense.defenseType == "pass" then
                    spec.title = "Pass"
                else
                    spec.title = defense.label or "Defense"
                end
                
                -- Modifier line: show the player's stat modifier for this defense
                if defense.statId then
                    local Stats = RPE and RPE.Stats
                    if Stats and Stats.GetValue then
                        local modValue = Stats:GetValue(defense.statId) or 0
                        table.insert(spec.lines, {
                            left = "Your Modifier:",
                            right = string.format("%+d", modValue),
                            r = 0.9, g = 0.9, b = 0.9
                        })
                    end
                elseif defense.defenseType == "simple" then
                    local Stats = RPE and RPE.Stats
                    if Stats and Stats.GetValue then
                        local modValue = Stats:GetValue("DEFENCE") or 0
                        table.insert(spec.lines, {
                            left = "Your Modifier:",
                            right = string.format("%+d", modValue),
                            r = 0.9, g = 0.9, b = 0.9
                        })
                    end
                end
                
                -- On Fail line: show damage on fail (separate row per damage type)
                if reactions and reactions.predictedDamage then
                    -- Show full damage breakdown by school if available
                    if reactions.damageBySchool then
                        for school, amount in pairs(reactions.damageBySchool) do
                            if tonumber(amount) and tonumber(amount) > 0 then
                                table.insert(spec.lines, {
                                    left = "On Fail:",
                                    right = string.format("Takes %d %s damage", math.floor(tonumber(amount)), school),
                                    r = 1, g = 0.3, b = 0.3
                                })
                            end
                        end
                    else
                        -- Fallback to single school display if breakdown not available
                        local damageAmount = reactions.predictedDamage or 0
                        local school = reactions.damageSchool or "Physical"
                        table.insert(spec.lines, {
                            left = "On Fail:",
                            right = string.format("Takes %d %s damage", damageAmount, school),
                            r = 1, g = 0.3, b = 0.3
                        })
                    end
                end
                
                if Common and Common.ShowTooltip then
                    Common:ShowTooltip(frame, spec)
                end
            end)
            
            btn.frame:HookScript("OnLeave", function()
                if Common and Common.HideTooltip then
                    Common:HideTooltip()
                end
            end)
            
            btn:Show()
        end
    end
    
    -- Track visible slots for layout
    self.visibleSlots = #defenseOptions
    
    -- Update threshold display
    if reactions and reactions.attackRoll then
        self.thresholdText:SetText(tostring(reactions.attackRoll))
    else
        self.thresholdText:SetText("")
    end
    
    -- Update attacker portrait
    if reactions and reactions.caster then
        -- Get attacker unit info
        local attackerUnit = RPE.Common:FindUnitById(reactions.caster)
        if attackerUnit then
            -- Create portrait if not already created
            if not self.unitPortrait then
                local UnitPortrait = RPE_UI.Prefabs and RPE_UI.Prefabs.UnitPortrait
                if UnitPortrait then
                    self.unitPortrait = UnitPortrait:New("RPE_PlayerReaction_AttackerPortrait", {
                        parent = self.root,
                        size = 50,
                        unit = attackerUnit,
                        noBackground = false,
                    })
                    -- Position the portrait to the right of the buttons (10px lower)
                    self.unitPortrait.frame:SetPoint("LEFT", self.reactionHost.frame, "RIGHT", 20, -12)
                end
            else
                -- Update existing portrait with actual unit
                self.unitPortrait:SetUnit(attackerUnit)
            end
            
            -- Hide the health bar
            if self.unitPortrait and self.unitPortrait.hp then
                self.unitPortrait.hp:Hide()
            end
        end
    end

    -- Recalculate layout to fit only visible buttons
    self:Layout()
    
    self.root:Show()
    if self.chrome then
        FadeInFrame(self.chrome, 0.2)
    end
end

function PlayerReactionWidget:HideReactions()
    -- Cancel any pending AC close timer
    if self._acCloseTimer then
        self._acCloseTimer:Cancel()
        self._acCloseTimer = nil
    end
    
    if self.root then
        self.root:Hide()
    end
    for i = 1, self.numSlots do
        if self.buttons[i] then
            self.buttons[i]:Hide()
        end
    end
    self.reactions = {}
    
    -- Destroy the widget completely so it's recreated fresh next time
    if self.root and self.root.frame then
        self.root.frame:SetParent(nil)
        self.root.frame:ClearAllPoints()
    end
    self.root = nil
    self.unitPortrait = nil
    self.buttons = {}
end

-- ============ Defense Handlers ============
function PlayerReactionWidget:_handleSimpleDefense(reaction)
    local defenceStat = RPE.Stats and RPE.Stats:GetValue("DEFENCE") or 0
    local roll = Common and Common:Roll("1d20") or math.random(1, 20)
    local lhs = roll + defenceStat
    local hitResult = false

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Complete then
        PlayerReaction:Complete(hitResult, roll, lhs, 0)
    end
end

function PlayerReactionWidget:_handleComplexDefense(reaction, statId)
    local defenseStat = RPE.Stats and RPE.Stats:GetValue(statId) or 0
    local roll = Common and Common:Roll("1d20") or math.random(1, 20)
    local lhs = roll + defenseStat
    local hitResult = false

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Complete then
        PlayerReaction:Complete(hitResult, roll, lhs, 0)
    end
end

function PlayerReactionWidget:_handlePassDefense(reaction)
    local hitResult = false
    local roll = 0
    local lhs = 0

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Complete then
        PlayerReaction:Complete(hitResult, roll, lhs, 0)
    end
end

-- ============ Singleton ============
function PlayerReactionWidget.New(opts)
    local self = setmetatable({}, PlayerReactionWidget)
    self:BuildUI(opts or {})
    return self
end

local _instance = nil

function PlayerReactionWidget:GetInstance()
    if not _instance then
        _instance = PlayerReactionWidget.New()
    end
    return _instance
end

function PlayerReactionWidget:Open(reactions)
    local instance = self:GetInstance()
    if instance then
        instance:ShowReactions(reactions)
    end
    return instance
end

function PlayerReactionWidget:Close()
    local instance = self:GetInstance()
    return instance:HideReactions()
end

return PlayerReactionWidget
