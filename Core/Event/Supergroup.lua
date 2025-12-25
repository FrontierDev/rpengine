-- RPE/Core/Supergroup.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

---@class Supergroup
---@field members table<string, true>   -- set of "name-realm" (lowercased)
---@field _list string[]                -- stable array view of members
---@field _trackedMembers table<string, true>  -- track online members to detect disconnects
local Supergroup = {}
Supergroup.__index = Supergroup
RPE.Core.Supergroup = Supergroup

-- Global live instance so everyone can append/consume
RPE.Core.ActiveSupergroup = RPE.Core.ActiveSupergroup or setmetatable({
    members = {},
    _list   = {},
    _trackedMembers = {},
}, Supergroup)

-- ==========================================================
-- Utilities
-- ==========================================================

local function RealmSlug(s) return s and s:gsub("%s+", "") or "" end

--- Build canonical keys.
--- @return string|nil lowerKey, string|nil display
local function ToFullKey(name, realm)
    if not name or name == "" then return nil, nil end
    local r = (realm and realm ~= "" and realm) or (GetRealmName() or "")
    r = RealmSlug(r)
    local display = name .. "-" .. r
    return display:lower(), display
end

--- From a unit token like "raid1", "party2", "player".
--- @return string|nil lowerKey
local function TokenToKey(token)
    local n, r = UnitName(token)
    if not n then return nil end
    local lower = ToFullKey(n, r)
    return lower
end

local function rebuildList(self)
    local out = {}
    for k in pairs(self.members or {}) do out[#out+1] = k end
    table.sort(out) -- stable, lexicographic
    self._list = out
end

-- Whenever membership changes, make sure Event has REAL units/IDs.
local function SyncEventWithMembers(self)
    local ev = RPE.Core.ActiveEvent
    if not ev or not ev.EnsurePlayerUnit then return end
    for key in pairs(self.members or {}) do
        ev:EnsurePlayerUnit(key) -- permanent id assigned once
    end
end

-- ==========================================================
-- Public API
-- ==========================================================

--- Returns a stable, sorted array of member keys ("name-realm", lowercased).
function Supergroup:GetMembers()
    return self._list or {}
end

--- Ensure a member exists in the supergroup. Returns true if added.
function Supergroup:Add(fullNameOrLower)
    if not fullNameOrLower or fullNameOrLower == "" then return false end
    local lower = fullNameOrLower:lower()
    self.members = self.members or {}
    if not self.members[lower] then
        self.members[lower] = true
        rebuildList(self)
        SyncEventWithMembers(self)
        return true
    end
    return false
end

--- Remove a member (if present). Returns true if removed.
function Supergroup:Remove(fullNameOrLower)
    if not fullNameOrLower or fullNameOrLower == "" then return false end
    local lower = fullNameOrLower:lower()
    if self.members and self.members[lower] then
        self.members[lower] = nil
        rebuildList(self)
        -- DO NOT delete Event units; IDs are permanent.
        return true
    end
    return false
end

--- Add the local player explicitly (solo or otherwise), or add a named player.
function Supergroup:AddSoloPlayer(fullName)
    if not fullName or fullName == "" then
        local n, r = UnitName("player")
        if not n then return end
        fullName = (n .. "-" .. RealmSlug(r or GetRealmName() or "")):lower()
    else
        fullName = fullName:lower()
    end
    self:Add(fullName)
end

--- Merge all members of the PLAYER'S CURRENT GROUP (party/raid) into the supergroup.
function Supergroup:MergeFromMyGroup()
    -- Ensure local player
    local me = TokenToKey("player")
    if me then self:Add(me) end

    if IsInRaid() then
        local n = GetNumGroupMembers() or 0
        for i = 1, n do
            local k = TokenToKey("raid" .. i)
            if k then self:Add(k) end
        end
    elseif IsInGroup() then
        local n = GetNumGroupMembers() or 0
        for i = 1, math.max(0, n - 1) do
            local k = TokenToKey("party" .. i)
            if k then self:Add(k) end
        end
    end
end

--- A remote leader provides a roster (array of "Name-Realm" strings).
---@param _leaderIgnored any  -- (old API arg kept for compatibility; unused)
---@param roster string[]
function Supergroup:AddRosterFromLeader(_leaderIgnored, roster)
    if type(roster) ~= "table" then return end
    for _, v in ipairs(roster) do
        if type(v) == "string" and v ~= "" then
            self:Add(v:lower())
        end
    end
end

--- Rebuild from current game state.
function Supergroup:Rebuild()
    self.members = self.members or {}
    self:MergeFromMyGroup()
    rebuildList(self)
    SyncEventWithMembers(self)
end

--- Check for members who have gone offline and update the event accordingly.
function Supergroup:CheckForOfflineMembers()
    if not IsInGroup() then return end
    
    local currentMembers = {}
    
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unitToken = "raid" .. i
            local name, realm = UnitName(unitToken)
            if name then
                local lower = ToFullKey(name, realm)
                if lower and UnitIsConnected(unitToken) then
                    currentMembers[lower] = true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unitToken = "party" .. i
            local name, realm = UnitName(unitToken)
            if name then
                local lower = ToFullKey(name, realm)
                if lower and UnitIsConnected(unitToken) then
                    currentMembers[lower] = true
                end
            end
        end
    end
    
    -- Add the local player (always connected)
    local meKey = TokenToKey("player")
    if meKey then
        currentMembers[meKey] = true
    end
    
    -- Check for members who were online but are now gone (disconnect or logout)
    for memberKey in pairs(self._trackedMembers or {}) do
        if not currentMembers[memberKey] then
            -- This member went offline
            if RPE and RPE.Core and RPE.Core.ActiveEvent then
                local ev = RPE.Core.ActiveEvent
                if ev.units and ev.units[memberKey] then
                    local unitId = ev.units[memberKey].id or "?"
                    if ev.turn and ev.turn > 0 then
                        -- Event is running: mark inactive
                        ev.units[memberKey].active = false
                        RPE.Debug:Print(string.format("%s has been marked as inactive (left the game).", memberKey, unitId))
                    else
                        -- Event not started: remove from list
                        ev.units[memberKey] = nil
                        RPE.Debug:Print(string.format("%s has been removed from the event (left the game).", memberKey, unitId))
                    end
                end
            end
        end
    end
    
    -- Check for members who came back online (were offline but are now online)
    for memberKey in pairs(currentMembers) do
        if not (self._trackedMembers and self._trackedMembers[memberKey]) then
            -- This member just came online
            RPE.Debug:Print(string.format("%s has come online.", memberKey))
            if RPE and RPE.Core and RPE.Core.ActiveEvent then
                local ev = RPE.Core.ActiveEvent
                if ev.turn and ev.turn > 0 then
                    -- Event is running: resync the player
                    if ev.units and ev.units[memberKey] then
                        ev.units[memberKey].active = true
                    end
                    local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
                    if Broadcast and Broadcast.ResyncPlayer then
                        Broadcast:ResyncPlayer(memberKey)
                        RPE.Debug:Print(string.format("%s has rejoined the event.", memberKey))
                    end
                end
            end
        end
    end
    
    -- Update tracked members for next check
    self._trackedMembers = currentMembers
end

-- ==========================================================
-- Bootstrap & events
-- ==========================================================

local function OnRosterEvent(selfSG)
    -- Merge current WoW group state into the supergroup and sync event units.
    selfSG:Rebuild()
end

do
    local SG = RPE.Core.ActiveSupergroup

    -- Build initial state on load (after a frame so UnitName/realm are valid)
    C_Timer.After(0, function()
        OnRosterEvent(SG)
    end)

    -- Keep it fresh on roster changes / zoning
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function()
        OnRosterEvent(SG)
    end)

    -- Expose a simple manual refresh (debug)
    function Supergroup.DebugRefresh()
        OnRosterEvent(SG)
        RPE.Debug:Print("Supergroup refreshed.")
    end
end

return Supergroup
