-- RPE_UI/Windows/SetupWindow.lua
-- User-facing setup wizard window that loads pages from the dataset
-- referenced by the "setup_wizard" active rule.

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window    = RPE_UI.Elements.Window
local Panel     = RPE_UI.Elements.Panel
local VGroup    = RPE_UI.Elements.VerticalLayoutGroup
local HGroup    = RPE_UI.Elements.HorizontalLayoutGroup
local Text      = RPE_UI.Elements.Text
local TextBtn   = RPE_UI.Elements.TextButton
local HBorder   = RPE_UI.Elements.HorizontalBorder
local Dropdown  = RPE_UI.Elements.Dropdown
local ProgressBar = RPE_UI.Prefabs.ProgressBar

---@class SetupWindow
---@field root Window
---@field header Panel
---@field body Panel
---@field footer Panel
---@field pages table
---@field currentPageIdx number
---@field currentWinH number
---@field wizardData table|nil
---@field statValues table<string, number>
---@field statIncrementBy table<string, number>
---@field standardArrayAssignments table<string, number>
---@field standardArrayAvailable table<number, boolean>
---@field standardArrayStatRows table
---@field pointBuyPoints number
---@field incrementBy number
---@field selectedRace string|nil
---@field selectedRaceTraits table<string, boolean>
local SetupWindow = {}
_G.RPE_UI.Windows.SetupWindow = SetupWindow
SetupWindow.__index = SetupWindow
SetupWindow.Name = "SetupWindow"

local WIN_W = 600
local MIN_WIN_H = 400
local MAX_WIN_H = 700
local BUTTON_HEIGHT = 26
local BUTTON_SPACING = 4
local FOOTER_PADDING_Y = 7
local STAT_ROW_HEIGHT = 20  -- Height of each stat row
local HEADER_MIN_HEIGHT = 100  -- Minimum header height
local FOOTER_HEIGHT = BUTTON_HEIGHT + (2 * FOOTER_PADDING_Y)  -- Footer height

-- Race definitions for SELECT_RACE pages (World of Warcraft races)
-- Data from https://wowpedia.fandom.com/wiki/RaceId
local RACES = {
    -- Original Races
    {id = "human", name = "Human", icon = 236448},
    {id = "orc", name = "Orc", icon = 236452},
    {id = "dwarf", name = "Dwarf", icon = 236444},
    {id = "nightelf", name = "Night Elf", icon = 236450},
    {id = "undead", name = "Undead", icon = 236458},
    {id = "tauren", name = "Tauren", icon = 236454},
    {id = "gnome", name = "Gnome", icon = 236446},
    {id = "troll", name = "Troll", icon = 236456},
    {id = "goblin", name = "Goblin", icon = 463874},
    {id = "bloodelf", name = "Blood Elf", icon = 236440},
    {id = "draenei", name = "Draenei", icon = 236442},
    {id = "pandaren", name = "Pandaren", icon = 626190},
    {id = "nightborne", name = "Nightborne", icon = 1525723},
    {id = "highmountaintauren", name = "Highmountain Tauren", icon = 1786419},
    {id = "voidelf", name = "Void Elf", icon = 1786422},
    {id = "lightforged", name = "Lightforged Draenei", icon = 1786420},
    {id = "zandalari", name = "Zandalari Troll", icon = 2032601},
    {id = "kultiran", name = "Kul Tiran", icon = 2447785},
    {id = "darkiron", name = "Dark Iron Dwarf", icon = 1851464},
    {id = "vulpera", name = "Vulpera", icon = 3208033},
    {id = "magharorc", name = "Mag'har Orc", icon = 1989713},
    {id = "mechagnome", name = "Mechagnome", icon = 3208032},
    {id = "worgen", name = "Worgen", icon = 466012},
    {id = "dracthyr", name = "Dracthyr", icon = 4616659},
}

local CLASSES = {
    {id = "warrior", name = "Warrior", icon = 626008},
    {id = "paladin", name = "Paladin", icon = 626003},
    {id = "hunter", name = "Hunter", icon = 626000},
    {id = "rogue", name = "Rogue", icon = 626005},
    {id = "priest", name = "Priest", icon = 626004},
    {id = "deathknight", name = "Death Knight", icon = 625998},
    {id = "shaman", name = "Shaman", icon = 626006},
    {id = "mage", name = "Mage", icon = 626001},
    {id = "warlock", name = "Warlock", icon = 626007},
    {id = "druid", name = "Druid", icon = 625999},
    {id = "monk", name = "Monk", icon = 626002},
    {id = "demonhunter", name = "Demon Hunter", icon = 1260827},
    {id = "evoker", name = "Evoker", icon = 4574311},
}

local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.SetupWindow = self
end

local function wipe_children(group)
    if not (group and group.children) then return end
    for i = #group.children, 1, -1 do
        local ch = group.children[i]
        if ch and ch.frame and ch.frame.SetParent then ch.frame:SetParent(nil) end
        if ch and ch.Hide then ch:Hide() end
        group.children[i] = nil
    end
    if group.RequestAutoSize then group:RequestAutoSize() end
end

function SetupWindow:BuildUI()
    -- Root window - start with minimum height
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.currentWinH = MIN_WIN_H
    self.root = Window:New("RPE_Setup_Window", {
        parent = parentFrame,
        width  = WIN_W,
        height = self.currentWinH,
        point  = "CENTER",
        autoSize = false, -- fixed size
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

    -- Top border
    self.topBorder = HBorder:New("RPE_Setup_TopBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 2,
        y             = 0,
        layer         = "BORDER",
    })
    self.topBorder.frame:ClearAllPoints()
    self.topBorder.frame:SetPoint("TOPLEFT", self.root.frame, "TOPLEFT", 0, 0)
    self.topBorder.frame:SetPoint("TOPRIGHT", self.root.frame, "TOPRIGHT", 0, 0)
    _G.RPE_UI.Colors.ApplyHighlight(self.topBorder)

    -- Bottom border
    self.bottomBorder = HBorder:New("RPE_Setup_BottomBorder", {
        parent        = self.root,
        stretch       = true,
        thickness     = 2,
        y             = -2,
        layer         = "BORDER",
    })
    self.bottomBorder.frame:ClearAllPoints()
    self.bottomBorder.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.bottomBorder.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    _G.RPE_UI.Colors.ApplyHighlight(self.bottomBorder)

    -- Header panel (for title/instructions)
    self.header = Panel:New("RPE_Setup_Header", {
        y = -5,
        parent  = self.root,
        autoSize = true,
    })
    self.root:Add(self.header)
    self.header.frame:ClearAllPoints()
    self.header.frame:SetPoint("TOPLEFT", self.topBorder.frame, "BOTTOMLEFT", 0, 0)
    self.header.frame:SetPoint("TOPRIGHT", self.topBorder.frame, "BOTTOMRIGHT", 0, 0)

    -- Body panel (main content)
    self.body = Panel:New("RPE_Setup_Body", {
        parent  = self.root,
        autoSize = true,
    })
    self.root:Add(self.body)
    self.body.frame:ClearAllPoints()
    self.body.frame:SetPoint("TOPLEFT", self.header.frame, "BOTTOMLEFT", 0, 0)
    self.body.frame:SetPoint("TOPRIGHT", self.header.frame, "BOTTOMRIGHT", 0, 0)

    -- Footer panel
    self.footer = Panel:New("RPE_Setup_Footer", {
        parent  = self.root,
        autoSize = false,
    })
    self.root:Add(self.footer)
    self.footer.frame:ClearAllPoints()
    self.footer.frame:SetPoint("BOTTOMLEFT", self.root.frame, "BOTTOMLEFT", 0, 0)
    self.footer.frame:SetPoint("BOTTOMRIGHT", self.root.frame, "BOTTOMRIGHT", 0, 0)
    self.footer.frame:SetHeight(60)

    -- Body to footer anchoring
    self.body.frame:ClearAllPoints()
    self.body.frame:SetPoint("TOPLEFT", self.header.frame, "BOTTOMLEFT", 0, 0)
    self.body.frame:SetPoint("TOPRIGHT", self.header.frame, "BOTTOMRIGHT", 0, 0)
    self.body.frame:SetPoint("BOTTOMLEFT", self.footer.frame, "TOPLEFT", 0, 0)
    self.body.frame:SetPoint("BOTTOMRIGHT", self.footer.frame, "TOPRIGHT", 0, 0)

    -- Progress bar above buttons
    if ProgressBar then
        self.progressBar = ProgressBar:New("RPE_Setup_ProgressBar", {
            parent = self.footer,
            width = WIN_W - 20,
            height = 6,
            value = 1,
            maxValue = 1,
            showText = false,
            style = "progress_xp"
        })
        self.footer:Add(self.progressBar)
        self.progressBar.frame:SetPoint("TOP", self.footer.frame, "TOP", 0, -2)
    end

    -- Footer button group - centered
    local footerGroup = HGroup:New("RPE_Setup_FooterGroup", {
        parent = self.footer, spacingX = 12, alignH = "CENTER", alignV = "CENTER", y = -10,
        autoSize = false, width = WIN_W, height = BUTTON_HEIGHT + (2 * FOOTER_PADDING_Y),
    })
    self.footer:Add(footerGroup)

    local prevBtn = TextBtn:New("RPE_Setup_PrevBtn", {
        parent = footerGroup, text = "< Previous", width = 100, height = BUTTON_HEIGHT,
        onClick = function() self:PreviousPage() end,
    })
    footerGroup:Add(prevBtn)
    self.prevBtn = prevBtn

    local pageText = Text:New("RPE_Setup_PageText", {
        parent = footerGroup, text = "Step 1 / 1", fontSize = 12,
    })
    footerGroup:Add(pageText)
    self.pageText = pageText

    local nextBtn = TextBtn:New("RPE_Setup_NextBtn", {
        parent = footerGroup, text = "Next >", width = 100, height = BUTTON_HEIGHT,
        onClick = function() self:NextPage() end,
    })
    footerGroup:Add(nextBtn)
    self.nextBtn = nextBtn

    local finishBtn = TextBtn:New("RPE_Setup_FinishBtn", {
        parent = footerGroup, text = "Finish", width = 100, height = BUTTON_HEIGHT,
        onClick = function() self:Finish() end,
    })
    footerGroup:Add(finishBtn)
    self.finishBtn = finishBtn

    self.pages = {}
    self.currentPageIdx = 1
    self.statValues = {}
    self.statIncrementBy = {}  -- Maps statId to the incrementBy value from the page where it was first edited
    self._pageItemSelections = {}  -- Maps pageIdx to {itemId -> {id, qty}} for per-page item tracking
    self._pageAllowances = {}  -- Maps pageIdx to spent allowance in copper for that page
    self._pageSpareChange = {}  -- Maps pageIdx to leftover copper amount if spareChange is enabled
    self._pageSelectedProfessions = {}  -- Maps pageIdx to array of selected profession names
    self._pageProfessionLevels = {}  -- Maps pageIdx -> profName -> level
    self:LoadWizardData()
    self:ShowPage(1)

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function SetupWindow:LoadWizardData()
    local AR = _G.RPE and _G.RPE.ActiveRules
    if not AR then
        return
    end

    -- Get the dataset name from the "setup_wizard" rule
    local setupDatasetName = AR:Get("setup_wizard")
    if not setupDatasetName then
        return
    end

    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not DB then
        return
    end

    local dataset = DB.GetByName(setupDatasetName)
    if not dataset then
        return
    end

    if not dataset.setupWizard or not dataset.setupWizard.pages then
        return
    end

    self.wizardData = dataset.setupWizard
    self.pages = self.wizardData.pages or {}
    self.dataset = dataset  -- Store dataset for later access to custom races
    
    local DBG = _G.RPE and _G.RPE.Debug
    if DBG then DBG:Internal("[SetupWindow] Loaded wizard data with " .. tostring(#self.pages) .. " pages") end
    
    self:UpdatePageText()
end

function SetupWindow:ResizeWindow(statCount)
    -- Calculate height needed based on number of stats
    -- Format: header (variable) + body (rows) + footer (fixed)
    -- Use higher per-stat height to account for spacing and padding between rows
    local headerHeight = HEADER_MIN_HEIGHT
    local perStatHeight = 32  -- Height per stat row including spacing
    local statRowsHeight = (statCount or 0) * perStatHeight
    local newHeight = headerHeight + statRowsHeight + FOOTER_HEIGHT + 40  -- +40 for additional spacing/padding
    
    -- Clamp to min/max
    newHeight = math.max(MIN_WIN_H, math.min(newHeight, MAX_WIN_H))
    
    self.currentWinH = newHeight
    if self.root and self.root.frame and self.root.frame.SetHeight then
        self.root.frame:SetHeight(newHeight)
    end
end

function SetupWindow:ShowPage(idx)
    idx = math.max(1, math.min(idx or 1, #self.pages))
    self.currentPageIdx = idx

    -- Clear header and body
    wipe_children(self.header)
    wipe_children(self.body)

    if #self.pages == 0 then
        local text = Text:New("RPE_Setup_NoPages", {
            parent = self.body, text = "No setup pages configured.",
            fontSize = 12,
        })
        self.body:Add(text)
        return
    end

    local page = self.pages[idx]
    if not page then return end

    -- Create header group for title and instructions
    local headerGroup = VGroup:New("RPE_Setup_HeaderGroup_" .. idx, {
        parent = self.header, spacingY = 6, alignH = "CENTER", alignV = "TOP",
        autoSize = false, width = WIN_W - 20, height = 100,
        padding = {top=10, bottom=-10, left=0, right=0},
    })
    self.header:Add(headerGroup)

    -- Create body group for page content
    local bodyGroup = VGroup:New("RPE_Setup_BodyGroup_" .. idx, {
        parent = self.body, spacingY = 12, alignH = "CENTER", alignV = "TOP",
        autoSize = true, width = WIN_W - 20, x = 10,
    })
    self.body:Add(bodyGroup)
    self._currentBodyGroup = bodyGroup  -- Store for use in UpdateWindowHeight
    
    -- Ensure body doesn't shift by setting a fixed width
    self.body.frame:SetWidth(WIN_W)

    -- Page type specific rendering
    if page.pageType == "SELECT_RACE" then
        self:RenderSelectRace(headerGroup, bodyGroup, page)
    elseif page.pageType == "SELECT_CLASS" then
        self:RenderSelectClass(headerGroup, bodyGroup, page)
    elseif page.pageType == "SELECT_LANGUAGE" then
        self:RenderSelectLanguage(headerGroup, bodyGroup, page)
    elseif page.pageType == "SELECT_SPELLS" then
        self:RenderSelectSpells(headerGroup, bodyGroup, page)
    elseif page.pageType == "SELECT_ITEMS" then
        self:RenderSelectItems(headerGroup, bodyGroup, page)
    elseif page.pageType == "SELECT_PROFESSIONS" then
        self:RenderSelectProfessions(headerGroup, bodyGroup, page)
    elseif page.pageType == "SELECT_STATS" then
        self:RenderSelectStats(headerGroup, bodyGroup, page)
    end

    self:UpdatePageText()
    self:UpdateButtonStates()
end

function SetupWindow:UpdateWindowHeight(traitCount)
    -- Calculate and set window height based on trait count
    -- 3 traits per row, ~100 pixels per row (includes spacing and borders)
    local traitRows = math.max(1, math.ceil(traitCount / 3))
    local headerHeight = HEADER_MIN_HEIGHT
    local bodyHeight = traitRows * 100
    local newHeight = headerHeight + bodyHeight + FOOTER_HEIGHT + 20
    
    -- Clamp to min/max
    newHeight = math.max(MIN_WIN_H, math.min(newHeight, MAX_WIN_H))
    
    self.currentWinH = newHeight
    if self.root and self.root.frame then
        self.root.frame:SetHeight(newHeight)
    end
    
    -- Fix body panel width to prevent horizontal shifts
    if self.body and self.body.frame then
        self.body.frame:SetWidth(WIN_W)
    end
    
    -- Reset bodyGroup position and anchor to prevent layout shift
    if self._currentBodyGroup and self._currentBodyGroup.frame then
        self._currentBodyGroup.frame:ClearAllPoints()
        self._currentBodyGroup.frame:SetPoint("TOPLEFT", self.body.frame, "TOPLEFT", 10, 0)
        self._currentBodyGroup.frame:SetPoint("TOPRIGHT", self.body.frame, "TOPRIGHT", -10, 0)
    end
end

function SetupWindow:RenderSelectRace(headerGroup, bodyGroup, page)
    local maxRaceTraits = RPE.ActiveRules:Get("max_racial_traits", 0)
    local window = self
    
    -- Title in header
    local titleText = Text:New("RPE_Setup_SelectRace_Title", {
        parent = headerGroup, text = page.title or "Select a Race",
        fontTemplate = "GameFontNormalLarge"
    })
    headerGroup:Add(titleText)
    
    -- Instructions in header
    local instrText = Text:New("RPE_Setup_SelectRace_Instructions", {
        parent = headerGroup, 
        text = "Select a race and up to " .. tostring(maxRaceTraits) .. " racial traits",
    })
    headerGroup:Add(instrText)
    
    -- Track selected race and traits
    if not self.selectedRace then
        self.selectedRace = nil
    end
    if not self.selectedRaceTraits then
        self.selectedRaceTraits = {}
    end
    
    -- Build race list from RACES plus any custom races from dataset
    local racesToUse = {}
    for _, race in ipairs(RACES) do
        table.insert(racesToUse, race)
    end
    
    -- Add custom races from the current page if available
    -- Custom races are stored at the page level, not wizard level
    if page.customRaces and #page.customRaces > 0 then
        for _, race in ipairs(page.customRaces) do
            table.insert(racesToUse, race)
        end
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupWindow] Loaded " .. tostring(#page.customRaces) .. " custom races from page") end
        for i, race in ipairs(page.customRaces) do
            if DBG then DBG:Internal("[SetupWindow]   Race " .. i .. ": id=" .. tostring(race.id) .. ", name=" .. tostring(race.name) .. ", icon=" .. tostring(race.icon)) end
        end
    else
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupWindow] No custom races in current page") end
    end
    
    -- Get IconButton class
    local IconBtn = RPE_UI.Elements.IconButton
    
    -- Calculate number of rows needed (12 columns per row)
    local racesPerRow = 12
    local numRows = math.ceil(#racesToUse / racesPerRow)
    local DBG = _G.RPE and _G.RPE.Debug
    if DBG then DBG:Internal("[SetupWindow] Total races: " .. tostring(#racesToUse) .. ", rows needed: " .. tostring(numRows)) end
    
    -- Create dynamic rows based on race count
    local raceButtons = {}
    local raceIdx = 1
    
    for rowNum = 1, numRows do
        local raceRow = HGroup:New("RPE_Setup_RaceRow_" .. rowNum, {
            parent = bodyGroup, spacingX = 8, alignH = "CENTER", alignV = "TOP",
            autoSize = true, width = WIN_W,
        })
        bodyGroup:Add(raceRow)
        
        for colNum = 1, racesPerRow do
            if raceIdx <= #racesToUse then
                local raceData = racesToUse[raceIdx]
                local raceId = raceData.id
                
                local btn = IconBtn:New("RPE_Setup_Race_" .. raceId, {
                    parent = raceRow, 
                    icon = raceData.icon,
                    width = 40, 
                    height = 40,
                    tooltip = raceData.name,
                })
                raceRow:Add(btn)
                raceButtons[raceId] = btn
                
                raceIdx = raceIdx + 1
            end
        end
    end
    
    -- Function to update visual state of all race buttons
    local function updateRaceButtonStates()
        for raceId, btn in pairs(raceButtons) do
            if raceId == window.selectedRace then
                -- Selected: fully saturated
                btn:SetColor(1, 1, 1, 1)
            else
                -- Not selected: desaturated
                btn:SetColor(0.5, 0.5, 0.5, 1)
            end
        end
    end
    
    -- Set up click handlers for all race buttons
    for raceId, btn in pairs(raceButtons) do
        btn:SetOnClick(function()
            window.selectedRace = raceId
            window.selectedRaceTraits = {}
            updateRaceButtonStates()
            updateTraitList()
            -- Recalculate window height for new trait count
            local totalTraits = 0
            local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
            if AuraRegistry and window.selectedRace and AuraRegistry.defs then
                local raceTag = "race:" .. window.selectedRace
                for auraId, auraDef in pairs(AuraRegistry.defs) do
                    if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                        for _, tag in ipairs(auraDef.tags) do
                            if tag == raceTag then
                                totalTraits = totalTraits + 1
                                break
                            end
                        end
                    end
                end
            end
            window:UpdateWindowHeight(totalTraits)
        end)
    end
    
    -- Trait display area
    local traitContainer = VGroup:New("RPE_Setup_RaceTraitContainer", {
        parent = bodyGroup, spacingY = 6, alignH = "CENTER", alignV = "TOP",
        autoSize = true, width = WIN_W - 20,
    })
    bodyGroup:Add(traitContainer)
    
    local traitLabel = Text:New("RPE_Setup_RaceTraitLabel", {
        parent = traitContainer, text = " ",
        fontSize = 12, marginB = 6,
    })
    traitContainer:Add(traitLabel)
    
    -- Trait list area (up to 3 columns)
    local traitListGroup = HGroup:New("RPE_Setup_RaceTraitList", {
        parent = traitContainer, spacingX = 12, alignH = "CENTER", alignV = "TOP",
        autoSize = true, width = WIN_W - 20,
    })
    traitContainer:Add(traitListGroup)
    
    -- Helper function to update trait list display
    local columns = nil
    local noTraitsText = nil
    function updateTraitList()
        -- If columns don't exist, create them
        if not columns then
            columns = {
                VGroup:New("RPE_Setup_TraitCol1", {
                    parent = traitListGroup, spacingY = 4, alignH = "LEFT", alignV = "TOP",
                    autoSize = true,
                }),
                VGroup:New("RPE_Setup_TraitCol2", {
                    parent = traitListGroup, spacingY = 4, alignH = "LEFT", alignV = "TOP",
                    autoSize = true,
                }),
                VGroup:New("RPE_Setup_TraitCol3", {
                    parent = traitListGroup, spacingY = 4, alignH = "LEFT", alignV = "TOP",
                    autoSize = true,
                }),
            }
            for i, col in ipairs(columns) do
                traitListGroup:Add(col)
            end
        end
        
        -- Clear previous trait entries from columns
        for _, col in ipairs(columns) do
            if col.children then
                for i = #col.children, 1, -1 do
                    local ch = col.children[i]
                    if ch and ch.frame and ch.frame.SetParent then ch.frame:SetParent(nil) end
                    if ch and ch.Hide then ch:Hide() end
                    col.children[i] = nil
                end
            end
        end
        
        -- Hide "no traits" message if it exists
        if noTraitsText and noTraitsText.frame then
            noTraitsText:Hide()
        end
        
        if not window.selectedRace then
            return
        end
        
        -- Get AuraRegistry to find traits with the race tag
        local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
        if not AuraRegistry then
            return
        end
        
        -- Find all traits with the race tag
        local raceTag = "race:" .. window.selectedRace
        local traits = {}
        
        -- Get all auras and filter by tag
        if AuraRegistry.defs then
            for auraId, auraDef in pairs(AuraRegistry.defs) do
                -- Check if this aura is a trait and has the race tag
                if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                    local hasRaceTag = false
                    for _, tag in ipairs(auraDef.tags) do
                        if tag == raceTag then
                            hasRaceTag = true
                            break
                        end
                    end
                    if hasRaceTag then
                        table.insert(traits, {id = auraId, name = auraDef.name or auraId})
                    end
                end
            end
        end
        
        if #traits == 0 then
            -- Create the "no traits" message once if it doesn't exist
            if not noTraitsText or not noTraitsText.frame or not noTraitsText.frame:GetParent() then
                noTraitsText = Text:New("RPE_Setup_RaceTraitNone", {
                    parent = traitListGroup, text = "No racial traits available.",
                    fontSize = 10,
                })
                traitListGroup:Add(noTraitsText)
            else
                noTraitsText:Show()
            end
            return
        end
        
        -- Create 3-column layout for traits
        local TraitEntry = RPE_UI.Prefabs.TraitEntry
        
        -- Track trait entries for updating selection state
        local traitEntries = {}
        
        -- Distribute traits across columns
        for idx, trait in ipairs(traits) do
            local colIdx = ((idx - 1) % 3) + 1
            local col = columns[colIdx]
            local traitId = trait.id
            
            -- Create a trait entry
            local isSelected = window.selectedRaceTraits[traitId] or false
            
            -- Get the aura definition to get the icon
            local icon = nil
            local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
            if AuraRegistry then
                local auraDef = AuraRegistry:Get(traitId)
                if auraDef and auraDef.icon then
                    icon = auraDef.icon
                end
            end
            
            local traitEntry = TraitEntry:New("RPE_Setup_Trait_" .. traitId, {
                parent = col,
                auraId = traitId,
                label = trait.name,
                icon = icon,
                width = 150,
                height = 24,
                onClick = function()
                    if window.selectedRaceTraits[traitId] then
                        window.selectedRaceTraits[traitId] = nil
                    else
                        -- Check if we're at the max
                        local count = 0
                        for _ in pairs(window.selectedRaceTraits) do count = count + 1 end
                        
                        if maxRaceTraits > 0 and count >= maxRaceTraits then
                            return
                        end
                        
                        window.selectedRaceTraits[traitId] = true
                    end
                    
                    -- Update display
                    updateTraitList()
                end,
            })
            col:Add(traitEntry)
            traitEntries[traitId] = traitEntry
            
            -- Set initial selected state
            traitEntry:SetSelected(isSelected)
        end
    end
    
    -- Create Select All button (outside updateTraitList so it doesn't duplicate)
    local selectAllBtn = TextBtn:New("RPE_Setup_SelectAllTraits", {
        parent = traitContainer, text = "Select All", width = 100, height = BUTTON_HEIGHT,
        marginT = 6,
        onClick = function()
            window.selectedRaceTraits = {}
            -- Get the current traits list
            local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
            if AuraRegistry and window.selectedRace then
                local raceTag = "race:" .. window.selectedRace
                local traits = {}
                if AuraRegistry.defs then
                    for auraId, auraDef in pairs(AuraRegistry.defs) do
                        if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                            local hasRaceTag = false
                            for _, tag in ipairs(auraDef.tags) do
                                if tag == raceTag then
                                    hasRaceTag = true
                                    break
                                end
                            end
                            if hasRaceTag then
                                table.insert(traits, {id = auraId, name = auraDef.name or auraId})
                            end
                        end
                    end
                end
                local count = 0
                for idx, trait in ipairs(traits) do
                    if maxRaceTraits <= 0 or count < maxRaceTraits then
                        window.selectedRaceTraits[trait.id] = true
                        count = count + 1
                    end
                end
            end
            updateTraitList()
        end,
    })
    traitContainer:Add(selectAllBtn)
    
    -- Initial render
    updateTraitList()
    
    -- Set initial window height
    local totalTraits = 0
    if AuraRegistry and window.selectedRace and AuraRegistry.defs then
        local raceTag = "race:" .. window.selectedRace
        for auraId, auraDef in pairs(AuraRegistry.defs) do
            if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                for _, tag in ipairs(auraDef.tags) do
                    if tag == raceTag then
                        totalTraits = totalTraits + 1
                        break
                    end
                end
            end
        end
    end
    self:UpdateWindowHeight(totalTraits)
end

function SetupWindow:RenderSelectClass(headerGroup, bodyGroup, page)
    local maxClassTraits = RPE.ActiveRules:Get("max_class_traits", 0)
    local window = self
    
    -- Title in header
    local titleText = Text:New("RPE_Setup_SelectClass_Title", {
        parent = headerGroup, text = page.title or "Select a Class",
        fontTemplate = "GameFontNormalLarge"
    })
    headerGroup:Add(titleText)
    
    -- Instructions in header
    local instrText = Text:New("RPE_Setup_SelectClass_Instructions", {
        parent = headerGroup, 
        text = "Select a class and up to " .. tostring(maxClassTraits) .. " class traits",
    })
    headerGroup:Add(instrText)
    
    -- Track selected class and traits
    if not self.selectedClass then
        self.selectedClass = nil
    end
    if not self.selectedClassTraits then
        self.selectedClassTraits = {}
    end
    
    -- Build class list from CLASSES plus any custom classes from page
    local classesToUse = {}
    for _, class in ipairs(CLASSES) do
        table.insert(classesToUse, class)
    end
    
    -- Add custom classes from the current page if available
    -- Custom classes are stored at the page level, not wizard level
    if page.customClasses and #page.customClasses > 0 then
        for _, class in ipairs(page.customClasses) do
            table.insert(classesToUse, class)
        end
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupWindow] Loaded " .. tostring(#page.customClasses) .. " custom classes from page") end
        for i, class in ipairs(page.customClasses) do
            if DBG then DBG:Internal("[SetupWindow]   Class " .. i .. ": id=" .. tostring(class.id) .. ", name=" .. tostring(class.name) .. ", icon=" .. tostring(class.icon)) end
        end
    else
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupWindow] No custom classes in current page") end
    end
    
    -- Get IconButton class
    local IconBtn = RPE_UI.Elements.IconButton
    
    -- Calculate number of rows needed (5 columns per row)
    local classesPerRow = 5
    local numRows = math.ceil(#classesToUse / classesPerRow)
    local DBG = _G.RPE and _G.RPE.Debug
    if DBG then DBG:Internal("[SetupWindow] Total classes: " .. tostring(#classesToUse) .. ", rows needed: " .. tostring(numRows)) end
    
    -- Create dynamic rows based on class count
    local classButtons = {}
    local classIdx = 1
    
    for rowNum = 1, numRows do
        local classRow = HGroup:New("RPE_Setup_ClassRow_" .. rowNum, {
            parent = bodyGroup, spacingX = 8, alignH = "CENTER", alignV = "TOP",
            autoSize = true, width = WIN_W - 20,
        })
        bodyGroup:Add(classRow)
        
        for colNum = 1, classesPerRow do
            if classIdx <= #classesToUse then
                local classData = classesToUse[classIdx]
                local classId = classData.id
                
                local btn = IconBtn:New("RPE_Setup_Class_" .. classId, {
                    parent = classRow, 
                    icon = classData.icon,
                    width = 40, 
                    height = 40,
                    tooltip = classData.name,
                })
                classRow:Add(btn)
                classButtons[classId] = btn
                
                classIdx = classIdx + 1
            end
        end
    end
    
    -- Function to update visual state of all class buttons
    local function updateClassButtonStates()
        for classId, btn in pairs(classButtons) do
            if classId == window.selectedClass then
                -- Selected: fully saturated
                btn:SetColor(1, 1, 1, 1)
            else
                -- Not selected: desaturated
                btn:SetColor(0.5, 0.5, 0.5, 1)
            end
        end
    end
    
    -- Set up click handlers for all class buttons
    for classId, btn in pairs(classButtons) do
        btn:SetOnClick(function()
            window.selectedClass = classId
            window.selectedClassTraits = {}
            updateClassButtonStates()
            updateClassTraitList()
            -- Recalculate window height for new trait count
            local totalTraits = 0
            local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
            if AuraRegistry and window.selectedClass and AuraRegistry.defs then
                local classTag = "class:" .. window.selectedClass
                for auraId, auraDef in pairs(AuraRegistry.defs) do
                    if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                        for _, tag in ipairs(auraDef.tags) do
                            if tag == classTag then
                                totalTraits = totalTraits + 1
                                break
                            end
                        end
                    end
                end
            end
            window:UpdateWindowHeight(totalTraits)
        end)
    end
    
    -- Trait display area
    local classTraitContainer = VGroup:New("RPE_Setup_ClassTraitContainer", {
        parent = bodyGroup, spacingY = 0, alignH = "CENTER", alignV = "TOP",
        autoSize = true, width = WIN_W - 20,
    })
    bodyGroup:Add(classTraitContainer)
    
    local classTraitLabel = Text:New("RPE_Setup_ClassTraitLabel", {
        parent = classTraitContainer, text = " ",
        fontSize = 12, marginB = 6,
    })
    classTraitContainer:Add(classTraitLabel)
    
    -- Trait list area (up to 3 columns)
    local classTraitListGroup = HGroup:New("RPE_Setup_ClassTraitList", {
        parent = classTraitContainer, spacingX = 12, alignH = "CENTER", alignV = "TOP",
        autoSize = true, width = WIN_W - 20,
    })
    classTraitContainer:Add(classTraitListGroup)
    
    -- Helper function to update class trait list display
    function updateClassTraitList()
        -- Clear previous trait displays
        if classTraitListGroup.children then
            for i = #classTraitListGroup.children, 1, -1 do
                local ch = classTraitListGroup.children[i]
                if ch and ch.frame and ch.frame.SetParent then ch.frame:SetParent(nil) end
                if ch and ch.Hide then ch:Hide() end
                classTraitListGroup.children[i] = nil
            end
        end
        
        if not window.selectedClass then
            return
        end
        
        -- Get AuraRegistry to find traits with the class tag
        local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
        if not AuraRegistry then
            return
        end
        
        -- Find all traits with the class tag
        local classTag = "class:" .. window.selectedClass
        local traits = {}
        
        -- Get all auras and filter by tag
        if AuraRegistry.defs then
            for auraId, auraDef in pairs(AuraRegistry.defs) do
                -- Check if this aura is a trait and has the class tag
                if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                    local hasClassTag = false
                    for _, tag in ipairs(auraDef.tags) do
                        if tag == classTag then
                            hasClassTag = true
                            break
                        end
                    end
                    if hasClassTag then
                        table.insert(traits, {id = auraId, name = auraDef.name or auraId})
                    end
                end
            end
        end
        
        if #traits == 0 then
            local noTraitsText = Text:New("RPE_Setup_ClassTraitNone", {
                parent = classTraitListGroup, text = "No class traits available.",
                fontSize = 10,
            })
            classTraitListGroup:Add(noTraitsText)
            return
        end
        
        -- Calculate rows needed (3 columns per row, 24px height per trait)
        local traitRowCount = math.ceil(#traits / 3)
        
        -- Create 3-column layout for traits
        local columns = {
            VGroup:New("RPE_Setup_ClassTraitCol1", {
                parent = classTraitListGroup, spacingY = 4, alignH = "LEFT", alignV = "TOP",
                autoSize = true,
            }),
            VGroup:New("RPE_Setup_ClassTraitCol2", {
                parent = classTraitListGroup, spacingY = 4, alignH = "LEFT", alignV = "TOP",
                autoSize = true,
            }),
            VGroup:New("RPE_Setup_ClassTraitCol3", {
                parent = classTraitListGroup, spacingY = 4, alignH = "LEFT", alignV = "TOP",
                autoSize = true,
            }),
        }
        
        for i, col in ipairs(columns) do
            classTraitListGroup:Add(col)
        end
        
        -- Get TraitEntry class
        local TraitEntry = RPE_UI.Prefabs.TraitEntry
        
        -- Track trait entries for updating selection state
        local classTraitEntries = {}
        
        -- Distribute traits across columns
        for idx, trait in ipairs(traits) do
            local colIdx = ((idx - 1) % 3) + 1
            local col = columns[colIdx]
            local traitId = trait.id
            
            -- Create a trait entry
            local isSelected = window.selectedClassTraits[traitId] or false
            
            -- Get the aura definition to get the icon
            local icon = nil
            local AuraRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
            if AuraRegistry then
                local auraDef = AuraRegistry:Get(traitId)
                if auraDef and auraDef.icon then
                    icon = auraDef.icon
                end
            end
            
            local traitEntry = TraitEntry:New("RPE_Setup_ClassTrait_" .. traitId, {
                parent = col,
                auraId = traitId,
                label = trait.name,
                icon = icon,
                width = 150,
                height = 24,
                onClick = function()
                    if window.selectedClassTraits[traitId] then
                        window.selectedClassTraits[traitId] = nil
                    else
                        -- Check if we're at the max
                        local count = 0
                        for _ in pairs(window.selectedClassTraits) do count = count + 1 end
                        
                        if maxClassTraits > 0 and count >= maxClassTraits then
                            return
                        end
                        
                        window.selectedClassTraits[traitId] = true
                    end
                    
                    -- Update display
                    updateClassTraitList()
                end,
            })
            col:Add(traitEntry)
            classTraitEntries[traitId] = traitEntry
            
            -- Set initial selected state
            traitEntry:SetSelected(isSelected)
        end
    end
    
    -- Initial render
    updateClassTraitList()
    
    -- Set initial window height
    local totalTraits = 0
    if AuraRegistry and window.selectedClass and AuraRegistry.defs then
        local classTag = "class:" .. window.selectedClass
        for auraId, auraDef in pairs(AuraRegistry.defs) do
            if auraDef and auraDef.isTrait and auraDef.tags and type(auraDef.tags) == "table" then
                for _, tag in ipairs(auraDef.tags) do
                    if tag == classTag then
                        totalTraits = totalTraits + 1
                        break
                    end
                end
            end
        end
    end
    self:UpdateWindowHeight(totalTraits)
end

function SetupWindow:RenderSelectLanguage(headerGroup, bodyGroup, page)
    local window = self
    
    -- Title in header
    local titleText = Text:New("RPE_Setup_SelectLanguage_Title", {
        parent = headerGroup, text = page.title or "Select Languages",
        fontTemplate = "GameFontNormalLarge"
    })
    headerGroup:Add(titleText)
    
    -- Instructions in header
    local instrText = Text:New("RPE_Setup_SelectLanguage_Instructions", {
        parent = headerGroup, 
        text = "Select languages and set your proficiency level for each.\nYou will always know Common or Orcish.",
    })
    headerGroup:Add(instrText)
    
    -- Get Language system
    local Language = _G.RPE and _G.RPE.Core and _G.RPE.Core.Language
    local LanguageTable = _G.RPE and _G.RPE.Core and _G.RPE.Core.LanguageTable
    if not Language or not LanguageTable then
        local errorText = Text:New("RPE_Setup_SelectLanguage_Error", {
            parent = bodyGroup, text = "Language system not available",
        })
        bodyGroup:Add(errorText)
        return
    end
    
    -- Build languages list from page data
    local languagesToUse = {}
    if page.languages and #page.languages > 0 then
        for _, lang in ipairs(page.languages) do
            table.insert(languagesToUse, lang)
        end
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupWindow] Loaded " .. tostring(#page.languages) .. " languages from page") end
        for i, lang in ipairs(page.languages) do
            if DBG then DBG:Internal("[SetupWindow]   Language " .. i .. ": name=" .. tostring(lang.name) .. ", skill=" .. tostring(lang.skill)) end
        end
    else
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupWindow] No languages in current page") end
    end
    
    -- Create a table UI to allow editing languages
    local languageContainer = VGroup:New("RPE_Setup_LanguageContainer", {
        parent = bodyGroup, spacingY = 8, alignH = "CENTER", alignV = "TOP",
        autoSize = false, width = WIN_W - 20,
    })
    bodyGroup:Add(languageContainer)
    
    -- Display current languages as entries
    if #languagesToUse > 0 then
        local LanguageEntry = RPE_UI.Prefabs and RPE_UI.Prefabs.LanguageEntry
        if LanguageEntry then
            for _, langData in ipairs(languagesToUse) do
                -- Wrap each language entry in an HGroup for proper centering
                local entryRow = HGroup:New("RPE_Setup_LangRow_" .. langData.name, {
                    parent = languageContainer, spacingX = 8, alignH = "CENTER", alignV = "CENTER",
                    autoSize = true,
                })
                languageContainer:Add(entryRow)
                
                local entry = LanguageEntry:New("RPE_Setup_Lang_" .. langData.name, {
                    parent = entryRow,
                    width = 300,
                    height = 24,
                    icon = "Interface\\Icons\\INV_Misc_Book_09",
                    languageName = langData.name,
                    skillLevel = langData.skill or 0,
                    onRemove = function()
                        -- Remove language from page.languages
                        if page.languages then
                            for idx, lang in ipairs(page.languages) do
                                if lang.name == langData.name then
                                    table.remove(page.languages, idx)
                                    break
                                end
                            end
                        end
                        -- Refresh the page to show updated list
                        window:ShowPage(window.currentPageIdx)
                    end,
                })
                entryRow:Add(entry)
            end
        end
    else
        local noLangText = Text:New("RPE_Setup_NoLanguages", {
            parent = languageContainer, text = "Click to add a language",
        })
        languageContainer:Add(noLangText)
    end
    
    -- Add button to learn new language
    local addLanguageBtn = TextBtn:New("RPE_Setup_AddLanguage", {
        parent = languageContainer, text = "+ Add Language", width = 120, height = 26,
        onClick = function()
            -- Show dialog to add new language
            window:ShowAddLanguageDialog(page)
        end,
    })
    languageContainer:Add(addLanguageBtn)
end

function SetupWindow:ShowAddLanguageDialog(page)
    local LanguageTable = _G.RPE and _G.RPE.Core and _G.RPE.Core.LanguageTable
    if not LanguageTable then return end
    
    local allLanguages = LanguageTable.GetLanguages() or {}
    if #allLanguages == 0 then return end
    
    local Popup = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    local HGroup = RPE_UI.Elements and RPE_UI.Elements.HorizontalLayoutGroup
    local Text = RPE_UI.Elements and RPE_UI.Elements.Text
    local Dropdown = RPE_UI.Elements and RPE_UI.Elements.Dropdown
    
    if not (Popup and HGroup and Text and Dropdown) then
        return
    end
    
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
    
    local isImmersion = RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = isImmersion and WorldFrame or UIParent
    
    local p = Popup.New({
        title = "Add Language",
        text = "Select a language and proficiency level:",
        width = 400,
        parentFrame = parentFrame,
        clickOffToClose = true,
    })
    
    -- Set popup to be above the setup window
    if p and p.root and p.root.frame then
        p.root.frame:SetFrameStrata("TOOLTIP")
        p.root.frame:SetToplevel(true)
    end
    
    -- Language selector row
    local langRow = HGroup:New("RPE_AddLang_LangRow", {
        parent = p.mid,
        autoSize = true,
        spacingX = 10,
        alignV = "CENTER",
    })
    
    local langLabel = Text:New("RPE_AddLang_LangLabel", {
        parent = langRow,
        text = "Language:",
        width = 80,
    })
    langRow:Add(langLabel)
    
    local langDropdown = Dropdown:New("RPE_AddLang_LangDropdown", {
        parent = langRow,
        width = 280,
        choices = allLanguages,
        value = allLanguages[1],
    })
    langRow:Add(langDropdown)
    p.mid:Add(langRow)
    
    -- Proficiency selector row
    local profRow = HGroup:New("RPE_AddLang_ProfRow", {
        parent = p.mid,
        autoSize = true,
        spacingX = 10,
        alignV = "CENTER",
    })
    
    local profLabel = Text:New("RPE_AddLang_ProfLabel", {
        parent = profRow,
        text = "Proficiency:",
        width = 80,
    })
    profRow:Add(profLabel)
    
    local profDropdown = Dropdown:New("RPE_AddLang_ProfDropdown", {
        parent = profRow,
        width = 280,
        choices = proficiencyLevels,
        value = proficiencyLevels[3],
    })
    profRow:Add(profDropdown)
    p.mid:Add(profRow)
    
    -- Recalculate layout
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
            local selectedLang = langDropdown:GetValue()
            local profIndex = 3  -- Default to "Intermediate"
            
            -- Find which proficiency level was selected
            for idx, level in ipairs(proficiencyLevels) do
                if profDropdown:GetValue() == level then
                    profIndex = idx
                    break
                end
            end
            
            local skill = proficiencyValues[profIndex] or 150
            
            -- Check if language already exists
            local exists = false
            if page.languages then
                for _, lang in ipairs(page.languages) do
                    if lang.name == selectedLang then
                        lang.skill = skill
                        exists = true
                        break
                    end
                end
            end
            
            -- Add new language if doesn't exist
            if not exists then
                if not page.languages then page.languages = {} end
                table.insert(page.languages, { name = selectedLang, skill = skill })
            end
            
            -- Refresh the page display
            self:ShowPage(self.currentPageIdx)
        end,
        function() end  -- Cancel callback
    )
    
    p:SetButtons("Add", "Cancel")
    p:Show()
end

-- Helper: Extract race from spell tags (handles "race:orc" and direct race names)
local function extractRaceFromTags(tags)
    if not tags then return nil end
    for _, tag in ipairs(tags) do
        -- Format: "race:orc" or "race:human" etc.
        if tag:match("^race:") then
            return tag:sub(6):lower()
        end
        -- Format: Direct race name like "Human", "Orc", etc.
        if tag:match("^(Dwarf|Gnome|Human|Orc|Tauren|Troll|BloodElf|Draenei|Pandaren|Nightborne|HighmountainTauren|VoidElf|Mechagnome|Worgen|Dracthyr|LightForged|Zandalari|KulTiran|DarkIron|Vulpera|MagharOrc)$") then
            return tag:lower()
        end
    end
    return nil
end

-- Helper: Check if spell is a racial ability
local function isRacialSpell(tags)
    if not tags then return false end
    for _, tag in ipairs(tags) do
        if tag == "Racial" or extractRaceFromTags({tag}) then
            return true
        end
    end
    return false
end

-- Helper: Normalize race names for comparison
local function normalizeRaceName(raceName)
    if not raceName then return nil end
    local normalized = raceName:lower()
    -- Handle common misspellings/variants
    local raceMap = {
        ["bloodelf"] = "bloodelf",
        ["draenei"] = "draenei",
        ["darkiron"] = "darkiron",
        ["dracthyr"] = "dracthyr",
        ["highmountaintauren"] = "highmountaintauren",
        ["kultiran"] = "kultiran",
        ["lightforged"] = "lightforged",
        ["magharorc"] = "magharorc",
        ["mechagnome"] = "mechagnome",
        ["nightborne"] = "nightborne",
        ["voidelf"] = "voidelf",
        ["zandalari"] = "zandalari",
    }
    return raceMap[normalized] or normalized
end

function SetupWindow:RenderSelectSpells(headerGroup, bodyGroup, page)
    local window = self
    
    -- Read spell configuration from page (read-only, never modify page object)
    local allowRacial = page.allowRacial ~= false
    local restrictToClass = page.restrictToClass or false
    local restrictToRace = page.restrictToRace or false
    local firstRankOnly = page.firstRankOnly or false
    
    -- Initialize spell selections on first render (not on re-renders during same session)
    -- Store in local runtime state, NOT in the page object from the dataset
    if not self._spellSelectedSpells then
        self._spellSelectedSpells = {}
    end
    
    -- Header text
    local titleText = Text:New("RPE_Setup_SelectSpells_Title", {
        parent=headerGroup, text="Select Spells", fontTemplate="GameFontNormalLarge"
    })
    headerGroup:Add(titleText)
    
    -- Instructions in header
    local instrText = Text:New("RPE_Setup_SelectSpells_Instructions", {
        parent=headerGroup,
        text="Left-click to add spells. Right-click to remove.\nHold shift to increase and decrease ranks.",
        fontTemplate="GameFontNormalSmall"
    })
    headerGroup:Add(instrText)
    
    -- Get spell data from active registry
    local SpellRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
    local Spell = _G.RPE and _G.RPE.Core and _G.RPE.Core.Spell
    local Common = _G.RPE and _G.RPE.Common
    local UICommon = _G.RPE_UI and _G.RPE_UI.Common
    local spellsList = {}
    local spellObjects = {}  -- Keep references to original spell objects for tooltips
    
    if SpellRegistry and type(SpellRegistry.All) == "function" then
        local allSpells = SpellRegistry:All()
        if allSpells then
            for spellId, spell in pairs(allSpells) do
                if spell and spell.name then
                    table.insert(spellsList, {
                        id = spellId,
                        name = spell.name,
                        icon = spell.icon or 134400,
                        maxRanks = spell.maxRanks or 1,
                        tags = spell.tags or {},
                    })
                    spellObjects[spellId] = spell  -- Store original spell object
                end
            end
        end
    end
    
    -- Sort spells by name
    table.sort(spellsList, function(a, b)
        local an = tostring(a.name or ""):lower()
        local bn = tostring(b.name or ""):lower()
        if an ~= bn then return an < bn end
        return tostring(a.id) < tostring(b.id)
    end)
    
    -- Built-in class/spec tags (same as SpellbookSheet)
    local BUILTIN_CLASS_TAGS = {
        { class = "Warrior",  color = {1.00, 0.78, 0.55}, specs = {"Arms", "Fury", "Protection"} },
        { class = "Paladin",  color = {0.96, 0.55, 0.73}, specs = {"Holy", "Protection", "Retribution"} },
        { class = "Hunter",   color = {0.67, 0.83, 0.45}, specs = {"Beast Mastery", "Marksmanship", "Survival"} },
        { class = "Rogue",    color = {1.00, 0.96, 0.41}, specs = {"Assassination", "Combat", "Subtlety"} },
        { class = "Priest",   color = {1.00, 1.00, 1.00}, specs = {"Discipline", "Holy", "Shadow"} },
        { class = "Death Knight", color = {0.77, 0.12, 0.23}, specs = {"Blood", "Frost", "Unholy"} },
        { class = "Shaman",   color = {0.00, 0.44, 0.87}, specs = {"Elemental", "Enhancement", "Restoration"} },
        { class = "Mage",     color = {0.25, 0.78, 0.92}, specs = {"Arcane", "Fire", "Frost"} },
        { class = "Warlock",  color = {0.53, 0.53, 0.93}, specs = {"Affliction", "Demonology", "Destruction"} },
        { class = "Monk",     color = {0.00, 1.00, 0.59}, specs = {"Brewmaster", "Mistweaver", "Windwalker"} },
        { class = "Druid",    color = {1.00, 0.49, 0.04}, specs = {"Balance", "Feral", "Guardian", "Restoration"} },
        { class = "Demon Hunter", color = {0.64, 0.19, 0.79}, specs = {"Havoc", "Vengeance", "Devourer"} },
        { class = "Evoker",  color = {0.33, 0.75, 0.93}, specs = {"Devastation", "Preservation", "Augmentation"} },
    }
    
    -- Collect all unique tags from spells (normalized to lowercase)
    local allTags = {}
    for _, spellData in ipairs(spellsList) do
        if spellData.tags then
            for _, tag in ipairs(spellData.tags) do
                allTags[tag:lower()] = true
            end
        end
    end
    
    -- Separate extra tags (not in built-in class/spec list) - case insensitive
    local extraTags = {}
    local builtinTagsLower = {}
    for _, classDef in ipairs(BUILTIN_CLASS_TAGS) do
        builtinTagsLower[classDef.class:lower()] = true
        for _, spec in ipairs(classDef.specs) do
            builtinTagsLower[spec:lower()] = true
        end
    end
    
    for tag in pairs(allTags) do
        if not builtinTagsLower[tag] then
            table.insert(extraTags, tag)
        end
    end
    table.sort(extraTags)
    
    -- Initialize active filters
    if not self._spellActiveFilters then
        self._spellActiveFilters = {}
    end
    
    -- Main container with proper alignment (like SELECT_LANGUAGE)
    local mainContainer = VGroup:New((bodyGroup.frame:GetName() or "RPE_Spells").."_MainContainer", {
        parent=bodyGroup, spacingY=8, alignH="CENTER", alignV="CENTER",
        autoSize=false, width=(WIN_W or 800) - 40
    })
    bodyGroup:Add(mainContainer)
    
    -- Calculate remaining spell points (before creating UI so we can display it)
    -- Treat nil or 0 as unlimited (math.huge)
    local maxSpellPoints = tonumber(page.maxSpellPoints or 0) or 0
    if maxSpellPoints <= 0 then
        maxSpellPoints = math.huge
    end
    local spentPoints = 0
    for spellId, rank in pairs(self._spellSelectedSpells) do
        spentPoints = spentPoints + (rank or 1)
    end
    local remainingPoints = (maxSpellPoints == math.huge) and math.huge or (maxSpellPoints - spentPoints)
    
    -- Spell points display at top (only if there's a limit)
    if maxSpellPoints ~= math.huge then
        local pointsText = Text:New((mainContainer.frame:GetName() or "RPE_Spells").."_PointsDisplay", {
            parent=mainContainer,
            text=("Points Spent: %d / %d"):format(spentPoints, maxSpellPoints),
            fontTemplate="GameFontNormalSmall"
        })
        mainContainer:Add(pointsText)
    end
    
    -- Filter bar below spell points
    local filterBar = HGroup:New((mainContainer.frame:GetName() or "RPE_Spells").."_FilterBar", {
        parent=mainContainer, spacingX=8, alignH="CENTER", alignV="CENTER", autoSize=true
    })
    mainContainer:Add(filterBar)
    
    -- Filter button for tags
    local filterBtn = TextBtn:New((filterBar.frame:GetName() or "RPE_Spells").."_FilterBtn", {
        parent=filterBar, width=200, height=24, text="Filter: All Tags"
    })
    filterBar:Add(filterBtn)
    
    -- Helper to update filter button label
    local function updateFilterButtonLabel()
        local count = 0
        for _, enabled in pairs(self._spellActiveFilters) do
            if enabled then count = count + 1 end
        end
        if count == 0 then
            filterBtn:SetText("Filter: All Tags")
        else
            filterBtn:SetText(("Filter: %d selected"):format(count))
        end
    end
    
    filterBtn:SetOnClick(function()
        UICommon:ContextMenu(filterBtn.frame, function(level, menuList)
            if level == 1 then
                UIDropDownMenu_AddButton({
                    text = "All Tags",
                    isNotRadio = true,
                    checked = (next(self._spellActiveFilters) == nil),
                    func = function()
                        self._spellActiveFilters = {}
                        updateFilterButtonLabel()
                        window:ShowPage(window.currentPageIdx)
                        CloseDropDownMenus()
                    end,
                }, level)
                
                UIDropDownMenu_AddSeparator(level)
                
                -- Class submenu
                local anyClassActive = false
                for _, classDef in ipairs(BUILTIN_CLASS_TAGS) do
                    for _, spec in ipairs(classDef.specs) do
                        if self._spellActiveFilters[spec:lower()] then
                            anyClassActive = true
                            break
                        end
                    end
                    if anyClassActive then break end
                end
                
                UIDropDownMenu_AddButton({
                    text = "Class",
                    hasArrow = true,
                    notCheckable = false,
                    checked = anyClassActive,
                    keepShownOnClick = true,
                    menuList = "class_submenu",
                }, level)
                
                -- Race submenu
                local anyRaceActive = false
                for tag in pairs(self._spellActiveFilters) do
                    if tag == "racial" or (self._spellActiveFilters[tag] and extractRaceFromTags({tag})) then
                        anyRaceActive = true
                        break
                    end
                end
                
                UIDropDownMenu_AddButton({
                    text = "Race",
                    hasArrow = true,
                    notCheckable = false,
                    checked = anyRaceActive,
                    keepShownOnClick = true,
                    menuList = "race_submenu",
                }, level)
                
                UIDropDownMenu_AddSeparator(level)
                
                -- Spell type filters
                UIDropDownMenu_AddButton({
                    text = "melee",
                    isNotRadio = true,
                    keepShownOnClick = true,
                    checked = self._spellActiveFilters["melee"] == true,
                    func = function()
                        self._spellActiveFilters["melee"] = not self._spellActiveFilters["melee"]
                        updateFilterButtonLabel()
                        window:ShowPage(window.currentPageIdx)
                    end,
                }, level)
                
                UIDropDownMenu_AddButton({
                    text = "ranged",
                    isNotRadio = true,
                    keepShownOnClick = true,
                    checked = self._spellActiveFilters["ranged"] == true,
                    func = function()
                        self._spellActiveFilters["ranged"] = not self._spellActiveFilters["ranged"]
                        updateFilterButtonLabel()
                        window:ShowPage(window.currentPageIdx)
                    end,
                }, level)
                
                UIDropDownMenu_AddButton({
                    text = "spell",
                    isNotRadio = true,
                    keepShownOnClick = true,
                    checked = self._spellActiveFilters["spell"] == true,
                    func = function()
                        self._spellActiveFilters["spell"] = not self._spellActiveFilters["spell"]
                        updateFilterButtonLabel()
                        window:ShowPage(window.currentPageIdx)
                    end,
                }, level)
            elseif level == 2 and menuList == "class_submenu" then
                -- Class/spec submenu
                for _, classDef in ipairs(BUILTIN_CLASS_TAGS) do
                    local cr, cg, cb = unpack(classDef.color)
                    local classKeyLower = classDef.class:lower()
                    local allOn = true
                    for _, spec in ipairs(classDef.specs) do
                        if not self._spellActiveFilters[spec:lower()] then allOn = false break end
                    end
                    
                    UIDropDownMenu_AddButton({
                        text = classDef.class,
                        textR = cr, textG = cg, textB = cb,
                        hasArrow = true,
                        notCheckable = false,
                        checked = allOn,
                        keepShownOnClick = true,
                        menuList = classKeyLower,
                        func = function()
                            local anyActive = false
                            for _, spec in ipairs(classDef.specs) do
                                if self._spellActiveFilters[spec:lower()] then anyActive = true break end
                            end
                            if self._spellActiveFilters[classKeyLower] then anyActive = true end
                            
                            local newState = not anyActive
                            for _, spec in ipairs(classDef.specs) do
                                self._spellActiveFilters[spec:lower()] = newState
                            end
                            if allTags[classKeyLower] then
                                self._spellActiveFilters[classKeyLower] = newState
                            end
                            updateFilterButtonLabel()
                            window:ShowPage(window.currentPageIdx)
                        end,
                    }, level)
                end
            elseif level == 2 and menuList == "race_submenu" then
                -- Race submenu
                UIDropDownMenu_AddButton({
                    text = "Racial",
                    isNotRadio = true,
                    keepShownOnClick = true,
                    checked = self._spellActiveFilters["racial"] == true,
                    func = function()
                        self._spellActiveFilters["racial"] = not self._spellActiveFilters["racial"]
                        updateFilterButtonLabel()
                        window:ShowPage(window.currentPageIdx)
                    end,
                }, level)
                
                UIDropDownMenu_AddSeparator(level)
                
                -- Individual race filters from extraTags
                for _, tag in ipairs(extraTags) do
                    if tag:match("^race:") or extractRaceFromTags({tag}) then
                        UIDropDownMenu_AddButton({
                            text = tag,
                            isNotRadio = true,
                            keepShownOnClick = true,
                            checked = self._spellActiveFilters[tag] == true,
                            func = function()
                                self._spellActiveFilters[tag] = not self._spellActiveFilters[tag]
                                updateFilterButtonLabel()
                                window:ShowPage(window.currentPageIdx)
                            end,
                        }, level)
                    end
                end
            elseif level == 3 and menuList then
                -- Handle class submenu for specs
                for _, classDef in ipairs(BUILTIN_CLASS_TAGS) do
                    if menuList == classDef.class:lower() then
                        local cr, cg, cb = unpack(classDef.color)
                        for _, spec in ipairs(classDef.specs) do
                            local specKeyLower = spec:lower()
                            UIDropDownMenu_AddButton({
                                text = spec,
                                textR = cr, textG = cg, textB = cb,
                                isNotRadio = true,
                                keepShownOnClick = true,
                                checked = self._spellActiveFilters[specKeyLower] == true,
                                func = function()
                                    self._spellActiveFilters[specKeyLower] = not self._spellActiveFilters[specKeyLower]
                                    updateFilterButtonLabel()
                                    window:ShowPage(window.currentPageIdx)
                                end,
                            }, level)
                        end
                        break
                    end
                end
            end
        end)
    end)
    
    -- Filter spells based on active filters
    local filteredSpellsList = {}
    if next(self._spellActiveFilters) == nil then
        -- No filters, show all
        filteredSpellsList = spellsList
    else
        -- Only show spells with matching tags (case-insensitive)
        for _, spellData in ipairs(spellsList) do
            local hasMatchingTag = false
            if spellData.tags then
                for _, tag in ipairs(spellData.tags) do
                    if self._spellActiveFilters[tag:lower()] then
                        hasMatchingTag = true
                        break
                    end
                end
            end
            if hasMatchingTag then
                table.insert(filteredSpellsList, spellData)
            end
        end
    end
    
    -- Pagination settings: 2 rows x 10 columns = 20 spells per page
    local spellsPerPage = 20
    local spellsPerRow = 10
    local totalPages = math.max(1, math.ceil(#filteredSpellsList / spellsPerPage))
    if not self._spellPageIdx then self._spellPageIdx = 1 end
    
    -- Ensure current page is valid
    if self._spellPageIdx > totalPages then
        self._spellPageIdx = totalPages
    end
    
    -- Create centered container for spell grid
    local gridContainer = VGroup:New((mainContainer.frame:GetName() or "RPE_Spells").."_GridContainer", {
        parent=mainContainer, spacingY=8, alignH="CENTER", alignV="CENTER", autoSize=true
    })
    mainContainer:Add(gridContainer)
    
    -- Helper function to check if a spell can be added
    local function canAddSpell(spellId)
        -- Already added
        if self._spellSelectedSpells[spellId] then
            return false
        end
        
        -- Check spell points
        local spentPoints = 0
        for id, rank in pairs(self._spellSelectedSpells) do
            spentPoints = spentPoints + (rank or 1)
        end
        local checkMaxPoints = maxSpellPoints
        if checkMaxPoints ~= math.huge and spentPoints >= checkMaxPoints then
            return false
        end
        
        -- Check max spells total
        local totalSelected = 0
        for _ in pairs(self._spellSelectedSpells) do
            totalSelected = totalSelected + 1
        end
        local maxSpellsTotal = tonumber(page.maxSpellsTotal or 0) or 0
        if maxSpellsTotal <= 0 then
            maxSpellsTotal = math.huge
        end
        if maxSpellsTotal ~= math.huge and totalSelected >= maxSpellsTotal then
            return false
        end
        
        -- Check class restriction (if enabled)
        if restrictToClass then
            local spellObj = spellObjects[spellId]
            if spellObj and spellObj.tags then
                -- Check if this is a racial spell - if so, allow it regardless of class
                local isRacial = false
                for _, tag in ipairs(spellObj.tags) do
                    if tag == "Racial" or tag:match("^(Dwarf|Gnome|Human|Orc|Tauren|Troll|BloodElf|Draenei|Pandaren|Nightborne|HighmountainTauren|VoidElf|Mechagnome|Worgen|Dracthyr|LightForged|Zandalari|KulTiran|DarkIron|Vulpera|MagharOrc)$") then
                        isRacial = true
                        break
                    end
                end
                
                -- If not racial, check class restriction
                if not isRacial then
                    local playerClass = window.selectedClass
                    if playerClass then
                        playerClass = playerClass:lower()
                        local hasClass = false
                        for _, tag in ipairs(spellObj.tags) do
                            if tag:lower() == playerClass then
                                hasClass = true
                                break
                            end
                        end
                        if not hasClass then
                            return false
                        end
                    end
                end
            end
        end
        
        -- Check race restriction for racial spells (if enabled)
        if restrictToRace then
            local spellObj = spellObjects[spellId]
            if spellObj and spellObj.tags and isRacialSpell(spellObj.tags) then
                local spellRace = extractRaceFromTags(spellObj.tags)
                local playerRace = window.selectedRace and normalizeRaceName(window.selectedRace)
                local normalizedSpellRace = spellRace and normalizeRaceName(spellRace)
                
                if spellRace and playerRace and normalizedSpellRace ~= playerRace then
                    return false
                end
            end
        end
        
        -- Check racial restriction (if racial spells not allowed)
        if not allowRacial then
            local spellObj = spellObjects[spellId]
            if spellObj and spellObj.tags and isRacialSpell(spellObj.tags) then
                return false
            end
        end
        
        return true
    end
    
    -- Build spell grid
    local currentPage = self._spellPageIdx
    local startIdx = (currentPage - 1) * spellsPerPage + 1
    
    local IconBtn = RPE_UI.Elements.IconButton
    local spellButtons = {}
    local spellIdx = startIdx
    
    -- Create rows and spell buttons (2 rows x 10 columns)
    for rowNum = 1, 2 do
        local rowGroup = HGroup:New((gridContainer.frame:GetName() or "RPE_Spells").."_Row" .. rowNum, {
            parent=gridContainer, spacingX=4, alignH="CENTER", alignV="CENTER", autoSize=true
        })
        gridContainer:Add(rowGroup)
        
        for colNum = 1, spellsPerRow do
            local spell = filteredSpellsList[spellIdx]
            if spell then
                local spellObj = spellObjects[spell.id]
                local spellBtn = IconBtn:New(
                    (rowGroup.frame:GetName() or "RPE_Spell").."_" .. spell.id,
                    {
                        width = 40, height = 40,
                        icon = spell.icon,
                        hasBackground = true,
                        noBorder = false,
                    }
                )
                rowGroup:Add(spellBtn)
                spellButtons[spell.id] = {btn = spellBtn, data = spell, obj = spellObj}
                
                -- Check if spell can be added and lock if not
                local canAdd = canAddSpell(spell.id)
                if not canAdd then
                    spellBtn:Lock()
                end
                
                -- Setup tooltip from Spell.lua using Common.lua ShowTooltip
                if spellBtn.frame then
                    spellBtn.frame:SetScript("OnEnter", function()
                        if spellObj and type(spellObj.GetTooltip) == "function" then
                            local rank = self._spellSelectedSpells[spell.id] or 1
                            local tooltipSpec = spellObj:GetTooltip(rank)
                            if tooltipSpec and Common and Common.ShowTooltip then
                                Common:ShowTooltip(spellBtn.frame, tooltipSpec)
                            end
                        end
                    end)
                    spellBtn.frame:SetScript("OnLeave", function()
                        if Common and Common.HideTooltip then
                            Common:HideTooltip()
                        else
                            GameTooltip:Hide()
                        end
                    end)
                    
                    -- Click handlers
                    spellBtn.frame:HookScript("OnMouseDown", function(_, button)
                        if button == "LeftButton" then
                            if IsShiftKeyDown() then
                                -- Shift-click: learn higher rank
                                if firstRankOnly then return end
                                
                                local currentRank = self._spellSelectedSpells[spell.id] or 1
                                local nextRank = currentRank + 1
                                
                                if nextRank <= spell.maxRanks then
                                    self._spellSelectedSpells[spell.id] = nextRank
                                    window:ShowPage(window.currentPageIdx)
                                end
                            else
                                -- Normal click: add spell at rank 1
                                if not self._spellSelectedSpells[spell.id] then
                                    if canAddSpell(spell.id) then
                                        self._spellSelectedSpells[spell.id] = 1
                                        window:ShowPage(window.currentPageIdx)
                                    end
                                end
                            end
                        elseif button == "RightButton" then
                            -- Right-click: remove spell
                            if self._spellSelectedSpells[spell.id] then
                                self._spellSelectedSpells[spell.id] = nil
                                window:ShowPage(window.currentPageIdx)
                            end
                        end
                    end)
                end
                
                spellIdx = spellIdx + 1
            end
        end
    end
    
    -- Pagination controls - placed directly under grid
    local pageNavGroup = HGroup:New((gridContainer.frame:GetName() or "RPE_Spells").."_PageNav", {
        parent=gridContainer, spacingX=10, alignH="CENTER", alignV="CENTER", autoSize=true
    })
    gridContainer:Add(pageNavGroup)
    
    local prevPageBtn = TextBtn:New((pageNavGroup.frame:GetName() or "RPE_Spells").."_PrevPage", {
        parent=pageNavGroup, width=70, height=22, text="Prev",
        onClick=function()
            self._spellPageIdx = math.max(1, (self._spellPageIdx or 1) - 1)
            window:ShowPage(window.currentPageIdx)
        end
    })
    pageNavGroup:Add(prevPageBtn)
    
    local pageNumText = Text:New((pageNavGroup.frame:GetName() or "RPE_Spells").."_PageNum", {
        parent=pageNavGroup, text = ("Page %d / %d"):format(currentPage, totalPages),
        fontTemplate="GameFontNormalSmall"
    })
    pageNavGroup:Add(pageNumText)
    
    local nextPageBtn = TextBtn:New((pageNavGroup.frame:GetName() or "RPE_Spells").."_NextPage", {
        parent=pageNavGroup, width=70, height=22, text="Next",
        onClick=function()
            self._spellPageIdx = math.min(totalPages, (self._spellPageIdx or 1) + 1)
            window:ShowPage(window.currentPageIdx)
        end
    })
    pageNavGroup:Add(nextPageBtn)
    
    -- Selected spells display
    if next(self._spellSelectedSpells) then
        local selectedGroup = VGroup:New((mainContainer.frame:GetName() or "RPE_Spells").."_Selected", {
            parent=mainContainer, spacingY=4, alignH="CENTER", alignV="TOP", autoSize=true
        })
        mainContainer:Add(selectedGroup)
        
        local selectedRow = HGroup:New((selectedGroup.frame:GetName() or "RPE_Spells").."_SelectedRow", {
            parent=selectedGroup, spacingX=4, alignH="CENTER", alignV="CENTER", autoSize=true
        })
        selectedGroup:Add(selectedRow)
        
        -- Display selected spells as buttons with rank indicator
        for spellId, rank in pairs(self._spellSelectedSpells) do
            local spell = nil
            for _, s in ipairs(spellsList) do
                if s.id == spellId then
                    spell = s
                    break
                end
            end
            
            if spell then
                local spellObj = spellObjects[spellId]
                local rankLabel = rank > 1 and " [Rank " .. rank .. "]" or ""
                local selectedBtn = IconBtn:New(
                    (selectedRow.frame:GetName() or "RPE_SpellSel").."_" .. spellId,
                    {
                        width = 40, height = 40,
                        icon = spell.icon,
                        hasBackground = true,
                        noBorder = false,
                    }
                )
                selectedRow:Add(selectedBtn)
                
                -- Tooltip for selected spell
                if selectedBtn.frame then
                    selectedBtn.frame:SetScript("OnEnter", function()
                        if spellObj and type(spellObj.GetTooltip) == "function" then
                            local tooltipSpec = spellObj:GetTooltip(rank)
                            if tooltipSpec and Common and Common.ShowTooltip then
                                Common:ShowTooltip(selectedBtn.frame, tooltipSpec)
                            end
                        end
                    end)
                    selectedBtn.frame:SetScript("OnLeave", function()
                        if Common and Common.HideTooltip then
                            Common:HideTooltip()
                        else
                            GameTooltip:Hide()
                        end
                    end)
                    
                    -- Right-click to remove from selected spells
                    selectedBtn.frame:HookScript("OnMouseDown", function(_, button)
                        if button == "RightButton" then
                            self._spellSelectedSpells[spellId] = nil
                            window:ShowPage(window.currentPageIdx)
                        elseif button == "LeftButton" and IsShiftKeyDown() then
                            -- Shift-click: bump rank
                            if not firstRankOnly and rank < spell.maxRanks then
                                self._spellSelectedSpells[spellId] = rank + 1
                                window:ShowPage(window.currentPageIdx)
                            end
                        end
                    end)
                end
            end
        end
    end
end

function SetupWindow:RenderSelectItems(headerGroup, bodyGroup, page)
    local window = self
    local Common = _G.RPE and _G.RPE.Common
    local ItemRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.ItemRegistry
    
    -- NOTE: spareChange support
    -- If page.spareChange is true, calculate leftover copper after item selection
    -- and store in self._pageSpareChange[currentPageIdx] for use in Finish()
    -- Example: if allowance is 1000 and items cost 700, store 300 in _pageSpareChange
    local IconButton = _G.RPE_UI and _G.RPE_UI.Elements and _G.RPE_UI.Elements.IconButton
    local DBG = _G.RPE and _G.RPE.Debug
    
    -- Title in header
    local titleText = Text:New("RPE_Setup_SelectItems_Title", {
        parent=headerGroup, text=(page.title or "Select Items"), fontTemplate="GameFontNormalLarge"
    })
    headerGroup:Add(titleText)
    
    -- Instructions in header
    local instrText = Text:New("RPE_Setup_SelectItems_Instructions", {
        parent=headerGroup, text="Left-click to add items. Right-click to remove.\n(Item allowance is based on market value in copper)",
        fontTemplate="GameFontNormalSmall"
    })
    headerGroup:Add(instrText)
    
    -- Read page configuration (READ-ONLY)
    local maxAllowance = tonumber(page.maxAllowance or 0) or 0
    if maxAllowance <= 0 then
        maxAllowance = math.huge
    end
    local includeTags = page.includeTags or ""
    local excludeTags = page.excludeTags or ""
    local maxRarity = page.maxRarity or "legendary"
    
    -- Parse tags (comma-separated, case-insensitive, trimmed)
    local function parseTags(tagStr)
        local tags = {}
        if type(tagStr) == "string" and tagStr ~= "" then
            for tag in tagStr:gmatch("[^,]+") do
                tag = tag:match("^%s*(.-)%s*$")  -- trim
                if tag ~= "" then
                    table.insert(tags, tag:lower())
                end
            end
        end
        return tags
    end
    
    local includeTagsList = parseTags(includeTags)
    local excludeTagsList = parseTags(excludeTags)
    
    -- Rarity ranking for max rarity filter
    local rarityRank = { common=1, uncommon=2, rare=3, epic=4, legendary=5 }
    local maxRarityRank = rarityRank[maxRarity] or 5
    
    -- Initialize window state if needed
    if not self._pageItemSelections then
        self._pageItemSelections = {}
    end
    if not self._pageAllowances then
        self._pageAllowances = {}
    end
    if not self._pageItemSelections[self.currentPageIdx] then
        self._pageItemSelections[self.currentPageIdx] = {}
    end
    if not self._itemActiveFilters then
        self._itemActiveFilters = {}
    end
    if not self._itemPageIdx then
        self._itemPageIdx = 1
    end
    
    -- Get all items from registry
    if not ItemRegistry then
        if DBG then DBG:Error("ItemRegistry not available for SELECT_ITEMS") end
        return
    end
    
    local allItems = ItemRegistry:All() or {}
    
    -- Get items selected for this specific page
    local pageItems = self._pageItemSelections[self.currentPageIdx] or {}
    
    -- Calculate spent allowance in copper (sum of item prices for this page only)
    local spentAllowanceCopper = 0
    for _, slot in ipairs(pageItems) do
        local itemObj = allItems[slot.id]
        if itemObj and type(itemObj.GetPrice) == "function" then
            local price = itemObj:GetPrice() * slot.qty
            spentAllowanceCopper = spentAllowanceCopper + price
        end
    end
    
    -- Convert maxAllowance from base units to copper (1 unit = 4 copper)
    local maxAllowanceCopper = maxAllowance  -- maxAllowance is already in copper
    
    -- Filter items based on tags, rarity, category, and dropdown filters
    local filteredItems = {}
    for itemId, itemObj in pairs(allItems) do
        if itemObj then
            -- Check rarity
            local itemRarityRank = rarityRank[itemObj.rarity] or 1
            if itemRarityRank <= maxRarityRank then
                -- Check include tags (if specified, item must have at least one)
                local passIncludeFilter = true
                if #includeTagsList > 0 then
                    local hasIncludeTag = false
                    for _, tag in ipairs(itemObj.tags or {}) do
                        if hasIncludeTag then break end
                        for _, includeTag in ipairs(includeTagsList) do
                            if tag:lower() == includeTag then
                                hasIncludeTag = true
                                break
                            end
                        end
                    end
                    passIncludeFilter = hasIncludeTag
                end
                
                -- Check exclude tags (if item has any, skip it)
                local passExcludeFilter = true
                if #excludeTagsList > 0 then
                    local hasExcludeTag = false
                    for _, tag in ipairs(itemObj.tags or {}) do
                        if hasExcludeTag then break end
                        for _, excludeTag in ipairs(excludeTagsList) do
                            if tag:lower() == excludeTag then
                                hasExcludeTag = true
                                break
                            end
                        end
                    end
                    passExcludeFilter = not hasExcludeTag
                end
                
                -- Filter dropdowns will be added after main container is created
                -- Store filtered items for now and re-filter after dropdowns exist
                if passIncludeFilter and passExcludeFilter then
                    table.insert(filteredItems, { id=itemId, obj=itemObj })
                end
            end
        end
    end
    
    -- Sort by name for consistent display
    table.sort(filteredItems, function(a, b)
        return (a.obj.name or a.id):lower() < (b.obj.name or b.id):lower()
    end)
    
    -- Main container with proper alignment (centered, like SELECT_SPELLS)
    local mainContainer = VGroup:New((bodyGroup.frame:GetName() or "RPE_Items").."_MainContainer", {
        parent=bodyGroup, spacingY=8, alignH="CENTER", alignV="TOP",
        autoSize=false, width=(WIN_W or 800) - 40
    })
    bodyGroup:Add(mainContainer)
    
    -- Initialize per-page category filter state
    if not self._itemCategoryFilter then
        self._itemCategoryFilter = {}  -- Per-page filters, nil means "All"
    end
    if not self._itemCategoryFilter[self.currentPageIdx] then
        self._itemCategoryFilter[self.currentPageIdx] = nil  -- nil means "All"
    end
    
    -- Create filter controls group
    local filterGroup = HGroup:New((mainContainer.frame:GetName() or "RPE_Items").."_FilterGroup", {
        parent=mainContainer, spacingX=10, alignH="CENTER", alignV="CENTER", autoSize=true
    })
    mainContainer:Add(filterGroup)
    
    -- Category filter dropdown - restrict choices based on page configuration
    local allCategoryChoices = { "All", "CONSUMABLE", "EQUIPMENT", "MATERIAL", "QUEST", "MISC" }
    local categoryChoices = allCategoryChoices
    local allowedCategoriesSet = {}
    
    -- Parse allowed categories from page configuration
    if page.allowedCategory and page.allowedCategory ~= "" then
        for cat in page.allowedCategory:gmatch("[^,]+") do
            local trimmed = cat:match("^%s*(.-)%s*$")
            allowedCategoriesSet[trimmed] = true
        end
        -- If specific categories are allowed, restrict dropdown to those and pre-filter items
        if next(allowedCategoriesSet) then
            categoryChoices = {}
            table.insert(categoryChoices, "All")
            for _, cat in ipairs({"CONSUMABLE", "EQUIPMENT", "MATERIAL", "QUEST", "MISC"}) do
                if allowedCategoriesSet[cat] then
                    table.insert(categoryChoices, cat)
                end
            end
            
            -- Pre-filter items to only include allowed categories
            local allowedItems = {}
            for _, item in ipairs(filteredItems) do
                if allowedCategoriesSet[item.obj.category] then
                    table.insert(allowedItems, item)
                end
            end
            filteredItems = allowedItems
        end
    end
    
    local categoryDisplayValue = (self._itemCategoryFilter[self.currentPageIdx] and self._itemCategoryFilter[self.currentPageIdx] or "All")
    
    local categoryDropdown = Dropdown:New((filterGroup.frame:GetName() or "RPE_Items").."_CategoryFilter", {
        parent=filterGroup, width=150, choices=categoryChoices,
        value=categoryDisplayValue,
        onChanged=function(dropdown, newValue)
            if newValue == "All" then
                self._itemCategoryFilter[self.currentPageIdx] = nil
            else
                self._itemCategoryFilter[self.currentPageIdx] = newValue
            end
            window:ShowPage(window.currentPageIdx)
        end
    })
    filterGroup:Add(categoryDropdown)
    
    -- Helper function to apply category filter to items
    local function applyCategoryFilter(baseItems)
        local pageFilter = self._itemCategoryFilter[self.currentPageIdx]
        if not pageFilter then
            return baseItems  -- "All" selected, return unfiltered
        end
        
        local result = {}
        for _, item in ipairs(baseItems) do
            if item.obj.category == pageFilter then
                table.insert(result, item)
            end
        end
        return result
    end
    
    -- Apply category filter to the base filtered items
    filteredItems = applyCategoryFilter(filteredItems)
    
    -- Allowance display (only if there's a limit)
    if maxAllowanceCopper ~= math.huge then
        local allowanceText = Text:New((mainContainer.frame:GetName() or "RPE_Items").."_AllowanceDisplay", {
            parent=mainContainer,
            text=("Allowance: %s / %s"):format(
                Common and Common.FormatCopper and Common:FormatCopper(spentAllowanceCopper) or tostring(spentAllowanceCopper),
                Common and Common.FormatCopper and Common:FormatCopper(maxAllowanceCopper) or tostring(maxAllowanceCopper)
            ),
            fontTemplate="GameFontNormalSmall"
        })
        mainContainer:Add(allowanceText)
    end
    
    -- Pagination state
    local itemsPerPage = 30  -- 3 rows × 10 columns
    local totalPages = math.max(1, math.ceil(#filteredItems / itemsPerPage))
    local currentPage = math.max(1, math.min(self._itemPageIdx or 1, totalPages))
    
    -- Helper: check if item can be added
    local function canAddItem(itemId)
        -- Check allowance
        if maxAllowanceCopper ~= math.huge then
            local itemObj = allItems[itemId]
            if itemObj and type(itemObj.GetPrice) == "function" then
                local itemPrice = itemObj:GetPrice()
                if spentAllowanceCopper + itemPrice > maxAllowanceCopper then
                    return false
                end
            end
        end
        
        return true
    end
    
    -- Create centered container for item grid
    local gridContainer = VGroup:New((mainContainer.frame:GetName() or "RPE_Items").."_GridContainer", {
        parent=mainContainer, spacingY=8, alignH="CENTER", alignV="CENTER", autoSize=true
    })
    mainContainer:Add(gridContainer)
    
    -- Render grid (3 rows, 10 columns = 30 items per page)
    local itemIdx = 1 + ((currentPage - 1) * itemsPerPage)
    local itemsToShow = math.min(itemsPerPage, #filteredItems - ((currentPage - 1) * itemsPerPage))
    
    for row = 1, 3 do
        if itemIdx > #filteredItems then break end
        
        local rowGroup = HGroup:New((gridContainer.frame:GetName() or "RPE_Items").."_Row_"..row, {
            parent=gridContainer, spacingX=4, alignH="CENTER", alignV="TOP", autoSize=true
        })
        gridContainer:Add(rowGroup)
        
        for col = 1, 10 do
            if itemIdx > #filteredItems then break end
            
            local item = filteredItems[itemIdx]
            local itemId = item.id
            local itemObj = item.obj
            local isSelected = false
            for _, slot in ipairs(pageItems) do
                if slot.id == itemId then
                    isSelected = true
                    break
                end
            end
            local canAdd = canAddItem(itemId)
            
            local itemBtn = IconButton:New((rowGroup.frame:GetName() or "RPE_Items").."_Item_"..itemIdx, {
                parent=rowGroup, width=36, height=36, icon=itemObj.icon,
                enabled = not isSelected,
                isLocked = isSelected or not canAdd,
                onClick=function()
                    if not canAdd then return end
                    
                    -- Left-click: add a new stack (always start with qty=1)
                    table.insert(pageItems, { id = itemId, qty = 1 })
                    local itemPrice = itemObj:GetPrice()
                    spentAllowanceCopper = spentAllowanceCopper + itemPrice
                    window:ShowPage(window.currentPageIdx)
                end
            })
            rowGroup:Add(itemBtn)
            
            -- Setup tooltip from Item.lua ShowTooltip method
            if itemBtn.frame then
                itemBtn.frame:SetScript("OnEnter", function()
                    if itemObj and type(itemObj.ShowTooltip) == "function" then
                        local tooltipSpec = itemObj:ShowTooltip()
                        if tooltipSpec and Common and Common.ShowTooltip then
                            Common:ShowTooltip(itemBtn.frame, tooltipSpec)
                        end
                    else
                        -- Fallback: show item name and rarity
                        if Common and Common.ShowTooltip then
                            Common:ShowTooltip(itemBtn.frame, {
                                title = Common:ColorByQuality(itemObj.name or itemId, itemObj.rarity),
                                lines = {
                                    { text=itemObj.description or "" }
                                }
                            })
                        end
                    end
                end)
                itemBtn.frame:SetScript("OnLeave", function()
                    if Common and Common.HideTooltip then
                        Common:HideTooltip()
                    else
                        GameTooltip:Hide()
                    end
                end)
                
                -- Click handler for removal
                itemBtn.frame:HookScript("OnMouseDown", function(_, button)
                    if button == "RightButton" then
                        -- Right-click: remove the last stack of this item from page
                        for i = #pageItems, 1, -1 do
                            if pageItems[i].id == itemId then
                                local qty = pageItems[i].qty
                                local itemPrice = itemObj:GetPrice()
                                spentAllowanceCopper = math.max(0, spentAllowanceCopper - (itemPrice * qty))
                                table.remove(pageItems, i)
                                window:ShowPage(window.currentPageIdx)
                                break
                            end
                        end
                    end
                end)
            end
            
            itemIdx = itemIdx + 1
        end
    end
    
    -- Pagination controls
    local pageNavGroup = HGroup:New((gridContainer.frame:GetName() or "RPE_Items").."_PageNav", {
        parent=gridContainer, spacingX=10, alignH="CENTER", alignV="CENTER", autoSize=true
    })
    gridContainer:Add(pageNavGroup)
    
    local prevPageBtn = TextBtn:New((pageNavGroup.frame:GetName() or "RPE_Items").."_PrevPage", {
        parent=pageNavGroup, width=70, height=22, text="Prev",
        onClick=function()
            self._itemPageIdx = math.max(1, (self._itemPageIdx or 1) - 1)
            window:ShowPage(window.currentPageIdx)
        end
    })
    pageNavGroup:Add(prevPageBtn)
    
    local pageNumText = Text:New((pageNavGroup.frame:GetName() or "RPE_Items").."_PageNum", {
        parent=pageNavGroup, text = ("Page %d / %d"):format(currentPage, totalPages),
    })
    pageNavGroup:Add(pageNumText)
    
    local nextPageBtn = TextBtn:New((pageNavGroup.frame:GetName() or "RPE_Items").."_NextPage", {
        parent=pageNavGroup, width=70, height=22, text="Next",
        onClick=function()
            self._itemPageIdx = math.min(totalPages, (self._itemPageIdx or 1) + 1)
            window:ShowPage(window.currentPageIdx)
        end
    })
    pageNavGroup:Add(nextPageBtn)
    
    -- Selected items display section below grid
    local selectedContainer = VGroup:New((mainContainer.frame:GetName() or "RPE_Items").."_SelectedContainer", {
        parent=mainContainer, spacingY=6, alignH="CENTER", alignV="TOP", autoSize=true
    })
    mainContainer:Add(selectedContainer)
    
    local selectedLabel = Text:New((selectedContainer.frame:GetName() or "RPE_Items").."_SelectedLabel", {
        parent=selectedContainer, text="Selected Items:", fontTemplate="GameFontNormalSmall"
    })
    selectedContainer:Add(selectedLabel)
    
    -- Display selected items in a grid (5 columns)
    -- Group by itemId and calculate total qty per item
    local selectedItemsMap = {}
    for _, slot in ipairs(pageItems) do
        if not selectedItemsMap[slot.id] then
            selectedItemsMap[slot.id] = { id = slot.id, totalQty = 0 }
        end
        selectedItemsMap[slot.id].totalQty = selectedItemsMap[slot.id].totalQty + slot.qty
    end
    
    local selectedItems = {}
    for _, item in pairs(selectedItemsMap) do
        table.insert(selectedItems, item)
    end
    table.sort(selectedItems, function(a, b)
        local aName = (allItems[a.id] and allItems[a.id].name or a.id):lower()
        local bName = (allItems[b.id] and allItems[b.id].name or b.id):lower()
        return aName < bName
    end)
    
    if #selectedItems > 0 then
        local itemsPerRow = 5
        local numRows = math.ceil(#selectedItems / itemsPerRow)
        local selectedIdx = 1
        
        for row = 1, numRows do
            local selectedRowGroup = HGroup:New((selectedContainer.frame:GetName() or "RPE_Items").."_SelectedRow_"..row, {
                parent=selectedContainer, spacingX=8, alignH="CENTER", alignV="TOP", autoSize=true
            })
            selectedContainer:Add(selectedRowGroup)
            
            for col = 1, itemsPerRow do
                if selectedIdx <= #selectedItems then
                    local itemData = selectedItems[selectedIdx]
                    local itemId = itemData.id
                    local totalQty = itemData.totalQty
                    local itemObj = allItems[itemId]
                    
                    if itemObj then
                        
                        local selectedItemBtn = IconButton:New((selectedRowGroup.frame:GetName() or "RPE_Items").."_SelectedItem_"..selectedIdx, {
                            parent=selectedRowGroup, width=36, height=36, icon=itemObj.icon,
                            enabled=true,
                            isLocked=false,
                            onClick=function()
                                -- Right-click would remove, but left-click on selected shows it's selected
                                -- For now, just show tooltip
                            end
                        })
                        selectedRowGroup:Add(selectedItemBtn)
                        
                        -- Add quantity label if more than 1
                        if totalQty > 1 and selectedItemBtn.frame then
                            local qtyLabel = selectedItemBtn.frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalYellow")
                            qtyLabel:SetPoint("BOTTOMRIGHT", selectedItemBtn.frame, "BOTTOMRIGHT", -2, 2)
                            qtyLabel:SetText(tostring(totalQty))
                        end
                        
                        -- Setup tooltip for selected item (show quantity and price info)
                        if selectedItemBtn.frame then
                            selectedItemBtn.frame:SetScript("OnEnter", function()
                                if itemObj and type(itemObj.ShowTooltip) == "function" then
                                    local tooltipSpec = itemObj:ShowTooltip()
                                    if tooltipSpec and Common and Common.ShowTooltip then
                                        Common:ShowTooltip(selectedItemBtn.frame, tooltipSpec)
                                    end
                                end
                            end)
                            selectedItemBtn.frame:SetScript("OnLeave", function()
                                if Common and Common.HideTooltip then
                                    Common:HideTooltip()
                                else
                                    GameTooltip:Hide()
                                end
                            end)
                            
                            -- Right-click to remove all stacks of this item
                            selectedItemBtn.frame:HookScript("OnMouseDown", function(_, button)
                                if button == "RightButton" then
                                    local itemPrice = itemObj:GetPrice()
                                    local totalRemoved = 0
                                    -- Remove all stacks of this item
                                    for i = #pageItems, 1, -1 do
                                        if pageItems[i].id == itemId then
                                            totalRemoved = totalRemoved + pageItems[i].qty
                                            table.remove(pageItems, i)
                                        end
                                    end
                                    spentAllowanceCopper = math.max(0, spentAllowanceCopper - (itemPrice * totalRemoved))
                                    window:ShowPage(window.currentPageIdx)
                                end
                            end)
                        end
                    end
                    
                    selectedIdx = selectedIdx + 1
                end
            end
        end
    else
        local noneText = Text:New((selectedContainer.frame:GetName() or "RPE_Items").."_SelectedNone", {
            parent=selectedContainer, text="(None selected)", fontTemplate="GameFontNormalSmall"
        })
        selectedContainer:Add(noneText)
    end
    
    -- Calculate and store spare change if enabled for this page
    if page.spareChange and maxAllowanceCopper ~= math.huge then
        local spareCopper = math.max(0, maxAllowanceCopper - spentAllowanceCopper)
        self._pageSpareChange[self.currentPageIdx] = spareCopper
        if DBG then DBG:Internal("SetupWindow: Calculated spare change for page " .. self.currentPageIdx .. ": " .. spareCopper .. " copper") end
    end
end

function SetupWindow:RenderSelectProfessions(headerGroup, bodyGroup, page)
    local window = self
    local pageIdx = self.currentPageIdx
    local maxLevel = page.maxLevel or 1
    local maxProfs = _G.RPE and _G.RPE.ActiveRules and _G.RPE.ActiveRules:Get("max_professions") or nil
    local profPointsAllowance = page.professionPointsAllowance or 0  -- 0 = unlimited
    
    -- Store these for access in _UpdateProfessionsDisplay
    self._profsMaxLevel = maxLevel
    self._profsProfPointsAllowance = profPointsAllowance
    
    -- Title in header
    local titleText = Text:New("RPE_Setup_SelectProfs_Title", {
        parent = headerGroup, text = "Select Professions", fontTemplate = "GameFontNormalLarge"
    })
    headerGroup:Add(titleText)
    
    -- Instructions in header
    local instrText = Text:New("RPE_Setup_SelectProfs_Instructions", {
        parent = headerGroup, text = "Left-click to select. Shift+LMB/RMB to change level.",
        fontTemplate = "GameFontNormalSmall"
    })
    headerGroup:Add(instrText)
    
    -- Initialize state for this page if needed
    if not self._pageSelectedProfessions[pageIdx] then
        self._pageSelectedProfessions[pageIdx] = {}
    end
    if not self._pageProfessionLevels[pageIdx] then
        self._pageProfessionLevels[pageIdx] = {}
    end
    
    local selectedProfs = self._pageSelectedProfessions[pageIdx]
    local profLevels = self._pageProfessionLevels[pageIdx]
    
    -- Get profession icons and list from Common.lua
    local Common = _G.RPE and _G.RPE.Common or {}
    local PROF_ICONS = Common.ProfessionIcons or {}
    local allProfs = Common.ProfessionList or {
        "Cooking", "Fishing", "First Aid",
        "Alchemy", "Blacksmithing", "Enchanting", "Engineering",
        "Leatherworking", "Tailoring", "Inscription", "Jewelcrafting", "Mining", "Skinning", "Herbalism",
    }
    
    -- Filter out Cooking, Fishing, and First Aid (only show primary crafting professions)
    local ALL_PROFS = {}
    for _, prof in ipairs(allProfs) do
        if prof ~= "Cooking" and prof ~= "Fishing" and prof ~= "First Aid" then
            table.insert(ALL_PROFS, prof)
        end
    end
    
    -- Main container - centered like SELECT_SPELLS and SELECT_ITEMS
    local mainContainer = VGroup:New("RPE_Setup_SelectProfs_MainContainer", {
        parent = bodyGroup, spacingY = 12, alignH = "CENTER", alignV = "CENTER",
        autoSize = false, width = (WIN_W or 600) - 40
    })
    bodyGroup:Add(mainContainer)
    
    -- Professions chosen counter (only show if there's a max_professions rule) - BEFORE grid
    if maxProfs then
        local counterText = Text:New("RPE_Setup_SelectProfs_Counter", {
            parent = mainContainer, text = "Professions Chosen: " .. #selectedProfs .. " / " .. maxProfs,
            fontTemplate = "GameFontNormalSmall"
        })
        mainContainer:Add(counterText)
        self._profsCounterText = counterText
    end
    
    -- Profession points display (only show if there's a limit)
    if profPointsAllowance > 0 then
        local pointsText = Text:New("RPE_Setup_SelectProfs_PointsDisplay", {
            parent = mainContainer, text = "Points Used: 0 / " .. profPointsAllowance,
            fontTemplate = "GameFontNormalSmall"
        })
        mainContainer:Add(pointsText)
        self._profsPointsText = pointsText
    end
    
    -- Grid of profession icons (5 columns, 2 rows for 9 professions)
    local gridGroup = VGroup:New("RPE_Setup_SelectProfs_GridGroup", {
        parent = mainContainer, spacingX = 0, spacingY = 8, alignV = "TOP", alignH = "CENTER",
        autoSize = true
    })
    mainContainer:Add(gridGroup)
    
    local IconBtn = RPE_UI.Elements.IconButton
    local Text = RPE_UI.Elements.Text
    local profButtons = {}
    local profsPerRow = 6
    local currentRow = nil
    
    for i, profName in ipairs(ALL_PROFS) do
        -- Create new row every 5 professions
        if (i - 1) % profsPerRow == 0 then
            currentRow = HGroup:New("RPE_Setup_SelectProfs_Row_" .. math.ceil(i / profsPerRow), {
                parent = gridGroup, spacingX = 8, alignV = "CENTER", autoSize = true
            })
            gridGroup:Add(currentRow)
        end
        
        local icon = PROF_ICONS[profName] or "Interface\\Icons\\INV_Misc_QuestionMark"
        local btn = IconBtn:New("RPE_Setup_SelectProfs_" .. profName, {
            parent = currentRow, width = 32, height = 32, icon = icon,
            hasBorder = false, noBorder = true,
            hasBackground = false, noBackground = true,
            onClick = function(_, button)
                if button == "LeftButton" then
                    -- Regular click: toggle selection
                    if profLevels[profName] and profLevels[profName] > 0 then
                        -- Remove profession
                        profLevels[profName] = nil
                        local idx = nil
                        for j, p in ipairs(selectedProfs) do
                            if p == profName then idx = j; break end
                        end
                        if idx then table.remove(selectedProfs, idx) end
                    else
                        -- Add profession if not at max
                        if maxProfs and #selectedProfs >= maxProfs then
                            return  -- Don't add if at max
                        end
                        -- Check points allowance if limit exists (0 = unlimited)
                        if profPointsAllowance > 0 then
                            local currentPoints = 0
                            for _, pName in ipairs(selectedProfs) do
                                currentPoints = currentPoints + (profLevels[pName] or 0)
                            end
                            if currentPoints + maxLevel > profPointsAllowance then
                                return  -- Not enough points to add this profession at maxLevel
                            end
                        end
                        table.insert(selectedProfs, profName)
                        profLevels[profName] = maxLevel
                    end
                    window:_UpdateProfessionsDisplay(pageIdx, mainContainer)
                end
            end
        })
        if currentRow then
            currentRow:Add(btn)
        end
        profButtons[profName] = btn
        
        -- Add tooltip
        if btn.frame then
            btn.frame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(btn.frame, "ANCHOR_RIGHT")
                GameTooltip:SetText(profName, 1, 1, 1, 1, true)
                if profLevels[profName] and profLevels[profName] > 0 then
                    GameTooltip:AddLine("Level: " .. profLevels[profName], 0.5, 0.8, 1)
                end
                GameTooltip:Show()
            end)
            btn.frame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end
    
    -- Selected professions label
    local selectedLabel = Text:New("RPE_Setup_SelectProfs_SelectedLabel", {
        parent = mainContainer, text = "Selected Professions:",
        fontTemplate = "GameFontNormalSmall"
    })
    mainContainer:Add(selectedLabel)
    
    -- Wrapper for selected professions (to ensure centering)
    local selectedProfsContainer = VGroup:New("RPE_Setup_SelectProfs_SelectedContainer", {
        parent = mainContainer, spacingY = 4, alignH = "CENTER", alignV = "TOP", autoSize = true
    })
    mainContainer:Add(selectedProfsContainer)
    
    -- Selected professions display as icon buttons
    local selectedIconGroup = HGroup:New("RPE_Setup_SelectProfs_SelectedIcons", {
        parent = selectedProfsContainer, spacingX = 8, alignV = "CENTER", alignH = "CENTER", autoSize = true
    })
    selectedProfsContainer:Add(selectedIconGroup)
    
    self._selectedProfsIconGroup = selectedIconGroup
    self._mainProfsContainer = mainContainer
    self:_UpdateProfessionsDisplay(pageIdx, mainContainer)
end

function SetupWindow:_UpdateProfessionsDisplay(pageIdx, mainContainer)
    local selectedIconGroup = self._selectedProfsIconGroup
    if not selectedIconGroup then return end
    
    -- Clear old selections
    for i = #selectedIconGroup.children, 1, -1 do
        local ch = selectedIconGroup.children[i]
        if ch and ch.frame then ch.frame:SetParent(nil) end
        if ch and ch.Hide then ch:Hide() end
        selectedIconGroup.children[i] = nil
    end
    
    local selectedProfs = self._pageSelectedProfessions[pageIdx] or {}
    local profLevels = self._pageProfessionLevels[pageIdx] or {}
    
    -- Update counter if it exists
    local counterText = self._profsCounterText
    if counterText then
        local maxProfs = _G.RPE and _G.RPE.ActiveRules and _G.RPE.ActiveRules:Get("max_professions") or nil
        if maxProfs then
            counterText:SetText("Professions Chosen: " .. #selectedProfs .. " / " .. maxProfs)
        end
    end
    
    -- Update points display if it exists
    if self._profsPointsText and self._profsProfPointsAllowance and self._profsProfPointsAllowance > 0 then
        local currentPoints = 0
        for _, profName in ipairs(selectedProfs) do
            currentPoints = currentPoints + (profLevels[profName] or 0)
        end
        local remainingPoints = self._profsProfPointsAllowance - currentPoints
        self._profsPointsText:SetText(string.format("Points Used: %d / %d (Remaining: %d)", currentPoints, self._profsProfPointsAllowance, remainingPoints))
    end
    
    -- Get profession icons from Common.lua
    local Common = _G.RPE and _G.RPE.Common or {}
    local PROF_ICONS = Common.ProfessionIcons or {}
    
    local IconBtn = RPE_UI.Elements.IconButton
    local Text = RPE_UI.Elements.Text
    local window = self
    
    if #selectedProfs == 0 then
        local noneText = Text:New("RPE_Setup_SelectProfs_SelectedNone", {
            parent = selectedIconGroup, text = "(None selected)", fontTemplate = "GameFontNormalSmall"
        })
        selectedIconGroup:Add(noneText)
    else
        for _, profName in ipairs(selectedProfs) do
            local level = profLevels[profName] or 1
            local icon = PROF_ICONS[profName] or "Interface\\Icons\\INV_Misc_QuestionMark"
            
            -- Wrapper VGroup for icon + level text (icon above, level below)
            local profWrapper = VGroup:New("RPE_Setup_SelectProfs_SelWrapper_" .. profName, {
                parent = selectedIconGroup, spacingY = 2, alignH = "CENTER", alignV = "TOP", autoSize = true
            })
            selectedIconGroup:Add(profWrapper)
            
            local selBtn = IconBtn:New("RPE_Setup_SelectProfs_Sel_" .. profName, {
                parent = profWrapper, width = 32, height = 32, icon = icon,
                hasBorder = false, noBorder = true,
                hasBackground = false, noBackground = true,
                onClick = function(_, button)
                    if button == "LeftButton" and IsShiftKeyDown() then
                        -- Shift+LMB: increase level
                        local currentLevel = profLevels[profName] or 0
                        local maxLvl = window._profsMaxLevel or 1
                        local pointsAllowance = window._profsProfPointsAllowance or 0
                        if currentLevel < maxLvl then
                            -- Check points allowance if limit exists (0 = unlimited)
                            if pointsAllowance > 0 then
                                local currentPoints = 0
                                for _, pName in ipairs(selectedProfs) do
                                    currentPoints = currentPoints + (profLevels[pName] or 0)
                                end
                                if currentPoints >= pointsAllowance then
                                    return  -- Out of points
                                end
                            end
                            profLevels[profName] = currentLevel + 1
                            window:_UpdateProfessionsDisplay(pageIdx, mainContainer)
                        end
                    end
                end
            })
            profWrapper:Add(selBtn)
            
            -- Hook RMB directly to frame for mouse down event
            if selBtn.frame then
                selBtn.frame:HookScript("OnMouseDown", function(_, button)
                    if button == "RightButton" and IsShiftKeyDown() then
                        -- Shift+RMB: decrease level or remove
                        if (profLevels[profName] or 0) > 0 then
                            profLevels[profName] = profLevels[profName] - 1
                            if profLevels[profName] == 0 then
                                profLevels[profName] = nil
                                local idx = nil
                                for j, p in ipairs(selectedProfs) do
                                    if p == profName then idx = j; break end
                                end
                                if idx then table.remove(selectedProfs, idx) end
                            end
                        end
                        window:_UpdateProfessionsDisplay(pageIdx, mainContainer)
                    end
                end)
            end
            
            -- Level text displayed underneath icon
            local levelText = Text:New("RPE_Setup_SelectProfs_SelLevelText_" .. profName, {
                parent = profWrapper, text = "Lvl " .. tostring(level),
                fontTemplate = "GameFontNormalSmall", justifyH = "CENTER"
            })
            profWrapper:Add(levelText)
            
            -- Add tooltip for selected profession button
            if selBtn.frame then
                selBtn.frame:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(selBtn.frame, "ANCHOR_RIGHT")
                    GameTooltip:SetText(profName, 1, 1, 1, 1, true)
                    GameTooltip:AddLine("Level: " .. level, 0.5, 0.8, 1)
                    GameTooltip:Show()
                end)
                selBtn.frame:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
        end
    end
    
    if selectedIconGroup.RequestAutoSize then selectedIconGroup:RequestAutoSize() end
end


function SetupWindow:RenderSelectStats(headerGroup, bodyGroup, page)
    local statType = page.statType or "STANDARD_ARRAY"
    self.statType = statType  -- Store for use in Finish()
    local statsStr = page.stats or ""
    local maxPerStat = page.maxPerStat
    local maxPoints = page.maxPoints

    -- Parse the CSV list of stat IDs
    local statIds = {}
    if statsStr ~= "" then
        for statId in statsStr:gmatch("[^,]+") do
            statId = statId:gsub("^%s*(.-)%s*$", "%1") -- trim
            if statId ~= "" then
                table.insert(statIds, statId)
            end
        end
    end

    -- For STANDARD_ARRAY, limit to first 6 stats
    if statType == "STANDARD_ARRAY" then
        while #statIds > 6 do
            table.remove(statIds)
        end
    end

    -- Title in header
    local titleText = Text:New("RPE_Setup_SelectStats_Title", {
        parent = headerGroup, text = page.title or "Allocate ability scores",
        fontTemplate = "GameFontNormalLarge"
    })
    headerGroup:Add(titleText)

    -- Instructions in header
    local instructions = {}
    if statType == "STANDARD_ARRAY" then
        table.insert(instructions, "Assign the following values from lowest to highest.")
    elseif statType == "POINT_BUY" then
        table.insert(instructions, "27 points available (5e point buy)")
    elseif statType == "SIMPLE_ASSIGN" then
        if maxPerStat then
            table.insert(instructions, "Max per stat: " .. tostring(maxPerStat))
        end
        if maxPoints then
            table.insert(instructions, "Max total: " .. tostring(maxPoints))
        end
    else
        if maxPerStat then
            table.insert(instructions, "Max per stat: " .. tostring(maxPerStat))
        end
        if maxPoints then
            table.insert(instructions, "Max total: " .. tostring(maxPoints))
        end
    end

    if #instructions > 0 then
        local instrText = Text:New("RPE_Setup_SelectStats_Instructions", {
            parent = headerGroup, text = table.concat(instructions, " | "),
        })
        headerGroup:Add(instrText)
    end

    -- Status display in header (points/values)
    local statusRow = HGroup:New("RPE_Setup_SelectStats_Status", {
        parent = headerGroup, spacingX = 12, alignH = "CENTER", alignV = "CENTER",
        autoSize = false, width = WIN_W - 20, height = 16,
    })
    headerGroup:Add(statusRow)

    -- Initialize stat values storage if needed
    if not self.statValues then
        self.statValues = {}
    end
    if not self.pointsSpent then
        self.pointsSpent = 0
    end
    if not self.assignedArray then
        self.assignedArray = {}
    end
    
    -- Get incrementBy from page configuration
    self.incrementBy = page.incrementBy or 1

    -- If incrementBy is not 1, show the multiplier info
    if self.incrementBy ~= 1 then
        local multiplierText = Text:New("RPE_Setup_SelectStats_Multiplier", {
            parent = headerGroup, text = "Values will be multiplied by " .. tostring(self.incrementBy) .. " when saved.",
            fontSize = 10,
        })
        headerGroup:Add(multiplierText)
    end

    -- Get StatRegistry for stat definitions
    local StatRegistry = _G.RPE and _G.RPE.Core.StatRegistry

    -- Render based on stat type into bodyGroup
    if statType == "STANDARD_ARRAY" then
        self:RenderStandardArray(bodyGroup, statusRow, statIds, StatRegistry)
    elseif statType == "POINT_BUY" then
        self:RenderPointBuy(bodyGroup, statusRow, statIds, StatRegistry)
    else
        -- SIMPLE_ASSIGN and others
        self:RenderSimpleAssign(bodyGroup, statusRow, statIds, StatRegistry, maxPerStat, maxPoints)
    end
    
    -- Resize window based on number of stats being shown
    self:ResizeWindow(#statIds)
end

function SetupWindow:RenderStandardArray(parent, statusRow, statIds, StatRegistry)
    local arrayValues = {16, 14, 12, 11, 10, 8}
    local window = self -- Capture window instance for closures
    
    -- Track which array values are assigned (to prevent duplicates)
    if not window.standardArrayAssignments then
        window.standardArrayAssignments = {} -- maps statId -> arrayValue
        window.standardArrayAvailable = {} -- tracks which array values are used
    end
    
    -- Display unassigned values in header
    local statusLabel = Text:New("RPE_Setup_StdArrayStatusLabel", {
        parent = statusRow, text = "Unassigned:",
        autoSize = false, width = WIN_W - 20, height = 100,
    })
    statusRow:Add(statusLabel)

    local statusDisplay = Text:New("RPE_Setup_StdArrayStatusDisplay", {
        parent = statusRow, text = "16, 14, 12, 11, 10, 8",
        autoSize = false, width = WIN_W - 20, height = 100,
    })
    statusRow:Add(statusDisplay)

    -- Calculate and update available values display
    local function UpdatePointsDisplay()
        local used = {}
        for _, statId in ipairs(statIds) do
            local val = window.standardArrayAssignments[statId]
            if val then
                used[val] = true
            end
        end
        window.standardArrayAvailable = used
        
        -- Build list of unassigned values
        local unassigned = {}
        for _, val in ipairs(arrayValues) do
            if not used[val] then
                table.insert(unassigned, val)
            end
        end
        
        -- Display unassigned values
        local displayText = table.concat(unassigned, ", ")
        if displayText == "" then
            displayText = "All assigned!"
        end
        statusDisplay:SetText(displayText)
    end
    
    -- Create rows for each stat with three columns: Label, Value, Button
    for _, statId in ipairs(statIds) do
        if #(window.standardArrayStatRows or {}) < #statIds then
            window.standardArrayStatRows = window.standardArrayStatRows or {}
            
            local statDef = StatRegistry and StatRegistry:Get(statId)
            if statDef then
                local row = HGroup:New("RPE_Setup_StdArray_" .. statId, {
                    parent = parent, spacingX = 12, alignH = "CENTER", alignV = "CENTER",
                    autoSize = false, width = WIN_W - 20, height = 16,
                })
                parent:Add(row)

                -- Column 1: Stat name (fixed width for alignment)
                local nameText = Text:New("RPE_Setup_StdArrayStat_" .. statId, {
                    parent = row, text = (statDef.name or statId),
                    fontSize = 11, width = 60, autoSize = false,
                })
                nameText.frame:SetWidth(60)
                row:Add(nameText)

                -- Column 2: Stat value display (fixed width)
                local valueDisplay = Text:New("RPE_Setup_StdArrayValue_" .. statId, {
                    parent = row, text = "(Click to assign)",
                    fontSize = 11, width = 100, autoSize = false,
                })
                valueDisplay.frame:SetWidth(100)
                
                -- Make it clickable by wrapping in a frame
                local valueBtn = CreateFrame("Button", "RPE_Setup_StdArrayBtn_" .. statId, row.frame, "SecureActionButtonTemplate")
                valueBtn:SetSize(80, 20)
                valueBtn:SetPoint("LEFT", valueDisplay.frame, "LEFT")
                valueBtn:EnableMouse(true)
                
                local updateValueDisplay = function()
                    local assigned = window.standardArrayAssignments[statId]
                    if assigned then
                        local displayValue = assigned
                        -- For non-standard-array systems, show the multiplied value
                        if window.statType ~= "STANDARD_ARRAY" and window.incrementBy ~= 1 then
                            local statDef = StatRegistry and StatRegistry:Get(statId)
                            local baseVal = statDef and (statDef.base or 10) or 10
                            displayValue = baseVal + (assigned - baseVal) * window.incrementBy
                        end
                        -- Add % sign for percentage stats
                        local statDef = StatRegistry and StatRegistry:Get(statId)
                        local displayText = tostring(displayValue)
                        if statDef and statDef.pct == 1 then
                            displayText = displayText .. "%"
                        end
                        valueDisplay:SetText(displayText)
                    else
                        valueDisplay:SetText("(Click to assign)")
                    end
                    valueDisplay.frame:SetWidth(100)
                end
                
                valueBtn:SetScript("OnMouseUp", function(btn, button)
                    if button == "LeftButton" then
                        -- Find next available value in cycle: 16, 14, 12, 11, 10, 8
                        local currentVal = window.standardArrayAssignments[statId]
                        local nextVal = nil
                        
                        if not currentVal then
                            -- Find first available value
                            for _, val in ipairs(arrayValues) do
                                if not window.standardArrayAvailable[val] then
                                    nextVal = val
                                    break
                                end
                            end
                        else
                            -- Find next in cycle
                            local cycle = {16, 14, 12, 11, 10, 8, 16}
                            for i, val in ipairs(cycle) do
                                if val == currentVal then
                                    nextVal = cycle[i + 1]
                                    break
                                end
                            end
                        end
                        
                        if nextVal then
                            -- Remove old assignment
                            if currentVal then
                                window.standardArrayAssignments[statId] = nil
                            end
                            -- Assign new value
                            window.standardArrayAssignments[statId] = nextVal
                            window.statValues[statId] = nextVal
                            -- Track the incrementBy value from this page (only if not already set)
                            if not window.statIncrementBy[statId] then
                                window.statIncrementBy[statId] = window.incrementBy
                            end
                            updateValueDisplay()
                            UpdatePointsDisplay()
                        end
                        
                    elseif button == "RightButton" then
                        -- Remove assignment
                        window.standardArrayAssignments[statId] = nil
                        window.statValues[statId] = nil
                        updateValueDisplay()
                        UpdatePointsDisplay()
                    end
                end)
                
                -- Store reference for updates
                window.standardArrayStatRows[statId] = {
                    display = valueDisplay,
                    button = valueBtn,
                    updateDisplay = updateValueDisplay
                }
                
                row:Add(valueDisplay)
                updateValueDisplay()
            end
        end
    end
    
    UpdatePointsDisplay()
end

function SetupWindow:RenderPointBuy(parent, statusRow, statIds, StatRegistry)
    -- 5e Point Buy system: base 8, 27 points to spend
    -- Cost curve: 8=0, 9=1, 10=2, 11=3, 12=4, 13=5, 14=7, 15=9
    local pointBuyCosts = {
        [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9
    }

    -- Tracking
    if not self.pointBuyPoints then
        self.pointBuyPoints = 27
        for _, statId in ipairs(statIds) do
            self.statValues[statId] = 8 -- Base score
        end
    end

    -- Display points remaining in header
    local pointsLabel = Text:New("RPE_Setup_PointsLabel", {
        parent = statusRow, text = "Points remaining:",
        fontSize = 11, autoSize = true,
    })
    statusRow:Add(pointsLabel)

    local pointsDisplay = Text:New("RPE_Setup_PointsDisplay", {
        parent = statusRow, text = tostring(self.pointBuyPoints),
        fontSize = 11, autoSize = true,
    })
    statusRow:Add(pointsDisplay)

    -- Render each stat with +/- buttons (three columns: label, value, buttons)
    for _, statId in ipairs(statIds) do
        local statDef = StatRegistry and StatRegistry:Get(statId)
        if statDef then
            if not self.statValues[statId] then
                self.statValues[statId] = 8
            end

            local statRow = HGroup:New("RPE_Setup_PointBuyStat_" .. statId, {
                parent = parent, spacingX = 12, alignH = "CENTER", alignV = "CENTER",
                autoSize = false, width = WIN_W - 20, height = 16,
            })
            parent:Add(statRow)

            -- Column 1: Stat name (fixed width)
            local nameText = Text:New("RPE_Setup_PBStatName_" .. statId, {
                parent = statRow, text = (statDef.name or statId),
                fontSize = 11, width = 60, autoSize = false,
            })
            nameText.frame:SetWidth(60)
            statRow:Add(nameText)

            -- Column 2: Stat value display (fixed width)
            local valueText = Text:New("RPE_Setup_PBStatValue_" .. statId, {
                parent = statRow, text = tostring(self.statValues[statId]),
                fontSize = 11, width = 40, autoSize = false,
            })
            valueText.frame:SetWidth(40)
            statRow:Add(valueText)

            -- Helper function to update value display with multiplier
            local function UpdateValueDisplay()
                local baseVal = statDef and (statDef.base or 10) or 10
                local displayValue = self.statValues[statId]
                if self.incrementBy ~= 1 then
                    displayValue = baseVal + (self.statValues[statId] - baseVal) * self.incrementBy
                end
                -- Add % sign for percentage stats
                local displayText = tostring(displayValue)
                if statDef and statDef.pct == 1 then
                    displayText = displayText .. "%"
                end
                valueText:SetText(displayText)
                valueText.frame:SetWidth(40)
            end

            -- Column 3: +/- buttons
            -- Minus button
            local minusBtn = TextBtn:New("RPE_Setup_PBStatMinus_" .. statId, {
                parent = statRow, text = "-", width = 24, height = 20,
                onClick = function()
                    local current = self.statValues[statId]
                    if current > 8 then
                        local costOfCurrent = pointBuyCosts[current] or 0
                        self.statValues[statId] = current - 1
                        -- Track the incrementBy value from this page (only if not already set)
                        if not self.statIncrementBy[statId] then
                            self.statIncrementBy[statId] = self.incrementBy
                        end
                        local costOfNew = pointBuyCosts[current - 1] or 0
                        self.pointBuyPoints = self.pointBuyPoints + (costOfCurrent - costOfNew)
                        UpdateValueDisplay()
                        pointsDisplay:SetText(tostring(self.pointBuyPoints))
                        pointsDisplay.frame:SetWidth(40)
                    end
                end,
            })
            statRow:Add(minusBtn)

            -- Plus button
            local plusBtn = TextBtn:New("RPE_Setup_PBStatPlus_" .. statId, {
                parent = statRow, text = "+", width = 24, height = 20,
                onClick = function()
                    local current = self.statValues[statId]
                    if current < 15 then
                        local costOfCurrent = pointBuyCosts[current] or 0
                        local costOfNew = pointBuyCosts[current + 1] or 0
                        local costDiff = costOfNew - costOfCurrent
                        if self.pointBuyPoints >= costDiff then
                            self.statValues[statId] = current + 1
                            -- Track the incrementBy value from this page (only if not already set)
                            if not self.statIncrementBy[statId] then
                                self.statIncrementBy[statId] = self.incrementBy
                            end
                            self.pointBuyPoints = self.pointBuyPoints - costDiff
                            UpdateValueDisplay()
                            pointsDisplay:SetText(tostring(self.pointBuyPoints))
                            pointsDisplay.frame:SetWidth(40)
                        end
                    end
                end,
            })
            statRow:Add(plusBtn)
        end
    end
end

function SetupWindow:RenderSimpleAssign(parent, statusRow, statIds, StatRegistry, maxPerStat, maxPoints)
    -- Simple direct assignment with +/- buttons and optional constraints
    
    -- Display total points spent in header
    local pointsLabel = Text:New("RPE_Setup_SimpleAssignPointsLabel", {
        parent = statusRow, text = "Total points spent:",
        fontSize = 11, autoSize = false, width = WIN_W - 20, height = 16,
    })
    statusRow:Add(pointsLabel)

    local pointsDisplay = Text:New("RPE_Setup_SimpleAssignPointsDisplay", {
        parent = statusRow, text = "0",
        fontSize = 11, autoSize = false, width = WIN_W - 20, height = 16,
    })
    statusRow:Add(pointsDisplay)

    -- Calculate and update total points
    local function UpdatePointsDisplay()
        local total = 0
        local baseTotal = 0
        for _, statId in ipairs(statIds) do
            local statDef = StatRegistry and StatRegistry:Get(statId)
            local baseVal = 10  -- default
            if statDef and statDef.base then
                baseVal = (type(statDef.base) == "table" and statDef.base.default) or statDef.base or 10
            end
            baseTotal = baseTotal + baseVal
            total = total + (self.statValues[statId] or baseVal)
        end
        pointsDisplay:SetText(tostring(total - baseTotal))
    end
    
    -- Render each stat as a row with three columns: label, value, buttons
    for _, statId in ipairs(statIds) do
        local statDef = StatRegistry and StatRegistry:Get(statId)
        if statDef then
            local baseVal = 10
            if statDef.base then
                baseVal = (type(statDef.base) == "table" and statDef.base.default) or statDef.base or 10
            end
            
            -- Initialize stat value if not already set
            if not self.statValues[statId] then
                self.statValues[statId] = baseVal
            end

            local statRow = HGroup:New("RPE_Setup_Stat_" .. statId, {
                parent = parent, spacingX = 12, alignH = "CENTER", alignV = "CENTER",
                autoSize = false, width = WIN_W - 20, height = 16,
            })
            parent:Add(statRow)

            -- Column 1: Stat name label (fixed width)
            local nameText = Text:New("RPE_Setup_StatName_" .. statId, {
                parent = statRow, text = (statDef.name or statId),
                fontSize = 11, width = 60, autoSize = false,
            })
            nameText.frame:SetWidth(60)
            statRow:Add(nameText)

            -- Column 2: Stat value display (fixed width for alignment)
            local valueText = Text:New("RPE_Setup_StatValue_" .. statId, {
                parent = statRow, text = tostring(self.statValues[statId]),
                fontSize = 11, width = 40, autoSize = false,
            })
            valueText.frame:SetWidth(40)
            statRow:Add(valueText)

            -- Helper function to update value display with multiplier
            local function UpdateValueDisplay()
                local displayValue = self.statValues[statId]
                if self.incrementBy ~= 1 then
                    displayValue = baseVal + (self.statValues[statId] - baseVal) * self.incrementBy
                end
                -- Add % sign for percentage stats
                local displayText = tostring(displayValue)
                if statDef and statDef.pct == 1 then
                    displayText = displayText .. "%"
                end
                valueText:SetText(displayText)
                valueText.frame:SetWidth(40)
            end

            -- Column 3: +/- buttons
            -- Minus button
            local minusBtn = TextBtn:New("RPE_Setup_StatMinus_" .. statId, {
                parent = statRow, text = "-", width = 24, height = 20,
                onClick = function()
                    if self.statValues[statId] > 1 then
                        self.statValues[statId] = self.statValues[statId] - 1
                        -- Track the incrementBy value from this page (only if not already set)
                        if not self.statIncrementBy[statId] then
                            self.statIncrementBy[statId] = self.incrementBy
                        end
                        UpdateValueDisplay()
                        UpdatePointsDisplay()
                    end
                end,
            })
            statRow:Add(minusBtn)

            -- Plus button
            local plusBtn = TextBtn:New("RPE_Setup_StatPlus_" .. statId, {
                parent = statRow, text = "+", width = 24, height = 20,
                onClick = function()
                    local newVal = self.statValues[statId] + 1
                    if maxPerStat and newVal > maxPerStat then
                        return
                    end
                    self.statValues[statId] = newVal
                    -- Track the incrementBy value from this page (only if not already set)
                    if not self.statIncrementBy[statId] then
                        self.statIncrementBy[statId] = self.incrementBy
                    end
                    UpdateValueDisplay()
                    UpdatePointsDisplay()
                end,
            })
            statRow:Add(plusBtn)
        end
    end
    
    UpdatePointsDisplay()
end

function SetupWindow:UpdatePageText()
    local total = #self.pages
    local current = self.currentPageIdx
    if self.pageText then
        self.pageText:SetText(string.format("Page %d / %d", current, total))
    end
    
    -- Update progress bar
    if self.progressBar then
        self.progressBar:SetValue(current, total)
    end
end

-- Helper function to apply spare change from SELECT_ITEMS pages
-- Called from Finish() after processing all items for a page
-- If page.spareChange is true, uses SetCurrency to set leftover amount
function SetupWindow:_ApplySpareChange(pageIdx, page, profile)
    if not (page and page.pageType == "SELECT_ITEMS" and page.spareChange) then
        return
    end
    if not profile then return end
    
    -- Get the spare change amount calculated during item selection
    local spareCopper = self._pageSpareChange[pageIdx] or 0
    profile:SetCurrency("copper", spareCopper)
end

function SetupWindow:UpdateButtonStates()
    local total = #self.pages
    local current = self.currentPageIdx

    if self.prevBtn then
        self.prevBtn:SetEnabled(current > 1)
    end
    if self.nextBtn then
        self.nextBtn:SetEnabled(current < total)
    end
    if self.finishBtn then
        self.finishBtn:SetEnabled(true)
    end
end

function SetupWindow:PreviousPage()
    if self.currentPageIdx > 1 then
        self:ShowPage(self.currentPageIdx - 1)
    end
end

function SetupWindow:NextPage()
    if self.currentPageIdx < #self.pages then
        self:ShowPage(self.currentPageIdx + 1)
    end
end

function SetupWindow:Finish()
    local DBG = _G.RPE and _G.RPE.Debug
    
    -- NOTE: spareChange integration
    -- After processing each SELECT_ITEMS page, call self:_ApplySpareChange(pageIdx, page, profile)
    -- to apply spare change if page.spareChange is true
    
    local ProfileDB = _G.RPE and _G.RPE.Profile.DB
    if not ProfileDB then
        if DBG then DBG:Error("SetupWindow: ProfileDB not available") end
        return
    end
    
    -- Get or create the active profile for this character
    local profile = ProfileDB.GetOrCreateActive()
    if not profile then
        if DBG then DBG:Error("SetupWindow: Could not get active profile") end
        return
    end
    
    ---@type CharacterProfile
    profile = profile
    
    -- Save stats to player profile
    if self.statValues and next(self.statValues) then
        if DBG then DBG:Internal("SetupWindow: Saving stats") end
        
        for statId, assignedValue in pairs(self.statValues) do
            -- Set the base value of the stat in the profile
            profile:SetStatBase(statId, assignedValue)
            if DBG then DBG:Internal("SetupWindow: Set stat " .. statId .. " base = " .. assignedValue) end
        end
    end
    
    -- Save race and class to profile
    if self.selectedRace then
        profile.race = self.selectedRace
    end
    
    if self.selectedClass then
        profile.class = self.selectedClass
    end
    
    -- Add race and class traits to profile.traits
    if not profile.traits then
        profile.traits = {}
    end
    
    -- Add race traits
    for traitId, selected in pairs(self.selectedRaceTraits or {}) do
        if selected then
            -- Check if not already in traits list
            local found = false
            for _, existingId in ipairs(profile.traits) do
                if existingId == traitId then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(profile.traits, traitId)
            end
        end
    end
    
    -- Add class traits
    for traitId, selected in pairs(self.selectedClassTraits or {}) do
        if selected then
            -- Check if not already in traits list
            local found = false
            for _, existingId in ipairs(profile.traits) do
                if existingId == traitId then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(profile.traits, traitId)
            end
        end
    end
    
    -- Apply languages from any SELECT_LANGUAGE pages
    local Language = _G.RPE and _G.RPE.Core and _G.RPE.Core.Language
    if Language and self.pages then
        -- Initialize profile.languages if needed
        if not profile.languages then
            profile.languages = {}
        end
        
        for _, page in ipairs(self.pages) do
            if page.pageType == "SELECT_LANGUAGE" and page.languages then
                for _, langData in ipairs(page.languages) do
                    if langData.name and langData.skill then
                        profile.languages[langData.name] = langData.skill
                        Language:SetLanguageSkill(langData.name, langData.skill)
                    end
                end
            end
        end
    end
    
    -- Handle spell selection from any SELECT_SPELLS pages
    local hasSpellPage = false
    if self.pages then
        for _, page in ipairs(self.pages) do
            if page.pageType == "SELECT_SPELLS" then
                hasSpellPage = true
                if DBG then DBG:Internal("SetupWindow: Found SELECT_SPELLS page") end
                
                -- Note: restrictToClass, firstRankOnly, and allowRacial are only used during wizard setup
                -- to control UI behavior. They are NOT persisted to the profile.
                -- Only spell point and spell count limits are saved for reference.
                if not profile.spellConfig then
                    profile.spellConfig = {}
                end

                profile.spellConfig.maxSpellPoints = page.maxSpellPoints
                profile.spellConfig.maxSpellsTotal = page.maxSpellsTotal
                
                if DBG then DBG:Internal("SetupWindow: Clearing and learning spells") end
                -- Clear all existing spells
                profile:ClearSpells()
                
                -- Learn selected spells with all their ranks
                if self._spellSelectedSpells and next(self._spellSelectedSpells) then
                    
                    -- Get spell registry to look up spell definitions
                    local SpellRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
                    
                    for spellId, requestedRank in pairs(self._spellSelectedSpells) do
                        requestedRank = tonumber(requestedRank) or 1
                        
                        -- Learn all ranks from 1 to the requested rank
                        for rank = 1, requestedRank do
                            profile:LearnSpell(spellId, rank)
                        end
                    end
                end
                break  -- Only process first SELECT_SPELLS page
            end
        end
    end
    
    -- Handle item selection from any SELECT_ITEMS pages
    if self.pages then
        -- First, clear existing inventory and equipment
        local hasSelectItems = false
        for _, page in ipairs(self.pages) do
            if page.pageType == "SELECT_ITEMS" then
                hasSelectItems = true
                break
            end
        end
        
        if hasSelectItems then
            -- Clear inventory
            if profile.items then
                profile.items = {}
                if DBG then DBG:Internal("SetupWindow: Cleared inventory") end
            end
            
            -- Clear equipment slots
            if profile.equipment then
                profile.equipment = {}
                if DBG then DBG:Internal("SetupWindow: Cleared equipment") end
            end
        end
        
        -- Now add selected items from all SELECT_ITEMS pages
        for pageIdx, page in ipairs(self.pages) do
            if page.pageType == "SELECT_ITEMS" then
                if DBG then DBG:Internal("SetupWindow: Found SELECT_ITEMS page at index " .. pageIdx) end
                
                -- Add selected items to profile inventory (array of stacks)
                local pageItems = self._pageItemSelections[pageIdx]
                if pageItems and next(pageItems) then
                    for _, slot in ipairs(pageItems) do
                        local qty = tonumber(slot.qty) or 1
                        profile:AddItem(slot.id, qty)
                    end
                    if DBG then DBG:Internal("SetupWindow: Items added to inventory from page " .. pageIdx) end
                end
                
                -- Apply spare change if enabled for this page
                self:_ApplySpareChange(pageIdx, page, profile)
                if DBG then DBG:Internal("SetupWindow: Applied spare change for SELECT_ITEMS page " .. pageIdx) end
                
                -- Continue to next page instead of breaking
            end
        end
    end
    
    -- Handle profession selection from any SELECT_PROFESSIONS pages
    if self.pages then
        for pageIdx, page in ipairs(self.pages) do
            if page.pageType == "SELECT_PROFESSIONS" then
                if DBG then DBG:Internal("SetupWindow: Found SELECT_PROFESSIONS page at index " .. pageIdx) end
                
                -- Preserve utility professions before clearing
                local utilityProfs = {}
                if profile.professions then
                    if profile.professions.cooking then
                        utilityProfs.cooking = {
                            id = profile.professions.cooking.id,
                            level = profile.professions.cooking.level,
                            learned = profile.professions.cooking.learned,
                            spec = profile.professions.cooking.spec,
                            recipes = profile.professions.cooking.recipes or {}
                        }
                    end
                    if profile.professions.fishing then
                        utilityProfs.fishing = {
                            id = profile.professions.fishing.id,
                            level = profile.professions.fishing.level,
                            learned = profile.professions.fishing.learned,
                            spec = profile.professions.fishing.spec,
                            recipes = profile.professions.fishing.recipes or {}
                        }
                    end
                    if profile.professions.firstaid then
                        utilityProfs.firstaid = {
                            id = profile.professions.firstaid.id,
                            level = profile.professions.firstaid.level,
                            learned = profile.professions.firstaid.learned,
                            spec = profile.professions.firstaid.spec,
                            recipes = profile.professions.firstaid.recipes or {}
                        }
                    end
                end
                
                -- Clear all existing professions first
                profile:ClearProfessions()
                
                -- Initialize professions structure if not present
                if not profile.professions then
                    profile.professions = {}
                end
                
                -- Get selected professions and levels for this page
                local selectedProfs = self._pageSelectedProfessions[pageIdx] or {}
                local profLevels = self._pageProfessionLevels[pageIdx] or {}
                
                -- Add selected professions to profile
                for _, profName in ipairs(selectedProfs) do
                    local level = profLevels[profName] or 1
                    
                    -- Normalize profession names for storage (lowercase with underscores)
                    local profKey = profName:lower():gsub("%s+", "")
                    
                    -- Initialize profession slot if needed
                    if not profile.professions[profKey] then
                        profile.professions[profKey] = {
                            id = profName,
                            level = level,
                            learned = true,
                            spec = "",
                            recipes = {}
                        }
                    else
                        profile.professions[profKey].level = level
                        profile.professions[profKey].learned = true
                    end
                    
                    if DBG then DBG:Internal("SetupWindow: Added profession " .. profName .. " level " .. level) end
                end
                
                -- Restore utility professions with their preserved levels (always learned)
                for utilKey, utilProf in pairs(utilityProfs) do
                    profile.professions[utilKey] = {
                        id = utilProf.id,
                        level = utilProf.level,
                        learned = true,
                        spec = utilProf.spec,
                        recipes = utilProf.recipes
                    }
                    if DBG then DBG:Internal("SetupWindow: Restored utility profession " .. utilProf.id .. " level " .. utilProf.level) end
                end
                
                -- Ensure all utility professions exist and are learned
                if not profile.professions.cooking then
                    profile.professions.cooking = { id = "Cooking", level = 1, learned = true, spec = "", recipes = {} }
                else
                    profile.professions.cooking.learned = true
                end
                if not profile.professions.fishing then
                    profile.professions.fishing = { id = "Fishing", level = 1, learned = true, spec = "", recipes = {} }
                else
                    profile.professions.fishing.learned = true
                end
                if not profile.professions.firstaid then
                    profile.professions.firstaid = { id = "First Aid", level = 1, learned = true, spec = "", recipes = {} }
                else
                    profile.professions.firstaid.learned = true
                end
            end
        end
    end
    
    -- Learn all spells marked as alwaysKnown from the SpellRegistry
    local SpellRegistry = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
    if SpellRegistry and SpellRegistry.All then
        for spellId, spellDef in pairs(SpellRegistry:All()) do
            if spellDef and spellDef.alwaysKnown then
                -- Learn the spell at its max rank
                local maxRank = tonumber(spellDef.maxRanks) or 1
                for rank = 1, maxRank do
                    profile:LearnSpell(spellId, rank)
                end
                if DBG then DBG:Internal("SetupWindow: Learned alwaysKnown spell " .. spellId .. " (ranks 1-" .. maxRank .. ")") end
            end
        end
    end
    
    -- Save profile
    ProfileDB.SaveProfile(profile)
    if DBG then DBG:Internal("SetupWindow: Profile saved") end
    
    -- Refresh the CharacterSheet UI to show updated currencies
    local CharacterSheet = _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.CharacterSheetInstance
    if CharacterSheet and CharacterSheet.Refresh then
        CharacterSheet:Refresh()
        if DBG then DBG:Internal("SetupWindow: CharacterSheet refreshed") end
    end
    
    -- Clear all selections after finishing
    self._spellSelectedSpells = {}
    self._pageItemSelections = {}
    self._pageAllowances = {}
    self._itemCategoryFilter = {}
    self._itemPageIdx = 1
    self._pageSelectedProfessions = {}
    self._pageProfessionLevels = {}
    
    -- Reset progress after finishing
    self:ShowPage(1)
    
    -- Hide the window after finishing
    self:Hide()
    
    -- Refresh spellbook UI AFTER profile is saved
    if hasSpellPage then
        local SpellbookSheet = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.SpellbookSheet
        if SpellbookSheet and SpellbookSheet.Refresh then
            SpellbookSheet:Refresh()
            if DBG then DBG:Internal("SetupWindow: SpellbookSheet refreshed") end
        end
    end
    
    -- Refresh profession sheet AFTER profile is saved
    local ProfessionSheet = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.ProfessionSheet
    if ProfessionSheet and ProfessionSheet.Refresh then
        ProfessionSheet:Refresh()
        if DBG then DBG:Internal("SetupWindow: ProfessionSheet refreshed") end
    end
    
    if self.root and self.root.frame then
        self.root.frame:Hide()
    end
end

function SetupWindow:Show()
    -- Clear selections when opening wizard (fresh session)
    self._spellSelectedSpells = {}
    self._pageItemSelections = {}
    self._pageAllowances = {}
    self._itemCategoryFilter = {}
    self._itemPageIdx = 1
    self._pageSelectedProfessions = {}
    self._pageProfessionLevels = {}
    
    -- Reset progress to the beginning
    self:ShowPage(1)
    
    if self.root and self.root.frame then self.root:Show() end
end

function SetupWindow:Hide()
    if self.root and self.root.frame then self.root:Hide() end
end

function SetupWindow.New(opts)
    opts = opts or {}
    local self = setmetatable({}, SetupWindow)
    self:BuildUI()
    return self
end

return SetupWindow
