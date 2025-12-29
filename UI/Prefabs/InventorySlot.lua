-- RPE_UI/Prefabs/InventorySlot.lua
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

---@class InventorySlot: IconButton
---@field bgTex Texture
---@field borderTex Texture
---@field qBorder table
---@field name Text
---@field subtitle Text
---@field qty Text
---@field itemId any|nil
---@field quality string|nil
---@field quantity integer|nil
---@field glow any
---@field context string|nil
local InventorySlot = setmetatable({}, { __index = IconButton })
InventorySlot.__index = InventorySlot
RPE_UI.Prefabs.InventorySlot = InventorySlot

-- ===== Dataset fallback helpers ============================================

-- Find item data in ANY dataset (active or inactive) to render icon/rarity/tooltip
local function _findItemInAnyDataset(itemId)
    local sv = _G.RPEngineDatasetDB
    if not (sv and sv.datasets) then return nil end
    for _, ds in pairs(sv.datasets) do
        local items = ds and ds.items
        if items then
            local direct = items[itemId]
            if direct then return direct end
            local asStr  = items[tostring(itemId)]
            if asStr then return asStr end
            for k, v in pairs(items) do
                if tostring(k) == tostring(itemId) then
                    return v
                end
            end
        end
    end
    return nil
end

-- ===== Component ============================================================

function InventorySlot:New(name, opts)
    opts = opts or {}
    opts.width  = opts.width  or 48
    opts.height = opts.height or 48

    ---@type InventorySlot
    local o = IconButton.New(self, name, opts)
    local f = o.frame

    -- Ensure background always sits directly beneath the icon
    if not o.bg then
        o.bg = f:CreateTexture(nil, "ARTWORK", nil, -1)
        o.bg:SetAllPoints()
    end
    o.bg:SetTexCoord(0, 1, 0, 1)
    o.bg:SetTexture(opts.bgTexture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")

    -- Hide IconButton's default horizontal borders
    if o.topBorder then o.topBorder:Hide() end
    if o.bottomBorder then o.bottomBorder:Hide() end

    -- Optional decorative image border (atlas/art). Hidden unless provided.
    o.borderTex = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    o.borderTex:SetAllPoints()
    if opts.borderTexture then
        o.borderTex:SetTexture(opts.borderTexture)
    else
        o.borderTex:Hide()
    end

    -- Quality border (solid color lines around the icon). Hidden by default.
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

    -- Start hidden
    o.qBorder.top:Hide(); o.qBorder.bottom:Hide(); o.qBorder.left:Hide(); o.qBorder.right:Hide()

    -- Labels (available but hidden unless set)
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

    -- Quantity label (bottom-right). Hidden until quantity > 1
    o.qty = Text:New(name .. "_Qty", {
        parent = o,
        fontTemplate = "NumberFontNormalYellow",
        fontSize = 14,
        textPoint = "BOTTOMRIGHT",
        textPointRelative = "BOTTOMRIGHT",
        textX = opts.width * 0.4, textY = opts.height * -0.4,
        text = nil,
    })
    o.qty:SetAllPoints(o.frame)
    o.qty:Hide()

    -- Turn-based cooldown overlay (sits over icon, shrinks from bottom)
    local cdOverlay = f:CreateTexture(nil, "OVERLAY")
    cdOverlay:SetDrawLayer("OVERLAY", 6)
    cdOverlay:SetColorTexture(0, 0, 0, 0.45)  -- dark translucent
    cdOverlay:SetPoint("BOTTOMLEFT", o.icon, "BOTTOMLEFT", 0, 0)
    cdOverlay:SetPoint("BOTTOMRIGHT", o.icon, "BOTTOMRIGHT", 0, 0)
    cdOverlay:SetHeight(0)
    cdOverlay:Hide()

    -- Cooldown text (centered)
    local cdText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    cdText:SetDrawLayer("OVERLAY", 8)
    cdText:SetPoint("CENTER", f, "CENTER", 0, 0)
    cdText:SetJustifyH("CENTER"); cdText:SetJustifyV("MIDDLE")
    cdText:SetTextColor(1, 0.85, 0.2, 1)
    cdText:Hide()

    -- Item state
    o.itemId  = opts.itemId
    o.instanceGuid = opts.instanceGuid  -- Instance GUID for this item (for modifications)
    o.quality = opts.quality
    o.quantity= opts.quantity or 1
    o.cdOverlay = cdOverlay
    o.cdText = cdText
    o._cdTotal = nil
    o._cdRemain = 0
    o._cdAnimStart = nil
    o._cdAnimFrom = nil
    o._cdAnimTo = nil
    o._cdAnimDur = 0.18

    -- Animation driver (OnUpdate hook like ActionBarSlot)
    local function OnUpdateAnim(_, elapsed)
        if o._cdAnimStart then
            local t0 = o._cdAnimStart
            local dur = o._cdAnimDur or 0.18
            local prog = math.min(1, math.max(0, (GetTime() - t0) / dur))
            local from = o._cdAnimFrom or 0
            local to = o._cdAnimTo or 0
            local h = from + (to - from) * prog

            if o.cdOverlay and o.cdOverlay:IsShown() then
                o.cdOverlay:SetHeight(h)
            end

            if prog >= 1 then
                o._cdAnimStart = nil
            end
        end
    end
    f:SetScript("OnUpdate", OnUpdateAnim)

    -- Ensure icon starts nil unless explicitly provided
    if not opts.icon then o.icon:SetTexture(nil) end

    -- Apply initial quality/quantity visuals
    if o.quality and o.icon:GetTexture() then
        o:SetQuality(o.quality)
    end
    o:SetQuantity(o.quantity)

    -- Hover glow (hidden by default)
    o.glow = f:CreateTexture(nil, "OVERLAY")
    o.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    o.glow:SetBlendMode("ADD")
    o.glow:SetAlpha(0.8)
    o.glow:SetSize(o.frame:GetWidth() * 1.8, o.frame:GetHeight() * 1.8)
    o.glow:SetPoint("CENTER", o.frame, "CENTER")
    o.glow:Hide()

    -- Set context
    o.context = opts.context or nil

    -- Tooltip (fresh lookup; registry first. If missing, show grey name + red warning)
    f:HookScript("OnEnter", function(self)
        if not o.itemId then
            o.glow:Show()
            return
        end

        local reg  = RPE.Core and RPE.Core.ItemRegistry
        local item = reg and reg.Get and reg:Get(o.itemId) or nil

        if item and item.ShowTooltip and RPE and RPE.Common and RPE.Common.ShowTooltip then
            -- Live registry item → render full tooltip with instance GUID if available
            RPE.Common:ShowTooltip(self, item:ShowTooltip(o.instanceGuid))
        else
            -- Not in registry → show minimal tooltip:
            -- grey name (try registry name if available, else datasets, else id) + red warning
            local displayName

            -- Fallback: scan datasets for a name
            if (not displayName) and _G.RPEngineDatasetDB and _G.RPEngineDatasetDB.datasets then
                for _, ds in pairs(_G.RPEngineDatasetDB.datasets) do
                    local items = ds and ds.items
                    if items then
                        local v = items[o.itemId] or items[tostring(o.itemId)]
                        if not v then
                            for k, vv in pairs(items) do
                                if tostring(k) == tostring(o.itemId) then v = vv; break end
                            end
                        end
                        if v and v.name then
                            displayName = v.name
                            break
                        end
                    end
                end
            end

            displayName = displayName or tostring(o.itemId)

            if RPE and RPE.Common and RPE.Common.ShowTooltip then
                RPE.Common:ShowTooltip(self, {
                    title = displayName,
                    titleColor = {0.7, 0.7, 0.7}, -- grey title
                    lines = {
                        { text = "This item is not part of your active data.", r = 1, g = 0.25, b = 0.25, wrap = false },
                    },
                })
            end
        end

        o.glow:Show()
    end)

    -- Click handling
    f:HookScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Equip only if the item is present in the active registry and not during an event
            if o.itemId then
                local Event = RPE.Core and RPE.Core.Event
                if Event and Event.IsRunning and Event:IsRunning() then
                    if RPE and RPE.Debug and RPE.Debug.Warning then
                        RPE.Debug:Warning("Cannot equip items during an event.")
                    end
                    return
                end
                local reg = RPE.Core and RPE.Core.ItemRegistry
                local item = reg and reg.Get and reg:Get(o.itemId) or nil
                if item and item.data and item.data.slot and not o.context then
                    local profile = RPE.Profile.DB.GetOrCreateActive()
                    profile:Equip(item.data.slot, item.id, false)
                elseif not item then
                    if RPE and RPE.Debug and RPE.Debug.Warning then
                        RPE.Debug:Warning("Item not available in active datasets; cannot equip.")
                    end
                end
            end

        elseif button == "RightButton" and o.itemId then
            -- Open context menu only for items that exist in the registry
            local reg = RPE.Core and RPE.Core.ItemRegistry
            local item = reg and reg.Get and reg:Get(o.itemId) or nil
            if item then
                -- Always show context menu (right-click doesn't consume)
                InventorySlot:ShowItemContextMenu(o, item)
            else
                if RPE and RPE.Debug and RPE.Debug.Warning then
                    RPE.Debug:Warning("Item not available in active datasets; no actions available.")
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

function InventorySlot:SetBackground(path)
    if self.bg then
        self.bg:SetTexture(path or nil)
    end
end

function InventorySlot:SetBorder(path)
    if path then
        self.borderTex:SetTexture(path)
        self.borderTex:Show()
    else
        self.borderTex:SetTexture(nil)
        self.borderTex:Hide()
    end
end

---Sets the item icon (nil clears). Also refreshes quality border visibility.
function InventorySlot:SetItemIcon(path)
    self:SetIcon(path)
    if not path then
        self:ShowQualityBorder(false)
    elseif self.quality then
        self:SetQuality(self.quality)
    end
end

function InventorySlot:SetItemId(id) self.itemId = id end
function InventorySlot:GetItemId()   return self.itemId end
function InventorySlot:SetInstanceGuid(guid) self.instanceGuid = guid end
function InventorySlot:GetInstanceGuid() return self.instanceGuid end

--- Set the slot's item.
--- Accepts either:
---   1) string/number id  -> looks up in ItemRegistry (player inventory use)
---   2) table { id, icon, name?, rarity?, instanceGuid? } -> direct preview (editor; no registry)
---@param id any|string|number|table
---@param quantity integer|nil
---@param instanceGuid string|nil -- instance GUID for this item (used for modifications)
function InventorySlot:SetItem(id, quantity, instanceGuid)
    -- Editor/direct-preview path: table payload (no registry access)
    if type(id) == "table" then
        local data = id
        self.itemId = data.id
        self.instanceGuid = data.instanceGuid  -- preserve instanceGuid if in data
        self:SetItemIcon(data.icon or nil)
        self:SetQuality(data.rarity or nil)
        self:SetQuantity(quantity or 0)
        self:SetName(nil)
        self:SetSubtitle(nil)
        return
    end

    -- Registry-backed path (player inventory, etc.)
    local reg  = RPE.Core and RPE.Core.ItemRegistry
    local item = reg and reg.Get and reg:Get(id) or nil

    self.itemId = id
    self.instanceGuid = instanceGuid  -- store the provided instance GUID
    if item then
        self:SetItemIcon(item.icon)
        self:SetQuality(item.rarity)
    else
        local dsItem = _findItemInAnyDataset(id)
        if dsItem and dsItem.icon then
            self:SetItemIcon(dsItem.icon)
            -- Not part of active data → force grey border
            self.quality = nil                      -- don't use rarity colors
            self:SetQualityBorderColor(0.5, 0.5, 0.5, 1)
            self:ShowQualityBorder(true)
        else
            -- No data → empty slot (no icon)
            self:SetItemIcon(nil)
            self:SetQuality(nil)                    -- hides border
        end
    end

    self:SetQuantity(quantity or 0)
    self:SetName(nil)
    self:SetSubtitle(nil)
end

function InventorySlot:ClearItem()
    self.itemId   = nil
    self.quality  = nil
    self.quantity = 0
    self:SetIcon(nil)
    self:ShowQualityBorder(false)
    self.qty:Hide()
    self:SetName(nil)
    self:SetSubtitle(nil)
end

---Set the quality border color by quality key. Pass nil to hide.
function InventorySlot:SetQuality(qualityKey)
    self.quality = qualityKey
    local qc = qualityKey and QualityColors[qualityKey] or nil
    if qc and self.icon:GetTexture() then
        self:SetQualityBorderColor(qc.r or 1, qc.g or 1, qc.b or 1, 1)
        self:ShowQualityBorder(true)
    else
        self:ShowQualityBorder(false)
    end
end

---Set the stack quantity. Shows label only if > 1.
function InventorySlot:SetQuantity(qty)
    qty = tonumber(qty) or 1
    self.quantity = qty
    if qty > 1 then
        self.qty:SetText(tostring(qty))
        self.qty:Show()
    else
        self.qty:SetText("")
        self.qty:Hide()
    end
end

---Optional: set the visible labels (hidden if nil/empty)
function InventorySlot:SetName(text)
    if text and text ~= "" then
        self.name:SetText(text)
        self.name:Show()
    else
        self.name:SetText("")
        self.name:Hide()
    end
end

function InventorySlot:SetSubtitle(text)
    if text and text ~= "" then
        self.subtitle:SetText(text)
        self.subtitle:Show()
    else
        self.subtitle:SetText("")
        self.subtitle:Hide()
    end
end

--- Set turn-based cooldown with animated overlay
function InventorySlot:SetTurnCooldown(turns)
    turns = tonumber(turns) or 0
    
    if turns <= 0 then
        -- Cooldown finished
        self._cdRemain = 0
        self._cdTotal = nil
        if self.cdText then self.cdText:Hide() end
        if self.cdOverlay then self.cdOverlay:Hide(); self.cdOverlay:SetHeight(0) end
        return
    end
    
    -- starting or ticking: update totals
    if not self._cdTotal or turns > (self._cdRemain or 0) then
        self._cdTotal = turns
    end
    self._cdRemain = turns
    
    -- Get icon dimensions (matches ActionBarSlot approach)
    local iconTop = self.icon:GetTop() or 0
    local iconBottom = self.icon:GetBottom() or 0
    local fullH = math.max(0, iconTop - iconBottom)
    
    -- If icon hasn't been laid out yet, use frame size as fallback
    if fullH == 0 then
        fullH = self.frame:GetHeight() or 48
    end
    
    -- calculate target overlay height (bottom anchored, shrinks as turns drop)
    local frac = (self._cdTotal and self._cdTotal > 0) and (turns / self._cdTotal) or 1
    frac = math.min(1, math.max(0, frac))
    local targetH = math.floor(fullH * frac + 0.5)
    
    -- Queue animation (will be driven by OnUpdate)
    if self.cdOverlay then
        self.cdOverlay:Show()
        local currentH = self.cdOverlay:GetHeight() or 0
        self._cdAnimFrom = currentH
        self._cdAnimTo = targetH
        self._cdAnimStart = GetTime()
    end
    
    if self.cdText then
        self.cdText:SetText(tostring(turns))
        self.cdText:Show()
    end
end

--- Clear cooldown display
function InventorySlot:_promptAndTradeItem(playerName, itemId, itemDef)
    -- If item is not stackable, just send quantity 1
    if not itemDef.stackable then
        self:_tradeItem(playerName, itemId, 1)
        return
    end
    
    -- For stackable items, prompt for quantity
    local Popup = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.Popup
    if not Popup then
        self:_tradeItem(playerName, itemId, 1)
        return
    end
    
    local quantity = self.quantity or 1
    Popup.Prompt(
        "Trade Item",
        "How many " .. itemDef.name .. " to give to " .. playerName .. "?",
        tostring(quantity),
        function(text)
            local qty = tonumber(text)
            if qty and qty > 0 and math.floor(qty) == qty then
                self:_tradeItem(playerName, itemId, qty)
            end
        end,
        nil -- onCancel
    )
end

function InventorySlot:_tradeItem(playerName, itemId, quantity)
    -- Get player key
    local realm = GetRealmName():gsub("%s+", "")
    local playerKey = (playerName .. "-" .. realm):lower()
    
    -- Send via Broadcast (both sender and receiver will process this through Handle)
    local Broadcast = RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast
    if Broadcast and Broadcast.SendItemToPlayer then
        Broadcast:SendItemToPlayer(playerKey, itemId, quantity)
    end
end

function InventorySlot:ClearCooldown()
    self._cdRemain = 0
    self._cdTotal = nil
    if self.cdText then self.cdText:Hide() end
    if self.cdOverlay then self.cdOverlay:Hide(); self.cdOverlay:SetHeight(0) end
end
function InventorySlot:ShowQualityBorder(show)
    local qb = self.qBorder
    if not qb then return end
    if show then
        qb.top:Show(); qb.bottom:Show(); qb.left:Show(); qb.right:Show()
    else
        qb.top:Hide(); qb.bottom:Hide(); qb.left:Hide(); qb.right:Hide()
    end
end

function InventorySlot:SetQualityBorderColor(r, g, b, a)
    local qb = self.qBorder
    if not qb then return end
    qb.top:SetColorTexture(r, g, b, a or 1)
    qb.bottom:SetColorTexture(r, g, b, a or 1)
    qb.left:SetColorTexture(r, g, b, a or 1)
    qb.right:SetColorTexture(r, g, b, a or 1)
end

function InventorySlot:ShowItemContextMenu(slot, item)
    -- Safety: only build a menu if the item still exists in the registry
    local reg = RPE.Core and RPE.Core.ItemRegistry
    local live = reg and reg.Get and reg:Get(item and item.id) or nil
    if not live then
        if RPE and RPE.Debug and RPE.Debug.Warning then
            RPE.Debug:Warning("Item not available in active datasets; no actions available.")
        end
        return
    end

    RPE_UI.Common:ContextMenu(slot.frame, function(level, menuList)
        if level == 1 then
            -- For consumables with spells, show "Use"; for others, show "Equip"
            local isConsumableWithSpell = item.category == "CONSUMABLE" and item.spellId
            local actionText = isConsumableWithSpell and "Use" or "Equip"
            
            UIDropDownMenu_AddButton({
                text = actionText,
                func = function()
                    local check = reg and reg:Get(item.id)
                    if not check then
                        if RPE and RPE.Debug and RPE.Debug.Warning then
                            RPE.Debug:Warning("Item not available in active datasets; cannot " .. (isConsumableWithSpell and "use" or "equip") .. ".")
                        end
                        return
                    end
                    
                    if isConsumableWithSpell then
                        -- Consume: cast spell using the full SpellCast system
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
                        
                        -- Remove one from inventory after casting (only if CONSUMABLE)
                        if check.category == "CONSUMABLE" then
                            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
                            if profile then
                                profile:RemoveItem(check.id, 1)
                                if profile.Inventory and profile.Inventory.Refresh then
                                    profile.Inventory:Refresh()
                                end
                                -- Delay InventorySheet refresh until after spell finishes resolving (cooldown will be set during onResolve)
                                C_Timer.After(0, function()
                                    if RPE.Core and RPE.Core.Windows and RPE.Core.Windows.InventorySheet then
                                        RPE.Core.Windows.InventorySheet:Refresh()
                                    end
                                end)
                            end
                        end
                    else
                        -- Equip
                        if check.data and check.data.slot then
                            local profile = RPE.Profile.DB.GetOrCreateActive()
                            profile:Equip(check.data.slot, check.id, false)
                        end
                    end
                end,
                notCheckable = true
            }, level)

            -- Add "Modify..." option for EQUIPMENT items
            if item.category == "EQUIPMENT" then
                UIDropDownMenu_AddButton({
                    text = "Modify...",
                    hasArrow = true,
                    notCheckable = true,
                    menuList = "MODIFY_LIST"
                }, level)
            end

            UIDropDownMenu_AddButton({
                text = "Give to...",
                hasArrow = true,
                notCheckable = true,
                menuList = "GIVE_TO_LIST"
            }, level)

            UIDropDownMenu_AddButton({
                text = "Delete Item",
                func = function()
                    local check = reg and reg:Get(item.id)
                    if not check then return end

                    local profile = RPE.Profile.DB.GetOrCreateActive()
                    local qty = slot.quantity or 1 -- CORRECT: pull from slot, not self
                    profile:RemoveItem(check.id, qty)

                    if RPE.Core and RPE.Core.Windows and RPE.Core.Windows.InventorySheet then
                        RPE.Core.Windows.InventorySheet:Refresh()
                    end
                end,
                notCheckable = true
            }, level)

        elseif level == 2 and menuList == "MODIFY_LIST" then
            -- Get player's profile and ItemModification API
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
            local ItemMod = RPE.Core and RPE.Core.ItemModification
            if not profile or not profile.items or not ItemMod then
                UIDropDownMenu_AddButton({
                    text = "No modifications available",
                    isTitle = true,
                    notCheckable = true
                }, level)
                return
            end
            
            local slotInstanceGuid = slot.instanceGuid
            
            -- Part 1: Show currently applied modifications (checked, click to remove)
            local appliedMods = ItemMod:GetAppliedModifications(profile, slotInstanceGuid)
            if #appliedMods > 0 then
                UIDropDownMenu_AddButton({
                    text = "Applied Modifications",
                    isTitle = true,
                    notCheckable = true
                }, level)
                
                -- Group applied mods by item ID and count them
                local groupedMods = {}
                for _, appliedMod in ipairs(appliedMods) do
                    if not groupedMods[appliedMod.itemId] then
                        groupedMods[appliedMod.itemId] = {
                            name = appliedMod.name,
                            itemId = appliedMod.itemId,
                            modKeys = {},
                        }
                    end
                    table.insert(groupedMods[appliedMod.itemId].modKeys, appliedMod.modKey)
                end
                
                for _, modGroup in pairs(groupedMods) do
                    local displayText = modGroup.name
                    local count = #modGroup.modKeys
                    if count > 1 then
                        displayText = displayText .. " [" .. count .. "]"
                    end
                    
                    UIDropDownMenu_AddButton({
                        text = displayText,
                        checked = true,
                        func = function()
                            -- Remove only the first one (one click, one removal)
                            local firstModKey = modGroup.modKeys[1]
                            ItemMod:RemoveModificationByKey(profile, slotInstanceGuid, firstModKey, false)
                            
                            -- Close and rebuild dropdown
                            CloseDropDownMenus()
                            
                            -- Refresh UI
                            if RPE.Core.Windows and RPE.Core.Windows.InventorySheet then
                                RPE.Core.Windows.InventorySheet:Refresh()
                            end
                            if RPE.Core.Windows and RPE.Core.Windows.EquipmentSheet then
                                RPE.Core.Windows.EquipmentSheet:Refresh()
                            end
                            if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
                                RPE.Core.Windows.PlayerUnitWidget:Refresh()
                            end
                        end,
                    }, level)
                end
                
                -- Add a separator
                UIDropDownMenu_AddButton({
                    text = "",
                    isTitle = true,
                    notCheckable = true
                }, level)
            end
            
            -- Part 2: Show available modifications from inventory (only compatible ones)
            local modItems = {}
            local seenModIds = {}  -- Track by item ID to group duplicates
            for _, invSlot in ipairs(profile.items or {}) do
                local modItem = reg and reg:Get(invSlot.id)
                if modItem and modItem.category == "MODIFICATION" and not seenModIds[invSlot.id] then
                    -- Check if this modification is compatible with the item
                    local isCompatible, reason = ItemMod:IsModificationCompatible(profile, slotInstanceGuid, invSlot.id)
                    -- Check if player can actually apply it (has it in inventory + socket/limit not full)
                    local canApply, applyReason = ItemMod:CanApplyModification(profile, slotInstanceGuid, invSlot.id)
                    
                    if isCompatible then
                        -- Count total quantity of this modification across all inventory slots
                        local totalQty = 0
                        for _, slot in ipairs(profile.items or {}) do
                            if slot.id == invSlot.id then
                                totalQty = totalQty + (slot.qty or 1)
                            end
                        end
                        
                        table.insert(modItems, {
                            id = invSlot.id,
                            name = modItem.name or invSlot.id,
                            qty = totalQty,
                            canApply = canApply,
                            reason = applyReason or reason
                        })
                        seenModIds[invSlot.id] = true
                    end
                end
            end

            if #modItems == 0 and #appliedMods == 0 then
                UIDropDownMenu_AddButton({
                    text = "No modifications available",
                    isTitle = true,
                    notCheckable = true
                }, level)
                return
            end
            
            if #modItems > 0 then
                UIDropDownMenu_AddButton({
                    text = "Add Modification",
                    isTitle = true,
                    notCheckable = true
                }, level)
            end

            for _, modItem in ipairs(modItems) do
                local displayText = modItem.name
                if modItem.qty > 1 then
                    displayText = displayText .. " [" .. modItem.qty .. "]"
                end

                UIDropDownMenu_AddButton({
                    text = displayText,
                    disabled = not modItem.canApply,
                    tooltipTitle = modItem.canApply and nil or "Cannot Apply",
                    tooltipText = modItem.canApply and nil or modItem.reason,
                    func = function()
                        -- Apply modification to the item in inventory
                        local currentProfile = RPE.Profile.DB.GetOrCreateActive()
                        if not currentProfile then return end
                        
                        -- The item must be in inventory (unequipped) to apply modifications
                        local isEquipped = false
                        for _, eqItemId in pairs(currentProfile.equipment or {}) do
                            if eqItemId == item.id then
                                isEquipped = true
                                break
                            end
                        end
                        
                        if isEquipped then
                            RPE.Debug:Error("Item must be unequipped to apply modifications")
                            return
                        end
                        
                        -- Apply the modification (without specifying instance GUID - let it use the first found)
                        ItemMod:ApplyModification(currentProfile, slotInstanceGuid, modItem.id)
                        
                        -- Close the dropdown menu so it rebuilds with fresh data
                        CloseDropDownMenus()
                        
                        -- Refresh UI to reflect changes
                        if RPE.Core.Windows and RPE.Core.Windows.InventorySheet then
                            RPE.Core.Windows.InventorySheet:Refresh()
                        end
                        if RPE.Core.Windows and RPE.Core.Windows.EquipmentSheet then
                            RPE.Core.Windows.EquipmentSheet:Refresh()
                        end
                        if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
                            RPE.Core.Windows.PlayerUnitWidget:Refresh()
                        end
                    end,
                    notCheckable = true
                }, level)
            end

        elseif level == 2 and menuList == "GIVE_TO_LIST" then
            -- Block trading if the item has fallen out of the registry
            local current = reg and reg:Get(item.id)
            if not current then
                UIDropDownMenu_AddButton({
                    text = "Item not available",
                    isTitle = true, notCheckable = true
                }, level)
                return
            end

            local slot = self  -- Capture the InventorySlot instance for callbacks
            local added = false
            if IsInRaid() then
                for i = 1, GetNumGroupMembers() do
                    local name = GetRaidRosterInfo(i)
                    if name then
                        UIDropDownMenu_AddButton({
                            text = name,
                            func = function()
                                local chk = reg and reg:Get(item.id)
                                if chk then
                                    slot:_promptAndTradeItem(name, chk.id, chk)
                                end
                            end,
                            notCheckable = true
                        }, level)
                        added = true
                    end
                end
            elseif IsInGroup() then
                for i = 1, GetNumSubgroupMembers() do
                    local unit = "party"..i
                    if UnitExists(unit) then
                        local name = UnitName(unit)
                        UIDropDownMenu_AddButton({
                            text = name,
                            func = function()
                                local chk = reg and reg:Get(item.id)
                                if chk then
                                    slot:_promptAndTradeItem(name, chk.id, chk)
                                end
                            end,
                            notCheckable = true
                        }, level)
                        added = true
                    end
                end
                local playerName = UnitName("player")
                UIDropDownMenu_AddButton({
                    text = playerName .. " (You)",
                    func = function()
                        local chk = reg and reg:Get(item.id)
                        if chk then
                            slot:_promptAndTradeItem(playerName, chk.id, chk)
                        end
                    end,
                    notCheckable = true
                }, level)
                added = true
            end
            if not added then
                UIDropDownMenu_AddButton({
                    text = "No players found",
                    isTitle = true,
                    notCheckable = true
                }, level)
            end
        end
    end)
end

return InventorySlot
