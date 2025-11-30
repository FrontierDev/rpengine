-- RPE_UI/Windows/EventUnitsSheet.lua
RPE             = RPE or {}
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.Core        = RPE.Core or {}

local VGroup     = RPE_UI.Elements.VerticalLayoutGroup
local HGroup     = RPE_UI.Elements.HorizontalLayoutGroup
local TextButton = RPE_UI.Elements.TextButton
local Table      = RPE_UI.Elements.Table

---@class EventUnitsSheet
local EventUnitsSheet = {}
_G.RPE_UI.Windows.EventUnitsSheet = EventUnitsSheet
EventUnitsSheet.__index = EventUnitsSheet
EventUnitsSheet.Name = "EventUnitsSheet"

function EventUnitsSheet:BuildUI(opts)
    opts = opts or {}
    self.page = 1
    self.pageSize = 9
    
    -- Initialize filters with all teams and markers selected by default
    local maxTeams = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_teams) or 4
    self.filterTeams = {}
    for t = 1, maxTeams do
        self.filterTeams[t] = true
    end
    self.filterMarkers = {}
    for i = 1, 8 do
        self.filterMarkers[i] = true
    end
    self.filterMarkers.unmarked = true -- Unmarked is also selected by default

    self.sheet = VGroup:New("RPE_EUS_Root", {
        parent = opts.parent,
        autoSize = true,
        spacingY = 12,
        padding = { left=12, right=12, top=12, bottom=12 },
        alignH = "LEFT",
        alignV = "TOP",
    })

    self.controls = HGroup:New("RPE_EUS_Controls", {
        parent = self.sheet,
        autoSize = true,
        spacingX = 12,
        alignH = "LEFT",
        alignV = "CENTER",
    })
    self.sheet:Add(self.controls)

    local refreshBtn = TextButton:New("RPE_EUS_RefreshBtn", {
        parent = self.controls, width=80, height=24, text="Refresh",
        onClick = function() self:Refresh() end,
    })
    self.controls:Add(refreshBtn)

    self.unitFilterBtn = TextButton:New("RPE_EUS_UnitFilter", {
        parent = self.controls, width = 140, height = 24, text = "Filter: None",
        onClick = function(btn)
            RPE_UI.Common:ContextMenu(btn.frame, function(level, _)
                if level == 1 then
                    local maxTeams = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_teams) or 4
                    for t = 1, maxTeams do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = "Team " .. t
                        info.keepShownOnClick = true
                        info.checked = self.filterTeams[t]
                        info.isNotRadio = true
                        info.func = function()
                            self.filterTeams[t] = not self.filterTeams[t]
                            self:UpdateFilterText()
                            self:Refresh()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end

                    UIDropDownMenu_AddSeparator(level)

                    local names = { "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" }
                    for i = 1, 8 do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = names[i]
                        info.keepShownOnClick = true
                        info.checked = self.filterMarkers[i]
                        info.isNotRadio = true
                        info.func = function()
                            self.filterMarkers[i] = not self.filterMarkers[i]
                            self:UpdateFilterText()
                            self:Refresh()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end

                    -- Unmarked option
                    local unmarkedInfo = UIDropDownMenu_CreateInfo()
                    unmarkedInfo.text = "Unmarked"
                    unmarkedInfo.keepShownOnClick = true
                    unmarkedInfo.checked = self.filterMarkers.unmarked
                    unmarkedInfo.isNotRadio = true
                    unmarkedInfo.func = function()
                        self.filterMarkers.unmarked = not self.filterMarkers.unmarked
                        self:UpdateFilterText()
                        self:Refresh()
                    end
                    UIDropDownMenu_AddButton(unmarkedInfo, level)

                    UIDropDownMenu_AddSeparator(level)

                    local clear = UIDropDownMenu_CreateInfo()
                    clear.text = "Show All"
                    clear.func = function()
                        local maxTeams = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_teams) or 4
                        self.filterTeams = {}
                        for t = 1, maxTeams do
                            self.filterTeams[t] = true
                        end
                        self.filterMarkers = {}
                        for i = 1, 8 do
                            self.filterMarkers[i] = true
                        end
                        self.filterMarkers.unmarked = true
                        self:UpdateFilterText()
                        self:Refresh()
                    end
                    UIDropDownMenu_AddButton(clear, level)

                    local hideAll = UIDropDownMenu_CreateInfo()
                    hideAll.text = "Hide All"
                    hideAll.func = function()
                        local maxTeams = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_teams) or 4
                        self.filterTeams = {}
                        for t = 1, maxTeams do
                            self.filterTeams[t] = false
                        end
                        self.filterMarkers = {}
                        for i = 1, 8 do
                            self.filterMarkers[i] = false
                        end
                        self.filterMarkers.unmarked = false
                        self:UpdateFilterText()
                        self:Refresh()
                    end
                    UIDropDownMenu_AddButton(hideAll, level)
                end
            end)
        end
    })
    self.controls:Add(self.unitFilterBtn)

    local prevBtn = TextButton:New("RPE_EUS_Prev", {
        parent = self.controls, width=60, height=24, text="Prev",
        onClick = function()
            if self.page > 1 then self.page = self.page - 1; self:Refresh() end
        end
    })
    self.controls:Add(prevBtn)

    local nextBtn = TextButton:New("RPE_EUS_Next", {
        parent = self.controls, width=60, height=24, text="Next",
        onClick = function()
            self.page = self.page + 1
            self:Refresh()
        end
    })
    self.controls:Add(nextBtn)

    local addNpcBtn = TextButton:New("RPE_EUS_AddNPC", {
        parent = self.controls, width = 100, height = 24, text = "Add NPC",
        onClick = function()
            local AddNPCWindow = RPE_UI.Windows.AddNPCWindow
            AddNPCWindow.Open({
                team = 2,
                onConfirm = function(npcId, team, raidMarker, flags)
                    local ev = RPE.Core.ActiveEvent
                    if ev and ev.AddNPCFromRegistry then
                        ev:AddNPCFromRegistry(npcId, { team = team, raidMarker = raidMarker, active = flags and flags.active, hidden = flags and flags.hidden, flying = flags and flags.flying })
                        self:Refresh()
                    end
                end,
            })
        end,
    })
    self.controls:Add(addNpcBtn)

    self.table = Table:New("RPE_EUS_Table", {
        parent = self.sheet,
        autoSize = true,
        headerSpacingX = 12,
        rowHeight = 22,
        cellPadX = 6,
    })
    self.sheet:Add(self.table.root)

    self.table:SetColumns({
        { key="team",       title="Team",       width=50 },
        { key="id",         title="ID",         width=30 },
        { key="initiative", title="Init",       width=30 },
        { key="hp",         title="HP",         width=80 },
        { key="active",     title=RPE.Common.InlineIcons.Check,       width=20 },
        { key="hidden",     title=RPE.Common.InlineIcons.Hidden,       width=20 },
        { key="flying",     title=RPE.Common.InlineIcons.Flying,       width=20 },
        { key="name",       title="Unit Name",       width=240 },
    })

    self.table:SetSort(function(a,b)
        local at, bt = a.teamRaw or 1, b.teamRaw or 1
        if at ~= bt then return at < bt end
        local ai, bi = tonumber(a.initiative) or 0, tonumber(b.initiative) or 0
        if ai ~= bi then return ai > bi end
        return (a.id or 0) < (b.id or 0)
    end)

    self.table:SetRowOnClick(function(rowFrame, rowData, button)
        local ev = RPE.Core.ActiveEvent
        if not ev or not ev.SetTeamFor then return end

        local unit = ev.units[rowData.key]
        if not unit then return end

        -- Left click with modifiers: toggle flags
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                unit.active = not unit.active
                self:Refresh()
                -- Sync action bar button colors if controlling this unit
                local ABW = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
                if ABW and ABW._controlledUnitId == unit.id then
                    ABW:_UpdateFlagButtonColors(unit)
                end
                return
            elseif IsControlKeyDown() then
                unit.hidden = not unit.hidden
                self:Refresh()
                -- Sync action bar button colors if controlling this unit
                local ABW = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
                if ABW and ABW._controlledUnitId == unit.id then
                    ABW:_UpdateFlagButtonColors(unit)
                end
                return
            elseif IsAltKeyDown() then
                unit.flying = not unit.flying
                self:Refresh()
                -- Sync action bar button colors if controlling this unit
                local ABW = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
                if ABW and ABW._controlledUnitId == unit.id then
                    ABW:_UpdateFlagButtonColors(unit)
                end
                return
            end
        end

        -- Right click: context menu
        if button ~= "RightButton" then return end

        local maxTeams = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_teams) or 4

        RPE_UI.Common:ContextMenu(rowFrame, function(level, _)
            if level == 1 then
                -- Team submenu
                for t = 1, maxTeams do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = "Set to Team " .. t
                    info.checked = (unit.team == t)
                    info.isNotRadio = false
                    info.func = function()
                        ev:SetTeamFor(rowData.key, t)
                        self:Refresh()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end

                UIDropDownMenu_AddSeparator(level)

                -- Raid marker submenu
                local markers = {
                    [1] = "Star", [2] = "Circle", [3] = "Diamond", [4] = "Triangle",
                    [5] = "Moon", [6] = "Square", [7] = "Cross", [8] = "Skull"
                }
                if unit.SetRaidMarker then
                    for idx, label in ipairs(markers) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = "Set Marker: " .. label
                        info.icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. idx
                        info.checked = (unit.raidMarker == idx)
                        info.isNotRadio = false
                        info.func = function()
                            unit:SetRaidMarker(idx)
                            self:Refresh()
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end

                    local clearInfo = UIDropDownMenu_CreateInfo()
                    clearInfo.text = "Clear Marker"
                    clearInfo.checked = (unit.raidMarker == nil or unit.raidMarker == 0)
                    clearInfo.isNotRadio = false
                    clearInfo.func = function()
                        unit:SetRaidMarker(nil)
                        self:Refresh()
                    end
                    UIDropDownMenu_AddButton(clearInfo, level)
                end

                UIDropDownMenu_AddSeparator(level)

                -- Flag toggles (NPC-only)
                local function addFlagOption(flagKey, label)
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = label
                    info.isNotRadio = true
                    info.keepShownOnClick = true
                    info.checked = unit[flagKey]
                    info.disabled = not unit.isNPC
                    info.func = function()
                        unit[flagKey] = not unit[flagKey]
                        self:Refresh()
                        -- Sync action bar button colors if controlling this unit
                        local ABW = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
                        if ABW and ABW._controlledUnitId == unit.id then
                            ABW:_UpdateFlagButtonColors(unit)
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)
                end

                addFlagOption("active", "Active")
                addFlagOption("hidden", "Hidden")
                addFlagOption("flying", "Flying")
            end
        end)
    end)


    self:Refresh()
end

function EventUnitsSheet:UpdateFilterText()
    local count = 0
    for _, v in pairs(self.filterTeams or {}) do if v then count = count + 1 end end
    for _, v in pairs(self.filterMarkers or {}) do if v then count = count + 1 end end

    if count == 0 then
        self.unitFilterBtn:SetText("Filter: None")
    else
        self.unitFilterBtn:SetText("Filter: " .. count)
    end
end

function EventUnitsSheet:Refresh()
    local ev = RPE.Core.ActiveEvent
    if not ev or not ev.units then
        if RPE.Core.ActiveSupergroup and RPE.Core.ActiveSupergroup.Rebuild then
            RPE.Core.ActiveSupergroup:Rebuild()
        end
        return
    end

    self:UpdateFilterText()

    local markerIcons = {}
    for i = 1, 8 do
        markerIcons[i] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i .. ":12:12|t"
    end

    local rows = {}
    for _, u in pairs(ev.units) do
        local team = u.team or 1
        -- If filters exist, show only items that match the filter
        local teamMatch = self.filterTeams[team]
        
        -- Check marker match: marked units must match a checked marker, unmarked units must have unmarked checked
        local markerMatch = false
        if u.raidMarker and u.raidMarker > 0 then
            -- Unit has a marker, check if that marker is selected
            markerMatch = self.filterMarkers[u.raidMarker]
        else
            -- Unit is unmarked, check if unmarked is selected
            markerMatch = self.filterMarkers.unmarked
        end

        if teamMatch and markerMatch then
            local teamColorKey = "team" .. tostring(team)
            local r, g, b = RPE_UI.Colors.Get(teamColorKey)
            local colorHex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)

            local name = u.name or u.key or ""
            if not u.isNPC and name:find("-") then
                name = name:match("^[^-]+") or name
                name = name:sub(1,1):upper() .. name:sub(2):lower()
            end

            if u.raidMarker and markerIcons[u.raidMarker] then
                name = markerIcons[u.raidMarker] .. " " .. name
            end

            rows[#rows+1] = {
                key        = u.key,
                teamRaw    = team,
                team       = string.format("%s%d|r", colorHex, team),
                id         = u.id or 0,
                name       = name,
                initiative = tonumber(u.initiative) or 0,
                hp         = string.format("%d / %d", tonumber(u.hp or 0), tonumber(u.hpMax or 0)),
                active     = u.active and RPE.Common.InlineIcons.Check or "",
                hidden     = u.hidden and RPE.Common.InlineIcons.Hidden or "",
                flying     = u.flying and RPE.Common.InlineIcons.Flying or "",
            }
        end
    end

    local total = #rows
    local startIdx = (self.page - 1) * self.pageSize + 1
    if startIdx > total then
        self.page = 1
        startIdx = 1
    end
    local endIdx = math.min(startIdx + self.pageSize - 1, total)
    local pageRows = {}
    for i = startIdx, endIdx do
        pageRows[#pageRows+1] = rows[i]
    end

    self.table:SetRows(pageRows)
    self.table:Refresh()

    -- Add tooltip to each table row
    local visibleRows = self.table.rows or {}
    for i = 1, #pageRows do
        local data = pageRows[i]
        local row = visibleRows[i]
        local unit = RPE.Core.ActiveEvent and RPE.Core.ActiveEvent.units and RPE.Core.ActiveEvent.units[data.key]
        if row and unit and row.SetScript then
            row:SetScript("OnEnter", function()
                -- Check if hidden units should be masked
                if unit.hidden then
                    local isLeader = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()
                    local ev = RPE.Core and RPE.Core.ActiveEvent
                    local localPlayerKey = ev and ev.localPlayerKey
                    local isAlly = localPlayerKey and unit.team and 
                        ev.units[localPlayerKey] and 
                        ev.units[localPlayerKey].team == unit.team
                    
                    if not isLeader and not isAlly then
                        -- Show "Unknown Enemy" for non-leader non-allies
                        RPE.Common:ShowTooltip(row, {
                            title = "Unknown Enemy",
                            titleColor = { 1, 0.2, 0.2 },
                            lines = {},
                        })
                        return
                    end
                end
                
                -- Build tooltip spec using Unit:GetTooltip()
                local spec = unit:GetTooltip({ health = true, initiative = true })
                if spec then
                    -- Add help text at the bottom
                    table.insert(spec.lines, { left = " " })  -- spacer
                    table.insert(spec.lines, {
                        left = "<Shift + LMB> to toggle Active",
                        r = 0.7, g = 0.7, b = 0.7,
                        wrap = false
                    })
                    table.insert(spec.lines, {
                        left = "<Ctrl + LMB> to toggle Hidden",
                        r = 0.7, g = 0.7, b = 0.7,
                        wrap = false
                    })
                    table.insert(spec.lines, {
                        left = "<Alt + LMB> to toggle Flying",
                        r = 0.7, g = 0.7, b = 0.7,
                        wrap = false
                    })
                    table.insert(spec.lines, {
                        left = "<RMB> to show menu",
                        r = 0.7, g = 0.7, b = 0.7,
                        wrap = false
                    })
                    RPE.Common:ShowTooltip(row, spec)
                end
            end)
            row:SetScript("OnLeave", function()
                RPE.Common:HideTooltip()
            end)
        end
    end

end

function EventUnitsSheet.New(opts)
    local self = setmetatable({}, EventUnitsSheet)
    self:BuildUI(opts or {})
    _G.RPE_UI.Windows.EventUnitsSheetInstance = self
    return self
end

return EventUnitsSheet
