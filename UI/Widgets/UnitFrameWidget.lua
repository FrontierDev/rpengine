-- RPE_UI/Windows/UnitFrameWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local Portrait = RPE_UI.Prefabs.UnitPortrait

---@class UnitFrameWidget
---@field root Window
---@field content VGroup
---@field header HGroup
---@field teamBar HGroup
---@field teamLabel Text
---@field grid VGroup
---@field teamButtons table<integer, TextButton>
---@field currentTeam integer|nil
---@field portraitsByKey table<string, any>
---@field perRow integer
---@field portraitSize integer
local UnitFrameWidget = {}
_G.RPE_UI.Windows.UnitFrameWidget = UnitFrameWidget
UnitFrameWidget.__index = UnitFrameWidget
UnitFrameWidget.Name = "UnitFrameWidget"

-- ========= exposure =========
local function exposeCoreWindow(self)
    _G.RPE              = _G.RPE or {}
    _G.RPE.Core         = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.UnitFrameWidget = self

    _G.RPE.Core.RefreshUnitFrames = function()
        local win = _G.RPE.Core.Windows and _G.RPE.Core.Windows.UnitFrameWidget
        if win and win.Refresh then win:Refresh(true) end
    end
end

-- ========= helpers =========

-- Known WoW raid marker order (Skull priority first → Star last, then 0=Unmarked)
local RAID_ORDER = { 8, 7, 6, 5, 4, 3, 2, 1, 0 }
local RAID_NAME = {
    [1]="Star", [2]="Circle", [3]="Diamond", [4]="Triangle",
    [5]="Moon", [6]="Square", [7]="Cross",  [8]="Skull", [0]="Unmarked"
}

local function getRaidMarker(u)
    -- Accept multiple possible fields from your event/unit model
    local m = u and (u.raidMarker or u.marker or u.raidTargetIndex or u.rtid or u.markerId) or 0
    m = tonumber(m) or 0
    if m < 0 or m > 8 then m = 0 end
    return m
end

local function sortedTeams(ev)
    local set = {}
    for _, u in pairs((ev and ev.units) or {}) do
        if u.team ~= nil then set[tonumber(u.team) or 0] = true end
    end
    local arr = {}
    for t in pairs(set) do table.insert(arr, t) end
    table.sort(arr)
    return arr
end

local function teamName(ev, team)
    return (ev and ev.teamNames and ev.teamNames[team]) or ("Team "..tostring(team))
end

local function myTeamOrFirst(ev)
    if ev and ev.localPlayerKey and ev.units and ev.units[ev.localPlayerKey] then
        return tonumber(ev.units[ev.localPlayerKey].team or 1) or 1
    end
    local list = sortedTeams(ev or {})
    return list[1] or 1
end

local function _ClearChildren(group)
    if not group or not group.children then return end
    for i = #group.children, 1, -1 do
        local child = group.children[i]
        if child and child.Destroy then child:Destroy() end
        table.remove(group.children, i)
    end
end

-- ========= portrait cache =========

function UnitFrameWidget:_EnsurePortrait(u, parent)
    if not (u and u.key) then return nil end
    self.portraitsByKey = self.portraitsByKey or {}
    local p = self.portraitsByKey[u.key]
    if not p or not p.frame then
        p = Portrait:New(("RPE_UFW_Unit_%s"):format(u.key), {
            parent = parent, unit = u, size = self.portraitSize
        })
        self.portraitsByKey[u.key] = p
    else
        if p.SetParent and parent then p:SetParent(parent) end
        if p.SetUnit then p:SetUnit(u) end
    end
    if u.hp and u.hpMax and p.SetHealth then p:SetHealth(u.hp, u.hpMax) end
    -- Display absorption
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
    return p
end

-- ========= layout =========

function UnitFrameWidget:_ClearGrid()
    _ClearChildren(self.grid)
end

function UnitFrameWidget:_BuildTeamButtons(ev)
    -- wipe old
    for _, btn in pairs(self.teamButtons or {}) do
        if btn and btn.Destroy then btn:Destroy() end
    end
    self.teamButtons = {}
    _ClearChildren(self.teamBar)

    local teams = sortedTeams(ev)
    for _, t in ipairs(teams) do
        local btn = TextBtn:New(("RPE_UFW_TeamBtn_%d"):format(t), {
            parent  = self.teamBar,
            width   = 120, height = 22,
            text    = teamName(ev, t),
            onClick = function() self:SetTeam(t) end,
        })
        if self.teamBar.Add then self.teamBar:Add(btn) end
        self.teamButtons[t] = btn
    end
end

function UnitFrameWidget:_UpdateButtonStates()
    if not self.teamButtons then return end
    for t, btn in pairs(self.teamButtons) do
        if t == self.currentTeam then
            if btn.Lock then btn:Lock() end
        else
            if btn.Unlock then btn:Unlock() end
        end
    end
end

-- Build rows of portraits inside a container VGroup, using self.perRow
function UnitFrameWidget:_BuildRows(container, units)
    local perRow = self.perRow
    local idx, rowIdx = 1, 1
    while idx <= #units do
        local row = HGroup:New(("RPE_UFW_Row_%d"):format(rowIdx), {
            parent = container, autoSize = true, spacingX = 8, alignV = "CENTER",
        })
        if container.Add then container:Add(row) end
        for _ = 1, perRow do
            local u = units[idx]; idx = idx + 1
            if not u then break end
            local p = self:_EnsurePortrait(u, row)
            if p then
                if p.SetDisabled then p:SetDisabled((u.hp or 0) <= 0) end
                if row.Add then row:Add(p) end
            end
        end
        rowIdx = rowIdx + 1
    end
end

-- Group by raid marker after filtering by team
function UnitFrameWidget:_FillGridForTeam(ev, teamId)
    self:_ClearGrid()
    if not (ev and ev.units) then return end

    -- 1) collect units on team (include all units, not just active)
    local list = {}
    for _, u in pairs(ev.units) do
        if tonumber(u.team) == tonumber(teamId) then
            table.insert(list, u)
        end
    end

    -- 2) bucket by raid marker
    local buckets = { [0] = {} }
    for _, m in ipairs({1,2,3,4,5,6,7,8}) do buckets[m] = {} end
    for _, u in ipairs(list) do
        local m = getRaidMarker(u)
        table.insert(buckets[m], u)
    end

    -- 3) sort within each bucket (initiative desc, then id asc)
    local function sortUnits(arr)
        table.sort(arr, function(a, b)
            local ai, bi = tonumber(a.initiative) or 0, tonumber(b.initiative) or 0
            if ai ~= bi then return ai > bi end
            return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
        end)
    end
    for m, arr in pairs(buckets) do sortUnits(arr) end

    -- 4) build per-marker groups in preferred order
    local groupCounter = 1
    for _, m in ipairs(RAID_ORDER) do
        local arr = buckets[m]
        if arr and #arr > 0 then
            -- rows for this marker group
            local block = VGroup:New(("RPE_UFW_MarkerBlock_%d"):format(groupCounter), {
                parent = self.grid, autoSize = true, spacingY = 6,
            })
            if self.grid.Add then self.grid:Add(block) end

            self:_BuildRows(block, arr)
            groupCounter = groupCounter + 1
        end
    end

    -- 5) update team label text
    if self.teamLabel and self.teamLabel.SetText then
        self.teamLabel:SetText(teamName(ev, teamId))
    end

    if self.content and self.content.Relayout then self.content:Relayout() end
end

-- ========= public API =========

function UnitFrameWidget:BuildUI(opts)
    opts = opts or {}
    self.perRow        = tonumber(opts.perRow or 8) or 8
    self.portraitSize  = tonumber(opts.portraitSize or 32) or 32

    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent

    self.root = Window:New("RPE_UnitFrameWidget_Window", {
        parent = parentFrame,
        width  = 1, height = 1,
        point  = opts.point or "LEFT",
        pointRelative = opts.rel or "LEFT",
        x = opts.x or 64,
        y = opts.y or 160,
        autoSize = true,
        noBackground = true, noBorder = true,
        autoSizePadX = 12,
        autoSizePadY = 12,
    })

    -- Immersion parity (scale/mouse with UIParent)
    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)
        local function SyncScale()
            if UIParent and UIParent.GetScale then f:SetScale(UIParent:GetScale()) end
        end
        local function UpdateMouseForUIVisibility()
            if UIParent and UIParent.IsShown then f:EnableMouse(UIParent:IsShown()) end
        end
        SyncScale(); UpdateMouseForUIVisibility()
        if UIParent and UIParent.HookScript then
            UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
            UIParent:HookScript("OnHide", function() UpdateMouseForUIVisibility() end)
        end
        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Content stack
    self.content = VGroup:New("RPE_UFW_Content", {
        parent = self.root,
        autoSize = true,
        spacingY = 8,
        autoSizePadX = 8,
        autoSizePadY = 8,
        alignH = "CENTER",
    })
    self.root:Add(self.content)

    -- Header row
    self.header = HGroup:New("RPE_UFW_Header", {
        parent = self.content,
        autoSize = true,
        spacingX = 12,
        alignV   = "CENTER",
    })
    self.content:Add(self.header)

    -- Team switch bar
    self.teamBar = HGroup:New("RPE_UFW_TeamBar", {
        parent = self.content,
        autoSize = true,
        spacingX = 8,
        alignV = "CENTER",
    })
    self.content:Add(self.teamBar)

    -- Grid container
    self.grid = VGroup:New("RPE_UFW_Grid", {
        parent = self.content,
        autoSize = true,
        spacingY = 6,
    })
    self.content:Add(self.grid)

    self.portraitsByKey = {}
    self.teamButtons    = {}

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end

    exposeCoreWindow(self)
    self:Refresh(true)
end

--- Programmatic team switch
function UnitFrameWidget:SetTeam(teamId)
    if teamId == self.currentTeam then return end
    self.currentTeam = teamId
    self:_UpdateButtonStates()
    local ev = RPE.Core.ActiveEvent
    self:_FillGridForTeam(ev, teamId)
end

--- Rebuild team buttons and grid from current event state.
---@param keepTeam boolean|nil @keep current team if still valid
function UnitFrameWidget:Refresh(keepTeam)
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then
        self:_ClearGrid()
        return
    end

    self:_BuildTeamButtons(ev)

    local desiredTeam = (keepTeam and self.currentTeam) or myTeamOrFirst(ev)
    local exists = false
    for _, t in ipairs(sortedTeams(ev)) do if t == desiredTeam then exists = true break end end
    if not exists then desiredTeam = myTeamOrFirst(ev) end

    self.currentTeam = desiredTeam
    self:_UpdateButtonStates()
    self:_FillGridForTeam(ev, desiredTeam)
end

function UnitFrameWidget:Update() self:Refresh(true) end

-- Boilerplate
function UnitFrameWidget.New(opts)
    local self = setmetatable({}, UnitFrameWidget)
    self:BuildUI(opts or {})
    return self
end

function UnitFrameWidget:Show() if self.root and self.root.Show then self.root:Show() end end
function UnitFrameWidget:Hide() if self.root and self.root.Hide then self.root:Hide() end end

return UnitFrameWidget
