-- RPE_UI/Windows/StatisticSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton

-- Prefabs
local CharacterPortrait = RPE_UI.Prefabs.CharacterPortrait
local StatEntry         = RPE_UI.Prefabs.StatEntry

local StatMods = assert(RPE.Core.StatModifiers, "StatModifiers required")

---@class StatisticSheet
---@field Name string
---@field root Window
---@field topGroup HGroup
---@field profile table
---@field entries table<string, any>
local StatisticSheet = {}
_G.RPE_UI.Windows.StatisticSheet = StatisticSheet
StatisticSheet.__index = StatisticSheet
StatisticSheet.Name = "StatisticSheet"

-- Expose under RPE.Core.Windows too (so external hooks can find it)
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.StatisticSheet = self
end

local function _asBucket(x)
    if type(x) == "table" then
        return {
            ADD       = tonumber(x.ADD)       or 0,
            PCT_ADD   = tonumber(x.PCT_ADD)   or 0,
            MULT      = (tonumber(x.MULT) and tonumber(x.MULT) ~= 0) and tonumber(x.MULT) or 1,
            FINAL_ADD = tonumber(x.FINAL_ADD) or 0,
        }
    end
    return { ADD = tonumber(x) or 0, PCT_ADD = 0, MULT = 1, FINAL_ADD = 0 }
end

-- given base and equip, compute how much the aura bucket changes the stat as a single number
local function _auraDeltaFor(bucket, baseValue, equipMods)
    local pre  = (baseValue or 0) + (equipMods or 0)
    local with = (pre + (bucket.ADD or 0))
    with = with * (1 + (bucket.PCT_ADD or 0) / 100)
    with = with * (bucket.MULT or 1)
    with = with + (bucket.FINAL_ADD or 0)
    return with - pre
end

-- Resolve a stat's base value without runtime mods
local function _resolveBaseForStat(profile, statId)
    if not profile or not profile.stats then return 0 end
    local total = 0
    for _, stat in pairs(profile.stats or {}) do
        if stat and stat.id == statId then
            if type(stat._resolveBase) == "function" then
                total = total + (stat:_resolveBase(profile) or 0)
            elseif type(stat.GetBase) == "function" then
                total = total + (stat:GetBase(profile) or 0)
            else
                total = total + (tonumber(stat.base) or 0)
            end
        end
    end
    return total
end

local function _equipFor(profile, statId)
    local pid = profile and profile.name
    if not (pid and StatMods and StatMods.equip and StatMods.equip[pid]) then return 0 end
    return tonumber(StatMods.equip[pid][statId]) or 0
end


local function getModSum(profile, statId)
    local pid        = profile and profile.name or nil
    local baseValue  = _resolveBaseForStat(profile, statId)
    local equipMods  = _equipFor(profile, statId)
    -- Sum setupBonus across all datasets
    local setupBonus = 0
    if profile and profile.stats then
        for _, stat in pairs(profile.stats) do
            if stat and stat.id == statId and tonumber(stat.setupBonus) then
                setupBonus = setupBonus + tonumber(stat.setupBonus)
            end
        end
    end
    local auraRaw    = (pid and StatMods.aura and StatMods.aura[pid] and StatMods.aura[pid][statId]) or 0
    local auraBucket = _asBucket(auraRaw)
    local auraDelta  = _auraDeltaFor(auraBucket, baseValue, equipMods)
    return setupBonus + (equipMods or 0) + (auraDelta or 0)
end


function StatisticSheet:BuildUI(opts)
    -- Defer profile access until needed - it may not be initialized yet
    self.profile = nil
    self.entries = {}

    -- Root window
    -- self.root = Window:New("RPE_SS_Window", {
    --     width = opts.width or 640,
    --     height = opts.height or 1,
    --     point = opts.point or "CENTER",
    --     x = opts.x or 0, y = opts.y or 0,
    --     autoSize     = true,
    --     autoSizePadX = 24,
    --     autoSizePadY = 24,
    -- })

    self.sheet = VGroup:New("RPE_SS_Sheet", {
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
    self:TopGroup()
    self.sheet:Add(self.topGroup)

    -- Body content (primary/melee/ranged/spell/resistances)
    self:BodyGroup()
    self.sheet:Add(self.bodyGroup)

    -- Register / expose
    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE.Debug:Internal("Registering StatisticSheet window...")
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function StatisticSheet:TopGroup()
    self.topGroup = HGroup:New("RPE_SS_TopGroup", {
        parent  = self.sheet,
        width   = 600,
        height  = 88,
        x       = 12, y = -12,
        spacingX = 12,
        alignV  = "CENTER",
        alignH  = "LEFT",
        autoSize = true,
    })

    -- Portrait
    self.portrait = CharacterPortrait:New("RPE_SS_Portrait", {
        parent = self.topGroup,
        width  = 64,
        height = 64,
        icon   = "Interface\\TargetingFrame\\UI-Player-portrait",
    })
    self.topGroup:Add(self.portrait)

    -- Name/guild block
    local nameBlock = VGroup:New("RPE_SS_NameBlock", {
        parent = self.topGroup,
        width  = 1,
        height = 1,
        spacingY = 12,
        alignH = "LEFT",
        autoSize = true,
    })
    self.topGroup:Add(nameBlock)

    self.charName = Text:New("RPE_SS_CharName", {
        parent = nameBlock,
        text   = "Character Name",
        fontTemplate = "GameFontNormalLarge",
        justifyH = "LEFT",
        textPoint = "LEFT", textRelativePoint = "LEFT",
    })
    RPE_UI.Colors.ApplyText(self.charName.fs, "text")
    nameBlock:Add(self.charName)

    self.guildName = Text:New("RPE_SS_GuildName", {
        parent = nameBlock,
        text   = "<Guild Name>",
        fontTemplate = "GameFontNormal",
        justifyH = "LEFT",
        textPoint = "LEFT", textRelativePoint = "LEFT",
    })
    RPE_UI.Colors.ApplyText(self.guildName.fs, "textMuted")
    nameBlock:Add(self.guildName)

    -- Resource row
    self.resourceBlock = HGroup:New("RPE_SS_ResourceBlock", {
        parent  = nameBlock,
        width   = 1,
        height  = 24,
        spacingX = 24,
        alignV  = "CENTER",
        alignH  = "LEFT",
        autoSize = true,
    })
    nameBlock:Add(self.resourceBlock)
    -- Don't populate stats here - defer until Refresh is called after PLAYER_LOGIN
end

function StatisticSheet:BodyGroup()
    self.bodyGroup = VGroup:New("RPE_SS_BodyGroup", {
        parent  = self.sheet,
        width   = 600,
        height  = 88,
        padding = { left = 0, right = 0, top = 8, bottom = 0 },
        alignV  = "CENTER",
        alignH  = "CENTER",
        autoSize = true,
    })

    local function section(title, key, columns)
        local titleText = Text:New("RPE_SS_Title_" .. key, {
            parent = self.bodyGroup,
            text   = title,
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(titleText.fs, "textMuted")
        self.bodyGroup:Add(titleText)

        local row = HGroup:New("RPE_SS_Row_" .. key, {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        self.bodyGroup:Add(row)
        -- Don't populate stats here - defer until Refresh is called after PLAYER_LOGIN
    end

    section("Attributes",       "PRIMARY",      3)
    section("Stats",            "SECONDARY",    3)
    section("Resistances",      "RESISTANCE",   3)
end

-- Draw stats of a given category into a container.
function StatisticSheet:DrawStats(statBlock, filter, columns)
    -- Get or create profile on first access
    if not self.profile then
        if not RPE then return end
        if not RPE.Profile then return end
        if not RPE.Profile.DB then return end
        self.profile = RPE.Profile.DB.GetOrCreateActive()
    end
    if not self.profile then return end

    -- Collect visible stats from all datasets (flat profile.stats with CharacterStat objects)
    local stats = {}
    local totalInCategory = 0
    local hiddenByVisibility = 0
    for _, stat in pairs(self.profile.stats or {}) do
        if stat and stat.category == filter then
            totalInCategory = totalInCategory + 1
            local isVisible = (stat.visible == nil or stat.visible == 1 or stat.visible == true)
            if not isVisible then
                hiddenByVisibility = hiddenByVisibility + 1
            end
            if isVisible then
                table.insert(stats, stat)
            end
        end
    end

    -- Clear old children
    for _, child in ipairs(statBlock.children or {}) do child:Destroy() end
    statBlock.children = {}

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
        local width    = math.max(120, math.floor((160 * 2) / colCount))

        local entry = StatEntry:New("RPE_SS_" .. stat.id, {
            parent   = parent,
            width    = width,
            height   = 24,
            icon     = icon,
            label    = stat.name or stat.id,
            modifier = text,
            stat     = stat,
        })

        -- ✅ Apply bonus/malus colors immediately
        local modSum = getModSum(self.profile, stat.id)

        if modSum > 0 then
            RPE_UI.Colors.ApplyText(entry.mod.fs, "textBonus")
        elseif modSum < 0 then
            RPE_UI.Colors.ApplyText(entry.mod.fs, "textMalus")
        else
            RPE_UI.Colors.ApplyText(entry.mod.fs, "text")
        end

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

    local container = HGroup:New("RPE_SS_" .. filter .. "_Cols", {
        parent  = statBlock,
        spacingX = 24,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    statBlock:Add(container)

    local cols = {}
    for c = 1, columns do
        local col = VGroup:New(("RPE_SS_%s_Col%d"):format(filter, c), {
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

-- Update only one stat row (targeted refresh)
function StatisticSheet:RefreshStat(statId)
    -- Get or create profile on first access
    if not self.profile and RPE.Profile and RPE.Profile.DB then
        self.profile = RPE.Profile.DB.GetOrCreateActive()
    end
    
    if not self.entries then return end
    local entry = self.entries[statId]
    if not entry then
        RPE.Debug:Error(string.format("Cannot refresh stat: %s", tostring(statId)))
        return
    end

    -- ✅ Get effective value (runtime first, fallback to profile)
    local val = 0
    if RPE and RPE.Stats and RPE.Stats.GetValue then
        val = RPE.Stats:GetValue(statId)
    elseif self.profile and self.profile.GetStatValue then
        val = self.profile:GetStatValue(statId)
    end

    -- ✅ Need stat meta for percentage and base reference
    local stat = nil
    if self.profile and self.profile.GetStat then
        stat = self.profile:GetStat(statId)
    else
        if self.profile and self.profile.stats then
            for _, st in pairs(self.profile.stats) do if st and st.id == statId then stat = st; break end end
        end
    end

    -- Format value string
    local text
    if stat and stat.IsPercentage and stat:IsPercentage() then
        text = string.format("%.1f%%", val)
    else
        if math.floor(val) == val then
            text = tostring(val)             -- integer
        else
            text = string.format("%.2f", val) -- float fallback
        end
    end
    entry:SetMod(text)

    -- ✅ Apply bonus/malus colors
    local modSum = getModSum(self.profile, statId)

    if modSum > 0 then
        RPE_UI.Colors.ApplyText(entry.mod.fs, "textBonus")
    elseif modSum < 0 then
        RPE_UI.Colors.ApplyText(entry.mod.fs, "textMalus")
    else
        RPE_UI.Colors.ApplyText(entry.mod.fs, "text")
    end
end



-- Update all displayed stats (bulk refresh)
function StatisticSheet:Refresh()
    -- Get or create profile on first access
    if not self.profile and RPE.Profile and RPE.Profile.DB then
        self.profile = RPE.Profile.DB.GetOrCreateActive()
    end
    
    if not self.profile or not self.bodyGroup then 
        return 
    end
    
    -- Update character name and guild from profile
    if self.charName and self.profile.name then
        self.charName:SetText(self.profile.name)
    end
    
    -- Try to get guild from WoW API (player's current guild)
    local guildName = GetGuildInfo("player")
    if self.guildName then
        self.guildName:SetText(guildName or "<No Guild>")
    end
    
    -- Populate the three sections in order: PRIMARY, SECONDARY, RESISTANCE
    local categories = { "PRIMARY", "SECONDARY", "RESISTANCE" }
    local rows = {}
    
    -- Collect only HGroup rows (skip Text titles)
    for _, child in ipairs(self.bodyGroup.children or {}) do
        if child.kind == "HorizontalLayoutGroup" then
            table.insert(rows, child)
        end
    end
    
    -- Populate each row with its corresponding category
    for i, category in ipairs(categories) do
        if rows[i] then
            self:DrawStats(rows[i], category, 3)
        end
    end
    
    -- Also populate RESOURCE stats in the resource block (in topGroup)
    if self.resourceBlock then
        self:DrawStats(self.resourceBlock, "RESOURCE", 2)
    end
end

-- Full rebuild (rarely needed; e.g., after resetting profile)
function StatisticSheet:RebuildAll()
    -- Get profile if not already loaded
    if not self.profile and RPE.Profile and RPE.Profile.DB then
        self.profile = RPE.Profile.DB.GetOrCreateActive()
    end
    
    -- wipe entries map; rebuild UI sections against current profile
    self.entries = {}
    -- Rebuild the resource row inside the top group
    -- (Simplest approach: rebuild the whole sheet content)
    for _, child in ipairs(self.sheet.children or {}) do child:Destroy() end
    self.sheet.children = {}

    self:TopGroup();  self.sheet:Add(self.topGroup)
    self:BodyGroup(); self.sheet:Add(self.bodyGroup)
    
    -- Now populate with stats - only PRIMARY, SECONDARY, RESISTANCE
    local function section(title, key, columns)
        local titleText = Text:New("RPE_SS_Title_" .. key, {
            parent = self.bodyGroup,
            text   = title,
            fontTemplate = "GameFontNormalSmall",
            justifyH = "CENTER",
            textPoint = "TOP", textRelativePoint = "TOP",
            width  = 1, height = 12, y = -12,
        })
        RPE_UI.Colors.ApplyText(titleText.fs, "textMuted")

        local row = HGroup:New("RPE_SS_Row_" .. key, {
            parent  = self.bodyGroup,
            spacingX = 24,
            alignV   = "TOP",
            alignH   = "LEFT",
            autoSize = true,
        })
        self.bodyGroup:Add(row)
        self:DrawStats(row, key, columns)
    end

    section("Attributes",       "PRIMARY",      3)
    section("Stats",            "SECONDARY",    3)
    section("Resistances",      "RESISTANCE",   3)
end

-- External hook: called by CharacterStat when a stat changes
function StatisticSheet.OnStatChanged(statId)
    local sheet = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.StatisticSheet
    if sheet and sheet.RefreshStat then
        sheet:Refresh(statId)
    end
end

--- Injects character data into the UI.
function StatisticSheet:SetCharacter(data)
    if not data then return end
    if data.name  then self.charName:SetText(data.name) end
    if data.guild then self.guildName:SetText(data.guild) end
end

function StatisticSheet.New(opts)
    local self = setmetatable({}, StatisticSheet)
    self:BuildUI(opts or {})
    -- Store as a global instance so other code can find it
    _G.RPE_UI.Windows.StatisticSheetInstance = self
    return self
end

return StatisticSheet
