-- RPE/Core/Comms/Request.lua
RPE         = RPE or {}
RPE.Core    = RPE.Core or {}
RPE.Core.Comms = RPE.Core.Comms or {}

local Comms   = RPE.Core.Comms
local Request = {}
RPE.Core.Comms.Request = Request

Request._pending = {}
Request._counter = 0

---------------------------------------------------
-- Helpers
---------------------------------------------------
local function NewRequestId()
    Request._counter = Request._counter + 1
    return tostring(Request._counter) .. "-" .. tostring(time())
end

-- Generate a hash representing the current active datasets and ruleset
local function GenerateDatasetRulesetHash()
    local hashData = {}
    
    -- Helper function to recursively hash table contents
    local function hashTable(tbl, prefix)
        if not tbl or type(tbl) ~= "table" then return end
        
        local keys = {}
        for k, _ in pairs(tbl) do
            table.insert(keys, tostring(k))
        end
        table.sort(keys)  -- Ensure consistent ordering
        
        for _, k in ipairs(keys) do
            local v = tbl[k]
            local key = prefix .. k
            
            if type(v) == "table" then
                hashTable(v, key .. ".")
            else
                table.insert(hashData, key .. "=" .. tostring(v))
            end
        end
    end
    
    -- Add active ruleset data with full rule content
    if RPE.ActiveRules then
        table.insert(hashData, "RULESET:" .. tostring(RPE.ActiveRules.name or ""))
        
        -- Hash the actual rules content
        if RPE.ActiveRules.rules then
            hashTable(RPE.ActiveRules.rules, "RULE.")
        end
        
        -- Include other ruleset data
        if RPE.ActiveRules.data then
            hashTable(RPE.ActiveRules.data, "DATA.")
        end
    end
    
    -- Add active datasets with actual content
    local DatasetDB = RPE.Profile and RPE.Profile.DatasetDB
    if DatasetDB then
        local activeNames = DatasetDB.GetActiveNamesForCurrentCharacter()
        if activeNames then
            table.sort(activeNames)  -- Ensure consistent ordering
            
            for _, datasetName in ipairs(activeNames) do
                table.insert(hashData, "DATASET:" .. datasetName)
                
                -- Get the actual dataset and hash its content
                local dataset = DatasetDB.GetByName(datasetName)
                if dataset then
                    -- Hash spells, items, NPCs, stats, etc.
                    if dataset.spells then hashTable(dataset.spells, "SPELL.") end
                    if dataset.items then hashTable(dataset.items, "ITEM.") end
                    if dataset.npcs then hashTable(dataset.npcs, "NPC.") end
                    if dataset.stats then hashTable(dataset.stats, "STAT.") end
                    if dataset.auras then hashTable(dataset.auras, "AURA.") end
                    if dataset.recipes then hashTable(dataset.recipes, "RECIPE.") end
                    if dataset.reagents then hashTable(dataset.reagents, "REAGENT.") end
                end
            end
        end
    end
    
    -- Create a simple hash from the concatenated data
    local dataString = table.concat(hashData, "|")
    local hash = 0
    for i = 1, #dataString do
        hash = (hash * 31 + string.byte(dataString, i)) % 2147483647
    end
    return tostring(hash)
end

-- Check if a member is online in the group or is an NPC in the active event
local function IsOnlineGroupMember(memberKey)
    local meName, meRealm = UnitName("player")
    local meFull = (meName and ((meRealm and meRealm ~= "" and (meName.."-"..meRealm:gsub("%s+", ""))) or (meName.."-"..GetRealmName():gsub("%s+", "")))) or nil
    local meKey = meFull and meFull:lower()
    
    if memberKey == meKey then
        return true
    end
    
    -- Check if member is an NPC in the active event
    local ev = RPE.Core.ActiveEvent
    if ev and ev.units then
        for _, unit in pairs(ev.units) do
            if unit.key and unit.key:lower() == memberKey then
                if unit.isNPC then
                    return true  -- NPCs are always "ready"
                end
            end
        end
    end
    
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unitToken = "raid" .. i
            local n, r = UnitName(unitToken)
            if n then
                local lower = (n .. "-" .. (r or GetRealmName())):gsub("%s+", ""):lower()
                if lower == memberKey then
                    return UnitIsConnected(unitToken)
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unitToken = "party" .. i
            local n, r = UnitName(unitToken)
            if n then
                local lower = (n .. "-" .. (r or GetRealmName())):gsub("%s+", ""):lower()
                if lower == memberKey then
                    return UnitIsConnected(unitToken)
                end
            end
        end
    end
    
    return false
end

---------------------------------------------------
-- Ready check
---------------------------------------------------
--- Ready check across the Supergroup.
--- @param callback   fun(answer:string, sender:string)|nil   -- fires once per reply
--- @param onTimeout  fun(missing:string[])|nil               -- fires once if time runs out, with missing name-keys
--- @param timeoutSec number|nil                              -- default 10
function Request:CheckReady(callback, onTimeout, timeoutSec)
    local sg = RPE.Core.ActiveSupergroup
    if not sg then
        if callback then callback("yes", UnitName("player")) end
        return
    end

    local rulesetName = RPE.ActiveRules.name
    local datasetRulesetHash = GenerateDatasetRulesetHash()

    -- Make sure my local Blizzard roster is in the supergroup snapshot
    local meName, meRealm = UnitName("player")
    local meFull = (meName and ((meRealm and meRealm ~= "" and (meName.."-"..meRealm:gsub("%s+", ""))) or (meName.."-"..GetRealmName():gsub("%s+", "")))) or nil

    local members = sg:GetMembers() -- canonical keys (lowercased full names)
    if #members == 0 then
        if callback then callback("yes", meFull or UnitName("player")) end
        return
    end

    local meKey = meFull and meFull:lower()

    local reqId = NewRequestId()
    local expected = {}
    
    for _, key in ipairs(members) do
        if IsOnlineGroupMember(key) then
            expected[key] = true
        else
            RPE.Debug:Internal("Skipping offline/non-group member: " .. key)
        end
    end

    -- Create pending entry
    self._pending[reqId] = {
        callback  = callback,
        onTimeout = onTimeout,
        expected  = expected,          -- map of who we still wait for (keys)
        timeout   = GetTime() + (timeoutSec or 10),
    }

    -- Debug: show who we're waiting for
    local expectedList = {}
    for key in pairs(expected) do
        table.insert(expectedList, key)
    end

    -- Mark self ready immediately (don’t whisper yourself)
    if meKey and expected[meKey] then
        expected[meKey] = nil
        if callback and meFull then callback("yes", meFull) end
        if not next(expected) then
            -- Everyone was just me; clean up and exit
            self._pending[reqId] = nil
            return
        end
    end

    -- Whisper everyone else using the same canonical key string
    for key in pairs(expected) do
        Comms:Send("REQ_READY", { reqId, "ping", rulesetName, datasetRulesetHash }, "WHISPER", key)
    end
end

--- payload = { mode="EMOTE"/"SAY"/"YELL", leaderText="...", responseText="..." }
--- @param callback   fun(answer:boolean, sender:string)|nil
--- @param onTimeout  fun(missing:string[])|nil
--- @param timeoutSec number|nil
function Request:CheckChanter(payload, callback, onTimeout, timeoutSec)
    local sg = RPE.Core.ActiveSupergroup
    if not sg then return end

    local reqId   = NewRequestId()
    local members = sg:GetMembers()

    self._pending[reqId] = {
        kind      = "CHANTER",
        started   = time(),
        responses = {},
        members   = members,
        callback  = callback,   -- 🔑 keep same style as CheckReady
        onTimeout = onTimeout,
        timeout   = GetTime() + (timeoutSec or 10),
    }

    -- Serialize payload into semicolon-delimited flat array
    local msg = {
        reqId,
        payload.mode or "",
        payload.leaderText or "",
        payload.responseText or "",
    }
    RPE.Core.Comms:Send("REQ_CHANTER", msg, "RAID")

    return reqId
end

-- payload = { mode="EMOTE"/"SAY"/"YELL", leaderText="...", responseText="..." }
function Request:ChanterPerform(reqId, payload)
    if not reqId or not payload then return end
    RPE.Core.Comms:Send("CHANTER_PERFORM", {
        reqId,
        payload.mode or "",
        payload.leaderText or "",
        payload.responseText or "",
    }, "RAID")
end

---------------------------------------------------
-- Handlers
---------------------------------------------------

-- Member receives a ready check request. Here we will check if the player's active datasets and ruleset
-- hash matches that of the group leader's. If it does, then we will impose certain restrictions such
-- as:
--     * only allow equipment slots that are in the ruleset; unequip items from others.
--     * only allow spells from specific datasets.
--        etc...
Comms:RegisterHandler("REQ_READY", function(data, sender)
    local args  = { strsplit(";", data) }
    local reqId, _, rulesetName, leaderHash = args[1], args[2], args[3], args[4]

    -- Generate our own hash and compare with leader's hash
    local myHash = GenerateDatasetRulesetHash()
    
    if myHash == leaderHash then
        Request:Respond(reqId, "READY", "yes", sender)
    else
        -- Log mismatch for debugging
        RPE.Debug:Warning(string.format("[ReadyCheck] Dataset/Ruleset mismatch with leader %s. My hash: %s, Leader hash: %s", 
            sender, myHash or "nil", leaderHash or "nil"))
        Request:Respond(reqId, "READY", "no", sender)
    end
end)

-- Leader receives a response
Comms:RegisterHandler("RESP_READY", function(data, sender)
    local args          = { strsplit(";", data) }
    local reqId, answer = args[1], args[2]

    local pending = Request._pending[reqId]
    if not pending then return end

    local senderKey = sender:lower()  -- match supergroup keys
    pending.expected[senderKey] = nil

    -- Per-response callback (if provided)
    if pending.callback then
        local ok, err = pcall(pending.callback, answer, sender)
        if not ok then
            RPE.Debug:Error("[Request] READY callback failed: " .. tostring(err))
        end
    end

    -- Remove any members from expected who are no longer online/in-group
    for key in pairs(pending.expected) do
        if not IsOnlineGroupMember(key) then
            pending.expected[key] = nil
            RPE.Debug:Warning("Member " .. key .. " no longer online/in-group, removing from ready check.")
        end
    end

    -- If nobody left waiting, clear the request
    if not next(pending.expected) then
        Request._pending[reqId] = nil
    else
        local remainingList = {}
        for key in pairs(pending.expected) do
            table.insert(remainingList, key)
        end
    end
end)

-- Member receives a request for their supergroup roster
-- In SG_REQUEST_ROSTER handler, BEFORE sending the roster back:
Comms:RegisterHandler("SG_REQUEST_ROSTER", function(data, sender)
    local sg = RPE.Core.ActiveSupergroup
    if not sg or not sg.GetMembers then return end

    -- I am responding to someone else's request => I am NOT the leader.
    RPE.Core.isLeader = false

    -- Build and send roster
    local roster = {}
    for _, member in ipairs(sg:GetMembers()) do
        roster[#roster+1] = member
    end
    Comms:Send("SG_RESP_ROSTER", { sender, unpack(roster) }, "WHISPER", sender)
end)


-- Member receives a roster response from a leader
Comms:RegisterHandler("SG_RESP_ROSTER", function(data, sender)
    if not data or #data < 1 then return end
    local leaderName = sender
    local roster = {}
    for i = 2, #data do
        table.insert(roster, data[i])
    end

    RPE.Core.ActiveSupergroup:AddRosterFromLeader(leaderName, roster)
end)

Comms:RegisterHandler("REQ_CHANTER", function(data, sender)
    local args = { strsplit(";", data) }
    local reqId, mode, leaderText, responseText = args[1], args[2], args[3], args[4]

    local payload = {
        mode        = mode,
        leaderText  = leaderText,
        responseText= responseText,
    }

    local meName, meRealm = UnitName("player")
    local meFull = meName .. "-" .. (meRealm and meRealm ~= "" and meRealm or GetRealmName())
    meFull = meFull:gsub("%s+", ""):lower()

    -- ensure there is a pending entry with a timeout
    Request._pending[reqId] = Request._pending[reqId] or {
        responses = {},
        timeout   = GetTime() + 30, -- prevent nil timeout
        kind      = "CHANTER",
    }

    if string.lower(sender) ~= string.lower(meFull) then
        local recv = RPE_UI.Common:GetWindow("ChanterReceiverWindow")
        if not recv then recv = RPE_UI.Windows.ChanterReceiverWindow.New(payload) end

        recv.onAccept = function()
            -- record local acceptance so we can later perform
            Request._pending[reqId].responses[meFull] = true

            RPE.Core.Comms:Send("RESP_CHANTER", { reqId, "yes" }, "WHISPER", sender)
        end
        
        recv.onDecline = function()
            Request._pending[reqId].responses[meFull] = false

            RPE.Core.Comms:Send("RESP_CHANTER", { reqId, "no" }, "WHISPER", sender)
        end

        recv.leaderText:SetText(leaderText or "—")
        recv.respText:SetText(responseText or "—")
        recv:Show()
    else
        RPE.Core.Comms:Send("RESP_CHANTER", { reqId, "yes" }, "WHISPER", sender)
    end
end)



Comms:RegisterHandler("RESP_CHANTER", function(data, sender)
    local args = { strsplit(";", data) }
    local reqId, answer = args[1], args[2]

    local req = Request._pending[reqId]
    if not req or req.kind ~= "CHANTER" then return end

    req.responses[sender] = (answer == "yes")

    -- ✅ Debug log: leader sees a response
    if RPE.Debug and RPE.Debug.Info then
        RPE.Debug:Info(string.format("[Request] CHANTER response from %s: %s", sender, tostring(answer)))
    end

    -- Per-response callback
    if req.callback then
        local ok, err = pcall(req.callback, answer, sender)
        if not ok then
            RPE.Debug:Error("[Request] CHANTER callback failed: " .. tostring(err))
        end
    end

    -- Check if all members responded
    local allDone = true
    for _, member in ipairs(req.members) do
        if req.responses[member] == nil then
            allDone = false
            break
        end
    end

    if allDone then
        Request._pending[reqId] = nil
        if RPE.Debug and RPE.Debug.Info then
            RPE.Debug:Info(string.format("[Request] CHANTER %s complete, all responses received.", reqId))
        end
    end
end)

Comms:RegisterHandler("CHANTER_PERFORM", function(data, sender)
    local args = { strsplit(";", data) }
    local reqId, mode, leaderText, responseText = args[1], args[2], args[3], args[4]

    RPE.Debug:Internal(("Received CHANTER_PERFORM message for chanter request %s (%s) from %s"):format(reqId, mode, sender))

    -- Build canonical player name (Name-Realm)
    local meName, meRealm = UnitName("player")
    local meFull = meName .. "-" .. (meRealm and meRealm ~= "" and meRealm or GetRealmName())
    meFull = meFull:gsub("%s+", ""):lower()
    sender = sender:lower()

    mode = (mode == "YELL" or mode == "EMOTE") and mode or "SAY"

    local function performLine(text, channelMode)
        if not text or text == "" then return end
        if text:sub(1,1) == "/" then
            -- Slash command (drop the slash)
            ChatFrame1EditBox:SetText(text)
            ChatEdit_SendText(ChatFrame1EditBox, 0)
        else
            -- Normal chat message
            C_ChatInfo.SendChatMessage(text, channelMode or "SAY", nil, nil)
        end
    end

    if sender == meFull then
        -- Leader performs their line
        performLine(leaderText, mode)
    else
        -- Recipients perform their response only if they accepted
        local req = Request._pending[reqId]
        if req and req.responses and req.responses[meFull] then
            C_Timer.After(1, function()
                performLine(responseText, mode)
            end)
        end
    end

    -- Cleanup after performance
    Request._pending[reqId] = nil
end)


---------------------------------------------------
-- Respond
---------------------------------------------------
function Request:Respond(reqId, respType, payload, target)
    local data = type(payload) == "table" and table.concat(payload, ";") or tostring(payload or "")
    local wrapped = { reqId, data }
    Comms:Send("RESP_" .. respType, wrapped, "WHISPER", target)
end

---------------------------------------------------
-- Timeout cleanup
---------------------------------------------------
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()
    local now = GetTime()
    for reqId, info in pairs(Request._pending) do
        if now > info.timeout then
            -- Build list of missing responders
            local missing = {}
            for key in pairs(info.expected or {}) do
                table.insert(missing, key)
            end
            -- Notify
            if info.onTimeout then
                local ok, err = pcall(info.onTimeout, missing)
                if not ok then
                    RPE.Debug:Error("[Request] onTimeout failed: " .. tostring(err))
                end
            end
            -- Drop the request
            Request._pending[reqId] = nil
        end
    end
end)
