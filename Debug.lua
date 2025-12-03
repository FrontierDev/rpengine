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

function Debug:Dice(message)
    if not message or not debug then return end
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    local diceIcon = icons.Dice
    message = tostring(diceIcon .. " |cFF808080" .. message .. "|r")
    
    -- Push to ChatBoxWidget if available (as both chat message and debug message)
    local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if chatBox then
        -- Push as a chat message with "DICE" channel type (like NPC messages)
        chatBox:PushDiceMessage(message)

        -- Also push to debug tab
        chatBox:PushDebugMessage(message, "Dice")

        -- Also push to default chat frame
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        end
    end
end

function Debug:Combat(message)
    if not message or not debug then return end
    local icons = (RPE and RPE.Common and RPE.Common.InlineIcons) or {}
    local combatIcon = icons.Combat
    
    -- Color damage schools in the message
    -- Pattern: "X deals A School1, B School2 damage to Y"
    -- Start with grey wrapper, then inject colors for each school damage
    local coloredMessage = message
    local DamageSchoolInfo = RPE.Common and RPE.Common.DamageSchoolInfo or {}
    
    if next(DamageSchoolInfo) then
        for school, info in pairs(DamageSchoolInfo) do
            if info.color then
                -- Match patterns like "32 Physical" or "3 Fire"
                -- We'll wrap the school name and preceding number in color codes
                local r, g, b = math.floor(info.color.r * 255), math.floor(info.color.g * 255), math.floor(info.color.b * 255)
                local hex = string.format("%02x%02x%02x", r, g, b)
                local colorCode = "|cff" .. hex
                
                -- Pattern matches: digit(s) + space + school name
                -- Replace with: colored version of the damage amount and school
                coloredMessage = coloredMessage:gsub("(%d+)%s+" .. school, colorCode .. "%1 " .. school .. "|r")
            end
        end
    end
    
    -- Wrap the entire message in grey after injecting school colors
    coloredMessage = "|cFF808080" .. coloredMessage .. "|r"
    
    message = tostring(combatIcon .. " " .. coloredMessage)
    
    -- Push to ChatBoxWidget if available (as both chat message and debug message)
    local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if chatBox then
        -- Push as a chat message with "DICE" channel type (like NPC messages)
        chatBox:PushDiceMessage(message)

        -- Also push to debug tab
        chatBox:PushDebugMessage(message, "Combat")

        -- Also push to default chat frame
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        end
    end
end