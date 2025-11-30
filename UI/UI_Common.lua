-- UI/Common.lua
RPE    = RPE    or {}   -- default addon namespace (global, RPE-prefixed)
RPE_UI = RPE_UI or {}   -- UI namespace (global, RPE-prefixed)

RPE.Core = _G.RPE.Core or {} -- Core namespace (global, RPE-prefixed)
RPE.Core.Windows = _G.RPE.Core.Windows or {} -- Store registered windows

-- keep a Common table for future helpers (intentionally empty for now)
_G.RPE_UI.Common = RPE_UI.Common or {}

-- Register a window in the common UI system.
function RPE_UI.Common:RegisterWindow(window)
    if not window or not window.Name then
        RPE.Debug:Error("Attempted to register a window without a name.")
        return
    end

    if RPE.Core.Windows[window.Name] then
        RPE.Debug:Error("Window '" .. window.Name .. "' is already registered.")
        return
    else
        RPE.Core.Windows[window.Name] = window
        RPE.Debug:Internal("Registered window: " .. window.Name)
    end
end

-- Get a window by name
function RPE_UI.Common:GetWindow(name)
    if not name then return nil end
    return RPE.Core.Windows[name]
end

-- Show a frame
function RPE_UI.Common:Show(frame)
    if frame and frame.root.Show then
        frame.root:Show()
    end
end

-- Hide a frame
function RPE_UI.Common:Hide(frame)
    if frame and frame.root.Hide then
        frame.root:Hide()
    end
end

-- Toggle a window (create instance if needed, then toggle show/hide)
function RPE_UI.Common:Toggle(frame)
    if not frame then return end
    if frame.root.frame:IsVisible() then
        frame.root:Hide(frame)
    else
        frame.root:Show(frame)
    end
end

-- Create and show a context menu at a frame
---@param parent Frame The UI element to attach the menu to
---@param builder fun(level:number, menuList:any) Callback to populate the menu (same signature as UIDropDownMenu_Initialize)
---@return Frame|table contextMenu
function RPE_UI.Common:ContextMenu(parent, builder)
    if not self._contextMenu then
        self._contextMenu = CreateFrame("Frame", "RPE_UI_ContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local menu = self._contextMenu

    UIDropDownMenu_Initialize(menu, function(_, level, menuList)
        if type(builder) == "function" then
            builder(level, menuList)
        end
    end, "MENU")

    -- Always anchor the menu at the cursor
    ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
    return menu
end


