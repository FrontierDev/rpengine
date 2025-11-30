-- RPE_UI/Prefabs/ModelEditPrefab.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local VGroup    = RPE_UI.Elements.VerticalLayoutGroup
local Text      = RPE_UI.Elements.Text
local TextBtn   = RPE_UI.Elements.TextButton
local Panel     = RPE_UI.Elements.Panel
local Slider    = RPE_UI.Elements.Slider
local UnitPortrait = RPE_UI.Prefabs and RPE_UI.Prefabs.UnitPortrait

---@class ModelEditPrefab
---@field root VGroup
---@field preview PlayerModel
---@field portrait UnitPortrait
---@field displayIdText Text
---@field fileDataIdText Text
---@field pathText Text
---@field chooseBtn TextBtn
---@field sliders table
---@field _value table
local ModelEditPrefab = {}
ModelEditPrefab.__index = ModelEditPrefab
RPE_UI.Prefabs.ModelEditPrefab = ModelEditPrefab

-- Constructor
function ModelEditPrefab:New(name, opts)
    opts = opts or {}
    local self = setmetatable({}, ModelEditPrefab)

    self._value = opts.value or {
        displayId   = nil,
        fileDataId  = nil,
        filePath    = nil,
        cam = 1.0,
        rot = 0.0,
        z   = -0.35,
    }

    self.sliders = {}

    -- Root container
    self.root = VGroup:New(name .. "_Root", {
        parent   = opts.parent,
        spacingY = 8,
        alignH   = "CENTER",
        alignV   = "TOP",
        width    = 600,
        autoSize = true,
    })

    ----------------------------------------------------------------
    -- Model preview
    ----------------------------------------------------------------
    local previewPanel = Panel:New(name .. "_PreviewPanel", {
        parent   = self.root,
        width    = opts.width or 400,
        height   = opts.height or 220,
    })
    self.root:Add(previewPanel)

    local pm = CreateFrame("PlayerModel", name .. "_PlayerModel", previewPanel.frame)
    pm:SetAllPoints(previewPanel.frame)
    pm:SetKeepModelOnHide(true)
    pm:ClearTransform()
    pm:SetCamDistanceScale(1.0)
    pm:SetCustomCamera(1)
    pm:SetPosition(0, 0, 0)
    pm:Hide()
    self.preview = pm

    ----------------------------------------------------------------
    -- Portrait preview
    ----------------------------------------------------------------
    if UnitPortrait then
        local portrait = UnitPortrait:New(name .. "_Portrait", {
            parent = self.root,
            size   = 64,
            unit   = { isNPC = true, team = 1 },
        })
        if portrait and portrait.hp and portrait.hp.Hide then portrait.hp:Hide() end
        self.root:Add(portrait)
        self.portrait = portrait
    end

    ----------------------------------------------------------------
    -- Metadata labels
    ----------------------------------------------------------------
    self.displayIdText  = Text:New(name .. "_DisplayID", { parent = self.root, text = "DisplayID: —" })
    self.fileDataIdText = Text:New(name .. "_FileDataID", { parent = self.root, text = "FileDataID: —" })
    self.pathText       = Text:New(name .. "_Path", { parent = self.root, text = "Path: —", fontTemplate = "GameFontHighlightSmall" })
    self.root:Add(self.displayIdText)
    self.root:Add(self.fileDataIdText)
    self.root:Add(self.pathText)

    ----------------------------------------------------------------
    -- Sliders (cam / rot / z)
    ----------------------------------------------------------------
    self.sliders.cam = Slider:New(name .. "_CamSlider", {
        parent = self.root, width = 160, height = 18,
        min = 0.1, max = 5.0, step = 0.05,
        value = self._value.cam or 1.0,
        showValue = true,
        onChanged = function(_, val)
            self._value.cam = tonumber(val) or 1.0
            self:ApplyTransforms()
        end,
    })
    self.root:Add(self.sliders.cam)

    self.sliders.rot = Slider:New(name .. "_RotSlider", {
        parent = self.root, width = 160, height = 18,
        min = -math.pi, max = math.pi, step = 0.05,
        value = self._value.rot or 0.0,
        showValue = true,
        onChanged = function(_, val)
            self._value.rot = tonumber(val) or 0.0
            self:ApplyTransforms()
        end,
    })
    self.root:Add(self.sliders.rot)

    self.sliders.z = Slider:New(name .. "_ZSlider", {
        parent = self.root, width = 160, height = 18,
        min = -2.0, max = 2.0, step = 0.01,
        value = self._value.z or -0.35,
        showValue = true,
        onChanged = function(_, val)
            self._value.z = tonumber(val) or -0.35
            self:ApplyTransforms()
        end,
    })
    self.root:Add(self.sliders.z)

    ----------------------------------------------------------------
    -- Choose button
    ----------------------------------------------------------------
    self.chooseBtn = TextBtn:New(name .. "_ChooseBtn", {
        parent = self.root,
        width  = 120,
        height = 22,
        text   = "Choose Model",
        onClick = function()
            if not (RPE and RPE.Core and RPE.Core.OpenModelFinder) then
                return
            end
            RPE.Core.OpenModelFinder(function(displayId, fileDataId, filePath)
                self:SetModel(displayId, fileDataId, filePath)
            end, { filter = "" })
        end,
    })
    self.root:Add(self.chooseBtn)

    ----------------------------------------------------------------
    -- Apply initial
    ----------------------------------------------------------------
    if self._value.displayId or self._value.fileDataId then
        self:SetModel(self._value.displayId, self._value.fileDataId, self._value.filePath)
    end

    return self
end

-- Apply transforms from _value to preview + portrait
function ModelEditPrefab:ApplyTransforms()
    if not self.preview then return end
    local cam = tonumber(self._value.cam) or 1.0
    local rot = tonumber(self._value.rot) or 0.0
    local z   = tonumber(self._value.z)   or -0.35

    cam = math.min(math.max(cam, 0.1), 10.0)

    self.preview:ClearTransform()
    self.preview:SetCamDistanceScale(cam)
    self.preview:SetRotation(rot)
    self.preview:SetPosition(0, 0, z)

    if self.portrait and self.portrait.model then
        self.portrait.model:ClearTransform()
        self.portrait.model:SetCamDistanceScale(cam)
        self.portrait.model:SetRotation(rot)
        self.portrait.model:SetPosition(0, 0, z)
    end
end

-- Update model & metadata
function ModelEditPrefab:SetModel(displayId, fileDataId, filePath)
    self._value.displayId  = tonumber(displayId) or nil
    self._value.fileDataId = tonumber(fileDataId) or nil
    self._value.filePath   = filePath or self._value.filePath

    if not self.preview then return end
    self.preview:Show()
    self.preview:ClearTransform()

    if self._value.fileDataId then
        self.preview:SetModel(self._value.fileDataId)
    end
    if self._value.displayId then
        self.preview:SetDisplayInfo(self._value.displayId)
    end

    if self.displayIdText then
        self.displayIdText:SetText("DisplayID: " .. (self._value.displayId or "—"))
    end
    if self.fileDataIdText then
        self.fileDataIdText:SetText("FileDataID: " .. (self._value.fileDataId or "—"))
    end
    if self.pathText then
        self.pathText:SetText("Path: " .. (self._value.filePath or "—"))
    end

    if self.portrait then
        self.portrait:SetUnit({
            isNPC = true,
            team  = 1,
            fileDataId     = self._value.fileDataId,
            modelDisplayId = self._value.displayId,
            cam  = self._value.cam,
            rot  = self._value.rot,
            z    = self._value.z,
        })
    end

    self:ApplyTransforms()
end

-- For EditorWizardSheet
function ModelEditPrefab:GetValue()
    return {
        fileDataId = self._value.fileDataId,
        displayId  = self._value.displayId,
        filePath   = self._value.filePath,
        cam        = self._value.cam,
        rot        = self._value.rot,
        z          = self._value.z,
    }
end

function ModelEditPrefab:SetValue(v)
    if type(v) == "table" then
        self._value = v
        self:SetModel(v.displayId, v.fileDataId, v.filePath)
    end
end

return ModelEditPrefab
