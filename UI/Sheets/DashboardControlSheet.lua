-- RPE_UI/Sheets/DashboardControlSheet.lua
RPE             = RPE or {}
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local VGroup           = RPE_UI.Elements.VerticalLayoutGroup
local HGroup           = RPE_UI.Elements.HorizontalLayoutGroup
local Text             = RPE_UI.Elements.Text
local FrameElement     = RPE_UI.Elements.FrameElement
local TextButton       = RPE_UI.Elements.TextButton
local IconButton       = RPE_UI.Elements.IconButton
local HorizontalBorder = RPE_UI.Elements.HorizontalBorder
local C                = RPE_UI.Colors

---@class DashboardControlSheet
---@field sheet VGroup
---@field datasetButtons table<string, any>
---@field rulesetButtons table<string, any>
local DashboardControlSheet = {}
_G.RPE_UI.Windows.DashboardControlSheet = DashboardControlSheet
DashboardControlSheet.__index = DashboardControlSheet
DashboardControlSheet.Name = "DashboardControlSheet"

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.DashboardControlSheet = self
end

--- Get the currently active dataset for the character
function DashboardControlSheet:_getActiveDataset()
    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DatasetDB then return nil end
    return (DatasetDB.LoadActiveForCurrentCharacter and DatasetDB.LoadActiveForCurrentCharacter()) or nil
end

--- Toggle dataset active status (activate/deactivate)
function DashboardControlSheet:_toggleDatasetActive(datasetName)
    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DatasetDB then return end
    if not datasetName or datasetName == "" then return end
    
    if DatasetDB.ToggleActive then
        DatasetDB.ToggleActive(datasetName)
        
        -- Rebuild registries from all active datasets
        if RPE.Core then
            local function _refreshRegistry(reg, method)
                if reg and type(reg[method]) == "function" then
                    pcall(function() reg[method](reg) end)
                end
            end
            _refreshRegistry(RPE.Core.ItemRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.SpellRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.AuraRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.NPCRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.RecipeRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.InteractionRegistry, "RefreshFromActiveDatasets")
            _refreshRegistry(RPE.Core.StatRegistry, "RefreshFromActiveDatasets")
        end
        
        -- Update button styles after toggling
        self:_updateDatasetButtonStyles()
    end
end

--- Apply button styling based on active state
local function _applyDatasetButtonStyle(btn, isActive)
    if not btn or not btn.label then return end
    
    if isActive then
        -- Active: use textBonus (green)
        local r, g, b, a = C.Get("textBonus")
        btn.label:SetTextColor(r, g, b, a)
    else
        -- Inactive: use normal text color
        local nr, ng, nb, na = C.Get("text")
        btn.label:SetTextColor(nr, ng, nb, na)
    end
end

--- Check if setup wizard is available based on active ruleset and dataset
function DashboardControlSheet:_isSetupWizardAvailable()
    local RulesetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.RulesetDB
    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    
    if not RulesetDB or not DatasetDB then return false end
    
    -- Get the active ruleset
    local activeRulesetNames = (RulesetDB.GetActiveNamesForCurrentCharacter and RulesetDB.GetActiveNamesForCurrentCharacter()) or {}
    if #activeRulesetNames == 0 then return false end
    
    local activeRulesetName = activeRulesetNames[1]
    local activeRuleset = RulesetDB.GetByName and RulesetDB.GetByName(activeRulesetName)
    
    if not activeRuleset then return false end
    
    -- Check if ruleset has setup_wizard key
    if not activeRuleset.setup_wizard then return false end
    
    local setupWizardDataset = activeRuleset.setup_wizard
    
    -- Check if the dataset specified by setup_wizard key is active
    local activeDatasets = (DatasetDB.GetActiveNamesForCurrentCharacter and DatasetDB.GetActiveNamesForCurrentCharacter()) or {}
    for _, datasetName in ipairs(activeDatasets) do
        if datasetName == setupWizardDataset then
            return true
        end
    end
    
    return false
end

--- Update setup button enabled state based on setup wizard availability
function DashboardControlSheet:_updateSetupButtonState()
    if not self.setupBtn then return end
    
    local isAvailable = self:_isSetupWizardAvailable()
    
    -- Use the same styling function as other buttons
    if isAvailable then
        _applyDatasetButtonStyle(self.setupBtn, true)
    else
        _applyDatasetButtonStyle(self.setupBtn, false)
    end
end

--- Update all dataset button styles based on active dataset
function DashboardControlSheet:_updateDatasetButtonStyles()
    if not self.datasetButtons then return end
    
    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    local activeNames = (DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter and DatasetDB.GetActiveNamesForCurrentCharacter()) or {}
    local activeSet = {}
    for _, name in ipairs(activeNames) do
        activeSet[name] = true
    end
    
    for datasetName, btnData in pairs(self.datasetButtons) do
        local isActive = activeSet[datasetName] or false
        local btn = btnData.btn
        local iconElement = btnData.icon
        
        -- Update button color
        if btn then
            _applyDatasetButtonStyle(btn, isActive)
        end
        
        -- Update icon
        if iconElement then
            local icon = isActive and (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Check or "") or
                         (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Cancel or "")
            iconElement:SetText(icon)
        end
    end
    
    -- Update setup button state when datasets change
    self:_updateSetupButtonState()
end

--- Refresh ruleset button styles (updates check icons and button color)
function DashboardControlSheet:_refreshRulesetButtonStyles()
    if not self.rulesetButtons then return end
    
    local RulesetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.RulesetDB
    if not RulesetDB then return end
    
    local activeNames = (RulesetDB.GetActiveNamesForCurrentCharacter and RulesetDB.GetActiveNamesForCurrentCharacter()) or {}
    local activeSet = {}
    for _, name in ipairs(activeNames) do
        activeSet[name] = true
    end
    
    for rulesetName, btnData in pairs(self.rulesetButtons) do
        local isActive = activeSet[rulesetName] or false
        local btn = btnData.btn
        local iconElement = btnData.icon
        
        -- Update button color (green for active)
        if btn then
            _applyDatasetButtonStyle(btn, isActive)
        end
        
        -- Update icon
        if iconElement then
            local icon = isActive and (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Check or "") or ""
            iconElement:SetText(icon)
        end
    end
    
    -- Update setup button state when rulesets change
    self:_updateSetupButtonState()
end

function DashboardControlSheet:BuildUI(opts)
    opts = opts or {}
    self.datasetButtons = {}
    self.rulesetButtons = {}

    self.sheet = VGroup:New("RPE_DCS_Sheet", {
        parent = opts.parent,
        width  = 1,
        height = 1,
        point  = "TOP",
        relativePoint = "TOP",
        x = 0, y = 0,
        padding = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV = "TOP",
        alignH = "CENTER",
        autoSize = true,
    })

    -- Header
    local header = Text:New("RPE_DCS_Header", {
        parent       = self.sheet,
        text         = "Welcome to RPE v" .. (_G.RPE.AddonVersion or "unknown"),
        fontTemplate = "GameFontHighlightLarge",
        justifyH     = "CENTER",
    })
    C.ApplyText(header.fs, "text")
    self.sheet:Add(header)

    -- Initial instruction text
    local initialInstructionText = Text:New("RPE_DCS_InitialInstructionText", {
        parent       = self.sheet,
        text         = "Welcome to the RPE Dashboard! You can manage your active rulesets and datasets here. Access this window at any time using '/rpe'.\n\nYou must have one active ruleset and at least one active dataset. The DefaultClassic options contain built-in character stats, spells, items and more.",
        fontTemplate = "GameFontNormalSmall",
        justifyH     = "CENTER",
        width        = 500,
        height       = 30,
        wordWrap     = true,
    })
    C.ApplyText(initialInstructionText.fs, "textMuted")
    self.sheet:Add(initialInstructionText)

    -- Two-column container (rulesets left, datasets right)
    local columnContainer = HGroup:New("RPE_DCS_ColumnContainer", {
        parent = self.sheet,
        spacingX = 16,
        alignH = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(columnContainer)

    -- Left column: Rulesets
    local rulesetsColumn = VGroup:New("RPE_DCS_RulesetsColumn", {
        parent = columnContainer,
        width = 1,
        spacingY = 8,
        alignV = "TOP",
        autoSize = true,
    })
    columnContainer:Add(rulesetsColumn)

    -- Rulesets header
    local rulesetsHeader = Text:New("RPE_DCS_RulesetsHeader", {
        parent       = rulesetsColumn,
        text         = "Rulesets",
        fontTemplate = "GameFontHighlightSmall",
        justifyH     = "LEFT",
    })
    C.ApplyText(rulesetsHeader.fs, "textMuted")
    rulesetsColumn:Add(rulesetsHeader)

    -- Get rulesets from RulesetDB
    local RulesetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.RulesetDB
    if RulesetDB then
        local rulesetNames = (RulesetDB.ListNames and RulesetDB.ListNames()) or {}
        if #rulesetNames > 0 then
            -- Get list of active ruleset names
            local activeNames = (RulesetDB.GetActiveNamesForCurrentCharacter and RulesetDB.GetActiveNamesForCurrentCharacter()) or {}
            local activeSet = {}
            for _, name in ipairs(activeNames) do
                activeSet[name] = true
            end
            
            for _, rulesetName in ipairs(rulesetNames) do
                local isActive = activeSet[rulesetName] or false
                
                -- Create row with icon and button
                local rulesetRow = HGroup:New("RPE_DCS_RulesetRow_" .. rulesetName, {
                    parent = rulesetsColumn,
                    spacingX = 4,
                    alignV = "CENTER",
                    autoSize = true,
                })
                
                -- Icon (left side)
                local iconText = isActive and (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Check or "") or ""
                local iconElement = Text:New("RPE_DCS_RulesetIcon_" .. rulesetName, {
                    parent = rulesetRow,
                    text = iconText,
                    width = 16,
                    fontTemplate = "GameFontNormal",
                })
                rulesetRow:Add(iconElement)
                
                -- Button
                local rulesetBtn = TextButton:New("RPE_DCS_Ruleset_" .. rulesetName, {
                    parent  = rulesetRow,
                    width   = 120,
                    height  = 24,
                    text    = rulesetName,
                    noBorder = false,
                    onClick = function()
                        local rs = RulesetDB.GetByName(rulesetName)
                        if rs then
                            RulesetDB.SetActiveForCurrentCharacter(rulesetName)
                            if RPE.ActiveRules then
                                RPE.ActiveRules:SetRuleset(rs)
                            end
                            RPE.Debug:Print("Loaded ruleset: " .. rulesetName)
                            -- Refresh button styles to show/hide check icon
                            self:_refreshRulesetButtonStyles()
                        end
                    end,
                })
                rulesetRow:Add(rulesetBtn)
                
                self.rulesetButtons[rulesetName] = { btn = rulesetBtn, icon = iconElement }
                rulesetsColumn:Add(rulesetRow)
            end
        else
            local noRulesetsText = Text:New("RPE_DCS_NoRulesets", {
                parent       = rulesetsColumn,
                text         = "No rulesets available",
                fontTemplate = "GameFontDisable",
                justifyH     = "LEFT",
            })
            rulesetsColumn:Add(noRulesetsText)
        end
    end

    -- Right column: Datasets
    local datasetsColumn = VGroup:New("RPE_DCS_DatasetsColumn", {
        parent = columnContainer,
        width = 1,
        spacingY = 8,
        alignV = "TOP",
        autoSize = true,
    })
    columnContainer:Add(datasetsColumn)

    -- Datasets header
    local datasetsHeader = Text:New("RPE_DCS_DatasetsHeader", {
        parent       = datasetsColumn,
        text         = "Datasets",
        fontTemplate = "GameFontHighlightSmall",
        justifyH     = "LEFT",
    })
    C.ApplyText(datasetsHeader.fs, "textMuted")
    datasetsColumn:Add(datasetsHeader)

    -- Get datasets from DatasetDB
    local DatasetDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if DatasetDB then
        local datasetNames = (DatasetDB.ListNames and DatasetDB.ListNames()) or {}
        if #datasetNames > 0 then
            -- Get list of active dataset names
            local activeNames = (DatasetDB.GetActiveNamesForCurrentCharacter and DatasetDB.GetActiveNamesForCurrentCharacter()) or {}
            local activeSet = {}
            for _, name in ipairs(activeNames) do
                activeSet[name] = true
            end
            
            for _, datasetName in ipairs(datasetNames) do
                local isActive = activeSet[datasetName] or false
                
                -- Create row with button and icon
                local datasetRow = HGroup:New("RPE_DCS_DatasetRow_" .. datasetName, {
                    parent = datasetsColumn,
                    spacingX = 4,
                    alignV = "CENTER",
                    autoSize = true,
                })
                
                -- Button
                local datasetBtn = TextButton:New("RPE_DCS_Dataset_" .. datasetName, {
                    parent  = datasetRow,
                    width   = 120,
                    height  = 24,
                    text    = datasetName,
                    noBorder = false,
                    onClick = function()
                        self:_toggleDatasetActive(datasetName)
                    end,
                })
                datasetRow:Add(datasetBtn)
                
                -- Icon (right side)
                local iconText = isActive and (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Check or "") or
                                (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Cancel or "")
                local iconElement = Text:New("RPE_DCS_DatasetIcon_" .. datasetName, {
                    parent = datasetRow,
                    text = iconText,
                    width = 16,
                    fontTemplate = "GameFontNormal",
                })
                datasetRow:Add(iconElement)
                
                self.datasetButtons[datasetName] = { btn = datasetBtn, icon = iconElement }
                datasetsColumn:Add(datasetRow)
            end
        else
            local noDatasetsText = Text:New("RPE_DCS_NoDatasets", {
                parent       = datasetsColumn,
                text         = "No datasets available",
                fontTemplate = "GameFontDisable",
                justifyH     = "LEFT",
            })
            datasetsColumn:Add(noDatasetsText)
        end
    end

    -- Apply initial button styles
    self:_refreshRulesetButtonStyles()
    self:_updateDatasetButtonStyles()

    -- Instruction placeholder text
    local instructionText = Text:New("RPE_DCS_InstructionText", {
        parent       = self.sheet,
        text         = "Once you have selected your desired datasets and rulesets, you can proceed to set up your character by clicking the button below.\n\nYour event leader may have custom datasets which they want you to use. Please check with them if you're unsure.",
        fontTemplate = "GameFontNormalSmall",
        justifyH     = "CENTER",
        width        = 500,
        height       = 100,
        wordWrap     = true,
    })
    C.ApplyText(instructionText.fs, "textMuted")
    self.sheet:Add(instructionText)

    -- Button group container
    local buttonGroup = HGroup:New("RPE_DCS_ButtonGroup", {
        parent = self.sheet,
        spacingX = 12,
        alignH = "CENTER",
        alignV = "CENTER",
        autoSize = true,
    })
    self.sheet:Add(buttonGroup)

    -- Character Setup button
    self.setupBtn = TextButton:New("RPE_DCS_CharacterSetupBtn", {
        parent  = buttonGroup,
        width   = 120,
        height  = 28,
        text    = "Character Setup",
        noBorder = false,
        onClick = function()
            local Setup = RPE_UI.Common:GetWindow("SetupWindow")
            local isNewWindow = false
            if not Setup then
                -- Create it if it doesn't exist yet
                if RPE_UI.Windows and RPE_UI.Windows.SetupWindow then
                    Setup = RPE_UI.Windows.SetupWindow.New()
                    RPE_UI.Common:Show(Setup)
                    isNewWindow = true
                else
                    RPE.Debug:Error("Setup window not found.")
                    return
                end
            end
            -- Only toggle if it wasn't just created
            if not isNewWindow then
                RPE_UI.Common:Toggle(Setup)
            end
            
            -- Close the dashboard
            local Dashboard = RPE_UI.Common:GetWindow("DashboardWindow")
            if Dashboard then
                RPE_UI.Common:Hide(Dashboard)
            end
        end,
    })
    buttonGroup:Add(self.setupBtn)

    -- Change Skin button
    local changeSkinBtn = TextButton:New("RPE_DCS_ChangeSkinBtn", {
        parent  = buttonGroup,
        width   = 120,
        height  = 28,
        text    = "Change Skin",
        noBorder = false,
        onClick = function()
            local PaletteWindowClass = RPE_UI.Windows and RPE_UI.Windows.PaletteWindow
            if not PaletteWindowClass then
                RPE.Debug:Error("PaletteWindow class not found.")
                return
            end
            
            local paletteWin = RPE_UI.Common:GetWindow("PaletteWindow")
            if not paletteWin then
                paletteWin = PaletteWindowClass:New()
                RPE_UI.Common:RegisterWindow(paletteWin)
            end
            RPE_UI.Common:Show(paletteWin)
        end,
    })
    buttonGroup:Add(changeSkinBtn)

    -- Separator border
    local parentWidth = self.sheet.frame:GetWidth() or 500
    local optionsBorder = HorizontalBorder:New("RPE_DCS_OptionsBorder", {
        parent = self.sheet,
        width = parentWidth * 0.9,
        thickness = 1,
    })
    self.sheet:Add(optionsBorder)
      
    -- Additional Options header
    local optionsHeaderText = Text:New("RPE_DCS_OptionsHeaderText", {
        parent       = self.sheet,
        text         = "Additional Options",
        fontTemplate = "GameFontHighlightSmall",
        justifyH     = "CENTER",
    })
    C.ApplyText(optionsHeaderText.fs, "textMuted")
    self.sheet:Add(optionsHeaderText)
    
    -- Row of option toggle buttons
    local optionsGroup = HGroup:New("RPE_DCS_OptionsGroup", {
        parent = self.sheet,
        spacingX = 16,
        alignH = "CENTER",
        alignV = "CENTER",
        autoSize = true,
    })
    self.sheet:Add(optionsGroup)
    
    -- Update button colors based on current profile settings
    local function updateOptionButtonColors()
        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
        if not profile then return end
        
        -- Immersion mode: textBonus if enabled, textMalus if disabled
        if self.immersionBtn then
            if profile.immersionMode then
                local r, g, b, a = C.Get("textBonus")
                self.immersionBtn:SetColor(r, g, b, a)
            else
                local r, g, b, a = C.Get("textMalus")
                self.immersionBtn:SetColor(r, g, b, a)
            end
        end
        
        -- Chatbox: textBonus if enabled, textMalus if disabled
        if self.chatboxBtn then
            if profile.showChatbox then
                local r, g, b, a = C.Get("textBonus")
                self.chatboxBtn:SetColor(r, g, b, a)
            else
                local r, g, b, a = C.Get("textMalus")
                self.chatboxBtn:SetColor(r, g, b, a)
            end
        end
        
        -- Talking heads: textBonus if enabled, textMalus if disabled
        if self.talkingHeadsBtn then
            if profile.showTalkingHeads then
                local r, g, b, a = C.Get("textBonus")
                self.talkingHeadsBtn:SetColor(r, g, b, a)
            else
                local r, g, b, a = C.Get("textMalus")
                self.talkingHeadsBtn:SetColor(r, g, b, a)
            end
        end
    end
    self.updateOptionButtonColors = updateOptionButtonColors
    
    -- Immersion Mode button
    local immersionBtn = IconButton:New("RPE_DCS_ImmersionBtn", {
        parent = optionsGroup,
        width = 32,
        height = 32,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\immersion.png",
        tooltip = "Toggle Immersion Mode\nIn immersion mode, RPE UI will appear even when you have your Blizzard UI hidden.",
        hasBackground = false, noBackground = true,
        hasBorder = false, noBorder = true,
        onClick = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if profile then
                profile.immersionMode = not profile.immersionMode
                if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                    RPE.Profile.DB.SaveProfile(profile)
                end
                if RPE.Core then
                    RPE.Core.ImmersionMode = profile.immersionMode
                end
                updateOptionButtonColors()
            end
        end,
    })
    optionsGroup:Add(immersionBtn)
    self.immersionBtn = immersionBtn
    if immersionBtn.frame then immersionBtn.frame:Show() end
    
    -- Chatbox toggle button
    local chatboxBtn = IconButton:New("RPE_DCS_ChatboxBtn", {
        parent = optionsGroup,
        width = 32,
        height = 32,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\talk.png",
        tooltip = "Toggle Chatbox\nShow/hide the RPE chatbox. This is a chatbox that appears when you hide your Blizzard UI.",
        hasBackground = false, noBackground = true,
        hasBorder = false, noBorder = true,
        onClick = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if profile then
                profile.showChatbox = not profile.showChatbox
                if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                    RPE.Profile.DB.SaveProfile(profile)
                end
                local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.Chat
                if chatBox then
                    if profile.showChatbox then
                        chatBox:Show()
                    else
                        chatBox:Hide()
                    end
                end
                updateOptionButtonColors()
            end
        end,
    })
    optionsGroup:Add(chatboxBtn)
    self.chatboxBtn = chatboxBtn
    if chatboxBtn.frame then chatboxBtn.frame:Show() end
    
    -- Talking Heads toggle button
    local talkingHeadsBtn = IconButton:New("RPE_DCS_TalkingHeadsBtn", {
        parent = optionsGroup,
        width = 32,
        height = 32,
        icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\talking_head.png",
        tooltip = "Toggle Talking Heads\nShow/hide NPC speech bubbles. They will show in the chatbox even if this option is disabled.",
        hasBorder = false, noBorder = true,
        hasBackground = false, noBackground = true,
        onClick = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if profile then
                profile.showTalkingHeads = not profile.showTalkingHeads
                if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                    RPE.Profile.DB.SaveProfile(profile)
                end
                local speechBubbles = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.SpeechBubbles
                if speechBubbles then
                    if profile.showTalkingHeads then
                        speechBubbles:Show()
                    else
                        speechBubbles:Hide()
                    end
                end
                updateOptionButtonColors()
            end
        end,
    })
    optionsGroup:Add(talkingHeadsBtn)
    self.talkingHeadsBtn = talkingHeadsBtn
    if talkingHeadsBtn.frame then talkingHeadsBtn.frame:Show() end
    
    -- Initialize button colors
    updateOptionButtonColors()
    
    -- Apply initial setup button state
    self:_updateSetupButtonState()

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function DashboardControlSheet.New(opts)
    local self = setmetatable({}, DashboardControlSheet)
    self:BuildUI(opts or {})
    return self
end

return DashboardControlSheet
