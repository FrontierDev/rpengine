-- Debug.lua
local Debug = {}
_G.RPE.Debug = Debug

-- Variables
local debug = true
Debug.debug = debug

---Debug message categorization:
---
---INTERNAL - Under-the-hood technical details (targeting resolution, hit calculations, tick loops, state traces)
---INFO - Player-relevant feedback (learning, crafting, event lifecycle, combat results)
---WARNING/ERROR - User-facing issues and validation failures
---
---Use Print() for player-visible outcomes, Internal() for developer traces, Warning/Error for issues.

function Debug:Print(message)
    if not message or not debug then return end
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    print((icons.Info or "") .. " |cFF9d9d9d[RPEngine]|r " .. message)
    
    -- Also push to ChatBoxWidget if available
    local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if chatBox then
        chatBox:PushDebugMessage(message, "Info")
    end
end

function Debug:Error(message)
    if message and debug then
        local icon = (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Error) or ""
        print(icon .. " |cFFFF0000[RPEngine]|r " .. message)
        
        -- Also push to ChatBoxWidget if available
        local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
        if chatBox then
            chatBox:PushDebugMessage(message, "Error")
        end
    end
end

function Debug:Warning(message)
    if message and debug then
        local icon = (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Warning) or ""
        print(icon .. " |cFFFFA500[RPEngine Warning]|r " .. message)
        
        -- Also push to ChatBoxWidget if available
        local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
        if chatBox then
            chatBox:PushDebugMessage(message, "Warning")
        end
    end
end

function Debug:NYI(feature)
    if not feature or not debug then return end
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    print((icons.Info or "") .. " |cFF9d9d9d[RPEngine]|r " .. feature .. " is not yet implemented.")
end

function Debug:Obsolete(message)
    if not message or not debug then return end
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    --print((icons.Info or "") .. " |cFFFFA500[RPEngine Obsolete]|r " .. message)

    -- Also push to ChatBoxWidget if available
    local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if chatBox then
        chatBox:PushDebugMessage(message, "Internal")
    end
end

function Debug:Internal(message)
    if not message or not debug then return end
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    -- print((icons.Info or "") .. " |cFF808080[RPEngine Internal]|r " .. message)
    
    -- Also push to ChatBoxWidget if available
    local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if chatBox then
        chatBox:PushDebugMessage(message, "Internal")
    end
end
