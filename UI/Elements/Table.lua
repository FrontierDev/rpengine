-- RPE_UI/Elements/Table.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class Table: FrameElement
---@field frame Frame
---@field root FrameElement
---@field rows Frame[]
---@field columns table[]
---@field data table[]
---@field sortFn fun(a:table,b:table):boolean
---@field rowOnClick fun(rowFrame:Frame,rowData:table,button:string)|nil
local Table = setmetatable({}, { __index = FrameElement })
Table.__index = Table
RPE_UI.Elements.Table = Table

---@param name string
---@param opts table
function Table:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "Table:New requires opts.parent")

    local f = CreateFrame("Frame", name, opts.parent.frame)
    f:SetSize(opts.width or 300, opts.height or 200)

    ---@type Table
    local o = FrameElement.New(self, "Table", f, opts.parent)
    o.root          = o
    o.rows          = {}
    o.columns       = {}
    o.data          = {}
    o.sortFn        = nil
    o.rowOnClick    = nil
    o.headerSpacingX= opts.headerSpacingX or 12
    o.rowHeight     = opts.rowHeight or 20
    o.cellPadX      = opts.cellPadX or 6

    return o
end

function Table:SetColumns(cols)
    self.columns = cols or {}
    -- clear old headers if any
    if self.headers then
        for _, h in ipairs(self.headers) do h:Hide() end
    end
    self.headers = {}

    local x = 0
    for _, col in ipairs(self.columns) do
        local headerText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x + self.cellPadX, 0)
        headerText:SetWidth(col.width or 80)
        headerText:SetJustifyH("LEFT")
        headerText:SetText(col.title or col.key)
        table.insert(self.headers, headerText)

        x = x + (col.width or 80) + self.headerSpacingX
    end
end

function Table:SetRows(rows)
    self.data = rows or {}
    if self.sortFn then table.sort(self.data, self.sortFn) end
end

function Table:SetSort(fn) self.sortFn = fn end
function Table:SetRowOnClick(fn) self.rowOnClick = fn end

function Table:Refresh()
    -- clear old rows
    for _, row in ipairs(self.rows) do
        row:Hide()
        row:SetParent(nil)
    end
    self.rows = {}

    local yOffset = -20 -- leave space for header row
    for i, rowData in ipairs(self.data) do
        local rowFrame = CreateFrame("Button", nil, self.frame)
        rowFrame:SetHeight(self.rowHeight)
        rowFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, yOffset)
        rowFrame:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)
        yOffset = yOffset - self.rowHeight

        -- alternating background
        if i % 2 == 0 then
            rowFrame.bg = rowFrame:CreateTexture(nil, "BACKGROUND")
            rowFrame.bg:SetAllPoints()
            rowFrame.bg:SetColorTexture(0.12, 0.12, 0.16, 0.5)
        end

        rowFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        rowFrame:SetScript("OnClick", function(_, btn)
            if self.rowOnClick then self.rowOnClick(rowFrame, rowData, btn) end
        end)

        local x2 = 0
        for _, col in ipairs(self.columns) do
            local cell = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell:SetPoint("LEFT", rowFrame, "LEFT", x2 + self.cellPadX, 0)
            cell:SetWidth(col.width or 80)
            cell:SetJustifyH("LEFT")
            cell:SetText(rowData[col.key] or "")
            x2 = x2 + (col.width or 80) + self.headerSpacingX
        end

        table.insert(self.rows, rowFrame)
    end
end


return Table
