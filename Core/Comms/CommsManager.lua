-- RPE/Core/CommsManager.lua
RPE         = RPE or {}
RPE.Core    = RPE.Core or {}
RPE.Core.Comms = RPE.Core.Comms or {}

---@class CommsManager
local Comms = RPE.Core.Comms

-- ====== Config ======
Comms.prefix          = "RPE"   -- addon comm prefix
Comms.sendDelay       = 0.2     -- throttle between sends
Comms.maxRecvPerTick  = 100     -- how many receive msgs per frame (increased from 10 to process faster)

-- ====== Queues & state ======
Comms.sendQueue       = {}
Comms.recvQueue       = {}
Comms.handlers        = {}          -- map: msgType -> fn(data, sender)
Comms.incomingChunks  = {}          -- reassembly buffer
Comms.objectTracking  = {}          -- track objects being received: sender -> msgType -> { current, total }
Comms._msgCounter     = 0
Comms._sending        = false

---------------------------------------------------
-- Utilities
---------------------------------------------------
local function Serialize(tbl)
    -- naive: joins with ; (replace with something more robust later)
    return table.concat(tbl, ";")
end

local function Deserialize(str)
    return { strsplit(";", str) }
end

local function NewMsgId()
    Comms._msgCounter = Comms._msgCounter + 1
    return tostring(Comms._msgCounter) .. "-" .. tostring(time())
end

---------------------------------------------------
-- Sending
---------------------------------------------------
---Queue a message for sending (auto-chunk if >255).
---@param msgType string
---@param payload table|string
---@param channel string
---@param target string|nil
function Comms:Send(msgType, payload, channel, target)
    local data = type(payload) == "table" and Serialize(payload) or tostring(payload or "")
    local msgId = NewMsgId()

    -- WoW addon message hard limit is 255 bytes total
    -- Account for header: "TYPE:msgId:part:total:" which varies in size
    -- Use 180 bytes as safe chunk size to leave room for variable-length headers
    local maxLen = 180
    local totalParts = math.ceil(#data / maxLen)

    local w = RPE.Core.Windows.EventWidget
    for i = 1, totalParts do
        local chunk = data:sub((i - 1) * maxLen + 1, i * maxLen)
        local packet = string.format("%s:%s:%d:%d:%s",
            msgType, msgId, i, totalParts, chunk)

        RPE.Debug:Internal("Packet " .. packet)

        table.insert(self.sendQueue, {
            msg     = packet,
            channel = channel or "PARTY",
            target  = target,
        })

        if w and w.FlashSend then w:FlashSend() end
    end
end

function Comms:ProcessSendQueue()
    if self._sending or #self.sendQueue == 0 then return end
    local nextMsg = table.remove(self.sendQueue, 1)
    self._sending = true

    local result = C_ChatInfo.SendAddonMessage(
        self.prefix, nextMsg.msg, nextMsg.channel, nextMsg.target
    )

    if result == 0 then
        -- ✅ Success: move to next message
        RPE.Debug:Internal(string.format("[Comms] Message sent successfully on channel %s", nextMsg.channel))
        self._sending = false
        self:ProcessSendQueue()  -- Process next immediately
    elseif result == 3 or result == 8 then
        -- 3 = ADDON_MESSAGE_THROTTLE, 8 = CHANNEL_THROTTLE
        -- Re-queue the message and wait
        table.insert(self.sendQueue, 1, nextMsg)
        RPE.Debug:Internal(string.format("[Comms] Throttled (code %d), will retry in %.2fs", result, self.sendDelay))
        C_Timer.After(self.sendDelay, function()
            self._sending = false
            self:ProcessSendQueue()
        end)
    else
        -- Other error codes: discard and move on
        local errorNames = {
            [1] = "InvalidPrefix",
            [2] = "InvalidMessage",
            [4] = "InvalidChatType",
            [5] = "NotInGroup",
            [6] = "TargetRequired",
            [7] = "InvalidChannel",
            [9] = "GeneralError",
        }
        local errorName = errorNames[result] or "Unknown"
        RPE.Debug:Warning(string.format("[Comms] SendAddonMessage failed: code %d (%s), discarding message", result, errorName))
        self._sending = false
        self:ProcessSendQueue()  -- Skip this message and process next
    end
end

---------------------------------------------------
-- Receiving
---------------------------------------------------
---Called directly from CHAT_MSG_ADDON.
function Comms:OnAddonMessage(prefix, msg, sender)
    if prefix ~= self.prefix then return end
    table.insert(self.recvQueue, { msg = msg, sender = sender })
end

---Process up to maxRecvPerTick messages from the recv queue.
function Comms:ProcessRecvQueue()
    for i = 1, self.maxRecvPerTick do
        local item = table.remove(self.recvQueue, 1)
        if not item then break end
        self:_ProcessReceived(item.msg, item.sender)
    end
end

function Comms:_ProcessReceived(msg, sender)
    -- Expect: "TYPE:msgId:part:total:data"
    local w = RPE.Core.Windows.EventWidget
    if w and w.FlashRecv then w:FlashRecv() end
    
    -- Show loading widget during data reception
    local LoadingWidget = RPE_UI and RPE_UI.Widgets and RPE_UI.Widgets.LoadingWidget
    
    local msgType, msgId, part, total, data = strsplit(":", msg, 5)
    part, total = tonumber(part), tonumber(total)

    if not msgType or not msgId or not part or not total then 
        RPE.Debug:Warning(string.format("[Comms] Malformed message from %s", sender))
        return 
    end

    -- Map message types to human-readable names
    local typeLabels = {
        RULESET_META = "Metadata",
        RULESET_RULE = "Rules",
        RULESET_COMPLETE = "Complete",
        DATASET_META = "Metadata",
        DATASET_ITEM = "Items",
        DATASET_SPELL = "Spells",
        DATASET_AURA = "Auras",
        DATASET_NPC = "NPCs",
        DATASET_RECIPES = "Recipes",
        DATASET_INTERACTIONS = "Interactions",
        EXTRA = "Extra",
        DATASET_COMPLETE = "Complete",
    }
    local label = typeLabels[msgType] or msgType
    
    -- Only show loading widget for ruleset and dataset messages (not other message types)
    local isDataMessage = msgType:match("^RULESET_") or msgType:match("^DATASET_")
    
    -- Track object count per sender/msgType (increment on first chunk only)
    if isDataMessage and part == 1 then
        local key = sender .. ":" .. msgType
        if not self.objectTracking[key] then
            self.objectTracking[key] = { current = 0, total = 0 }
        end
        self.objectTracking[key].current = self.objectTracking[key].current + 1
    end
    
    -- Update progress display with object count (only for data messages)
    if isDataMessage and LoadingWidget then 
        LoadingWidget:Show()
        local key = sender .. ":" .. msgType
        local tracking = self.objectTracking[key]
        if tracking then
            LoadingWidget:SetProgress(string.format("%s (%d)", label, tracking.current))
        else
            LoadingWidget:SetProgress(label)
        end
    end

    RPE.Debug:Internal(string.format("[Comms] Received %s part %d/%d from %s (msgId=%s)", msgType, part, total, sender, msgId))

    if total > 1 then
        local entry = self.incomingChunks[msgId] or { total = total, parts = {}, sender = sender }
        entry.parts[part] = data
        self.incomingChunks[msgId] = entry

        -- complete?
        local complete = true
        for j = 1, total do
            if not entry.parts[j] then complete = false break end
        end
        if complete then
            local fullData = table.concat(entry.parts, "")
            self.incomingChunks[msgId] = nil
            RPE.Debug:Internal(string.format("[Comms] Reassembled %s from %d chunks (total size: %d bytes)", msgType, total, #fullData))
            self:_Dispatch(msgType, fullData, sender)
        else
            RPE.Debug:Internal(string.format("[Comms] Buffered chunk %d/%d for %s (msgId=%s)", part, total, msgType, msgId))
        end
    else
        RPE.Debug:Internal(string.format("[Comms] Received complete %s from %s (size: %d bytes)", msgType, sender, #data))
        self:_Dispatch(msgType, data, sender)
    end
end

---------------------------------------------------
-- Dispatch
---------------------------------------------------
function Comms:RegisterHandler(msgType, fn)
    RPE.Debug:Internal(string.format("Registered Comms handler: %s", msgType))
    self.handlers[msgType] = fn
end

function Comms:_Dispatch(msgType, raw, sender)
    local fn = self.handlers[msgType]
    if fn then
        local ok, err = pcall(fn, raw, sender)
        if not ok then
            RPE.Debug:Error(string.format("[Comms] Handler for %s failed: %s", msgType, err))
        end
        
        -- Hide loading widget only when entire dataset/ruleset is complete
        -- (Don't hide on individual object completion - that causes blinking)
        local LoadingWidget = RPE_UI and RPE_UI.Widgets and RPE_UI.Widgets.LoadingWidget
        if msgType == "DATASET_COMPLETE" or msgType == "RULESET_COMPLETE" then
            if LoadingWidget then LoadingWidget:Hide() end
        end
    else
        RPE.Debug:Internal(string.format("[Comms] Unhandled message type: %s", msgType))
    end
    
    -- Clear tracking for this sender/msgType when complete message is dispatched
    if msgType == "DATASET_COMPLETE" or msgType == "RULESET_COMPLETE" then
        -- Clear all tracking for this sender
        for key in pairs(self.objectTracking) do
            if key:match("^" .. sender:gsub("%p", "%%%0")) then
                self.objectTracking[key] = nil
            end
        end
    end
end

---------------------------------------------------
-- Init
---------------------------------------------------
-- Frame to pump queues
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()
    Comms:ProcessSendQueue()
    Comms:ProcessRecvQueue()
end)

-- Register CHAT_MSG_ADDON listener
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, event, prefix, message, channel, sender, ...)
    if event == "CHAT_MSG_ADDON" then
        -- Pass prefix, message, and sender correctly
        Comms:OnAddonMessage(prefix, message, sender)
    end
end)
