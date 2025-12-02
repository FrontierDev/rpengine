-- RPE_UI/Windows/ActionBarWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window        = RPE_UI.Elements.Window
local HGroup        = RPE_UI.Elements.HorizontalLayoutGroup
local FrameElement  = RPE_UI.Elements.FrameElement
local ActionBarSlot = RPE_UI.Prefabs.ActionBarSlot
local C             = RPE_UI.Colors

local SpellRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry

---@class ActionBarWidget
---@field root Window
---@field content HGroup
---@field barHost FrameElement
---@field slots table<number, ActionBarSlot>
---@field actions table<number, table>
---@field cooldownTurns table<number, integer>
---@field chrome Frame
---@field _controlledUnitId integer|nil  -- Unit ID when in temporary action bar mode (controlling another unit)
---@field _originalActions table|nil     -- Saved actions before entering temporary mode
---@field _auraStrip table|nil           -- AuraStripWidget showing buffs/debuffs of controlled unit
local ActionBarWidget = {}
_G.RPE_UI.Windows.ActionBarWidget = ActionBarWidget
ActionBarWidget.__index = ActionBarWidget
ActionBarWidget.Name = "ActionBarWidget"

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.ActionBarWidget = self
end

-- ============ Utilities ============
local function FadeInFrame(frame, duration)
    if not frame then return end
    frame:SetAlpha(0)
    frame:Show()
    UIFrameFadeIn(frame, duration or 0.25, 0, 1)
end

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

-- ============ Slots ============
function ActionBarWidget:_EnsureSlot(index)
    if self.slots[index] and self.slots[index].frame then
        return self.slots[index]
    end
    local slot = ActionBarSlot:New(("RPE_ActionBar_Slot_%d"):format(index), {
        parent = self.barHost,
        size   = self.slotSize,
    })
    slot:_Bind(index, self) -- so onClick gets context
    self.slots[index] = slot
    return slot
end

function ActionBarWidget:_UpdateSlotFromAction(index, action)
    local slot = self:_EnsureSlot(index)
    slot:SetAction(action)

    -- seed turn-based cooldown if provided on action (baked-in from profile)
    -- Note: we don't set cooldowns here if they're not explicitly on the action,
    -- because the Cooldowns system will provide them via RefreshBindingsFor
    local ct = action and tonumber(action.cooldownTurns)
    if ct and ct > 0 then
        self.cooldownTurns[index] = math.floor(ct)
        slot:SetTurnCooldown(self.cooldownTurns[index])
    else
        self.cooldownTurns[index] = 0
        -- Don't call SetTurnCooldown(0) here - let RefreshBindingsFor handle it
    end

    -- Respect explicit disabled state when not on cooldown
    if (self.cooldownTurns[index] or 0) <= 0 then
        local enabled = not (action and action.isEnabled == false)
        slot:SetEnabled(enabled)
    end
end

--- Helper: Get cooldown remaining for a spell, checking related spells and shared groups
local function getSpellCooldownRemaining(CD, casterKey, def, turn)
    if not (CD and def) then return 0 end
    
    local maxRemain = 0
    local maxMaxTurns = 0
    local SR = RPE.Core and RPE.Core.SpellRegistry
    
    -- Check individual spell cooldown
    if def.cooldown then
        local remain = CD:GetRemaining(casterKey, def, turn)
        if remain > maxRemain then 
            maxRemain = remain
            maxMaxTurns = def.cooldown.turns or 0
        end
        
        -- Check all ranks of this spell
        if def.name and SR then
            local allSpells = SR:All()
            for id, spellDef in pairs(allSpells or {}) do
                if spellDef.name == def.name and id ~= def.id and spellDef.cooldown then
                    local rankRemain = CD:GetRemaining(casterKey, spellDef, turn)
                    if rankRemain > maxRemain then
                        maxRemain = rankRemain
                        maxMaxTurns = spellDef.cooldown.turns or 0
                    end
                end
            end
        end
        
        -- Check shared group cooldown if spell is in a group
        local sharedGroup = def.cooldown.sharedGroup
        if sharedGroup and sharedGroup ~= "" then
            local groupDef = {
                id = sharedGroup,
                cooldown = { sharedGroup = sharedGroup, turns = def.cooldown.turns }
            }
            local groupRemain = CD:GetRemaining(casterKey, groupDef, turn)
            if groupRemain > maxRemain then
                maxRemain = groupRemain
                maxMaxTurns = def.cooldown.turns or 0
            end
        end
    end
    
    return maxRemain, maxMaxTurns
end

--- Helper: Get all spell IDs that should be on cooldown when this spell is cast
local function getRelatedSpellIds(spellId)
    local SR = RPE.Core and RPE.Core.SpellRegistry
    if not SR then return {spellId} end
    
    local def = SR:Get(spellId)
    if not def then return {spellId} end
    
    local result = {}
    
    -- Add the spell itself
    table.insert(result, spellId)
    
    -- Add all ranks of this spell (search for spells with same name but different rank)
    if def.name then
        local allSpells = SR:All()
        for id, spellDef in pairs(allSpells or {}) do
            if spellDef.name == def.name and id ~= spellId then
                table.insert(result, id)
            end
        end
    end
    
    return result
end

--- Manually restore cooldowns for slots by looking them up in the Cooldowns system
function ActionBarWidget:RestoreCooldowns(casterKey, turn)
    local CD = RPE.Core and RPE.Core.Cooldowns
    if not CD then return end
    
    turn = tonumber(turn) or 0
    
    for i = 1, self.numSlots do
        local action = self.actions[i]
        if action then
            local spellId = action.spellId or action.id
            if spellId then
                local SR = RPE.Core and RPE.Core.SpellRegistry
                local def = SR and SR:Get(spellId)
                
                if def and def.cooldown then
                    -- Get cooldown remaining (checks individual + all ranks + shared group)
                    local remain, maxTurns = getSpellCooldownRemaining(CD, casterKey, def, turn)
                    self:SetTurnCooldownForSlotWithTotal(i, remain, maxTurns)
                else
                    self:SetTurnCooldownForSlot(i, 0)
                end
            else
                self:SetTurnCooldownForSlot(i, 0)
            end
        else
            self:SetTurnCooldownForSlot(i, 0)
        end
    end
end

--- Set cooldown for a specific slot
function ActionBarWidget:SetTurnCooldownForSlot(index, turns)
    if index < 1 or index > self.numSlots then return end
    local slot = self.slots[index]
    if slot and slot.SetTurnCooldown then
        slot:SetTurnCooldown(turns)
    end
end

--- Set cooldown for a specific slot with total turns (for accurate overlay positioning)
function ActionBarWidget:SetTurnCooldownForSlotWithTotal(index, remaining, total)
    if index < 1 or index > self.numSlots then return end
    local slot = self.slots[index]
    if slot and slot.SetTurnCooldownWithTotal then
        slot:SetTurnCooldownWithTotal(remaining, total)
    end
end

-- ============ Chrome (styled background) ============
function ActionBarWidget:_EnsureChrome()
    if self.chrome and self.chrome:IsObjectType("Frame") then return end
    local parent = self.root and self.root.frame or UIParent
    local f = CreateFrame("Frame", "RPE_ActionBar_Chrome", parent)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((parent:GetFrameLevel() or 0) + 1)
    self.chrome = f

    -- background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    do
        local r,g,b,a = C.Get("background")
        bg:SetColorTexture(r, g, b, clamp((a or 0.95) - 0.15, 0.25, 1))
    end

    -- top divider
    local top = f:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    top:SetHeight(1)
    C.ApplyDivider(top)

    -- bottom divider
    local bot = f:CreateTexture(nil, "BORDER")
    bot:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, -1)
    bot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, -1)
    bot:SetHeight(1)
    local dr,dg,db,da = C.Get("divider")
    bot:SetColorTexture(dr*0.5, dg*0.5, db*0.5, da)

    -- subtle drop shadow below the bar
    local shadow = f:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 4, -4)
    shadow:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -4, -4)
    shadow:SetHeight(4)
    shadow:SetColorTexture(0, 0, 0, 0.25)

    f._bg = bg; f._top = top; f._bot = bot; f._shadow = shadow
end

-- ============ Cooldown API ============
local function defForAction(a)
    if not a then return nil end
    if a.spellId and SpellRegistry and SpellRegistry.Get then
        return SpellRegistry:Get(a.spellId)
    end
    -- TODO: items (when ItemUse exists)
    return nil
end

local function cdKeyForDef(def)
    if not def or not def.cooldown then return nil end
    local cd = def.cooldown
    if cd.sharedGroup and cd.sharedGroup ~= "" then
        return "G:" .. tostring(cd.sharedGroup)
    end
    return "S:" .. tostring(def.id or "?")
end

local function cdKeyForAction(a)
    local def = defForAction(a)
    return cdKeyForDef(def), def
end

--- Update only the slot(s) that match this cooldown key (from Cooldowns:Start)
function ActionBarWidget:ApplyCooldownKey(cdKey, turns)
    if not cdKey then return end
    for i = 1, self.numSlots do
        local a = self.actions[i]
        local aKey = cdKeyForAction(a)
        if aKey == cdKey then
            self:SetTurnCooldown(i, tonumber(turns) or 0)
        end
    end
end

--- Full repaint (from Cooldowns:OnPlayerTickStart)
function ActionBarWidget:RefreshAllCooldowns(casterKey, Cooldowns, turn)
    if not (Cooldowns and Cooldowns.GetRemaining) then return end
    for i = 1, self.numSlots do
        local a = self.actions[i]
        local def = defForAction(a)
        if def and def.cooldown then
            local remain = Cooldowns:GetRemaining(casterKey, def, turn)
            self:SetTurnCooldown(i, remain)
        else
            self:SetTurnCooldown(i, 0)
        end
    end
    
    -- Also refresh requirement states after cooldowns
    self:RefreshRequirements()
end

--- Refresh requirement states for all slots (enable/disable based on current requirements)
function ActionBarWidget:RefreshRequirements()
    local SR = RPE.Core and RPE.Core.SpellRegistry
    local Requirements = RPE.Core and RPE.Core.SpellRequirements
    if not (SR and Requirements) then return end
    
    -- Skip requirement checks if controlling an NPC
    if self._controlledUnitId then
        return
    end
    
    for i = 1, self.numSlots do
        local a = self.actions[i]
        if a and a.spellId then
            local slot = self.slots[i]
            if slot then
                -- Check if spell requirements are met
                local spell = SR:Get(a.spellId)
                if spell and spell.requirements and #spell.requirements > 0 then
                    local ctx = {}
                    local allMet = true
                    for _, req in ipairs(spell.requirements) do
                        local ok = Requirements:EvalRequirement(ctx, req)
                        if not ok then
                            allMet = false
                            break
                        end
                    end
                    
                    -- If on cooldown, stay disabled; otherwise enable/disable based on requirements
                    if (self.cooldownTurns[i] or 0) <= 0 then
                        slot:SetEnabled(allMet)
                    end
                end
            end
        end
    end
end

--- Start/set a turn-based cooldown on a slot (turns <= 0 clears it)
function ActionBarWidget:SetTurnCooldown(index, turns)
    if index < 1 or index > self.numSlots then return end
    turns = math.max(0, math.floor(tonumber(turns) or 0))
    self.cooldownTurns = self.cooldownTurns or {}
    self.cooldownTurns[index] = turns

    local slot = self.slots[index]
    if slot and slot.SetTurnCooldown then
        slot:SetTurnCooldown(turns) -- slot shows number + handles enable/darken
    end
end

--- Decrement all active slot cooldowns by 1 (call this once each new turn if you use widget-side ticking)
function ActionBarWidget:OnNewTurn()
    for i = 1, self.numSlots do
        local remain = self.cooldownTurns[i] or 0
        if remain > 0 then
            remain = remain - 1
            self.cooldownTurns[i] = remain

            local slot = self.slots[i]
            if slot and slot.SetTurnCooldown then
                slot:SetTurnCooldown(remain)
                if remain <= 0 then slot:Flash(0.35) end
            end
        end
    end
    
    -- Refresh requirement states each turn
    self:RefreshRequirements()
end

--- Enable/Disable a slot (independent of turn cooldown)
function ActionBarWidget:SetEnabled(index, enabled)
    local slot = self.slots[index]
    if not slot then return end
    if (self.cooldownTurns[index] or 0) > 0 then
        slot:SetEnabled(false)
    else
        slot:SetEnabled(enabled and true or false)
    end
    if self.actions[index] then
        self.actions[index].isEnabled = enabled and true or false
    end
end

--- Flash/Glow a slot briefly
function ActionBarWidget:FlashSlot(index, duration)
    local slot = self.slots[index]
    if not slot then return end
    slot:Flash(duration or 0.35)
end

--- Clear all slots
function ActionBarWidget:Clear()
    for i = 1, self.numSlots do
        local slot = self.slots[i]
        if slot then
            slot:Clear()
            slot:SetEnabled(true)
        end
        self.cooldownTurns[i] = 0
    end
end

-- ============ Public API ============
--- Build the widget UI
---@param opts { name?:string, numSlots?:number, slotSize?:number, spacing?:number, point?:string, rel?:string, x?:number, y?:number, padX?:number, padY?:number }
function ActionBarWidget:BuildUI(opts)
    opts = opts or {}
    self.name      = opts.name or "Action Bar"
    self.numSlots  = tonumber(opts.numSlots) or 8
    self.slotSize  = tonumber(opts.slotSize) or 40
    self.spacing   = tonumber(opts.spacing) or 6
    self.padX      = tonumber(opts.padX) or 12
    self.padY      = tonumber(opts.padY) or 10

    -- Root window (Alt+Z-safe when ImmersionMode is enabled)
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_ActionBar_Window", {
        parent = parentFrame,
        width  = 1, height = 1,
        autoSize = true,
        noBackground = true,
        point  = opts.point or "BOTTOM",
        pointRelative = opts.rel or "BOTTOM",
        x = opts.x or 0,
        y = opts.y or 120,
    })

    -- Immersion polish (match UI scale + mouse gating on Alt+Z)
    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale() f:SetScale(UIParent and UIParent:GetScale() or 1) end
        local function UpdateMouseForUIVisibility() f:EnableMouse(UIParent and UIParent:IsShown()) end
        SyncScale(); UpdateMouseForUIVisibility()
        UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
        UIParent:HookScript("OnHide", function() UpdateMouseForUIVisibility() end)

        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Content container
    self.content = HGroup:New("RPE_ActionBar_Content", {
        parent   = self.root,
        autoSize = true,
        spacingX = self.spacing,
        alignV   = "CENTER",
    })
    self.root:Add(self.content)

    -- Stable host frame for slots (never destroyed; slots are reused)
    self.barHostFrame = CreateFrame("Frame", "RPE_ActionBar_Host", self.content.frame)
    self.barHostFrame:SetAllPoints(self.content.frame)
    self.barHost = FrameElement:New("ActionBarHost", self.barHostFrame, self.content)

    -- Temporary action bar row (for controlling NPCs) - layout group with all control buttons
    local HGroup = RPE_UI.Elements.HorizontalLayoutGroup
    self.tempActionRow = HGroup:New("RPE_ActionBar_TempRow", {
        parent = UIParent,
        autoSize = true,
        spacingX = self.spacing,
        alignV = "CENTER",
    })
    self.tempActionRow.frame:ClearAllPoints()
    self.tempActionRow.frame:SetPoint("TOP", self.barHost.frame, "BOTTOM", 0, -12)
    self.tempActionRow:Hide()

    -- Previous unit button
    local IconBtn = RPE_UI.Elements.IconButton
    self.prevUnitBtn = IconBtn:New("RPE_ActionBar_PrevUnit", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\arrow_left.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Previous Unit",
        onClick = function()
            self:_CycleUnit(-1)
        end,
    })
    self.tempActionRow:Add(self.prevUnitBtn)

    -- Speak button
    self.speakBtn = IconBtn:New("RPE_ActionBar_Speak", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\talk.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Speak as Controlled Unit",
        onClick = function()
            self:_ShowSpeakDialog()
        end,
    })
    self.tempActionRow:Add(self.speakBtn)

    -- Kill/Resurrect button
    self.killResBtn = IconBtn:New("RPE_ActionBar_KillRes", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\raise-dead.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Kill / Resurrect",
        onClick = function()
            self:_KillOrResurrect()
        end,
    })
    self.tempActionRow:Add(self.killResBtn)

    -- Set Health button
    self.setHealthBtn = IconBtn:New("RPE_ActionBar_SetHealth", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\reputation.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Set Health",
        onClick = function()
            self:_ShowSetHealthDialog()
        end,
    })
    self.tempActionRow:Add(self.setHealthBtn)

    -- Toggle Active button
    self.toggleActiveBtn = IconBtn:New("RPE_ActionBar_ToggleActive", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\check.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Toggle Active\nInactive units do not appear in the turn order.",
        onClick = function()
            self:_ToggleUnitFlag("active")
        end,
    })
    self.tempActionRow:Add(self.toggleActiveBtn)

    -- Toggle Hidden button
    self.toggleHiddenBtn = IconBtn:New("RPE_ActionBar_ToggleHidden", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\hidden.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Toggle Hidden\nHidden units cannot be targeted until they are revealed.",
        onClick = function()
            self:_ToggleUnitFlag("hidden")
        end,
    })
    self.tempActionRow:Add(self.toggleHiddenBtn)

    -- Toggle Flying button
    self.toggleFlyingBtn = IconBtn:New("RPE_ActionBar_ToggleFlying", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\flying.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Toggle Flying\nFlying units cannot be targeted by melee attacks.",
        onClick = function()
            self:_ToggleUnitFlag("flying")
        end,
    })
    self.tempActionRow:Add(self.toggleFlyingBtn)

    -- Store flag button mapping for easy access
    self.flagButtons = {
        active = self.toggleActiveBtn,
        hidden = self.toggleHiddenBtn,
        flying = self.toggleFlyingBtn,
    }

    -- Next unit button
    self.nextUnitBtn = IconBtn:New("RPE_ActionBar_NextUnit", {
        parent = self.tempActionRow,
        width  = 16,
        height = 16,
        icon   = "Interface\\Addons\\RPEngine\\UI\\Textures\\arrow_right.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Next Unit",
        onClick = function()
            self:_CycleUnit(1)
        end,
    })
    self.tempActionRow:Add(self.nextUnitBtn)

    -- Exit button (separate from temp row, positioned to left of action bar)
    self.exitTempBtn = IconBtn:New("RPE_ActionBar_ExitTemp", {
        parent = UIParent,
        width  = 16,
        height = 16,
        icon   = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", -- a clear cancel icon
        noBackground = true, noBorder = true,
        hasBackground = false, hasBorder = false,
        tooltip = "End Unit Control",
        onClick = function()
            self:RestoreActions()
            self.tempActionRow:Hide()
            self.exitTempBtn:Hide()
        end,
    })
    self.exitTempBtn:Hide()

    -- Styled chrome behind the bar
    self:_EnsureChrome()

    -- Data caches
    self.slots          = {}
    self.actions        = {}
    self.cooldownTurns  = {}

    -- Pre-create slots
    for i = 1, self.numSlots do
        local slot = self:_EnsureSlot(i)
        slot.button:ClearAllPoints()
    end

    self:Layout()
    FadeInFrame(self.chrome, 0.25)
    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

--- Position chrome + slots centered with fixed spacing
function ActionBarWidget:Layout()
    local n    = self.numSlots
    local size = self.slotSize
    local gap  = self.spacing

    local totalW = n * size + (n - 1) * gap
    local totalH = size

    -- Position slots
    local startX = -totalW / 2 + size / 2
    for i = 1, n do
        local slot = self:_EnsureSlot(i)
        slot.button:ClearAllPoints()
        slot.button:SetPoint("CENTER", self.barHost.frame, "CENTER", startX + (i - 1) * (size + gap), 0)
        slot:SetSlotSize(size)
        slot:Show()
    end

    -- Position the exit button just to the left of the first slot
    if self.exitTempBtn and self.slots[1] and self.slots[1].button then
        self.exitTempBtn.frame:ClearAllPoints()
        self.exitTempBtn.frame:SetPoint("RIGHT", self.slots[1].button, "LEFT", -8, 0)
    end

    -- Size & position chrome to wrap the bar with padding
    self:_EnsureChrome()
    local padX, padY = self.padX, self.padY
    self.chrome:ClearAllPoints()
    self.chrome:SetPoint("CENTER", self.barHost.frame, "CENTER", 0, 0)
    self.chrome:SetSize(totalW + padX * 2, totalH + padY * 2)
end

--- Define actions for each slot.
-- actions[i] = { icon, name, tooltip, isEnabled=true/false, cooldownTurns=integer }
function ActionBarWidget:SetActions(actions)
    self.actions = actions or {}
    for i = 1, self.numSlots do
        self:_UpdateSlotFromAction(i, self.actions[i])
    end
    
    -- Refresh requirement states after setting actions
    self:RefreshRequirements()
end

--- Update a single slot action
function ActionBarWidget:SetAction(index, action)
    if index < 1 or index > self.numSlots then return end
    self.actions[index] = action
    self:_UpdateSlotFromAction(index, action)
    
    -- Refresh requirement state for this slot
    self:RefreshRequirements()
end

function ActionBarWidget:LoadFromProfile(profile)
    if not profile or not profile.actionBar then return end

    local SR = RPE.Core and RPE.Core.SpellRegistry
    if not SR then return end

    local cleaned = false

    for index, bind in pairs(profile.actionBar) do
        local spell = SR:Get(bind.spellId)
        if spell then
            local icon = spell.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
            self:SetAction(index, {
                spellId = bind.spellId,
                rank    = bind.rank,
                icon    = icon,
                isEnabled = true,
            })
        else
            -- Spell no longer exists — clear it from the profile and bar
            profile.actionBar[index] = nil
            local slot = self.slots[index]
            if slot and slot.Clear then slot:Clear() end
            cleaned = true
        end
    end

    -- Persist cleanup if invalid bindings were removed
    if cleaned and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
        RPE.Profile.DB.SaveProfile(profile)
    end
end

-- ============ Temporary Actions ============
--- Override the action bar with a temporary set of actions (e.g. for target unit).
---@param actions table<number, table> Action definitions for each slot
---@param label string|nil Optional label to show (not implemented here)
---@param tintColor table|nil Optional color override for chrome bg: {r,g,b,a}
---@param controlledUnitId integer|nil Unit ID of the controlled unit (for multi-unit casting)
---@param controlledUnitName string|nil Name of the controlled unit (for speak dialog)
function ActionBarWidget:SetTemporaryActions(actions, label, tintColor, controlledUnitId, controlledUnitName)
    self._originalActions = self.actions or {}
    
    -- Save the current cast bar state before switching (in case player was casting)
    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    if CB then
        self._originalCastBarCast = CB.currentCast
    end
    
    -- Store the controlled unit ID and name for spell casting and speaking
    self._controlledUnitId = tonumber(controlledUnitId)
    self._controlledUnitName = tostring(controlledUnitName or "NPC")
    
    -- Bind action bar cooldowns to the controlled unit's caster key
    if self._controlledUnitId then
        local CD = RPE.Core and RPE.Core.Cooldowns
        if CD and CD.BindActionBar then
            CD:BindActionBar(tostring(self._controlledUnitId), self)
        end
    end

    -- Set new temporary actions
    self:SetActions(actions or {})
    
    -- Now restore cooldown display after actions are set
    if self._controlledUnitId then
        local CD = RPE.Core and RPE.Core.Cooldowns
        local event = RPE.Core.ActiveEvent
        if CD and event then
            self:RestoreCooldowns(tostring(self._controlledUnitId), event.turn or 0)
        end
    end

    -- Only show temp action row if player is a supergroup leader
    if self.tempActionRow then
        local isLeader = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()
        if isLeader then
            self.tempActionRow:Show()
            
            -- Reparent to WorldFrame if in immersion mode (UIParent is hidden)
            local isImmersion = RPE.Core and RPE.Core.ImmersionMode
            if isImmersion and self.tempActionRow.frame:GetParent() ~= WorldFrame then
                self.tempActionRow.frame:SetParent(WorldFrame)
            end
        else
            self.tempActionRow:Hide()
        end
    end
    
    if self.exitTempBtn then
        self.exitTempBtn:Show()
        
        -- Reparent to WorldFrame if in immersion mode (UIParent is hidden)
        local isImmersion = RPE.Core and RPE.Core.ImmersionMode
        if isImmersion and self.exitTempBtn.frame:GetParent() ~= WorldFrame then
            self.exitTempBtn.frame:SetParent(WorldFrame)
        end
        
        self.exitTempBtn.frame:ClearAllPoints()
        self.exitTempBtn.frame:SetPoint("RIGHT", self.slots[1].button, "LEFT", -8, 0)
    end

    -- Set initial flag button colors based on the controlled unit
    local unit = RPE.Common:FindUnitById(self._controlledUnitId)
    if unit then
        self:_UpdateFlagButtonColors(unit)
        self:_UpdateKillResButtonIcon(unit)
    end

    -- Update navigation button states based on available units
    self:_UpdateNavigationButtonStates()

    -- Optional: update chrome background tint
    if self.chrome and self.chrome._bg and tintColor then
        self.chrome._bg:SetColorTexture(tintColor[1], tintColor[2], tintColor[3], tintColor[4] or 1.0)
    end

    -- Optional: show label (e.g. unit name) if desired
    -- You could implement a floating text object here if needed
end

--- Show a dialog to speak as the controlled NPC unit
function ActionBarWidget:_ShowSpeakDialog()
    local Popup = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    if not Popup or not Popup.New then
        return
    end
    
    local unitName = self._controlledUnitName or "NPC"
    
    -- Create popup with proper parent for Immersion mode
    local isImmersion = RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = isImmersion and WorldFrame or UIParent
    
    local p = Popup.New({
        title        = "Speaking as " .. unitName,
        text         = "Enter message:",
        showInput    = true,
        defaultText  = "",
        primaryText  = "OK",
        secondaryText= "Cancel",
        parentFrame  = parentFrame,
    })
    
    p:SetCallbacks(
        function(message)
            if message and message ~= "" then
                self:_BroadcastNPCMessage(message)
            end
        end,
        function() end
    )
    p:Show()
end

--- Broadcast an NPC message to the group
function ActionBarWidget:_BroadcastNPCMessage(message)
    local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if not Broadcast or not Broadcast.SendNPCMessage then
        return
    end
    
    if not self._controlledUnitId or not self._controlledUnitName then
        return
    end
    
    Broadcast:SendNPCMessage(self._controlledUnitId, self._controlledUnitName, message)
end

--- Restore the previously saved actions (typically the local player's)
function ActionBarWidget:RestoreActions()
    -- Reset the cached active profile to force reload of player profile
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.ResetActiveInstance then
        RPE.Profile.DB.ResetActiveInstance()
    end
    
    -- Unbind from the NPC's cooldown key if we were controlling one
    if self._controlledUnitId then
        local CD = RPE.Core and RPE.Core.Cooldowns
        if CD and CD.UnbindActionBar then
            CD:UnbindActionBar(self)
        end
    end
    
    -- Rebind to the player's cooldown key
    local CD = RPE.Core and RPE.Core.Cooldowns
    local event = RPE.Core.ActiveEvent
    local playerNumericId = nil
    if CD and event and event.localPlayerKey then
        local playerUnit = event.units and event.units[event.localPlayerKey]
        playerNumericId = playerUnit and playerUnit.id
        if playerNumericId then
            CD:BindActionBar(tostring(playerNumericId), self)
        end
    end
    
    -- Restore original actions if available
    if self._originalActions then
        self:SetActions(self._originalActions)
        self._originalActions = nil
    end
    
    -- Manually restore cooldowns from the Cooldowns tracker
    if playerNumericId and CD then
        self:RestoreCooldowns(tostring(playerNumericId), (event and event.turn) or 0)
    end
    
    -- Restore the cast bar to show the player's cast (if any)
    -- When we exit temp mode, we need to show the player's actual cast, not the NPC's cast
    local event = RPE.Core.ActiveEvent
    
    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    
    if event and CB then
        local playerUnitId = event:GetLocalPlayerUnitId()
        
        local playerCast = playerUnitId and event._activeCasts and event._activeCasts[playerUnitId]
        
        -- Check if player has an active cast that's not yet complete
        local hasActiveCast = playerCast and playerCast.remainingTurns and playerCast.remainingTurns > 0
        
        if hasActiveCast then
            -- Player has an ACTIVE cast, show it
            CB.currentCast = playerCast
            
            -- Update the cast bar display
            local ct = (playerCast.def and playerCast.def.cast) or { type = "INSTANT" }
            CB.castType = ct.type or "INSTANT"
            CB.totalTurns = tonumber(ct.turns) or 0
            
            if CB.icon and CB.icon.SetIcon then
                CB.icon:SetIcon((playerCast.def and playerCast.def.icon) or 135274)
            end
            
            if CB.castType == "INSTANT" then
                CB.bar:SetValue(1, 1)
                CB:Show()
            else
                -- Show the player's cast bar with current progress
                local total = (CB.totalTurns > 0) and CB.totalTurns or 1
                local remaining = playerCast.remainingTurns or total
                local done = math.max(0, total - remaining)
                CB.bar:SetValue(done, total)
                CB:Show()
            end
        else
            -- Player has no active cast (either no cast, or cast is complete)
            CB:ImmediateHide()
        end
    else
        if CB then
            CB:ImmediateHide()
        end
    end
    
    -- Clear controlled unit ID
    self._controlledUnitId = nil
    
    -- Clear the saved original cast state
    self._originalCastBarCast = nil

    -- Reset chrome background to default palette
    if self.chrome and self.chrome._bg then
        local r,g,b,a = RPE_UI.Colors.Get("background")
        self.chrome._bg:SetColorTexture(r, g, b, math.max(0.25, (a or 1) - 0.15))
    end

    if self.exitTempBtn then
        self.exitTempBtn:Hide()
    end

    local PUW = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
    if PUW then
        PUW:RestoreStats()
    end
end

-- ============ Boilerplate ============
function ActionBarWidget.New(opts)
    local self = setmetatable({}, ActionBarWidget)
    self:BuildUI(opts or {})
    return self
end

function ActionBarWidget:Show()
    if self.chrome then FadeInFrame(self.chrome, 0.2) end
    if self.root and self.root.Show then self.root:Show() end
end

function ActionBarWidget:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
end

--- Cycle to the next or previous unit in the event widget
function ActionBarWidget:_CycleUnit(direction)
    local event = RPE.Core.ActiveEvent
    if not event then return end
    
    -- Get NPCs from current batch/tick, or fall back to all active NPCs if ticks not ready
    local units = {}
    if event.ticks and event.tickIndex and event.ticks[event.tickIndex] then
        local currentTick = event.ticks[event.tickIndex]
        for _, u in ipairs(currentTick) do
            if u.isNPC then
                table.insert(units, u)
            end
        end
    end
    
    -- Fallback: use all active NPCs if no batch/tick available (event startup)
    if #units == 0 and event.units then
        for _, u in pairs(event.units) do
            if u.isNPC and u.active then
                table.insert(units, u)
            end
        end
    end
    
    if #units < 2 then
        -- Even if we can't cycle, update button states to show disabled state
        self:_UpdateNavigationButtonStates()
        return
    end
    
    -- Find current unit in list
    local currentIdx = nil
    for i, u in ipairs(units) do
        if tonumber(u.id) == self._controlledUnitId then
            currentIdx = i
            break
        end
    end
    
    -- Calculate next index WITHOUT wrapping
    if not currentIdx then
        currentIdx = 1
    else
        currentIdx = currentIdx + direction
    end
    
    -- Check bounds - don't wrap, just clamp
    if currentIdx < 1 or currentIdx > #units then
        -- Can't cycle in this direction, but update button states
        self:_UpdateNavigationButtonStates()
        return
    end
    
    -- Switch control to new unit
    local newUnit = units[currentIdx]
    if newUnit then
        -- Convert spell IDs to action objects
        local actions = {}
        if newUnit.spells and type(newUnit.spells) == "table" then
            local SR = RPE.Core and RPE.Core.SpellRegistry
            for i, spellId in ipairs(newUnit.spells) do
                local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
                local tooltip = spellId
                if SR then
                    local def = SR:Get(spellId)
                    if def then
                        icon = def.icon or icon
                        tooltip = (def.name or spellId)
                        if def.description and def.description ~= "" then
                            tooltip = tooltip .. "\n" .. def.description
                        end
                    end
                end
                actions[i] = {
                    spellId = spellId,
                    icon = icon,
                    tooltip = tooltip,
                    isEnabled = true,
                }
            end
        end
        self:SetTemporaryActions(actions, nil, nil, newUnit.id, newUnit.name)
        self:_UpdateFlagButtonColors(newUnit)
        self:_UpdateKillResButtonIcon(newUnit)
        self:_UpdateNavigationButtonStates()
        
        -- Update PlayerUnitWidget with the new controlled unit's stats
        local PUW = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
        if PUW then
            PUW:SetTemporaryStats(newUnit)
        end
        
        -- Refresh cast bar and unit frames to show the controlled unit
        local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
        if CB and CB.Refresh then
            CB:Refresh()
        end
        
        local UFW = RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget
        if UFW and UFW.Refresh then
            UFW:Refresh(true)
        end
    end
end

--- Kill or resurrect the controlled unit
function ActionBarWidget:_KillOrResurrect()
    if not self._controlledUnitId then return end
    
    local unit = RPE.Common:FindUnitById(self._controlledUnitId)
    if not unit then return end
    
    if unit.hp > 0 then
        -- Kill the unit
        unit.hp = 0
    else
        -- Resurrect the unit
        unit.hpMax = unit.hpMax or 10
        unit.hp = unit.hpMax
    end
    
    -- Update button icon based on new state
    self:_UpdateKillResButtonIcon(unit)
    
    -- Broadcast the health change
    local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.UpdateUnitHealth then
        Broadcast:UpdateUnitHealth(unit.id, unit.hp, unit.hpMax)
    end
end

--- Update the kill/resurrect button icon based on unit's current health
function ActionBarWidget:_UpdateKillResButtonIcon(unit)
    if not self.killResBtn then return end
    
    if unit.hp <= 0 then
        -- Dead -> show resurrect icon
        self.killResBtn:SetIcon("Interface\\Addons\\RPEngine\\UI\\Textures\\raise-dead.png")
        self.killResBtn:SetTooltip("Resurrect\nRestore this unit's health to full.")
    else
        -- Alive -> show kill icon (skull)
        self.killResBtn:SetIcon("Interface\\Addons\\RPEngine\\UI\\Textures\\salvage.png")
        self.killResBtn:SetTooltip("Kill\nSet this unit's health to 0.")
    end
end

--- Show a dialog to set the controlled unit's health
function ActionBarWidget:_ShowSetHealthDialog()
    local Popup = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    if not Popup or not Popup.New then
        return
    end
    
    if not self._controlledUnitId then
        return
    end
    
    local unit = RPE.Common:FindUnitById(self._controlledUnitId)
    if not unit then
        return
    end
    
    local isImmersion = RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = isImmersion and WorldFrame or UIParent
    
    local unitId = unit.id
    local hpMax = unit.hpMax or 10
    local currentHp = unit.hp or 0
    
    local function updateText(newHp)
        local delta = newHp - currentHp
        local deltaStr = ""
        if delta > 0 then
            deltaStr = string.format(" |cff00ff00(+%d)|r", delta)
        elseif delta < 0 then
            deltaStr = string.format(" |cffff0000(-%d)|r", -delta)
        end
        return ("Enter HP (0-%d):%s"):format(hpMax, deltaStr)
    end
    
    local Common = RPE and RPE.Common
    local displayName = Common and Common.FormatUnitName and Common:FormatUnitName(unit) or unit.name or "Unit"
    local p = Popup.New({
        title        = "Set Health for " .. displayName,
        text         = updateText(currentHp),
        showInput    = true,
        defaultText  = tostring(currentHp),
        primaryText  = "OK",
        secondaryText= "Cancel",
        parentFrame  = parentFrame,
    })
    
    -- Hook input changes to update the text showing HP delta
    p:SetInputChanged(function(newHpStr)
        local newHp = tonumber(newHpStr) or currentHp
        newHp = math.max(0, math.min(newHp, hpMax))
        
        -- Update the popup text to show delta
        if p and p.SetText then
            p:SetText(updateText(newHp))
        end
    end)
    
    p:SetCallbacks(
        function(value)
            local u = RPE.Common:FindUnitById(unitId)
            if u then
                local hp = tonumber(value) or 0
                u.hpMax = u.hpMax or 10
                u.hp = math.max(0, math.min(hp, u.hpMax))
                
                local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                if Broadcast and Broadcast.UpdateUnitHealth then
                    Broadcast:UpdateUnitHealth(u.id, u.hp, u.hpMax)
                end
            end
        end,
        function() end
    )
    p:Show()
end

--- Update flag button colors based on unit's current flag states
function ActionBarWidget:_UpdateFlagButtonColors(unit)
    if not unit then return end
    
    for flagName, btn in pairs(self.flagButtons or {}) do
        if btn and btn.SetColor then
            local r, g, b
            if unit[flagName] then
                r, g, b = RPE_UI.Colors.Get("textBonus")
            else
                r, g, b = RPE_UI.Colors.Get("textMalus")
            end
            -- Set base color
            btn:SetColor(r, g, b, 1)
            
            -- Set hover color (slightly darker)
            local hoverR = r * 0.7
            local hoverG = g * 0.7
            local hoverB = b * 0.7
            btn._hoverR = hoverR
            btn._hoverG = hoverG
            btn._hoverB = hoverB
        end
    end
end

--- Update navigation button states (lock/unlock/color based on available units)
function ActionBarWidget:_UpdateNavigationButtonStates()
    local event = RPE.Core.ActiveEvent
    if not event then return end
    
    -- Get NPCs from current batch/tick, or fall back to all active NPCs if ticks not ready
    local units = {}
    if event.ticks and event.tickIndex and event.ticks[event.tickIndex] then
        local currentTick = event.ticks[event.tickIndex]
        for _, u in ipairs(currentTick) do
            if u.isNPC then
                table.insert(units, u)
            end
        end
    end
    
    -- Fallback: use all active NPCs if no batch/tick available (event startup)
    if #units == 0 and event.units then
        for _, u in pairs(event.units) do
            if u.isNPC and u.active then
                table.insert(units, u)
            end
        end
    end
    
    -- Find current unit index
    local currentIdx = nil
    for i, u in ipairs(units) do
        if tonumber(u.id) == self._controlledUnitId then
            currentIdx = i
            break
        end
    end
    
    if not currentIdx then currentIdx = 1 end
    
    -- Check if we can go previous (idx > 1)
    local canGoPrev = currentIdx > 1
    if self.prevUnitBtn then
        if canGoPrev then
            self.prevUnitBtn:Unlock()
            local r, g, b = RPE_UI.Colors.Get("textBonus")
            self.prevUnitBtn:SetColor(r, g, b, 1)
            self.prevUnitBtn._hoverR = r * 0.7
            self.prevUnitBtn._hoverG = g * 0.7
            self.prevUnitBtn._hoverB = b * 0.7
        else
            self.prevUnitBtn:Lock()
            self.prevUnitBtn:SetColor(0, 0, 0, 0.4)  -- Translucent black
            self.prevUnitBtn._hoverR = 0
            self.prevUnitBtn._hoverG = 0
            self.prevUnitBtn._hoverB = 0
        end
    end
    
    -- Check if we can go next (idx < #units)
    local canGoNext = currentIdx < #units
    if self.nextUnitBtn then
        if canGoNext then
            self.nextUnitBtn:Unlock()
            local r, g, b = RPE_UI.Colors.Get("textBonus")
            self.nextUnitBtn:SetColor(r, g, b, 1)
            self.nextUnitBtn._hoverR = r * 0.7
            self.nextUnitBtn._hoverG = g * 0.7
            self.nextUnitBtn._hoverB = b * 0.7
        else
            self.nextUnitBtn:Lock()
            self.nextUnitBtn:SetColor(0, 0, 0, 0.4)  -- Translucent black
            self.nextUnitBtn._hoverR = 0
            self.nextUnitBtn._hoverG = 0
            self.nextUnitBtn._hoverB = 0
        end
    end
end

--- Toggle a unit flag (active, hidden, flying)
function ActionBarWidget:_ToggleUnitFlag(flag)
    if not self._controlledUnitId then return end
    
    local unit = RPE.Common:FindUnitById(self._controlledUnitId)
    if not unit then return end
    
    unit[flag] = not unit[flag]
    local Common = RPE and RPE.Common
    local displayName = Common and Common.FormatUnitName and Common:FormatUnitName(unit) or unit.name
    RPE.Debug:Internal(("Toggled unit %s flag %s to %s"):format(displayName, flag, tostring(unit[flag])))
    
    -- Update the corresponding button with color feedback
    local btn = self.flagButtons and self.flagButtons[flag]
    if btn and btn.SetColor then
        local r, g, b
        if unit[flag] then
            r, g, b = RPE_UI.Colors.Get("textBonus")
        else
            r, g, b = RPE_UI.Colors.Get("textMalus")
        end
        btn:SetColor(r, g, b, 1)
    end
    
    -- Refresh EventUnitsSheet if it exists
    local EUS = RPE_UI.Windows.EventUnitsSheetInstance
    if EUS and EUS.Refresh then
        EUS:Refresh()
    end
end

return ActionBarWidget
