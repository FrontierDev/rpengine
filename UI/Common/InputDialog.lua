-- RPE_UI/Common/InputDialog.lua
-- Reusable input dialog helper for prompting user text input

RPE_UI = RPE_UI or {}
RPE_UI.Common = RPE_UI.Common or {}

local Popup = RPE_UI.Prefabs and RPE_UI.Prefabs.Popup

---@class InputDialog
local InputDialog = {}
RPE_UI.Common.InputDialog = InputDialog

--- Show a simple text input dialog
---@param title string Dialog title
---@param text string Prompt text
---@param defaultText string|nil Default value in input field
---@param onAccept function|nil Callback when OK is clicked, receives input text as parameter
---@param onCancel function|nil Callback when Cancel is clicked
---@param opts table|nil Optional parameters: { parentFrame = Frame, sourceFrame = Frame }
---@return table|nil Popup instance
function InputDialog.Show(title, text, defaultText, onAccept, onCancel, opts)
    if not Popup or not Popup.New then
        print("|cffd1ff52[RPE]|r Popup prefab missing; cannot show input dialog.")
        return nil
    end
    
    opts = opts or {}
    local isImmersion = RPE.Core and RPE.Core.ImmersionMode
    local parentFrame = opts.parentFrame or (isImmersion and WorldFrame or UIParent)
    
    local p = Popup.New({
        title         = title or "Input",
        text          = text or "Enter text:",
        showInput     = true,
        defaultText   = defaultText or "",
        primaryText   = "OK",
        secondaryText = "Cancel",
        parentFrame   = parentFrame,
        sourceFrame   = opts.sourceFrame,  -- Pass through the source frame
    })
    
    p:SetCallbacks(
        function(input)
            if onAccept then
                onAccept(input)
            end
        end,
        function()
            if onCancel then
                onCancel()
            end
        end
    )
    
    p:Show()
    return p
end

--- Alias for Show (backwards compatibility with Popup.Prompt)
InputDialog.Prompt = InputDialog.Show

return InputDialog
