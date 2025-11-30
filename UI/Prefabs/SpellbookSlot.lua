-- RPE_UI/Prefabs/SpellbookSlot.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local IconButton = RPE_UI.Elements.IconButton
local Text       = RPE_UI.Elements.Text

---@class SpellbookSlot: IconButton
---@field bg Texture
---@field name Text
---@field subtitle Text
---@field glow Texture
---@field spellId string|nil
local SpellbookSlot = setmetatable({}, { __index = IconButton })
SpellbookSlot.__index = SpellbookSlot
RPE_UI.Prefabs.SpellbookSlot = SpellbookSlot

-- ===== helpers =============================================================

local function _getNumActionBarSlots()
    local slots = _G.RPE and _G.RPE.ActiveRules and _G.RPE.ActiveRules.Get
        and _G.RPE.ActiveRules:Get("action_bar_slots") or 12
    return tonumber(slots) or 12
end

local function _ensureActionBar()
    local coreWindows = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows
    local existing    = coreWindows and coreWindows.ActionBarWidget
    if existing and existing.root then
        return existing
    end
    if RPE_UI and RPE_UI.Windows and RPE_UI.Windows.ActionBarWidget
       and RPE_UI.Windows.ActionBarWidget.New then
        local bar = RPE_UI.Windows.ActionBarWidget.New({
            numSlots = _getNumActionBarSlots(),
            slotSize = 32,
            spacing  = 4,
            point    = "BOTTOM", rel = "BOTTOM", y = 60,
        })
        if bar and bar.Hide then bar:Hide() end
        return bar
    end
    return nil
end

local function _spellDisplay(spellId, fallbackName, fallbackIcon)
    local reg   = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
    local def   = reg and reg.Get and reg:Get(spellId) or nil
    local name  = (def and (def.name or def.displayName)) or fallbackName or tostring(spellId)
    local icon  = (def and def.icon) or fallbackIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    return name, icon, def
end

-- ===== component ===========================================================

function SpellbookSlot:New(name, opts)
    opts = opts or {}
    opts.width  = opts.width  or 40
    opts.height = opts.height or 40

    ---@type SpellbookSlot
    local o = IconButton.New(self, name, opts)
    local f = o.frame

    -- Empty-slot background (same art as InventorySlot)
    if not o.bg then
        o.bg = f:CreateTexture(nil, "ARTWORK", nil, -1)
        o.bg:SetAllPoints()
    end
    o.bg:SetTexCoord(0, 1, 0, 1)
    o.bg:SetTexture(opts.bgTexture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")

    -- Hide IconButton's decorative borders for a clean grid
    if o.topBorder then o.topBorder:Hide() end
    if o.bottomBorder then o.bottomBorder:Hide() end

    -- Optional labels (off by default)
    o.name = Text:New(name .. "_Name", { parent=o, fontTemplate="GameFontHighlightSmall", textPoint="TOP", textY=-2, text=nil })
    o.name:SetAllPoints(f); o.name:Hide()

    o.subtitle = Text:New(name .. "_Subtitle", { parent=o, fontTemplate="GameFontNormalSmall", textPoint="BOTTOM", textY=2, text=nil })
    o.subtitle:SetAllPoints(f); o.subtitle:Hide()

    -- Hover glow
    o.glow = f:CreateTexture(nil, "OVERLAY")
    o.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    o.glow:SetBlendMode("ADD")
    o.glow:SetAlpha(0.8)
    o.glow:SetSize(f:GetWidth()*1.8, f:GetHeight()*1.8)
    o.glow:SetPoint("CENTER", f, "CENTER")
    o.glow:Hide()

    -- Tooltip (registry-backed like InventorySlot, with dataset fallback)
    f:HookScript("OnEnter", function(self)
        if not o.spellId then
            o.glow:Show()
            return
        end

        local reg   = RPE and RPE.Core and RPE.Core.SpellRegistry
        local spell = reg and reg.Get and reg:Get(o.spellId)
        local rank  = o._rank or 1

        if spell then
            local tooltip = spell:GetTooltip(rank)
            RPE.Common:ShowTooltip(self, tooltip)
        else
            -- Not in active registry → minimal tooltip from datasets (if available)
            local displayName, desc
            local sv = _G.RPEngineDatasetDB
            if sv and sv.datasets then
                for _, ds in pairs(sv.datasets) do
                    local spells = ds and ds.spells
                    if spells then
                        local v = spells[o.spellId] or spells[tostring(o.spellId)]
                        if not v then
                            for k, vv in pairs(spells) do
                                if tostring(k) == tostring(o.spellId) then v = vv; break end
                            end
                        end
                        if v then
                            displayName = v.name or displayName
                            desc        = v.description or desc
                            break
                        end
                    end
                end
            end
            displayName = displayName or tostring(o.spellId)

            if RPE and RPE.Common and RPE.Common.ShowTooltip then
                local t = {
                    title      = displayName,
                    titleColor = { 0.7, 0.7, 0.7 }, -- grey title
                    lines = {},
                }
                if desc and desc ~= "" then
                    table.insert(t.lines, { text = desc, r = 0.85, g = 0.85, b = 0.85, wrap = true })
                end
                table.insert(t.lines, { text = "This spell is not part of your active data.", r = 1, g = 0.25, b = 0.25, wrap = false })
                RPE.Common:ShowTooltip(self, t)
            end
        end

        o.glow:Show()
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

    -- Right-click context menu (match InventorySlot pattern)
    f:HookScript("OnMouseDown", function(self, button)
        if button ~= "RightButton" or not o.spellId then return end

        -- Only offer actions if spell exists in the active registry (parity with InventorySlot)
        local reg  = RPE.Core and RPE.Core.SpellRegistry
        local spell= reg and reg.Get and reg:Get(o.spellId) or nil
        if spell then
            SpellbookSlot:ShowSpellContextMenu(self, spell, o)
        else
            if RPE and RPE.Debug and RPE.Debug.Warning then
                RPE.Debug:Warning("Spell not available in active datasets; no actions available.")
            end
        end
    end)

    -- Start empty unless an icon was explicitly provided
    if not opts.icon then o.icon:SetTexture(nil) end

    return o
end

-- =========================
-- Public API
-- =========================
function SpellbookSlot:SetName(text)
    if text and text ~= "" then self.name:SetText(text); self.name:Show()
    else self.name:SetText(""); self.name:Hide() end
end

function SpellbookSlot:SetSubtitle(text)
    if text and text ~= "" then self.subtitle:SetText(text); self.subtitle:Show()
    else self.subtitle:SetText(""); self.subtitle:Hide() end
end

--- Accepts table payload or nil.
--- { id, icon, name }
function SpellbookSlot:SetSpell(payload)
    if type(payload) == "table" then
        self.spellId   = payload.id
        self._dispName = payload.name
        self._rank     = payload.rank or 1   -- ✅ store rank
        self:SetIcon(payload.icon or nil)
    else
        self.spellId   = nil
        self._dispName = nil
        self._rank     = nil
        self:SetIcon(nil)
    end
end


function SpellbookSlot:ClearSpell()
    self:SetSpell(nil)
end

-- =========================
-- Context menu (InventorySlot style)
-- =========================
--- Show context menu at the frame.
--- NOTE: colon-call keeps `self` as the class table (like InventorySlot),
--- so the first arg is the anchor (frame or wrapper), second is the spell def, third is the slot object.
function SpellbookSlot:ShowSpellContextMenu(anchorCandidate, spellDef, slotObj)
    local anchor = (anchorCandidate and anchorCandidate.GetObjectType) and anchorCandidate
        or (anchorCandidate and anchorCandidate.frame) or UIParent

    RPE_UI.Common:ContextMenu(anchor, function(level, menuList)
        if level == 1 then
            UIDropDownMenu_AddButton({
                text = "Bind to...",
                hasArrow = true,
                notCheckable = true,
                menuList = "BIND_SLOT_LIST",
            }, level)

        elseif level == 2 and menuList == "BIND_SLOT_LIST" then
            local num = _getNumActionBarSlots()
            for i = 1, num do
                UIDropDownMenu_AddButton({
                    text = ("Slot %d"):format(i),
                    notCheckable = true,
                    func = function()
                        local bar = _ensureActionBar(); if not bar then return end
                        local name, icon = _spellDisplay(slotObj.spellId, slotObj._dispName, slotObj.icon and slotObj.icon:GetTexture())
                        local spellRank = slotObj._rank or 1

                        local action = {
                            spellId = slotObj.spellId,
                            rank    = spellRank,
                            icon    = icon,
                            name    = name,
                            isEnabled = true,
                        }

                        RPE.Profile.DB:GetOrCreateActive():SetActionBarSlot(i, action.spellId, action.rank)

                        if bar.SetAction then bar:SetAction(i, action) end
                        if bar.FlashSlot then bar:FlashSlot(i, 0.35) end
                    end,
                }, level)
            end
        end
    end)
end

return SpellbookSlot
