-- RPE_UI/Windows/SpellbookSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.ActiveRules = RPE.ActiveRules

local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local TextBtn  = RPE_UI.Elements.TextButton
local Common   = RPE_UI.Common

local SpellbookSlot = RPE_UI.Prefabs.SpellbookSlot

---@class SpellbookSheet
---@field activeTags table<string, boolean>
---@field highestOnly boolean
local SpellbookSheet = {}
_G.RPE_UI.Windows.SpellbookSheet = SpellbookSheet
SpellbookSheet.__index = SpellbookSheet
SpellbookSheet.Name = "SpellbookSheet"

------------------------------------------------------------
-- BUILT-IN TAGS (class/spec groups)
------------------------------------------------------------
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
    { class = "Demon Hunter", color = {0.64, 0.19, 0.79}, specs = {"Havoc", "Vengeance"} },
    { class = "Evoker",  color = {0.33, 0.75, 0.93}, specs = {"Devastation", "Preservation", "Augmentation"} },
}

------------------------------------------------------------
-- HELPER
------------------------------------------------------------
local function updateFilterButtonLabel(self)
    local count = 0
    for _, enabled in pairs(self.activeTags) do
        if enabled then count = count + 1 end
    end
    if count == 0 then
        self.tagBtn:SetText("Filter: All Tags")
    else
        self.tagBtn:SetText(("Filter: %d selected"):format(count))
    end
end

------------------------------------------------------------
function SpellbookSheet:BuildUI(opts)
    opts = opts or {}
    self.rows  = opts.rows or 6
    self.cols  = opts.cols or 8
    self.slots = {}
    self.activeTags = {}
    self.highestOnly = false

    self.sheet = VGroup:New("RPE_SB_Sheet", {
        parent = opts.parent,
        width  = 1,
        height = 1,
        point  = "TOP",
        relativePoint = "TOP",
        x = 0, y = 0,
        padding = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV = "TOP",
        alignH = "LEFT", -- restore left alignment
        autoSize = true,
    })

    --------------------------------------------------------
    -- Filter bar
    --------------------------------------------------------
    local filterBar = HGroup:New("RPE_SpellbookFilterBar", {
        parent = self.sheet,
        spacingX = 8,
        alignV = "CENTER",
        alignH = "LEFT", -- prevent centering
        autoSize = true,
    })
    self.sheet:Add(filterBar)

    self.tagBtn = TextBtn:New("RPE_SpellbookTagFilter", {
        parent = filterBar,
        width = 200, height = 24,
        text = "Filter: All Tags",
    })
    filterBar:Add(self.tagBtn)

    self.rankBtn = TextBtn:New("RPE_SpellbookHighestOnly", {
        parent = filterBar,
        width = 180, height = 24,
        text = "Show Highest Rank: OFF",
    })
    filterBar:Add(self.rankBtn)

    --------------------------------------------------------
    -- Collect dynamic tags
    --------------------------------------------------------
    local allTags = {}
    local reg = RPE.Core and RPE.Core.SpellRegistry
    if reg and reg.All then
        for _, def in pairs(reg:All()) do
            if def.tags then
                for _, tag in ipairs(def.tags) do
                    allTags[tag] = true
                end
            end
        end
    end
    local extraTags = {}
    for tag in pairs(allTags) do
        local found = false
        for _, c in ipairs(BUILTIN_CLASS_TAGS) do
            if tag == c.class then found = true break end
            for _, s in ipairs(c.specs) do if tag == s then found = true break end end
            if found then break end
        end
        if not found then table.insert(extraTags, tag) end
    end
    table.sort(extraTags)

    --------------------------------------------------------
    -- Dropdown menu builder
    --------------------------------------------------------
    self.tagBtn:SetOnClick(function()
        Common:ContextMenu(self.tagBtn.frame, function(level, menuList)
            local info

            if level == 1 then
                UIDropDownMenu_AddButton({
                    text = "All Tags",
                    isNotRadio = true,
                    checked = (next(self.activeTags) == nil),
                    func = function()
                        self.activeTags = {}
                        updateFilterButtonLabel(self)
                        CloseDropDownMenus()
                        self:Refresh()
                    end,
                }, level)

                UIDropDownMenu_AddSeparator(level)

                for _, classDef in ipairs(BUILTIN_CLASS_TAGS) do
                    local cr, cg, cb = unpack(classDef.color)
                    local allOn = true
                    for _, spec in ipairs(classDef.specs) do
                        if not self.activeTags[spec] then allOn = false break end
                    end

                    UIDropDownMenu_AddButton({
                        text = classDef.class,
                        textR = cr, textG = cg, textB = cb,
                        hasArrow = true,
                        notCheckable = false,
                        checked = allOn,
                        keepShownOnClick = true,
                        menuList = classDef.class,
                        func = function()
                            local anyActive = false
                            for _, spec in ipairs(classDef.specs) do
                                if self.activeTags[spec] then anyActive = true break end
                            end
                            local newState = not anyActive
                            for _, spec in ipairs(classDef.specs) do
                                self.activeTags[spec] = newState
                            end
                            updateFilterButtonLabel(self)
                            self:Refresh()
                        end,
                    }, level)
                end

                if #extraTags > 0 then
                    UIDropDownMenu_AddSeparator(level)
                    for _, tag in ipairs(extraTags) do
                        UIDropDownMenu_AddButton({
                            text = tag,
                            isNotRadio = true,
                            keepShownOnClick = true,
                            checked = self.activeTags[tag] == true,
                            func = function()
                                self.activeTags[tag] = not self.activeTags[tag]
                                updateFilterButtonLabel(self)
                                self:Refresh()
                            end,
                        }, level)
                    end
                end

            elseif level == 2 and menuList then
                for _, classDef in ipairs(BUILTIN_CLASS_TAGS) do
                    if menuList == classDef.class then
                        local cr, cg, cb = unpack(classDef.color)
                        for _, spec in ipairs(classDef.specs) do
                            UIDropDownMenu_AddButton({
                                text = spec,
                                textR = cr, textG = cg, textB = cb,
                                isNotRadio = true,
                                keepShownOnClick = true,
                                checked = self.activeTags[spec] == true,
                                func = function()
                                    self.activeTags[spec] = not self.activeTags[spec]
                                    updateFilterButtonLabel(self)
                                    self:Refresh()
                                end,
                            }, level)
                        end
                        break
                    end
                end
            end
        end)
    end)

    --------------------------------------------------------
    -- Highest rank toggle
    --------------------------------------------------------
    self.rankBtn:SetOnClick(function()
        self.highestOnly = not self.highestOnly
        self.rankBtn:SetText("Show Highest Rank: " .. (self.highestOnly and "ON" or "OFF"))
        self:Refresh()
    end)

    --------------------------------------------------------
    -- Spell grid
    --------------------------------------------------------
    self.grid = VGroup:New("RPE_SpellbookGrid", {
        parent  = self.sheet,
        width   = 1,
        height  = 1,
        spacingY = 4,
        alignH  = "LEFT", -- restore original left alignment
        autoSize = true,
        padding = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    self.sheet:Add(self.grid)

    local count = 1
    for r = 1, self.rows do
        local row = HGroup:New(("RPE_SpellbookRow_%d"):format(r), {
            parent = self.grid,
            spacingX = 4, alignV = "CENTER", autoSize = true,
        })
        self.grid:Add(row)
        for c = 1, self.cols do
            local idx = (r - 1) * self.cols + c
            local slot = SpellbookSlot:New(("RPE_SpellSlot_%d"):format(idx), {width = 40, height = 40})
            self.slots[count] = slot
            count = count + 1
            row:Add(slot)
        end
    end
end

------------------------------------------------------------
function SpellbookSheet:Refresh()
    local profile = RPE.Profile.DB:GetOrCreateActive()
    local reg     = RPE.Core and RPE.Core.SpellRegistry
    local useRanks = (RPE.ActiveRules:Get("use_spell_ranks") or 1) ~= 0
    local known   = profile.spells or {}

    local spellList, hasFilters = {}, next(self.activeTags) ~= nil

    for spellId, rank in pairs(known) do
        local def = reg and reg.Get and reg:Get(spellId)
        if def then
            local passes = true
            if hasFilters then
                passes = false
                if def.tags then
                    for _, t in ipairs(def.tags) do
                        if self.activeTags[t] then passes = true break end
                    end
                end
            end
            if passes then
                local icon = def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
                if useRanks and not self.highestOnly then
                    local maxRank = math.min(rank, tonumber(def.maxRanks or 1) or 1)
                    for r = 1, maxRank do
                        table.insert(spellList, {
                            id = spellId, rank = r,
                            name = (def.name or spellId) .. " (Rank " .. r .. ")",
                            icon = icon, def = def,
                        })
                    end
                else
                    table.insert(spellList, {id = spellId, rank = rank, name = def.name or spellId, icon = icon, def = def})
                end
            end
        end
    end

    table.sort(spellList, function(a,b)
        if a.name == b.name then return (a.rank or 1) < (b.rank or 1) end
        return a.name < b.name
    end)

    for i, slot in ipairs(self.slots) do
        local entry = spellList[i]
        if entry then
            slot:SetSpell(entry)
            slot:SetName(""); slot:SetSubtitle("")
        else
            slot:ClearSpell(); slot:SetName(""); slot:SetSubtitle("")
        end
    end
end

function SpellbookSheet.New(opts)
    local self = setmetatable({}, SpellbookSheet)
    self:BuildUI(opts or {})
    return self
end

return SpellbookSheet
