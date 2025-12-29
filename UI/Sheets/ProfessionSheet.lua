-- RPE_UI/Windows/ProfessionSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Panel    = RPE_UI.Elements.Panel
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local IconBtn  = RPE_UI.Elements.IconButton
local FrameEl  = RPE_UI.Elements.FrameElement

local RecipeRegistry = RPE.Core and RPE.Core.RecipeRegistry
local Common         = RPE.Common or {}

-- Fixed heights inside the craft panel
local SCROLLBAR_W = 24 -- width of UIPanelScrollFrame scrollbar
local TITLE_H  = 24
local ACTION_H = 30
local GAP_TOP  = 6
local GAP_BOT  = 6

---@class ProfessionSheet
local ProfessionSheet = {}
_G.RPE_UI.Windows.ProfessionSheet = ProfessionSheet
ProfessionSheet.__index = ProfessionSheet
ProfessionSheet.Name = "ProfessionSheet"

-- Get icons and profession list from Common.lua
local Common = RPE and RPE.Common or {}
local PROF_ICONS = Common.ProfessionIcons or {}
local ALL_PROFS = Common.ProfessionList or {
    "Cooking", "Fishing", "First Aid",
    "Alchemy", "Blacksmithing", "Enchanting", "Engineering",
    "Leatherworking", "Tailoring", "Inscription", "Jewelcrafting", "Mining", "Skinning", "Herbalism",
}

local function safeProf(p, id)
    if type(p) ~= "table" then p = {} end
    return {
        id      = id or p.id or "",
        level   = tonumber(p.level) or 0,
        learned = p.learned or false,
        spec    = p.spec or "",
        recipes = (type(p.recipes)=="table" and p.recipes) or {},
    }
end

-- Tooltip helpers
local function tipShow(frame, text)
    if not GameTooltip or not frame then return end
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(text, 1,1,1, 1, true)
end
local function tipHide() if GameTooltip then GameTooltip:Hide() end end

-- ============================================================================
function ProfessionSheet:BuildUI(opts)
    self.profile = RPE.Profile.DB.GetOrCreateActive()
    self.profile.professions = self.profile.professions or {}
    
    -- Ensure all professions are properly initialized with safeProf
    -- This handles both legacy storage (cooking, fishing, firstaid, profession1, profession2)
    -- and new storage (normalized profession names like alchemy, blacksmithing, etc.)
    for profName in pairs(self.profile.professions) do
        local prof = self.profile.professions[profName]
        -- Get the display name by looking it up in Common.ProfessionIcons or reconstructing it
        local displayName = prof.id or profName
        self.profile.professions[profName] = safeProf(prof, displayName)
    end
    
    -- Also ensure the utility professions exist
    self.profile.professions.cooking     = safeProf(self.profile.professions.cooking, "Cooking")
    self.profile.professions.fishing     = safeProf(self.profile.professions.fishing, "Fishing")
    self.profile.professions.firstaid    = safeProf(self.profile.professions.firstaid, "First Aid")

    self._catStates = {}
    self._craftQty  = 1

    self.sheet = VGroup:New("RPE_PS_Sheet", {
        parent = opts.parent, width=1, height=1,
        point="TOP", relativePoint="TOP", x=0, y=0,
        padding={ left=6, right=12, top=12, bottom=12 },
        spacingY=12, alignV="TOP", alignH="CENTER", autoSize=true,
    })

    self.iconRow = HGroup:New("RPE_PS_IconRow", {
        parent=self.sheet, spacingX=10, alignV="CENTER", autoSize=true,
    })
    self.sheet:Add(self.iconRow)
    self:DrawIconRow()

    self.bodyGroup = VGroup:New("RPE_PS_Body", {
        parent=self.sheet, spacingY=10, alignV="TOP", alignH="CENTER", autoSize=true,
    })
    self.sheet:Add(self.bodyGroup)

    self.title = Text:New("RPE_PS_Title", {
        parent=self.bodyGroup,
        text="Select a profession to view recipes.",
        fontTemplate="GameFontNormalLarge", justifyH="CENTER",
        width=1, height=16,
    })
    self.bodyGroup:Add(self.title)

    -- Progress bar for profession skill level (0-300)
    local ProgressBar = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.ProgressBar
    if ProgressBar then
        self.skillProgress = ProgressBar:New("RPE_PS_SkillProgress", {
            parent = self.bodyGroup,
            width = 300,
            height = 12,
            showLabel = true,
            style = "progress_xp"
        })
        self.bodyGroup:Add(self.skillProgress)
        
        -- Enable left click on progress bar to set random level
        self.skillProgress.frame:EnableMouse(true)
        self.skillProgress.frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" and self._currentProfession then
                self._currentProfession.level = math.random(0, 300)
                self:_updateProgressBar(self._currentProfession)
            end
        end)
    end

    self.split = HGroup:New("RPE_PS_SplitRow", {
        parent=self.bodyGroup, spacingX=32, alignV="TOP", autoSize=true,
    })
    self.bodyGroup:Add(self.split)

    -- pane sizing (account for scrollbars inside each pane)
    self._paneW = self._paneW or 200
    self._paneH = self._paneH or 320
    local LEFT_W  = self._paneW - SCROLLBAR_W
    local RIGHT_W = self._paneW + 40 - SCROLLBAR_W

    -- LEFT fixed pane
    self.leftPane = Panel:New("RPE_PS_LeftPane", {
        parent   = self.split,
        width    = LEFT_W,
        height   = self._paneH,
        autoSize = false,
    })
    self.split:Add(self.leftPane)

    local sf = CreateFrame("ScrollFrame", "RPE_PS_Scroll", self.leftPane.frame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     self.leftPane.frame, "TOPLEFT",  0, 0)
    sf:SetPoint("BOTTOMRIGHT", self.leftPane.frame, "BOTTOMRIGHT", 0, 0)

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetSize(LEFT_W, self._paneH)
    sf:SetScrollChild(sc)
    local scFE = FrameEl:New("ScrollChild", sc, nil)

    self.recipeList = VGroup:New("RPE_PS_RecipeList", {
        parent=scFE, width=LEFT_W, spacingY=6,
        alignH="LEFT", autoSize=true,
    })

    -- RIGHT fixed-height craft panel
    self.craftPanel = VGroup:New("RPE_PS_CraftPanel", {
        parent=self.split, spacingY=10, alignH="LEFT",
        autoSize=false, height=self._paneH, width=RIGHT_W,
    })
    self.split:Add(self.craftPanel)

    self:BuildCraftPanel(nil)
    self:PopulateRecipes(nil)

    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE_UI.Common:RegisterWindow(self)
    end
end

-- ============================================================================
-- Icons
local function profOwned(self, name)
    -- Normalize profession name for storage key lookup (lowercase, no spaces)
    local profKey = name:lower():gsub("%s+", "")
    
    -- Look up profession by normalized key
    if self.profile.professions and self.profile.professions[profKey] then
        local prof = self.profile.professions[profKey]
        local owned = prof and prof.learned
        return owned, prof
    end
    
    return false, safeProf(nil, name)
end

function ProfessionSheet:DrawIconRow()
    for i=#self.iconRow.children,1,-1 do self.iconRow.children[i]:Destroy() end
    self.iconRow.children={}
    for _, name in ipairs(ALL_PROFS) do
        local hasIt, prof = profOwned(self,name)
        local tex = PROF_ICONS[name] or "Interface\\Icons\\INV_Misc_QuestionMark"
        local btn = IconBtn:New("RPE_PS_Icon_"..name,{
            parent=self.iconRow, width=20,height=20, icon=tex,
            hasBorder=false, noBorder=true,
            hasBackground=false, noBackground=true,
            onClick=function()
                if hasIt then
                    -- switch profession: clear any selected recipe and craft panel
                    self.selectedRecipe = nil
                    self._currentProfession = prof
                    self.title:SetText(prof.id)
                    self:_updateProgressBar(prof)
                    self:PopulateRecipes(prof)
                    self:BuildCraftPanel(nil)      -- empty/right panel
                    self:_syncColumnHeights()
                end
            end
        })
        self.iconRow:Add(btn)
        if not hasIt then 
            btn:Lock()
            -- Desaturate unlearned profession icons
            if btn.icon then
                btn.icon:SetDesaturated(true)
                btn.icon:SetAlpha(0.4)
            end
        end
        btn.frame:SetScript("OnEnter",function()
            if hasIt then
                local tooltip = string.format("%s\nLevel %d",name,prof.level or 0)
                if prof.spec and prof.spec ~= "" then
                    tooltip = tooltip .. "\nSpec: " .. prof.spec
                end
                tipShow(btn.frame, tooltip)
            else
                tipShow(btn.frame,name.." (Not learned)")
            end
        end)
        btn.frame:SetScript("OnLeave",tipHide)
    end
end


-- ============================================================================
-- Helpers

-- Keep both panes strictly at the fixed height (never read current craft height)
function ProfessionSheet:_syncColumnHeights()
    if self.leftPane and self.leftPane.frame then
        self.leftPane.frame:SetHeight(self._paneH)
    end
    if self.craftPanel and self.craftPanel.frame then
        self.craftPanel.frame:SetHeight(self._paneH)
    end
end

function ProfessionSheet:_updateProgressBar(prof)
    if not prof or not self.skillProgress then return end
    
    local level = tonumber(prof.level) or 0
    local maxLevel = 300
    
    -- Update progress bar value (animates smoothly)
    self.skillProgress:SetValue(level, maxLevel)
end

function ProfessionSheet:OnSelectRecipe(recipe)
    self.selectedRecipe=recipe
    self:BuildCraftPanel(recipe)
    self:_syncColumnHeights()
end

-- Check if a recipe is learned by the current profession
function ProfessionSheet:_isRecipeLearned(recipe)
    if not recipe or not self._currentProfession then return false end
    
    local knownList = self._currentProfession.recipes or {}
    for _, id in ipairs(knownList) do
        if id == recipe.id then
            return true
        end
    end
    return false
end

-- Check if player can craft the recipe with given quantity
function ProfessionSheet:_canCraftRecipe(recipe, qty)
    if not recipe or not self.profile then return false end
    qty = math.max(1, tonumber(qty) or 1)
    
    -- Check required reagents for full quantity
    local reagents = recipe.reagents or {}
    for _, mat in ipairs(reagents) do
        local need = (tonumber(mat.qty) or 1) * qty
        if not self.profile:HasItem(tostring(mat.id), need) then
            return false
        end
    end
    return true
end

-- ============================================================================
-- Recipe list (with known-recipe highlighting)
function ProfessionSheet:_addCategory(parent, catKey, catTitle, items, prof, knownSet)
    -- First, filter recipes to only those with valid items in the registry
    local validRecipes = {}
    local invalidRecipes = {}
    local DBG = _G.RPE and _G.RPE.Debug
    local ItemRegistry = RPE.Core and RPE.Core.ItemRegistry
    
    for _, r in ipairs(items or {}) do
        -- Use outputItemId directly - it's the actual item ID in the recipe
        local itemIdToCheck = r.outputItemId
        local itemExists = ItemRegistry and ItemRegistry:Get(itemIdToCheck)
        
        if itemExists then
            table.insert(validRecipes, r)
        else
            table.insert(invalidRecipes, r)
            -- Debug: log what we're checking
            if DBG then
                DBG:Internal(("ProfessionSheet: Checking recipe '%s' (%s) with outputItemId '%s'"):format(r.name or r.id, r.id, itemIdToCheck))
                if not ItemRegistry then
                    DBG:Internal("  ItemRegistry is nil!")
                else
                    local allItems = ItemRegistry:All()
                    if not allItems then
                        DBG:Internal("  ItemRegistry:All() returned nil!")
                    else
                        local count = 0
                        for _ in pairs(allItems) do count = count + 1 end
                        DBG:Internal(("  ItemRegistry has %d items"):format(count))
                        if count == 0 then
                            DBG:Internal("  WARNING: ItemRegistry is EMPTY!")
                        else
                            -- Show first few items for debugging
                            local shown = 0
                            for id in pairs(allItems) do
                                if shown < 5 then
                                    DBG:Internal(("    - %s"):format(id))
                                    shown = shown + 1
                                end
                            end
                            -- Check if our item is in the list
                            if allItems[itemIdToCheck] then
                                DBG:Internal(("  FOUND '%s' in ItemRegistry!"):format(itemIdToCheck))
                            else
                                DBG:Internal(("  '%s' NOT found in ItemRegistry"):format(itemIdToCheck))
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Warn about invalid recipes
    if #invalidRecipes > 0 then
        if DBG then
            for _, r in ipairs(invalidRecipes) do
                DBG:Warning(("ProfessionSheet: Recipe '%s' (%s) has invalid output item '%s' (not in ItemRegistry)"):format(r.name or r.id, r.id, r.outputItemId))
            end
        end
    end
    
    -- If no valid recipes, don't display the category
    if #validRecipes == 0 then
        return
    end
    
    local head = HGroup:New("RPE_PS_CatHead_" .. catKey, {
        parent = parent,
        height = 12,
        spacingX = 6,
        alignV = "LEFT",
        autoSize = true,
    })
    parent:Add(head)

    local indicator = Text:New("RPE_PS_CatHeadIcon_" .. catKey, {
        parent = head,
        text = (self._catStates[catKey] ~= false) and "-" or "+",
        fontTemplate = "GameFontNormal",
    })
    head:Add(indicator)

    local list
    local btn = TextBtn:New("RPE_PS_CatHeadBtn_" .. catKey, {
        parent = head,
        text = catTitle,
        noBorder = true,
        onClick = function()
            local isExpanded = (self._catStates[catKey] ~= false)
            self._catStates[catKey] = not isExpanded
            if isExpanded then
                if list and list.Hide then list:Hide() end
                indicator:SetText("+")
            else
                if list and list.Show then list:Show() end
                indicator:SetText("-")
            end
            self:_syncColumnHeights()
        end,
    })
    head:Add(btn)

    list = VGroup:New("RPE_PS_CatList_" .. catKey, {
        parent = parent,
        width = parent.width or (self.recipeList and self.recipeList.width) or self._paneW - 18,
        spacingY = 2,
        alignH = "LEFT",
        autoSize = true,
    })
    parent:Add(list)

    local playerSkill = (prof and prof.level) or 0
    for i, r in ipairs(validRecipes) do
        local isKnown = knownSet[r.id] or false
        local color
        
        -- "Unlearned" category: always show in grey
        if catTitle == "Unlearned" then
            color = "|cff808080" -- grey for unlearned
        else
            -- Learned recipes: color by skill level
            color = Common.GetRecipeColor and Common:GetRecipeColor(playerSkill, r.skill) or "|cffffffff"
        end
        local label = string.format("%s%s|r", color, r.name)

        local rbtn = TextBtn:New(("RPE_PS_Cat_%s_Item_%d"):format(catKey, i), {
            parent = list,
            text = label,
            height = 16,
            noBorder = true,
            onClick = function()
                self:OnSelectRecipe(r)
            end,
        })

        -- hover highlight
        local f = rbtn.frame
        f:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        local tex = f:GetHighlightTexture()
        tex:SetAlpha(0.25)
        tex:SetAllPoints()

        list:Add(rbtn)
    end

    if self._catStates[catKey] == false then
        list:Hide()
        indicator:SetText("+")
    else
        list:Show()
        indicator:SetText("-")
    end
end

function ProfessionSheet:PopulateRecipes(prof)
    -- Clear old content
    for i = #self.recipeList.children, 1, -1 do
        self.recipeList.children[i]:Destroy()
    end
    self.recipeList.children = {}

    if not prof or not prof.id or prof.id == "" then
        local line = Text:New("RPE_PS_Recipe_None", {
            parent = self.recipeList,
            text = "(no profession selected)",
            fontTemplate = "GameFontNormalSmall",
            justifyH = "LEFT",
        })
        self.recipeList:Add(line)
        self:_syncColumnHeights()
        return
    end

    -- Pull recipes from registry
    local recipes = RecipeRegistry and RecipeRegistry:GetByProfession(prof.id) or {}
    local cats = {}
    for _, r in pairs(recipes) do
        local cat = r.category or "Misc"
        cats[cat] = cats[cat] or {}
        table.insert(cats[cat], r)
    end

    -- Build known recipe lookup table
    local profile = RPE.Profile.DB:GetOrCreateActive()
    local knownList = profile:GetKnownRecipes(prof.id)
    local knownSet = {}
    for _, id in ipairs(knownList or {}) do
        knownSet[id] = true
    end

    -- Build categories for LEARNED recipes only
    for cat, items in pairs(cats) do
        -- Filter to only recipes the player knows
        local learnedInCategory = {}
        for _, r in ipairs(items) do
            if knownSet[r.id] then
                table.insert(learnedInCategory, r)
            end
        end
        
        -- Only display category if it has learned recipes
        if #learnedInCategory > 0 then
            table.sort(learnedInCategory, function(a, b)
                return (a.name or a.id) < (b.name or b.id)
            end)
            self:_addCategory(self.recipeList, prof.id .. "_" .. cat, cat, learnedInCategory, prof, knownSet)
        end
    end

    -- Build "Unlearned" category for recipes player doesn't know
    local unlearnedRecipes = {}
    for _, r in pairs(recipes) do
        if not knownSet[r.id] then
            table.insert(unlearnedRecipes, r)
        end
    end
    
    if #unlearnedRecipes > 0 then
        table.sort(unlearnedRecipes, function(a, b)
            return (a.name or a.id) < (b.name or b.id)
        end)
        self:_addCategory(self.recipeList, prof.id .. "_Unlearned", "Unlearned", unlearnedRecipes, prof, knownSet)
    end

    self:_syncColumnHeights()
end


-- ============================================================================
-- Craft panel
local function hookItemTooltip(widgetFrame, itemDef)
    if not (widgetFrame and itemDef and itemDef.ShowTooltip and Common and Common.ShowTooltip) then return end
    widgetFrame:EnableMouse(true)
    widgetFrame:SetScript("OnEnter", function()
        local spec = itemDef:ShowTooltip()
        Common:ShowTooltip(widgetFrame, spec)
    end)
    widgetFrame:SetScript("OnLeave", function()
        if Common and Common.HideTooltip then Common:HideTooltip() end
    end)
end

function ProfessionSheet:_addMatRow(parent, idSuffix, icon, name, have, need, bonusesText, itemDef)
    local row = HGroup:New("RPE_PS_Craft_MatRow_"..idSuffix, {
        parent  = parent,
        spacingX = 8,
        alignV   = "CENTER",
        autoSize = true,
    })
    parent:Add(row)

    local ico = IconBtn:New("RPE_PS_Craft_MatIcon_"..idSuffix, {
        parent = row,
        width = 12, height = 12,
        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
    })
    row:Add(ico)

    local nameTxt = Text:New("RPE_PS_Craft_MatName_"..idSuffix, {
        parent = row,
        text   = name or "Item",
        fontTemplate = "GameFontNormal",
        justifyH = "LEFT",
    })
    row:Add(nameTxt)

    local qtyTxt = Text:New("RPE_PS_Craft_MatQty_"..idSuffix, {
        parent = row,
        text   = string.format("%d / %d", have or 0, need or 0),
        fontTemplate = "GameFontNormalSmall",
        justifyH = "LEFT",
    })
    row:Add(qtyTxt)

    -- Hook tooltip to both icon and name
    hookItemTooltip(ico.frame, itemDef)
    hookItemTooltip(nameTxt.frame, itemDef)

    if bonusesText and bonusesText ~= "" then
        local bonuses = Text:New("RPE_PS_Craft_MatBonus_"..idSuffix, {
            parent = parent,
            text   = "  • " .. bonusesText,
            fontTemplate = "GameFontNormalSmall",
            justifyH = "LEFT",
        })
        parent:Add(bonuses)
    end
end

function ProfessionSheet:_qtyClampSet(qty)
    local q=tonumber(qty) or 1
    if q<1 then q=1 elseif q>999 then q=999 end
    self._craftQty=q
    if self._qtyText and self._qtyText.SetText then self._qtyText:SetText(tostring(self._craftQty)) end
end

function ProfessionSheet:BuildCraftPanel(recipe)
    -- Clear
    for i = #self.craftPanel.children, 1, -1 do
        self.craftPanel.children[i]:Destroy()
    end
    self.craftPanel.children = {}

    if self.craftPanel and self.craftPanel.frame then
        self.craftPanel.frame:SetHeight(self._paneH)
    end

    local r = (recipe and RecipeRegistry and RecipeRegistry:Get(recipe.id)) or nil
    local ItemRegistry = RPE.Core and RPE.Core.ItemRegistry
    local Common       = RPE.Common or {}

    -- constants used to compute the viewport height
    local TITLE_H, ACTION_H = 24, 30
    local GAP_TOP, GAP_BOT  = 6, 6
    local SCROLLBAR_W       = 18

    -- TITLE
    local titleRow = HGroup:New("RPE_PS_Craft_TitleRow", {
        parent   = self.craftPanel,
        spacingX = 8,
        alignV   = "CENTER",
        autoSize = true,
    })
    self.craftPanel:Add(titleRow)
    if titleRow.frame then titleRow.frame:SetHeight(TITLE_H) end

    local outIcon, outName, outItemDef
    if r then
        local outItem   = r:GetOutputItem()
        outIcon         = outItem and outItem.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
        outName         = outItem and outItem.name or r.outputItemId
        -- Use outputItemId directly for registry lookup
        outItemDef      = (ItemRegistry and r.outputItemId) and ItemRegistry:Get(r.outputItemId) or nil
        local qualKey   = r.quality or "common"
        outName         = (Common.ColorByQuality and Common:ColorByQuality(outName, qualKey)) or outName
    else
        outIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
        outName = "Select a recipe"
        outItemDef = nil
    end

    local outBtn = IconBtn:New("RPE_PS_Craft_OutIcon", {
        parent = titleRow, width = 20, height = 20, icon = outIcon, noBorder = true,
    }); titleRow:Add(outBtn)

    local outText = Text:New("RPE_PS_Craft_OutName", {
        parent = titleRow, text = outName, fontTemplate = "GameFontNormalLarge", justifyH = "LEFT",
    }); titleRow:Add(outText)

    -- Hook tooltip for the output icon & title (if item is known)
    if outItemDef and outItemDef.ShowTooltip and Common and Common.ShowTooltip then
        outBtn.frame:EnableMouse(true)
        outBtn.frame:SetScript("OnEnter", function()
            local spec = outItemDef:ShowTooltip()
            Common:ShowTooltip(outBtn.frame, spec)
        end)
        outBtn.frame:SetScript("OnLeave", function()
            if Common.HideTooltip then Common:HideTooltip() end
        end)

        outText.frame:EnableMouse(true)
        outText.frame:SetScript("OnEnter", function()
            local spec = outItemDef:ShowTooltip()
            Common:ShowTooltip(outText.frame, spec)
        end)
        outText.frame:SetScript("OnLeave", function()
            if Common.HideTooltip then Common:HideTooltip() end
        end)
    end

    -- SCROLLVIEW (middle content only)
    local frameW   = (self.craftPanel and self.craftPanel.frame and self.craftPanel.frame:GetWidth()) or 0
    local visibleW = (frameW > 0 and frameW) or (self._paneW + 40 - SCROLLBAR_W)
    local visibleH = math.max(80, self._paneH - TITLE_H - ACTION_H - GAP_TOP - GAP_BOT)

    local scrollPane = Panel:New("RPE_PS_Craft_ScrollPane", {
        parent   = self.craftPanel,
        width    = visibleW,
        height   = visibleH,
        autoSize = false,
    })
    self.craftPanel:Add(scrollPane)

    local sf = CreateFrame("ScrollFrame", "RPE_PS_Craft_SF", scrollPane.frame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     scrollPane.frame, "TOPLEFT",  0, 0)
    sf:SetPoint("BOTTOMRIGHT", scrollPane.frame, "BOTTOMRIGHT", 0, 0)

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetSize(visibleW, visibleH)
    sf:SetScrollChild(sc)
    local scFE = FrameEl:New("RPE_PS_Craft_ScrollChild", sc, nil)

    local content = VGroup:New("RPE_PS_Craft_Content", {
        parent   = scFE,
        width    = visibleW,
        spacingY = 8,
        alignH   = "LEFT",
        autoSize = true,
    })

    if r then
        if r.tools and #r.tools > 0 then
            content:Add(Text:New("RPE_PS_Craft_ToolsText", {
                parent = content,
                text   = "Requires: " .. table.concat(r.tools, ", "),
                fontTemplate = "GameFontNormalSmall",
                justifyH = "LEFT",
            }))
        end

        if r.reagents and #r.reagents > 0 then
            content:Add(Text:New("RPE_PS_Craft_ReqLabel", {
                parent = content, text = "Required Items",
                fontTemplate = "GameFontNormal", justifyH = "LEFT",
            }))
            local reqList = VGroup:New("RPE_PS_Craft_ReqList", {
                parent = content, spacingY = 4, alignH = "LEFT", autoSize = true,
            })
            content:Add(reqList)

            for i, mat in ipairs(r.reagents) do
                local it   = ItemRegistry and ItemRegistry:Get(mat.id)
                local icon = it and it.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                local name = it and ((Common.ColorByQuality and Common:ColorByQuality(it.name, it.rarity)) or it.name) or mat.id
                local id   = tostring(mat.id)
                local have = (self.profile and self.profile.GetItemQty) and self.profile:GetItemQty(id) or 0
                self:_addMatRow(reqList, "Req"..i, icon, name, have, mat.qty, nil, it)
            end
        end

        if r.optional and #r.optional > 0 then
            content:Add(Text:New("RPE_PS_Craft_OptLabel", {
                parent = content, text = "Optional Items",
                fontTemplate = "GameFontNormal", justifyH = "LEFT",
            }))
            local optList = VGroup:New("RPE_PS_Craft_OptList", {
                parent = content, spacingY = 4, alignH = "LEFT", autoSize = true,
            })
            content:Add(optList)

            for i, mat in ipairs(r.optional) do
                local it   = ItemRegistry and ItemRegistry:Get(mat.id)
                local icon = it and it.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                local name = it and ((Common.ColorByQuality and Common:ColorByQuality(it.name, it.rarity)) or it.name) or mat.id
                local id   = tostring(mat.id)
                local have = (self.profile and self.profile.GetItemQty) and self.profile:GetItemQty(id) or 0
                self:_addMatRow(optList, "Opt"..i, icon, name, have, mat.qty, mat.bonus or "", it)
            end
        end
    end

    -- ACTION ROW (outside scroll)
    local actionRow = HGroup:New("RPE_PS_Craft_ActionRow", {
        parent   = self.craftPanel,
        spacingX = 12,
        alignV   = "CENTER",
        autoSize = true,
    })
    self.craftPanel:Add(actionRow)
    if actionRow.frame then actionRow.frame:SetHeight(ACTION_H) end

    local minusBtn = TextBtn:New("RPE_PS_Craft_QtyMinus", {
        parent  = actionRow, width = 28, height = 24, text = "–",
        onClick = function() self:_qtyClampSet((self._craftQty or 1) - 1) end
    }); actionRow:Add(minusBtn)

    self._qtyText = Text:New("RPE_PS_Craft_QtyText", {
        parent = actionRow, text = tostring(self._craftQty or 1),
        fontTemplate = "GameFontNormal", justifyH = "CENTER", width = 40, height = 16,
    }); actionRow:Add(self._qtyText)

    local plusBtn = TextBtn:New("RPE_PS_Craft_QtyPlus", {
        parent  = actionRow, width = 28, height = 24, text = "+",
        onClick = function() self:_qtyClampSet((self._craftQty or 1) + 1) end
    }); actionRow:Add(plusBtn)

    local craftBtn = TextBtn:New("RPE_PS_Craft_DoCraft", {
        parent = actionRow, width = 80, height = 26, text = "Craft",
        onClick = function()
            if not r or not RPE or not RPE.Core or not RPE.Core.Crafting then return end
            local qty = tonumber(self._craftQty or 1) or 1
            if qty < 1 then qty = 1 end
            RPE.Core.Crafting:CraftRecipe(r, qty)
        end
    }); actionRow:Add(craftBtn)
    
    -- Disable craft button if recipe is unlearned or not enough materials
    if not self:_isRecipeLearned(r) or not self:_canCraftRecipe(r, self._craftQty or 1) then
        craftBtn:Lock()
    end

    local craftAllBtn = TextBtn:New("RPE_PS_Craft_DoCraftAll", {
        parent = actionRow, width = 50, height = 26, text = "All",
        onClick = function()
            if not r or not RPE or not RPE.Core or not RPE.Core.Crafting then return end
            RPE.Core.Crafting:CraftRecipeAll(r)
        end
    }); actionRow:Add(craftAllBtn)
    
    -- Disable "All" button if recipe is unlearned or can't craft at all
    if not self:_isRecipeLearned(r) or not self:_canCraftRecipe(r, 1) then
        craftAllBtn:Lock()
    end

    -- lock both panes to the same fixed height
    if self.leftPane and self.leftPane.frame then self.leftPane.frame:SetHeight(self._paneH) end
    if self.craftPanel and self.craftPanel.frame then self.craftPanel.frame:SetHeight(self._paneH) end
end


function ProfessionSheet:Refresh()
    -- Ensure we always read the current active profile instance
    self.profile = RPE.Profile.DB.GetOrCreateActive()

    -- Rebuild the icon row to reflect updated profession learned status
    self:DrawIconRow()

    -- Rebuild the right panel for the current selection (or empty state)
    if self.selectedRecipe then
        self:BuildCraftPanel(self.selectedRecipe)
    else
        self:BuildCraftPanel(nil)
    end
    
    -- Update progress bar if a profession is currently selected
    if self._currentProfession then
        self:_updateProgressBar(self._currentProfession)
    end
    
    self:_syncColumnHeights()
end

-- ============================================================================
function ProfessionSheet.New(opts)
    local self=setmetatable({},ProfessionSheet)
    self:BuildUI(opts or {})
    return self
end
return ProfessionSheet
