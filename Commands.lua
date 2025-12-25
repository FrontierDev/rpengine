-- Commands.lua
local Commands = {}
_G.RPE.Commands = Commands

-- === Slash Command ===
SLASH_RPE1 = "/rpe"
SlashCmdList["RPE"] = function(msg)
    local arg, rest = msg:lower():match("^(%S+)%s*(.*)$")
    if arg == "palette" then
        local C = RPE_UI and RPE_UI.Colors
        if not C then return end
        local paletteName = rest:match("^(%S+)")
        if not paletteName or paletteName == "" then
            local list = table.concat(C.ListPalettes(), ", ")
            print("Available palettes: " .. list)
            return
        end
        if C.ApplyPalette(paletteName) then
            local prof = RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if prof and prof.SetPaletteName then
                prof:SetPaletteName(paletteName)
            end
            print("Palette applied: " .. paletteName)
        else
            print("Palette not found: " .. paletteName)
        end
    elseif arg == "sheet" then
        local main = RPE_UI.Common:GetWindow("MainWindow")
        if not main then
            RPE.Debug:Error("Main window not found.")
            return
        end
        RPE_UI.Common:Toggle(main)
    elseif arg == "rules" then
        if not (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then
            RPE.Debug:Warning("Only the supergroup leader can open the Ruleset window.")
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
            RPE.Debug:Warning("Only the supergroup leader can open the Event window.")
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
    elseif arg == "setup" then
        local Setup = RPE_UI.Common:GetWindow("SetupWindow")
        local isNewWindow = false
        if not Setup then
            -- Create it if it doesn't exist yet
            if RPE_UI.Windows and RPE_UI.Windows.SetupWindow then
                Setup = RPE_UI.Windows.SetupWindow.New()
                RPE_UI.Common:Show(Setup)
                isNewWindow = true
            else
                RPE.Debug:Error("Setup window not found.")
                return
            end
        end
        -- Only toggle if it wasn't just created
        if not isNewWindow then
            RPE_UI.Common:Toggle(Setup)
        end
    elseif arg == "stat" then
        
    elseif arg == "trpname" then
        -- Print the current player's TRP3 character (roleplay) name, falling back to game name
        local getter = RPE and RPE.Common and RPE.Common.GetTRP3NameForUnit
        if not getter then
            RPE.Debug:Error("[Commands] TRP3 helper not available (Common:GetTRP3NameForUnit missing).")
            return
        end
        local ok, name = pcall(function() return RPE.Common:GetTRP3NameForUnit("player") end)
        if ok and name and name ~= "" then
            RPE.Debug:Error("[Commands] TRP3 name: " .. name)
        else
            RPE.Debug:Error("[Commands] TRP3 name: (none)")
        end

        local statId = rest:match("^(%S+)")
        if statId then
            statId = statId:upper()
            local val = RPE.Stats:GetValue(statId)
            if not val then
                RPE.Debug:Warning(string.format("[Commands] Stat %s not found.", statId))
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
        local isNewWindow = false
        if not win then
            -- If the class is loaded but not instantiated/registered yet, create it.
            local C = _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.ChanterSenderWindow
            if C and C.New then
                win = C.New({})
                win:Show()
                isNewWindow = true
            end
        end
        if not win then
            RPE.Debug:Error("[Commands] Chanter window not found.")
            return
        end
        -- Only toggle if it wasn't just created
        if not isNewWindow then
            RPE_UI.Common:Toggle(win)
        end
    elseif arg == "chat" then
        -- Show the ChatBoxWidget
        local ChatBox = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
        if not ChatBox then
            RPE.Debug:Error("[Commands] ChatBox widget not found.")
            return
        end
        ChatBox:Show()
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
    elseif arg == "location" then
        local Location = RPE and RPE.Core and RPE.Core.Location
        if not Location then
            RPE.Debug:Error("[Commands] Location module not found.")
            return
        end
        local loc = Location:GetPlayerLocation()
        if loc then
            RPE.Debug:Print(string.format("Your Location: %s, %.3f, %.3f (MapID: %d)", loc.zone, loc.x, loc.y, loc.mapID))
        else
            RPE.Debug:Error("[Commands]Could not retrieve location.")
        end
    elseif arg == "lfrp" then
        local LFRPWindow = RPE_UI.Common:GetWindow("LFRPWindow")
        local isNewWindow = false
        if not LFRPWindow then
            -- Create it if it doesn't exist yet
            if RPE_UI.Windows and RPE_UI.Windows.LFRPWindow then
                LFRPWindow = RPE_UI.Windows.LFRPWindow.New()
                RPE_UI.Common:Show(LFRPWindow)
                isNewWindow = true
            else
                RPE.Debug:Error("[Commands] LFRP window class not found.")
                return
            end
        end
        -- Only toggle if it wasn't just created
        if not isNewWindow then
            RPE_UI.Common:Toggle(LFRPWindow)
        end
    elseif arg == "currency" then
        local currencyKey = rest:match("^(%S+)%s+(%S+)")
        local amount = rest:match("^%S+%s+(%S+)")
        if not currencyKey or not amount then
            RPE.Debug:Warning("[Commands] Usage: /rpe currency [key] [amount]")
            return
        end
        amount = tonumber(amount)
        if not amount or amount <= 0 then
            RPE.Debug:Warning("[Commands] Amount must be a positive number.")
            return
        end
        local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive()
        if not profile then
            RPE.Debug:Error("[Commands] No active profile found.")
            return
        end
        
        -- Check if it's a hardcoded currency
        local Common = RPE.Common
        local hardcodedCurrencies = Common and Common.CurrencyIcons or {}
        local currencyKeyLower = currencyKey:lower()
        local foundCurrency = false
        local iconId = nil
        
        if hardcodedCurrencies[currencyKeyLower] then
            -- Found as hardcoded currency
            foundCurrency = true
            iconId = hardcodedCurrencies[currencyKeyLower]
        else
            -- Try to find as an item in the ItemRegistry by searching for matching name
            local ItemRegistry = RPE.Core and RPE.Core.ItemRegistry
            if ItemRegistry then
                local allItems = ItemRegistry:All()
                if allItems then
                    -- Search through all items for one with matching name and CURRENCY category
                    for itemId, item in pairs(allItems) do
                        if item and item.name and item.data then
                            if item.name:lower() == currencyKeyLower and item.category and item.category:lower() == "currency" then
                                -- Found a CURRENCY category item by name
                                foundCurrency = true
                                iconId = tonumber(item.icon) or nil
                                currencyKey = currencyKeyLower  -- Normalize to lowercase for storage
                                break
                            end
                        end
                    end
                end
            end
        end
        
        -- Only add currency if we found it
        if foundCurrency then
            profile:AddCurrency(currencyKey, amount)
        else
            RPE.Debug:Warning("[Commands] Currency not found: " .. currencyKey)
        end
    elseif arg == "npcinfo" then
            -- Print information about the current target (safe calls)
            local exists = false
            pcall(function() exists = UnitExists("target") end)
            if not exists then
                print("No target selected.")
                return
            end

            local ok, name = pcall(UnitName, "target")
            if not ok or not name then name = "(unknown)" end

            local guid
            ok, guid = pcall(UnitGUID, "target")
            if not ok then guid = "(no GUID)" end

            local npcId
            if type(guid) == "string" then
                -- try common GUID patterns to extract an NPC id
                npcId = guid:match("%-(%d+)%-%x+$") or guid:match("%-(%d+)$")
            end

            local level = "?"
            ok, level = pcall(UnitLevel, "target") if not ok then level = "?" end

            local classif = "?"
            ok, classif = pcall(UnitClassification, "target") if not ok then classif = "?" end

            local ctype = "?"
            ok, ctype = pcall(UnitCreatureType, "target") if not ok then ctype = "?" end

            local hp, hpmax = "?", "?"
            ok, hp = pcall(UnitHealth, "target") if not ok then hp = "?" end
            ok, hpmax = pcall(UnitHealthMax, "target") if not ok then hpmax = "?" end

            RPE.Debug:Print(string.format("Target: %s | level=%s | guid=%s | npcId=%s | type=%s | classification=%s | HP=%s/%s",
                tostring(name), tostring(level), tostring(guid), tostring(npcId or ""), tostring(ctype), tostring(classif), tostring(hp), tostring(hpmax)
            ))
    else
    end
end
