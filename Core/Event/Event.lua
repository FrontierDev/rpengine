-- RPE/Core/Event.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local UnitClass = RPE.Core.Unit
local Resources = RPE.Core.Resources

---@class Event
---@field id string|nil
---@field name string|nil
---@field readyResponses table<string, boolean>
---@field units table<string, EventUnit>          -- key -> unit
---@field _usedIds table<integer, true>
---@field _nextId integer
---@field turn integer
---@field ticks table[]          -- { {unitA, unitB, ...}, {unitC,...}, ... }
---@field tickIndex integer
---@field localPlayerKey string|nil
---@field teamNames table[]
---@field _activeCasts table<integer, SpellCast>  -- caster unit ID -> active SpellCast object
local Event = {}
Event.__index = Event
RPE.Core.Event = Event

local isRunning = false
local isPlayerTurn = false

-- ============= Helpers =============

local function toKey(fullName)
    return type(fullName) == "string" and fullName:lower() or nil
end

local function getLocalPlayerKey()
    local me = UnitName("player")
    local realm = GetRealmName():gsub("%s+", "")
    return (me and realm) and (me .. "-" .. realm):lower() or nil
end

-- Ensure our collections/ID tracker exist and are consistent with any pre-existing units
function Event:_ensureCollections()
    self.units    = self.units    or {}
    self._usedIds = self._usedIds or {}
    self._activeCasts = self._activeCasts or {}  -- Track active SpellCast objects by caster unit ID

    local maxId = 0
    for _, u in pairs(self.units) do
        local id = u and tonumber(u.id)
        if id then
            self._usedIds[id] = true
            if id > maxId then maxId = id end
        end
    end

    self._nextId = math.max(tonumber(self._nextId) or 1, maxId + 1)
end

function Event:GetLocalPlayerUnitId()
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return nil end
    local key = ev.localPlayerKey or getLocalPlayerKey()
    local u = key and ev.units[key] or nil
    return u and u.id or nil
end


-- Permanent, monotonically increasing allocation (never reuses)
function Event:_allocId()
    self:_ensureCollections()
    while self._usedIds[self._nextId] do
        self._nextId = self._nextId + 1
    end
    local id = self._nextId
    self._usedIds[id] = true
    self._nextId = id + 1
    return id
end

-- Recompute tick buckets without advancing the turn; keep current tickIndex valid.
function Event:RebuildTicks()
    local maxTickUnits = (RPE.ActiveRules and RPE.ActiveRules.rules.max_tick_units) or 5

    -- collect + sort by initiative (desc)
    local list = {}
    for _, u in pairs(self.units or {}) do list[#list+1] = u end
    table.sort(list, function(a,b) return (a.initiative or 0) > (b.initiative or 0) end)

    -- re-bucket
    local ticks, grp = {}, {}
    for _, u in ipairs(list) do
        grp[#grp+1] = u
        if #grp >= maxTickUnits then
            ticks[#ticks+1] = grp
            grp = {}
        end
    end
    if #grp > 0 then ticks[#ticks+1] = grp end

    self.ticks = ticks
    if not self.tickIndex or self.tickIndex < 1 then self.tickIndex = 1 end
    if self.tickIndex > #self.ticks then self.tickIndex = #self.ticks end
end

function Event:IsRunning()
    return isRunning
end

-- ============= Unit API (real IDs only) =============

--- Ensure a player unit exists with a permanent id (default team=1).
---@param nameFull string  -- "Name-Realm"
---@return EventUnit|nil
function Event:EnsurePlayerUnit(nameFull)
    self:_ensureCollections()
    local key = toKey(nameFull)
    if not key or key == "" then return nil end

    local u = self.units[key]
    if not u then
        u = UnitClass.New(self:_allocId(), {
            key        = key,
            name       = nameFull,
            team       = 1,
            isNPC      = false,
            hpMax      = 100,
            hp         = 100,
            initiative = 0,
            unitType   = "Humanoid", --[[@as UnitType]]
            unitSize   = "Medium",   --[[@as UnitSize]]
            active=true, hidden=false, flying=false
        })
        self.units[key] = u
    end
    return u
end

--- Add an NPC with a permanent id; returns the created unit.
---@param npcName string
---@param team integer|nil
---@param addedByFull string|nil  -- "Name-Realm" of the adder
---@return EventUnit
function Event:AddNPC(npcName, team, addedByFull)
    self:_ensureCollections()
    npcName = npcName or "NPC"

    -- 1. Allocate numeric event id
    local id = self:_allocId()

    -- 2. Generate unique GUID for the lookup key
    local key
    if RPE.Common and RPE.Common.GenerateGUID then
        key = RPE.Common:GenerateGUID("npc")
    else
        key = string.format("npc-%d", id)
    end

    -- 3. Lookup NPC definition
    local def = RPE.Core.NPCRegistry and RPE.Core.NPCRegistry:Get(npcName)
    if not def then
        error("NPCRegistry:Get failed for name: " .. tostring(npcName))
    end

    -- 3.5. Calculate NPC team and find max enemy team size for hpPerPlayer scaling
    local npcTeam = tonumber(team) or def.team or 1
    local enemyTeamSizes = {}
    
    -- Count non-NPC units on each team
    for _, u in pairs(self.units or {}) do
        if not u.isNPC then
            local uTeam = tonumber(u.team) or 1
            if uTeam ~= npcTeam then
                enemyTeamSizes[uTeam] = (enemyTeamSizes[uTeam] or 0) + 1
            end
        end
    end
    
    -- Find the largest enemy team size
    local maxEnemyTeamSize = 0
    for _, size in pairs(enemyTeamSizes) do
        if size > maxEnemyTeamSize then
            maxEnemyTeamSize = size
        end
    end
    
    -- Calculate total HP: hpBase + (hpPerPlayer × maxEnemyTeamSize)
    local hpBase = tonumber(def.hpMax) or 100
    local hpPerPlayer = tonumber(def.hpPerPlayer) or 0
    local totalHp = hpBase + (hpPerPlayer * maxEnemyTeamSize)

    -- 4. Create the unit
    local u = UnitClass.New(id, {
        key        = key,
        name       = def.name or npcName,
        team       = npcTeam,
        isNPC      = true,
        addedBy    = addedByFull and toKey(addedByFull) or nil,

        -- Vital stats: use calculated values from NPC definition
        hpMax      = totalHp,
        hp         = tonumber(def.hpStart) or totalHp,
        initiative = 0,
        unitType   = def.unitType or "Humanoid",
        unitSize   = def.unitSize or "Medium",

        -- Model data
        fileDataId = def.fileDataId,
        displayId  = def.displayId,
        cam        = def.cam,
        rot        = def.rot,
        z          = def.z,

        -- Appearance / status
        raidMarker = def.raidMarker,
        hidden     = false,
        flying     = false,
        active     = false,

        -- Load spells (not broadcasted, but local to the session)
        spells     = def.spells or {},

        -- Stats
        stats      = def.stats or {},
    })

    self.units[key] = u
    return u
end


--- Add an NPC from the NPCRegistry into this event.
---@param npcId string
---@param opts table|nil  -- { team, raidMarker }
---@return EventUnit
function Event:AddNPCFromRegistry(npcId, opts)
    self:_ensureCollections()
    opts = opts or {}

    -- 1. Allocate a unique numeric id for this unit in the event
    local id = self:_allocId()

    -- 1.5. Calculate scaled HP based on enemy team size
    local npcTeam = tonumber(opts.team or 1)
    local enemyTeamSizes = {}
    
    -- Count non-NPC units on each team
    for _, u in pairs(self.units or {}) do
        if not u.isNPC then
            local uTeam = tonumber(u.team) or 1
            if uTeam ~= npcTeam then
                enemyTeamSizes[uTeam] = (enemyTeamSizes[uTeam] or 0) + 1
            end
        end
    end
    
    -- Find the largest enemy team size
    local maxEnemyTeamSize = 0
    for _, size in pairs(enemyTeamSizes) do
        if size > maxEnemyTeamSize then
            maxEnemyTeamSize = size
        end
    end
    
    -- Get NPC definition and calculate scaled HP
    local proto = RPE.Core.NPCRegistry:Get(npcId)
    local hpBase = tonumber(proto and proto.hpMax) or 100
    local hpPerPlayer = tonumber(proto and proto.hpPerPlayer) or 0
    local scaledHpMax = hpBase + (hpPerPlayer * maxEnemyTeamSize)

    -- 2. Build a unit seed from the registry prototype
    local seed = RPE.Core.NPCRegistry:BuildUnitSeed(npcId, {
        team       = opts.team,
        raidMarker = opts.raidMarker,
        active     = opts.active,
        hidden     = opts.hidden,
        flying     = opts.flying,
        hpMax      = scaledHpMax,
        hp         = scaledHpMax,
    })

    -- 3. Overwrite the key with a guaranteed-unique GUID
    if RPE.Common and RPE.Common.GenerateGUID then
        seed.key = RPE.Common:GenerateGUID("npc")
    else
        -- fallback: ensure it’s still unique
        seed.key = string.format("npc-%d", id)
    end

    -- Optional: keep a back-reference to the registry id for tracing
    seed.npcId = npcId
    
    -- Optional: set summoner if provided (for summoned pets/totems)
    if opts.summonedBy then
        seed.summonedBy = opts.summonedBy
    end

    -- 4. Create the unit and insert into the event
    local u = RPE.Core.Unit.New(id, seed)
    self.units[seed.key] = u
    return u
end


--- Assign or change a team number for a player or NPC in this event.
---@param keyOrFull string -- unit key or full name ("Name-Realm")
---@param team integer
function Event:SetTeamFor(keyOrFull, team)
    self:_ensureCollections()
    local key = (type(keyOrFull) == "string") and keyOrFull:lower() or nil
    if not key then
        RPE.Debug:Error("[Event:SetTeamFor] Key was nil.")
        return
    end

    local u = self.units[key]
    if u then
        u:SetTeam(team)
        RPE.Debug:Print(string.format("Unit %s now assigned to Team %d (ID #%d)", u.name, u.team, u.id))
    else
        RPE.Debug:Error("SetTeamFor: no unit found for "..tostring(keyOrFull))
    end
end

function Event:DumpUnits()
    self:_ensureCollections()
    RPE.Debug:Print("=== Event Units ===")
    local list = {}
    for _, u in pairs(self.units) do list[#list+1] = u end
    table.sort(list, function(a,b) return (a.id or 0) < (b.id or 0) end)
    for _, u in ipairs(list) do
        RPE.Debug:Print(string.format("[%d] %s (Team %d, key=%s, NPC=%s, HP=%d/%d, Init=%d)",
            u.id, u.name, u.team, u.key, tostring(u.isNPC), u.hp or 0, u.hpMax or 0, u.initiative or 0))
    end
end

function Event:UpdateUnits(opts)
    self:_ensureCollections()

    if opts and type(opts.units) == "table" and next(opts.units) ~= nil then
        for _, dto in ipairs(opts.units) do
            local key = toKey(dto.key)
            if key and not self.units[key] then
                local u = UnitClass.New(dto.id, {
                    key        = key,
                    name       = dto.name,
                    team       = dto.team,
                    isNPC      = dto.isNPC,
                    addedBy    = dto.addedBy,
                    hp         = dto.hp,
                    hpMax      = dto.hpMax,
                    initiative = dto.initiative or 0,
                    raidMarker = dto.raidMarker or nil,
                    unitType = dto.unitType,
                    unitSize = dto.unitSize,
                    active = dto.active,
                    hidden = dto.hidden,
                    flying = dto.flying,
                    stats = (type(dto.stats) == "table") and dto.stats or nil
                })
                self.units[key] = u
            else
                local u = self.units[key]
                if u then
                    u.team       = dto.team or u.team
                    u.hp         = dto.hp or u.hp
                    u.hpMax      = dto.hpMax or u.hpMax
                    u.initiative = dto.initiative or u.initiative
                    local val = tonumber(dto.raidMarker)
                    u.raidMarker = (val and val > 0) and val or nil
                    if dto.active ~= nil then u.active = dto.active end
                    if dto.hidden ~= nil then u.hidden = dto.hidden end
                    if dto.flying ~= nil then u.flying = dto.flying end

                    -- Only overwrite stats if a valid table is provided
                    if type(dto.stats) == "table" then
                        u.stats = dto.stats
                    end
                end
            end

            if dto.id then
                self._usedIds[dto.id] = true
                if dto.id >= self._nextId then self._nextId = dto.id + 1 end
            end
        end
    end

    RPE.Debug:Print("Updated units.")
end


-- ============= Initiative & Serialization =============

function Event:RollInitiatives(minVal, maxVal)
    self:_ensureCollections()
    minVal, maxVal = tonumber(minVal) or 0, tonumber(maxVal) or 20
    for _, u in pairs(self.units) do
        if u.RollInitiative then u:RollInitiative(minVal, maxVal)
        else u.initiative = math.random(minVal, maxVal) end
    end
end

function Event:_serializeUnits()
    local out = {}
    for _, u in pairs(self.units or {}) do
        out[#out+1] = {
            id         = u.id,
            key        = u.key,
            name       = u.name,
            team       = u.team,
            isNPC      = u.isNPC,
            addedBy    = u.addedBy,
            hp         = u.hp,
            hpMax      = u.hpMax,
            initiative = u.initiative or 0,
            raidMarker = u.raidMarker or nil,
            stats      = u.stats or nil,
            unitType   = u.unitType,
            unitSize   = u.unitSize,
            active     = u.active,
            hidden     = u.hidden,
            flying     = u.flying,
            fileDataId = u.fileDataId,
            displayId  = u.displayId,
            cam        = u.cam,
            rot        = u.rot,
            z          = u.z,
            spells     = u.spells,
        }
    end
    return out
end

-- ============= Lifecycle =============
--- Leader-side: prepare & ready-check. DOES NOT wipe units/IDs.
function Event:OnAwake(opts)
    self:_ensureCollections()
    self.id   = RPE.Common.GenerateGUID("EVENT")
    self.name = (opts and opts.name) or "<opts.name> missing"
    self.subtext = (opts and opts.subtext) or ""
    self.difficulty = (opts and opts.difficulty) or "NORMAL"
    self.localPlayerKey = getLocalPlayerKey()
    self.readyResponses = {}
    self.teamNames = opts.teamNames or {
        [1] = "Alliance Forces",
        [2] = "Horde Forces"
    }

    -- seed any known members from Supergroup with REAL IDs
    local sg = RPE.Core.ActiveSupergroup
    if sg and sg.GetMembers then
        for _, key in ipairs(sg:GetMembers()) do
            self:EnsurePlayerUnit(key)
        end
    else
        -- solo: ensure I exist
        local me = UnitName("player")
        local realm = GetRealmName():gsub("%s+", "")
        if me then
            self:EnsurePlayerUnit(me .. "-" .. realm)
        end
    end

    -- Ready check (leader or solo)
    if (IsInGroup() and UnitIsGroupLeader("player")) or (not IsInGroup()) then
        RPE.Core.Comms.Request:CheckReady(
            function(answer, sender)  -- per reply
                self:OnPlayerReadyResponse(sender, answer)
            end,
            function(missing)         -- timeout
                RPE.Debug:Print("Ready check timed out. Missing:")
                for _, key in ipairs(missing) do RPE.Debug:Print(" - "..key) end
            end,
            10 -- seconds (optional)
        )
    end
end

--- Leader-side: handle individual player responses.
function Event:OnPlayerReadyResponse(sender, answer)
    local key = (sender and sender:lower()) or nil
    if key and not self.units[key] then
        -- ensure sender has a real unit/id
        self:EnsurePlayerUnit(sender)
    end
    local u = key and self.units[key]

    if answer == "yes" then
        self.readyResponses[key] = true
        if u then
            RPE.Debug:Print(string.format("   - %s [Team %d | ID #%d] is ready.", sender, u.team, u.id))
        else
            RPE.Debug:Print(string.format("   - %s is ready.", sender))
        end
    elseif answer == "no" then
        self.readyResponses[key] = false
        if u then
            RPE.Debug:Error(string.format("   - %s [Team %d | ID #%d] is NOT ready.", sender, u.team, u.id))
        else
            RPE.Debug:Error(string.format("   - %s is NOT ready.", sender))
        end
    end

    -- Are all known members ready?
    local sg = RPE.Core.ActiveSupergroup
    local allReady = true
    if sg and sg.GetMembers then
        for _, member in ipairs(sg:GetMembers()) do
            if not self.readyResponses[member:lower()] then
                allReady = false
                break
            end
        end
    else
        local me = UnitName("player")
        local realm = GetRealmName():gsub("%s+", "")
        local meKey = toKey(me .. "-" .. realm)
        allReady = self.readyResponses[meKey] == true
    end

    if allReady then
        self:OnPlayersReady()
    end
end

--- Leader-side: everyone ready → roll initiatives and broadcast start.
function Event:OnPlayersReady()
    RPE.Debug:Print("All players are ready. Starting event.")

    self:RollInitiatives(0, 20)

    RPE.Core.Comms.Broadcast:StartEvent({
        id        = self.id,
        name      = self.name,
        subtext   = self.subtext,
        difficulty = self.difficulty,
        teamNames = self.teamNames,
        units     = self:_serializeUnits(),
    })
end

--- Client-side (and also executed on leader after broadcast): start the event UI, hydrate units if provided.
function Event:OnStart(opts)
    self:_ensureCollections()
    self.turn = 1
    self.ticks = {}
    self.tickIndex = 0
    self.localPlayerKey = getLocalPlayerKey()

    -- Track last-turn highlights
    self.attackedThisTurn   = {}
    self.protectedThisTurn  = {}
    self.attackedLastTurn   = {}
    self.protectedLastTurn  = {}

    self.id   = (opts and opts.id)   or self.id
    self.name = (opts and opts.name) or self.name
    self.subtext = (opts and opts.subtext) or self.subtext or ""
    self.difficulty = (opts and opts.difficulty) or self.difficulty or "NORMAL"
    self.teamNames = (opts and opts.teamNames) or {}

    -- If the leader sent units, hydrate from payload (preserve our id counters)
    self.units = {}
    if opts and type(opts.units) == "table" and next(opts.units) ~= nil then
        for _, dto in ipairs(opts.units) do
            local key = toKey(dto.key)
            if key and not self.units[key] then
                local u = UnitClass.New(dto.id, {
                    key        = key,
                    name       = dto.name,
                    team       = dto.team,
                    isNPC      = dto.isNPC,
                    addedBy    = dto.addedBy,
                    hp         = dto.hp,
                    hpMax      = dto.hpMax,
                    initiative = dto.initiative or 0,
                    raidMarker = dto.raidMarker or nil,
                    active = dto.active,
                    hidden = dto.hidden,
                    flying = dto.flying,
                    stats = (type(dto.stats) == "table") and dto.stats or nil,
                    fileDataId = dto.fileDataId,
                    displayId  = dto.displayId,
                    cam        = dto.cam,
                    rot        = dto.rot,
                    z          = dto.z,
                    spells     = dto.spells,
                })
                self.units[key] = u
            else
                local u = self.units[key]
                if u then
                    u.team       = dto.team or u.team
                    u.hp         = dto.hp or u.hp
                    u.hpMax      = dto.hpMax or u.hpMax
                    u.initiative = dto.initiative or u.initiative
                    local val = tonumber(dto.raidMarker)
                    u.raidMarker = (val and val > 0) and val or nil

                    -- Only overwrite stats if a table is provided
                    if type(dto.stats) == "table" then
                        u.stats = dto.stats
                    end
                end
            end

            if dto.id then
                self._usedIds[dto.id] = true
                if dto.id >= self._nextId then self._nextId = dto.id + 1 end
            end
        end
    end

    self._snapshot = {}
    for _, u in pairs(self.units or {}) do
        if tonumber(u.id) then
            self._snapshot[tonumber(u.id)] = u:ToSyncState()
        end
    end

    -- Event started debug message.
    RPE.Debug:Print(string.format("Event started: %s (%s)", self.name or "(nil)", self.id or "(nil)"))

    -- Make this event globally accessible to UI helpers that expect ActiveEvent
    RPE.Core.ActiveEvent = self
    isRunning = true
    RPE.Core.Windows.EventControlSheet:UpdateTickButtonState()

    -- Launch the event widget
    local uiOpts = { name = self.name, eventSubtext = self.subtext, difficulty = self.difficulty, showTurnProgress = false }
    local eventWidget = RPE_UI.Windows.EventWidget.New(uiOpts)
    RPE_UI.Common:Show(eventWidget)

    -- Launch the action bar widget
    local bar = nil
    if not RPE.Core.Windows.ActionBarWidget then
        bar = RPE_UI.Windows.ActionBarWidget.New({
            numSlots = RPE.ActiveRules:Get("action_bar_slots") or 12,
            slotSize = 32,
            spacing  = 4,
            point = "BOTTOM", rel = "BOTTOM", y = 60,
        })
    else
        RPE_UI.Common:Toggle(RPE.Core.Windows.ActionBarWidget)
        bar = RPE.Core.Windows.ActionBarWidget
    end

    -- Bind the action bar to RPE.Core.Cooldowns
    -- Use the player's numeric unit ID so cooldowns match what SpellCast.New produces
    local CD = RPE.Core.Cooldowns
    if CD and self.localPlayerKey and bar then
        local playerUnit = self.units[self.localPlayerKey]
        local playerNumericId = playerUnit and playerUnit.id
        if playerNumericId then
            CD:BindActionBar(tostring(playerNumericId), bar)
        end
    end

    -- Launch the player unit frame.
    local unitFrame = RPE_UI.Windows.PlayerUnitWidget.New({ resources = { "HEALTH", "MANA" }})
    unitFrame:Show()
    RPE.Core.Windows.PlayerUnitWidget = unitFrame

    -- Launch the unit frame grid
    local unitFrameGrid = RPE_UI.Windows.UnitFrameWidget.New()
    unitFrameGrid:Show()

    -- Prepare targeting window (hidden until a spell is cast)
    local TW = RPE_UI.Windows.TargetWindowInstance
               or RPE_UI.Windows.TargetWindow.New()
    RPE_UI.Windows.TargetWindowInstance = TW
    TW:Hide()

    -- Attach aura manager to event.
    self._auraManager = RPE.Core.AuraManager.New(self)

    -- Default chat channel (optional)
    RPE.Core.Windows.Chat:SetChannel("SAY")

    -- Send health/max health update to everyone.
    local B = RPE.Core.Comms and RPE.Core.Comms.Broadcast
    local c, m = RPE.Core.Resources:Get("HEALTH")
    if B and B.UpdateUnitHealth then
        -- Calculate total absorption from player's absorption shields
        local totalAbsorption = 0
        if self then
            local localPlayerKey = self.localPlayerKey
            if localPlayerKey and self.units and self.units[localPlayerKey] then
                local playerUnit = self.units[localPlayerKey]
                if playerUnit.absorption then
                    for _, shield in pairs(playerUnit.absorption) do
                        if shield.amount then
                            totalAbsorption = totalAbsorption + shield.amount
                        end
                    end
                end
            end
        end
        B:UpdateUnitHealth(nil, c, m, totalAbsorption)
    end

    -- Refresh action bar button states based on current equipment/inventory
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    -- Build initial ticks for turn 1 (same logic as OnTurn, but without incrementing turn)
    self.ticks = {}
    self.tickIndex = 0
    
    local maxTickUnits = (RPE.ActiveRules and RPE.ActiveRules.rules.max_tick_units) or 5
    local units = {}
    for _, u in pairs(self.units) do table.insert(units, u) end
    table.sort(units, function(a, b)
        return (a.initiative or 0) > (b.initiative or 0)
    end)
    
    local tick = {}
    for i, u in ipairs(units) do
        if u.active then
            table.insert(tick, u)
            if #tick >= maxTickUnits then
                table.insert(self.ticks, tick)
                tick = {}
            end
        end
    end
    
    if #tick > 0 then
        table.insert(self.ticks, tick)
    end
    
    RPE.Debug:Internal(string.format("Turn %d started with %d ticks", self.turn, #self.ticks))
    
    -- Show the first tick
    self:OnTick()
end

-- Leader-side
function Event:Advance()
    local UnitClass = RPE.Core.Unit
    self._snapshot = self._snapshot or {}

    -- Build "now" state map
    local now = {}
    for _, u in pairs(self.units or {}) do
        local s = u:ToSyncState()
        now[s.id] = s
    end

    -- Compute deltas
    local deltas = {}

    -- new + updated
    for id, s in pairs(now) do
        local prev = self._snapshot[id]
        if not prev then
            -- New: full fields + stats
            table.insert(deltas, { op="N", id=id, fields=s, stats=s.stats })
        else
            local changed, statsChanged = UnitClass.DiffStates(prev, s)
            local hasScalar = next(changed) ~= nil
            if hasScalar or statsChanged then
                table.insert(deltas, {
                    op="U", id=id,
                    fields = changed,
                    stats  = statsChanged and s.stats or nil
                })
            end
        end
    end

    -- removed
    for id, _ in pairs(self._snapshot) do
        if not now[id] then
            table.insert(deltas, { op="R", id=id })
        end
    end

    -- Roll snapshot forward
    self._snapshot = now

    -- Turn vs tick unchanged
    local mode
    if not self.ticks or not self.tickIndex or self.tickIndex >= #self.ticks then
        mode = "turn"
    else
        mode = "tick"
    end

    RPE.Core.Comms.Broadcast:Advance({
        id     = self.id,
        name   = self.name,
        mode   = mode,
        deltas = deltas,     -- <=== new path
    })
end

-- Sent by the group leader to end the event on all clients.
function Event:OnEnd(opts)
    RPE.Debug:Print("Ending event: " .. tostring(self.name or "(nil)"))
    RPE.Core.Comms.Broadcast:EndEvent()
end

function Event:OnEndClient(opts)
    RPE.Debug:Print("Event ended: " .. tostring(self.name or "(nil)"))

    -- Close all event-related UI
    RPE_UI.Common:Hide(RPE.Core.Windows.EventWidget)
    RPE_UI.Common:Hide(RPE.Core.Windows.ActionBarWidget)
    RPE_UI.Common:Hide(RPE.Core.Windows.PlayerUnitWidget)
    RPE_UI.Common:Hide(RPE.Core.Windows.UnitFrameWidget)
    RPE_UI.Common:Hide(RPE.Core.Windows.TargetWindowInstance)

    -- Reset the event.
    isRunning = false
    isPlayerTurn = false
    RPE.Core.Windows.EventControlSheet:UpdateTickButtonState()
end

function Event:MarkAttacked(unitId)
    unitId = tonumber(unitId); if not unitId then return end
    self.attackedThisTurn = self.attackedThisTurn or {}
    self.attackedThisTurn[unitId] = true
end

function Event:MarkProtected(unitId)
    unitId = tonumber(unitId); if not unitId then return end
    self.protectedThisTurn = self.protectedThisTurn or {}
    self.protectedThisTurn[unitId] = true
end

-- Client-side
function Event:AdvanceClient(mode, units, subtext)
    if units then
        self:UpdateUnits({ units = units })
    end

    -- Changing the subtext doesnt do anything currently. NYI.

    if mode == "turn" then
        self:OnTurn()
    elseif mode == "tick" then
        self:OnTick()
    end
end

--- Expire absorption shields that have reached their duration
function Event:_ExpireAbsorptionShields()
    if not (self and self.units) then return end
    
    for _, unit in pairs(self.units) do
        if unit.absorption then
            local expired = {}
            
            -- Check each shield for expiry
            for shieldId, shield in pairs(unit.absorption) do
                if shield.duration and shield.appliedTurn then
                    local turnsElapsed = (self.turn or 0) - (shield.appliedTurn or 0)
                    if turnsElapsed >= shield.duration then
                        table.insert(expired, shieldId)
                        if RPE and RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal(string.format(
                                "[Event] Shield %s expired on %s (duration=%d, elapsed=%d turns)",
                                shieldId, unit.name or tostring(unit.id), shield.duration, turnsElapsed
                            ))
                        end
                    end
                end
            end
            
            -- Remove expired shields
            for _, shieldId in ipairs(expired) do
                unit.absorption[shieldId] = nil
            end
        end
    end
end

function Event:OnTurn()
    self.turn = (self.turn or 0) + 1
    
    -- Reset help call flag at the start of each new turn
    RPE.Core._helpCalledThisTurn = false
    
    -- Expire absorption shields at the start of each turn
    self:_ExpireAbsorptionShields()
    
    self.ticks = {}
    self.tickIndex = 0

    -- Roll previous-turn markers, then clear current-turn accumulators
    self.attackedLastTurn  = self.attackedThisTurn  or {}
    self.protectedLastTurn = self.protectedThisTurn or {}
    self.attackedThisTurn, self.protectedThisTurn = {}, {}

    local maxTickUnits = (RPE.ActiveRules and RPE.ActiveRules.rules.max_tick_units) or 5

    -- collect + sort
    local units = {}
    for _, u in pairs(self.units) do table.insert(units, u) end
    table.sort(units, function(a, b)
        return (a.initiative or 0) > (b.initiative or 0)
    end)

    -- assign only active units into tick groups
    local tick = {}
    for i, u in ipairs(units) do
        if u.active then
            table.insert(tick, u)
            if #tick >= maxTickUnits then
                table.insert(self.ticks, tick)
                tick = {}
            end
        end
    end

    if #tick > 0 then
        table.insert(self.ticks, tick)
    end

    RPE.Debug:Internal(string.format("Turn %d started with %d ticks", self.turn, #self.ticks))
    self:OnTick()
end

function Event:OnTick()
    -- Increase the tick index.
    self.tickIndex = (self.tickIndex or 0) + 1
    local tickUnits = self.ticks[self.tickIndex]

    -- === Log NPCs in the current tick group ===
    for _, u in ipairs(tickUnits or {}) do
        if u.isNPC and u.active then
        end
    end

    if not tickUnits then
        RPE.Debug:Internal("All ticks done for this turn.")
        return
    end

    RPE.Debug:Internal(string.format("Tick %d/%d", self.tickIndex, #self.ticks))

    -- update the widget
    local widget = RPE.Core.Windows.EventWidget
    if widget and widget.ShowTick then
        widget:ShowTick(self.turn, self.tickIndex, #self.ticks, tickUnits)

        if widget.balanceBar then
            widget.balanceBar:Calculate(self)
        end
    end

    -- Refresh action bar requirements at the start of each tick
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    if self.localPlayerKey then
        -- End the player's current turn if it was their turn last turn.
        if isPlayerTurn then self:OnPlayerTickEnd() end

        -- Reset.
        isPlayerTurn = false
        for _, u in ipairs(tickUnits) do
            if u.key == self.localPlayerKey then
                -- Start player turn.
                self:OnPlayerTickStart()
                break
            end
        end
    end

    -- Process NPC turns (active casts)
    self:OnNPCTickStart()
    
    -- End NPC turns (aura expiration)
    self:OnNPCTickEnd()
end

--- Called locally when the player's turn starts.
function Event:OnPlayerTickStart()
    if not isPlayerTurn then isPlayerTurn = true end

    -- Reset help flag for new turn
    local prWidget = RPE.Core.Windows and RPE.Core.Windows.PlayerReactionWidget
    if prWidget and prWidget._helpUsedThisTurn ~= nil then
        prWidget._helpUsedThisTurn = false
    end

    -- Ping the player and alert them that their turn started.
    local icon = (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Warning) or ""
    PlaySound(12889) -- RaidWarning

    -- Recover only the local player's resources
    RPE.Core.Resources:OnPlayerTurnStart()

    -- Tick player's active cast from registry
    -- This ensures the player's actual cast (in _activeCasts) is processed, not just what's
    -- displayed in the cast bar. This matters when we temporarily control another unit,
    -- because the cast bar shows the controlled unit's cast, but we need to continue
    -- ticking the player's actual cast.
    local playerUnitId = self:GetLocalPlayerUnitId()
    if playerUnitId then
        local playerCast = self._activeCasts and self._activeCasts[playerUnitId]
        if playerCast then
            local ctx = { event = self, resources = RPE.Core.Resources, cooldowns = RPE.Core.Cooldowns }
            -- Tick will internally handle:
            -- 1. Decrementing remainingTurns
            -- 2. Calling CB:Update() to update the cast bar
            -- 3. If complete, CB:Update -> CB:Finish -> Resolve -> ClearCast from registry
            playerCast:Tick(ctx, self.turn)
        end
    end

    -- Tick auras.
    self._auraManager:OnOwnerTurnStart(self.localPlayerKey, self.turn)
    RPE.Debug:Internal(('[Event:OnPlayerTickStart] Calling OnTick for turn %d'):format(self.turn))
    self._auraManager:OnTick(self.turn)

    -- Tick cooldowns.
    local CD = RPE.Core.Cooldowns
    if CD then CD:OnPlayerTickStart(self.turn) end

    -- Refresh action bar button states at player turn start
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    -- Show last-turn attacked/protected icons (only last turn)
    do
        -- 1) Clear everything
        for _, u in pairs(self.units or {}) do
            if u.SetAttackedLast  then u:SetAttackedLast(false) end
            if u.SetProtectedLast then u:SetProtectedLast(false) end
        end

        -- 2) Set "attacked last" for units hit last turn
        for id in pairs(self.attackedLastTurn or {}) do
            for _, u in pairs(self.units or {}) do
                if tonumber(u.id) == tonumber(id) and u.SetAttackedLast then
                    u:SetAttackedLast(true)
                    break
                end
            end
        end
        
        -- 3) Set "protected last" for units healed/protected last turn
        for id in pairs(self.protectedLastTurn or {}) do
            for _, u in pairs(self.units or {}) do
                if tonumber(u.id) == tonumber(id) and u.SetProtectedLast then
                    u:SetProtectedLast(true)
                    break
                end
            end
        end
    end
end

function Event:OnPlayerTickEnd()
    -- Ping the player and alert them that their turn ended.
    local icon = (RPE.Common and RPE.Common.InlineIcons and RPE.Common.InlineIcons.Warning) or ""

    if RPE.Core.Resources:Has("ACTION") and RPE.Core.Resources:Has("BONUS_ACTION") then
        Resources:Set("ACTION", 0)
        Resources:Set("BONUS_ACTION", 0)
    end

    -- Refresh action bar requirements at the start of each tick
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    self._auraManager:OnOwnerTurnEnd(self.localPlayerKey, self.turn)
end

-- ============= NPC TURN =============
function Event:OnNPCTickStart()
    -- Process any active casts for NPC units
    -- This includes NPCs that were added to the tick, PLUS any NPCs with active casts that might not be in the tick
    -- (e.g., NPCs being controlled by the player in temporary mode)
    
    -- First, process NPCs that are in the current tick
    local tickUnits = self.ticks[self.tickIndex]
    if tickUnits then
        for i, unit in ipairs(tickUnits) do
            local castId = tonumber(unit.id)
            local cast = castId and self._activeCasts and self._activeCasts[castId]
            if cast then
                self:_TickCast(cast)
            end
        end
    end
    
    -- ALSO process any OTHER NPCs that have active casts but aren't in the tick
    -- This handles temporary mode where an NPC is being controlled
    if self._activeCasts then
        for unitId, cast in pairs(self._activeCasts) do
            local unit = self.units[unitId] or self:_LookupUnitById(unitId)
            if unit and unit.isNPC then
                -- Check if this unit is already in the tick
                local isInTick = false
                if tickUnits then
                    for _, tickUnit in ipairs(tickUnits) do
                        if tonumber(tickUnit.id) == unitId then
                            isInTick = true
                            break
                        end
                    end
                end
                
                if not isInTick then
                    self:_TickCast(cast)
                end
            end
        end
    end

    -- Refresh action bar button states at NPC turn start
    local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
    if actionBar and actionBar.RefreshRequirements then
        actionBar:RefreshRequirements()
    end

    -- Handle aura expiration for NPCs on their turn start
    local tickUnits = self.ticks[self.tickIndex]
    if tickUnits and self._auraManager then
        for _, unit in ipairs(tickUnits) do
            if unit.isNPC and unit.active then
                local npcId = tonumber(unit.id)
                if npcId then
                    self._auraManager:OnOwnerTurnStart(npcId, self.turn)
                end
            end
        end
    end
end

-- Helper to tick a single cast
function Event:_TickCast(cast)
    local ctx = {
        event      = self,
        resources  = nil,  -- NPCs don't spend resources
        cooldowns  = RPE.Core.Cooldowns,
        actionBar  = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget,
    }
    
    if RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[Event:_TickCast] Ticking NPC cast, caster=%s, remainingTurns=%d, currentTurn=%d'):format(
            tostring(cast.caster),
            cast.remainingTurns or -1,
            self.turn
        ))
    end
    
    cast:Tick(ctx, self.turn)
end

-- Helper to look up unit by numeric ID
function Event:_LookupUnitById(unitId)
    -- Check units table
    if self.units then
        for key, unit in pairs(self.units) do
            if tonumber(unit.id) == unitId then
                return unit
            end
        end
    end
    return nil
end


-- Debug helper to show what casts are registered
function Event:_DebugCastKeys()
    if not self._activeCasts then return "nil" end
    local keys = {}
    for k, _ in pairs(self._activeCasts) do
        table.insert(keys, tostring(k))
    end
    return table.concat(keys, ", ") or "(empty)"
end

function Event:OnNPCTickEnd()
    -- Handle aura expiration for NPCs that just finished their turn
    local tickUnits = self.ticks[self.tickIndex]
    if not tickUnits then return end
    
    for _, unit in ipairs(tickUnits) do
        if unit.isNPC and unit.active and self._auraManager then
            local npcId = tonumber(unit.id)
            if npcId then
                self._auraManager:OnOwnerTurnEnd(npcId, self.turn)
            end
        end
    end
end

-- ============= Multi-Cast Tracking API =============
---Register an active cast for a specific caster unit.
---@param casterUnitId integer  -- Unit ID of the caster
---@param cast SpellCast        -- The SpellCast object to track
function Event:RegisterCast(casterUnitId, cast)
    if not casterUnitId or not cast then return end
    casterUnitId = tonumber(casterUnitId)
    if not casterUnitId or casterUnitId <= 0 then return end
    
    self._activeCasts = self._activeCasts or {}
    self._activeCasts[casterUnitId] = cast
end

---Unregister/clear a cast for a specific caster unit.
---@param casterUnitId integer
function Event:ClearCast(casterUnitId)
    if not self._activeCasts then return end
    casterUnitId = tonumber(casterUnitId)
    if casterUnitId then
        local cast = self._activeCasts[casterUnitId]
        self._activeCasts[casterUnitId] = nil
    end
end

---Get the active cast for a specific caster unit (if any).
---@param casterUnitId integer
---@return SpellCast|nil
function Event:GetActiveCast(casterUnitId)
    if not self._activeCasts then return nil end
    casterUnitId = tonumber(casterUnitId)
    if not casterUnitId then return nil end
    return self._activeCasts[casterUnitId]
end

-- ============= Initialisers =============
--- Leader entrypoint: reuse the global instance; never create a throwaway.
function Event.StartEvent(opts)
    local self = RPE.Core.ActiveEvent
    if not self or getmetatable(self) ~= Event then
        self = setmetatable(self or {}, Event)
        RPE.Core.ActiveEvent = self
    end

    self:_ensureCollections()
    self:OnAwake(opts or {})
    return self
end

--- Client entrypoint: create a local instance if needed, then start.
function Event.StartEventClient(opts)
    local self = RPE.Core.ActiveEvent
    if not self or getmetatable(self) ~= Event then
        self = setmetatable({}, Event)
        RPE.Core.ActiveEvent = self
    end
    self:_ensureCollections()
    self:OnStart(opts or {})
    return self
end

-- ============= Event End =============
function Event.EndEvent(opts)
    local self = RPE.Core.ActiveEvent
    self:OnEnd(opts or {})
end

-- ============= Global ActiveEvent instance =============
-- Ensure ActiveEvent is a real, persistent instance from the start.
RPE.Core.ActiveEvent = RPE.Core.ActiveEvent or setmetatable({
    id = nil,
    name = nil,
    readyResponses = {},
    units = {},
    _usedIds = {},
    _nextId = 1,
}, Event)

return Event
