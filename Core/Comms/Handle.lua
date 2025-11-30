-- RPE/Core/Comms/Handle.lua
RPE              = RPE or {}
RPE.Core         = RPE.Core or {}
RPE.Core.Comms   = RPE.Core.Comms or {}


local Common       = RPE and RPE.Common
local AuraManager  = RPE.Core and RPE.Core.AuraManager
local AuraRegistry = RPE.Core and RPE.Core.AuraRegistry
local Comms        = RPE.Core.Comms
local Handle       = RPE.Core.Comms.Handle or {}

RPE.Core.Comms.Handle = Handle

-- Helpers --
local function _unesc(s)
    if not s then return "" end
    s = s:gsub("%%0A", "\n"):gsub("%%3B", ";"):gsub("%%25", "%%")
    return s
end

local function _mgr()
    local ev = RPE.Core.ActiveEvent
    return ev._auraManager
end

-- Receive a ruleset push: name ; count ; k1 ; v1 ; k2 ; v2 ; ...
Comms:RegisterHandler("RULESET_PUSH", function(data, sender)
    local RulesetDB       = RPE.Profile and RPE.Profile.RulesetDB
    local RulesetProfile  = RPE.Profile and RPE.Profile.RulesetProfile
    if not (RulesetDB and RulesetProfile) then
        RPE.Debug:Error("[Handle] RulesetDB/Profile missing; cannot apply incoming ruleset.")
        return
    end

    local args = { strsplit(";", data) }
    local name = args[1]
    local n    = tonumber(args[2] or "0") or 0

    if not name or name == "" then
        RPE.Debug:Error("[Handle] RULESET_PUSH missing ruleset name.")
        return
    end

    -- Rebuild rules table
    local rules = {}
    local idx = 3
    for i = 1, n do
        local k = args[idx];      idx = idx + 1
        local v = args[idx];      idx = idx + 1
        if k and k ~= "" then
            rules[k] = v -- keep as string (ActiveRules will coerce/parse)
        end
    end

    -- Upsert ruleset locally
    local rs = RulesetDB.GetOrCreateByName(name, { rules = rules })
    -- Overwrite rules (so updates replace prior)
    rs.rules = rules
    rs.updatedAt = time() or rs.updatedAt
    RulesetDB.Save(rs)

    -- Make it the active ruleset for this character
    RulesetDB.SetActiveForCurrentCharacter(name)

    -- Refresh live ActiveRules snapshot
    if RPE.ActiveRules and RPE.ActiveRules.SetRuleset then
        RPE.ActiveRules:SetRuleset(rs)
    end

    RPE.Debug:Print(string.format("[Handle] Applied incoming ruleset '%s' from %s and set it active.", name, sender))
end)

Comms:RegisterHandler("START_EVENT", function(data, sender)
    local args = { strsplit(";", data) }
    local id   = args[1]
    local name = args[2]

    -- Determine if subtext and difficulty are present (new format)
    local subtext, difficulty, teamNamesStr, startIdx
    if args[5] ~= nil and tonumber(args[5]) == nil then
        -- New format: subtext and difficulty present
        subtext      = _unesc(args[3] or "")
        difficulty   = args[4] or "NORMAL"
        teamNamesStr = args[5] or ""
        startIdx     = 6
    elseif args[4] ~= nil and tonumber(args[4]) == nil then
        -- Older new format: subtext present but no difficulty
        subtext      = _unesc(args[3] or "")
        difficulty   = "NORMAL"
        teamNamesStr = args[4] or ""
        startIdx     = 5
    else
        -- Oldest format: no subtext or difficulty
        subtext      = ""
        difficulty   = "NORMAL"
        teamNamesStr = args[3] or ""
        startIdx     = 4
    end

    local teamNames = {}
    local idx = 1
    for tn in string.gmatch(teamNamesStr, "([^,]+)") do
        teamNames[idx] = tn
        idx = idx + 1
    end

    local units = {}
    local i = startIdx
    while i <= #args do
        local u = {}
        u.id         = tonumber(args[i]); i = i + 1
        u.key        = args[i];           i = i + 1
        u.name       = args[i];           i = i + 1
        u.team       = tonumber(args[i]); i = i + 1
        u.isNPC      = args[i] == "1";    i = i + 1
        u.hp         = tonumber(args[i]); i = i + 1
        u.hpMax      = tonumber(args[i]); i = i + 1
        u.initiative = tonumber(args[i]); i = i + 1
        u.raidMarker = tonumber(args[i]); i = i + 1
        if not u.raidMarker or u.raidMarker <= 0 then
            u.raidMarker = nil
        end
        u.unitType = args[i] ~= "" and args[i] or nil; i = i + 1
        u.unitSize = args[i] ~= "" and args[i] or nil; i = i + 1
        u.active   = args[i] == "1"; i = i + 1
        u.hidden   = args[i] == "1"; i = i + 1
        u.flying   = args[i] == "1"; i = i + 1

        -- New: parse stats string
        u.stats = {}
        local statsStr = args[i] or ""; i = i + 1
        if statsStr ~= "" then
            for pair in string.gmatch(statsStr, "([^,]+)") do
                local k, v = pair:match("([^=]+)=([^=]+)")
                if k then
                    u.stats[k] = tonumber(v) or 0
                end
            end
        end

        u.fileDataId = tonumber(args[i]) or nil; i = i + 1
        u.displayId  = tonumber(args[i]) or nil; i = i + 1
        u.cam        = tonumber(args[i]) or nil; i = i + 1
        u.rot        = tonumber(args[i]) or nil; i = i + 1
        u.z          = tonumber(args[i]) or nil; i = i + 1
        
        -- New: parse spells string
        local spellsStr = args[i] or ""; i = i + 1
        u.spells = {}
        if spellsStr ~= "" then
            for sid in string.gmatch(spellsStr, "([^,]+)") do
                if sid and sid ~= "" then
                    table.insert(u.spells, sid)
                end
            end
        end
        units[#units+1] = u
    end

    RPE.Core.ActiveEvent:OnStart({
        id        = id,
        name      = name,
        subtext   = subtext,
        difficulty = difficulty,
        teamNames = teamNames,
        units     = units,
    })
end)



-- Receive an advance (either start of a new turn or a new tick)
Comms:RegisterHandler("ADVANCE", function(data, sender)
    local UnitClass = RPE.Core.Unit
    local args = { strsplit(";", data) }
    local id   = args[1]
    local name = args[2]
    local subtext = args[3]
    local mode    = args[4]

    if not id or not name or not mode then
        RPE.Debug:Error("[Handle] ADVANCE missing id, name, or mode.")
        return
    end

    local ev = RPE.Core.ActiveEvent
    if not ev then
        RPE.Debug:Error("[Handle] ADVANCE but no ActiveEvent.")
        return
    end
    ev._snapshot = ev._snapshot or {}

    -- New delta format? args[5] == "DELTAS"
    if args[5] == "DELTAS" then
        local n = tonumber(args[6]) or 0
        local i = 7
        local structureChanged = false   -- ✅ track roster changes

        for _ = 1, n do
            local uId = tonumber(args[i]) or 0; i = i + 1
            local op  = args[i] or "U";          i = i + 1
            local kvS = args[i] or "";           i = i + 1
            local stS = args[i] or "";           i = i + 1

            local fields = UnitClass.KVDecode(kvS)
            local stats  = (stS ~= "" and UnitClass.StatsDecode(stS)) or nil

            if op == "N" then
                local key = fields.key and fields.key:lower() or nil
                if key then
                    local u = ev.units[key]
                    if not u then
                        u = UnitClass.New(uId, {
                            key        = key,
                            name       = fields.name,
                            team       = fields.team,
                            isNPC      = fields.isNPC,
                            hp         = fields.hp,
                            hpMax      = fields.hpMax,
                            initiative = fields.initiative or 0,
                            raidMarker = fields.raidMarker or nil,
                            unitType   = fields.unitType,
                            unitSize   = fields.unitSize,
                            active     = fields.active or false,
                            hidden     = fields.hidden or false,
                            flying     = fields.flying or false,
                        })
                        ev.units[key] = u
                        structureChanged = true
                    else
                        UnitClass.ApplyKV(u, fields)
                    end
                    if type(stats) == "table" then u.stats = stats end
                    ev._snapshot[uId] = u:ToSyncState()
                end

            elseif op == "U" then
                local target
                for _, uu in pairs(ev.units or {}) do
                    if tonumber(uu.id) == uId then target = uu break end
                end
                if target then
                    UnitClass.ApplyKV(target, fields)
                    if type(stats) == "table" then target.stats = stats end
                    ev._snapshot[uId] = target:ToSyncState()
                end

            elseif op == "R" then
                for k, uu in pairs(ev.units or {}) do
                    if tonumber(uu.id) == uId then ev.units[k] = nil break end
                end
                ev._snapshot[uId] = nil
                structureChanged = true
            end
        end

        -- ✅ Keep UI/state sane after roster changes
        -- Only rebuild ticks if we're at the START of a turn (tickIndex == 0)
        -- Mid-turn additions will be processed in the next turn's batching
        if structureChanged and ev.RebuildTicks then
            -- Only rebuild if we're not currently in the middle of processing ticks
            if ev.tickIndex == 0 then
                ev:RebuildTicks()
            end
            -- Don't refresh portrait row here - let ShowTick handle it after AdvanceClient
            if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
                RPE.Core.Windows.UnitFrameWidget:Refresh(true)
            end
        end

        ev:AdvanceClient(mode, nil, subtext)
        return
    end

    -------------------------------------------------------------------------
    -- Legacy path: full units list (kept for backward compatibility)
    -------------------------------------------------------------------------
    local units = {}
    local i = 5
    while i <= #args do
        local u = {}
        u.id         = tonumber(args[i]); i = i + 1
        u.key        = args[i];           i = i + 1
        u.name       = args[i];           i = i + 1
        u.team       = tonumber(args[i]); i = i + 1
        u.isNPC      = args[i] == "1";    i = i + 1
        u.hp         = tonumber(args[i]); i = i + 1
        u.hpMax      = tonumber(args[i]); i = i + 1
        u.initiative = tonumber(args[i]); i = i + 1
        local rm     = tonumber(args[i]); i = i + 1
        u.raidMarker = (rm and rm > 0) and rm or nil
        u.unitType = args[i] ~= "" and args[i] or nil; i = i + 1
        u.unitSize = args[i] ~= "" and args[i] or nil; i = i + 1
        u.active = args[i] == "1"; i = i + 1
        u.hidden = args[i] == "1"; i = i + 1
        u.flying = args[i] == "1"; i = i + 1

        -- stats CSV
        u.stats = {}
        local statsCSV = args[i] or "";   i = i + 1
        for pair in string.gmatch(statsCSV, "([^,]+)") do
            local k, v = pair:match("([^=]+)=([^=]+)")
            if k then u.stats[k] = tonumber(v) or 0 end
        end

        units[#units+1] = u
    end

    ev:AdvanceClient(mode, units, subtext)
end)


Comms:RegisterHandler("END_EVENT", function(data, sender)

    local ev = RPE.Core.ActiveEvent
    if not ev then
        RPE.Debug:Error("[Handle] END_EVENT but no ActiveEvent.")
        return
    end

    ev:OnEndClient()
end)

-- APPLY
Comms:RegisterHandler("AURA_APPLY", function(data, sender)
    if sender == UnitName("player") then return end
    local args = { strsplit(";", data) }
    local sId, tId = tonumber(args[1]) or 0, tonumber(args[2]) or 0
    local auraId, stacks, desc = args[3], tonumber(args[5]) or 0, _unesc(args[6] or "")

    if tId == 0 or not auraId or auraId == "" then 
        RPE.Debug:Error("[Handle:AURA_APPLY] Aura ID was not valid.")
        return 
    end

    local mgr = _mgr(); if not mgr then return end
    mgr._netSquelch = true
    local ok, err = pcall(function()
        mgr:Apply(sId ~= 0 and sId or nil, tId, auraId, {
            stacks = (stacks > 0) and stacks or nil,
            -- description is UI-only; your tooltip can read desc from the aura instance if you store it,
            -- or just use local AuraRegistry text. We're not mutating instance here.
        })
    end)
    mgr._netSquelch = false
    if not ok and RPE and RPE.Debug and RPE.Debug.Error then
        RPE.Debug:Error("[Handle] AURA_APPLY error: " .. tostring(err))
    end
end)

-- REMOVE: tId ; auraId ; fromSourceId
Comms:RegisterHandler("AURA_REMOVE", function(data, sender)
    if sender == UnitName("player") then return end
    local args = { strsplit(";", data) }
    local tId  = tonumber(args[1]) or 0
    local aura = args[2]
    local sId  = tonumber(args[3] or "0") or 0
    if tId == 0 or not aura or aura == "" then return end

    local mgr = _mgr(); if not mgr then return end
    mgr._netSquelch = true
    local ok, err = pcall(function()
        mgr:Remove(tId, aura, (sId ~= 0) and sId or nil)
    end)
    mgr._netSquelch = false
    if not ok and RPE and RPE.Debug and RPE.Debug.Error then
        RPE.Debug:Error("[Handle] AURA_REMOVE error: " .. tostring(err))
    end
end)

-- DISPEL: tId ; typesCSV ; max ; helpful01
Comms:RegisterHandler("AURA_DISPEL", function(data, sender)
    if sender == UnitName("player") then return end
    local args = { strsplit(";", data) }
    local tId  = tonumber(args[1]) or 0
    local types = {}
    for ty in (args[2] or ""):gmatch("([^,]+)") do types[#types+1] = ty end
    local max     = tonumber(args[3]) or 1
    local helpful = (args[4] == "1")
    if tId == 0 then return end

    local mgr = _mgr(); if not mgr then return end
    mgr._netSquelch = true
    local ok, err = pcall(function()
        mgr:Dispel(tId, { types = types, max = max, helpful = helpful })
    end)
    mgr._netSquelch = false
    if not ok and RPE and RPE.Debug and RPE.Debug.Error then
        RPE.Debug:Error("[Handle] AURA_DISPEL error: " .. tostring(err))
    end
end)


-- === Scaffold: remote stat modifications (currently rejected) ===============
-- STATMOD: tId ; auraId ; instanceId ; op ; statId ; value
Comms:RegisterHandler("AURA_STATMOD", function(data, sender)
    -- Disabled by default: we don't accept remote stat writes yet.
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Print("[Handle] Ignored AURA_STATMOD from " .. tostring(sender) .. " (remote stat mods disabled).")
    end
end)

Comms:RegisterHandler("DAMAGE", function(data, sender)
    -- Do NOT early-return on self: SpellActions no longer applies locally.
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end

    -- helper to find a unit quickly
    local function findUnitById(tid)
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == tid then return u end
        end
    end

    while i <= #args do
        local tId    = tonumber(args[i]) or 0; i = i + 1
        local amount = math.max(0, math.floor(tonumber(args[i]) or 0)); i = i + 1
        local school = args[i] or "";                                      i = i + 1
        local isCrit = (args[i] == "1");                                   i = i + 1
        local tDelta = tonumber(args[i] or ""); if tDelta == nil then tDelta = amount end; i = i + 1

        if tId > 0 and amount > 0 then
            local target = findUnitById(tId)
            if target then
                target:ApplyDamage(amount)
                if sId ~= 0 then target:AddThreat(sId, tDelta) end

                local getMyId = RPE.Core.GetLocalPlayerUnitId
                local myId    = getMyId and getMyId() or nil
                
                if myId and sId == myId then
                    -- target:SetAttackedLast(true)
                end

                if myId and tId == myId then
                    RPE.Core.Windows.PlayerUnitWidget:Refresh()
                end

                -- Portrait updates handled by ShowTick

                -- optional: route crit/school to UI if you like
            end
        end
    end
end)

Comms:RegisterHandler("HEAL", function(data, sender)
    -- Do NOT early-return on self: SpellActions no longer applies locally.
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end

    -- helper to find a unit quickly
    local function findUnitById(tid)
        for _, u in pairs(ev.units) do
            if tonumber(u.id) == tid then return u end
        end
    end

    while i <= #args do
        local tId    = tonumber(args[i]) or 0; i = i + 1
        local amount = math.max(0, math.floor(tonumber(args[i]) or 0)); i = i + 1
        local isCrit = (args[i] == "1");                                i = i + 1
        local tDelta = tonumber(args[i] or "") or 0; i = i + 1

        if tId > 0 and amount > 0 then
            local target = findUnitById(tId)
            if target then
                target:Heal(amount)
                if sId ~= 0 then target:AddThreat(sId, -tDelta) end -- heals often reduce threat vs damage

                local getMyId = RPE.Core.GetLocalPlayerUnitId
                local myId    = getMyId and getMyId() or nil

                if myId and sId == myId then
                    -- target:SetProtectedLast(true) -- already handled via Event:MarkProtected
                end

                if myId and tId == myId then
                    RPE.Core.Windows.PlayerUnitWidget:Refresh()
                end

                -- Portrait updates handled by ShowTick

                -- optional: route crit flag to UI
            end
        end
    end
end)

-- HEALTH: tId ; hp ; hpMax
Comms:RegisterHandler("HEALTH", function(data, sender)
    local args = { strsplit(";", data) }
    local tId   = tonumber(args[1]) or 0
    local hp    = tonumber(args[2]) or 0
    local hpMax = tonumber(args[3]) or 1
    if tId == 0 then return end

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    local unit = Common:FindUnitById(tId)
    if not unit then return end

    -- Clamp + apply
    hp    = Common:Clamp(hp,    0, hpMax)
    hpMax = Common:Clamp(hpMax, 1, hpMax)
    unit.hpMax = hpMax
    unit.hp    = hp

    -- Debug
    local debug = false
    if debug and  RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Print(("%s%s → %d/%d")
            :format(Common.InlineIcons.Health,
                    unit.name or ("#" .. tId),
                    unit.hp, unit.hpMax))
    end

    -- UI refresh
    local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
    if myId and tonumber(unit.id) == tonumber(myId) then
        if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
            RPE.Core.Windows.PlayerUnitWidget:Refresh()
        end
    end
    -- Portrait updates handled by ShowTick
    if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
        RPE.Core.Windows.UnitFrameWidget:Refresh(true)
    end
end)

-- UNIT_HEALTH: tId ; hp ; hpMax (for any unit, including NPCs)
Comms:RegisterHandler("UNIT_HEALTH", function(data, sender)
    local args = { strsplit(";", data) }
    local tId   = tonumber(args[1]) or 0
    local hp    = tonumber(args[2]) or 0
    local hpMax = tonumber(args[3]) or 1
    if tId == 0 then return end

    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return end
    local unit = Common:FindUnitById(tId)
    if not unit then return end

    -- Clamp + apply
    hp    = Common:Clamp(hp,    0, hpMax)
    hpMax = Common:Clamp(hpMax, 1, hpMax)
    unit.hpMax = hpMax
    unit.hp    = hp

    -- Debug
    local debug = true
    if debug and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Print(("%s%s → %d/%d")
            :format(Common.InlineIcons.Health,
                    unit.name or ("#" .. tId),
                    unit.hp, unit.hpMax))
    end

    -- UI refresh - refresh EventWidget's portrait row if unit is in current tick
    if RPE.Core.Windows and RPE.Core.Windows.EventWidget then
        RPE.Core.Windows.EventWidget:RefreshPortraitRow(false)
    end
    
    -- Also refresh UnitFrameWidget
    if RPE.Core.Windows and RPE.Core.Windows.UnitFrameWidget then
        RPE.Core.Windows.UnitFrameWidget:Refresh(true)
    end
    
    -- Also refresh PlayerUnitWidget if this is the local player
    local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
    if myId and tonumber(unit.id) == tonumber(myId) then
        if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
            RPE.Core.Windows.PlayerUnitWidget:Refresh()
        end
    end
end)

-- ATTACK_SPELL: sId ; tId ; spellId ; spellName ; hitSystem ; attackRoll ; thresholdStatsCSV ; damageCSV ; auraEffectsJSON
Comms:RegisterHandler("ATTACK_SPELL", function(data, sender)
    local args = { strsplit(";", data) }
    local i    = 1
    local sId  = tonumber(args[i]) or 0; i = i + 1
    local tId  = tonumber(args[i]) or 0; i = i + 1
    local spellId = args[i] or ""; i = i + 1
    local spellName = args[i] or ""; i = i + 1
    local hitSystem = args[i] or "complex"; i = i + 1
    local attackRoll = tonumber(args[i]) or 0; i = i + 1
    local thresholdStatsCSV = args[i] or ""; i = i + 1
    local damageCSV = args[i] or ""; i = i + 1
    local auraEffectsJSON = args[i] or ""; i = i + 1

    if sId == 0 or tId == 0 or spellId == "" or spellName == "" then
        RPE.Debug:Warning("[Handle] ATTACK_SPELL missing required fields")
        return
    end

    -- Parse threshold stats from CSV
    local thresholdStats = {}
    if thresholdStatsCSV ~= "" then
        for stat in string.gmatch(thresholdStatsCSV, "([^,]+)") do
            local trimmed = stat:match("^%s*(.-)%s*$")
            if trimmed ~= "" then
                table.insert(thresholdStats, trimmed)
            end
        end
    end

    -- Parse damage by school from CSV (format: school1:amount1,school2:amount2,...)
    local damageBySchool = {}
    if damageCSV ~= "" then
        for damageStr in string.gmatch(damageCSV, "([^,]+)") do
            local school, amount = damageStr:match("^([^:]+):(%d+)$")
            if school and amount then
                damageBySchool[school] = tonumber(amount) or 0
            end
        end
    end
    
    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[Handle] ATTACK_SPELL received damageCSV=\'%s\', parsed as: %s'):format(
            damageCSV, 
            table.concat((function() local t = {} for s, a in pairs(damageBySchool) do table.insert(t, s..":"..a) end return t end)(), ",")))
    end

    -- Parse aura effects from JSON (format: auraId|actionKey|argsJSON||auraId|actionKey|argsJSON)
    local auraEffects = {}
    if auraEffectsJSON ~= "" then
        for effectStr in string.gmatch(auraEffectsJSON, "([^|][^|]*||?|[^|][^|]*||?[^|]*||?)") do
            local parts = { strsplit("|", effectStr) }
            if #parts >= 2 then
                table.insert(auraEffects, {
                    auraId = parts[1],
                    actionKey = parts[2],
                    argsJSON = parts[3] or "",
                })
            end
        end
    end

    -- Get active event and find attacker
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then
        RPE.Debug:Warning("[Handle] ATTACK_SPELL but no ActiveEvent")
        return
    end

    local attacker = nil
    for _, u in pairs(ev.units) do
        if tonumber(u.id) == sId then
            attacker = u
            break
        end
    end

    if not attacker then
        RPE.Debug:Warning("[Handle] ATTACK_SPELL attacker not found: " .. tostring(sId))
        return
    end

    -- Check if this is the local player being attacked
    local myId = ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
    if not myId or tonumber(myId) ~= tId then
        -- Not us being attacked, ignore
        return
    end

    -- Get the spell definition for context
    local SpellRegistry = RPE.Core and RPE.Core.SpellRegistry
    local spell = nil
    if SpellRegistry and SpellRegistry.Get then
        spell = SpellRegistry:Get(spellId)
    end

    -- Calculate total damage from all schools
    local totalDamage = 0
    for _, amount in pairs(damageBySchool) do
        totalDamage = totalDamage + (tonumber(amount) or 0)
    end

    if RPE and RPE.Debug and RPE.Debug.Print then
        RPE.Debug:Internal(('[Handle] ATTACK_SPELL: %s (%s) attacks with %s [attackRoll=%d, totalDamage=%d, auraEffects=%d]')
            :format(attacker.name, tostring(sId), spellName, attackRoll, totalDamage, #auraEffects))
    end

    -- Trigger player reaction dialog
    local PlayerReaction = RPE.Core and RPE.Core.PlayerReaction
    if PlayerReaction and PlayerReaction.Start then
        -- Dummy spell/action tables for now (real values would come from NPC data)
        local dummyAction = {
            hitModifier = "$stat.NPC_MELEE_HIT$",
            hitThreshold = thresholdStats,  -- Array of stat IDs
        }
        
        -- Completion callback: will be called when player chooses a defense
        -- For AC mode: lhs is attackRoll, rhs is player's AC
        -- For complex/simple: lhs is player's total, rhs is player's defense modifier
        local function onAttackComplete(hitResult, roll, lhs, rhs)
            local playerDefends
            
            if hitSystem == "ac" then
                -- AC mode: player AC is in rhs, attacker roll is in lhs (from PlayerReactionWidget callback)
                -- Actually, let me check what PlayerReactionWidget passes...
                -- In AC mode, it calls: PlayerReaction:Complete(isHit, reactions.attackRoll, reactions.attackRoll, reactions.ac or 0)
                -- So: roll=attackRoll, lhs=attackRoll, rhs=AC
                -- Attacker hits if: attackRoll >= AC (which is checked as lhs >= rhs)
                playerDefends = (lhs < rhs)  -- Player defends if attackRoll < AC
            else
                -- Complex/Simple mode: lhs is player total, attackRoll is attacker's roll
                -- Player defends if their total >= attacker's roll
                playerDefends = (lhs >= attackRoll)
            end
            
            if RPE and RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal(('[Handle] Attack complete: hitSystem=%s, playerRoll=%d, lhs=%d, rhs=%d, attackerRoll=%d, playerDefends=%s')
                    :format(hitSystem, roll or 0, lhs or 0, rhs or 0, attackRoll, tostring(playerDefends)))
            end
            
            -- Apply damage if attacker hits (player failed to defend)
            if not playerDefends and totalDamage > 0 then
                local target = Common:FindUnitById(tId)
                if target then
                    -- Apply total damage from all schools combined
                    target:ApplyDamage(totalDamage)
                    if RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget then
                        RPE.Core.Windows.PlayerUnitWidget:Refresh()
                    end
                end
            elseif playerDefends then
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal("[Handle] Player successfully defended against attack!")
                end
            end
            
            -- Apply triggered aura effects if attacker hit
            if not playerDefends and #auraEffects > 0 then
                if RPE and RPE.Debug and RPE.Debug.Print then
                    RPE.Debug:Internal(('[Handle] Applying %d aura effects from attack'):format(#auraEffects))
                end
                
                local SpellActions = RPE.Core and RPE.Core.SpellActions
                if SpellActions then
                    for _, effect in ipairs(auraEffects) do
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(('[Handle] Applying aura effect: auraId=%s, action=%s'):format(
                                effect.auraId, effect.actionKey))
                        end
                        
                        -- Parse args from JSON if present
                        local effectArgs = {}
                        if effect.argsJSON and effect.argsJSON ~= "" then
                            -- Simple JSON parsing for args (can be enhanced if needed)
                            -- For now, just try to deserialize basic key=value pairs
                            for key, val in string.gmatch(effect.argsJSON, '([%w_]+)=([^,}]+)') do
                                effectArgs[key] = val
                            end
                        end
                        
                        -- Execute the action on target
                        local ok, err = pcall(function()
                            SpellActions:Run(effect.actionKey, ev or {}, { caster = sId }, { tId }, effectArgs)
                        end)
                        
                        if not ok and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal("|cffff5555[Handle] Aura effect error:|r " .. tostring(err))
                        end
                    end
                end
            end
        end
        
        -- Pass attack details to the reaction dialog for display
        local turnNum = nil
        if ev and ev.turn then
            turnNum = ev.turn
        end
        
        -- Determine primary damage school (pick the one with most damage, or first)
        local primarySchool = "Physical"
        local maxDamage = 0
        for school, amount in pairs(damageBySchool) do
            if tonumber(amount) and tonumber(amount) > maxDamage then
                maxDamage = tonumber(amount)
                primarySchool = school
            end
        end
        
        local attackDetails = {
            attackRoll = attackRoll,
            predictedDamage = totalDamage,
            damageSchool = primarySchool,
            damageBySchool = damageBySchool,  -- Full breakdown by school
            spellName = spellName,
            turn = turnNum,  -- Include turn number if available
            thresholdStats = thresholdStats,  -- Include threshold stats for complex defense
        }
        
        PlayerReaction:Start(hitSystem, spell or { name = spellName, id = spellId }, dummyAction, sId, tId, onAttackComplete, attackDetails)
    else
        RPE.Debug:Warning("[Handle] PlayerReaction module not available")
    end
end)

-- NPC_MESSAGE: unitId ; unitName ; message
-- Receive a message from a controlled NPC unit
Comms:RegisterHandler("NPC_MESSAGE", function(data, sender)
    local args = { strsplit(";", data) }
    local unitId = tonumber(args[1]) or 0
    local unitName = args[2] or "NPC"
    local message = args[3] or ""
    
    if not unitName or unitName == "" or not message or message == "" then
        return
    end
    
    -- Add to chat box if available
    local ChatBoxWidget = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if ChatBoxWidget and ChatBoxWidget.PushNPCMessage then
        ChatBoxWidget:PushNPCMessage(unitName, message)
    end
    
    -- Also add to default Blizzard chat frame
    if DEFAULT_CHAT_FRAME then
        local r, g, b = 1.0, 1.0, 0.624  -- #FFFF9F
        DEFAULT_CHAT_FRAME:AddMessage(unitName .. " says: " .. message, r, g, b)
    end
    
    -- Trigger speech bubble if available
    local ChatBoxWidget = RPE and RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ChatBoxWidget
    if ChatBoxWidget and ChatBoxWidget.speechBubbleWidget then
        -- Look up the NPC unit to get model data
        local npcUnit = nil
        if unitId > 0 then
            local ActiveEvent = RPE and RPE.Core and RPE.Core.ActiveEvent
            if ActiveEvent and ActiveEvent.units then
                for _, unit in pairs(ActiveEvent.units) do
                    if unit.id == unitId and unit.isNPC then
                        npcUnit = unit
                        break
                    end
                end
            end
        end
        ChatBoxWidget.speechBubbleWidget:ShowBubble(nil, unitName, message, npcUnit)
    end
end)


