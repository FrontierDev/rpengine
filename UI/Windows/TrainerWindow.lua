-- RPE_UI/Windows/TrainerWindow.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local Panel    = RPE_UI.Elements.Panel
local TextBtn  = RPE_UI.Elements.TextButton
local Text     = RPE_UI.Elements.Text
local HBorder  = RPE_UI.Elements.HorizontalBorder
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Common   = RPE.Common or {}

local RecipeRegistry = RPE.Core and RPE.Core.RecipeRegistry
local CharacterProfile = RPE.Profile and RPE.Profile.CharacterProfile
local SpellRegistry = RPE.Core and RPE.Core.SpellRegistry


---@class TrainerWindow
local TrainerWindow = {}
_G.RPE_UI.Windows.TrainerWindow = TrainerWindow
TrainerWindow.__index = TrainerWindow
TrainerWindow.Name = "TrainerWindow"

local FOOTER_HEIGHT = 30
local ENTRY_HEIGHT  = 20
local ENTRY_SPACING = 3
local HEADER_HEIGHT = 28

local FILTER_OPTIONS = { "Available", "Unavailable", "Already Known" }

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.TrainerWindow = self
end

-- Update filter button label text
function TrainerWindow:_updateFilterText()
    local active = {}
    for k, v in pairs(self.activeFilters or {}) do
        if v then table.insert(active, k) end
    end
    if #active == 0 then
        self.filterBtn:SetText("Filter")
    else
        self.filterBtn:SetText("Filter")
    end
end

-- === Build UI ===============================================================
function TrainerWindow:BuildUI()
    -- Root window
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_Trainer_Window", {
        parent = parentFrame,
        width  = 420,
        height = 480,
        point  = "CENTER",
        autoSize = false,
    })

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

    -- === Borders ===
    self.topBorder = HBorder:New("RPE_Trainer_TopBorder", { parent=self.root, stretch=true, thickness=4 })
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    RPE_UI.Colors.ApplyHighlight(self.topBorder)

    self.bottomBorder = HBorder:New("RPE_Trainer_BottomBorder", { parent=self.root, stretch=true, thickness=4 })
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    RPE_UI.Colors.ApplyHighlight(self.bottomBorder)

    -- === Header ===
    self.header = Panel:New("RPE_Trainer_Header", { parent=self.root, autoSize=false })
    self.header.frame:SetHeight(HEADER_HEIGHT)
    self.header.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.header.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)

    -- Profession title (top-left)
    self.headerText = Text:New("RPE_Trainer_HeaderText", {
        parent = self.header,
        text = "Blacksmithing Training", -- will be updated later
        fontTemplate = "GameFontNormalLarge",
        justifyH = "LEFT",
    })
    self.headerText.frame:ClearAllPoints()
    self.headerText.frame:SetPoint("LEFT", self.header.frame, "LEFT", 10, 0)

    -- Filter dropdown (top-right, now multi-select)
    self.filterBtn = TextBtn:New("RPE_Trainer_FilterBtn", {
        parent = self.header,
        width  = 160, height = 20,
        text   = "Filter: Available",
        noBorder = true,
        onClick = function(btn)
            if not (RPE_UI and RPE_UI.Common and RPE_UI.Common.ContextMenu) then return end
            RPE_UI.Common:ContextMenu(btn.frame or UIParent, function(level)
                if level ~= 1 then return end
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true
                info.notCheckable = true
                info.text = "Show recipes:"
                UIDropDownMenu_AddButton(info, level)

                for _, name in ipairs(FILTER_OPTIONS) do
                    local nfo = UIDropDownMenu_CreateInfo()
                    nfo.text = name
                    nfo.keepShownOnClick = true
                    nfo.isNotRadio = true
                    nfo.checked = self.activeFilters[name]
                    nfo.func = function()
                        self.activeFilters[name] = not self.activeFilters[name]
                        self:_updateFilterText()
                        self:RefreshList()
                    end
                    UIDropDownMenu_AddButton(nfo, level)
                end
            end)
        end,
    })
    self.filterBtn.frame:ClearAllPoints()
    self.filterBtn.frame:SetPoint("RIGHT", self.header.frame, "RIGHT", -10, 0)

    -- Default filter: only "Available"
    self.activeFilters = { Available = true }
    self:_updateFilterText()

    -- === Content ===
    self.content = Panel:New("RPE_Trainer_Content", { parent=self.root, autoSize=true })
    self.root:Add(self.content)
    self.content.frame:SetPoint("TOPLEFT", self.header.frame, "BOTTOMLEFT", 0, 0)
    self.content.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 30)

    -- === Scroll ===
    self.scrollFrame = CreateFrame("ScrollFrame", "RPE_Trainer_Scroll", self.content.frame, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", self.content.frame, "TOPLEFT", 8, -8)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", self.content.frame, "BOTTOMRIGHT", -26, 50)

    self.scrollChild = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollChild:SetSize(1, 1)
    self.scrollFrame:SetScrollChild(self.scrollChild)
    local scrollParent = { frame = self.scrollChild, children = {} }

    self.recipeGroup = VGroup:New("RPE_Trainer_RecipeGroup", {
        parent   = scrollParent,
        padding  = { left = 10, right = 10, top = 6, bottom = 6 },
        spacingY = ENTRY_SPACING,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })

    -- === Selected recipe text (non-intrusive) ===
    self.selectedText = Text:New("RPE_Trainer_SelectedText", {
        parent = self.content,
        text = "Selected: (none)",
        fontTemplate = "GameFontNormalSmall",
        justifyH = "CENTER",
    })
    self.selectedText.frame:SetPoint("TOPLEFT", self.scrollFrame, "BOTTOMLEFT", 8, -4)
    self.selectedText.frame:SetPoint("RIGHT", self.scrollFrame, "RIGHT", -8, 0)
    self.selectedText.frame:SetHeight(14)

    -- === Recipe cost text (non-intrusive, sits just below Selected line) ===
    self.costText = Text:New("RPE_Trainer_CostText", {
        parent = self.content,
        text = "Cost: —",
        fontTemplate = "GameFontNormalSmall",
        justifyH = "CENTER",
    })
    self.costText.frame:SetPoint("TOPLEFT", self.selectedText.frame, "BOTTOMLEFT", 0, -2)
    self.costText.frame:SetPoint("RIGHT", self.selectedText.frame, "RIGHT", 0, 0)
    self.costText.frame:SetHeight(14)

    -- === Footer ===
    self.footer = Panel:New("RPE_Trainer_Footer", { parent=self.root, autoSize=false })
    self.root:Add(self.footer)
    self.footer.frame:SetHeight(FOOTER_HEIGHT)
    self.footer.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)

    -- Close button (bottom-left)
    self.closeBtn = TextBtn:New("RPE_Trainer_CloseBtn", {
        parent = self.footer,
        width  = 100, height = 22,
        text   = "Close",
        onClick = function() self:Hide() end,
    })
    self.closeBtn.frame:ClearAllPoints()
    self.closeBtn.frame:SetPoint("LEFT", self.footer.frame, "LEFT", 20, 0)

    -- Learn button (bottom-right)
    self.learnBtn = TextBtn:New("RPE_Trainer_LearnBtn", {
        parent = self.footer,
        width  = 100, height = 22,
        text   = "Learn",
        onClick = function()
            local profile = RPE.Profile.DB:GetOrCreateActive()

            if self.mode == "SPELLS" then
                local spell = self.selectedSpell
                local rank  = self.selectedRank or 1
                if not spell then
                    RPE.Debug:Warning("No spell selected.")
                    return
                end

                if (profile:GetSpellRank(spell.id) or 0) >= rank then
                    RPE.Debug:Warning("You already know this rank.")
                    return
                end

                if rank > 1 and profile:GetSpellRank(spell.id) < (rank - 1) then
                    RPE.Debug:Warning("You must learn previous ranks first.")
                    return
                end

                local useLevels = (RPE.ActiveRules:Get("use_level_system") or 1) ~= 0
                local requiredLvl = spell.unlockLevel + ((rank - 1) * (spell.rankInterval or 1))

                if useLevels and ((profile.level or 1) < requiredLvl) then
                    RPE.Debug:Warning(("Requires level %d to learn Rank %d."):format(requiredLvl, rank))
                    return
                end

                profile:LearnSpell(spell.id, rank)
                RPE.Debug:Internal(("Learned %s (Rank %d)"):format(spell.name or spell.id, rank))
                self:RefreshList()
                return
            end

            -- === Recipe learning ===
            if not self.selectedRecipe then
                RPE.Debug:Warning("No recipe selected.")
                return
            end
            local recipe = self.selectedRecipe
            if profile:KnowsRecipe(recipe.profession, recipe.id) then
                RPE.Debug:Warning("You already know this recipe.")
                return
            end
            local prof = self.profData

            if not prof or ((prof.level or 0) < (recipe.skill or 0)) then
                RPE.Debug:Warning(("You need %d %s skill to learn this recipe."):format(recipe.skill, recipe.profession))
                return
            end

            profile:LearnRecipe(recipe.profession, recipe.id)
            RPE.Debug:Internal(("Learned recipe: %s"):format(recipe.name or recipe.id))
            self:RefreshList()
        end
    })
    self.learnBtn.frame:ClearAllPoints()
    self.learnBtn.frame:SetPoint("RIGHT", self.footer.frame, "RIGHT", -20, 0)


    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

-- === Helpers ================================================================
local function clearList(group)
    if not group or not group.children then return end
    for _, child in ipairs(group.children) do
        if child.Destroy then child:Destroy() end
    end
    group.children = {}
end

-- Single entry creation ------------------------------------------------------
function TrainerWindow:_addRecipeEntry(recipe, prof, profile)
    local playerSkill = tonumber((prof and prof.level) or 0)
    local color = Common.GetRecipeColor and Common:GetRecipeColor(playerSkill, recipe.skill) or "|cffffffff"
    local knows = profile and profile:KnowsRecipe(recipe.profession, recipe.id)
    if knows then color = "|cff808080" end

    local label = string.format("%s%s|r", color, recipe.name or recipe.id)
    local row = HGroup:New("RPE_Trainer_RecipeRow_" .. recipe.id, {
        parent   = self.recipeGroup,
        spacingX = 6,
        alignH   = "LEFT",
        alignV   = "CENTER",
        autoSize = true,
    })
    self.recipeGroup:Add(row)

    local btn = TextBtn:New("RPE_Trainer_Recipe_" .. recipe.id, {
        parent = row,
        width  = 360,
        height = ENTRY_HEIGHT,
        text   = label,
        noBorder = true,
        onClick = function()
            self.selectedRecipe = recipe
            self.selectedButton = btn
            self:_updateSelectionHighlight()
            self:_updateLearnButton()
            self.selectedText:SetText(("Selected: %s (%s)"):format(recipe.name or recipe.id, recipe.skill))
            self.costText:SetText(("Cost: %s"):format(recipe:GetFormattedCost()))
        end,
    })

    -- Left-align text
    btn.label:ClearAllPoints()
    btn.label:SetPoint("LEFT", btn.frame, "LEFT", 6, 0)
    btn.label:SetJustifyH("LEFT")

    row:Add(btn)
end

function TrainerWindow:_addSpellEntry(spell, profile)
    local known = profile.spells and profile.spells[spell.id]
    local color = known and "|cff808080" or "|cffffffff"
    local label = string.format("%s%s|r", color, spell.name or spell.id)
    local row = HGroup:New("RPE_Trainer_SpellRow_" .. spell.id, {
        parent   = self.recipeGroup,
        spacingX = 6,
        alignH   = "LEFT",
        alignV   = "CENTER",
        autoSize = true,
    })
    self.recipeGroup:Add(row)

    local btn = TextBtn:New("RPE_Trainer_Spell_" .. spell.id, {
        parent = row,
        width  = 360,
        height = ENTRY_HEIGHT,
        text   = label,
        noBorder = true,
        onClick = function()
            self.selectedRecipe = nil
            self.selectedSpell = spell
            self.selectedButton = btn
            self:_updateSelectionHighlight()
            self.selectedText:SetText(("Selected: %s (Lv %d)"):format(spell.name or spell.id, spell.unlockLevel or 1))
            self.costText:SetText("Cost: —")
            self:_updateLearnButton()
        end,
    })

    btn.label:ClearAllPoints()
    btn.label:SetPoint("LEFT", btn.frame, "LEFT", 6, 0)
    btn.label:SetJustifyH("LEFT")

    row:Add(btn)
end

function TrainerWindow:_addSpellRankEntry(entry, profile)
    local spell = entry.spellRef
    local knownRank = profile:GetSpellRank(spell.id)
    local pLevel = tonumber(profile.level) or 1
    local requiredLvl = tonumber(entry.unlockLevel) or 1
    local color

    local useLevels = (RPE.ActiveRules:Get("use_level_system") or 1) ~= 0

    if knownRank >= entry.rank then
        color = "|cff808080" -- grey: already known
    elseif (not useLevels or pLevel >= requiredLvl)
    and (entry.rank == 1 or knownRank >= (entry.rank - 1)) then
        color = "|cff00ff00" -- green: available to learn
    else
        color = "|cffff4040" -- red: unavailable
    end

    local label = string.format("%s%s|r", color, entry.name)
    local row = HGroup:New("RPE_Trainer_SpellRow_" .. spell.id .. "_R" .. entry.rank, {
        parent   = self.recipeGroup,
        spacingX = 6,
        alignH   = "LEFT",
        alignV   = "CENTER",
        autoSize = true,
    })
    self.recipeGroup:Add(row)

    local btn = TextBtn:New("RPE_Trainer_Spell_" .. spell.id .. "_R" .. entry.rank, {
        parent = row,
        width  = 360,
        height = ENTRY_HEIGHT,
        text   = label,
        noBorder = true,
        onClick = function()
            self.selectedRecipe = nil
            self.selectedSpell  = spell
            self.selectedRank   = entry.rank
            self.selectedButton = btn
            self:_updateSelectionHighlight()
            self.selectedText:SetText(
                ("Selected: %s (Rank %d, Lv %d)"):format(
                    spell.name or spell.id,
                    entry.rank,
                    entry.unlockLevel or 1
                )
            )
            self.costText:SetText(("Cost: %s"):format(spell:GetFormattedTrainingCost(entry.rank)))
            self:_updateLearnButton()
        end,
    })

    btn.label:ClearAllPoints()
    btn.label:SetPoint("LEFT", btn.frame, "LEFT", 6, 0)
    btn.label:SetJustifyH("LEFT")
    row:Add(btn)
end



-- Update highlight for selected entry
function TrainerWindow:_updateSelectionHighlight()
    -- Clear previous selections
    for _, child in ipairs(self.recipeGroup.children or {}) do
        for _, sub in ipairs(child.children or {}) do
            if sub.kind == "TextButton" then
                -- Restore normal base color
                if sub._baseR and sub._baseG and sub._baseB and sub._baseA then
                    sub.bg:SetColorTexture(sub._baseR, sub._baseG, sub._baseB, sub._baseA)
                end
                -- Restore its original OnLeave if it was replaced
                if sub._originalOnLeave then
                    sub.frame:SetScript("OnLeave", sub._originalOnLeave)
                    sub._originalOnLeave = nil
                end
            end
        end
    end

    -- Highlight the newly selected button
    local btn = self.selectedButton
    if btn then
        if btn._hoverR and btn._hoverG and btn._hoverB and btn._hoverA then
            btn.bg:SetColorTexture(btn._hoverR, btn._hoverG, btn._hoverB, btn._hoverA)
        end

        -- Override OnLeave so highlight stays while selected
        if not btn._originalOnLeave then
            btn._originalOnLeave = btn.frame:GetScript("OnLeave")
        end
        btn.frame:SetScript("OnLeave", function() end)
    end
end


-- Enable/disable Learn button based on selection
function TrainerWindow:_updateLearnButton()
    local recipe = self.selectedRecipe
    local prof   = self.profData
    local profile = RPE.Profile.DB:GetOrCreateActive()

    if self.mode == "SPELLS" then
        local spell = self.selectedSpell
        local rank  = self.selectedRank or 1
        if not spell then self.learnBtn:Lock() return end

        local knownRank = profile:GetSpellRank(spell.id)
        local pLevel = tonumber(profile.level) or 1
        local spellLvl = tonumber(spell.unlockLevel) or 1
        local rankInt  = tonumber(spell.rankInterval) or 1
        local requiredLvl = spellLvl + ((rank - 1) * rankInt)

        local useLevels = (RPE.ActiveRules:Get("use_level_system") or 1) ~= 0

        -- Apply level gating only if the system is enabled
        local belowLevel = useLevels and (pLevel < requiredLvl)

        if (knownRank >= rank)
        or belowLevel
        or (rank > 1 and knownRank < (rank - 1)) then
            self.learnBtn:Lock()
        else
            self.learnBtn:Unlock()
        end
        return
    end


    if not recipe then
        self.learnBtn:Lock()
        return
    end

    if profile:KnowsRecipe(recipe.profession, recipe.id) then
        self.learnBtn:Lock()
        return
    end

    local playerSkill = tonumber((prof and prof.level) or 0)
    if playerSkill >= (recipe.skill or 0) then
        self.learnBtn:Unlock()
    else
        self.learnBtn:Lock()
    end
end

---@param data { mode: string, flags: table, maxLevel: number, target: string }
function TrainerWindow:SetTrainerData(data)
    self.mode     = data.mode or "RECIPES"
    self.flags    = data.flags or {}
    self.maxLevel = tonumber(data.maxLevel) or 0
    self.target   = data.target or nil

    if self.mode == "SPELLS" then
        self.profName = "Spells"
    else
        -- flags can be either a string (e.g., "engineering") or a table with profession key
        local flagsValue = data.flags or {}
        local professionName = "Blacksmithing"
        
        if type(flagsValue) == "string" then
            professionName = flagsValue
        elseif type(flagsValue) == "table" and flagsValue.profession then
            professionName = flagsValue.profession
        end
        
        -- Capitalize profession name for display (e.g., "engineering" -> "Engineering")
        if type(professionName) == "string" and professionName ~= "" then
            professionName = professionName:sub(1, 1):upper() .. professionName:sub(2):lower()
            -- Handle special cases like "First Aid" and "Herbalism"
            if professionName == "First-aid" then professionName = "First Aid" end
        end
        
        self.profName = professionName
    end
    
    local profile = RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
    local profData = nil

    if profile and profile.professions then
        -- Debug all professions
        RPE.Debug:Internal("[TrainerWindow] Available professions:")
        for key, p in pairs(profile.professions) do
            if type(p) == "table" then
                RPE.Debug:Internal(string.format("  [%s] id=%s, level=%s", tostring(key), tostring(p.id), tostring(p.level)))
            end
        end

        -- Try direct key lookup
        profData = profile.professions[self.profName:lower()]

        -- Try matching by ID field (case-insensitive)
        if not profData then
            for _, p in pairs(profile.professions) do
                if type(p.id) == "string" and p.id:lower() == self.profName:lower() then
                    profData = p
                    break
                end
            end
        end
    end

    self.profData = profData
    local skill = (profData and tonumber(profData.level)) or 0

    RPE.Debug:Internal(("[TrainerWindow] Player's %s skill: %d"):format(self.profName, skill))

    self.headerText:SetText(("%s Training"):format(self.profName or "Profession"))
    self.npcName = data.target or "Trainer"
    self:RefreshList()
end




function TrainerWindow:RefreshList()
    clearList(self.recipeGroup)
    local profile = RPE.Profile.DB:GetOrCreateActive()

    if self.mode == "SPELLS" then
        self:_refreshSpells(profile)
    else
        self:_refreshRecipes(profile)
    end
end

function TrainerWindow:_refreshRecipes(profile)
    local map = RecipeRegistry and RecipeRegistry:GetByProfession(self.profName) or {}
    local prof = self.profData
    local playerSkill = (prof and prof.level) or 0

    -- Categorize recipes
    local groups = {
        Available = {},
        Unavailable = {},
        ["Already Known"] = {},
    }

    for _, recipe in pairs(map) do
        local knows = profile:KnowsRecipe(recipe.profession, recipe.id)
        local available = (playerSkill >= (recipe.skill or 0)) and not knows

        if available then
            table.insert(groups.Available, recipe)
        elseif knows then
            table.insert(groups["Already Known"], recipe)
        else
            table.insert(groups.Unavailable, recipe)
        end
    end

    -- Sort each group by skill descending
    local function sortBySkillDesc(a, b)
        return (a.skill or 0) > (b.skill or 0)
    end
    for _, g in pairs(groups) do
        table.sort(g, sortBySkillDesc)
    end

    -- Display in order: Available -> Unavailable -> Already Known
    local order = { "Available", "Unavailable", "Already Known" }
    local count = 0

    for _, groupName in ipairs(order) do
        if self.activeFilters[groupName] then
            local recipes = groups[groupName]
            if #recipes > 0 then
                -- Add group header
                local header = Text:New("RPE_Trainer_Group_" .. groupName, {
                    parent = self.recipeGroup,
                    text = groupName,
                    fontTemplate = "GameFontNormal",
                })
                self.recipeGroup:Add(header)

                -- Add entries
                for _, recipe in ipairs(recipes) do
                    self:_addRecipeEntry(recipe, self.profData, profile)
                    count = count + 1
                end
            end
        end
    end

    if count == 0 then
        local txt = Text:New("RPE_Trainer_Empty", {
            parent = self.recipeGroup,
            text = "(No recipes match your filter)",
            fontTemplate = "GameFontNormalSmall"
        })
        self.recipeGroup:Add(txt)
    end
end

function TrainerWindow:_refreshSpells(profile)
    local map = SpellRegistry and SpellRegistry:All() or {}
    local playerLevel = tonumber(profile.level) or 1
    local knownSpells = profile.spells or {}
    local tags = self.flags.tags or {}

    -- Get ruleset settings
    local useRanks = (RPE.ActiveRules:Get("use_spell_ranks") or 1) ~= 0
    local useLevels = (RPE.ActiveRules:Get("use_level_system") or 1) ~= 0

    local groups = {
        Available = {},
        Unavailable = {},
        ["Already Known"] = {},
    }

    for _, spell in pairs(map) do
        -- === Tag filtering ===
        local matchTag = true
        if tags and #tags > 0 then
            matchTag = false
            for _, want in ipairs(tags) do
                for _, tag in ipairs(spell.tags or {}) do
                    if tag:lower() == want:lower() then
                        matchTag = true
                        break
                    end
                end
                if matchTag then break end
            end
        end
        if not matchTag then
            -- skip this spell entirely
        else
            -- === Determine rank handling ===
            local maxR = (useRanks and tonumber(spell.maxRanks)) or 1
            local baseLvl = tonumber(spell.unlockLevel) or 1
            local step = tonumber(spell.rankInterval) or 1
            local knownRank = profile:GetSpellRank(spell.id)

            for r = 1, maxR do
                local requiredLvl = baseLvl + (r - 1) * step
                local known = knownRank >= r

                -- Rank gating
                local prevLearned = (r == 1) or (knownRank >= (r - 1))

                -- If level system is off, everything is learnable
                local available
                if not useLevels then
                    available = not known and prevLearned
                else
                    available = (playerLevel >= requiredLvl) and not known and prevLearned
                end

                -- If spell ranks disabled, only show rank 1
                if not useRanks and r > 1 then
                    break
                end

                local entry = {
                    id = spell.id,
                    name = ("%s (Rank %d)"):format(spell.name or spell.id, r),
                    rank = r,
                    unlockLevel = requiredLvl,
                    spellRef = spell,
                }

                if known then
                    table.insert(groups["Already Known"], entry)
                elseif available then
                    table.insert(groups.Available, entry)
                elseif not useLevels then
                    -- Level system off → all ranks visible and learnable unless known
                    table.insert(groups.Available, entry)
                else
                    table.insert(groups.Unavailable, entry)
                end
            end
        end
    end

    -- === Sorting ===
    local function sortByLevel(a, b)
        return (a.unlockLevel or 0) < (b.unlockLevel or 0)
    end
    for _, g in pairs(groups) do table.sort(g, sortByLevel) end

    -- === Rendering ===
    local count = 0
    local order = { "Available", "Unavailable", "Already Known" }
    for _, groupName in ipairs(order) do
        if self.activeFilters[groupName] then
            local spells = groups[groupName]
            if #spells > 0 then
                local header = Text:New("RPE_Trainer_Group_" .. groupName, {
                    parent = self.recipeGroup,
                    text = groupName,
                    fontTemplate = "GameFontNormal",
                })
                self.recipeGroup:Add(header)

                for _, entry in ipairs(spells) do
                    self:_addSpellRankEntry(entry, profile)
                    count = count + 1
                end
            end
        end
    end

    if count == 0 then
        local txt = Text:New("RPE_Trainer_Empty", {
            parent = self.recipeGroup,
            text = "(No spells match your filter)",
            fontTemplate = "GameFontNormalSmall",
        })
        self.recipeGroup:Add(txt)
    end
end




function TrainerWindow.New()
    local self = setmetatable({}, TrainerWindow)
    self:BuildUI()
    return self
end

function TrainerWindow:Show() if self.root and self.root.Show then self.root:Show() end end
function TrainerWindow:Hide() if self.root and self.root.Hide then self.root:Hide() end end

return TrainerWindow
