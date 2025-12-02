-- Commands.lua
local Commands = {}
_G.RPE.Commands = Commands

-- === Slash Command ===
SLASH_RPE1 = "/rpe"
SlashCmdList["RPE"] = function(msg)
    local arg, rest = msg:lower():match("^(%S+)%s*(.*)$")
    if arg == "sheet" then
        local main = RPE_UI.Common:GetWindow("MainWindow")
        if not main then
            RPE.Debug:Error("Main window not found.")
            return
        end
        RPE_UI.Common:Toggle(main)

    elseif arg == "rules" then
        if not (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then
            RPE.Debug:Print("Only the supergroup leader can open the Ruleset window.")
            return
        end
        local Ruleset = RPE_UI.Common:GetWindow("Ruleset")
        if not Ruleset then
            RPE.Debug:Error("Ruleset window not found.")
            return
        end
        RPE_UI.Common:Toggle(Ruleset)

    elseif arg == "event" then
        if not (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then
            RPE.Debug:Print("Only the supergroup leader can open the Event window.")
            return
        end
        local Event = RPE_UI.Common:GetWindow("EventWindow")
        if not Event then
            RPE.Debug:Error("Event window not found.")
            return
        end
        RPE_UI.Common:Toggle(Event)

    elseif arg == "data" then
        local Ruleset = RPE_UI.Common:GetWindow("DatasetWindow")
        if not Ruleset then
            RPE.Debug:Error("Dataset window not found.")
            return
        end
        RPE_UI.Common:Toggle(Ruleset)


    elseif arg == "stat" then
        local statId = rest:match("^(%S+)")
        if statId then
            statId = statId:upper()
            local val = RPE.Stats:GetValue(statId)
            if not val then
                RPE.Debug:Warning(string.format("Stat %s not found.", statId))
                return
            end
            RPE.Debug:Print(string.format("Stat %s: %d", statId, val))
        end


    elseif arg == "sginvite" then
        local fullName = rest:match("^(%S+)")
        if not fullName or not fullName:find("-", 1, true) then
            return
        end

        local sg = RPE.Core.ActiveSupergroup
        if not sg then
            return
        end

        sg:AddSoloPlayer(fullName)
        RPE.Core.isLeader = true  -- inviter becomes leader

        -- Ask them (if they are a leader) to publish their roster.
        RPE.Core.Comms:Send("SG_REQUEST_ROSTER", { UnitName("player") }, "WHISPER", fullName)

    elseif arg == "chant" then
        -- Show/toggle the Chanter sender window
        local win = RPE_UI.Common:GetWindow("ChanterSenderWindow")
        if not win then
            -- If the class is loaded but not instantiated/registered yet, create it.
            local C = _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.ChanterSenderWindow
            if C and C.New then
                win = C.New({})
                win:Show()
            end
        end

        if not win then
            RPE.Debug:Error("Chanter window not found.")
            return
        end

        RPE_UI.Common:Toggle(win)

    elseif arg == "leader" then
        -- Print the result of RPE.Core.IsLeader()
        local fn = RPE and RPE.Core and RPE.Core.IsLeader
        if not fn then return end

        local ok, result = pcall(fn)
        if not result then
            RPE.Debug:Print("You are not the leader of a supergroup.")
        else
            RPE.Debug:Print("You are the leader of a supergroup.")
        end

    elseif arg == "clipboard" then
        local Clipboard = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.Clipboard
            if Clipboard then
                Clipboard:Show()
            else
        end
    else

    end
end
