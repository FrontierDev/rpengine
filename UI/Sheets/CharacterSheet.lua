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

    -- Collect visible stats from all datasets (flat profile.stats with CharacterStat objects)
    local stats = {}
    for _, stat in pairs(self.profile.stats or {}) do
        if stat and stat.category == filter
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

function CharacterSheet:DrawCurrencies(currencyRow)
    if not self.profile then return end
    
    -- Clear old children
    for _, child in ipairs(currencyRow.children or {}) do child:Destroy() end
    currencyRow.children = {}
    
    -- Initialize currencies table if needed
    if not self.profile.currencies then
        self.profile.currencies = {}
    end
    local currencies = self.profile.currencies
    
    -- Initialize missing currencies to 0
    if currencies.honor == nil then currencies.honor = 0 end
    if currencies.conquest == nil then currencies.conquest = 0 end
    if currencies.justice == nil then currencies.justice = 0 end
    if currencies.valor == nil then currencies.valor = 0 end
    if currencies.copper == nil then currencies.copper = 0 end
    
    -- Define built-in currency types with their icon IDs and descriptions
    local builtInCurrencies = {
        { key = "copper",   name = "Copper",   icon = nil, description = "The common currency used all around Azeroth." },
        { key = "honor",    name = "Honor",    icon = 1455894, description = "Honor points earned through PvP combat." },
        { key = "conquest", name = "Conquest", icon = 1523630, description = "Conquest points earned through PvP triumphs." },
        { key = "justice",  name = "Justice",  icon = 463446, description = "Justice points earned through PvE combat." },
        { key = "valor",    name = "Valor",    icon = 463447, description = "Valor points earned from heroic encounters." },
    }
    
    -- Collect all currencies (built-in + custom from ItemRegistry)
    local allCurrencies = {}
    
    -- Add built-in currencies first
    for _, currencyDef in ipairs(builtInCurrencies) do
        table.insert(allCurrencies, currencyDef)
    end
    
    -- Add custom currencies from ItemRegistry
    local ItemRegistry = RPE.Core and RPE.Core.ItemRegistry
    if ItemRegistry then
        local allItems = ItemRegistry:All()
        if allItems then
            for itemId, item in pairs(allItems) do
                -- Check if item is a CURRENCY type
                local category = item.category
                if category and category:lower() == "currency" then
                    -- Add this custom currency (key must match how it's stored in profile)
                    local customCurrency = {
                        key = item.name:lower(),  -- Use lowercase name as key (matches Commands.lua storage)
                        name = item.name or itemId,
                        icon = item.icon and tonumber(item.icon) or nil,
                        description = item.description or "",
                        isCustom = true,
                    }
                    table.insert(allCurrencies, customCurrency)
                end
            end
        end
    end
    
    if #allCurrencies == 0 then return end
    
    -- Create a single row with all currencies displayed side-by-side
    for _, currencyDef in ipairs(allCurrencies) do
        local amount = currencies[currencyDef.key] or 0
        local formatted
        local icon = ""
        
        if currencyDef.key == "copper" then
            formatted = RPE.Common:FormatCopper(amount)
        else
            formatted = tostring(amount)
            if currencyDef.icon then
                icon = "|T" .. currencyDef.icon .. ":16:16|t "
            end
        end
        
        local entry = HGroup:New("RPE_CS_Currency_" .. currencyDef.key, {
            parent = currencyRow,
            spacingX = 4,
            alignV = "CENTER",
            alignH = "CENTER",
            autoSize = true,
        })
        currencyRow:Add(entry)
        
        local amountText = Text:New("RPE_CS_CurrencyValue_" .. currencyDef.key, {
            parent = entry,
            text = icon .. formatted,
            width = 140,
            height = 18,
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
        })
        amountText.fs:ClearAllPoints()
        amountText.fs:SetPoint("CENTER", amountText.frame, "CENTER", 0, 0)
        
        -- Add tooltip and right-click menu on hover
        amountText.frame:EnableMouse(true)
        
        -- Store currency info for context menu
        amountText._currencyDef = currencyDef
        amountText._profile = self.profile
        amountText._sheet = self
        
        amountText.frame:SetScript("OnEnter", function(self)
            if RPE and RPE.Common and RPE.Common.ShowTooltip then
                RPE.Common:ShowTooltip(self, {
                    title = amountText._currencyDef.name,
                    lines = amountText._currencyDef.description and amountText._currencyDef.description ~= "" and {
                        { text = amountText._currencyDef.description }
                    } or {}
                })
            end
        end)
        
        amountText.frame:SetScript("OnLeave", function()
            if RPE and RPE.Common and RPE.Common.HideTooltip then
                RPE.Common:HideTooltip()
            end
        end)
        
        -- Right-click for context menu
        amountText.frame:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                local currencyDef = amountText._currencyDef
                local profile = amountText._profile
                local sheet = amountText._sheet
                
                RPE_UI.Common:ContextMenu(self, function(level, menuList)
                    if level == 1 then
                        UIDropDownMenu_AddButton({
                            text = "Send to...",
                            func = function()
                                sheet:_ShowSendCurrencyDialog(currencyDef, profile)
                            end,
                            notCheckable = true
                        }, level)
                        
                        UIDropDownMenu_AddButton({
                            text = "|cffff0000Clear Currency|r",
                            func = function()
                                profile:SetCurrency(currencyDef.key, 0)
                                sheet:Refresh()
                            end,
                            notCheckable = true
                        }, level)
                    end
                end)
            end
        end)
        
        entry:Add(amountText)
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

function CharacterSheet:_ShowSendCurrencyDialog(currencyDef, profile)
    local Popup = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    local HGroup = RPE_UI.Elements and RPE_UI.Elements.HorizontalLayoutGroup
    local VGroup = RPE_UI.Elements and RPE_UI.Elements.VerticalLayoutGroup
    local Text = RPE_UI.Elements and RPE_UI.Elements.Text
    local Input = RPE_UI.Elements and RPE_UI.Elements.Input
    local Dropdown = RPE_UI.Elements and RPE_UI.Elements.Dropdown
    
    if not (Popup and HGroup and VGroup and Text and Input and Dropdown) then
        return
    end
    
    -- Build list of group members
    local players = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                table.insert(players, name)
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name then
                    table.insert(players, name)
                end
            end
        end
    end
    
    if #players == 0 then
        RPE.Debug:Warning("No group members found to send currency to")
        return
    end
    
    table.sort(players)
    
    -- Create popup dialog
    local isImmersion = RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = isImmersion and WorldFrame or UIParent
    
    local p = Popup.New({
        title = "Send " .. currencyDef.name,
        text = "Select a recipient and amount to send:",
        width = 400,
        parentFrame = parentFrame,
        clickOffToClose = true,
    })
    
    -- Recipient selector
    local recipientRow = HGroup:New("RPE_SendCurrency_RecipientRow", {
        parent = p.mid,
        autoSize = true,
        spacingX = 10,
        alignV = "CENTER",
    })
    
    local recipientLabel = Text:New("RPE_SendCurrency_RecipientLabel", {
        parent = recipientRow,
        text = "To:",
        width = 60,
    })
    recipientRow:Add(recipientLabel)
    
    local recipientDropdown = Dropdown:New("RPE_SendCurrency_RecipientDropdown", {
        parent = recipientRow,
        width = 310,
        choices = players,
        value = players[1],
    })
    recipientRow:Add(recipientDropdown)
    
    p.mid:Add(recipientRow)
    
    -- Amount selector
    local amountRow = HGroup:New("RPE_SendCurrency_AmountRow", {
        parent = p.mid,
        autoSize = true,
        spacingX = 10,
        alignV = "CENTER",
    })
    
    local amountLabel = Text:New("RPE_SendCurrency_AmountLabel", {
        parent = amountRow,
        text = "Amount:",
        width = 60,
    })
    amountRow:Add(amountLabel)
    
    local currentAmount = profile:GetCurrency(currencyDef.key)
    local amountInput = Input:New("RPE_SendCurrency_AmountInput", {
        parent = amountRow,
        width = 310,
        height = 20,
        placeholder = "0",
        text = tostring(currentAmount),
    })
    amountRow:Add(amountInput)
    
    p.mid:Add(amountRow)
    
    -- Recalculate mid layout
    if p.mid and p.mid.CalculateLayout then
        p.mid:CalculateLayout()
    end
    
    -- Resize popup
    C_Timer.After(0, function()
        if p and p._autoResize then
            pcall(p._autoResize, p)
        end
    end)
    
    -- Set up callbacks
    p:SetCallbacks(
        function()
            local selectedPlayer = recipientDropdown:GetValue()
            local amountText = amountInput:GetText()
            local amount = tonumber(amountText) or 0
            
            if not selectedPlayer or selectedPlayer == "" then
                RPE.Debug:Warning("No recipient selected")
                return
            end
            
            if amount <= 0 then
                RPE.Debug:Warning("Invalid amount")
                return
            end
            
            if amount > currentAmount then
                RPE.Debug:Warning("You don't have enough " .. currencyDef.name)
                return
            end
            
            -- Send the currency via broadcast
            local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
            if Broadcast and Broadcast.SendCurrency then
                local realm = GetRealmName():gsub("%s+", "")
                local playerKey = (selectedPlayer .. "-" .. realm):lower()
                Broadcast:SendCurrency(playerKey, currencyDef.key, amount)
                
                -- Refresh the sheet to show updated amount
                self:Refresh()
            end
        end,
        function() end  -- Cancel callback
    )
    
    p:SetButtons("Send", "Cancel")
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
    
    -- Organize traits by category and type
    local classTraits = {}  -- {className => [traits]}
    local racialTraits = {} -- {raceName => [traits]}
    local genericTraits = {} -- [traits]
    
    for _, trait in ipairs(traitAuras) do
        local isRacial = false
        local isClass = false
        local raceType = nil
        local classType = nil
        
        if trait.def.tags then
            for _, tag in ipairs(trait.def.tags) do
                if type(tag) == "string" then
                    local tagLower = tag:lower()
                    if tagLower:sub(1, 5) == "race:" then
                        isRacial = true
                        raceType = tag:sub(6)  -- Extract "human" from "race:human"
                        break
                    elseif tagLower:sub(1, 6) == "class:" then
                        isClass = true
                        classType = tag:sub(7)  -- Extract "warrior" from "class:warrior"
                        break
                    end
                end
            end
        end
        
        if isRacial and raceType then
            racialTraits[raceType] = racialTraits[raceType] or {}
            table.insert(racialTraits[raceType], trait)
        elseif isClass and classType then
            classTraits[classType] = classTraits[classType] or {}
            table.insert(classTraits[classType], trait)
        else
            table.insert(genericTraits, trait)
        end
    end
    
    -- Sort category names
    local classNames = {}
    for className in pairs(classTraits) do
        table.insert(classNames, className)
    end
    table.sort(classNames)
    
    local raceNames = {}
    for raceName in pairs(racialTraits) do
        table.insert(raceNames, raceName)
    end
    table.sort(raceNames)
    
    -- Sort traits within each category
    local function sortTraits(traits)
        table.sort(traits, function(a, b)
            return (a.def.name or a.id) < (b.def.name or b.id)
        end)
        return traits
    end
    
    for _, className in ipairs(classNames) do
        sortTraits(classTraits[className])
    end
    for _, raceName in ipairs(raceNames) do
        sortTraits(racialTraits[raceName])
    end
    sortTraits(genericTraits)
    
    -- Store menu data on self so it persists across menu re-initialization
    self._traitMenuData = {
        classTraits = classTraits,
        racialTraits = racialTraits,
        genericTraits = genericTraits,
        classNames = classNames,
        raceNames = raceNames,
        classCount = classCount,
        racialCount = racialCount,
        genericCount = genericCount,
        totalTraits = totalTraits,
        profile = self.profile,
        AuraRegistry = AuraRegistry,
    }
    
    RPE_UI.Common:ContextMenu(self, function(level, menuList)
        local data = self._traitMenuData
        if not data then return end
        
        if level == 1 then
            -- Level 1: Main categories
            local maxTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits) or 0
            local atMaxTotal = maxTraits > 0 and data.totalTraits >= maxTraits
            
            -- Class Traits category
            if #data.classNames > 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.text = "Class Traits"
                info.hasArrow = true
                info.menuList = "CLASS_TRAITS"
                UIDropDownMenu_AddButton(info, level)
            end
            
            -- Racial Traits category
            if #data.raceNames > 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.text = "Racial Traits"
                info.hasArrow = true
                info.menuList = "RACIAL_TRAITS"
                UIDropDownMenu_AddButton(info, level)
            end
            
            -- Generic Traits category
            if #data.genericTraits > 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.text = "Generic Traits"
                info.hasArrow = true
                info.menuList = "GENERIC_TRAITS"
                UIDropDownMenu_AddButton(info, level)
            end
            
        elseif level == 2 then
            -- Level 2: Class or Race subcategories, or Generic traits directly
            if menuList == "CLASS_TRAITS" then
                for _, className in ipairs(data.classNames) do
                    local maxClassTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_class_traits) or 0
                    local classDisabled = maxClassTraits > 0 and data.classCount >= maxClassTraits
                    
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = className:sub(1, 1):upper() .. className:sub(2):lower()  -- Capitalize
                    info.hasArrow = true
                    info.menuList = "CLASS:" .. className
                    info.disabled = classDisabled and not data.profile:HasTrait(data.classTraits[className][1].id)
                    UIDropDownMenu_AddButton(info, level)
                end
                
            elseif menuList == "RACIAL_TRAITS" then
                for _, raceName in ipairs(data.raceNames) do
                    local maxRacialTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_racial_traits) or 0
                    local raceDisabled = maxRacialTraits > 0 and data.racialCount >= maxRacialTraits
                    
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = raceName:sub(1, 1):upper() .. raceName:sub(2):lower()  -- Capitalize
                    info.hasArrow = true
                    info.menuList = "RACE:" .. raceName
                    info.disabled = raceDisabled and not data.profile:HasTrait(data.racialTraits[raceName][1].id)
                    UIDropDownMenu_AddButton(info, level)
                end
                
            elseif menuList == "GENERIC_TRAITS" then
                for _, trait in ipairs(data.genericTraits) do
                    local maxGenericTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_generic_traits) or 0
                    local isDisabled = maxGenericTraits > 0 and data.genericCount >= maxGenericTraits and not data.profile:HasTrait(trait.id)
                    
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = trait.def.name or trait.id
                    info.icon = trait.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                    info.disabled = isDisabled
                    info.func = function()
                        if not isDisabled then
                            data.profile:AddTrait(trait.id)
                            self:DrawTraits(traitBlock)
                            CloseDropDownMenus()
                            
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
            
        elseif level == 3 then
            -- Level 3: Individual traits within a class or race
            local maxTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_traits) or 0
            local atMaxTotal = maxTraits > 0 and data.totalTraits >= maxTraits
            
            if menuList and menuList:sub(1, 6) == "CLASS:" then
                local className = menuList:sub(7)
                local maxClassTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_class_traits) or 0
                
                for _, trait in ipairs(data.classTraits[className]) do
                    local isDisabled = (atMaxTotal and not data.profile:HasTrait(trait.id)) or 
                                      (maxClassTraits > 0 and data.classCount >= maxClassTraits and not data.profile:HasTrait(trait.id))
                    
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = trait.def.name or trait.id
                    info.icon = trait.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                    info.disabled = isDisabled
                    info.func = function()
                        if not isDisabled then
                            data.profile:AddTrait(trait.id)
                            self:DrawTraits(traitBlock)
                            CloseDropDownMenus()
                            
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
                
            elseif menuList and menuList:sub(1, 5) == "RACE:" then
                local raceName = menuList:sub(6)
                local maxRacialTraits = (RPE.ActiveRules and RPE.ActiveRules.rules and RPE.ActiveRules.rules.max_racial_traits) or 0
                
                for _, trait in ipairs(data.racialTraits[raceName]) do
                    local isDisabled = (atMaxTotal and not data.profile:HasTrait(trait.id)) or 
                                      (maxRacialTraits > 0 and data.racialCount >= maxRacialTraits and not data.profile:HasTrait(trait.id))
                    
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = trait.def.name or trait.id
                    info.icon = trait.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                    info.disabled = isDisabled
                    info.func = function()
                        if not isDisabled then
                            data.profile:AddTrait(trait.id)
                            self:DrawTraits(traitBlock)
                            CloseDropDownMenus()
                            
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

    -- Add Currencies section
    do
        local currencyTitle = Text:New("RPE_CS_Title_Currencies", {
            parent = self.bodyGroup,
            text   = "Currencies",
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(currencyTitle.fs, "textMuted")
        self.bodyGroup:Add(currencyTitle)

        local currencyRow = HGroup:New("RPE_CS_Row_Currencies", {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "CENTER",
            autoSize = true,
        })
        self.bodyGroup:Add(currencyRow)
        self:DrawCurrencies(currencyRow)
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