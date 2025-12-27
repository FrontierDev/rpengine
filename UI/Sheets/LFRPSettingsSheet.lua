-- RPE_UI/Sheets/LFRPSettingsSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local IconButton = RPE_UI.Elements.IconButton
local Checkbox = RPE_UI.Elements.Checkbox
local MultiSelectDropdown = RPE_UI.Elements.MultiSelectDropdown
local C        = RPE_UI.Colors

-- Fixed widths for alignment
local LABEL_WIDTH = 220
local DROPDOWN_WIDTH = 180
local ROW_SPACING_X = 10
local MAX_SELECTIONS = 5

-- "I am ..." choices with numerical IDs
local I_AM_CHOICES = RPE.Common.I_Am_Choices

-- "Looking for ..." choices with numerical IDs
local LOOKING_FOR_CHOICES = RPE.Common.Looking_For_Choices

---@class LFRPSettingsSheet
---@field sheet VGroup
---@field trpNameText Text
---@field statusText Text
---@field toggleBtn TextBtn
---@field iAmDropdown MultiSelectDropdown
---@field lookingForDropdown MultiSelectDropdown
---@field iAmSelected table
---@field lookingForSelected table
local LFRPSettingsSheet = {}
_G.RPE_UI.Windows.LFRPSettingsSheet = LFRPSettingsSheet
LFRPSettingsSheet.__index = LFRPSettingsSheet
LFRPSettingsSheet.Name = "LFRPSettingsSheet"

-- unique id helper
local _uid = 0
local function _name(prefix) _uid=_uid+1; return string.format("%s_%04d", prefix or "RPE_LFRP", _uid) end

local function _label(parent, text)
    local lbl = Text:New(_name("RPE_LFRP_Label"), {
        parent       = parent,
        width        = LABEL_WIDTH,
        height       = 24,
        text         = text or "",
        justifyH     = "RIGHT",
        fontTemplate = "GameFontNormal",
    })
    -- Enforce exact width (some Text implementations auto-size)
    if lbl.frame and lbl.frame.SetWidth then
        lbl.frame:SetWidth(LABEL_WIDTH)
    end
    -- Set font string width for proper right-alignment
    if lbl.fs and lbl.fs.SetWidth then
        lbl.fs:SetWidth(LABEL_WIDTH)
    end
    return lbl
end

function LFRPSettingsSheet.New(opts)
    local self = setmetatable({}, LFRPSettingsSheet)
    opts = opts or {}

    -- Initialize tag selections
    self.iAmSelected = {}
    self.lookingForSelected = {}

    -- Root VGroup for the sheet
    self.sheet = VGroup:New("RPE_LFRP_SettingsSheet", {
        parent     = opts.parent,
        width      = 1, height = 1,
        point      = "TOP", relativePoint = "TOP",
        padding    = { left = 0, right = 20, top = 20, bottom = 20 },
        spacingY   = 10,
        alignH     = "LEFT",
        autoSize   = true,
    })

    -- === TRP Info Section (with Auto Rejoin button in top right) ===
    local trpHGroup = HGroup:New(_name("RPE_LFRP_TRPHGroup"), {
        parent = self.sheet,
        autoSize = true,
        spacingX = 8,
        alignH = "LEFT",
        alignV = "CENTER",
    })
    self.sheet:Add(trpHGroup)

    local refreshBtn = IconButton:New(_name("RPE_LFRP_RefreshTRPBtn"), {
        parent = trpHGroup,
        width = 16,
        height = 16,
        hasBackground = false, noBackground = true,
        hasBorder = false, noBorder = true,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\refresh.png",
        tooltip = "Refresh TRP Name",
        onClick = function()
            self:RefreshTRPInfo()
        end,
    })
    trpHGroup:Add(refreshBtn)

    self.trpNameText = Text:New(_name("RPE_LFRP_TRPName"), {
        parent = trpHGroup,
        text = "Unknown",
        fontTemplate = "GameFontNormal",
    })
    trpHGroup:Add(self.trpNameText)

    -- === "I am ..." section ===
    local iAmRow = HGroup:New(_name("RPE_LFRP_IAmRow"), {
        parent   = self.sheet,
        spacingX = ROW_SPACING_X,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.iAmLabel = _label(iAmRow, "I am ...")
    self.iAmDropdown = MultiSelectDropdown:New(_name("RPE_LFRP_IAmDropdown"), {
        parent = iAmRow,
        width  = DROPDOWN_WIDTH,
        height = 24,
        choices = I_AM_CHOICES,
        noBorder = false,
        onChanged = function(dd, selected)
            self.iAmSelected = selected or {}
            self:UpdateIAmLabel()
        end,
    })
    if self.iAmDropdown.frame and self.iAmDropdown.frame.SetWidth then
        self.iAmDropdown.frame:SetWidth(DROPDOWN_WIDTH)
    end
    iAmRow:Add(self.iAmLabel)
    iAmRow:Add(self.iAmDropdown)
    self.sheet:Add(iAmRow)

    -- === "Looking for ..." section ===
    local lookingForRow = HGroup:New(_name("RPE_LFRP_LookingForRow"), {
        parent   = self.sheet,
        spacingX = ROW_SPACING_X,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.lookingForLabel = _label(lookingForRow, "Looking for ...")
    self.lookingForDropdown = MultiSelectDropdown:New(_name("RPE_LFRP_LookingForDropdown"), {
        parent = lookingForRow,
        width  = DROPDOWN_WIDTH,
        height = 24,
        choices = LOOKING_FOR_CHOICES,
        noBorder = false,
        onChanged = function(dd, selected)
            self.lookingForSelected = selected or {}
            self:UpdateLookingForLabel()
        end,
    })
    if self.lookingForDropdown.frame and self.lookingForDropdown.frame.SetWidth then
        self.lookingForDropdown.frame:SetWidth(DROPDOWN_WIDTH)
    end
    lookingForRow:Add(self.lookingForLabel)
    lookingForRow:Add(self.lookingForDropdown)
    self.sheet:Add(lookingForRow)

    -- === Checkboxes Section ===
    local checkboxRow = HGroup:New(_name("RPE_LFRP_CheckboxRow"), {
        parent   = self.sheet,
        spacingX = 20,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(checkboxRow)

    -- Broadcast Location checkbox
    local broadcastLocationGroup = HGroup:New(_name("RPE_LFRP_BroadcastLocationGroup"), {
        parent   = checkboxRow,
        spacingX = 8,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    local broadcastLocationLabel = Text:New(_name("RPE_LFRP_BroadcastLocationLabel"), {
        parent = broadcastLocationGroup,
        text = "Broadcast Location",
        fontTemplate = "GameFontNormal",
    })
    broadcastLocationGroup:Add(broadcastLocationLabel)
    self.broadcastLocationCheckbox = Checkbox:New(_name("RPE_LFRP_BroadcastLocationCheckbox"), {
        parent = broadcastLocationGroup,
        checked = false,
    })
    broadcastLocationGroup:Add(self.broadcastLocationCheckbox)
    checkboxRow:Add(broadcastLocationGroup)

    -- Recruiting/Recruitable checkbox
    local recruitingLabel = IsInGuild() and "Recruiting" or "Recruitable"
    local recruitingGroup = HGroup:New(_name("RPE_LFRP_RecruitingGroup"), {
        parent   = checkboxRow,
        spacingX = 8,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    local recruitingLabelText = Text:New(_name("RPE_LFRP_RecruitingLabel"), {
        parent = recruitingGroup,
        text = recruitingLabel,
        fontTemplate = "GameFontNormal",
    })
    recruitingGroup:Add(recruitingLabelText)
    self.recruitingCheckbox = Checkbox:New(_name("RPE_LFRP_RecruitingCheckbox"), {
        parent = recruitingGroup,
        checked = false,
    })
    recruitingGroup:Add(self.recruitingCheckbox)
    checkboxRow:Add(recruitingGroup)

    -- Approachable checkbox
    local approachableGroup = HGroup:New(_name("RPE_LFRP_ApproachableGroup"), {
        parent   = checkboxRow,
        spacingX = 8,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    local approachableLabel = Text:New(_name("RPE_LFRP_ApproachableLabel"), {
        parent = approachableGroup,
        text = "Approachable",
        fontTemplate = "GameFontNormal",
    })
    approachableGroup:Add(approachableLabel)
    self.approachableCheckbox = Checkbox:New(_name("RPE_LFRP_ApproachableCheckbox"), {
        parent = approachableGroup,
        checked = false,
    })
    approachableGroup:Add(self.approachableCheckbox)
    checkboxRow:Add(approachableGroup)

    -- === Control Section ===
    local controlHGroup = HGroup:New(_name("RPE_LFRP_ControlHGroup"), {
        parent = self.sheet,
        width = 400,
        autoSize = false,
        alignH = "CENTER",
        alignV = "CENTER",
        spacingX = 12,
    })
    self.sheet:Add(controlHGroup)

    self.autoRejoinBtn = IconButton:New(_name("RPE_LFRP_AutoRejoinBtn"), {
        parent = controlHGroup,
        width = 24,
        height = 24,
        noBackground = true,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\rejoin.png",
        tooltip = "Toggle Auto Rejoin\n\nWhen enabled (green), you will automatically rejoin LFRP on login and resume broadcasting with your saved settings.",
        onClick = function()
            self:ToggleAutoRejoin()
        end,
    })
    controlHGroup:Add(self.autoRejoinBtn)
    
    -- Initialize button color based on current setting
    self:UpdateAutoRejoinButton()

    self.toggleBtn = TextBtn:New(_name("RPE_LFRP_ToggleBtn"), {
        parent = controlHGroup,
        width = 120,
        height = 28,
        text = "Enable LFRP",
        noBorder = false,
        onClick = function()
            self:ToggleLFRP()
        end,
    })
    controlHGroup:Add(self.toggleBtn)

    self.statusText = Text:New(_name("RPE_LFRP_StatusText"), {
        parent = controlHGroup,
        text = "LFRP Disabled",
        fontTemplate = "GameFontNormal",
    })
    controlHGroup:Add(self.statusText)

    local closeBtn = TextBtn:New(_name("RPE_LFRP_CloseBtn"), {
        parent = controlHGroup,
        width = 120,
        height = 28,
        text = "Close",
        noBorder = false,
        onClick = function()
            local win = RPE_UI.Common:GetWindow("LFRPWindow")
            if win then
                RPE_UI.Common:Toggle(win)
            end
        end,
    })
    controlHGroup:Add(closeBtn)

    -- Initialize display
    self:RefreshTRPInfo()
    self:UpdateStatusDisplay()
    self:UpdateIAmLabel()
    self:UpdateLookingForLabel()
    self:LoadLFRPSettingsFromProfile()

    return self
end

function LFRPSettingsSheet:AddIAmTag(tag)
    -- Don't add if already selected or at max
    for _, t in ipairs(self.iAmSelected) do
        if t == tag then return end
    end
    if #self.iAmSelected >= MAX_SELECTIONS then return end

    table.insert(self.iAmSelected, tag)
    self:UpdateIAmLabel()
end

function LFRPSettingsSheet:RemoveIAmTag(tag)
    for i, t in ipairs(self.iAmSelected) do
        if t == tag then
            table.remove(self.iAmSelected, i)
            self:UpdateIAmLabel()
            return
        end
    end
end

function LFRPSettingsSheet:UpdateIAmLabel()
    local labels = self.iAmDropdown:GetLabels()
    local count = #labels
    local text
    if count == 0 then
        text = "I am ..."
    else
        text = "I am ... " .. table.concat(labels, ", ")
    end
    self.iAmLabel:SetText(text)
    -- Re-apply fixed width after SetText (which calls ResizeToText)
    if self.iAmLabel.frame then self.iAmLabel.frame:SetWidth(LABEL_WIDTH) end
    if self.iAmLabel.fs then self.iAmLabel.fs:SetWidth(LABEL_WIDTH) end
end

function LFRPSettingsSheet:AddLookingForTag(tag)
    -- Don't add if already selected or at max
    for _, t in ipairs(self.lookingForSelected) do
        if t == tag then return end
    end
    if #self.lookingForSelected >= MAX_SELECTIONS then return end

    table.insert(self.lookingForSelected, tag)
    self:UpdateLookingForLabel()
end

function LFRPSettingsSheet:RemoveLookingForTag(tag)
    for i, t in ipairs(self.lookingForSelected) do
        if t == tag then
            table.remove(self.lookingForSelected, i)
            self:UpdateLookingForLabel()
            return
        end
    end
end

function LFRPSettingsSheet:UpdateLookingForLabel()
    local labels = self.lookingForDropdown:GetLabels()
    local count = #labels
    local text
    if count == 0 then
        text = "Looking for ..."
    else
        text = "Looking for ... " .. table.concat(labels, ", ")
    end
    self.lookingForLabel:SetText(text)
    -- Re-apply fixed width after SetText (which calls ResizeToText)
    if self.lookingForLabel.frame then self.lookingForLabel.frame:SetWidth(LABEL_WIDTH) end
    if self.lookingForLabel.fs then self.lookingForLabel.fs:SetWidth(LABEL_WIDTH) end
end

function LFRPSettingsSheet:SerializeSettings()
    -- Get TRP3 name (with fallback to character name)
    local trpName = ""
    local getter = RPE and RPE.Common and RPE.Common.GetTRP3NameForUnit
    if getter then
        local ok, name = pcall(function()
            return RPE.Common:GetTRP3NameForUnit("player")
        end)
        if ok and name and name ~= "" then
            trpName = name
        end
    end
    
    -- Get guild name
    local guildName = GetGuildInfo("player") or ""
    
    -- Get IDs from dropdowns (returns sorted array)
    local iAmIds = self.iAmDropdown:GetValue() or {}
    local lookingForIds = self.lookingForDropdown:GetValue() or {}
    
    -- Pad both to exactly 5 items with 0s
    while #iAmIds < 5 do
        table.insert(iAmIds, 0)
    end
    while #lookingForIds < 5 do
        table.insert(lookingForIds, 0)
    end
    
    -- Truncate to exactly 5 (shouldn't happen with MaxSelections = 5, but be safe)
    iAmIds = { iAmIds[1], iAmIds[2], iAmIds[3], iAmIds[4], iAmIds[5] }
    lookingForIds = { lookingForIds[1], lookingForIds[2], lookingForIds[3], lookingForIds[4], lookingForIds[5] }
    
    -- Determine recruiting status: 0 = no, 1 = recruiting, 2 = recruitable
    local recruitingStatus = 0
    if self.recruitingCheckbox and self.recruitingCheckbox.check and self.recruitingCheckbox.check:GetChecked() then
        recruitingStatus = IsInGuild() and 1 or 2
    end
    
    -- Determine approachable status: 0 = no, 1 = yes
    local approachableStatus = (self.approachableCheckbox and self.approachableCheckbox.check and self.approachableCheckbox.check:GetChecked()) and 1 or 0
    
    -- Determine if broadcast location is enabled
    local broadcastLocation = (self.broadcastLocationCheckbox and self.broadcastLocationCheckbox.check and self.broadcastLocationCheckbox.check:GetChecked()) or false
    
    return {
        trpName = trpName,
        guildName = guildName,
        iAm = iAmIds,
        lookingFor = lookingForIds,
        recruiting = recruitingStatus,
        approachable = approachableStatus,
        broadcastLocation = broadcastLocation,
    }
end

-- Static helper to serialize LFRP settings from profile (used by auto-rejoin)
function LFRPSettingsSheet.SerializeSettingsFromProfile(profile)
    -- Get TRP3 name (with fallback to character name)
    local trpName = ""
    local getter = RPE and RPE.Common and RPE.Common.GetTRP3NameForUnit
    if getter then
        local ok, name = pcall(function()
            return RPE.Common:GetTRP3NameForUnit("player")
        end)
        if ok and name and name ~= "" then
            trpName = name
        end
    end
    
    -- Get guild name
    local guildName = GetGuildInfo("player") or ""
    
    -- Get saved LFRP settings from profile
    local iAmIds = {}
    local lookingForIds = {}
    local broadcastLocation = false
    local recruiting = false
    local approachable = false
    
    if profile and profile.lfrpSettings then
        iAmIds = profile.lfrpSettings.iAmIds or {}
        lookingForIds = profile.lfrpSettings.lookingForIds or {}
        broadcastLocation = profile.lfrpSettings.broadcastLocation or false
        recruiting = profile.lfrpSettings.recruiting or false
        approachable = profile.lfrpSettings.approachable or false
    end
    
    -- Pad to exactly 5 items with 0s
    while #iAmIds < 5 do
        table.insert(iAmIds, 0)
    end
    while #lookingForIds < 5 do
        table.insert(lookingForIds, 0)
    end
    
    -- Truncate to exactly 5
    iAmIds = { iAmIds[1], iAmIds[2], iAmIds[3], iAmIds[4], iAmIds[5] }
    lookingForIds = { lookingForIds[1], lookingForIds[2], lookingForIds[3], lookingForIds[4], lookingForIds[5] }
    
    -- Determine recruiting status: 0 = no, 1 = recruiting, 2 = recruitable
    local recruitingStatus = 0
    if recruiting then
        recruitingStatus = IsInGuild() and 1 or 2
    end
    
    -- Determine approachable status: 0 = no, 1 = yes
    local approachableStatus = approachable and 1 or 0
    
    return {
        trpName = trpName,
        guildName = guildName,
        iAm = iAmIds,
        lookingFor = lookingForIds,
        recruiting = recruitingStatus,
        approachable = approachableStatus,
        broadcastLocation = broadcastLocation,
    }
end

function LFRPSettingsSheet:RefreshTRPInfo()
    local getter = RPE and RPE.Common and RPE.Common.GetTRP3NameForUnit
    local displayName = "Unknown"
    
    if getter then
        local ok, name = pcall(function()
            return RPE.Common:GetTRP3NameForUnit("player")
        end)
        if ok and name and name ~= "" then
            displayName = RPE.Common.InlineIcons.RPE .. " LFRP as " .. name
        else
            -- Fallback to player name without server name, title-cased
            local playerName = UnitName("player")
            if playerName then
                -- Remove server name (everything after hyphen)
                playerName = playerName:match("^([^-]+)") or playerName
                -- Title case the name
                displayName = RPE.Common.InlineIcons.RPE .. " LFRP as " .. playerName:sub(1, 1):upper() .. playerName:sub(2):lower()
            end
        end
    else
        -- Fallback to player name without server name, title-cased
        local playerName = UnitName("player")
        if playerName then
            -- Remove server name (everything after hyphen)
            playerName = playerName:match("^([^-]+)") or playerName
            -- Title case the name
            displayName = RPE.Common.InlineIcons.RPE .. " LFRP as " .. playerName:sub(1, 1):upper() .. playerName:sub(2):lower()
        end
    end
    
    self.trpNameText:SetText(displayName)
end

function LFRPSettingsSheet:ToggleLFRP()
    local LFRP = RPE and RPE.Core and RPE.Core.LFRP
    if not LFRP then
        RPE.Debug:Error("LFRP system not initialized.")
        return
    end

    -- Toggle state
    local newState = not (LFRP.IsInitialized or false)
    LFRP.IsInitialized = newState

    if newState then
        -- Enable: join channel, add player's own pin and start broadcasting
        local Comms = LFRP.Comms
        if Comms and Comms.InitializeChannelOnly then
            -- Join the LFRP channel
            Comms:InitializeChannelOnly()
        end

        local Location = RPE.Core.Location
        if Location then
            local loc = Location:GetPlayerLocation()
            if loc then
                -- Add our own pin to the map
                local PinManager = LFRP.PinManager
                if PinManager then
                    PinManager:AddPin(loc.mapID, loc.x, loc.y, "Interface\\Icons\\Inv_misc_ahnqirajtrinket_03", UnitName("player"), UnitName("player"))
                end
            end
        end

        -- Start periodic broadcasts with callback to get fresh settings each cycle
        if Comms and Comms.StartBroadcasting then
            -- Pass a callback function that will serialize fresh settings each broadcast
            Comms:StartBroadcasting(function()
                return self:SerializeSettings()
            end)
        end

        RPE.Debug:Print("LFRP enabled. Broadcasting location...")
    else
        -- Disable: stop broadcasting, remove own pin
        local Comms = LFRP.Comms
        if Comms and Comms.StopBroadcasting then
            Comms:StopBroadcasting()
        end

        local PinManager = LFRP.PinManager
        if PinManager then
            PinManager:RemovePinBySender(UnitName("player"))
        end

        RPE.Debug:Print("LFRP disabled.")
    end

    -- Save current LFRP settings to profile regardless of enable/disable state
    self:SaveLFRPSettingsToProfile()
    self:UpdateStatusDisplay()
end

function LFRPSettingsSheet:UpdateStatusDisplay()
    local LFRP = RPE and RPE.Core and RPE.Core.LFRP
    local isEnabled = LFRP and LFRP.IsInitialized or false

    if isEnabled then
        self.statusText:SetText("Broadcasting...")
        self.toggleBtn:SetText("Disable LFRP")
    else
        self.statusText:SetText("LFRP Disabled")
        self.toggleBtn:SetText("Enable LFRP")
    end
end

function LFRPSettingsSheet:ToggleAutoRejoin()
    local profile = RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    
    local newState = not profile:GetAutoRejoinLFRP()
    profile:SetAutoRejoinLFRP(newState)
    
    -- Save the profile
    local ProfileDB = RPE.Profile.DB
    if ProfileDB and ProfileDB.SaveProfile then
        ProfileDB.SaveProfile(profile)
    end
    
    -- Update button visual state
    self:UpdateAutoRejoinButton()
    
    -- Also save current LFRP settings to profile
    self:SaveLFRPSettingsToProfile()
end

function LFRPSettingsSheet:UpdateAutoRejoinButton()
    if not self.autoRejoinBtn then return end
    
    local profile = RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    
    local isEnabled = profile:GetAutoRejoinLFRP()
    
    -- Visual feedback: change button color based on state
    if isEnabled then
        self.autoRejoinBtn:SetColor(0.2, 1, 0.2, 1)  -- Green when enabled
    else
        self.autoRejoinBtn:SetColor(1, 1, 1, 1)  -- White when disabled
    end
end

function LFRPSettingsSheet:SaveLFRPSettingsToProfile()
    local profile = RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    
    -- Store LFRP preferences on the profile
    profile.lfrpSettings = profile.lfrpSettings or {}
    profile.lfrpSettings.iAmIds = self.iAmDropdown:GetValue() or {}
    profile.lfrpSettings.lookingForIds = self.lookingForDropdown:GetValue() or {}
    profile.lfrpSettings.broadcastLocation = self.broadcastLocationCheckbox and self.broadcastLocationCheckbox.check and self.broadcastLocationCheckbox.check:GetChecked() or false
    profile.lfrpSettings.recruiting = self.recruitingCheckbox and self.recruitingCheckbox.check and self.recruitingCheckbox.check:GetChecked() or false
    profile.lfrpSettings.approachable = self.approachableCheckbox and self.approachableCheckbox.check and self.approachableCheckbox.check:GetChecked() or false
    
    -- Save to database
    local ProfileDB = RPE.Profile.DB
    if ProfileDB and ProfileDB.SaveProfile then
        ProfileDB.SaveProfile(profile)
    end
end

function LFRPSettingsSheet:LoadLFRPSettingsFromProfile()
    local profile = RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
    if not profile or not profile.lfrpSettings then return end
    
    local settings = profile.lfrpSettings
    
    -- Load "I am" selections
    if settings.iAmIds and #settings.iAmIds > 0 then
        self.iAmDropdown:SetValue(settings.iAmIds)
        self:UpdateIAmLabel()
    end
    
    -- Load "Looking for" selections
    if settings.lookingForIds and #settings.lookingForIds > 0 then
        self.lookingForDropdown:SetValue(settings.lookingForIds)
        self:UpdateLookingForLabel()
    end
    
    -- Load broadcast location checkbox
    if self.broadcastLocationCheckbox and self.broadcastLocationCheckbox.check then
        self.broadcastLocationCheckbox.check:SetChecked(settings.broadcastLocation or false)
    end
    
    -- Load recruiting checkbox
    if self.recruitingCheckbox and self.recruitingCheckbox.check then
        self.recruitingCheckbox.check:SetChecked(settings.recruiting or false)
    end
    
    -- Load approachable checkbox
    if self.approachableCheckbox and self.approachableCheckbox.check then
        self.approachableCheckbox.check:SetChecked(settings.approachable or false)
    end
end

function LFRPSettingsSheet:Show()
    if self.sheet and self.sheet.Show then
        self.sheet:Show()
    end
    -- Update button color when showing in case settings changed
    self:UpdateAutoRejoinButton()
end

function LFRPSettingsSheet:Hide()
    if self.sheet and self.sheet.Hide then
        self.sheet:Hide()
    end
end

return LFRPSettingsSheet