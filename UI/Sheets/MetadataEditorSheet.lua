-- RPE_UI/Windows/MetadataEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Panel     = RPE_UI.Elements.Panel
local Text      = RPE_UI.Elements.Text
local Dropdown  = RPE_UI.Elements.Dropdown
local Input     = RPE_UI.Elements.Input
local C         = RPE_UI.Colors

---@class MetadataEditorSheet
---@field sheet Panel
---@field root Panel
---@field editingName string|nil
---@field labels table
---@field inputs table
---@field dropdowns table
local MetadataEditorSheet = {}
_G.RPE_UI.Windows.MetadataEditorSheet = MetadataEditorSheet
MetadataEditorSheet.__index = MetadataEditorSheet
MetadataEditorSheet.Name = "MetadataEditorSheet"

local LABEL_HEIGHT      = 20
local CHECKBOX_HEIGHT   = 20
local CONTENT_PAD_X     = 12
local CONTENT_PAD_Y     = 12
local ITEM_SPACING      = 16
local LABEL_WIDTH       = 100

-- ---------- helpers ---------------------------------------------------------
local function _dprint(...)
    if RPE.Debug and RPE.Debug.Internal then
        local args = {...}
        local strArgs = {}
        for i, v in ipairs(args) do
            strArgs[i] = tostring(v)
        end
        RPE.Debug:Internal(table.concat(strArgs, " "))
    end
end

local function _DB()
    return _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB or nil
end

local function _getDataset(name)
    local DB = _DB()
    if not DB then return nil end
    return DB.GetByName and DB.GetByName(name) or nil
end
-- ---------- end helpers -----------------------------------------------------

function MetadataEditorSheet:SetEditingDataset(name)
    self.editingName = name
    self:Refresh()
end

function MetadataEditorSheet:Refresh()
    local ds = _getDataset(self.editingName)
    _dprint("MetadataEditorSheet:Refresh() - dataset name:", self.editingName or "None", "found:", ds and "YES" or "NO")
    
    if not ds then
        _dprint("  No dataset loaded, skipping refresh")
        return
    end
    
    -- Set flag to prevent callbacks from saving during refresh
    self._isRefreshing = true
    
    -- Check if current player is the author
    local playerName = UnitName("player")
    local isAuthor = (ds.author == playerName)
    local isLocked = (ds.securityLevel == "Locked")
    local isReadOnly = isLocked and not isAuthor
    
    _dprint("  isAuthor:", isAuthor, "isLocked:", isLocked, "isReadOnly:", isReadOnly)
    
    -- Update author label
    if self.labels and self.labels.author then
        local authorText = "Author: " .. (ds.author or "Unknown")
        self.labels.author:SetText(authorText)
        _dprint("  author set to:", authorText)
    end
    
    -- Update read-only combined view or editable view
    if isReadOnly then
        -- Hide all editable controls
        if self.inputs.description and self.inputs.description.frame then
            self.inputs.description.frame:Hide()
        end
        if self.dropdowns.securityLevel and self.dropdowns.securityLevel.frame then
            self.dropdowns.securityLevel.frame:Hide()
        end
        if self.labels.descriptionLabel and self.labels.descriptionLabel.frame then
            self.labels.descriptionLabel.frame:Hide()
        end
        if self.labels.securityLabel and self.labels.securityLabel.frame then
            self.labels.securityLabel.frame:Hide()
        end
        
        -- Show read-only description and security level
        if self.labels.readOnlyDescription then
            local descText = ds.description or "(None)"
            self.labels.readOnlyDescription:SetText("Description: " .. descText)
            self.labels.readOnlyDescription.frame:Show()
            _dprint("  Showing read-only description:", descText)
        end
        if self.labels.readOnlySecurityLevel then
            local secText = ds.securityLevel or "Open"
            self.labels.readOnlySecurityLevel:SetText("Security Level: " .. secText)
            self.labels.readOnlySecurityLevel.frame:Show()
            _dprint("  Showing read-only security level:", secText)
        end
    else
        -- Hide read-only display
        if self.labels.readOnlyDescription and self.labels.readOnlyDescription.frame then
            self.labels.readOnlyDescription.frame:Hide()
        end
        if self.labels.readOnlySecurityLevel and self.labels.readOnlySecurityLevel.frame then
            self.labels.readOnlySecurityLevel.frame:Hide()
        end
        
        -- Show all editable controls
        if self.labels.descriptionLabel and self.labels.descriptionLabel.frame then
            self.labels.descriptionLabel.frame:Show()
        end
        if self.inputs.description and self.inputs.description.frame then
            self.inputs.description.frame:Show()
            local descValue = ds.description or ""
            _dprint("  setting description input to:", descValue, "(type:", type(descValue), ")")
            if self.inputs.description.SetText then
                self.inputs.description:SetText(descValue)
                _dprint("  description SetText called")
            end
        end
        if self.labels.securityLabel and self.labels.securityLabel.frame then
            self.labels.securityLabel.frame:Show()
        end
        if self.dropdowns.securityLevel and self.dropdowns.securityLevel.frame then
            self.dropdowns.securityLevel.frame:Show()
            local securityLevel = ds.securityLevel or "Open"
            _dprint("  setting security level to:", securityLevel)
            if self.dropdowns.securityLevel.SetValue then
                self.dropdowns.securityLevel:SetValue(securityLevel)
            end
        end
    end
    
    -- Clear refresh flag
    self._isRefreshing = false
    
    _dprint("MetadataEditorSheet:Refresh() completed")
end

function MetadataEditorSheet:BuildUI()
    -- Root sheet panel
    self.sheet = Panel:New("RPE_MetadataEditorSheet_Root", {
        parent   = self.root,
        autoSize = false,
    })
    self.sheet.frame:ClearAllPoints()
    self.sheet.frame:SetPoint("TOPLEFT",  self.root.frame, "TOPLEFT", 0, 0)
    self.sheet.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    self.sheet.frame:SetPoint("BOTTOMLEFT",  self.root.frame, "BOTTOMLEFT", 0, 0)
    self.sheet.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    
    self.labels = {}
    self.inputs = {}
    self.dropdowns = {}
    
    local currentY = -CONTENT_PAD_Y
    
    -- Author label
    self.labels.author = Text:New("RPE_Metadata_AuthorLabel", {
        parent = self.sheet,
        text   = "Author: Unknown",
    })
    self.labels.author.frame:ClearAllPoints()
    self.labels.author.frame:SetPoint("TOPLEFT", self.sheet.frame, "TOPLEFT", CONTENT_PAD_X, currentY)
    self.labels.author.frame:SetHeight(LABEL_HEIGHT)
    currentY = currentY - LABEL_HEIGHT - ITEM_SPACING
    
    -- Description label
    self.labels.descriptionLabel = Text:New("RPE_Metadata_DescriptionLabel", {
        parent = self.sheet,
        text   = "Description:",
    })
    self.labels.descriptionLabel.frame:ClearAllPoints()
    self.labels.descriptionLabel.frame:SetPoint("TOPLEFT", self.sheet.frame, "TOPLEFT", CONTENT_PAD_X, currentY)
    self.labels.descriptionLabel.frame:SetHeight(LABEL_HEIGHT)
    currentY = currentY - LABEL_HEIGHT - 4
    
    -- Description input field
    self.inputs.description = Input:New("RPE_Metadata_DescriptionInput", {
        parent = self.sheet,
        width = 200,
        height = 24,
        placeholder = "Enter description...",
        onTextChanged = function(text)
            -- Skip saving during Refresh() to avoid overwriting the loaded value
            if self._isRefreshing then 
                _dprint("  description onTextChanged skipped (refreshing)")
                return 
            end
            
            _dprint("  description onTextChanged fired with text:", text)
            local ds = _getDataset(self.editingName)
            if not ds then
                _dprint("    ERROR: Dataset not found!")
                return
            end
            -- Only save if text actually changed
            if ds.description ~= text then
                _dprint("    Saving description:", text)
                ds.description = text
                local DB = _DB()
                if DB and DB.Save then
                    DB.Save(ds)
                    _dprint("    DB.Save completed")
                end
            else
                _dprint("    Description unchanged, skipping save")
            end
        end,
    })
    self.inputs.description.frame:ClearAllPoints()
    self.inputs.description.frame:SetPoint("TOPLEFT", self.sheet.frame, "TOPLEFT", CONTENT_PAD_X, currentY)
    self.inputs.description.frame:SetWidth(300)
    currentY = currentY - 24 - (ITEM_SPACING * 2)
    
    -- Security Level label
    self.labels.securityLabel = Text:New("RPE_Metadata_SecurityLabel", {
        parent = self.sheet,
        text   = "Security Level:",
    })
    self.labels.securityLabel.frame:ClearAllPoints()
    self.labels.securityLabel.frame:SetPoint("TOPLEFT", self.sheet.frame, "TOPLEFT", CONTENT_PAD_X, currentY)
    self.labels.securityLabel.frame:SetHeight(LABEL_HEIGHT)
    
    -- Security Level dropdown
    self.dropdowns.securityLevel = Dropdown:New("RPE_Metadata_SecurityDropdown", {
        parent = self.sheet,
        width = 150,
        height = 24,
        value = "Open",
        choices = { "Open", "Viewable", "Locked" },
        onChanged = function(dropdownSelf, value)
            -- Skip saving during Refresh() to avoid overwriting the loaded value
            if self._isRefreshing then return end
            
            _dprint("SecurityLevel dropdown changed to:", value, "for dataset:", self.editingName)
            local ds = _getDataset(self.editingName)
            if not ds then
                _dprint("  ERROR: Dataset not found!")
                return
            end
            _dprint("  Dataset found, setting securityLevel to:", value)
            ds.securityLevel = value
            _dprint("  ds.securityLevel is now:", ds.securityLevel)
            local DB = _DB()
            if DB and DB.Save then
                _dprint("  Calling DB.Save...")
                DB.Save(ds)
                _dprint("  DB.Save completed")
            else
                _dprint("  ERROR: DB or DB.Save not available!")
            end
        end,
    })
    self.dropdowns.securityLevel.frame:ClearAllPoints()
    self.dropdowns.securityLevel.frame:SetPoint("TOPLEFT", self.labels.securityLabel.frame, "TOPRIGHT", 8, 0)
    currentY = currentY - 24 - ITEM_SPACING
    currentY = currentY - 24 - ITEM_SPACING
    
    -- Read-only description display (shown when locked for non-author)
    self.labels.readOnlyDescription = Text:New("RPE_Metadata_ReadOnlyDescription", {
        parent = self.sheet,
        text   = "Description: (None)",
    })
    self.labels.readOnlyDescription.frame:ClearAllPoints()
    self.labels.readOnlyDescription.frame:SetPoint("TOPLEFT", self.sheet.frame, "TOPLEFT", CONTENT_PAD_X, -CONTENT_PAD_Y - LABEL_HEIGHT - 10)
    self.labels.readOnlyDescription.frame:SetHeight(24)
    self.labels.readOnlyDescription.frame:Hide()
    
    -- Read-only security level display (shown when locked for non-author)
    self.labels.readOnlySecurityLevel = Text:New("RPE_Metadata_ReadOnlySecurityLevel", {
        parent = self.sheet,
        text   = "Security Level: Open",
    })
    self.labels.readOnlySecurityLevel.frame:ClearAllPoints()
    self.labels.readOnlySecurityLevel.frame:SetPoint("TOPLEFT", self.sheet.frame, "TOPLEFT", CONTENT_PAD_X, -CONTENT_PAD_Y - LABEL_HEIGHT - 40)
    self.labels.readOnlySecurityLevel.frame:SetHeight(24)
    self.labels.readOnlySecurityLevel.frame:Hide()
    
    -- Calculate minimum height needed for all content
    local minHeight = math.abs(currentY) + CONTENT_PAD_Y
    self.sheet.frame:SetHeight(math.max(minHeight, 200))
end

function MetadataEditorSheet:ApplyPalette()
    -- Text and Checkbox elements will auto-update via their own ApplyPalette
    -- Panel elements will auto-update via their own ApplyPalette
end

function MetadataEditorSheet.New(args)
    args = args or {}
    local self = setmetatable({}, MetadataEditorSheet)
    
    self.root = args.parent or UIParent
    self.editingName = args.editingName or nil
    
    self:BuildUI()
    if self.editingName then
        self:Refresh()
    end
    
    -- Register as palette consumer
    if C and C.RegisterConsumer then
        C.RegisterConsumer(self)
    end
    
    return self
end

return MetadataEditorSheet
