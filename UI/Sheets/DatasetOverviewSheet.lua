-- RPE_UI/Windows/DatasetOverviewSheet.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.Windows = RPE.Core.Windows or {}

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local HGroup  = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup  = RPE_UI.Elements.VerticalLayoutGroup
local Text    = RPE_UI.Elements.Text
local TextBtn = RPE_UI.Elements.TextButton

---@class DatasetOverviewSheet
---@field Name string
---@field sheet any
---@field header any
---@field body any
---@field leftCol any
---@field rightCol any
---@field leftList any
---@field rightList any
---@field countText any
local DatasetOverviewSheet = {}
_G.RPE_UI.Windows.DatasetOverviewSheet = DatasetOverviewSheet
DatasetOverviewSheet.__index = DatasetOverviewSheet
DatasetOverviewSheet.Name = "DatasetOverviewSheet"

-- Build UI -------------------------------------------------------------------
function DatasetOverviewSheet:BuildUI(opts)
    -- Root sheet (match StatisticSheet style)
    self.sheet = VGroup:New("RPE_DSO_Sheet", {
        parent   = opts.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP",
        x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV   = "TOP",
        alignH   = "CENTER",
        autoSize = true,
    })

    -- Header row
    self.header = HGroup:New("RPE_DSO_Header", {
        parent   = self.sheet,
        width    = 600, height = 28,
        spacingX = 12,
        alignV   = "CENTER",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.header)

    local title = Text:New("RPE_DSO_Title", {
        parent = self.header,
        text = "Datasets Overview",
        fontTemplate = "GameFontNormalLarge",
        justifyH = "LEFT",
        textPoint = "LEFT", textRelativePoint = "LEFT",
    })
    self.header:Add(title)

    self.countText = Text:New("RPE_DSO_Count", {
        parent = self.header,
        text = "Active: 0 / 0",
        fontTemplate = "GameFontNormalSmall",
        justifyH = "LEFT",
        textPoint = "LEFT", textRelativePoint = "LEFT",
    })
    self.header:Add(self.countText)

    -- Body: two columns
    self.body = HGroup:New("RPE_DSO_Body", {
        parent   = self.sheet,
        width    = 600, height = 1,
        spacingX = 48,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    self.sheet:Add(self.body)

    -- Left (Active)
    self.leftCol = VGroup:New("RPE_DSO_ActiveCol", {
        parent   = self.body,
        width    = 1, height = 1,
        spacingY = 8,
        alignH   = "LEFT",
        autoSize = true,
    })
    self.body:Add(self.leftCol)

    local leftTitle = Text:New("RPE_DSO_ActiveTitle", {
        parent = self.leftCol,
        text   = "Active",
        fontTemplate = "GameFontNormalSmall",
        justifyH = "LEFT",
        textPoint = "LEFT", textRelativePoint = "LEFT",
    })
    self.leftCol:Add(leftTitle)

    self.leftList = VGroup:New("RPE_DSO_ActiveList", {
        parent   = self.leftCol,
        width    = 1, height = 1,
        spacingY = 6,
        alignH   = "LEFT",
        autoSize = true,
    })
    self.leftCol:Add(self.leftList)

    -- Right (Inactive)
    self.rightCol = VGroup:New("RPE_DSO_InactiveCol", {
        parent   = self.body,
        width    = 1, height = 1,
        spacingY = 8,
        alignH   = "LEFT",
        autoSize = true,
    })
    self.body:Add(self.rightCol)

    local rightTitle = Text:New("RPE_DSO_InactiveTitle", {
        parent = self.rightCol,
        text   = "Inactive",
        fontTemplate = "GameFontNormalSmall",
        justifyH = "LEFT",
        textPoint = "LEFT", textRelativePoint = "LEFT",
    })
    self.rightCol:Add(rightTitle)

    self.rightList = VGroup:New("RPE_DSO_InactiveList", {
        parent   = self.rightCol,
        width    = 1, height = 1,
        spacingY = 6,
        alignH   = "LEFT",
        autoSize = true,
    })
    self.rightCol:Add(self.rightList)

    self:Refresh()
end

-- Refresh lists --------------------------------------------------------------
function DatasetOverviewSheet:Refresh()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    local all = (DB and DB.ListNames and DB.ListNames()) or {}
    table.sort(all, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
    local active = (DB and DB.GetActiveNamesForCurrentCharacter and DB.GetActiveNamesForCurrentCharacter()) or {}

    local activeSet = {}
    for _, n in ipairs(active) do activeSet[n] = true end

    -- Split
    local inactive = {}
    for _, n in ipairs(all) do
        if not activeSet[n] then table.insert(inactive, n) end
    end

    -- Update header count
    if self.countText and self.countText.SetText then
        self.countText:SetText(string.format("Active: %d / %d", #active, #all))
    end

    -- Wipe lists
    for _, ch in ipairs(self.leftList.children or {})  do if ch.Destroy then ch:Destroy() end end
    for _, ch in ipairs(self.rightList.children or {}) do if ch.Destroy then ch:Destroy() end end
    self.leftList.children, self.rightList.children = {}, {}

    -- Row builder: label + toggle button
    local function addRow(parent, name, makeActive)
        local row = HGroup:New(("RPE_DSO_Row_%s"):format(name), {
            parent   = parent,
            width    = 1, height = 24,
            spacingX = 8,
            alignV   = "CENTER",
            alignH   = "LEFT",
            autoSize = true,
        })
        parent:Add(row)

        local label = Text:New(("RPE_DSO_Label_%s"):format(name), {
            parent = row,
            text   = tostring(name),
            justifyH = "LEFT",
            textPoint = "LEFT", textRelativePoint = "LEFT",
            width  = 260, height = 16,
        })
        row:Add(label)

        local btn = TextBtn:New(("RPE_DSO_Toggle_%s"):format(name), {
            parent = row,
            width  = 110, height = 22,
            text   = makeActive and "Activate" or "Deactivate",
            noBorder = true, hasBorder = false,
            onClick = function()
                if not DB then return end
                if makeActive and DB.AddActive then
                    DB.AddActive(name)
                elseif (not makeActive) and DB.RemoveActive then
                    DB.RemoveActive(name)
                end
                local ds = DB.LoadActiveForCurrentCharacter and DB.LoadActiveForCurrentCharacter()
                if ds and ds.ApplyToRegistries then pcall(function() ds:ApplyToRegistries() end) end

                -- Nudge window header if present
                local win = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                if win and win.UpdateHeader then win:UpdateHeader() end

                self:Refresh()
            end
        })
        row:Add(btn)
    end

    -- Left = Active
    for _, n in ipairs(active) do addRow(self.leftList, n, false) end
    -- Right = Inactive
    for _, n in ipairs(inactive) do addRow(self.rightList, n, true) end

    if self.sheet.Relayout then self.sheet:Relayout() end
end

function DatasetOverviewSheet.New(opts)
    local self = setmetatable({}, DatasetOverviewSheet)
    self:BuildUI(opts or {})
    return self
end

return DatasetOverviewSheet
