-- RPE_UI/Prefabs/ActionBarSlot.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class ActionBarSlot : FrameElement
---@field frame Button
---@field button Button
---@field bg Texture
---@field icon Texture
---@field cooldown Cooldown
---@field hotkey FontString
---@field disabledOverlay Texture
---@field glow Texture
---@field reactionGlow Texture    -- pulsing glow for reaction-castable spells
---@field cdOverlay Texture       -- dark overlay that shrinks
---@field cdLine Texture          -- bright line at overlay top edge
---@field cdText FontString|nil   -- centered cooldown text
---@field action table|nil
---@field _cdTotal integer|nil
---@field _cdRemain integer|nil
---@field _cdAnimStart number|nil
---@field _cdAnimFrom number|nil
---@field _cdAnimTo number|nil
---@field _cdAnimDur number|nil
---@field _reactionPulseStart number|nil -- animation start time for reaction glow
local ActionBarSlot = setmetatable({}, { __index = FrameElement })
ActionBarSlot.__index = ActionBarSlot
RPE_UI.Prefabs.ActionBarSlot = ActionBarSlot

local EMPTY_SLOT_TEX = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

local function SafeTexture(tex, path)
    if not tex then return end
    if path and path ~= "" then
        tex:SetTexture(path); tex:Show()
    else
        tex:SetTexture(nil);  tex:Hide()
    end
end

local function FadeOutOnce(tex, duration, startAlpha)
    if not tex then return end
    duration = duration or 0.35
    if startAlpha then tex:SetAlpha(startAlpha) end
    tex:Show()
    UIFrameFadeOut(tex, duration, tex:GetAlpha() or 0.9, 0.0)
    C_Timer.After(duration, function()
        if tex and tex.Hide then tex:Hide() end
    end)
end

local function clamp(x, a, b)
    if x < a then return a elseif x > b then return b else return x end
end

---Create a new action bar slot (styled like InventorySlot).
---@param name string
---@param opts { parent: any, size?: number }
---@return ActionBarSlot
function ActionBarSlot:New(name, opts)
    opts = opts or {}
    local parentFrame =
        (opts.parent and opts.parent.frame)
        or (type(opts.parent) == "table" and type(opts.parent.GetObjectType) == "function" and opts.parent)
        or UIParent

    local size = tonumber(opts.size) or 48

    -- Secure button
    local btn = CreateFrame("Button", name, parentFrame, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    btn:RegisterForClicks("AnyUp")
    btn:SetMotionScriptsWhileDisabled(true)

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(EMPTY_SLOT_TEX)
    bg:SetTexCoord(0,1,0,1)

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT",     btn, "TOPLEFT",     2, -2)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Blizzard Cooldown spiral (unused for turns; we only clear it)
    local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(true)
    cd:SetSwipeColor(0, 0, 0, 0.6)

    -- Disabled overlay (for non-cooldown disables)
    local dis = btn:CreateTexture(nil, "OVERLAY")
    dis:SetAllPoints()
    dis:SetColorTexture(0.2, 0.2, 0.2, 0.55)
    dis:Hide()

    -- Glow
    local glow = btn:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.8)
    glow:SetDrawLayer("OVERLAY", 7)
    glow:SetSize(size * 1.8, size * 1.8)
    glow:SetPoint("CENTER", btn, "CENTER")
    glow:Hide()

    -- Reaction glow (pulsing glow when castable as reaction)
    local reactionGlow = btn:CreateTexture(nil, "OVERLAY")
    reactionGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    reactionGlow:SetBlendMode("ADD")
    reactionGlow:SetAlpha(0.1)  -- matches pulse minimum so it's ready when shown
    reactionGlow:SetDrawLayer("OVERLAY", 7)
    reactionGlow:SetSize(size * 1.8, size * 1.8)
    reactionGlow:SetPoint("CENTER", btn, "CENTER")
    reactionGlow:SetVertexColor(0.2, 0.8, 1)  -- cyan-blue for reactions
    reactionGlow:Hide()

    -- Turn-based cooldown overlay (sits over icon, shrinks from bottom)
    local cdOverlay = btn:CreateTexture(nil, "OVERLAY")
    cdOverlay:SetDrawLayer("OVERLAY", 6)
    cdOverlay:SetColorTexture(0, 0, 0, 0.45)  -- dark translucent
    cdOverlay:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
    cdOverlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    cdOverlay:SetHeight(0)
    cdOverlay:Hide()

    -- Bright line at the overlay's top edge
    local cdLine = btn:CreateTexture(nil, "OVERLAY")
    cdLine:SetDrawLayer("OVERLAY", 7)
    cdLine:SetColorTexture(1, 1, 1, 0.75)
    cdLine:SetPoint("LEFT", cdOverlay, "LEFT", 0, 0)
    cdLine:SetPoint("RIGHT", cdOverlay, "RIGHT", 0, 0)
    cdLine:SetHeight(2)
    cdLine:Hide()

    -- Wrap
    local o = FrameElement.New(self, "ActionBarSlot", btn, opts.parent)
    o.button          = btn
    o.bg              = bg
    o.icon            = icon
    o.cooldown        = cd
    o.disabledOverlay = dis
    o.glow            = glow
    o.reactionGlow    = reactionGlow
    o.cdOverlay       = cdOverlay
    o.cdLine          = cdLine
    o.action          = nil
    o.cdText          = nil
    o._cdTotal        = nil
    o._cdRemain       = 0
    o._cdAnimStart    = nil
    o._cdAnimFrom     = nil
    o._cdAnimTo       = nil
    o._cdAnimDur      = 0.18
    o._reactionPulseStart = nil
    o._slotBaseSize = size  -- Store base size for glow animations

    -- Animation driver
    local function OnUpdateAnim(_, elapsed)
        -- Update cooldown animation
        if o._cdAnimStart then
            local t0   = o._cdAnimStart
            local dur  = o._cdAnimDur or 0.18
            local prog = clamp((GetTime() - t0) / dur, 0, 1)
            local from = o._cdAnimFrom or 0
            local to   = o._cdAnimTo or 0
            local h    = from + (to - from) * prog

            if o.cdOverlay and o.cdOverlay:IsShown() then
                o.cdOverlay:SetHeight(h)
                -- keep the bright line glued to the overlay's top edge
                o.cdLine:ClearAllPoints()
                o.cdLine:SetPoint("TOPLEFT", o.cdOverlay, "TOPLEFT", 0, 0)
                o.cdLine:SetPoint("TOPRIGHT", o.cdOverlay, "TOPRIGHT", 0, 0)
                o.cdLine:Show()
            end

            if prog >= 1 then
                o._cdAnimStart = nil
            end
        end

        -- Update reaction glow pulse animation (independent from cooldown animation)
        if o.reactionGlow and o.reactionGlow:IsShown() and o._reactionPulseStart then
            local pulseTime = GetTime() - o._reactionPulseStart
            local pulseCycle = 0.8  -- 0.8 second pulse cycle (faster)
            local pulseProgress = (pulseTime % pulseCycle) / pulseCycle
            
            -- Smooth sinusoidal pulse: affects both alpha and size for dramatic effect
            local minAlpha = 0.1
            local maxAlpha = 1.0
            local baseSize = o._slotBaseSize or 48
            local minSize = baseSize * 1.8      -- base size (slot size * 1.8)
            local maxSize = baseSize * 2.0      -- expanded size (slot size * 2.8)
            local pulseWave = 0.5 + 0.5 * math.sin((pulseProgress * math.pi * 2) - math.pi / 2)
            
            local alpha = minAlpha + (maxAlpha - minAlpha) * pulseWave
            local currentSize = minSize + (maxSize - minSize) * pulseWave
            
            o.reactionGlow:SetAlpha(alpha)
            o.reactionGlow:SetSize(currentSize, currentSize)
        end
    end
    btn:SetScript("OnUpdate", OnUpdateAnim)

    -- Tooltip (use Common:ShowTooltip just like item slots)
    btn:HookScript("OnEnter", function(self)
        o.glow:Show()

        local a = o.action
        if not a or not a.spellId then return end

        -- If action has a direct tooltip, use it (for temporary/NPC actions)
        if a.tooltip and type(a.tooltip) == "string" then
            local firstLine = a.tooltip:match("^([^\n]+)")
            Common:ShowTooltip(self, {
                title = firstLine or a.tooltip,
                lines = {{ text = a.tooltip }}
            })
            return
        end

        -- Otherwise try spell registry
        local SR = RPE.Core.SpellRegistry
        local spell = SR and SR:Get(a.spellId)
        if not spell then return end

        if spell.GetTooltip then
            -- If this action bar is controlling an NPC, pass the unit so tooltip uses NPC's stats
            local casterUnit = nil
            if o._ownerWidget and o._ownerWidget._controlledUnitId then
                casterUnit = RPE.Common:FindUnitById(o._ownerWidget._controlledUnitId)
            end
            Common:ShowTooltip(self, spell:GetTooltip(a.rank or 1, casterUnit))
        else
            -- fallback if ShowTooltip not present (shouldn't happen once you add it)
            -- Common:ShowTooltip(self, { title = spell.name or a.spellId, lines = { spell:GetTooltip() } })
        end
    end)

    btn:HookScript("OnLeave", function()
        o.glow:Hide()
        RPE.Common:HideTooltip()
    end)

    -- Click -> cast spell (skip target window for CASTER/SELF)
    btn:SetScript("OnClick", function(_, mouseButton)
        local a = o.action
        if not a or not a.spellId or a.isEnabled == false then return end
        local SR = RPE.Core.SpellRegistry
        local SC = RPE.Core.SpellCast
        local spell = SR and SR:Get(a.spellId)
        if not spell then
            UIErrorsFrame:AddMessage("Spell not found: " .. tostring(a.spellId), 1, 0.2, 0.2)
            return
        end

        local event = RPE.Core.ActiveEvent
        if not event then
            UIErrorsFrame:AddMessage("No active event.", 1, 0.2, 0.2)
            return
        end

        -- Only apply player turn logic for the local player, not for NPCs or controlled units
        local skipTurnCheck = false
        if o._ownerWidget and o._ownerWidget._controlledUnitId then
            skipTurnCheck = true
        end
        if not skipTurnCheck then
            local isPlayerTurn = false
            if event and event.localPlayerKey and event.ticks and event.tickIndex and (#event.ticks > 0 and event.ticks[event.tickIndex]) then
                local tickUnits = event.ticks[event.tickIndex]
                if tickUnits then
                    for _, u in ipairs(tickUnits) do
                        if u.key == event.localPlayerKey then
                            isPlayerTurn = true
                            break
                        end
                    end
                end
            end
            local canCastOffTurn = false
            if not isPlayerTurn and (RPE.Core._helpRequestsThisTurn or 0) > 0 and spell.tags then
                for _, tag in ipairs(spell.tags) do
                    local lowerTag = tag:lower()
                    if lowerTag == "assist" or lowerTag == "reaction" then
                        canCastOffTurn = true
                        break
                    end
                end
            end

            if not isPlayerTurn and not canCastOffTurn then
                UIErrorsFrame:AddMessage("Not your turn.", 1, 0.2, 0.2)
                return
            end
        end

        -- Build casting context
        local ctx = {
            event      = event,
            resources  = RPE.Core.Resources,
            cooldowns  = RPE.Core.Cooldowns,
            actionBar  = o._ownerWidget,
            slotIndex  = o.index,
        }

        -- Determine who is casting: check for controlled unit or default to local player key
        local casterId = nil
        local casterKey = event.localPlayerKey
        if o._ownerWidget and o._ownerWidget._controlledUnitId then
            -- Casting as a controlled unit (numeric ID)
            casterId = o._ownerWidget._controlledUnitId
        else
            -- Casting as local player (key -> need to look up numeric ID)
            casterId = casterKey
        end

        -- Create cast object and validate requirements BEFORE any targeting
        local cast = SC.New(a.spellId, casterId, a.rank)
        local ok, reason = cast:Validate(ctx)
        if not ok then
            UIErrorsFrame:AddMessage("Cannot cast: "..(reason or ""), 1, 0.3, 0.3)
            return
        end

        -- === Case 1: Self or caster-only targeting (instant resolve) ===
        local defaultTargeter = spell.targeter and spell.targeter.default
        if defaultTargeter == "CASTER" or defaultTargeter == "SELF" then
            -- Seed precast targets
            cast.targetSets = cast.targetSets or {}
            local tgtKey = (defaultTargeter == "SELF") and "CASTER" or defaultTargeter
            local sel = RPE.Core.Targeters and RPE.Core.Targeters:Select(tgtKey, ctx, cast, {})
            
            -- If we have targets from selector, use them. Otherwise, use the caster as fallback.
            -- This ensures NPCs target themselves, not the player!
            if sel and sel.targets and #sel.targets > 0 then
                cast.targetSets.precast = sel.targets
            else
                -- For SELF/CASTER targeting, the target should be the caster (player or NPC)
                -- Find the unit with this numeric ID to get its key
                local casterKey = event.localPlayerKey
                if event and event.units then
                    for key, unit in pairs(event.units) do
                        if unit.id == casterId then
                            casterKey = key
                            break
                        end
                    end
                end
                cast.targetSets.precast = { casterKey }
            end

            cast:FinishTargeting(ctx)

            -- click feedback
            if o._slotSize then
                local shrinkSize = o._slotSize * 0.9
                o:SetSlotSize(shrinkSize)
                C_Timer.After(0.1, function()
                    if o and o._slotSize then o:SetSlotSize(o._slotSize) end
                end)
            end
            return
        end

        -- === Case 2: All other spells use full targeting pipeline ===
        cast:InitTargeting()
        cast:RequestNextTargetSet(ctx)

        -- click feedback
        if o._slotSize then
            local shrinkSize = o._slotSize * 0.9
            o:SetSlotSize(shrinkSize)
            C_Timer.After(0.1, function()
                if o and o._slotSize then o:SetSlotSize(o._slotSize) end
            end)
        end
    end)

    return o
end

-- ===== API =====

function ActionBarSlot:_Bind(index, ownerWidget)
    self.index = index
    self._ownerWidget = ownerWidget
end

function ActionBarSlot:SetSlotSize(size)
    size = tonumber(size) or 48
    self._currentSize = size
    if not self._slotSize then self._slotSize = size end
    self.frame:SetSize(size, size)
    if self.glow then self.glow:SetSize(size * 1.8, size * 1.8) end
end

-- Internal: check if spell requirements are met

--- Check if this slot's spell requirements are met and it is the player's turn
function ActionBarSlot:MeetsAllRequirements()
    if not self.action or not self.action.spellId then return false end
    local SR = RPE.Core.SpellRegistry
    local spell = SR and SR:Get(self.action.spellId)
    if not spell then return false end

    -- Only apply player turn logic for the local player, not for NPCs or controlled units
    local event = RPE.Core.ActiveEvent
    local skipTurnCheck = false
    if self._ownerWidget and self._ownerWidget._controlledUnitId then
        skipTurnCheck = true
    end

    if not skipTurnCheck then
        -- If player is defending, always allow reaction/assist spells
        if RPE.Core._isDefendingThisTurn and (spell.tags or spell.flags) then
            for _, tag in ipairs(spell.tags or spell.flags) do
                local lowerTag = tag:lower()
                if lowerTag == "assist" or lowerTag == "reaction" then
                    return true
                end
            end
        end

        local isPlayerTurn = false
        if event and event.localPlayerKey and event.ticks and event.tickIndex and (#event.ticks > 0 and event.ticks[event.tickIndex]) then
            local tickUnits = event.ticks[event.tickIndex]
            if tickUnits then
                for _, u in ipairs(tickUnits) do
                    if u.key == event.localPlayerKey then
                        isPlayerTurn = true
                        break
                    end
                end
            end
        end

        local canCastOffTurn = false
        if not isPlayerTurn and ((RPE.Core._helpRequestsThisTurn or 0) > 0 or RPE.Core._isDefendingThisTurn) and (spell.tags or spell.flags) then
            for _, tag in ipairs(spell.tags or spell.flags) do
                local lowerTag = tag:lower()
                if lowerTag == "assist" or lowerTag == "reaction" then
                    canCastOffTurn = true
                    break
                end
            end
        end

        if not isPlayerTurn and not canCastOffTurn then
            return false -- Not the player's turn, and not a reaction/assist spell with help called
        end
    end

    -- Check spell-level requirements
    if spell.requirements and #spell.requirements > 0 then
        local Requirements = RPE.Core.SpellRequirements
        if not Requirements then return false end
        local ctx = {}
        for _, req in ipairs(spell.requirements) do
            local ok = Requirements:EvalRequirement(ctx, req)
            if not ok then
                return false  -- requirement not met
            end
        end
    end

    return true  -- all requirements met
end

function ActionBarSlot:SetAction(action)
    self.action = action
    SafeTexture(self.icon, action and action.icon or nil)
    
    -- Determine if action should be enabled: handled by ActionBarWidget:RefreshRequirements
    
    -- reset cd visuals
    self.cooldown:Clear()
    if self.cdOverlay then self.cdOverlay:Hide(); self.cdOverlay:SetHeight(0) end
    if self.cdLine then self.cdLine:Hide() end
    if self.cdText then self.cdText:Hide() end
    self._cdTotal  = nil
    self._cdRemain = 0
    
    -- Hide reaction glow by default (will be shown in ActionBarWidget if spell has assist/reaction tag)
    if self.reactionGlow then
        self.reactionGlow:Hide()
        self._reactionPulseStart = nil
    end
    
    self:Show()
end

function ActionBarSlot:Clear()
    self.action = nil
    SafeTexture(self.icon, nil)
    self.disabledOverlay:Hide()
    self.cooldown:Clear()
    if self.cdOverlay then self.cdOverlay:Hide(); self.cdOverlay:SetHeight(0) end
    if self.cdLine then self.cdLine:Hide() end
    if self.cdText then self.cdText:Hide() end
    self._cdTotal  = nil
    self._cdRemain = 0
    
    -- Hide reaction glow when slot is cleared
    if self.reactionGlow then
        self.reactionGlow:Hide()
        self._reactionPulseStart = nil
    end
end

-- Internal: animate overlay height towards target
local function AnimateOverlayHeight(self, targetH)
    if not self.cdOverlay then return end
    local currentH = self.cdOverlay:GetHeight() or 0
    self._cdAnimFrom  = currentH
    self._cdAnimTo    = targetH
    self._cdAnimStart = GetTime()
    -- flash the top edge line a bit on update
    if self.cdLine then
        self.cdLine:SetAlpha(1.0)
        FadeOutOnce(self.cdLine, 0.18, 1.0) -- quick spark
    end
end

--- Turn-based cooldown with animated overlay & centered text.
---@param turns integer Remaining turns (0 = ready)
function ActionBarSlot:SetTurnCooldown(turns)
    turns = tonumber(turns) or 0
    self.cooldown:Clear()

    -- Ensure centered text above overlays
    if not self.cdText then
        local t = self.button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        t:SetDrawLayer("OVERLAY", 8)
        t:SetPoint("CENTER", self.button, "CENTER", 0, 0)
        t:SetJustifyH("CENTER"); t:SetJustifyV("MIDDLE")
        t:SetTextColor(1, 0.85, 0.2, 1)
        self.cdText = t
    end

    local iconTop = self.icon:GetTop() or 0
    local iconBottom = self.icon:GetBottom() or 0
    local fullH = math.max(0, iconTop - iconBottom)

    if turns <= 0 then
        -- cooldown finished
        self._cdRemain = 0
        self._cdTotal  = nil
        if self.cdText then self.cdText:Hide() end
        if self.cdOverlay then self.cdOverlay:Hide(); self.cdOverlay:SetHeight(0) end
        if self.cdLine then self.cdLine:Hide() end
        self:SetEnabled(true)
        return
    end

    -- starting or ticking: update totals
    if not self._cdTotal or turns > (self._cdRemain or 0) then
        -- new cooldown or a longer one superseded it
        self._cdTotal = turns
    end
    self._cdRemain = turns

    -- calculate target overlay height (bottom anchored, shrinks as turns drop)
    local frac = (self._cdTotal and self._cdTotal > 0) and (turns / self._cdTotal) or 1
    frac = clamp(frac, 0, 1)
    local targetH = math.floor(fullH * frac + 0.5)

    -- show/update visuals
    if self.cdOverlay then
        self.cdOverlay:Show()
        AnimateOverlayHeight(self, targetH)
    end
    if self.cdLine and self.cdOverlay then
        self.cdLine:Show()
        self.cdLine:ClearAllPoints()
        self.cdLine:SetPoint("TOPLEFT", self.cdOverlay, "TOPLEFT", 0, 0)
        self.cdLine:SetPoint("TOPRIGHT", self.cdOverlay, "TOPRIGHT", 0, 0)
    end

    if self.cdText then
        self.cdText:SetText(tostring(turns))
        self.cdText:Show()
    end

    -- darken + disable during cooldown
    self:SetEnabled(false)
end

--- Set cooldown with both total and remaining turns (for restoring from tracker)
function ActionBarSlot:SetTurnCooldownWithTotal(remaining, total)
    remaining = tonumber(remaining) or 0
    total = tonumber(total) or remaining
    self.cooldown:Clear()

    -- Ensure centered text above overlays
    if not self.cdText then
        local t = self.button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        t:SetDrawLayer("OVERLAY", 8)
        t:SetPoint("CENTER", self.button, "CENTER", 0, 0)
        t:SetJustifyH("CENTER"); t:SetJustifyV("MIDDLE")
        t:SetTextColor(1, 0.85, 0.2, 1)
        self.cdText = t
    end

    local iconTop = self.icon:GetTop() or 0
    local iconBottom = self.icon:GetBottom() or 0
    local fullH = math.max(0, iconTop - iconBottom)

    if remaining <= 0 then
        -- cooldown finished
        self._cdRemain = 0
        self._cdTotal  = nil
        if self.cdText then self.cdText:Hide() end
        if self.cdOverlay then self.cdOverlay:Hide(); self.cdOverlay:SetHeight(0) end
        if self.cdLine then self.cdLine:Hide() end
        self:SetEnabled(true)
        return
    end

    -- Set explicit totals (for restoration from tracker)
    self._cdTotal = total
    self._cdRemain = remaining

    -- calculate target overlay height (bottom anchored, shrinks as turns drop)
    local frac = (self._cdTotal and self._cdTotal > 0) and (remaining / self._cdTotal) or 1
    frac = clamp(frac, 0, 1)
    local targetH = math.floor(fullH * frac + 0.5)

    -- show/update visuals
    if self.cdOverlay then
        self.cdOverlay:Show()
        AnimateOverlayHeight(self, targetH)
    end
    if self.cdLine and self.cdOverlay then
        self.cdLine:Show()
        self.cdLine:ClearAllPoints()
        self.cdLine:SetPoint("TOPLEFT", self.cdOverlay, "TOPLEFT", 0, 0)
        self.cdLine:SetPoint("TOPRIGHT", self.cdOverlay, "TOPRIGHT", 0, 0)
    end

    if self.cdText then
        self.cdText:SetText(tostring(remaining))
        self.cdText:Show()
    end

    -- darken + disable during cooldown
    self:SetEnabled(false)
end

function ActionBarSlot:SetEnabled(enabled)
    enabled = not not enabled
    self.disabledOverlay:SetShown(not enabled)

    if self.button then
        if enabled then
            self.button:Enable()
            if self.icon then self.icon:SetVertexColor(1, 1, 1, 1) end   -- normal
        else
            self.button:Disable()
            if self.icon then self.icon:SetVertexColor(0.35, 0.35, 0.35, 1) end -- darken
        end
    end

    if self.action then self.action.isEnabled = enabled end
end

function ActionBarSlot:Flash(duration)
    if not self.glow then return end
    self.glow:SetAlpha(0.9)
    FadeOutOnce(self.glow, duration or 0.35, 0.9)
end

--- Show the pulsing reaction glow (blue glow indicating spell can be cast as reaction)
function ActionBarSlot:ShowReactionGlow()
    if not self.reactionGlow then return end
    self.reactionGlow:Show()
    self._reactionPulseStart = GetTime()
end

--- Hide the pulsing reaction glow
function ActionBarSlot:HideReactionGlow()
    if not self.reactionGlow then return end
    self.reactionGlow:Hide()
    self._reactionPulseStart = nil
end

--- Set the color of the reaction glow (default: cyan-blue for reactions)
---@param r number Red (0-1)
---@param g number Green (0-1)
---@param b number Blue (0-1)
function ActionBarSlot:SetReactionGlowColor(r, g, b)
    if not self.reactionGlow then return end
    self.reactionGlow:SetVertexColor(r or 0.2, g or 0.8, b or 1)
end

return ActionBarSlot
