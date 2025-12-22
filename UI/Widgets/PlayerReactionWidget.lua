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
local Advantage     = RPE and RPE.Core and RPE.Core.Advantage
local Formula       = RPE and RPE.Core and RPE.Core.Formula
local StatRegistry  = RPE and RPE.Core and RPE.Core.StatRegistry
local ActiveRules   = RPE and RPE.ActiveRules
local Broadcast     = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast

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

-- ============ Immunity Check ============
local function _checkDamageSchoolImmunity(damageSchool)
    -- Get player's unit and aura manager
    local ev = RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local playerId = ev:GetLocalPlayerUnitId()
    if not playerId then return false end
    
    -- Get all auras on the player
    local auras = ev._auraManager:All(playerId)
    if not auras or #auras == 0 then return false end
    
    -- Normalize damage school to lowercase for case-insensitive comparison
    local normalizedSchool = damageSchool and damageSchool:lower() or ""
    if normalizedSchool == "" then return false end
    
    -- Check each aura for immunity to this damage school
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.immunity and aura.def.immunity.damageSchools then
            local schools = aura.def.immunity.damageSchools
            if type(schools) == "table" then
                for _, school in ipairs(schools) do
                    if school and school:lower() == normalizedSchool then
                        return true  -- Found immunity to this damage school
                    end
                end
            end
        end
    end
    
    return false
end

-- ============ Get All Immune Schools ============
local function _getImmuneSchools()
    -- Get player's unit and aura manager
    local ev = RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return {} end
    
    local playerId = ev:GetLocalPlayerUnitId()
    if not playerId then return {} end
    
    -- Get all auras on the player
    local auras = ev._auraManager:All(playerId)
    if not auras or #auras == 0 then return {} end
    
    -- Collect all immune damage schools
    local immuneSchools = {}
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.immunity and aura.def.immunity.damageSchools then
            local schools = aura.def.immunity.damageSchools
            if type(schools) == "table" then
                for _, school in ipairs(schools) do
                    if school then
                        immuneSchools[school:lower()] = school  -- Store original case
                    end
                end
            end
        end
    end
    
    return immuneSchools
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
    self._helpUsedThisTurn = false

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

    -- Mark player as engaged when defending
    local playerUnit = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() and RPE.Common and RPE.Common:FindUnitById(RPE.Core.ActiveEvent:GetLocalPlayerUnitId())
    if playerUnit then
        -- Reset combat counter to keep player engaged
        if type(playerUnit.ResetCombat) == "function" then
            playerUnit:ResetCombat()
        end
        -- Update engagement state
        if type(playerUnit.SetEngaged) == "function" then
            playerUnit:SetEngaged(true)
        end
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
            -- Log the AC defense outcome
            local defenderName = UnitName("player") or "You"
            local school = reactions.damageSchool or "Physical"
            local attackerName = "Attacker"
            if reactions and reactions.caster then
                local attacker = RPE.Common and RPE.Common:FindUnitById(reactions.caster)
                if attacker then
                    attackerName = (RPE.Common and RPE.Common:FormatUnitName(attacker)) or ("Unit " .. tostring(reactions.caster))
                end
            end
            if Broadcast and Broadcast.SendCombatMessage then
                local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() or 0
                Broadcast:SendCombatMessage(playerId, defenderName, ("%s deals %d %s damage to %s."):format(attackerName, reactions.predictedDamage, school, defenderName))
            end

            local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
            if PlayerReaction and PlayerReaction.Complete then
                -- Store the chosen defense stat in currentReaction before completing
                local currentReaction = PlayerReaction:GetCurrent()
                if currentReaction then
                    currentReaction.chosenDefenseStat = "AC"
                end
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
            local statName = "Defence"  -- Default name
            if StatRegistry then
                local stat = StatRegistry:Get("DEFENCE")
                if stat then
                    if stat.icon then
                        icon = stat.icon
                    end
                    -- Priority: defenceName > name > default
                    if stat.defenceName and stat.defenceName ~= "" then
                        statName = stat.defenceName
                    elseif stat.name then
                        statName = stat.name
                    end
                end
            end
            table.insert(defenseOptions, {
                icon = icon,
                defenseType = "simple",
                label = statName,
                handler = function() self:_handleSimpleDefense(reactions) end,
            })
        elseif reactions.hitSystem == "complex" then
            -- Complex: show defense options for each threshold stat sent by spell
            local thresholdStats = reactions.thresholdStats or {}
            local Stats = RPE and RPE.Stats
            
            for _, statId in ipairs(thresholdStats) do
                -- Prevent DEFENCE and AC stats from being used in complex defense rolls
                if statId == "DEFENCE" or statId == "AC" then
                    if RPE and RPE.Debug and RPE.Debug.Internal then
                        RPE.Debug:Internal(("PlayerReactionWidget - Threshold stat '%s' is a simple system stat, skipping"):format(tostring(statId)))
                    end
                -- Check if this defense stat is prevented by crowd control
                elseif RPE and RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent._auraManager then
                    local playerId = RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
                    if playerId and RPE.Core.ActiveEvent._auraManager:IsDefenceStatFailing(playerId, statId) then
                        if RPE and RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal(("PlayerReactionWidget - Defense stat '%s' is prevented by crowd control, skipping"):format(tostring(statId)))
                        end
                    -- Validate stat exists before adding defense option
                    elseif not (Stats and Stats.Get and Stats:Get(statId)) then
                        if RPE and RPE.Debug and RPE.Debug.Warning then
                            RPE.Debug:Internal(("PlayerReactionWidget - Threshold stat '%s' not found, skipping"):format(tostring(statId)))
                        end
                    else
                        -- Get icon and name from stat definition if available
                        local icon = 132093  -- Default icon
                        local statName = statId  -- Fallback to ID
                        if StatRegistry then
                            local stat = StatRegistry:Get(statId)
                            if stat then
                                if stat.icon then
                                    icon = stat.icon
                                end
                                -- Priority: defenceName > name > ID
                                if stat.defenceName and stat.defenceName ~= "" then
                                    statName = stat.defenceName
                                elseif stat.name then
                                    statName = stat.name
                                end
                            end
                        end
                        
                        table.insert(defenseOptions, {
                            icon = icon,
                            defenseType = "complex",
                            label = statName,  -- Use the stat name, not ID
                            statId = statId,
                            handler = function() self:_handleComplexDefense(reactions, statId) end,
                        })
                    end
                -- Validate stat exists before adding defense option
                elseif not (Stats and Stats.Get and Stats:Get(statId)) then
                    if RPE and RPE.Debug and RPE.Debug.Warning then
                        RPE.Debug:Internal(("PlayerReactionWidget - Threshold stat '%s' not found, skipping"):format(tostring(statId)))
                    end
                else
                    -- Get icon and name from stat definition if available
                    local icon = 132093  -- Default icon
                    local statName = statId  -- Fallback to ID
                    if StatRegistry then
                        local stat = StatRegistry:Get(statId)
                        if stat then
                            if stat.icon then
                                icon = stat.icon
                            end
                            -- Priority: defenceName > name > ID
                            if stat.defenceName and stat.defenceName ~= "" then
                                statName = stat.defenceName
                            elseif stat.name then
                                statName = stat.name
                            end
                        end
                    end
                    
                    table.insert(defenseOptions, {
                        icon = icon,
                        defenseType = "complex",
                        label = statName,  -- Use the stat name, not ID
                        statId = statId,
                        handler = function() self:_handleComplexDefense(reactions, statId) end,
                    })
                end
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
        
        -- Help button (available if not already used this turn)
        if not self._helpUsedThisTurn then
            table.insert(defenseOptions, {
                icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\help.png",  -- Help icon
                defenseType = "help",
                label = "Help",
                handler = function() self:_handleHelp() end,
                buttonIndex = nil,  -- Will be set when button is created
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
            defense.buttonIndex = i  -- Store the button index for reference in tooltip
            btn:SetOnClick(function()
                if defense.handler then
                    defense.handler()
                end
                -- Lock help button after it's clicked (disables click, hover, and desaturates)
                if defense.defenseType == "help" and btn then
                    btn:Lock()
                else
                    -- End help call if any other defense button is pressed
                    local Broadcast = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if Broadcast and Broadcast.CallHelpEnd and RPE.Core._helpCalledThisTurn then
                        local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() or 0
                        Broadcast:CallHelpEnd(playerId)
                    end
                end
            end)
            btn:SetIcon(defense.icon)
            btn:SetColor(0.6, 0.6, 0.6, 1.00)
            
            -- Apply color tint to Pass button
            if defense.defenseType == "pass" then
                btn:SetColor(0.95, 0.55, 0.55, 1.00)
            -- Apply color tint to Help button
            elseif defense.defenseType == "help" then
                btn:SetColor(0.55, 0.75, 0.95, 1.00)
            end
            
            -- Add tooltip
            btn.frame:HookScript("OnEnter", function(frame)
                local spec = { title = "", lines = {}, width = 350 }  -- Wider tooltip for immersion mode

                -- Title: Action name
                if defense.defenseType == "pass" then
                    spec.title = "Pass"
                elseif defense.defenseType == "help" then
                    spec.title = "Help"
                else
                    spec.title = defense.label or "Defense"
                end

                -- Help button has simplified tooltip with just damage info
                if defense.defenseType == "help" then
                    -- Check if help button has been used (if it's locked)
                    if defense.buttonIndex and self.buttons[defense.buttonIndex] and self.buttons[defense.buttonIndex]._locked then
                        table.insert(spec.lines, {
                            left = "You cannot call for help again this turn.",
                            right = "",
                            r = 0.95, g = 0.5, b = 0.5
                        })
                    else
                        table.insert(spec.lines, {
                            left = "Request assistance from allies",
                            right = "",
                            r = 0.9, g = 0.9, b = 0.9
                        })
                        
                        -- Show expected damage if available
                        if reactions and reactions.damages and next(reactions.damages) then
                            table.insert(spec.lines, { left = "", right = "", r = 0, g = 0, b = 0 })  -- Blank line for spacing
                            table.insert(spec.lines, {
                                left = "Expected Damage Taken:",
                                right = "",
                                r = 0.7, g = 0.9, b = 0.7
                            })
                            
                            local totalDamage = 0
                            for school, amount in pairs(reactions.damages) do
                                totalDamage = totalDamage + amount
                                table.insert(spec.lines, {
                                    left = "  " .. school .. ":",
                                    right = tostring(amount),
                                    r = 0.9, g = 0.9, b = 0.9
                                })
                            end
                            
                            table.insert(spec.lines, {
                                left = "  Total:",
                                right = tostring(totalDamage),
                                r = 0.95, g = 0.5, b = 0.5
                            })
                        end
                    end
                else
                    -- Defense button tooltip (original logic)
                    
                -- Get immune schools to display and filter damage
                local immuneSchools = _getImmuneSchools()
                
                -- Show immunity info if player has immunities
                if immuneSchools and next(immuneSchools) then
                    local immuneList = {}
                    for _, school in pairs(immuneSchools) do
                        table.insert(immuneList, school)
                    end
                    table.sort(immuneList)
                    local immuneText = table.concat(immuneList, ", ")
                    local immuneColor = C and C.palette and C.palette.textModified or {0.55, 0.75, 0.95, 1.00}
                    table.insert(spec.lines, {
                        left = "You are immune to " .. immuneText,
                        right = "",
                        r = immuneColor[1], g = immuneColor[2], b = immuneColor[3]
                    })
                    table.insert(spec.lines, { left = "", right = "", r = 0, g = 0, b = 0 })  -- Blank line for spacing
                end

                -- Modifier line: show the player's stat modifier for this defense
                if defense.statId then
                    local Stats = RPE and RPE.Stats
                    if Stats and Stats.GetValue then
                        local modValue = Stats:GetValue(defense.statId) or 0
                        local statDef = StatRegistry and StatRegistry:Get(defense.statId)
                        -- Use defenceName if available, otherwise use stat name, otherwise fall back to ID
                        local statName = (statDef and statDef.defenceName and statDef.defenceName ~= "") and statDef.defenceName 
                                      or (statDef and statDef.name) or defense.statId
                        
                        -- Use textMalus for negative, textBonus for positive
                        local color = modValue >= 0 and (C.palette and C.palette.textBonus) or (C.palette and C.palette.textMalus)
                        if not color then
                            color = {0.9, 0.9, 0.9, 1}
                        end
                        
                        table.insert(spec.lines, {
                            left = statName .. " Modifier:",
                            right = string.format("%+d", modValue),
                            r = color[1], g = color[2], b = color[3]
                        })

                        -- Show absorption from shields (check player's actual absorption)
                        local playerUnitId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
                        local playerUnit = nil
                        if playerUnitId and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent.units then
                            -- Find the unit with matching ID
                            for _, u in pairs(RPE.Core.ActiveEvent.units) do
                                if u.id == playerUnitId then
                                    playerUnit = u
                                    break
                                end
                            end
                        end
                        if playerUnit and playerUnit.absorption then
                            local totalAbsorption = 0
                            for shieldId, shield in pairs(playerUnit.absorption) do
                                if shield.amount then
                                    totalAbsorption = totalAbsorption + shield.amount
                                end
                            end
                            if totalAbsorption > 0 then
                                local absorbColor = C and C.palette and C.palette.textBonus or {0.9, 0.9, 0.9, 1}
                                table.insert(spec.lines, {
                                    left = "Shields Absorb:",
                                    right = string.format("%d damage", totalAbsorption),
                                    r = absorbColor[1], g = absorbColor[2], b = absorbColor[3]
                                })
                            end
                        end

                        -- Show advantage/disadvantage level if present
                        local Advantage = RPE and RPE.Core and RPE.Core.Advantage
                        if Advantage then
                            local advLevel = Advantage:Get(defense.statId)
                            if advLevel > 0 then
                                local advColor = C and C.palette and C.palette.textBonus or {0.55, 0.95, 0.65, 1.00}
                                table.insert(spec.lines, {
                                    left = "Advantage:",
                                    right = string.format("x%d", advLevel),
                                    r = advColor[1], g = advColor[2], b = advColor[3]
                                })
                            elseif advLevel < 0 then
                                local disColor = C and C.palette and C.palette.textMalus or {0.95, 0.55, 0.55, 1.00}
                                table.insert(spec.lines, {
                                    left = "Disadvantage:",
                                    right = string.format("x%d", math.abs(advLevel)),
                                    r = disColor[1], g = disColor[2], b = disColor[3]
                                })
                            end

                            table.insert(spec.lines, { left = "", right = "", r = 0, g = 0, b = 0 })  -- Blank line for spacing
                        end
                    end
                elseif defense.defenseType == "simple" then
                    local Stats = RPE and RPE.Stats
                    if Stats and Stats.GetValue then
                        local modValue = Stats:GetValue("DEFENCE") or 0
                        local statDef = StatRegistry and StatRegistry:Get("DEFENCE")
                        -- Use defenceName if available, otherwise use stat name, otherwise fall back to "Defence"
                        local statName = (statDef and statDef.defenceName and statDef.defenceName ~= "") and statDef.defenceName 
                                      or (statDef and statDef.name) or "Defence"
                        
                        -- Use textMalus for negative, textBonus for positive
                        local color = modValue >= 0 and (C.palette and C.palette.textBonus) or (C.palette and C.palette.textMalus)
                        if not color then
                            color = {0.9, 0.9, 0.9, 1}
                        end
                        
                        table.insert(spec.lines, {
                            left = statName .. " Modifier:",
                            right = string.format("%+d", modValue),
                            r = color[1], g = color[2], b = color[3]
                        })

                        -- Show absorption from shields (check player's actual absorption)
                        local playerUnitId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
                        local playerUnit = nil
                        if playerUnitId and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent.units then
                            -- Find the unit with matching ID
                            for _, u in pairs(RPE.Core.ActiveEvent.units) do
                                if u.id == playerUnitId then
                                    playerUnit = u
                                    break
                                end
                            end
                        end
                        if playerUnit and playerUnit.absorption then
                            local totalAbsorption = 0
                            for shieldId, shield in pairs(playerUnit.absorption) do
                                if shield.amount then
                                    totalAbsorption = totalAbsorption + shield.amount
                                end
                            end
                            if totalAbsorption > 0 then
                                local absorbColor = C and C.palette and C.palette.textBonus or {0.9, 0.9, 0.9, 1}
                                table.insert(spec.lines, {
                                    left = "Shields Absorb:",
                                    right = string.format("%d damage", totalAbsorption),
                                    r = absorbColor[1], g = absorbColor[2], b = absorbColor[3]
                                })
                            end
                        end

                        -- Show advantage/disadvantage level for DEFENCE if present
                        local Advantage = RPE and RPE.Core and RPE.Core.Advantage
                        if Advantage then
                            local advLevel = Advantage:Get("DEFENCE")
                            if advLevel > 0 then
                                local advColor = C and C.palette and C.palette.textBonus or {0.55, 0.95, 0.65, 1.00}
                                table.insert(spec.lines, {
                                    left = "Advantage:",
                                    right = string.format("x%d", advLevel),
                                    r = advColor[1], g = advColor[2], b = advColor[3]
                                })
                            elseif advLevel < 0 then
                                local disColor = C and C.palette and C.palette.textMalus or {0.95, 0.55, 0.55, 1.00}
                                table.insert(spec.lines, {
                                    left = "Disadvantage:",
                                    right = string.format("x%d", math.abs(advLevel)),
                                    r = disColor[1], g = disColor[2], b = disColor[3]
                                })
                            end
                        end

                        table.insert(spec.lines, { left = "", right = "", r = 0, g = 0, b = 0 })  -- Blank line for spacing
                    end
                end
                
                -- Get attacker's roll to determine tooltip ranges
                local attackerRoll = reactions and reactions.attackRoll or 50  -- Default to 50
                
                -- Add spacing before damage breakdown if we showed modifiers/advantages
                local hasStats = (defense.statId and defense.defenseType == "complex") or defense.defenseType == "simple"
                if hasStats and (#spec.lines > 0 and spec.lines[#spec.lines].left ~= "") then
                    table.insert(spec.lines, { left = "", right = "", r = 0, g = 0, b = 0 })
                end
                
                -- Get immune schools to avoid showing damage for them
                local immuneSchools = _getImmuneSchools()
                
                -- On Fail line: show damage with fail mitigation applied (1 to [N-1])
                -- Only show for non-pass defenses
                if reactions and reactions.predictedDamage and defense.defenseType ~= "pass" then
                    local failLabel = "1-" .. tostring(math.max(1, attackerRoll - 1))
                    -- Show full damage breakdown by school if available
                    if reactions.damageBySchool then
                        for school, amount in pairs(reactions.damageBySchool) do
                            -- Skip displaying damage for schools player is immune to
                            if not immuneSchools[school:lower()] then
                                if tonumber(amount) and tonumber(amount) > 0 then
                                    local failDamage = amount
                                    
                                    -- Apply fail mitigation based on defense type
                                    if defense.statId and defense.defenseType == "complex" then
                                        -- Complex defense: get fail mitigation from the specific defense stat
                                        local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                                        local statDef = StatRegistry and StatRegistry:Get(defense.statId)
                                        
                                        if statDef and statDef.mitigation and statDef.mitigation.fail then
                                            local mitigationExpr = statDef.mitigation.fail
                                            if mitigationExpr ~= 0 then
                                                if type(mitigationExpr) == "number" then
                                                    failDamage = math.max(0, amount - mitigationExpr)
                                                elseif type(mitigationExpr) == "string" then
                                                    local Formula = RPE and RPE.Core and RPE.Core.Formula
                                                    if Formula and Formula.Roll then
                                                        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                                        local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                                        local result = Formula:Roll(exprWithValue, profile)
                                                        if result and type(result) == "number" then
                                                            failDamage = math.max(0, result)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    elseif defense.defenseType == "simple" then
                                        -- Simple defense: get fail mitigation from DEFENCE stat
                                        local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                                        local defenceStat_def = StatRegistry and StatRegistry:Get("DEFENCE")
                                        
                                        if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.fail then
                                            local mitigationExpr = defenceStat_def.mitigation.fail
                                            if mitigationExpr ~= 0 then
                                                if type(mitigationExpr) == "number" then
                                                    failDamage = math.max(0, amount - mitigationExpr)
                                                elseif type(mitigationExpr) == "string" then
                                                    local Formula = RPE and RPE.Core and RPE.Core.Formula
                                                    if Formula and Formula.Roll then
                                                        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                                        local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                                        local result = Formula:Roll(exprWithValue, profile)
                                                        if result and type(result) == "number" then
                                                            failDamage = math.max(0, result)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    table.insert(spec.lines, {
                                        left = failLabel,
                                        right = string.format("Takes %d %s damage", math.floor(tonumber(failDamage)), school),
                                        r = 1, g = 0.3, b = 0.3
                                    })
                                end
                            end
                        end
                    else
                        -- Fallback to single school display if breakdown not available
                        local damageAmount = reactions.predictedDamage or 0
                        local school = reactions.damageSchool or "Physical"
                        
                        -- Apply fail mitigation for single school fallback
                        if defense.statId and defense.defenseType == "complex" then
                            local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                            local statDef = StatRegistry and StatRegistry:Get(defense.statId)
                            
                            if statDef and statDef.mitigation and statDef.mitigation.fail then
                                local mitigationExpr = statDef.mitigation.fail
                                if mitigationExpr ~= 0 then
                                    if type(mitigationExpr) == "number" then
                                        damageAmount = math.max(0, damageAmount - mitigationExpr)
                                    elseif type(mitigationExpr) == "string" then
                                        local Formula = RPE and RPE.Core and RPE.Core.Formula
                                        if Formula and Formula.Roll then
                                            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(damageAmount))
                                            local result = Formula:Roll(exprWithValue, profile)
                                            if result and type(result) == "number" then
                                                damageAmount = math.max(0, result)
                                            end
                                        end
                                    end
                                end
                            end
                        elseif defense.defenseType == "simple" then
                            local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                            local defenceStat_def = StatRegistry and StatRegistry:Get("DEFENCE")
                            
                            if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.fail then
                                local mitigationExpr = defenceStat_def.mitigation.fail
                                if mitigationExpr ~= 0 then
                                    if type(mitigationExpr) == "number" then
                                        damageAmount = math.max(0, damageAmount - mitigationExpr)
                                    elseif type(mitigationExpr) == "string" then
                                        local Formula = RPE and RPE.Core and RPE.Core.Formula
                                        if Formula and Formula.Roll then
                                            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(damageAmount))
                                            local result = Formula:Roll(exprWithValue, profile)
                                            if result and type(result) == "number" then
                                                damageAmount = math.max(0, result)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        if not immuneSchools[school:lower()] then
                            table.insert(spec.lines, {
                                left = failLabel,
                                right = string.format("Takes %d %s damage", damageAmount, school),
                                r = 1, g = 0.3, b = 0.3
                            })
                        end
                    end
                end
                
                -- On Success line: show mitigated damage per school (if defending succeeds)
                
                -- For tooltip, show as dice roll range based on attacker's roll
                -- Fail: 1 to [N-1]
                -- Success: N to 99
                -- Critical: 100
                local successLabel = (defense.defenseType == "pass") and " " or tostring(attackerRoll) .. "-99"
                local critLabel = "100"
                
                if reactions and reactions.damageBySchool then
                    -- Apply mitigation per damage school
                    local successDamageBySchool = {}
                    local critSuccessDamageBySchool = nil
                    
                    for school, amount in pairs(reactions.damageBySchool) do
                        successDamageBySchool[school] = amount
                        
                        -- Apply mitigation based on defense type
                        if defense.defenseType == "pass" then
                            -- Pass defense: no mitigation, take full damage per school
                            successDamageBySchool[school] = amount
                        elseif defense.statId and defense.defenseType ~= "pass" then
                            -- Get mitigation from this specific defense stat
                            local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                            local statDef = StatRegistry and StatRegistry:Get(defense.statId)
                            
                            if statDef and statDef.mitigation and statDef.mitigation.normal then
                                local mitigationExpr = statDef.mitigation.normal
                                if mitigationExpr ~= 0 then
                                    if type(mitigationExpr) == "number" then
                                        successDamageBySchool[school] = math.max(0, amount - mitigationExpr)
                                    elseif type(mitigationExpr) == "string" then
                                        local Formula = RPE and RPE.Core and RPE.Core.Formula
                                        if Formula and Formula.Roll then
                                            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                            local result = Formula:Roll(exprWithValue, profile)
                                            if result and type(result) == "number" then
                                                successDamageBySchool[school] = math.max(0, result)
                                            end
                                        end
                                    end
                                end
                            end
                        elseif defense.defenseType == "simple" then
                            -- For simple defense, use DEFENCE stat's mitigation
                            local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                            local defenceStat_def = StatRegistry and StatRegistry:Get("DEFENCE")
                            
                            if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.normal then
                                local mitigationExpr = defenceStat_def.mitigation.normal
                                if mitigationExpr ~= 0 then
                                    if type(mitigationExpr) == "number" then
                                        successDamageBySchool[school] = math.max(0, amount - mitigationExpr)
                                    elseif type(mitigationExpr) == "string" then
                                        local Formula = RPE and RPE.Core and RPE.Core.Formula
                                        if Formula and Formula.Roll then
                                            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                            local result = Formula:Roll(exprWithValue, profile)
                                            if result and type(result) == "number" then
                                                successDamageBySchool[school] = math.max(0, result)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Calculate critical success damage if mitigation differs
                    local hasCritMitigation = false
                    if defense.defenseType ~= "pass" then
                        local StatRegistry = RPE and RPE.Core and RPE.Core.StatRegistry
                        local statDef = nil
                        if defense.statId then
                            statDef = StatRegistry and StatRegistry:Get(defense.statId)
                        elseif defense.defenseType == "simple" then
                            statDef = StatRegistry and StatRegistry:Get("DEFENCE")
                        end
                        
                        if statDef and statDef.mitigation and statDef.mitigation.critical ~= nil then
                            hasCritMitigation = true
                            critSuccessDamageBySchool = {}
                            
                            for school, amount in pairs(reactions.damageBySchool) do
                                local critMitigationExpr = statDef.mitigation.critical
                                critSuccessDamageBySchool[school] = amount
                                
                                if critMitigationExpr ~= 0 then
                                    if type(critMitigationExpr) == "number" then
                                        critSuccessDamageBySchool[school] = math.max(0, amount - critMitigationExpr)
                                    elseif type(critMitigationExpr) == "string" then
                                        local Formula = RPE and RPE.Core and RPE.Core.Formula
                                        if Formula and Formula.Roll then
                                            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
                                            local exprWithValue = critMitigationExpr:gsub("%$value%$", tostring(amount))
                                            local result = Formula:Roll(exprWithValue, profile)
                                            if result and type(result) == "number" then
                                                critSuccessDamageBySchool[school] = math.max(0, result)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Display success damage per school (skip immune schools)
                    local labelColor = (defense.defenseType == "pass") and {r = 1, g = 0.3, b = 0.3} or {r = 0.3, g = 1, b = 0.3}
                    for school, amount in pairs(successDamageBySchool) do
                        -- Skip displaying damage for schools player is immune to
                        if not immuneSchools[school:lower()] then
                            if tonumber(amount) and tonumber(amount) >= 0 then
                                table.insert(spec.lines, {
                                    left = successLabel,
                                    right = string.format("Takes %d %s damage", math.floor(tonumber(amount)), school),
                                    r = labelColor.r, g = labelColor.g, b = labelColor.b
                                })
                            end
                        end
                    end
                    
                    -- Display critical success damage per school if different from normal (skip immune schools)
                    if hasCritMitigation and critSuccessDamageBySchool then
                        for school, amount in pairs(critSuccessDamageBySchool) do
                            -- Skip displaying damage for schools player is immune to
                            if not immuneSchools[school:lower()] then
                                if tonumber(amount) and tonumber(amount) >= 0 then
                                    table.insert(spec.lines, {
                                        left = critLabel,
                                        right = string.format("Takes %d %s damage", math.floor(tonumber(amount)), school),
                                        r = 0.2, g = 1, b = 0.5
                                    })
                                end
                            end
                        end
                    end
                    elseif reactions and reactions.predictedDamage then
                        -- Fallback for old single-school format
                        local school = reactions.damageSchool or "Physical"
                        -- Skip displaying damage if player is immune to this school
                        if not immuneSchools[school:lower()] then
                            local labelColor = (defense.defenseType == "pass") and {r = 1, g = 0.3, b = 0.3} or {r = 0.3, g = 1, b = 0.3}
                            table.insert(spec.lines, {
                                left = successLabel,
                                right = string.format("Takes %d %s damage", reactions.predictedDamage, school),
                                r = labelColor.r, g = labelColor.g, b = labelColor.b
                            })
                        end
                    end
                end  -- Close the if defense.defenseType == "help" else block
                
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
    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
    local hitRollVal = ActiveRules and ActiveRules:Get("hit_roll") or "1d20"
    local hitRoll = type(hitRollVal) == "table" and hitRollVal[1] or tostring(hitRollVal)
    
    local roll = (Advantage and profile) and (Advantage:Roll(hitRoll, profile, "DEFENCE") or 0) or (Common and Common:Roll(hitRoll) or math.random(1, 20))
    local lhs = roll + defenceStat
    local defendSuccess = lhs >= (reaction.attackRoll or 0)
    
    -- Apply mitigation per damage school
    local finalDamageBySchool = {}
    if reaction.damageBySchool then
        for school, amount in pairs(reaction.damageBySchool) do
            -- Check for aura-based immunity to this damage school
            if _checkDamageSchoolImmunity(school) then
                finalDamageBySchool[school] = 0
            else
                finalDamageBySchool[school] = amount
                
                local defenceStat_def = StatRegistry and StatRegistry:Get("DEFENCE")
                if defendSuccess then
                    -- Apply normal mitigation on success
                    if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.normal then
                        local mitigationExpr = defenceStat_def.mitigation.normal
                        if mitigationExpr ~= 0 then
                            if type(mitigationExpr) == "number" then
                                finalDamageBySchool[school] = math.max(0, amount - mitigationExpr)
                            elseif type(mitigationExpr) == "string" and Formula and profile then
                                local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                local result = Formula:Roll(exprWithValue, profile)
                                if result and type(result) == "number" then
                                    finalDamageBySchool[school] = math.max(0, result)
                                end
                            end
                        end
                    end
                else
                    -- Apply fail mitigation on failure
                    if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.fail then
                        local mitigationExpr = defenceStat_def.mitigation.fail
                        if mitigationExpr ~= 0 then
                            if type(mitigationExpr) == "number" then
                                finalDamageBySchool[school] = math.max(0, amount - mitigationExpr)
                            elseif type(mitigationExpr) == "string" and Formula and profile then
                                local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                local result = Formula:Roll(exprWithValue, profile)
                                if result and type(result) == "number" then
                                    finalDamageBySchool[school] = math.max(0, result)
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        -- Fallback for single school
        local school = reaction.damageSchool or "Physical"
        if _checkDamageSchoolImmunity(school) then
            finalDamageBySchool[school] = 0
        else
            finalDamageBySchool[school] = reaction.predictedDamage
            
            local defenceStat_def = StatRegistry and StatRegistry:Get("DEFENCE")
            if defendSuccess then
                -- Apply normal mitigation on success
                if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.normal then
                    local mitigationExpr = defenceStat_def.mitigation.normal
                    if mitigationExpr ~= 0 then
                        if type(mitigationExpr) == "number" then
                            finalDamageBySchool[school] = math.max(0, reaction.predictedDamage - mitigationExpr)
                        elseif type(mitigationExpr) == "string" and Formula and profile then
                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(reaction.predictedDamage))
                            local result = Formula:Roll(exprWithValue, profile)
                            if result and type(result) == "number" then
                                finalDamageBySchool[school] = math.max(0, result)
                            end
                        end
                    end
                end
            else
                -- Apply fail mitigation on failure
                if defenceStat_def and defenceStat_def.mitigation and defenceStat_def.mitigation.fail then
                    local mitigationExpr = defenceStat_def.mitigation.fail
                    if mitigationExpr ~= 0 then
                        if type(mitigationExpr) == "number" then
                            finalDamageBySchool[school] = math.max(0, reaction.predictedDamage - mitigationExpr)
                        elseif type(mitigationExpr) == "string" and Formula and profile then
                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(reaction.predictedDamage))
                            local result = Formula:Roll(exprWithValue, profile)
                            if result and type(result) == "number" then
                                finalDamageBySchool[school] = math.max(0, result)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Calculate total final damage
    local totalFinalDamage = 0
    for _, amount in pairs(finalDamageBySchool) do
        totalFinalDamage = totalFinalDamage + amount
    end
    
    local outcomeText = defendSuccess and (totalFinalDamage > 0 and "partially defend" or "fully defend") or "failed to defend"
    
    local attackerName = "Attacker"
    if reaction and reaction.caster then
        local attacker = RPE.Common and RPE.Common:FindUnitById(reaction.caster)
        if attacker then
            attackerName = (RPE.Common and RPE.Common:FormatUnitName(attacker)) or ("Unit " .. tostring(reaction.caster))
        end
    end
    
    local Debug = RPE and RPE.Debug
    if Debug and Debug.Dice then
        Debug:Dice(("You %s against %s. (%d vs %d)"):format(outcomeText, attackerName, lhs, reaction.attackRoll or 0))
    end

    local defenderName = UnitName("player") or "You"
    if Broadcast and Broadcast.SendCombatMessage then
        local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() or 0
        -- Aggregate damage by school into single message
        local damageStrings = {}
        for school, amount in pairs(finalDamageBySchool) do
            if tonumber(amount) and tonumber(amount) > 0 then
                table.insert(damageStrings, math.floor(amount) .. " " .. school)
            end
        end
        if #damageStrings > 0 then
            local damageText = table.concat(damageStrings, ", ")
            Broadcast:SendCombatMessage(playerId, defenderName, ("%s deals %s damage to %s."):format(attackerName, damageText, defenderName))
        else
            -- All damage was mitigated
            Broadcast:SendCombatMessage(playerId, defenderName, ("%s's attack is completely negated!"):format(attackerName))
        end
    end

    -- Store the chosen defense stat in currentReaction before completing
    local currentReaction = RPE.Core and RPE.Core.PlayerReaction and RPE.Core.PlayerReaction:GetCurrent()
    if currentReaction then
        currentReaction.chosenDefenseStat = "DEFENCE"
    end

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Complete then
        PlayerReaction:Complete(defendSuccess, roll, lhs, totalFinalDamage)
    end
end

function PlayerReactionWidget:_handleComplexDefense(reaction, statId)
    local defenseStat = RPE.Stats and RPE.Stats:GetValue(statId) or 0
    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB:GetOrCreateActive()
    local hitRollVal = ActiveRules and ActiveRules:Get("hit_roll") or "1d20"
    local hitRoll = type(hitRollVal) == "table" and hitRollVal[1] or tostring(hitRollVal)
    
    local roll = (Advantage and profile) and (Advantage:Roll(hitRoll, profile, statId) or 0) or (Common and Common:Roll(hitRoll) or math.random(1, 20))
    local lhs = roll + defenseStat
    local defendSuccess = lhs >= (reaction.attackRoll or 0)
    
    -- Apply mitigation per damage school
    local finalDamageBySchool = {}
    if reaction.damageBySchool then
        for school, amount in pairs(reaction.damageBySchool) do
            -- Check for aura-based immunity to this damage school
            if _checkDamageSchoolImmunity(school) then
                finalDamageBySchool[school] = 0
            else
                finalDamageBySchool[school] = amount
                
                local statDef = StatRegistry and StatRegistry:Get(statId)
                if defendSuccess and statId then
                    -- Apply normal mitigation on success
                    if statDef and statDef.mitigation and statDef.mitigation.normal then
                        local mitigationExpr = statDef.mitigation.normal
                        if mitigationExpr ~= 0 then
                            if type(mitigationExpr) == "number" then
                                finalDamageBySchool[school] = math.max(0, amount - mitigationExpr)
                            elseif type(mitigationExpr) == "string" and Formula and profile then
                                local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                local result = Formula:Roll(exprWithValue, profile)
                                if result and type(result) == "number" then
                                    finalDamageBySchool[school] = math.max(0, result)
                                end
                            end
                        end
                    end
                elseif not defendSuccess and statId then
                    -- Apply fail mitigation on failure
                    if statDef and statDef.mitigation and statDef.mitigation.fail then
                        local mitigationExpr = statDef.mitigation.fail
                        if mitigationExpr ~= 0 then
                            if type(mitigationExpr) == "number" then
                                finalDamageBySchool[school] = math.max(0, amount - mitigationExpr)
                            elseif type(mitigationExpr) == "string" and Formula and profile then
                                local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(amount))
                                local result = Formula:Roll(exprWithValue, profile)
                                if result and type(result) == "number" then
                                    finalDamageBySchool[school] = math.max(0, result)
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        -- Fallback for single school
        local school = reaction.damageSchool or "Physical"
        if _checkDamageSchoolImmunity(school) then
            finalDamageBySchool[school] = 0
        else
            finalDamageBySchool[school] = reaction.predictedDamage
            
            local statDef = StatRegistry and StatRegistry:Get(statId)
            if defendSuccess and statId then
                -- Apply normal mitigation on success
                if statDef and statDef.mitigation and statDef.mitigation.normal then
                    local mitigationExpr = statDef.mitigation.normal
                    if mitigationExpr ~= 0 then
                        if type(mitigationExpr) == "number" then
                            finalDamageBySchool[school] = math.max(0, reaction.predictedDamage - mitigationExpr)
                        elseif type(mitigationExpr) == "string" and Formula and profile then
                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(reaction.predictedDamage))
                            local result = Formula:Roll(exprWithValue, profile)
                            if result and type(result) == "number" then
                                finalDamageBySchool[school] = math.max(0, result)
                            end
                        end
                    end
                end
            elseif not defendSuccess and statId then
                -- Apply fail mitigation on failure
                if statDef and statDef.mitigation and statDef.mitigation.fail then
                    local mitigationExpr = statDef.mitigation.fail
                    if mitigationExpr ~= 0 then
                        if type(mitigationExpr) == "number" then
                            finalDamageBySchool[school] = math.max(0, reaction.predictedDamage - mitigationExpr)
                        elseif type(mitigationExpr) == "string" and Formula and profile then
                            local exprWithValue = mitigationExpr:gsub("%$value%$", tostring(reaction.predictedDamage))
                            local result = Formula:Roll(exprWithValue, profile)
                            if result and type(result) == "number" then
                                finalDamageBySchool[school] = math.max(0, result)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Calculate total final damage
    local totalFinalDamage = 0
    for _, amount in pairs(finalDamageBySchool) do
        totalFinalDamage = totalFinalDamage + amount
    end
    
    local outcomeText = defendSuccess and (totalFinalDamage > 0 and "partially defend" or "fully defend") or "failed to defend"
    
    local attackerName = "Attacker"
    if reaction and reaction.caster then
        local attacker = RPE.Common and RPE.Common:FindUnitById(reaction.caster)
        if attacker then
            attackerName = (RPE.Common and RPE.Common:FormatUnitName(attacker)) or ("Unit " .. tostring(reaction.caster))
        end
    end
    
    local Debug = RPE and RPE.Debug
    if Debug and Debug.Dice then
        Debug:Dice(("You %s against %s. (%d vs %d)"):format(outcomeText, attackerName, lhs, reaction.attackRoll or 0))
    end

    local defenderName = UnitName("player") or "You"
    if Broadcast and Broadcast.SendCombatMessage then
        local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() or 0
        -- Aggregate damage by school into single message
        local damageStrings = {}
        for school, amount in pairs(finalDamageBySchool) do
            if tonumber(amount) and tonumber(amount) > 0 then
                table.insert(damageStrings, math.floor(amount) .. " " .. school)
            end
        end
        if #damageStrings > 0 then
            local damageText = table.concat(damageStrings, ", ")
            Broadcast:SendCombatMessage(playerId, defenderName, ("%s deals %s damage to %s."):format(attackerName, damageText, defenderName))
        end
    end

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Complete then
        -- Store the chosen defense stat in currentReaction before completing
        local currentReaction = PlayerReaction:GetCurrent()
        if currentReaction then
            currentReaction.chosenDefenseStat = statId
        end
        PlayerReaction:Complete(defendSuccess, roll, lhs, totalFinalDamage)
    end
end

function PlayerReactionWidget:_handlePassDefense(reaction)
    local defendSuccess = false  -- Passing on a defense = no defense (take full damage)
    local roll = 0
    local lhs = 0
    
    -- Calculate total final damage from all schools, checking for immunity
    local finalDamageBySchool = {}
    if reaction.damageBySchool then
        for school, amount in pairs(reaction.damageBySchool) do
            -- Check for aura-based immunity to this damage school
            if _checkDamageSchoolImmunity(school) then
                finalDamageBySchool[school] = 0
            else
                finalDamageBySchool[school] = amount
            end
        end
    else
        -- Fallback for single school
        local school = reaction.damageSchool or "Physical"
        if _checkDamageSchoolImmunity(school) then
            finalDamageBySchool[school] = 0
        else
            finalDamageBySchool[school] = reaction.predictedDamage
        end
    end
    
    -- Calculate total final damage
    local totalFinalDamage = 0
    for _, amount in pairs(finalDamageBySchool) do
        totalFinalDamage = totalFinalDamage + amount
    end

    -- Display outcome
    local attackerName = "Attacker"
    if reaction and reaction.caster then
        local attacker = RPE.Common and RPE.Common:FindUnitById(reaction.caster)
        if attacker then
            attackerName = (RPE.Common and RPE.Common:FormatUnitName(attacker)) or ("Unit " .. tostring(reaction.caster))
        end
    end
    local Debug = RPE and RPE.Debug
    if Debug and Debug.Dice then
        Debug:Dice(("You passed against %s (no defense attempted)."):format(attackerName))
    end

    local defenderName = UnitName("player") or "You"
    if Broadcast and Broadcast.SendCombatMessage then
        local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() or 0
        -- Aggregate damage by school into single message, but note that absorption will reduce actual HP damage
        if reaction.damageBySchool then
            local damageStrings = {}
            for school, amount in pairs(finalDamageBySchool) do
                if tonumber(amount) and tonumber(amount) > 0 then
                    table.insert(damageStrings, math.floor(amount) .. " " .. school)
                end
            end
            if #damageStrings > 0 then
                local damageText = table.concat(damageStrings, ", ")
                -- Note: actual HP damage will be reduced by absorption shields when DAMAGE handler applies them
                Broadcast:SendCombatMessage(playerId, defenderName, ("%s deals %s damage to %s."):format(attackerName, damageText, defenderName))
            end
        else
            -- Fallback for single school
            local school = reaction.damageSchool or "Physical"
            Broadcast:SendCombatMessage(playerId, defenderName, ("%s deals %d %s damage to %s."):format(attackerName, totalFinalDamage, school, defenderName))
        end
    end

    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Complete then
        -- Pass defendSuccess=false and totalFinalDamage (passed defense takes full damage)
        PlayerReaction:Complete(defendSuccess, roll, lhs, totalFinalDamage)
    end
end

function PlayerReactionWidget:_handleHelp()
    -- Mark help as used this turn
    self._helpUsedThisTurn = true
    
    -- Get player name and ID
    local playerName = UnitName("player") or "You"
    local playerId = RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:GetLocalPlayerUnitId() or 0
    
    -- Broadcast help call to teammates
    local Broadcast = RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.CallHelp then
        Broadcast:CallHelp(playerId, playerName)
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
