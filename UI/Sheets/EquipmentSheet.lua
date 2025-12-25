-- RPE_UI/Windows/EquipmentSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE.ActiveRules = RPE.ActiveRules

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local Panel    = RPE_UI.Elements.Panel
local FrameElement = RPE_UI.Elements.FrameElement

-- Prefabs
local CharacterPortrait = RPE_UI.Prefabs.CharacterPortrait
local EquipmentSlot     = RPE_UI.Prefabs.EquipmentSlot

---@class EquipmentSheet
---@field Name string
---@field root Window
---@field topGroup HGroup
---@field profile table
---@field entries table<string, any>
local EquipmentSheet = {}
_G.RPE_UI.Windows.EquipmentSheet = EquipmentSheet
EquipmentSheet.__index = EquipmentSheet
EquipmentSheet.Name = "EquipmentSheet"

local slotBgIcons = {
    ["head"]        = "interface\\paperdoll\\ui-paperdoll-slot-head.blp",
    ["feet"]        = "interface\\paperdoll\\ui-paperdoll-slot-feet.blp",
    ["legs"]        = "interface\\paperdoll\\ui-paperdoll-slot-legs.blp",
    ["hands"]       = "interface\\paperdoll\\ui-paperdoll-slot-hands.blp",
    ["mainhand"]    = "interface\\paperdoll\\ui-paperdoll-slot-mainhand.blp",
    ["neck"]        = "interface\\paperdoll\\ui-paperdoll-slot-neck.blp",
    ["ranged"]      = "interface\\paperdoll\\ui-paperdoll-slot-ranged.blp",
    ["back"]        = "interface\\paperdoll\\ui-paperdoll-slot-rear.blp",
    ["relic"]       = "interface\\paperdoll\\ui-paperdoll-slot-relic.blp",
    ["offhand"]     = "interface\\paperdoll\\ui-paperdoll-slot-secondaryhand.blp",
    ["finger"]      = "interface\\paperdoll\\ui-paperdoll-slot-finger.blp",
    ["shirt"]       = "interface\\paperdoll\\ui-paperdoll-slot-shirt.blp",
    ["shoulder"]    = "interface\\paperdoll\\ui-paperdoll-slot-shoulder.blp",
    ["tabard"]      = "interface\\paperdoll\\ui-paperdoll-slot-tabard.blp",
    ["trinket"]     = "interface\\paperdoll\\ui-paperdoll-slot-trinket.blp",
    ["waist"]       = "interface\\paperdoll\\ui-paperdoll-slot-waist.blp",
    ["wrists"]      = "interface\\paperdoll\\ui-paperdoll-slot-wrists.blp",
    ["chest"]       = "interface\\paperdoll\\ui-paperdoll-slot-chest.blp",
    ["ammo"]        = "interface\\paperdoll\\ui-paperdoll-slot-ammo.blp"
}


-- Expose under RPE.Core.Windows too (so external hooks can find it)
local function exposeCoreWindow(self)
    _G.RPE       = _G.RPE or {}
    _G.RPE.Core  = _G.RPE.Core or {}
    _G.RPE.Core.Windows = _G.RPE.Core.Windows or {}
    _G.RPE.Core.Windows.EquipmentSheet = self
end

function EquipmentSheet:BuildUI(opts)
    self.profile = RPE.Profile.DB.GetOrCreateActive()  -- live profile (includes transient mods)
    self.entries = {}

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

    -- Top content (portrait + name/guild + resources)
    -- self:TopGroup()
    -- self.sheet:Add(self.topGroup)

    -- Body content (primary/melee/ranged/spell/resistances)
    self:BodyGroup()
    

    -- Register / expose
    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE.Debug:Internal("Registering EquipmentSheet window...")
        RPE_UI.Common:RegisterWindow(self)
    end
    exposeCoreWindow(self)
end

function EquipmentSheet:TopGroup()
    self.topGroup = HGroup:New("RPE_ES_TopGroup", {
        parent  = self.sheet,
        width   = 600,
        height  = 88,
        x       = 12, y = -12,
        spacingX = 12,
        alignV  = "CENTER",
        alignH  = "LEFT",
        autoSize = false,
    })
end

function EquipmentSheet:BodyGroup()
    self.bodyGroup = VGroup:New("RPE_ES_BodyGroup", {
        parent  = self.sheet,
        width   = 600,
        height  = 88,
        padding = { left = 0, right = 0, top = 8, bottom = 0 },
        alignV  = "CENTER",
        alignH  = "CENTER",
        autoSize = true,
    })
    self.sheet:Add(self.bodyGroup)

    self.row1 = HGroup:New("RPE_ES_BodyGroup_1", {
        parent = self.bodyGroup,
        width = 600,
        height = 1,
        autoSize = true,
        alignV = "CENTER",
        alignH = "CENTER"
    })
    self.bodyGroup:Add(self.row1)

    self.leftgroup = VGroup:New("RPE_ES_BodyGroup_1_Left", {
        parent = self.row1,
        width = 1,
        height = 1,
        autoSize = true,
        alignV = "CENTER",
        alignH = "CENTER",
        point = "LEFT", relativePoint = "LEFT"
    })
    self.row1:Add(self.leftgroup)

    local modelFrame = CreateFrame("PlayerModel", "RPE_ES_PlayerModel", self.row1.frame)
    modelFrame:SetSize(250, 350)        -- tweak size as needed
    modelFrame:SetUnit("player")        -- shows the player’s current character model
    modelFrame:SetRotation(0.25*math.pi)           -- facing direction
    modelFrame:SetCamDistanceScale(0.6)   -- zoom
    modelFrame:SetPosition(0, 0, -0.2)     -- offsets

    self.row1spacer = FrameElement:New("PlayerModel", modelFrame, self.row1)
    self.row1:Add(self.row1spacer)

    self.rightgroup = VGroup:New("RPE_ES_BodyGroup_1_Right", {
        parent = self.row1,
        width = 1,
        height = 1,
        autoSize = true,
        alignV = "CENTER",
        alignH = "CENTER",
        point = "RIGHT", relativePoint = "RIGHT"
    })
    self.row1:Add(self.rightgroup)

    self.row2 = HGroup:New("RPE_ES_BodyGroup_2", {
        parent = self.bodyGroup,
        width = 1, height = 1,
        autoSize = true,
        alignV = "CENTER",
        alignH = "CENTER"
    })
    self.bodyGroup:Add(self.row2)

    self:DrawLeftSlots()
    self:DrawRightSlots()
    self:DrawBottomSlots()
    
    self:Refresh()
end

function EquipmentSheet:DrawSlot(parent, key)
    local name = string.format("RPE_ES_%s_Slot", key)
    local slot = EquipmentSlot:New(name, {
        width      = 48, height = 48,
        bgTexture  = tostring(slotBgIcons[string.lower(key)]),
        noBorder   = true,
    })
    self.slots = self.slots or {}
    self.slots[key] = slot
    parent:Add(slot)
end

function EquipmentSheet:DrawLeftSlots()
    local list = RPE.ActiveRules:Get("equipment_slots_left")
    if not list then return end

    for _, val in ipairs(list) do
       self:DrawSlot(self.leftgroup, string.lower(tostring(val)))
    end
end

function EquipmentSheet:DrawRightSlots()
    local list = RPE.ActiveRules:Get("equipment_slots_right")
    if not list then return end

    for _, val in ipairs(list) do
       self:DrawSlot(self.rightgroup, string.lower(tostring(val)))
    end
end

function EquipmentSheet:DrawBottomSlots()
    local list = RPE.ActiveRules:Get("equipment_slots_bottom")
    if not list then return end

    for _, val in ipairs(list) do
       self:DrawSlot(self.row2, string.lower(tostring(val)))
    end
end

local function _normSlotKey(k)
    return tostring(k or ""):lower():gsub("%s+", ""):gsub("_",""):gsub("-","")
end

local function _payloadForSetItem(v)
    -- Accept either an id or a table; if it's a table with an id, SetItem handles it too.
    if type(v) == "table" then
        return v.id or v.ItemID or v.itemId or v
    end
    return v
end

function EquipmentSheet:Refresh()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    
    local equipment = profile.equipment or {}

    -- Build a normalized view of the equipment table: "mainhand"/"main_hand"/"MainHand" -> "mainhand"
    local eq = {}
    for k, v in pairs(equipment) do
        eq[_normSlotKey(k)] = v
    end

    -- Drive each UI slot from the normalized equipment map
    for slotKey, slotWidget in pairs(self.slots or {}) do
        local normKey   = _normSlotKey(slotKey)
        local equipped  = eq[normKey]
        slotWidget:SetItem(_payloadForSetItem(equipped))
        
        -- Store the slot key on the widget so tooltips can access it
        slotWidget._equipmentSlot = slotKey
        
        -- Get the instance GUID for this equipped item so tooltips can show modifications
        local instanceGuid = nil
        if profile.equippedInstanceGuids then
            -- Try both the raw slot key and normalized version
            instanceGuid = profile.equippedInstanceGuids[slotKey] or profile.equippedInstanceGuids[normKey]
        end
        slotWidget:SetInstanceGuid(instanceGuid)
    end
end


--- Injects character data into the UI.
function EquipmentSheet:SetCharacter(data)
    if not data then return end
    if data.name  then self.charName:SetText(data.name) end
    if data.guild then self.guildName:SetText(data.guild) end
end

function EquipmentSheet.New(opts)
    local self = setmetatable({}, EquipmentSheet)
    self:BuildUI(opts or {})
    return self
end

return EquipmentSheet