-- RPE_UI/Windows/EventWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window       = RPE_UI.Elements.Window
local Panel        = RPE_UI.Elements.Panel
local TextBtn      = RPE_UI.Elements.TextButton
local HBorder      = RPE_UI.Elements.HorizontalBorder
local VGroup       = RPE_UI.Elements.VerticalLayoutGroup
local HGroup       = RPE_UI.Elements.HorizontalLayoutGroup
local Text         = RPE_UI.Elements.Text
local FrameElement = RPE_UI.Elements.FrameElement

local ProgressBar  = RPE_UI.Prefabs.ProgressBar
local PowerBalance = RPE_UI.Prefabs.PowerBalance
local C            = RPE_UI.Colors

---@class EventWidget
---@field root Window
---@field content VGroup
---@field header HGroup
---@field progressGroup HGroup
---@field balanceBar PowerBalance
local EventWidget = {}
_G.RPE_UI.Windows.EventWidget = EventWidget
EventWidget.__index = EventWidget
EventWidget.Name = "EventWidget"

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.EventWidget = self
end

-- helper: fade in a frame, then run callback
local function FadeInFrame(frame, duration, callback)
    if not frame then return end  -- 🔒 guard
    frame:SetAlpha(0)
    frame:Show()
    UIFrameFadeIn(frame, duration or 0.5, 0, 1)
    C_Timer.After(duration or 0.5, function()
        if frame and frame:IsShown() and callback then
            callback()
        elseif callback and not frame then
            -- frame disappeared before fade completed, still call callback safely
            callback()
        end
    end)
end

-- Ensure (or create) a reusable portrait for a given unit.
function EventWidget:_EnsurePortrait(unit)
    if not (unit and unit.key) then return nil end

    local p = self.portraitsByKey[unit.key]
    if not p or not p.frame then
        -- Create once under the stable host element, passing noHealthBar flag for non-combat
        p = unit:CreatePortrait(self.portraitHost, self.portraitSize, self.portraitNoHealthBar)
        self.portraitsByKey[unit.key] = p
    else
        -- Ensure it stays parented to the stable host (belt & braces)
        if p.parent ~= self.portraitHost then
            p:SetParent(self.portraitHost)
        end
    end
    return p
end

-- Lay out a linear row of portraits centered inside the host.
function EventWidget:_LayoutPortraits(list)
    local n = #list
    if n == 0 then return end

    local size = self.portraitSize
    local gap  = self.portraitGap
    local totalW = n * size + (n - 1) * gap
    local startX = -totalW / 2 + size / 2

    for i, unit in ipairs(list) do
        local p = self.portraitsByKey[unit.key]
        if p and p.frame then
            p:ClearAllPoints()
            p:SetPoint("TOP", self.portraitHost.frame, "TOP", startX + (i - 1) * (size + gap), 0)
        end
    end
end

-- Show exactly the given units (array) in order; hide all others. Optional fade.
function EventWidget:_ShowUnits(units, doFade)
    -- Cancel any pending fade timers from previous ShowUnits calls
    if self._fadeTimers then
        for _, timerId in ipairs(self._fadeTimers) do
            C_Timer.Cancel(timerId)
        end
    end
    self._fadeTimers = {}

    -- Mark who should be shown
    local showSet = {}
    for _, u in ipairs(units) do showSet[u.key] = true end

    -- 1) Hide ALL portrait frames that should NOT be shown
    -- First, iterate through ALL children in portraitHostFrame and hide non-matching ones
    if self.portraitHostFrame then
        local numChildren = self.portraitHostFrame:GetNumChildren()
        for i = 1, numChildren do
            local child = select(i, self.portraitHostFrame:GetChildren())
            if child then
                -- Check if this child belongs to a unit we should show
                local shouldHide = true
                for key, p in pairs(self.portraitsByKey or {}) do
                    if p and p.frame == child and showSet[key] then
                        shouldHide = false
                        break
                    end
                end
                
                if shouldHide then
                    child:SetAlpha(1)
                    child:Hide()
                    child:ClearAllPoints()
                    -- Also explicitly hide the model and texture inside
                    if child.model then child.model:Hide() end
                    if child.texture then child.texture:Hide() end
                end
            end
        end
    end
    
    -- Clean up cache entries for portraits that shouldn't be shown
    for key in pairs(self.portraitsByKey or {}) do
        if not showSet[key] then
            self.portraitsByKey[key] = nil
        end
    end

    -- 2) Ensure portraits for the listed units exist and update their state
    for _, u in ipairs(units) do
        local p = self:_EnsurePortrait(u)
        if p then
            p.frame:SetAlpha(1)  -- Reset alpha before showing
            p:Show()  -- Show early so fade-in works
            
            -- Always update health (in case it changed)
            if p.SetHealth then p:SetHealth(u.hp, u.hpMax) end
            
            -- Update absorption shields
            if p.SetAbsorption then
                local totalAbsorption = 0
                if u.absorption then
                    for _, shield in pairs(u.absorption) do
                        if shield.amount then
                            totalAbsorption = totalAbsorption + shield.amount
                        end
                    end
                end
                p:SetAbsorption(totalAbsorption)
            end
            
            if p.ApplyRaidMarker then p:ApplyRaidMarker() end
            if p.ApplyTeamColor then p:ApplyTeamColor() end
            if p.Refresh then p:Refresh() end
        end
    end

    -- 3) Layout & fade in (with optional staggered fade)
    self:_LayoutPortraits(units)
    for i, u in ipairs(units) do
        local p = self.portraitsByKey[u.key]
        if p and p.frame then
            if doFade then
                p.frame:SetAlpha(0)  -- Set to transparent
                local timerId = C_Timer.After((i - 1) * 0.15, function()
                    FadeInFrame(p.frame, 0.3)
                end)
                table.insert(self._fadeTimers, timerId)
            end
        end
    end
end

function EventWidget:BuildUI(opts)
    self.data = {}
    self.data.eventName = opts.name
    self.data.eventSubtext = opts.eventSubtext
    self.data.difficulty = opts.difficulty
    self.data.showTurnProgress = opts.showTurnProgress or false
    self.data.turnNumber = opts.turnNumber or 1
    self.data.isNonCombat = opts.isNonCombat or false

    -- Root window
    self.root = Window:New("RPE_EventWidget_Window", {
        parent = RPE.Core.ImmersionMode and WorldFrame or UIParent,
        width  = 1,
        height = 1,
        point  = "TOPLEFT",
        pointRelative = "TOP",
        y = -50,
        autoSize = true,
        noBackground = true,
    })

    if RPE.Core.ImmersionMode then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale()
            f:SetScale(UIParent and UIParent:GetScale() or 1)
        end
        SyncScale()

        -- Disable mouse when UI is hidden (Alt+Z) so you don’t eat clicks
        local function UpdateMouseForUIVisibility()
            f:EnableMouse(UIParent and UIParent:IsShown())
        end
        UpdateMouseForUIVisibility()

        UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
        UIParent:HookScript("OnHide", function() UpdateMouseForUIVisibility() end)

        -- Also keep scale on resolution / scale changes
        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end
    
    -- Comms indicators (above root, not inside layout groups)
    self.commGroup = HGroup:New("RPE_EventWidget_CommsGroup", {
        parent   = self.root,
        autoSize = true,
        spacingX = 6,
        alignV   = "CENTER",
        point    = "BOTTOM",
        pointRelative = "TOP",
        y = 4,
    })
    self.root:Add(self.commGroup)

    -- Sending icon
    self.iconSend = Panel:New("RPE_EventWidget_CommsSend", {
        parent   = self.commGroup,
        width    = 16, height = 16,
        bgTexture = "Interface\\AddOns\\RPEngine\\UI\\Textures\\icon_send.png",
        paletteKey = "textMalus"

    })
    self.iconSend.frame:Hide()
    self.commGroup:Add(self.iconSend)

    -- Receiving icon
    self.iconRecv = Panel:New("RPE_EventWidget_CommsRecv", {
        parent   = self.commGroup,
        width    = 16, height = 16,
        bgTexture = "Interface\\AddOns\\RPEngine\\UI\\Textures\\icon_recv.png",
        paletteKey = "textBonus"
    })
    self.iconRecv.frame:Hide()
    self.commGroup:Add(self.iconRecv)

    self.content = VGroup:New("RPE_EventWidget_Content", {
        parent = self.root,
        width   = 1, height  = 1,
        autoSize = true,
        point   = "TOP",
        pointRelative = "TOP",
        spacingY = 8,
    })
    self.root:Add(self.content)

    -- staged build: header first, then balance
    self:BuildHeader(function()
        self:BuildBalance(function()
            self:BuildPortraitRow(function()
                -- More...?
            end)
        end)
    end)

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function EventWidget:BuildHeader(nextStep)
    self.header = HGroup:New("RPE_EventWidget_Header", {
        parent = self.content,
        autoSize = true,
        autoSizePadX = 16,
        autoSizePadY = 2,
        spacingX = 12,
        alignV = "CENTER",
    })
    self.content:Add(self.header)

    -- Difficulty icon
    local icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\event_normal.png"
    
    if self.data.difficulty == "HEROIC" then
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\event_heroic.png"
    elseif self.data.difficulty == "MYTHIC" then
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\event_mythic.png"
    end

    self.difficultyIcon = Panel:New("RPE_EventWidget_Header_DifficultyIcon", {
        parent = self.header,
        width = 48, height = 48,
        autoSize = false,
        x = 0,
        point  = "LEFT", pointRelative = "LEFT",
        bgTexture = icon,
        paletteKey = "textModified"
    })
    self.header:Add(self.difficultyIcon)

    -- Turn number
    self.turnNumberText = Text:New("RPE_EventWidget_Header_TurnNumberText", {
        parent = self.difficultyIcon,
        fontTemplate = "GameFontHighlightLarge",
        textPoint = "TOP",
        textRelativePoint = "TOP",
        y = 8,
        text = self.data.turnNumber and tostring(self.data.turnNumber) or "1",
        autoSize = false,
    })
    C.ApplyText(self.turnNumberText.fs, "divider")
    self.difficultyIcon:Add(self.turnNumberText)

    -- Turn progress bar (sits above the turn number)
    self.turnProgress = ProgressBar:New("RPE_EventWidget_TurnProgress", {
        parent = self.difficultyIcon,
        width  = 32,   -- slightly smaller than the icon
        height = 6,    -- slim bar
        point  = "BOTTOM",
        pointRelative = "TOP",
        y = 24,
        styles = {
            default = "progress_event",
            full    = "progress_event",
            empty   = "progress_event",
        },
        showLabel = false,
    })
    self.difficultyIcon:Add(self.turnProgress)
    self.turnProgress:SetValue(0, 100) -- start empty
    self.turnProgress:Hide() -- start hidden

    -- Name group
    self.nameGroup = VGroup:New("RPE_EventWidget_Header_NameGroup", {
        parent = self.header,
        autoSize = true,
        spacingY = 2,
        alignH = "LEFT",
    })
    self.header:Add(self.nameGroup)

    -- Event name
    self.eventNameText = Text:New("RPE_EventWidget_Header_EventNameText", {
        parent = self.nameGroup,
        fontTemplate = "GameFontHighlightLarge",
        textPoint = "TOPLEFT",
        textRelativePoint = "TOPLEFT",
        text = self.data.eventName or "Combat Event",
        autoSize = true,
    })
    C.ApplyText(self.eventNameText.fs, "text")
    self.nameGroup:Add(self.eventNameText)

    -- Event subtext
    self.eventSubtext = Text:New("RPE_EventWidget_Header_EventSubtext", {
        parent = self.nameGroup,
        fontTemplate = "GameFontHighlight",
        textPoint = "TOPLEFT",
        textRelativePoint = "TOPLEFT",
        text = string.format("  %s", self.data.eventSubtext or "good guys btw"),
        autoSize = true,
    })
    C.ApplyText(self.eventSubtext.fs, "textMuted")
    self.nameGroup:Add(self.eventSubtext)

    -- Force header size
    local iconW  = self.difficultyIcon.frame:GetWidth() or 0
    local textW  = self.eventNameText.frame:GetWidth() or 0
    local spacing = self.header.spacingX or 0
    self.header:SetSize(iconW + spacing + textW, math.max(
        self.difficultyIcon.frame:GetHeight() or 0,
        self.eventNameText.frame:GetHeight() or 0
    ))

    -- Hide header for non-combat events
    if self.data.isNonCombat then
        self.header.frame:Hide()
    end

    -- Create intermission text right after header
    self.intermissionText = Text:New("RPE_EventWidget_Intermission", {
        parent       = self.content,
        text         = "INTERMISSION",
        fontTemplate = "GameFontHighlightLarge",
        justifyH     = "CENTER",
        autoSize     = true,
    })
    C.ApplyText(self.intermissionText.fs, "textMuted")
    self.content:Add(self.intermissionText)
    self.intermissionText:Hide()

    -- fade in this group, then continue (skip fade for non-combat)
    if self.data.isNonCombat then
        if nextStep then nextStep() end
    else
        FadeInFrame(self.header.frame, 0.5, nextStep)
    end
end

function EventWidget:BuildBalance(nextStep)
    self.progressGroup = HGroup:New("RPE_EventWidget_ProgressGroup", {
        parent = self.content,
        autoSize = true,
        spacingX = 8,
        alignV = "CENTER",
    })
    self.content:Add(self.progressGroup)

    self.balanceBar = PowerBalance:New("RPE_EventWidget_Balance", {
        parent = self.progressGroup,
        width  = 200,
        height = 10,
    })
    self.balanceBar:SetValues(
        { 1, 1 },
        { "progress_event", "progress_eventcomplete" }
    )
    self.progressGroup:Add(self.balanceBar)

    self:RefreshBalance({
        values = {1,1},
        colors = {"team1", "team2"}
    })

    -- Hide progress bar for non-combat events
    if self.data.isNonCombat then
        self.progressGroup.frame:Hide()
    end

    -- fade in progress bar, then continue (skip fade for non-combat)
    if self.data.isNonCombat then
        if nextStep then nextStep() end
    else
        FadeInFrame(self.progressGroup.frame, 0.5, nextStep)
    end
end

function EventWidget:BuildPortraitRow(nextStep)
    -- For non-combat events, get custom portrait size from rules
    local portraitSize = 48
    local portraitNoHealthBar = false
    
    if self.data.isNonCombat then
        portraitNoHealthBar = true
        local customSize = RPE.ActiveRules and RPE.ActiveRules:Get("portrait_size")
        if customSize and tonumber(customSize) then
            portraitSize = tonumber(customSize)
        end
    end
    
    self.portraitRow = HGroup:New("RPE_EventWidget_PortraitRow", {
        parent   = self.content,
        autoSize = true,
        spacingX = 20,
        alignV   = "CENTER",
        width = 600,  -- increased width to accommodate aura icons on left
        height = 120,
    })
    self.content:Add(self.portraitRow)

    -- Stable host that never gets destroyed; portraits are parented here once and reused.
    self.portraitHostFrame = CreateFrame("Frame", "RPE_EventWidget_PortraitHost", self.portraitRow.frame)
    self.portraitHostFrame:SetAllPoints(self.portraitRow.frame)
    self.portraitHost = FrameElement:New("PortraitHost", self.portraitHostFrame, self.portraitRow)

    -- Cache + layout settings
    self.portraitsByKey = self.portraitsByKey or {}  -- key -> UnitPortrait
    self.portraitSize   = portraitSize
    self.portraitNoHealthBar = portraitNoHealthBar
    self.portraitGap    = 28  -- spacing between portrait groups

    FadeInFrame(self.portraitRow.frame, 0.5, function()
        if self._pendingTick then
            self:ShowTick(unpack(self._pendingTick))
            self._pendingTick = nil
        else
            self:RefreshPortraitRow(true) -- initial fade
        end
        if nextStep then nextStep() end
    end)
end

function EventWidget:RefreshPortraitRow(doFade)
    if not self.portraitHost then return end

    local event = RPE.Core.ActiveEvent
    if not event then
        RPE.Debug:Internal("[EventWidget] RefreshPortraitRow: No active event")
        return
    end
    
    if not (event.ticks and #event.ticks > 0) then
        RPE.Debug:Internal("[EventWidget] RefreshPortraitRow: Event has no ticks yet (ticks=" .. tostring(event.ticks and #event.ticks or 0) .. ")")
        return
    end
    
    if not event.units or not next(event.units) then
        RPE.Debug:Internal("[EventWidget] RefreshPortraitRow: Event has no units")
        return
    end

    -- Show units from the first tick (or current tick if we're mid-execution)
    local tickIndex = event.tickIndex and event.tickIndex > 0 and event.tickIndex or 1
    local list = {}
    if event.ticks[tickIndex] then
        for _, u in ipairs(event.ticks[tickIndex]) do
            table.insert(list, u)
        end
    end
    
    if #list == 0 then
        RPE.Debug:Internal("[EventWidget] RefreshPortraitRow: No units in tick " .. tickIndex)
        return
    end
    
    table.sort(list, function(a, b)
        local ai, bi = tonumber(a.initiative) or 0, tonumber(b.initiative) or 0
        if ai ~= bi then return ai > bi end
        if (a.team or 0) ~= (b.team or 0) then return (a.team or 0) < (b.team or 0) end
        return (a.id or 0) < (b.id or 0)
    end)

    self:_ShowUnits(list, doFade and true or false)
end

function EventWidget:ShowIntermission()
    -- Hide portraits and progress bar
    for _, p in pairs(self.portraitsByKey or {}) do
        if p and p.frame then
            p:Hide()
        end
    end
    if self.progressGroup and self.progressGroup.frame then
        self.progressGroup.frame:Hide()
    end
    
    -- Show intermission text (already created in BuildHeader)
    if self.intermissionText and self.intermissionText.frame then
        self.intermissionText:Show()
        FadeInFrame(self.intermissionText.frame, 0.5)
    end
end

function EventWidget:HideIntermission()
    -- Hide intermission text
    if self.intermissionText and self.intermissionText.frame then
        self.intermissionText:Hide()
    end
    
    -- Show progress bar and portraits again (skip for non-combat)
    if not self.data.isNonCombat then
        if self.progressGroup and self.progressGroup.frame then
            FadeInFrame(self.progressGroup.frame, 0.5)
        end
    end
    
    -- Show and layout portraits
    self:RefreshPortraitRow(true)
end


function EventWidget:RefreshBalance(data)
    local values = data.values
    local colors = data.colors
    self.balanceBar:SetValues(values, colors)
end

function EventWidget:ShowTick(turn, tickIndex, totalTicks, units)
    -- If portrait row not built yet, queue this tick
    if not self.portraitRow or not self.portraitHost then
        self._pendingTick = { turn, tickIndex, totalTicks, units }
        return
    end

    -- Update header
    if self.turnNumberText then
        self.turnNumberText:SetText(tostring(turn))
    end

    if self.turnProgress then
        if totalTicks > 1 then
            self.turnProgress:Show()
            self.turnProgress:SetValue(tickIndex, totalTicks)
        else
            self.turnProgress:Hide()
        end
    end

    -- Reuse portraits: layout & show only these units for the tick
    self:_ShowUnits(units, true)
end

-- Flash send/recv icons
function EventWidget:FlashSend()
    if not self.iconSend then return end
    self.iconSend.frame:Show()
    C_Timer.After(0.5, function() if self.iconSend then self.iconSend.frame:Hide() end end)
end

function EventWidget:FlashRecv()
    if not self.iconRecv then return end
    self.iconRecv.frame:Show()
    C_Timer.After(0.5, function() if self.iconRecv then self.iconRecv.frame:Hide() end end)
end

function EventWidget.New(opts)
    local self = setmetatable({}, EventWidget)
    self:BuildUI(opts)
    self:RefreshPortraitRow(false)
    return self
end

function EventWidget:Show()
    if self.root and self.root.Show then self.root:Show() end
end

function EventWidget:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
end

return EventWidget
