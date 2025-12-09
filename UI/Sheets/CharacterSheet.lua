-- RPE_UI/Windows/CharacterSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local FrameElement = RPE_UI.Elements.FrameElement

-- Prefabs
local CharacterPortrait = RPE_UI.Prefabs.CharacterPortrait
local StatEntry         = RPE_UI.Prefabs.StatEntry
local TraitEntry        = RPE_UI.Prefabs.TraitEntry
local LanguageEntry     = RPE_UI.Prefabs.LanguageEntry

---@class CharacterSheet
---@field Name string
---@field root Window
---@field topGroup HGroup
---@field profile table
---@field entries table<string, any>
local CharacterSheet = {}
_G.RPE_UI.Windows.CharacterSheet = CharacterSheet
CharacterSheet.__index = CharacterSheet
CharacterSheet.Name = "CharacterSheet"

function CharacterSheet:BuildUI(opts)
    -- Defer profile access until needed - it may not be initialized yet
    self.profile = nil
    self.entries = {}

    self.sheet = VGroup:New("RPE_CS_Sheet", {
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

    -- Top content (portrait + name/guild + resources)
    -- self:TopGroup()
    -- self.sheet:Add(self.topGroup)

    -- Body content (primary/melee/ranged/spell/resistances)
    self:BodyGroup()
    self.sheet:Add(self.bodyGroup)

    -- Register / expose
    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE.Debug:Internal("Registering CharacterSheet window...")
        RPE_UI.Common:RegisterWindow(self)
    end

    -- Get or create profile on first access
    if not self.profile and RPE.Profile and RPE.Profile.DB then
        self.profile = RPE.Profile.DB.GetOrCreateActive()
        self.profile:_InitializeLanguages()
    end
end

function CharacterSheet:TopGroup()
    self.topGroup = HGroup:New("RPE_CS_TopGroup", {
        parent  = self.sheet,
        width   = 600,
        height  = 88,
        x       = 12, y = -12,
        spacingX = 12,
        alignV  = "CENTER",
        alignH  = "LEFT",
        autoSize = false,
    })
end

function CharacterSheet:BodyGroup()
    self.bodyGroup = VGroup:New("RPE_CS_BodyGroup", {
        parent  = self.sheet,
        width   = 600,
        height  = 88,
        padding = { left = 0, right = 0, top = 8, bottom = 0 },
        alignV  = "CENTER",
        alignH  = "CENTER",
        autoSize = true,
    })

    local function section(title, key, columns)
        local titleText = Text:New("RPE_CS_Title_" .. key, {
            parent = self.bodyGroup,
            text   = title,
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(titleText.fs, "textMuted")

        local row = HGroup:New("RPE_CS_Row_" .. key, {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        self.bodyGroup:Add(row)
        -- Don't call DrawStats here - defer until profile is available
        -- This will be called by Refresh() after PLAYER_LOGIN
    end

    section("Skills",            "SKILL",        3)
end

function CharacterSheet:DrawStats(statBlock, filter, columns)
    -- Get or create profile on first access
    if not self.profile then
        if not RPE then return end
        if not RPE.Profile then return end
        if not RPE.Profile.DB then return end
        
        self.profile = RPE.Profile.DB.GetOrCreateActive()
    end
    
    if not self.profile then
        return 
    end

    -- Clear old children
    for _, child in ipairs(statBlock.children or {}) do child:Destroy() end
    statBlock.children = {}

    -- Collect visible stats
    local stats = {}
    for _, stat in pairs(self.profile.stats or {}) do
        if stat.category == filter
        and _G.RPE.ActiveRules:IsStatEnabled(stat.id, stat.category)
        and (stat.visible == nil or stat.visible == 1 or stat.visible == true) then
            table.insert(stats, stat)
        end
    end
    
    table.sort(stats, function(a,b) return a.id < b.id end)

    local function makeEntry(parent, stat)
        local val =
            (RPE and RPE.Stats and RPE.Stats.GetValue and RPE.Stats:GetValue(stat.id))
            or (self.profile and self.profile.GetStatValue and self.profile:GetStatValue(stat.id))
            or 0

        local text = (stat.IsPercentage and stat:IsPercentage())
            and string.format("%.1f%%", val)
            or tostring(val)

        local icon = (stat.icon and stat.icon ~= "") and stat.icon
                  or "Interface\\Icons\\INV_Misc_QuestionMark"

        local colCount = (type(columns) == "number" and columns > 0) and columns or 2
        local width    = math.max(120, math.floor((210 * 2) / colCount))

        local entry = StatEntry:New("RPE_CS_" .. stat.id, {
            parent   = parent,
            width    = width,
            height   = 24,
            icon     = icon,
            label    = stat.name or stat.id,
            modifier = text,
            stat     = stat,
        })

        -- Track for targeted refresh
        self.entries[stat.id] = entry
        return entry
    end

    local count = #stats
    if count == 0 then return end
    columns = tonumber(columns) or ((count == 1) and 1 or 2)
    columns = math.max(1, math.min(columns, count))

    if columns == 1 then
        for i = 1, count do
            statBlock:Add(makeEntry(statBlock, stats[i]))
        end
        return
    end

    local container = HGroup:New("RPE_CS_" .. filter .. "_Cols", {
        parent  = statBlock,
        spacingX = 24,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    statBlock:Add(container)

    local cols = {}
    for c = 1, columns do
        local col = VGroup:New(("RPE_CS_%s_Col%d"):format(filter, c), {
            parent  = container,
            spacingY = 6,
            alignH   = "LEFT",
            autoSize = true,
        })
        container:Add(col)
        cols[c] = col
    end

    local rows = math.ceil(count / columns)
    local idx  = 1
    for r = 1, rows do
        for c = 1, columns do
            if idx > count then break end
            cols[c]:Add(makeEntry(cols[c], stats[idx]))
            idx = idx + 1
        end
    end
end

function CharacterSheet:DrawTraits(traitBlock)
    if not self.profile then return end
    
    local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
    if not AuraRegistry then return end
    
    -- Clear old children
    for _, child in ipairs(traitBlock.children or {}) do child:Destroy() end
    traitBlock.children = {}
    
    -- Draw existing traits
    for _, auraId in ipairs(self.profile:GetTraits() or {}) do
        local auraDef = AuraRegistry:Get(auraId)
        if auraDef then
            local entry = TraitEntry:New("RPE_CS_Trait_" .. auraId, {
                parent = traitBlock,
                width = 180,
                height = 24,
                icon = auraDef.icon or 134400,
                label = auraDef.name or auraId,
                auraId = auraId,
                onClick = function()
                    self.profile:RemoveTrait(auraId)
                    self:DrawTraits(traitBlock)
                end,
            })
            traitBlock:Add(entry)
        end
    end
    
    -- Check max_traits limit
    local maxTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits) or 0
    local currentTraitCount = #(self.profile:GetTraits() or {})
    local atMaxTraits = maxTraits > 0 and currentTraitCount >= maxTraits
    
    -- Only show "Add Trait" button if not at max traits
    if not atMaxTraits then
        local addTraitEntry = TraitEntry:New("RPE_CS_AddTrait", {
            parent = traitBlock,
            width = 180,
            height = 24,
            icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\health.png",
            label = "Add Trait",
            onClick = function()
                self:ShowTraitDropdown(traitBlock)
            end,
        })
        traitBlock:Add(addTraitEntry)
    end
    
    -- Force the container and parent to recalculate sizes
    if traitBlock.CalculateLayout then
        traitBlock:CalculateLayout()
    end
end

function CharacterSheet:DrawLanguages(langBlock)
    local Language = RPE.Core and RPE.Core.Language
    if not Language then 
        RPE.Debug:Error("Language system not found; cannot draw languages in Character Sheet.")
        return end
    
    -- Clear old children
    for _, child in ipairs(langBlock.children or {}) do child:Destroy() end
    langBlock.children = {}
    
    -- Get the player's language system
    local playerLanguageSystem = Language.playerLanguages or {}

    -- Determine default language based on faction
    local playerFaction = UnitFactionGroup("player")
    local defaultLanguage = (playerFaction == "Alliance") and "Common" or "Orcish"

    -- Convert to sorted list
    local languages = {}
    for langName, skillLevel in pairs(playerLanguageSystem) do
        table.insert(languages, { name = langName, skill = skillLevel })
    end
    table.sort(languages, function(a, b) return a.name < b.name end)
    
    -- Draw each language
    for _, langData in ipairs(languages) do
        local isDefault = (langData.name == defaultLanguage)
        local entry = LanguageEntry:New("RPE_CS_Lang_" .. langData.name, {
            parent = langBlock,
            width = 220,
            height = 24,
            icon = "Interface\\Icons\\INV_Misc_BookOfLore",
            languageName = langData.name,
            skillLevel = langData.skill,
            isDefaultLanguage = isDefault,
            onRemove = not isDefault and function()
                Language.playerLanguages[langData.name] = nil
                -- Also remove from profile
                if self.profile and self.profile.languages then
                    self.profile.languages[langData.name] = nil
                    local ProfileDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DB
                    if ProfileDB then
                        ProfileDB.SaveProfile(self.profile)
                    end
                end
                self:DrawLanguages(langBlock)
            end or nil,
        })
        langBlock:Add(entry)
    end
    
    -- Add "Learn Language" button
    local learnLangEntry = LanguageEntry:New("RPE_CS_LearnLanguage", {
        parent = langBlock,
        width = 220,
        height = 24,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\health.png",
        languageName = "Learn Language",
        skillLevel = 0,
        isButton = true,
        onClick = function()
            self:ShowLanguageDialog()
        end,
    })
    langBlock:Add(learnLangEntry)
    
    -- Force the container and parent to recalculate sizes
    if langBlock.CalculateLayout then
        langBlock:CalculateLayout()
    end
end

function CharacterSheet:ShowLanguageDialog()
    local Language = RPE.Core and RPE.Core.Language
    local LanguageTable = RPE.Core and RPE.Core.LanguageTable
    if not Language or not LanguageTable then return end
    
    local Popup = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    local HGroup = RPE_UI.Elements and RPE_UI.Elements.HorizontalLayoutGroup
    local Text = RPE_UI.Elements and RPE_UI.Elements.Text
    local Dropdown = RPE_UI.Elements and RPE_UI.Elements.Dropdown
    
    if not (Popup and HGroup and Text and Dropdown) then
        return
    end
    
    -- Get all available languages
    local availableLanguages = LanguageTable.GetLanguages() or {}
    local languageNames = availableLanguages
    
    -- Proficiency levels: 0%, 25%, 50%, 75%, 100%
    local proficiencyLevels = {
        "0% (No Knowledge)",
        "25% (Beginner)",
        "50% (Intermediate)",
        "75% (Advanced)",
        "100% (Fluent)",
    }
    
    local proficiencyValues = {
        0, 75, 150, 225, 300
    }
    
    -- Create popup dialog using Popup prefab
    local isImmersion = RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = isImmersion and WorldFrame or UIParent
    
    local p = Popup.New({
        title = "Learn Language",
        text = "Select a language and your proficiency level:",
        width = 400,
        parentFrame = parentFrame,
        clickOffToClose = true,
    })
    
    -- Create language selector row and add it to the mid (content) layout
    local langRow = HGroup:New("RPE_LearnLang_LangRow", {
        parent = p.mid,
        autoSize = true,
        spacingX = 10,
        alignV = "CENTER",
    })
    
    local langLabel = Text:New("RPE_LearnLang_LangLabel", {
        parent = langRow,
        text = "Language:",
        width = 80,
    })
    langRow:Add(langLabel)
    
    local langDropdown = Dropdown:New("RPE_LearnLang_LangDropdown", {
        parent = langRow,
        width = 280,
        choices = languageNames,
        value = languageNames[1],
    })
    langRow:Add(langDropdown)
    
    -- Add language row to the mid layout
    local FrameElement = RPE_UI.Elements and RPE_UI.Elements.FrameElement
    if FrameElement then
        p.mid:Add(langRow)
    end
    
    -- Create proficiency selector row and add it to the mid layout
    local profRow = HGroup:New("RPE_LearnLang_ProfRow", {
        parent = p.mid,
        autoSize = true,
        spacingX = 10,
        alignV = "CENTER",
    })
    
    local profLabel = Text:New("RPE_LearnLang_ProfLabel", {
        parent = profRow,
        text = "Proficiency:",
        width = 80,
    })
    profRow:Add(profLabel)
    
    local profDropdown = Dropdown:New("RPE_LearnLang_ProfDropdown", {
        parent = profRow,
        width = 280,
        choices = proficiencyLevels,
        value = proficiencyLevels[1],
    })
    profRow:Add(profDropdown)
    
    -- Add proficiency row to the mid layout
    if FrameElement then
        p.mid:Add(profRow)
    end
    
    -- Recalculate mid layout and resize popup
    if p.mid and p.mid.CalculateLayout then
        p.mid:CalculateLayout()
    end
    
    -- Re-size popup after adding rows
    C_Timer.After(0, function()
        if p and p._autoResize then
            pcall(p._autoResize, p)
        end
    end)
    
    -- Set up callbacks
    p:SetCallbacks(
        function()
            local selectedLang = langDropdown:GetValue()
            local selectedProfText = profDropdown:GetValue()
            
            -- Find the proficiency value corresponding to the selected text
            local selectedProfValue = 0
            for i, profText in ipairs(proficiencyLevels) do
                if profText == selectedProfText then
                    selectedProfValue = proficiencyValues[i]
                    break
                end
            end
            
            if selectedLang and self.profile then
                Language:SetLanguageSkill(selectedLang, selectedProfValue)
                
                -- Update the character sheet
                local mainWindow = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.MainWindow
                if mainWindow and mainWindow.Refresh then
                    mainWindow:Refresh()
                end
                
                -- Trigger resize of main window to accommodate language list changes
                C_Timer.After(0, function()
                    if mainWindow and mainWindow.content and mainWindow.content.SetSize and self.sheet and self.sheet.frame then
                        local w = self.sheet.frame:GetWidth() + 12
                        local h = self.sheet.frame:GetHeight() + 12
                        if w and h then
                            local padX = mainWindow.content.autoSizePadX or 0
                            local padY = mainWindow.content.autoSizePadY or 0
                            local minW = mainWindow.footer and mainWindow.footer.frame and mainWindow.footer.frame:GetWidth() or 0
                            
                            local cw = math.max(w + padX, minW)
                            local ch = h + padY
                            
                            mainWindow.content:SetSize(cw, ch)
                            mainWindow.root:SetSize(cw, ch + (mainWindow.footer and mainWindow.footer.frame and mainWindow.footer.frame:GetHeight() or 0))
                        end
                    end
                end)
            end
        end,
        function() end  -- Cancel callback (just close)
    )
    
    p:SetButtons("Learn", "Cancel")
    p:Show()
end

function CharacterSheet:DrawExperienceBar(expRow)
    if not self.profile then return end
    
    local ActiveRules = RPE.ActiveRules
    if not ActiveRules or not ActiveRules.rules then return end
    
    -- Get the exp_per_level formula
    local expPerLevel = ActiveRules.rules.exp_per_level
    if not expPerLevel then return end
    
    -- Get current ruleset ID for keying experience
    local rulesetId = ActiveRules.rules.id or "default"
    
    -- Get total experience from profile (keyed by ruleset)
    local experienceData = self.profile.experience or {}
    local totalExp = experienceData[rulesetId] or 0
    
    -- Helper function to calculate experience required for a level (1-indexed)
    local function expForLevel(level)
        if level <= 1 then return 0 end
        
        -- expPerLevel can be a number or a formula string with $level$ placeholder
        local Formula = RPE.Core and RPE.Core.Formula
        if not Formula then return 1000 end
        
        -- If it's already a number, scale by level
        if type(expPerLevel) == "number" then
            return expPerLevel * (level - 1)
        end
        
        -- If it's a string formula, substitute level and roll
        if type(expPerLevel) == "string" then
            local expr = expPerLevel:gsub("%$level%$", tostring(level - 1))
            local result = Formula:Roll(expr, self.profile)
            return tonumber(result) or 1000
        end
        
        return 1000
    end
    
    -- Calculate current level from total experience
    local currentLevel = 1
    local expForCurrentLevel = 0
    local expForNextLevel = expForLevel(2)
    
    for level = 1, 1000 do
        local requiredExp = expForLevel(level)
        if totalExp < requiredExp then
            currentLevel = level - 1
            expForCurrentLevel = level > 1 and expForLevel(level - 1) or 0
            expForNextLevel = requiredExp
            break
        end
    end
    
    -- Calculate progress to next level
    local expInCurrentLevel = totalExp - expForCurrentLevel
    local expNeededForLevel = expForNextLevel - expForCurrentLevel
    local expProgress = math.max(0, math.min(1, expInCurrentLevel / expNeededForLevel))
    
    -- Clear old children
    for _, child in ipairs(expRow.children or {}) do child:Destroy() end
    expRow.children = {}
    
    -- Container for level info and progress bar
    local expContainer = VGroup:New("RPE_CS_ExpContainer", {
        parent = expRow,
        autoSize = false,
        width = 300,
        height = 40,
        spacingY = 4,
        alignH = "LEFT",
        alignV = "TOP",
    })
    expRow:Add(expContainer)
    
    -- Level display row
    local levelRow = HGroup:New("RPE_CS_LevelRow", {
        parent = expContainer,
        autoSize = false,
        width = 300,
        height = 12,
        spacingX = 12,
        alignH = "LEFT",
        alignV = "CENTER",
    })
    expContainer:Add(levelRow)
    
    local levelLabel = Text:New("RPE_CS_LevelLabel", {
        parent = levelRow,
        text = "Level:",
        width = 50,
        height = 12,
        fontTemplate = "GameFontNormalSmall",
    })
    levelLabel.fs:ClearAllPoints()
    levelLabel.fs:SetPoint("LEFT", levelLabel.frame, "LEFT", 0, 0)
    levelLabel.fs:SetJustifyH("LEFT")
    levelRow:Add(levelLabel)
    
    local levelValue = Text:New("RPE_CS_LevelValue", {
        parent = levelRow,
        text = tostring(currentLevel),
        width = 40,
        height = 12,
        fontTemplate = "GameFontNormalSmall",
    })
    levelValue.fs:ClearAllPoints()
    levelValue.fs:SetPoint("LEFT", levelValue.frame, "LEFT", 0, 0)
    levelValue.fs:SetJustifyH("LEFT")
    levelRow:Add(levelValue)
    
    local expLabel = Text:New("RPE_CS_ExpLabel", {
        parent = levelRow,
        text = "Exp:",
        width = 40,
        height = 12,
        fontTemplate = "GameFontNormalSmall",
    })
    expLabel.fs:ClearAllPoints()
    expLabel.fs:SetPoint("LEFT", expLabel.frame, "LEFT", 0, 0)
    expLabel.fs:SetJustifyH("LEFT")
    levelRow:Add(expLabel)
    
    local expValue = Text:New("RPE_CS_ExpValue", {
        parent = levelRow,
        text = string.format("%d / %d", expInCurrentLevel, expNeededForLevel),
        width = 120,
        height = 12,
        fontTemplate = "GameFontNormalSmall",
    })
    expValue.fs:ClearAllPoints()
    expValue.fs:SetPoint("LEFT", expValue.frame, "LEFT", 0, 0)
    expValue.fs:SetJustifyH("LEFT")
    levelRow:Add(expValue)
    
    -- Progress bar with tooltip
    local progBarFrame = CreateFrame("Frame", "RPE_CS_ExpBar", expContainer.frame)
    progBarFrame:SetSize(300, 12)
    progBarFrame:EnableMouse(true)
    
    local bgTex = progBarFrame:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    local barTex = progBarFrame:CreateTexture(nil, "ARTWORK")
    barTex:SetPoint("LEFT", progBarFrame, "LEFT", 0, 0)
    barTex:SetSize(300 * expProgress, 12)
    
    local r, g, b, a = RPE_UI.Colors and RPE_UI.Colors.Get("progress_xp") or 0.45, 0.30, 0.65, 0.9
    if r then
        barTex:SetColorTexture(r, g, b, a)
    else
        barTex:SetColorTexture(0.45, 0.30, 0.65, 0.9)
    end
    
    -- Add tooltip on hover showing next 10 levels
    progBarFrame:SetScript("OnEnter", function(self)
        if RPE and RPE.Common and RPE.Common.ShowTooltip then
            local tooltipLines = {}
            for i = 1, 10 do
                local level = currentLevel + i
                local requiredExp = expForLevel(level)
                table.insert(tooltipLines, {
                    text = string.format("Level %d: %d exp", level, requiredExp)
                })
            end
            RPE.Common:ShowTooltip(self, {
                title = "Experience Progression",
                titleColor = { 1, 1, 1 },
                lines = tooltipLines,
            })
        end
    end)
    
    progBarFrame:SetScript("OnLeave", function()
        if RPE and RPE.Common and RPE.Common.HideTooltip then
            RPE.Common:HideTooltip()
        end
    end)
    
    local barElement = FrameElement.New(FrameElement, "ExpBar", progBarFrame, expContainer)
    expContainer:Add(barElement)
end

function CharacterSheet:ShowTraitDropdown(traitBlock)
    if not self.profile then return end
    
    local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
    if not AuraRegistry then return end
    
    local traitAuras = {}
    for id, auraDef in pairs(AuraRegistry.defs or {}) do
        if auraDef and auraDef.isTrait then
            table.insert(traitAuras, { id = id, def = auraDef })
        end
    end
    
    if #traitAuras == 0 then return end
    
    table.sort(traitAuras, function(a, b)
        return (a.def.name or a.id) < (b.def.name or b.id)
    end)
    
    -- Count current traits by type
    local racialCount = 0
    local classCount = 0
    local genericCount = 0
    local totalTraits = 0
    
    for _, traitId in ipairs(self.profile:GetTraits() or {}) do
        totalTraits = totalTraits + 1
        local def = AuraRegistry:Get(traitId)
        if def and def.tags then
            local isRacial = false
            local isClass = false
            for _, tag in ipairs(def.tags) do
                if type(tag) == "string" then
                    local tagLower = tag:lower()
                    if tagLower:sub(1, 5) == "race:" then
                        isRacial = true
                        break
                    elseif tagLower:sub(1, 6) == "class:" then
                        isClass = true
                        break
                    end
                end
            end
            if isRacial then
                racialCount = racialCount + 1
            elseif isClass then
                classCount = classCount + 1
            else
                genericCount = genericCount + 1
            end
        else
            genericCount = genericCount + 1
        end
    end
    
    RPE_UI.Common:ContextMenu(self, function(level, _)
        if level == 1 then
            -- Check overall max_traits limit
            local maxTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits) or 0
            local atMaxTotal = maxTraits > 0 and totalTraits >= maxTraits
            
            for _, trait in ipairs(traitAuras) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = trait.def.name or trait.id
                info.icon = trait.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                
                -- Check if this trait should be disabled
                local isRacial = false
                local isClass = false
                if trait.def.tags then
                    for _, tag in ipairs(trait.def.tags) do
                        if type(tag) == "string" then
                            local tagLower = tag:lower()
                            if tagLower:sub(1, 5) == "race:" then
                                isRacial = true
                                break
                            elseif tagLower:sub(1, 6) == "class:" then
                                isClass = true
                                break
                            end
                        end
                    end
                end
                
                local disabled = false
                
                -- First check overall max_traits limit
                if atMaxTotal and not self.profile:HasTrait(trait.id) then
                    disabled = true
                else
                    -- Then check type-specific limits
                    if isRacial then
                        local maxRacialTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits_racial) or 0
                        disabled = maxRacialTraits > 0 and racialCount >= maxRacialTraits and not self.profile:HasTrait(trait.id)
                    elseif isClass then
                        local maxClassTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits_class) or 0
                        disabled = maxClassTraits > 0 and classCount >= maxClassTraits and not self.profile:HasTrait(trait.id)
                    else
                        local maxGenericTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_generic_traits) or 0
                        disabled = maxGenericTraits > 0 and genericCount >= maxGenericTraits and not self.profile:HasTrait(trait.id)
                    end
                end
                
                info.disabled = disabled
                info.func = function()
                    if not disabled then
                        self.profile:AddTrait(trait.id)
                        self:DrawTraits(traitBlock)
                        
                        -- Call the same resize logic as MainWindow:ShowTab does
                        C_Timer.After(0, function()
                            local mainWindow = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.MainWindow
                            if mainWindow then
                                if mainWindow.content and mainWindow.content.SetSize and self.sheet and self.sheet.frame then
                                    local w = self.sheet.frame:GetWidth() + 12
                                    local h = self.sheet.frame:GetHeight() + 12
                                    if w and h then
                                        local padX = mainWindow.content.autoSizePadX or 0
                                        local padY = mainWindow.content.autoSizePadY or 0
                                        local minW = mainWindow.footer.frame:GetWidth() or 0

                                        -- apply padding and enforce minimum width
                                        local cw = math.max(w + padX, minW)
                                        local ch = h + padY

                                        mainWindow.content:SetSize(cw, ch)
                                        mainWindow.root:SetSize(cw, ch + mainWindow.footer.frame:GetHeight())
                                    end
                                end
                            end
                        end)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end

function CharacterSheet:Refresh()
    -- Get or create profile on first access
    if not self.profile and RPE.Profile and RPE.Profile.DB then
        self.profile = RPE.Profile.DB.GetOrCreateActive()
    end

    if not self.bodyGroup then return end
    -- Clear old sections
    for _, child in ipairs(self.bodyGroup.children or {}) do child:Destroy() end
    self.bodyGroup.children = {}

    -- Rebuild sections with stat data - CharacterSheet only shows SKILL stats
    local function section(title, key, columns)
        local titleText = Text:New("RPE_CS_Title_" .. key, {
            parent = self.bodyGroup,
            text   = title,
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(titleText.fs, "textMuted")

        local row = HGroup:New("RPE_CS_Row_" .. key, {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        self.bodyGroup:Add(row)
        self:DrawStats(row, key, columns)
    end

    -- Add Experience bar if use_level_system is enabled (BEFORE Skills section)
    local useLevelSystem = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.use_level_system) or 0
    if useLevelSystem == 1 then
        local expTitle = Text:New("RPE_CS_Title_Experience", {
            parent = self.bodyGroup,
            text   = "Experience",
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(expTitle.fs, "textMuted")
        self.bodyGroup:Add(expTitle)

        local expRow = HGroup:New("RPE_CS_Row_Experience", {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "CENTER",
            autoSize = true,
        })
        self.bodyGroup:Add(expRow)
        self:DrawExperienceBar(expRow)
    end

    section("Skills",            "SKILL",        3)

    -- Add Languages and Traits side-by-side (left and right columns)
    do
        local rowContainer = HGroup:New("RPE_CS_Row_LanguagesTraits", {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        self.bodyGroup:Add(rowContainer)

        -- Left column: Languages
        local langColContainer = VGroup:New("RPE_CS_Col_Languages_Container", {
            parent  = rowContainer,
            spacingY = 6,
            alignH   = "LEFT",
            autoSize = true,
        })
        rowContainer:Add(langColContainer)

        local langTitle = Text:New("RPE_CS_Title_Languages", {
            parent = langColContainer,
            text   = "Languages",
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(langTitle.fs, "textMuted")
        langColContainer:Add(langTitle)

        local langRow = VGroup:New("RPE_CS_Row_Languages", {
            parent  = langColContainer,
            spacingY = 6,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        langColContainer:Add(langRow)
        self:DrawLanguages(langRow)

        -- Right column: Traits
        local traitColContainer = VGroup:New("RPE_CS_Col_Traits_Container", {
            parent  = rowContainer,
            spacingY = 6,
            alignH   = "LEFT",
            autoSize = true,
        })
        rowContainer:Add(traitColContainer)

        local traitTitle = Text:New("RPE_CS_Title_Traits", {
            parent = traitColContainer,
            text   = "Traits",
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(traitTitle.fs, "textMuted")
        traitColContainer:Add(traitTitle)

        local traitRow = VGroup:New("RPE_CS_Row_Traits", {
            parent  = traitColContainer,
            spacingY = 6,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        traitColContainer:Add(traitRow)
        self:DrawTraits(traitRow)
    end
end

--- Injects character data into the UI.
function CharacterSheet:SetCharacter(data)
    if not data then return end
    if data.name  then self.charName:SetText(data.name) end
    if data.guild then self.guildName:SetText(data.guild) end
end

function CharacterSheet.New(opts)
    local self = setmetatable({}, CharacterSheet)
    self:BuildUI(opts or {})
    -- Store as a global instance so other code can find it
    _G.RPE_UI.Windows.CharacterSheetInstance = self
    -- Expose under RPE.Core.Windows too (so external hooks can find it)
    _G.RPE = _G.RPE or {}
    _G.RPE.Core = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.CharacterSheet = self
    return self
end

return CharacterSheet