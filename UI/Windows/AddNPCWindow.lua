-- RPE_UI/Windows/AddNPCWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local Dropdown = RPE_UI.Elements.Dropdown
local HBorder  = RPE_UI.Elements.HorizontalBorder
local C        = RPE_UI.Colors

local NPCRegistry = RPE.Core and RPE.Core.NPCRegistry

---@class AddNPCWindow
local AddNPCWindow = {}
_G.RPE_UI.Windows.AddNPCWindow = AddNPCWindow
AddNPCWindow.__index = AddNPCWindow
AddNPCWindow.Name = "AddNPCWindow"

local RAID_MARKERS = {
    [0] = "(none)",
    [1] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    [2] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
    [3] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    [4] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
    [5] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
    [6] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    [7] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    [8] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}

-- collect sorted NPC ids/names
local function _collectNPCs()
    local list = {}
    if NPCRegistry and NPCRegistry.Pairs then
        for id, proto in NPCRegistry:Pairs() do
            list[#list+1] = { id = id, name = proto.name or id }
        end
    end
    table.sort(list, function(a,b)
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)
    return list
end

function AddNPCWindow:BuildUI(opts)
    opts = opts or {}
    
    -- Use WorldFrame in immersion mode so window shows when UI is hidden
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    
    self.root = Window:New("RPE_AddNPC_Window", {
        parent = parentFrame, 
        width = 380,  -- will be resized by autoSize
        height = 90, -- will be resized by autoSize
        point = "CENTER",
        autoSize = true,
        autoSizePadX = 0,
        autoSizePadY = 0,
    })

    -- Handle immersion mode scaling and mouse interaction
    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("FULLSCREEN_DIALOG")  -- Higher strata to appear above event window
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
        
        if UIParent then
            UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
            UIParent:HookScript("OnHide", function() UpdateMouseForUIVisibility() end)
        end

        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Set opaque background using a slightly darker shade of background color
    local r, g, b, _ = C.Get("background")
    self.root.frame:SetBackdropColor(r * 0.9, g * 0.9, b * 0.9, 1)

    -- Top border (stretched full width)
    self.topBorder = HBorder:New("RPE_AddNPC_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 1,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    if RPE_UI.Colors and RPE_UI.Colors.ApplyHighlight then
        RPE_UI.Colors.ApplyHighlight(self.topBorder)
    end

    -- Bottom border (stretched full width)
    self.bottomBorder = HBorder:New("RPE_AddNPC_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 1,
        y             = 0,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    if RPE_UI.Colors and RPE_UI.Colors.ApplyHighlight then
        RPE_UI.Colors.ApplyHighlight(self.bottomBorder)
    end

    self.sheet = VGroup:New("RPE_AddNPC_Sheet", {
        parent   = self.root,
        spacingY = 10,
        alignH   = "CENTER",
        alignV   = "TOP",
        padding  = { left = 4, right = 4, top = 12, bottom = 12 },
        autoSize = true,
    })
    self.root:Add(self.sheet)
    
    -- Position sheet to respect window bounds
    self.sheet.frame:ClearAllPoints()
    self.sheet.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.sheet.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)

    -- Title
    self.title = Text:New("RPE_AddNPC_Title", {
        parent = self.sheet, text = "Add NPC", fontTemplate = "GameFontNormalLarge",
    })
    self.title:SetJustifyH("CENTER")
    self.sheet:Add(self.title)

    -- Row: dropdown + name label
    local npcRow = HGroup:New("RPE_AddNPC_NpcRow", {
        parent = self.sheet, spacingX = 12, alignV = "CENTER", alignH = "CENTER", autoSize = true,
    })
    self.sheet:Add(npcRow)

    local npcs = _collectNPCs()
    local npcChoices, npcMap = {}, {}
    for _, e in ipairs(npcs) do
        npcChoices[#npcChoices+1] = e.name   -- what the dropdown displays
        npcMap[e.name] = e.id               -- map name -> id
    end

    self.npcDropdown = Dropdown:New("RPE_AddNPC_Dropdown", {
        parent = npcRow, width = 180, choices = npcChoices,
        onChanged = function(_, val) -- val is the name
            local id = npcMap[val]
            if id then
                for _, e in ipairs(npcs) do
                    if e.id == id then
                        self._selectedNpc = e
                        self:UpdateNameLabel()
                    end
                end
            end
        end,
    })
    npcRow:Add(self.npcDropdown)
    
    -- Set default NPC to first in list
    if npcs[1] then
        self._selectedNpc = npcs[1]
    end
    
    -- Add dropdown borders
    if self.npcDropdown.frame then
        local topDropdownBorder = HBorder:New("RPE_AddNPC_DropdownTopBorder", {
            parent = self.npcDropdown,
            stretch = true,
            thickness = 1,
            y = 0,
            layer = "OVERLAY",
        })
        topDropdownBorder.frame:ClearAllPoints()
        topDropdownBorder.frame:SetPoint("TOPLEFT", self.npcDropdown.frame, "TOPLEFT", 0, 0)
        topDropdownBorder.frame:SetPoint("TOPRIGHT", self.npcDropdown.frame, "TOPRIGHT", 0, 0)
        if RPE_UI.Colors and RPE_UI.Colors.ApplyHighlight then
            RPE_UI.Colors.ApplyHighlight(topDropdownBorder)
        end

        local bottomDropdownBorder = HBorder:New("RPE_AddNPC_DropdownBottomBorder", {
            parent = self.npcDropdown,
            stretch = true,
            thickness = 1,
            y = 0,
            layer = "OVERLAY",
        })
        bottomDropdownBorder.frame:ClearAllPoints()
        bottomDropdownBorder.frame:SetPoint("BOTTOMLEFT", self.npcDropdown.frame, "BOTTOMLEFT", 0, 0)
        bottomDropdownBorder.frame:SetPoint("BOTTOMRIGHT", self.npcDropdown.frame, "BOTTOMRIGHT", 0, 0)
        if RPE_UI.Colors and RPE_UI.Colors.ApplyHighlight then
            RPE_UI.Colors.ApplyHighlight(bottomDropdownBorder)
        end
    end

    self.nameLabel = Text:New("RPE_AddNPC_NameLabel", {
        parent = npcRow, text = "(no NPC selected)", fontTemplate = "GameFontNormal",
    })
    self.nameLabel:SetJustifyH("CENTER")
    npcRow:Add(self.nameLabel)

    -- Raid marker row
    local markerRow = HGroup:New("RPE_AddNPC_MarkerRow", {
        parent = self.sheet, spacingX = 4, alignV = "CENTER", alignH = "CENTER", autoSize = true,
    })
    self.sheet:Add(markerRow)

    self._selectedMarker = 0
    self._markerButtons = {}  -- store button references for feedback
    for i = 0, 8 do
        local btn = TextBtn:New("RPE_AddNPC_Marker_"..i, {
            parent = markerRow, width = 28, height = 28,
            text = (i==0) and "X" or "",
            onClick = function()
                self._selectedMarker = i
                self:UpdateMarkerButtonFeedback()
                self:UpdateNameLabel()
            end,
        })
        if i > 0 and btn.frame then
            btn.frame:SetNormalTexture(RAID_MARKERS[i])
        end
        -- Apply darker background color
        if btn.bg then
            local r, g, b = C.Get("background")
            btn.bg:SetColorTexture(r * 0.9, g * 0.9, b * 0.9, 1)
        end
        markerRow:Add(btn)
        self._markerButtons[i] = btn
    end

    -- Flag buttons row (active, hidden, flying)
    local flagRow = HGroup:New("RPE_AddNPC_FlagRow", {
        parent = self.sheet, spacingX = 8, alignV = "CENTER", alignH = "CENTER", autoSize = true,
    })
    self.sheet:Add(flagRow)

    -- Determine default for active flag based on whether event is running
    local isEventRunning = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader() and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:IsRunning()
    self._selectedActive = isEventRunning and true or false
    self._selectedHidden = false
    self._selectedFlying = false

    local IconBtn = RPE_UI.Elements.IconButton
    
    self.activeBtn = IconBtn:New("RPE_AddNPC_Active", {
        parent = flagRow,
        width = 24,
        height = 24,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\check.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Toggle Active",
        onClick = function()
            self._selectedActive = not self._selectedActive
            self:UpdateFlagButtonColors()
        end,
    })
    flagRow:Add(self.activeBtn)

    self.hiddenBtn = IconBtn:New("RPE_AddNPC_Hidden", {
        parent = flagRow,
        width = 24,
        height = 24,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\hidden.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Toggle Hidden",
        onClick = function()
            self._selectedHidden = not self._selectedHidden
            self:UpdateFlagButtonColors()
        end,
    })
    flagRow:Add(self.hiddenBtn)

    self.flyingBtn = IconBtn:New("RPE_AddNPC_Flying", {
        parent = flagRow,
        width = 24,
        height = 24,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\flying.png",
        noBackground = true, hasBackground = false,
        noBorder = true, hasBorder = false,
        tooltip = "Toggle Flying",
        onClick = function()
            self._selectedFlying = not self._selectedFlying
            self:UpdateFlagButtonColors()
        end,
    })
    flagRow:Add(self.flyingBtn)
    
    self:UpdateFlagButtonColors()

    -- Team row
    local teamRow = HGroup:New("RPE_AddNPC_TeamRow", {
        parent = self.sheet, spacingX = 8, alignV = "CENTER", alignH = "CENTER", autoSize = true,
    })
    self.sheet:Add(teamRow)

    self._selectedTeam = opts.team or 2
    local maxTeams = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_teams) or 4
    for t=1,maxTeams do
        local btn = TextBtn:New("RPE_AddNPC_Team_"..t, {
            parent = teamRow, width = 70, height = 24,
            text = ("Team %d"):format(t),
            onClick = function()
                self._selectedTeam = t
                self:UpdateNameLabel()
            end,
        })
        -- Apply darker background color
        if btn.bg then
            local r, g, b = C.Get("background")
            btn.bg:SetColorTexture(r * 0.9, g * 0.9, b * 0.9, 1)
        end
        teamRow:Add(btn)
    end

    -- Footer: confirm and cancel
    local buttonRow = HGroup:New("RPE_AddNPC_ButtonRow", {
        parent = self.sheet, spacingX = 8, alignV = "CENTER", alignH = "CENTER", autoSize = true,
    })
    self.sheet:Add(buttonRow)

    self.confirmBtn = TextBtn:New("RPE_AddNPC_Confirm", {
        parent = buttonRow, width = 100, height = 24,
        text = "Add NPC",
        onClick = function()
            if self._selectedNpc and self._onConfirm then
                self:RecordSelection()  -- Save current selection as defaults
                self._onConfirm(self._selectedNpc.id, self._selectedTeam, (self._selectedMarker ~= 0) and self._selectedMarker or nil, {
                    active = self._selectedActive,
                    hidden = self._selectedHidden,
                    flying = self._selectedFlying,
                })
                -- Only hide if Shift key is not held
                if not IsShiftKeyDown() then
                    self:Hide()
                end
            end
        end,
    })
    -- Apply darker background color
    if self.confirmBtn.bg then
        local r, g, b = C.Get("background")
        self.confirmBtn.bg:SetColorTexture(r * 0.9, g * 0.9, b * 0.9, 1)
    end
    buttonRow:Add(self.confirmBtn)

    self.cancelBtn = TextBtn:New("RPE_AddNPC_Cancel", {
        parent = buttonRow, width = 100, height = 24,
        text = "Cancel",
        onClick = function()
            self:Hide()
        end,
    })
    -- Apply darker background color
    if self.cancelBtn.bg then
        local r, g, b = C.Get("background")
        self.cancelBtn.bg:SetColorTexture(r * 0.9, g * 0.9, b * 0.9, 1)
    end
    buttonRow:Add(self.cancelBtn)
end

function AddNPCWindow:UpdateNameLabel()
    local txt = self._selectedNpc and self._selectedNpc.name or "(no NPC)"
    if self._selectedMarker and self._selectedMarker > 0 then
        txt = "|T"..RAID_MARKERS[self._selectedMarker]..":0|t "..txt
    end
    if self._selectedTeam then
        local colorKey = "team"..tostring(self._selectedTeam)
        local r,g,b = C.Get(colorKey)
        self.nameLabel:SetColor(r,g,b,1)
    end
    self.nameLabel:SetText(txt)
end

function AddNPCWindow:UpdateMarkerButtonFeedback()
    if not self._markerButtons then return end
    for i, btn in pairs(self._markerButtons) do
        if btn and btn.topBorder and btn.bottomBorder then
            if i == self._selectedMarker then
                -- Selected button: show borders with accent color
                local r, g, b = C.Get("divider")
                if btn.topBorder then 
                    btn.topBorder:SetColorTexture(r, g, b, 1)
                    btn.topBorder:SetAlpha(1)
                end
                if btn.bottomBorder then 
                    btn.bottomBorder:SetColorTexture(r, g, b, 1)
                    btn.bottomBorder:SetAlpha(1)
                end
            else
                -- Unselected buttons: hide borders
                if btn.topBorder then btn.topBorder:SetAlpha(0) end
                if btn.bottomBorder then btn.bottomBorder:SetAlpha(0) end
            end
        end
    end
end

function AddNPCWindow:UpdateFlagButtonColors()
    local textBonusR, textBonusG, textBonusB = C.Get("textBonus")
    
    -- Active button
    if self.activeBtn then
        if self._selectedActive then
            self.activeBtn:SetColor(textBonusR, textBonusG, textBonusB, 1)
        else
            self.activeBtn:SetColor(0.5, 0.5, 0.5, 0.6)
        end
    end
    
    -- Hidden button
    if self.hiddenBtn then
        if self._selectedHidden then
            self.hiddenBtn:SetColor(textBonusR, textBonusG, textBonusB, 1)
        else
            self.hiddenBtn:SetColor(0.5, 0.5, 0.5, 0.6)
        end
    end
    
    -- Flying button
    if self.flyingBtn then
        if self._selectedFlying then
            self.flyingBtn:SetColor(textBonusR, textBonusG, textBonusB, 1)
        else
            self.flyingBtn:SetColor(0.5, 0.5, 0.5, 0.6)
        end
    end
end

function AddNPCWindow:Show() if self.root then self.root:Show() end end
function AddNPCWindow:Hide() if self.root then self.root:Hide() end end

function AddNPCWindow.Open(opts)
    if not AddNPCWindow.instance then
        AddNPCWindow.instance = setmetatable({}, AddNPCWindow)
        AddNPCWindow.instance:BuildUI(opts or {})
    end
    local instance = AddNPCWindow.instance
    
    -- Restore last used settings if available, otherwise use defaults
    instance._selectedMarker = instance._lastMarker or 0
    instance._selectedTeam = instance._lastTeam or (opts and opts.team or 2)
    instance._selectedActive = instance._lastActive ~= nil and instance._lastActive or (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader() and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent:IsRunning() and true or false)
    instance._selectedHidden = instance._lastHidden or false
    instance._selectedFlying = instance._lastFlying or false
    instance._onConfirm = opts and opts.onConfirm
    instance:UpdateMarkerButtonFeedback()
    instance:UpdateNameLabel()
    instance:Show()
    return instance
end

function AddNPCWindow:RecordSelection()
    -- Save the current selection as defaults for next time
    self._lastMarker = self._selectedMarker
    self._lastTeam = self._selectedTeam
    self._lastNpc = self._selectedNpc
    self._lastActive = self._selectedActive
    self._lastHidden = self._selectedHidden
    self._lastFlying = self._selectedFlying
end

return AddNPCWindow
