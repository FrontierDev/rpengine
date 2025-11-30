-- RPE_UI/Windows/AuraStripWidget.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.Windows = RPE.Core.Windows or {}

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window     = RPE_UI.Elements.Window
local VGroup     = RPE_UI.Elements.VerticalLayoutGroup
local HGroup     = RPE_UI.Elements.HorizontalLayoutGroup
local IconBtn    = RPE_UI.Elements.IconButton
local Text       = RPE_UI.Elements.Text
local AuraEvents = RPE.Core.AuraEvents

---@class AuraStripWidget
---@field root Window
---@field content VGroup
---@field unitId integer
---@field debuffStrip HGroup
---@field buffStrip HGroup
---@field iconsByInst table<integer, { btn:any, count:Text, turns:Text, parentStrip:HGroup, auraId:string, border?:table }>
---@field _turnTicker table|nil
local AuraStripWidget = {}
AuraStripWidget.__index = AuraStripWidget
RPE_UI.Windows.AuraStripWidget = AuraStripWidget
AuraStripWidget.Name = "AuraStripWidget"

-- ===== Utilities =====================================================================

local function getMgr()
    local ev = RPE.Core and RPE.Core.ActiveEvent
    return ev and ev._auraManager or nil
end

-- WoW-style debuff colors
local DEBUFF_COLORS = {
    MAGIC   = { 0.20, 0.60, 1.00, 1.0 }, -- blue
    CURSE   = { 0.60, 0.00, 1.00, 1.0 }, -- purple
    DISEASE = { 0.60, 0.40, 0.00, 1.0 }, -- brown
    POISON  = { 0.00, 0.60, 0.00, 1.0 }, -- green
    BLEED   = { 0.80, 0.10, 0.10, 1.0 }, -- red (custom)
    ENRAGE  = { 1.00, 0.25, 0.25, 1.0 }, -- light red (custom)
    DEFAULT = { 0.75, 0.10, 0.10, 1.0 },
}

local function getDebuffColor(def)
    if not def or def.isHelpful then return nil end
    local t = def.dispelType and string.upper(def.dispelType) or "DEFAULT"
    return unpack(DEBUFF_COLORS[t] or DEBUFF_COLORS.DEFAULT)
end

-- Create/update a 1px border around an IconButton, colored as requested
local function applyBorder(entry, def)
    if not entry or not entry.btn or not entry.btn.frame then return end
    if def and def.isHelpful then
        -- helpful auras: remove border if present
        if entry.border then
            for _, tex in pairs(entry.border) do if tex and tex.Hide then tex:Hide() end end
            entry.border = nil
        end
        return
    end

    local r,g,b,a = getDebuffColor(def)
    local f = entry.btn.frame
    local border = entry.border
    if not border then
        border = {}
        -- 4 edge textures
        border.top    = f:CreateTexture(nil, "OVERLAY")
        border.bottom = f:CreateTexture(nil, "OVERLAY")
        border.left   = f:CreateTexture(nil, "OVERLAY")
        border.right  = f:CreateTexture(nil, "OVERLAY")
        -- anchor
        border.top:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
        border.top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
        border.top:SetHeight(2)

        border.bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -1, -1)
        border.bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
        border.bottom:SetHeight(2)

        border.left:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
        border.left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -1, -1)
        border.left:SetWidth(2)

        border.right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
        border.right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
        border.right:SetWidth(2)

        entry.border = border
    end

    for _, tex in pairs(border) do
        tex:SetColorTexture(r, g, b, a or 1)
        tex:Show()
    end
end

-- ===== Build =========================================================================

function AuraStripWidget:BuildUI(opts)
    opts = opts or {}
    self.unitId = opts.unitId

    -- Root window anchored top-right @ (-64, -64)
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent
    self.root = Window:New("RPE_AuraStrip_Window_"..tostring(self.unitId or 0), {
        parent   = parentFrame,
        width    = 1,
        height   = 1,
        autoSize = true,
        point    = "TOPRIGHT",
        pointRelative = "TOPRIGHT",
        x        = -240,
        y        = -64,
        noBackground = true,
    })

    -- Immersion polish
    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG"); f:SetToplevel(true); f:SetIgnoreParentScale(true)
        local function SyncScale() f:SetScale(UIParent and UIParent:GetScale() or 1) end
        local function UpdateMouseForUIVisibility() f:EnableMouse(UIParent and UIParent:IsShown()) end
        SyncScale(); UpdateMouseForUIVisibility()
        UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
        UIParent:HookScript("OnHide", function() UpdateMouseForUIVisibility() end)
        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Vertical content: buffs on top, debuffs below (right-aligned)
    self.content = VGroup:New("RPE_AuraStrip_Content_"..tostring(self.unitId or 0), {
        parent   = self.root,
        autoSize = true,
        spacingY = 24,       -- proper spacing between buff and debuff strips (8 + 16px offset)
        alignH   = "RIGHT",
    })
    self.root:Add(self.content)

    self.buffStrip = HGroup:New("RPE_AuraStrip_Buffs_"..tostring(self.unitId or 0), {
        parent   = self.content,
        autoSize = true,
        spacingX = 4,
        alignV   = "BOTTOM",  -- align bottom so they don't overlap
        alignH   = "RIGHT",   -- right edge locked; new icons append to the right and grow left
    })
    self.content:Add(self.buffStrip)

    self.debuffStrip = HGroup:New("RPE_AuraStrip_Debuffs_"..tostring(self.unitId or 0), {
        parent   = self.content,
        autoSize = true,
        spacingX = 4,
        alignV   = "BOTTOM",  -- align bottom
        alignH   = "RIGHT",
    })
    self.content:Add(self.debuffStrip)

    self.iconsByInst = {}

    -- Event subscriptions - set up once, listeners check current unitId at runtime
    if AuraEvents then
        AuraEvents:On("APPLY", function(a) 
            if a and self.unitId and a.targetId == self.unitId then 
                self:_AddAuraInstance(a) 
            end 
        end)
        AuraEvents:On("REFRESH", function(a) 
            if a and self.unitId and a.targetId == self.unitId then 
                self:_UpdateAuraInstance(a) 
            end 
        end)
        AuraEvents:On("TICK", function(a) 
            if a and self.unitId and a.targetId == self.unitId then 
                self:_UpdateAuraInstance(a) 
            end 
        end)
        AuraEvents:On("REMOVE", function(a) 
            if a and self.unitId and a.targetId == self.unitId then 
                self:RemoveAuraInstance(a.instanceId) 
            end 
        end)
        AuraEvents:On("EXPIRE", function(a) 
            if a and self.unitId and a.targetId == self.unitId then 
                self:RemoveAuraInstance(a.instanceId) 
            end 
        end)
    end

    -- Periodic counter sync (covers global-turn changes without aura events)
    self:_StartTurnTicker()

    -- Initial sync
    self:Refresh()
    return self
end

function AuraStripWidget:_StartTurnTicker()
    if self._turnTicker then self._turnTicker:Cancel() end
    self._turnTicker = C_Timer.NewTicker(0.25, function()
        self:_UpdateAllTurns()
    end)
end

-- Choose strip by helpfulness
function AuraStripWidget:_StripForDef(def)
    return (def and def.isHelpful) and self.buffStrip or self.debuffStrip
end

-- ===== Instance lifecycle =============================================================

-- Add a new aura instance (icons grow right -> left on a right-aligned strip by appending)
function AuraStripWidget:_AddAuraInstance(a)
    local def = RPE.Core.AuraRegistry:Get(a.id); if not def then return end
    local strip = self:_StripForDef(def)
    local instId = tonumber(a.instanceId) or 0
    if self.iconsByInst[instId] then return end

    local name = ("RPE_AuraIcon_%s_%d_%d"):format(a.id, self.unitId or 0, instId)
    local btn = IconBtn:New(name, {
        parent = strip,
        width  = 32, height = 32,
        icon   = def.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        desaturated = not def.isHelpful,
    })

    -- Append => newest icon sits at right edge, older shift left (strip is right-aligned)
    if strip.Add then strip:Add(btn) else
        table.insert(strip.children, btn); if strip.Relayout then strip:Relayout() end
    end

    -- Force texture in case the element skin ignores the init field
    if btn.SetIcon and def.icon then btn:SetIcon(def.icon)
    elseif btn.icon and btn.icon.SetTexture and def.icon then btn.icon:SetTexture(def.icon)
    end

    -- Tooltip (hover)
    -- Tooltip (hover) via Common helpers
    btn.frame:HookScript("OnEnter", function(frame)
        local spec
        if a.GetTooltip then
            spec = a:GetTooltip()
        else
            -- minimal fallback: title + parsed description
            local def2 = RPE.Core.AuraRegistry:Get(a.id) or {}
            local text = def2.description and Common:ParseText(def2.description) or nil
            spec = { title = def2.name or a.id or "Aura", lines = {} }
            if text and text ~= "" then
                table.insert(spec.lines, { text = text, r = 1, g = 0.82, b = 0, wrap = true })
            end
        end
        Common:ShowTooltip(frame, spec)
    end)

    btn.frame:HookScript("OnLeave", function()
        Common:HideTooltip()
    end)

    -- Stacks: bottom-right overlay IN the icon
    local count = Text:New(name.."_Count", {
        parent = btn,
        fontTemplate = "GameFontNormalSmall",
        text = "",
        point = "BOTTOMRIGHT",
        textPoint = "BOTTOMRIGHT",
        x = -1, y = 1,
    })

    -- Turns: centered UNDER the icon (anchor text TOP to icon BOTTOM)
    local turns = Text:New(name.."_Turns", {
        parent = btn,
        fontTemplate = "GameFontNormal",
        text = "",
        point = "CENTER",
        textPoint = "CENTER",
        y = -28,
    })

    local entry = { btn = btn, count = count, turns = turns, parentStrip = strip, auraId = a.id }
    self.iconsByInst[instId] = entry

    -- Debuff border
    applyBorder(entry, def)

    btn:Show()
    self:_UpdateAuraInstance(a)
end

-- Update an existing aura instance
function AuraStripWidget:_UpdateAuraInstance(a)
    local instId = tonumber(a.instanceId) or 0
    local entry = self.iconsByInst[instId]; if not entry then return end
    local def = RPE.Core.AuraRegistry:Get(a.id)

    -- Stacks
    if a.stacks and a.stacks > 1 then
        entry.count:SetText(tostring(a.stacks))
    else
        entry.count:SetText("")
    end

    -- Turns
    local mgr = getMgr()
    if a.expiresOn and mgr and mgr.event then
        local left = math.max(0, (a.expiresOn or 0) - (mgr.event.turn or 0))
        entry.turns:SetText(left > 0 and tostring(left) or "")
    else
        entry.turns:SetText("")
    end

    -- Keep border color consistent even if def changed dynamically
    applyBorder(entry, def)
end

-- Fast pass: refresh only the "turns" text based on current manager state
function AuraStripWidget:_UpdateAllTurns()
    if not self.unitId then return end
    local mgr = getMgr(); if not mgr then return end
    
    -- Get all current auras for this unit
    local allAuras = mgr:All(self.unitId)
    local byInst = {}
    for _, a in ipairs(allAuras) do
        byInst[tonumber(a.instanceId) or 0] = a
    end
    
    -- Update existing aura turn counts
    for instId, entry in pairs(self.iconsByInst) do
        local a = byInst[instId]
        if a and a.expiresOn and mgr.event then
            local left = math.max(0, (a.expiresOn or 0) - (mgr.event.turn or 0))
            entry.turns:SetText(left > 0 and tostring(left) or "")
        else
            entry.turns:SetText("")
        end
    end
    
    local layoutDirty = false
    
    -- Check for new auras that weren't showing before
    -- This catches auras that existed before we switched to this unit
    for _, a in ipairs(allAuras) do
        local instId = tonumber(a.instanceId) or 0
        if not self.iconsByInst[instId] then
            self:_AddAuraInstance(a)
            layoutDirty = true
        end
    end
    
    -- Check for auras that have been removed
    local present = {}
    for _, a in ipairs(allAuras) do
        present[tonumber(a.instanceId) or 0] = true
    end
    for instId, _ in pairs(self.iconsByInst) do
        if not present[instId] then
            self:RemoveAuraInstance(instId)
            layoutDirty = true
        end
    end
    
    -- Force layout update if auras were added or removed
    if layoutDirty then
        if self.buffStrip and self.buffStrip.Relayout then self.buffStrip:Relayout() end
        if self.debuffStrip and self.debuffStrip.Relayout then self.debuffStrip:Relayout() end
        if self.content and self.content.Relayout then self.content:Relayout() end
        if self.root and self.root.Relayout then self.root:Relayout() end
    end
end

-- Remove an aura instance (from layout & frames)
function AuraStripWidget:RemoveAuraInstance(instId)
    instId = tonumber(instId) or 0
    local entry = self.iconsByInst[instId]; if not entry then return end

    local parent = entry.parentStrip
    if parent and parent.children then
        for i = #parent.children, 1, -1 do
            if parent.children[i] == entry.btn then
                table.remove(parent.children, i)
                break
            end
        end
    end

    if entry.border then
        for _, tex in pairs(entry.border) do if tex and tex.Hide then tex:Hide() end end
        entry.border = nil
    end

    if entry.btn   and entry.btn.Destroy   then entry.btn:Destroy()   end
    if entry.count and entry.count.Destroy then entry.count:Destroy() end
    if entry.turns and entry.turns.Destroy then entry.turns:Destroy() end

    self.iconsByInst[instId] = nil
    if parent and parent.Relayout then parent:Relayout() end
end

-- Full reconciliation
function AuraStripWidget:Refresh()
    if not self.unitId then return end
    local mgr = getMgr(); if not mgr then return end

    local present = {}
    for _, a in ipairs(mgr:All(self.unitId)) do
        local instId = tonumber(a.instanceId) or 0
        present[instId] = true
        if not self.iconsByInst[instId] then
            self:_AddAuraInstance(a)
        else
            self:_UpdateAuraInstance(a)
        end
    end

    for instId, _ in pairs(self.iconsByInst) do
        if not present[instId] then
            self:RemoveAuraInstance(instId)
        end
    end

    -- Force layout update after adding/removing auras
    if self.buffStrip and self.buffStrip.Relayout then
        self.buffStrip:Relayout()
    end
    if self.debuffStrip and self.debuffStrip.Relayout then
        self.debuffStrip:Relayout()
    end
    if self.content and self.content.Relayout then
        self.content:Relayout()
    end
    if self.root and self.root.Relayout then
        self.root:Relayout()
    end
end

function AuraStripWidget:Show()
    if self.root then self.root:Show() end
    if not self._turnTicker then self:_StartTurnTicker() end
end

function AuraStripWidget:Hide()
    if self.root then self.root:Hide() end
    if self._turnTicker then self._turnTicker:Cancel(); self._turnTicker = nil end
end

-- ===== Temporary Mode (for controlled units) =======================================

--- Enter temporary mode to display a controlled unit's auras
--- This switches the widget to show a specific unit's auras (stays in top-right corner)
function AuraStripWidget:EnterTemporaryMode(controlledUnitId)
    self.unitId = tonumber(controlledUnitId) or 0
    
    -- Clear old auras first
    for instId, entry in pairs(self.iconsByInst) do
        if entry.btn and entry.btn.Destroy then entry.btn:Destroy() end
        if entry.count and entry.count.Destroy then entry.count:Destroy() end
        if entry.turns and entry.turns.Destroy then entry.turns:Destroy() end
    end
    self.iconsByInst = {}
    
    -- Clear the strip layouts
    if self.buffStrip and self.buffStrip.children then
        self.buffStrip.children = {}
    end
    if self.debuffStrip and self.debuffStrip.children then
        self.debuffStrip.children = {}
    end
    
    -- Debug
    local mgr = getMgr()
    if mgr then
        local auras = mgr:All(self.unitId)
    end
    
    -- Now refresh to populate with new unit's auras
    self:Refresh()
    self:Show()
end

--- Exit temporary mode and hide the aura strip
function AuraStripWidget:ExitTemporaryMode()
    self:Hide()
    self.unitId = nil
    -- Clear all icon entries
    for instId, entry in pairs(self.iconsByInst) do
        if entry.btn and entry.btn.Destroy then entry.btn:Destroy() end
        if entry.count and entry.count.Destroy then entry.count:Destroy() end
        if entry.turns and entry.turns.Destroy then entry.turns:Destroy() end
    end
    self.iconsByInst = {}
end

function AuraStripWidget.New(opts)
    local o = setmetatable({}, AuraStripWidget)
    return o:BuildUI(opts or {})
end

return AuraStripWidget
