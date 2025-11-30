-- RPE_UI/Windows/CharacterSheet.lua
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

--- Rebuild all stat sections (full refresh)
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

    section("Skills",            "SKILL",        3)
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