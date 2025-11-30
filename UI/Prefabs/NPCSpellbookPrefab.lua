-- RPE_UI/Prefabs/NPCSpellbookPrefab.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local VGroup  = RPE_UI.Elements.VerticalLayoutGroup
local HGroup  = RPE_UI.Elements.HorizontalLayoutGroup
local Text    = RPE_UI.Elements.Text
local SlotPF  = RPE_UI.Prefabs and RPE_UI.Prefabs.SpellbookSlot

---@class NPCSpellbookPrefab
---@field root VGroup
---@field _value string[]             -- list of spell ids (editor value)
---@field _slots any[]                -- SpellbookSlot instances
---@field _cols integer
---@field _rows integer
local NPCSpellbookPrefab = {}
NPCSpellbookPrefab.__index = NPCSpellbookPrefab
RPE_UI.Prefabs.NPCSpellbookPrefab = NPCSpellbookPrefab

-- simple name helper
local function _name(pfx, i)
    return string.format("%s_%02d", pfx or "RPE_NPCSB", i or 0)
end

local function _allSpellsSorted()
    local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
    local map = reg and reg.All and reg:All() or {}
    local list = {}
    for id, sp in pairs(map) do
        list[#list+1] = { id = id, name = (sp and (sp.name or sp.displayName)) or id, icon = sp and sp.icon }
    end
    table.sort(list, function(a,b)
        local an = tostring(a.name or a.id):lower()
        local bn = tostring(b.name or b.id):lower()
        if an ~= bn then return an < bn end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

local function _showPickMenu(anchor, onPick)
    local Common = _G.RPE_UI and _G.RPE_UI.Common
    if not (Common and Common.ContextMenu) then return end
    local items = _allSpellsSorted()
    Common:ContextMenu(anchor, function(level, menuList)
        if level == 1 then
            UIDropDownMenu_AddButton({
                text = "|cffff6060Clear Slot|r",
                notCheckable = true,
                func = function() onPick(nil) end,
            }, level)
            for _, it in ipairs(items) do
                UIDropDownMenu_AddButton({
                    text = it.name,
                    icon = it.icon,
                    notCheckable = true,
                    func = function() onPick(it) end,
                }, level)
            end
        end
    end)
end

-- helper: apply a spell ID to a slot
function NPCSpellbookPrefab:_applySlotValue(idx, id, slot)
    if id and id ~= "" then
        local reg   = _G.RPE and _G.RPE.Core and _G.RPE.Core.SpellRegistry
        local def   = reg and reg.Get and reg:Get(id) or nil
        local name  = (def and (def.name or def.displayName)) or tostring(id)
        local icon  = (def and def.icon) or "Interface\\Icons\\INV_Misc_QuestionMark"
        slot:SetSpell({ id = id, name = name, icon = icon })
        slot.spellId = id
    else
        slot:ClearSpell()
        slot.spellId = nil
    end
end

function NPCSpellbookPrefab:New(name, opts)
    opts = opts or {}
    local self = setmetatable({}, NPCSpellbookPrefab)

    self._cols  = 5
    self._rows  = opts.rows or 4
    self._slots = {}
    self._value = {}

    -- preload incoming spells
    if type(opts.value) == "table" then
        for _, v in ipairs(opts.value) do
            local sid = tostring(v or ""):match("^%s*(.-)%s*$")
            if sid ~= "" then table.insert(self._value, sid) end
        end
    end

    self.root = VGroup:New(name .. "_Root", {
        parent   = opts.parent,
        spacingY = 6,
        alignH   = "LEFT",
        alignV   = "TOP",
        autoSize = true,
    })

    local title = Text:New(name .. "_Title", {
        parent = self.root,
        text   = "Spellbook",
        fontTemplate = "GameFontNormal",
        justifyH = "LEFT",
    })
    self.root:Add(title)

    -- build slots
    local idx = 1
    for r = 1, self._rows do
        local row = HGroup:New(_name(name .. "_Row", r), {
            parent = self.root, spacingX = 6, alignV = "CENTER", alignH = "LEFT", autoSize = true,
        })
        self.root:Add(row)

        for c = 1, self._cols do
            local slotIndex = idx -- capture index per slot
            local slot = SlotPF:New(_name(name .. "_Slot", slotIndex), {
                parent = row,
                width  = (opts.slotSize or 40),
                height = (opts.slotSize or 40),
            })
            row:Add(slot)
            self._slots[slotIndex] = slot

            -- init with existing value
            self:_applySlotValue(slotIndex, self._value[slotIndex], slot)

            -- click handler
            local f = slot.frame
            f:HookScript("OnMouseDown", function(_, button)
                if button ~= "LeftButton" then return end
                _showPickMenu(f, function(choice)
                    if not choice then
                        self._value[slotIndex] = nil
                        self:_applySlotValue(slotIndex, nil, slot)
                        if GameTooltip then GameTooltip:Hide() end
                        return
                    end
                    local sid = tostring(choice.id or ""):match("^%s*(.-)%s*$")
                    if sid == "" then return end
                    self._value[slotIndex] = sid
                    self:_applySlotValue(slotIndex, sid, slot)
                end)
            end)

            idx = idx + 1
        end
    end

    return self
end

-- return clean list of IDs
function NPCSpellbookPrefab:GetValue()
    local out = {}
    for i, slot in ipairs(self._slots) do
        local id = self._value[i]
        if id and id ~= "" then
            table.insert(out, id)
        end
    end
    if RPE and RPE.Debug and RPE.Debug.Print then
        local joined = (#out > 0) and table.concat(out, ", ") or "(none)"
        RPE.Debug:Internal("NPCSpellbookPrefab:GetValue -> " .. joined)
    end
    return out
end

-- set value when editing existing NPC
function NPCSpellbookPrefab:SetValue(v)
    if type(v) ~= "table" then return end
    self._value = {}
    for i, id in ipairs(v) do
        local sid = tostring(id or ""):match("^%s*(.-)%s*$")
        if sid ~= "" then self._value[i] = sid end
    end
    for i, slot in ipairs(self._slots) do
        self:_applySlotValue(i, self._value[i], slot)
    end
end

return NPCSpellbookPrefab
