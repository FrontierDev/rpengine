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

            local price = tonumber(opts.price) or 0
            local maxStock = tonumber(opts.maxStock) or 1
            local stackable = item.stackable or false
            local mode = opts.mode or "buy"

            if mode == "buy" then
                -- BUY MODE: player buys from NPC
                if not stackable then
                    -- Non-stackable: check if player can afford, then add and deduct cost
                    local playerCopper = profile:GetCurrency("copper") or 0
                    if playerCopper >= price then
                        if profile:SpendCurrency("copper", price) then
                            profile:AddItem(item.id, 1)
                            PlaySound(120)
                            -- Refresh shop window
                            local shopWindow = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.ShopWindow
                            if shopWindow and shopWindow.Refresh then
                                shopWindow:Refresh()
                            end
                        end
                    end
                else
                    -- Stackable: show popup to ask for quantity
                    local Popup = RPE_UI.Prefabs.Popup
                    if not Popup then return end

                    local p = Popup.New({
                        title = "Buy " .. (item.name or "Item"),
                        text = "How many would you like to buy? (Max: " .. maxStock .. ")",
                        showInput = true,
                        defaultText = "1",
                        placeholder = "1-" .. maxStock,
                        primaryText = "Buy",
                        secondaryText = "Cancel",
                    })

                    p:SetCallbacks(function(text)
                        local qty = tonumber(text) or 1
                        qty = math.max(1, math.min(qty, maxStock))

                        local totalCost = price * qty
                        local playerCopper = profile:GetCurrency("copper") or 0

                        if playerCopper >= totalCost then
                            if profile:SpendCurrency("copper", totalCost) then
                                profile:AddItem(item.id, qty)
                                PlaySound(567428)
                                -- Refresh shop window
                                local shopWindow = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.ShopWindow
                                if shopWindow and shopWindow.Refresh then
                                    shopWindow:Refresh()
                                end
                            end
                        end
                    end, function()
                        -- Cancel: do nothing
                    end)

                    p:Show()
                end
            else
                -- SELL MODE: player sells to NPC
                if not stackable then
                    -- Non-stackable: sell 1 item
                    if profile:HasItem(item.id, 1) then
                        profile:RemoveItem(item.id, 1)
                        profile:AddCurrency("copper", price)
                        PlaySound(120)
                        -- Refresh shop window
                        local shopWindow = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.ShopWindow
                        if shopWindow and shopWindow.Refresh then
                            shopWindow:Refresh()
                        end
                    end
                else
                    -- Stackable: show popup to ask for quantity
                    local Popup = RPE_UI.Prefabs.Popup
                    if not Popup then return end

                    local playerQty = profile:GetItemQty(item.id) or 0
                    local maxSell = math.min(playerQty, maxStock)

                    local p = Popup.New({
                        title = "Sell " .. (item.name or "Item"),
                        text = "How many would you like to sell? (Max: " .. maxSell .. ")",
                        showInput = true,
                        defaultText = "1",
                        placeholder = "1-" .. maxSell,
                        primaryText = "Sell",
                        secondaryText = "Cancel",
                    })

                    p:SetCallbacks(function(text)
                        local qty = tonumber(text) or 1
                        qty = math.max(1, math.min(qty, maxSell))

                        local totalPrice = price * qty

                        if profile:HasItem(item.id, qty) then
                            profile:RemoveItem(item.id, qty)
                            profile:AddCurrency("copper", totalPrice)
                            PlaySound(567428)
                            -- Refresh shop window
                            local shopWindow = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.ShopWindow
                            if shopWindow and shopWindow.Refresh then
                                shopWindow:Refresh()
                            end
                        end
                    end, function()
                        -- Cancel: do nothing
                    end)

                    p:Show()
                end
            end
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

    -- In sell mode, use plain name; in buy mode use quality color
    local nameText
    if opts.mode == "sell" then
        nameText = item.name or "(Item)"
    else
        nameText = Common:ColorByQuality(item.name or "(Item)", item.rarity or "common")
    end

    o.name = Text:New(name .. "_Name", {
        parent = textGroup,
        text = nameText,
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
