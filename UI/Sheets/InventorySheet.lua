-- RPE_UI/Windows/InventorySheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.ActiveRules = RPE.ActiveRules

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local FrameElement = RPE_UI.Elements.FrameElement

-- Prefabs
local InventorySlot = RPE_UI.Prefabs.InventorySlot

---@class InventorySheet
---@field Name string
---@field root Window
---@field grid VGroup
---@field slots InventorySlot[]
local InventorySheet = {}
_G.RPE_UI.Windows.InventorySheet = InventorySheet
InventorySheet.__index = InventorySheet
InventorySheet.Name = "InventorySheet"

-- Expose under RPE.Core.Windows too
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.InventorySheet = self
end

--- Build UI
---@param opts table
function InventorySheet:BuildUI(opts)
    opts = opts or {}
    self.rows = opts.rows or 6
    self.cols = opts.cols or 8
    self.slots = {}

    self.sheet = VGroup:New("RPE_ES_Sheet", {
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

    self.grid = VGroup:New("RPE_InventoryGrid", {
        parent  = self.sheet,
        width   = 1,
        height  = 1,
        spacingY = 4,
        alignH  = "CENTER",
        autoSize = true,
        padding = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    local count = 1
    for r = 1, self.rows do
        local row = HGroup:New(("RPE_InventoryRow_%d"):format(r), {
            parent = self.grid,
            spacingX = 4,
            alignV   = "CENTER",
            autoSize = true,
        })
        self.grid:Add(row)

        for c = 1, self.cols do
            local slotIndex = (r - 1) * self.cols + c
            local slot = InventorySlot:New(("RPE_InvSlot_%d"):format(slotIndex), {
                width = 40, height = 40, noBorder = true
            })
            self.slots[count] = slot
            count = count + 1
            row:Add(slot)
        end
    end

    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function InventorySheet:Refresh()
    local inventory = Common:GetInventory() or {}

    -- Clear all slots first
    for i, slot in ipairs(self.slots) do
        slot:SetItem(nil)
    end

    -- Fill with current inventory (slot array)
    local count = 1
    for _, entry in ipairs(inventory) do
        if entry.id and entry.qty and entry.qty > 0 then
            if self.slots[count] then
                self.slots[count]:SetItem(entry.id, entry.qty)
            end
            count = count + 1
        end
    end
end


function InventorySheet.New(opts)
    local self = setmetatable({}, InventorySheet)
    self:BuildUI(opts or {})
    return self
end

return InventorySheet
