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
    o.instanceGuid = opts.instanceGuid  -- Instance GUID for this equipped item (for modifications)
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
            -- Live registry item → render full tooltip with instance GUID if available
            RPE.Common:ShowTooltip(self, item:ShowTooltip(o.instanceGuid))
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

    -- Right-click to open context menu
    f:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" and o.itemId then
            local reg  = RPE.Core and RPE.Core.ItemRegistry
            local item = reg and reg.Get and reg:Get(o.itemId) or nil
            if item then
                EquipmentSlot:ShowItemContextMenu(o, item)
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
function EquipmentSlot:SetInstanceGuid(guid) self.instanceGuid = guid end
function EquipmentSlot:GetInstanceGuid() return self.instanceGuid end

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

function EquipmentSlot:ShowItemContextMenu(slot, item)
    -- Safety: only build a menu if the item still exists in the registry
    local reg = RPE.Core and RPE.Core.ItemRegistry
    local live = reg and reg.Get and reg:Get(item and item.id) or nil
    if not live then
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("Item not available in active datasets; no actions available.")
        end
        return
    end

    RPE_UI.Common:ContextMenu(slot.frame, function(level)
        if level ~= 1 then return end

        -- Title
        local info = UIDropDownMenu_CreateInfo()
        info.isTitle = true; info.notCheckable = true
        info.text = item.name or item.id
        UIDropDownMenu_AddButton(info, level)

        -- Unequip option
        UIDropDownMenu_AddButton({
            text = "Unequip",
            func = function()
                local check = reg and reg:Get(item.id)
                if not check then
                    if RPE and RPE.Debug and RPE.Debug.Warning then
                        RPE.Debug:Warning("Item not available in active datasets; cannot unequip.")
                    end
                    return
                end
                if check.data and check.data.slot then
                    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
                    if profile and profile.Unequip then
                        profile:Unequip(check.data.slot)
                    end
                end
            end,
            notCheckable = true
        }, level)

        -- Use option (for items with spells, regardless of category)
        if item.spellId then
            UIDropDownMenu_AddButton({
                text = "Use",
                func = function()
                    local check = reg and reg:Get(item.id)
                    if not check then
                        if RPE and RPE.Debug and RPE.Debug.Warning then
                            RPE.Debug:Warning("Item not available in active datasets; cannot use.")
                        end
                        return
                    end
                    
                    -- Use: cast spell using the full SpellCast system
                    local SR = RPE.Core and RPE.Core.SpellRegistry
                    local SC = RPE.Core and RPE.Core.SpellCast
                    if not (SR and SC) then return end
                    
                    local spell = SR:Get(check.spellId)
                    if not spell then 
                        if RPE and RPE.Debug then
                            RPE.Debug:Warning("Spell not found in registry: "..tostring(check.spellId))
                        end
                        return 
                    end
                    
                    local event = RPE.Core.ActiveEvent
                    if not event then return end
                    
                    -- Get player's numeric ID from event
                    local casterId = event.localPlayerKey
                    
                    -- Create cast object
                    local cast = SC.New(check.spellId, casterId, check.spellRank or 1)
                    
                    -- Build context
                    local ctx = {
                        event = event,
                        resources = RPE.Core.Resources,
                        cooldowns = RPE.Core.Cooldowns,
                    }
                    
                    -- Validate and execute
                    local ok, reason = cast:Validate(ctx)
                    if not ok then
                        if RPE and RPE.Debug and RPE.Debug.Warning then
                            RPE.Debug:Warning("Cannot cast: " .. (reason or ""))
                        end
                        return
                    end
                    
                    -- Handle targeting
                    local defaultTargeter = spell.targeter and spell.targeter.default
                    if defaultTargeter == "CASTER" or defaultTargeter == "SELF" or defaultTargeter == "ALL_ALLIES" or defaultTargeter == "ALL_ENEMIES" or defaultTargeter == "ALL_UNITS" then
                        -- Self-targeting spell, execute immediately
                        cast.targetSets = cast.targetSets or {}
                        local tgtKey = (defaultTargeter == "SELF") and "CASTER" or defaultTargeter
                        local sel = RPE.Core.Targeters and RPE.Core.Targeters:Select(tgtKey, ctx, cast, {})
                        
                        if sel and sel.targets and #sel.targets > 0 then
                            cast.targetSets.precast = sel.targets
                        else
                            cast.targetSets.precast = { casterId }
                        end
                        
                        cast:FinishTargeting(ctx)
                    else
                        -- Requires targeting
                        cast:InitTargeting()
                        cast:RequestNextTargetSet(ctx)
                    end
                end,
                notCheckable = true
            }, level)
        end
    end)
end

return EquipmentSlot
