-- RPE_UI/Windows/TargetWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local TextBtn  = RPE_UI.Elements.TextButton
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local IconBtn  = RPE_UI.Elements.IconButton

---@class TargetWindow
---@field root Window
---@field content Panel
---@field footer Panel
---@field header HGroup
---@field tabs HGroup
---@field grid VGroup
---@field confirmBtn TextBtn
---@field cancelBtn TextBtn
---@field spellIcon IconButton
---@field spellName Text
---@field countText Text
---@field hitText Text
---@field tabAllies TextBtn
---@field tabEnemies TextBtn
---@field tabFocus TextBtn
---@field _flags table<string, boolean>
---@field _maxTargets integer
---@field _selected table<string, true>
---@field _currentTab "ALLIES"|"ENEMIES"|"FOCUS"
---@field _unitProvider fun(): (table[], table[])
---@field _onConfirm fun(keys: string[])
---@field _onCancel fun()
---@field _casterUnitId integer|nil Unit ID of the caster (for team context when casting as another unit)
---@field _referenceTeam integer The team ID used to determine allies vs enemies
---@field _targeter string|nil The targeter name (e.g., "RAID_MARKER") for conditional UI behavior
local TargetWindow = {}
_G.RPE_UI.Windows.TargetWindow = TargetWindow
TargetWindow.__index = TargetWindow
TargetWindow.Name = "TargetWindow"

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.TargetWindow = self
end

local function parseFlags(v)
    local out = {}
    if type(v) == "string" then
        for tok in v:gmatch("%S+") do out[tok] = true end
    elseif type(v) == "table" then
        for k, b in pairs(v) do if b then out[k] = true end end
    end
    return out
end

local function getSelfKey()
    local n = UnitName("player")
    local r = GetRealmName() and GetRealmName():gsub("%s+","") or ""
    return (n and r) and (n.."-"..r) or "player"
end

local function countSel(t) local c=0; for _ in pairs(t) do c=c+1 end; return c end

local function unitMatchesFlags(unit, flags, referenceTeam)
    -- Check if unit matches the provided flags (A=ally, E=enemy, etc.)
    -- Flags can include "0" suffix (e.g., "A0", "E0") to allow dead targets
    if not flags or not next(flags) then return true end
    
    local isAlly = unit.team == referenceTeam
    
    -- Check each flag, stripping "0" suffix if present
    for flag in pairs(flags) do
        -- Strip "0" suffix to get base flag (e.g., "A0" -> "A", "AM0" -> "AM")
        local baseFlag = flag:gsub("0$", "")
        
        if baseFlag == "A" and isAlly then return true end
        if baseFlag == "E" and not isAlly then return true end
        if baseFlag == "AM" and isAlly then return true end  -- Ally but not self
        if baseFlag == "EM" and not isAlly then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------
function TargetWindow:BuildUI(opts)
    opts = opts or {}

    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_Target_Window", {
        parent = parentFrame,
        width  = 1, height = 1,
        point  = "CENTER",
        autoSize = true,
        noBackground = opts.noBackground,
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

    self.content = VGroup:New("RPE_Target_Content", {
        parent = self.root,
        autoSize = true,
        y = -8,
        autoSizePadX = 12,
        autoSizePadY = 8,
        spacingY     = 8,
    })
    self.root:Add(self.content)

    -- Header row
    self.header = HGroup:New("RPE_Target_Header", {
        parent = self.content,
        autoSize = true,
        spacingX = 8,
        alignV   = "CENTER",
    })
    self.content:Add(self.header)

    -- Tabs
    self.tabs = HGroup:New("RPE_Target_Tabs", {
        parent = self.content,
        autoSize = true,
        spacingX = 8,
        alignV   = "CENTER",
    })
    self.content:Add(self.tabs)

    self.tabAllies = TextBtn:New("RPE_Target_TabAllies", {
        parent = self.tabs, width=100, height=22,
        text = "Allies",
        onClick=function() self:_SwitchTab("ALLIES") end,
    })
    self.tabEnemies = TextBtn:New("RPE_Target_TabEnemies", {
        parent = self.tabs, width=100, height=22,
        text = "Enemies",
        onClick=function() self:_SwitchTab("ENEMIES") end,
    })
    self.tabFocus = TextBtn:New("RPE_Target_TabFocus", {
        parent = self.tabs, width=100, height=22,
        text = "Focus",
        onClick=function() self:_SwitchTab("FOCUS") end,
    })

    self.tabs:Add(self.tabAllies)
    self.tabs:Add(self.tabEnemies)
    self.tabs:Add(self.tabFocus)

    -- Spell info
    self.spellIcon = IconBtn:New("RPE_Target_SpellIcon", {
        parent=self.header, width=20, height=20,
        noBackground=true, icon=135274,
    })
    self.header:Add(self.spellIcon)

    local nameCol = VGroup:New("RPE_Target_NameCol", {
        parent=self.header, autoSize=true, spacingY=2,
    })
    self.header:Add(nameCol)

    self.spellName = Text:New("RPE_Target_SpellName", {
        parent=nameCol, text="Select Targets", fontTemplate="GameFontHighlight",
    })
    self.countText = Text:New("RPE_Target_Count", {
        parent=nameCol, text="Targets: 0 / 1", fontTemplate="GameFontNormalSmall",
    })
    nameCol:Add(self.spellName)
    nameCol:Add(self.countText)

    self.hitText = Text:New("RPE_Target_HitText", {
        parent=self.header, text="", fontTemplate="GameFontNormal",
    })
    self.header:Add(self.hitText)

    -- Grid
    self.grid = VGroup:New("RPE_Target_Grid", {
        parent=self.content, autoSize=true, spacingY=4,
    })
    self.content:Add(self.grid)

    -- Footer
    self.footer = HGroup:New("RPE_Target_Footer", {
        parent=self.content, autoSize=true, spacingX=12, alignH="CENTER",
    })
    self.content:Add(self.footer)

    self.confirmBtn = TextBtn:New("RPE_Target_Confirm", {
        parent=self.footer, width=120, height=24, text="Confirm",
        onClick=function() self:Confirm() end,
    })
    self.cancelBtn = TextBtn:New("RPE_Target_Cancel", {
        parent=self.footer, width=120, height=24, text="Cancel",
        onClick=function() self:Cancel() end,
    })
    self.footer:Add(self.confirmBtn)
    self.footer:Add(self.cancelBtn)

    -- state
    self._selected, self._flags = {}, {}
    self._maxTargets, self._currentTab = 1, "ALLIES"
    self._unitProvider = function() return {}, {} end
    self._portraitsByKey = {}  -- Map unit key -> portrait frame for updating visuals

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
    self:Hide()
end

-- ---------------------------------------------------------------------------
-- public API
-- ---------------------------------------------------------------------------
function TargetWindow:Open(opts)
    opts = opts or {}
    self._flags       = parseFlags(opts.flags or {})
    self._maxTargets  = tonumber(opts.maxTargets or 1) or 1
    self._casterUnitId = tonumber(opts.casterUnitId) or nil
    self._targeter    = opts.targeter or nil
    
    -- Determine and store the reference team
    local ev = RPE.Core.ActiveEvent
    self._referenceTeam = 1
    if ev and ev.units then
        if self._casterUnitId then
            for _, u in pairs(ev.units) do
                if tonumber(u.id) == self._casterUnitId then
                    self._referenceTeam = u.team or 1
                    break
                end
            end
        else
            if ev.localPlayerKey and ev.units[ev.localPlayerKey] then
                self._referenceTeam = ev.units[ev.localPlayerKey].team or 1
            end
        end
    end
    
    self._unitProvider = opts.unitProvider or function()
        local ev = RPE.Core.ActiveEvent
        if not ev or not ev.units then return {}, {} end
        local allies, enemies = {}, {}
        
        for _, u in pairs(ev.units) do
            if u.team == self._referenceTeam then table.insert(allies, u)
            else table.insert(enemies, u) end
        end
        return allies, enemies
    end
    self._onConfirm, self._onCancel = opts.onConfirm, opts.onCancel
    self._computeHit = opts.computeHitChance

    -- header
    if self.spellIcon and self.spellIcon.icon then
        self.spellIcon.icon:SetTexture(opts.spellIcon or 135274)
    end
    self.spellName:SetText(opts.spellName or "Select Targets")
    self.countText:SetText(("Targets: %d / %d"):format(0, self._maxTargets))
    self.hitText:SetText("")

    -- default tab: Focus if not empty, else Allies/Enemies
    local hasFocus = self:_HasFocusUnits()
    if hasFocus then
        self.tabFocus.frame:Show()
        self._currentTab = "FOCUS"
    else
        self.tabFocus.frame:Hide()
        self._currentTab = (self._flags["E"] or self._flags["EM"]) and "ENEMIES" or "ALLIES"
    end

    wipe(self._selected)
    self:_RebuildGrid()
    self:Show()
end

function TargetWindow:Show() if self.root and self.root.Show then self.root:Show() end end
function TargetWindow:Hide() if self.root and self.root.Hide then self.root:Hide() end end

-- ---------------------------------------------------------------------------
-- internals
-- ---------------------------------------------------------------------------
function TargetWindow:_SwitchTab(tab)
    if tab == self._currentTab then return end
    self._currentTab = tab
    self:_RebuildGrid()
end

function TargetWindow:_updateCounters()
    local n = countSel(self._selected)
    self.countText:SetText(("Targets: %d / %d"):format(n, self._maxTargets))
    if self._computeHit then
        local arr = {}; for k in pairs(self._selected) do table.insert(arr, k) end
        local pct = tonumber(self._computeHit(arr))
        if pct then
            pct = math.max(0, math.min(100, math.floor(pct + 0.5)))
            self.hitText:SetText(("Hit Chance: %d%%"):format(pct))
        else self.hitText:SetText("") end
    else self.hitText:SetText("") end
end

-- Determine if Focus tab has units
function TargetWindow:_HasFocusUnits()
    local ev = RPE.Core.ActiveEvent
    if not ev or not ev.units then return false end
    local me = ev.localPlayerKey
    for _, u in pairs(ev.units) do
        if u.threatTopFor == me or u.attackedBy == me or u.healedBy == me then
            return true
        end
    end
    return false
end

function TargetWindow:_RebuildGrid()
    -- clear
    for i = #self.grid.children, 1, -1 do
        local c = self.grid.children[i]; if c.Destroy then c:Destroy() end
        table.remove(self.grid.children, i)
    end
    
    -- Clear portrait map
    wipe(self._portraitsByKey)
    
    local ev = RPE.Core.ActiveEvent
    if not ev or not ev.units then return end

    -- Determine the reference team: if _casterUnitId is set, use that unit's team; otherwise use local player's team
    local myTeam = 1
    if self._casterUnitId then
        -- Find the controlled unit and use its team
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == self._casterUnitId then
                myTeam = u.team or 1
                break
            end
        end
    else
        -- Default: use local player's team
        if ev.localPlayerKey and ev.units[ev.localPlayerKey] then
            myTeam = ev.units[ev.localPlayerKey].team or 1
        end
    end

    local me        = getSelfKey()
    -- Check if any flag contains "0" (e.g., "A0", "E0") to allow dead targets
    local allowDead = false
    for flag in pairs(self._flags) do
        if type(flag) == "string" and flag:find("0") then
            allowDead = true
            break
        end
    end
    local noSelf    = self._flags["NS"]
    local onlySelf  = self._flags["SO"]

    local function isValid(u)
        if not allowDead and (u.hp or 0) <= 0 then return false end
        if noSelf and u.key == me then return false end
        if onlySelf and u.key ~= me then return false end
        -- flag-based target filtering
        if self._flags["A"] and tonumber(u.team) ~= tonumber(myTeam) then return false end
        if (self._flags["E"] or self._flags["EM"]) and tonumber(u.team) == tonumber(myTeam) then return false end
        return true
    end

    local function buildTeamBlock(team, list, drawHeader)
        local teamName = (ev.teamNames and ev.teamNames[team]) or ("Team "..tostring(team))

        if drawHeader then
            local label = Text:New(("RPE_Target_TeamLabel_%s"):format(team), {
                parent=self.grid, text=teamName, fontTemplate="GameFontHighlight",
            })
            self.grid:Add(label)
        end

        local perRow, size, idx = 8, 32, 1
        while idx <= #list do
            local row = HGroup:New(("RPE_Target_Team%s_Row%d"):format(team, idx), {
                parent=self.grid, autoSize=true, spacingX=8, alignV="CENTER",
            })
            self.grid:Add(row)

            for c = 1, perRow do
                local u = list[idx]; idx = idx + 1
                if not u then break end
                local portrait = RPE_UI.Prefabs.UnitPortrait:New(
                    ("RPE_Target_Unit_%s"):format(u.key),
                    { parent=row, unit=u, size=size }
                )

                if u.hp and u.hpMax then
                    portrait:SetHealth(u.hp, u.hpMax)
                end
                
                -- Display absorption
                if portrait.SetAbsorption then
                    local totalAbsorption = 0
                    if u.absorption then
                        for _, shield in pairs(u.absorption) do
                            if shield.amount then
                                totalAbsorption = totalAbsorption + shield.amount
                            end
                        end
                    end
                    portrait:SetAbsorption(totalAbsorption)
                end

                if not isValid(u) then
                    portrait:SetDisabled(true)
                else
                    portrait:SetDisabled(false)
                    portrait.frame:EnableMouse(true)
                    
                    -- Store portrait reference for later updates
                    self._portraitsByKey[u.key] = portrait.frame
                    
                    -- Override OnClick to prevent unit control activation (only target selection in TargetWindow)
                    portrait.frame:SetScript("OnClick", function()
                        -- Do nothing; target selection handled by OnMouseDown
                    end)
                    
                    portrait.frame:SetScript("OnMouseDown", function()
                        local isDeselecting = self._selected[u.key]
                        local currentEv = RPE.Core.ActiveEvent
                        
                        if isDeselecting then
                            self._selected[u.key] = nil
                            portrait.frame:SetAlpha(0.5)
                            
                            -- If using RAID_MARKER targeter and unit has a raid marker, deselect all with same marker
                            if self._targeter == "RAID_MARKER" and u.raidMarker and currentEv and currentEv.units then
                                for _, otherU in pairs(currentEv.units) do
                                    if otherU.raidMarker == u.raidMarker and otherU.key ~= u.key then
                                        self._selected[otherU.key] = nil
                                        -- Update visual of related portrait
                                        if self._portraitsByKey[otherU.key] then
                                            self._portraitsByKey[otherU.key]:SetAlpha(0.5)
                                        end
                                    end
                                end
                            end
                        else
                            -- Check if unit matches the flags
                            if not unitMatchesFlags(u, self._flags, self._referenceTeam) then
                                UIErrorsFrame:AddMessage("That target is not valid for this spell.", 1,1,0)
                                return
                            end
                            
                            -- For RAID_MARKER, ignore maxTargets limit; for others, enforce it
                            if self._targeter ~= "RAID_MARKER" and countSel(self._selected) >= self._maxTargets then
                                UIErrorsFrame:AddMessage("You cannot select any more targets.", 1,1,0)
                                return
                            end
                            self._selected[u.key] = true
                            portrait.frame:SetAlpha(1.0)
                            
                            -- If using RAID_MARKER targeter and unit has a raid marker, select all with same marker
                            if self._targeter == "RAID_MARKER" and u.raidMarker and currentEv and currentEv.units then
                                for _, otherU in pairs(currentEv.units) do
                                    if otherU.raidMarker == u.raidMarker and otherU.key ~= u.key then
                                        -- Check if this related unit also matches the flags
                                        if unitMatchesFlags(otherU, self._flags, self._referenceTeam) then
                                            self._selected[otherU.key] = true
                                            -- Update visual of related portrait
                                            if self._portraitsByKey[otherU.key] then
                                                self._portraitsByKey[otherU.key]:SetAlpha(1.0)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        self:_updateCounters()
                    end)
                    portrait.frame:SetAlpha(self._selected[u.key] and 1.0 or 0.5)
                end


                row:Add(portrait)
            end
        end
    end

    if self._currentTab == "ALLIES" then
        local allies = {}
        for _, u in pairs(ev.units) do if u.team == myTeam then table.insert(allies, u) end end
        buildTeamBlock(myTeam, allies, true)

    elseif self._currentTab == "ENEMIES" then
        local byTeam = {}
        for _, u in pairs(ev.units) do
            if u.team ~= myTeam then
                byTeam[u.team] = byTeam[u.team] or {}
                table.insert(byTeam[u.team], u)
            end
        end
        for team, list in pairs(byTeam) do buildTeamBlock(team, list, true) end

    elseif self._currentTab == "FOCUS" then
        local meKey = ev.localPlayerKey
        local focus = {
            attacked  = {},
            protected = {},
            threat    = {},
        }

        for _, u in pairs(ev.units) do
            if u.attackedLast == meKey then
                table.insert(focus.attacked, u)
            end
            if u.protectedLast == meKey then
                table.insert(focus.protected, u)
            end
            if u.topThreat == meKey then
                table.insert(focus.threat, u)
            end
        end

        local any = false
        if #focus.attacked > 0 then
            any = true
            local label = Text:New("RPE_Target_FocusAttackedLabel", {
                parent=self.grid, text="Last Attacked", fontTemplate="GameFontHighlight",
            })
            self.grid:Add(label)
            buildTeamBlock("Attacked Last Turn", focus.attacked, false)
        end
        if #focus.protected > 0 then
            any = true
            local label = Text:New("RPE_Target_FocusProtectedLabel", {
                parent=self.grid, text="Last Protected", fontTemplate="GameFontHighlight",
            })
            self.grid:Add(label)
            buildTeamBlock("Protected Last Turn", focus.protected, false)
        end
        if #focus.threat > 0 then
            any = true
            local label = Text:New("RPE_Target_FocusThreatLabel", {
                parent=self.grid, text="Top Threat", fontTemplate="GameFontHighlight",
            })
            self.grid:Add(label)
            buildTeamBlock("Threat", focus.threat, false)
        end

        if not any then
            -- hide tab and fall back
            self.tabFocus.frame:Hide()
            self._currentTab = "ALLIES"
            self:_RebuildGrid()
            return
        end
    end


    self:_updateCounters()
end

function TargetWindow:Confirm()
    local n = countSel(self._selected)
    if n == 0 then
        UIErrorsFrame:AddMessage("Select at least one target.", 1,0.3,0.3)
        return
    end
    local out = {}; for k in pairs(self._selected) do table.insert(out, k) end
    if self._onConfirm then self._onConfirm(out) end
    self:Hide()
end

function TargetWindow:Cancel()
    if self._onCancel then self._onCancel() end
    self:Hide()
end

-- ctor
function TargetWindow.New(opts)
    local o = setmetatable({}, TargetWindow)
    opts = opts or {}
    o:BuildUI(opts)
    return o
end

---Force-refresh the Focus tab (debug/test).
function TargetWindow:DebugShowFocus()
    if not self.root then return end

    -- Switch tab to Focus and rebuild
    self._currentTab = "FOCUS"
    self.tabFocus.frame:Show()
    self:_RebuildGrid()
    self:Show()
end

SLASH_RPEFOCUS1 = "/rpefocus"
SlashCmdList.RPEFOCUS = function(msg)
    local ev = RPE.Core.ActiveEvent
    local win = _G.RPE and RPE.Core.Windows and RPE.Core.Windows.TargetWindow
    if not ev then
        return
    end
    if not win then
        return
    end

    ev:DebugSeedFocus()
    win:DebugShowFocus()
end



return TargetWindow
