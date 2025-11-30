-- RPE_UI/Prefabs/ShopItem.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local IconButton   = RPE_UI.Elements.IconButton
local Text         = RPE_UI.Elements.Text
local HGroup       = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup       = RPE_UI.Elements.VerticalLayoutGroup
local C            = RPE_UI.Colors

local Common   = RPE.Common or {}
local ItemReg  = RPE.Core and RPE.Core.ItemRegistry

---@class ShopItem: FrameElement
---@field icon IconButton
---@field name Text
---@field cost Text
---@field stack Text
local ShopItem = setmetatable({}, { __index = FrameElement })
ShopItem.__index = ShopItem
RPE_UI.Prefabs.ShopItem = ShopItem

function ShopItem:New(name, opts)
    opts = opts or {}
    assert(opts.parent, "ShopItem requires a parent")
    assert(opts.itemId, "ShopItem requires itemId")

    local width  = opts.width or 180
    local height = opts.height or 40

    local item = ItemReg and ItemReg:Get(opts.itemId)
    assert(item, "Invalid itemId passed to ShopItem: " .. tostring(opts.itemId))

    local frame = CreateFrame("Frame", name, opts.parent.frame or UIParent)
    frame:SetSize(width, height)

    local o = FrameElement.New(self, "ShopItem", frame, opts.parent)

    local group = HGroup:New(name .. "_HGroup", {
        parent = o,
        spacingX = 8,
        alignV = "CENTER",
        autoSize = true,
    })
    o:AddChild(group)

    -- === Icon ===
    o.icon = IconButton:New(name .. "_Icon", {
        parent = group,
        width = 32, height = 32,
        icon = item.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
    })

    o.icon.frame:SetScript("OnEnter", function(self)
        if not o.icon._locked and o.icon.icon and o.icon.icon.SetVertexColor then
            o.icon.icon:SetVertexColor(o.icon._hoverR, o.icon._hoverG, o.icon._hoverB, o.icon._hoverA)
        end

        Common:ShowTooltip(self, item:ShowTooltip())
    end)

    o.icon.frame:SetScript("OnLeave", function(self)
        Common:HideTooltip()
    end)

    o.icon.frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            local PDB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DB
            local profile = PDB and PDB.GetOrCreateActive()
            if not profile then
                return
            end

            profile:AddItem(item.id, 1)
        end
    end)

    group:Add(o.icon)

    -- === Stack count (bottom-right corner of icon) ===
    local qty = tonumber(opts.stack)
    if qty and qty > 1 and qty < math.huge then
        o.stack = Text:New(name .. "_StackText", {
            parent = o.icon,
            text = "(" .. qty .. ")",
            fontTemplate = "GameFontNormalOutline",
            color = { 1, 1, 1, 1 },
        })
        o.icon:AddChild(o.stack)
        o.stack.frame:SetPoint("BOTTOMRIGHT", o.icon.frame, "BOTTOMRIGHT", -2, 2)
    end

    -- === Texts (name + cost) ===
    local textGroup = VGroup:New(name .. "_TextGroup", {
        parent = group,
        alignH = "LEFT",
        spacingY = 2,
        autoSize = true,
    })
    group:Add(textGroup)

    o.name = Text:New(name .. "_Name", {
        parent = textGroup,
        text = Common:ColorByQuality(item.name or "(Item)", item.rarity or "common"),
        fontTemplate = "GameFontNormal",
        justifyH = "LEFT",
    })
    textGroup:Add(o.name)

    o.cost = Text:New(name .. "_Cost", {
        parent = textGroup,
        text = opts.cost or "—",
        fontTemplate = "GameFontNormalSmall",
        justifyH = "LEFT",
        color = { 0.9, 0.85, 0.3, 1 },
    })
    textGroup:Add(o.cost)

    return o
end

return ShopItem
