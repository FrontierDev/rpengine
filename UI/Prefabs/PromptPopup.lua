-- RPE_UI/Prefabs/PromptPopup.lua
-- Reusable text input popup that appears above all other UI elements

RPE_UI = RPE_UI or {}
RPE_UI.Prefabs = RPE_UI.Prefabs or {}

local Window = RPE_UI.Elements and RPE_UI.Elements.Window
local Panel = RPE_UI.Elements and RPE_UI.Elements.Panel
local Text = RPE_UI.Elements and RPE_UI.Elements.Text
local TextBtn = RPE_UI.Elements and RPE_UI.Elements.TextButton
local Input = RPE_UI.Elements and RPE_UI.Elements.Input

---@class PromptPopup
---@field root Window
---@field titleText Text
---@field messageText Text
---@field inputField any
---@field okBtn any
---@field cancelBtn any
---@field onConfirm function|nil
---@field onCancel function|nil
local PromptPopup = {}
PromptPopup.__index = PromptPopup
RPE_UI.Prefabs.PromptPopup = PromptPopup

local PADDING = 12
local BUTTON_HEIGHT = 26
local BUTTON_WIDTH = 80
local INPUT_HEIGHT = 24

function PromptPopup:BuildUI(opts)
    opts = opts or {}
    
    -- Determine parent frame - use WorldFrame for Immersion mode to ensure it's always on top
    local isImmersion = RPE and RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = isImmersion and WorldFrame or UIParent

    -- Root window - centered, high strata to appear above all other UI
    self.root = Window:New("RPE_PromptPopup_Window", {
        parent = parentFrame,
        width  = 400,
        height = 200,
        point  = "CENTER",
        pointRelative = "CENTER",
        autoSize = false,
        noBackground = false,
    })
    
    -- Ensure it's on top of everything
    if self.root.frame then
        self.root.frame:SetFrameStrata("DIALOG")
        self.root.frame:SetToplevel(true)
    end

    -- Title
    self.titleText = Text:New("RPE_PromptPopup_Title", {
        parent = self.root,
        fontTemplate = "GameFontNormalLarge",
        text = opts.title or "Enter Text",
        autoSize = true,
    })
    self.titleText.frame:SetPoint("TOP", self.root.frame, "TOP", 0, -PADDING)

    -- Message text
    self.messageText = Text:New("RPE_PromptPopup_Message", {
        parent = self.root,
        fontTemplate = "GameFontNormal",
        text = opts.message or "Enter a value:",
        autoSize = true,
    })
    self.messageText.frame:SetPoint("TOP", self.titleText.frame, "BOTTOM", 0, -PADDING)

    -- Input field
    if Input then
        self.inputField = Input:New("RPE_PromptPopup_Input", {
            parent = self.root,
            width = 300,
            height = INPUT_HEIGHT,
            text = opts.defaultText or "",
            placeholder = opts.placeholder or "",
        })
        self.inputField.frame:SetPoint("TOP", self.messageText.frame, "BOTTOM", 0, -PADDING)
        
        -- Focus the input field
        if self.inputField and self.inputField.editBox then
            self.inputField.editBox:SetFocus()
        end
    end

    -- Button group (OK and Cancel)
    local inputBottomY = self.inputField and (self.inputField.frame:GetTop() - (self.inputField.frame:GetHeight() or INPUT_HEIGHT)) or 0

    -- OK button
    self.okBtn = TextBtn:New("RPE_PromptPopup_OK", {
        parent = self.root,
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        text = opts.okText or "OK",
        noBorder = false,
        onClick = function()
            local text = self.inputField and self.inputField:GetText() or ""
            if self.onConfirm then
                self.onConfirm(text)
            end
            self:Hide()
        end,
    })
    if self.okBtn.frame then
        self.okBtn.frame:SetPoint("BOTTOM", self.root.frame, "BOTTOM", -BUTTON_WIDTH/2 - 6, PADDING)
    end

    -- Cancel button
    self.cancelBtn = TextBtn:New("RPE_PromptPopup_Cancel", {
        parent = self.root,
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        text = opts.cancelText or "Cancel",
        noBorder = false,
        onClick = function()
            if self.onCancel then
                self.onCancel()
            end
            self:Hide()
        end,
    })
    if self.cancelBtn.frame then
        self.cancelBtn.frame:SetPoint("BOTTOM", self.root.frame, "BOTTOM", BUTTON_WIDTH/2 + 6, PADDING)
    end

    -- Handle Enter key in input field
    if self.inputField and self.inputField.editBox then
        self.inputField.editBox:SetScript("OnEnterPressed", function()
            if self.okBtn.frame then
                self.okBtn.frame:Click()
            end
        end)
    end

    -- Handle Escape key
    if self.root.frame then
        self.root.frame:SetScript("OnKeyDown", function(frame, key)
            if key == "ESCAPE" then
                if self.cancelBtn.frame then
                    self.cancelBtn.frame:Click()
                end
            end
        end)
    end
end

function PromptPopup:SetCallbacks(onConfirm, onCancel)
    self.onConfirm = onConfirm
    self.onCancel = onCancel
end

function PromptPopup:Show()
    if self.root and self.root.Show then
        self.root:Show()
    end
    if self.inputField and self.inputField.editBox then
        self.inputField.editBox:SetFocus()
    end
end

function PromptPopup:Hide()
    if self.root and self.root.Hide then
        self.root:Hide()
    end
end

function PromptPopup.New(opts)
    local self = setmetatable({}, PromptPopup)
    self:BuildUI(opts or {})
    return self
end

return PromptPopup
