-- Core.lua
local Core = {}
_G.RPE.Core = Core

RPE.Core.ImmersionMode = true

RPE.Core.Windows = RPE.Core.Windows or {}
RPE.Core.StatModifiers = {
    equip = {}, -- equip[profileId][statId] = number
    aura  = {}, -- aura[profileId][statId]  = number
}

-- Supergroup leadership flag (default solo => leader)
RPE.Core.isLeader = true

-- Blizzard party/raid leader takes precedence; otherwise use our supergroup flag.
function RPE.Core.IsLeader()
    if IsInRaid() or IsInGroup() then
        return UnitIsGroupLeader("player")
    end
    local v = RPE.Core.isLeader
    if v == nil then return true end
    return v and true or false
end


-- Announce local player's TRP3 display name when entering world or joining a group.
do
    local lastAnnounce = 0
    local function AnnounceIfAvailable()
        local now = time()
        if now - lastAnnounce < 5 then return end
        lastAnnounce = now

        local trpName = nil
        -- Prefer the shared Common helper if available
        if RPE and RPE.Common and RPE.Common.GetTRP3NameForUnit then
            local ok, res = pcall(function() return RPE.Common:GetTRP3NameForUnit("player") end)
            if ok and res and res ~= "" then trpName = res end
        end

        -- Fallback to TRP3 API directly
        if not trpName and _G and _G.TRP3_API and _G.TRP3_API.register and _G.TRP3_API.register.getPlayerCompleteName then
            local ok, res = pcall(function() return _G.TRP3_API.register.getPlayerCompleteName(false) end)
            if ok and res and res ~= "" then trpName = res end
        end

        if trpName and trpName ~= "" and RPE and RPE.Core and RPE.Core.Comms and RPE.Core.Comms.Broadcast and RPE.Core.Comms.Broadcast.AnnounceTRPName then
            RPE.Core.Comms.Broadcast:AnnounceTRPName(trpName)
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(string.format("[Core] Announced TRP name: %s", trpName))
            end
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            AnnounceIfAvailable()
        elseif event == "GROUP_ROSTER_UPDATE" then
            if IsInGroup() then AnnounceIfAvailable() end
        end
    end)
end