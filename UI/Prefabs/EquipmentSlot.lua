-- RPE_UI/Prefabs/EquipmentSlot.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local IconButton = RPE_UI.Elements.IconButton
local Text       = RPE_UI.Elements.Text

-- Pull quality colors from RPE.Common (fallback provided)
local QualityColors = (RPE and RPE.Common and RPE.Common.QualityColors) or {
    common    = { r = 1.00, g = 1.00, b = 1.00 },
    uncommon  = { r = 0.12, g = 1.00, b = 0.00 },
    rare      = { r = 0.00, g = 0.44, b = 0.87 },
    epic      = { r = 0.64, g = 0.21, b = 0.93 },
    legendary = { r = 1.00, g = 0.50, b = 0.00 },
}

---@class EquipmentSlot: IconButton
---@field bg Texture
---@field borderTex Texture
---@field qBorder table
---@field name Text
---@field subtitle Text
---@field qty Text
---@field itemId any|nil
---@field quality string|nil
---@field quantity integer|nil
---@field glow any
local EquipmentSlot = setmetatable({}, { __index = IconButton })
EquipmentSlot.__index = EquipmentSlot
RPE_UI.Prefabs.EquipmentSlot = EquipmentSlot

-- ===== Dataset fallback helpers ============================================

-- Find item data in ANY dataset (active or inactive) to render icon/rarity/tooltip
local function _findItemInAnyDataset(itemId)
    local sv = _G.RPEngineDatasetDB
    if not (sv and sv.datasets) then return nil end
    for _, ds in pairs(sv.datasets) do
        local items = ds and ds.items
        if items then
            local v = items[itemId] or items[tostring(itemId)]
            if not v then
                for k, vv in pairs(items) do
                    if tostring(k) == tostring(itemId) then v = vv; break end
                end
            end
            if v then return v end
        end
    end
    return nil
end

function EquipmentSlot:New(name, opts)
    opts = opts or {}
    opts.width  = opts.width  or 48
    opts.height = opts.height or 48

    ---@type EquipmentSlot
    local o = IconButton.New(self, name, opts)
    local f = o.frame

    -- Background under icon
    if not o.bg then
        o.bg = f:CreateTexture(nil, "ARTWORK", nil, -1)
        o.bg:SetAllPoints()
    end
    o.bg:SetTexCoord(0, 1, 0, 1)
    o.bg:SetTexture(opts.bgTexture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")

    -- Hide IconButton's default horizontal borders
    if o.topBorder then o.topBorder:Hide() end
    if o.bottomBorder then o.bottomBorder:Hide() end

    -- Optional decorative overlay border
    o.borderTex = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    o.borderTex:SetAllPoints()
    if opts.borderTexture then
        o.borderTex:SetTexture(opts.borderTexture)
    else
        o.borderTex:Hide()
    end

    -- Quality border
    local t = opts.qualityBorderThickness or 2
    o.qBorder = {
        top    = f:CreateTexture(nil, "OVERLAY", nil, 2),
        bottom = f:CreateTexture(nil, "OVERLAY", nil, 2),
        left   = f:CreateTexture(nil, "OVERLAY", nil, 2),
        right  = f:CreateTexture(nil, "OVERLAY", nil, 2),
    }
    o.qBorder.top   :SetPoint("TOPLEFT",     f, "TOPLEFT",     0, 0)
    o.qBorder.top   :SetPoint("TOPRIGHT",    f, "TOPRIGHT",    0, 0)
    o.qBorder.top   :SetHeight(t)
    o.qBorder.bottom:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    o.qBorder.bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    o.qBorder.bottom:SetHeight(t)
    o.qBorder.left  :SetPoint("TOPLEFT",     f, "TOPLEFT",     0, 0)
    o.qBorder.left  :SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    o.qBorder.left  :SetWidth(t)
    o.qBorder.right :SetPoint("TOPRIGHT",    f, "TOPRIGHT",    0, 0)
    o.qBorder.right :SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    o.qBorder.right :SetWidth(t)
    o.qBorder.top:Hide(); o.qBorder.bottom:Hide(); o.qBorder.left:Hide(); o.qBorder.right:Hide()

    -- Optional labels
    o.name = Text:New(name .. "_Name", {
        parent = o,
        fontTemplate = "GameFontHighlightSmall",
        textPoint = "TOP",
        textY = -2,
        text = opts.nameText or nil,
    })
    o.name:SetAllPoints(o.frame)
    if not opts.nameText then o.name:Hide() end

    o.subtitle = Text:New(name .. "_Subtitle", {
        parent = o,
        fontTemplate = "GameFontNormalSmall",
        textPoint = "BOTTOM",
        textY = 2,
        text = opts.subtitleText or nil,
    })
    o.subtitle:SetAllPoints(o.frame)
    if not opts.subtitleText then o.subtitle:Hide() end

    -- Quantity label
    o.qty = Text:New(name .. "_Qty", {
        parent = o,
        fontTemplate = "GameFontHighlightSmall",
        textPoint = "BOTTOMRIGHT",
        textX = -2, textY = 2,
        text = nil,
    })
    o.qty:SetAllPoints(o.frame)
    o.qty:Hide()

    -- Item state
    o.itemId   = opts.itemId
    o.quality  = opts.quality
    o.quantity = opts.quantity or 1

    if not opts.icon then o.icon:SetTexture(nil) end
    if o.quality and o.icon:GetTexture() then
        o:SetQuality(o.quality)
    end
    o:SetQuantity(o.quantity)

    -- Hover glow
    o.glow = f:CreateTexture(nil, "OVERLAY")
    o.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    o.glow:SetBlendMode("ADD")
    o.glow:SetAlpha(0.8)
    o.glow:SetSize(o.frame:GetWidth() * 1.8, o.frame:GetHeight() * 1.8)
    o.glow:SetPoint("CENTER", o.frame, "CENTER")
    o.glow:Hide()

    -- Tooltip with dataset fallback
    f:HookScript("OnEnter", function(self)
        o.glow:Show()
        if not o.itemId then
            return
        end

        local reg  = RPE.Core and RPE.Core.ItemRegistry
        local item = reg and reg.Get and reg:Get(o.itemId) or nil

        if item and item.ShowTooltip and RPE and RPE.Common and RPE.Common.ShowTooltip then
            RPE.Common:ShowTooltip(self, item:ShowTooltip())
        else
            -- Fallback minimal tooltip
            local display = nil
            local dsItem = _findItemInAnyDataset(o.itemId)
            if dsItem and dsItem.name then display = dsItem.name end
            display = display or tostring(o.itemId)

            if RPE and RPE.Common and RPE.Common.ShowTooltip then
                RPE.Common:ShowTooltip(self, {
                    title = display,
                    titleColor = {0.7, 0.7, 0.7},
                    lines = {
                        { text = "This item is not part of your active data.", r = 1, g = 0.25, b = 0.25, wrap = false },
                    },
                })
            end
        end
    end)

    -- Right-click to unequip (if item specifies a slot)
    f:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" and o.itemId then
            local reg  = RPE.Core and RPE.Core.ItemRegistry
            local item = reg and reg.Get and reg:Get(o.itemId) or nil
            if item and item.data and item.data.slot then
                local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
                if profile and profile.Unequip then
                    profile:Unequip(item.data.slot)
                end
            end
        end
    end)

    f:HookScript("OnLeave", function()
        o.glow:Hide()
        if RPE and RPE.Common and RPE.Common.HideTooltip then
            RPE.Common:HideTooltip()
        end
        if GameTooltip and GameTooltip:IsOwned(f) then
            GameTooltip:Hide()
        end
    end)

    return o
end

-- =========================
-- Public API
-- =========================

function EquipmentSlot:SetBackground(path)
    if self.bg then
        self.bg:SetTexture(path or nil)  -- fixed: self.bgTex -> self.bg
    end
end

function EquipmentSlot:SetBorder(path)
    if path then
        self.borderTex:SetTexture(path)
        self.borderTex:Show()
    else
        self.borderTex:SetTexture(nil)
        self.borderTex:Hide()
    end
end

---Sets the item icon (nil clears). Also refreshes quality border visibility.
function EquipmentSlot:SetItemIcon(path)
    self:SetIcon(path)
    if not path then
        self:ShowQualityBorder(false)
    elseif self.quality then
        self:SetQuality(self.quality)
    end
end

function EquipmentSlot:SetItemId(id) self.itemId = id end
function EquipmentSlot:GetItemId()   return self.itemId end

---Convenience: set the slot's item.
---Accepts either:
---  1) id (string/number) -> lookup in ItemRegistry
---  2) table { id, icon, name?, rarity? } -> direct preview (no registry)
---@param id any|string|number|table
---@param quantity integer|nil
function EquipmentSlot:SetItem(id, quantity)
    if type(id) == "table" then
        local data = id
        self.itemId = data.id
        self:SetItemIcon(data.icon or nil)
        self:SetQuality(data.rarity or nil)
        self:SetQuantity(quantity or 1)
        return
    end

    self.itemId = id
    local reg  = RPE.Core and RPE.Core.ItemRegistry
    local item = reg and reg.Get and reg:Get(id) or nil

    if item then
        self:SetItemIcon(item.icon)
        self:SetQuality(item.rarity)
    else
        -- fallback: look in any dataset so the slot still shows something
        local dsItem = _findItemInAnyDataset and _findItemInAnyDataset(id)
        if dsItem and dsItem.icon then
            self:SetItemIcon(dsItem.icon)
            self.quality = nil                         -- grey border (not active)
            self:SetQualityBorderColor(0.5, 0.5, 0.5, 1)
            self:ShowQualityBorder(true)
        else
            self:SetItemIcon(nil)
            self:SetQuality(nil)
        end
    end

    self:SetQuantity(quantity or 1)
end


function EquipmentSlot:ClearItem()
    self.itemId  = nil
    self.quality = nil
    self.quantity = 1
    self:SetIcon(nil)
    self:ShowQualityBorder(false)
    if self.qty then self.qty:Hide() end
end

---Set the quality border color by quality key (case-insensitive). Pass nil to hide.
function EquipmentSlot:SetQuality(qualityKey)
    self.quality = qualityKey
    local qc = nil
    if type(qualityKey) == "string" then
        qc = QualityColors[qualityKey] or QualityColors[qualityKey:lower()]
    end
    if qc and self.icon:GetTexture() then
        self:SetQualityBorderColor(qc.r or 1, qc.g or 1, qc.b or 1, 1)
        self:ShowQualityBorder(true)
    else
        self:ShowQualityBorder(false)
    end
end

---Set the stack quantity. Shows label only if > 1.
function EquipmentSlot:SetQuantity(qty)
    qty = tonumber(qty) or 1
    self.quantity = qty
    if not self.qty then return end
    if qty > 1 then
        self.qty:SetText(tostring(qty))
        self.qty:Show()
    else
        self.qty:SetText("")
        self.qty:Hide()
    end
end

---Optional labels
function EquipmentSlot:SetName(text)
    if not self.name then return end
    if text and text ~= "" then
        self.name:SetText(text)
        self.name:Show()
    else
        self.name:SetText("")
        self.name:Hide()
    end
end

function EquipmentSlot:SetSubtitle(text)
    if not self.subtitle then return end
    if text and text ~= "" then
        self.subtitle:SetText(text)
        self.subtitle:Show()
    else
        self.subtitle:SetText("")
        self.subtitle:Hide()
    end
end

-- =========================
-- Internal helpers
-- =========================
function EquipmentSlot:ShowQualityBorder(show)
    local qb = self.qBorder
    if not qb then return end
    if show then
        qb.top:Show(); qb.bottom:Show(); qb.left:Show(); qb.right:Show()
    else
        qb.top:Hide(); qb.bottom:Hide(); qb.left:Hide(); qb.right:Hide()
    end
end

function EquipmentSlot:SetQualityBorderColor(r, g, b, a)
    local qb = self.qBorder
    if not qb then return end
    qb.top:SetColorTexture(r, g, b, a or 1)
    qb.bottom:SetColorTexture(r, g, b, a or 1)
    qb.left:SetColorTexture(r, g, b, a or 1)
    qb.right:SetColorTexture(r, g, b, a or 1)
end

return EquipmentSlot
