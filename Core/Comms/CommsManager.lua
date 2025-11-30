-- RPE/Core/CommsManager.lua
RPE         = RPE or {}
RPE.Core    = RPE.Core or {}
RPE.Core.Comms = RPE.Core.Comms or {}

---@class CommsManager
local Comms = RPE.Core.Comms

-- ====== Config ======
Comms.prefix          = "RPE"   -- addon comm prefix
Comms.sendDelay       = 0.2     -- throttle between sends
Comms.maxRecvPerTick  = 10      -- how many receive msgs per frame

-- ====== Queues & state ======
Comms.sendQueue       = {}
Comms.recvQueue       = {}
Comms.handlers        = {}          -- map: msgType -> fn(data, sender)
Comms.incomingChunks  = {}          -- reassembly buffer
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
    RPE.Debug:Internal(string.format("Sending message: %s to %s", msgType, channel))

    local data = type(payload) == "table" and Serialize(payload) or tostring(payload or "")
    local msgId = NewMsgId()

    -- Chunk to safe size (<255)
    local maxLen = 200
    local totalParts = math.ceil(#data / maxLen)

    local w = RPE.Core.Windows.EventWidget
    for i = 1, totalParts do
        local chunk = data:sub((i - 1) * maxLen + 1, i * maxLen)
        local packet = string.format("%s:%s:%d:%d:%s",
            msgType, msgId, i, totalParts, chunk)

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

    C_ChatInfo.SendAddonMessage(
        self.prefix, nextMsg.msg, nextMsg.channel, nextMsg.target
    )

    C_Timer.After(self.sendDelay, function()
        self._sending = false
    end)
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
    
    local msgType, msgId, part, total, data = strsplit(":", msg, 5)
    part, total = tonumber(part), tonumber(total)

    if not msgType or not msgId or not part or not total then return end

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
            self:_Dispatch(msgType, fullData, sender)
        end
    else
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
    else
        RPE.Debug:Internal(string.format("[Comms] Unhandled message type: %s", msgType))
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
