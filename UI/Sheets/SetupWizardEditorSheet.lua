-- RPE_UI/Sheets/SetupWizardEditorSheet.lua
-- Editor for Setup Wizard pages with action groups, using SetupPages prefab

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local VGroup      = RPE_UI.Elements.VerticalLayoutGroup
local Text        = RPE_UI.Elements.Text
local SetupPages  = RPE_UI.Prefabs.SetupPages

---@class SetupWizardEditorSheet
---@field Name string
---@field sheet any
---@field setupPages any
---@field editingName string|nil
local SetupWizardEditorSheet = {}
_G.RPE_UI.Windows.SetupWizardEditorSheet = SetupWizardEditorSheet
SetupWizardEditorSheet.__index = SetupWizardEditorSheet
SetupWizardEditorSheet.Name = "SetupWizardEditorSheet"

-- ---------------------------------------------------------------------------
-- Bind the dataset being edited
-- ---------------------------------------------------------------------------
function SetupWizardEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then
        self.editingName = name
    else
        self.editingName = nil
    end
    if self.Refresh then
        self:Refresh()
    end
end

function SetupWizardEditorSheet:GetEditingDataset()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB or nil
    if not (DB and self.editingName) then return nil end

    local candidates = { "GetByName", "GetByKey", "Get" }
    for _, fname in ipairs(candidates) do
        local fn = DB[fname]
        if type(fn) == "function" then
            local ok1, ds1 = pcall(fn, DB, self.editingName)
            if ok1 and ds1 then return ds1 end
            local ok2, ds2 = pcall(fn, self.editingName)
            if ok2 and ds2 then return ds2 end
        end
    end
    return nil
end

function SetupWizardEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    if self.Refresh then self:Refresh() end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function _getSetupWizard(ds)
    if not ds then return nil end
    if not ds.setupWizard then
        ds.setupWizard = { pages = {} }
    end
    if not ds.setupWizard.pages then
        ds.setupWizard.pages = {}
    end
    return ds.setupWizard
end

local function _saveDataset(ds)
    if not ds then return end
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if DB and DB.Save then
        pcall(DB.Save, ds)
    end
end

-- ---------------------------------------------------------------------------
-- UI Building
-- ---------------------------------------------------------------------------
function SetupWizardEditorSheet:BuildUI(opts)
    opts = opts or {}
    self.parent = opts.parent
    
    self.sheet = VGroup:New("RPE_SetupWizardEditor_Sheet", {
        parent   = self.parent,
        width    = 1, height = 1,
        point    = "TOP", relativePoint = "TOP", x = 0, y = 0,
        padding  = { left = 12, right = 12, top = 12, bottom = 12 },
        spacingY = 12,
        alignV   = "TOP",
        alignH   = "LEFT",
        autoSize = true,
    })
    
    -- Title
    local titleText = Text:New("RPE_SetupWizardEditor_Title", {
        parent = self.sheet,
        text   = "Setup Wizard Pages",
    })
    self.sheet:Add(titleText)
    
    -- SetupPages prefab with action groups
    -- Page type schema notes:
    -- - SELECT_ITEMS: supports optional boolean field "spareChange"
    --   When true, player's copper currency is set to the leftover amount
    --   from the item selection page (allowance - spent)
    self.setupPages = SetupPages:New("RPE_SetupWizardEditor_Pages", {
        parent = self.sheet,
        ownerSheet = self.sheet,
        actionSchemas = ((_G.RPE and _G.RPE.Core and _G.RPE.Core.SpellActionSchemas) or nil),
        onSave = function() self:_savePageData() end,
    })
    self.sheet:Add(self.setupPages.root)
    
    self.editingName = nil
end

function SetupWizardEditorSheet:_savePageData()
    local DBG = _G.RPE and _G.RPE.Debug
    if DBG then DBG:Internal("[SetupWizard] _savePageData called") end
    
    local ds = self:GetEditingDataset()
    if not ds then
        if DBG then DBG:Internal("[SetupWizard] ERROR: GetEditingDataset returned nil") end
        return
    end
    if DBG then DBG:Internal("[SetupWizard] Got dataset: " .. (ds.name or "?")) end
    
    if self.setupPages then
        local pages = self.setupPages:GetValue()
        if DBG then DBG:Internal("[SetupWizard] GetValue returned " .. #pages .. " page(s)") end
        
        -- Ensure dataset has setupWizard table
        if not ds.setupWizard then
            ds.setupWizard = {}
        end
        
        -- Assign pages to the dataset's setupWizard
        ds.setupWizard.pages = pages
        if DBG then DBG:Internal("[SetupWizard] Assigned to ds.setupWizard.pages, now = " .. #(ds.setupWizard.pages or {})) end
    else
        if DBG then DBG:Internal("[SetupWizard] ERROR: setupPages is nil") end
        return
    end
    
    -- Save the entire dataset
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if DBG then DBG:Internal("[SetupWizard] DB = " .. (DB and "found" or "nil")) end
    if DB and DB.Save then
        if DBG then DBG:Internal("[SetupWizard] Calling DB.Save with ds.setupWizard.pages = " .. #(ds.setupWizard.pages or {})) end
        local ok, err = pcall(DB.Save, ds)
        if ok then
            if DBG then DBG:Internal("[SetupWizard] DB.Save succeeded") end
        else
            if DBG then DBG:Internal("[SetupWizard] DB.Save FAILED: " .. tostring(err)) end
        end
    else
        if DBG then DBG:Internal("[SetupWizard] ERROR: DB or DB.Save not available") end
    end
end

function SetupWizardEditorSheet:Refresh()
    local DBG = _G.RPE and _G.RPE.Debug
    if not self.sheet or not self.sheet.frame then return end
    if not self.setupPages then return end
    
    local ds = self:GetEditingDataset()
    if not ds then return end
    
    local wizard = _getSetupWizard(ds)
    local pages = (wizard and wizard.pages) or {}
    
    self.setupPages:SetValue(pages)
    
    if self.sheet.Relayout then
        pcall(function() self.sheet:Relayout() end)
    end
end

function SetupWizardEditorSheet.New(opts)
    local self = setmetatable({}, SetupWizardEditorSheet)
    self:BuildUI(opts)
    return self
end

return SetupWizardEditorSheet
