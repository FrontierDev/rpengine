-- RPE/Core/SpellActions.lua
-- Registry for atomic spell actions (runtime execution).
-- Parsing/rolling of amounts is delegated to RPE.Core.Formula.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Formula  = assert(RPE.Core.Formula, "Formula required")
local Broadcast = RPE.Core.Comms and RPE.Core.Comms.Broadcast
local Actions  = { _acts = {}, _pendingCombatMessages = {}, _pendingDamageByGroup = {} }

Actions.__index = Actions
RPE.Core.SpellActions = Actions

-- Pending combat messages to be sent after all actions are processed
-- Format: { [spellCastKey] = { [targetId] = { casterName, casterUnit, schools={} } } }
local _pendingCombatMessages = {}

-- Pending damage broadcasts per group (deferred until end of group execution)
-- Format: { [groupId] = { casterId, entries=[{target, damageBySchool, crit, threat}] } }
local _pendingDamageByGroup = {}

-- Local helpers
local GetMyUnitId = function()
    local ev = RPE.Core.ActiveEvent
    return ev and ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId() or nil
end

-- Resolve unit id or object from number | table{id} | string (numeric id or key)
local function coerceUnitId(x)
    if type(x) == "number" then return x end
    if type(x) == "table" and tonumber(x.id) then return tonumber(x.id) end
    if type(x) == "string" then
        local n = tonumber(x)
        if n then return n end
        local ev = RPE.Core.ActiveEvent
        if ev and ev.units then
            local u = ev.units[x:lower()]
            if u and tonumber(u.id) then return tonumber(u.id) end
        end
    end
    return 0
end

local function findUnitById(id)
    id = tonumber(id) or 0
    if id <= 0 then return nil end
    local ev = RPE.Core.ActiveEvent
    if not (ev and ev.units) then return nil end
    for _, u in pairs(ev.units) do
        if tonumber(u.id) == id then return u end
    end
    return nil
end

--- Flush pending combat messages for a spell cast (after all actions processed)
function Actions:FlushCombatMessages(castKey)
    if not castKey or not _pendingCombatMessages[castKey] then return end
    
    local targets = _pendingCombatMessages[castKey]
    for targetId, targetData in pairs(targets) do
        if Broadcast and Broadcast.SendCombatMessage then
            local targetUnit = findUnitById(targetId)
            local targetName = (RPE.Common and RPE.Common:FormatUnitName(targetUnit)) or (targetUnit and targetUnit.name) or tostring(targetId)
            local message = nil
            
            -- Check if this is damage (has schools), healing (has healAmount), or shield (has shieldAmount)
            if targetData.schools and #targetData.schools > 0 then
                -- Damage message
                local damageStrings = {}
                for _, schoolInfo in ipairs(targetData.schools) do
                    if schoolInfo.amount > 0 then
                        table.insert(damageStrings, math.floor(schoolInfo.amount) .. " " .. schoolInfo.school)
                    end
                end
                
                if #damageStrings > 0 then
                    local damageText = table.concat(damageStrings, ", ")
                    message = targetData.casterName .. " deals " .. damageText .. " damage to " .. targetName .. "."
                end
            elseif targetData.healAmount and targetData.healAmount > 0 then
                -- Healing message
                message = targetData.casterName .. " heals " .. targetName .. " for " .. math.floor(targetData.healAmount) .. " hitpoints."
            elseif targetData.shieldAmount and targetData.shieldAmount > 0 then
                -- Shield message
                message = targetData.casterName .. " grants " .. targetName .. " a shield absorbing " .. math.floor(targetData.shieldAmount) .. " damage for " .. targetData.shieldDuration .. " turn" .. (targetData.shieldDuration == 1 and "." or "s.")
            end
            
            if message then
                if RPE and RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal(("[SpellActions] Flushed combat message: " .. message))
                end
                
                Broadcast:SendCombatMessage(targetData.casterId, targetData.casterName, message)
            end
        end
    end
    
    _pendingCombatMessages[castKey] = nil
end

--- Flush pending damage for a group (aggregate all schools and broadcast once)
function Actions:FlushDamageForGroup(groupId)
    if not groupId or not _pendingDamageByGroup[groupId] then return end
    
    local groupData = _pendingDamageByGroup[groupId]
    local aggregatedByTarget = {}  -- { [targetId] = { target, damageBySchool, crit, threat } }
    
    -- Aggregate all damage entries from this group
    for _, entry in ipairs(groupData.entries or {}) do
        local tgtId = tostring(entry.target)
        if not aggregatedByTarget[tgtId] then
            aggregatedByTarget[tgtId] = {
                target = entry.target,
                damageBySchool = {},
                crit = entry.crit,
                threat = entry.threat,
            }
        end
        
        -- Merge damage schools
        for school, amt in pairs(entry.damageBySchool or {}) do
            aggregatedByTarget[tgtId].damageBySchool[school] = 
                (aggregatedByTarget[tgtId].damageBySchool[school] or 0) + amt
        end
        
        -- Mark as crit if any was crit
        if entry.crit then aggregatedByTarget[tgtId].crit = true end
    end
    
    -- Convert to list and broadcast
    local aggregatedList = {}
    for _, agg in pairs(aggregatedByTarget) do
        table.insert(aggregatedList, agg)
    end
    
    if #aggregatedList > 0 and Broadcast and Broadcast.Damage then
        if RPE and RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("DAMAGE GROUP aggregated: %d entries -> %d targets"):format(
                #(groupData.entries or {}), #aggregatedList))
            for i, e in ipairs(aggregatedList) do
                local schoolStr = ""
                for school, amt in pairs(e.damageBySchool) do
                    if schoolStr ~= "" then schoolStr = schoolStr .. ", " end
                    schoolStr = schoolStr .. school .. ":" .. math.floor(amt)
                end
                RPE.Debug:Internal(("  [%d] target=%s schools=[%s] crit=%s"):
                    format(i, tostring(e.target), schoolStr, tostring(e.crit)))
            end
        end
        
        Broadcast:Damage(groupData.casterId, aggregatedList)
    end
    
    _pendingDamageByGroup[groupId] = nil
end

-- ===== Registry ==============================================================

--- Register an action handler.
---@param key string
---@param fn fun(ctx:table, cast:table, targets:table, args:table)
function Actions:Register(key, fn)
    assert(type(key) == "string" and key ~= "", "SpellActions:Register: key must be string")
    assert(type(fn)  == "function", "SpellActions:Register: fn must be function")
    self._acts[key] = fn
end

--- Run an action handler.
---@param key string
---@param ctx table|nil
---@param cast table|nil
---@param targets table|nil
---@param args table|nil
function Actions:Run(key, ctx, cast, targets, args)
    local fn = self._acts[key]

    if not fn then
        if RPE.Debug and RPE.Debug.Warn then
            RPE.Debug:Warn("Unknown action: " .. tostring(key))
        end
        return
    end
    return fn(ctx or {}, cast or {}, targets or {}, args or {})
end

-- ===== Default Actions =======================================================

-- DAMAGE: roll amount and apply to all targets.
Actions:Register("DAMAGE", function(ctx, cast, targets, args)
    local ev = ctx and ctx.event
    if not (ev and targets and #targets > 0) then return end

    -- Reset the caster's combat counter immediately (they are attempting an attack)
    local casterUnit = findUnitById(cast and cast.caster)
    if RPE.Debug then RPE.Debug:Print(string.format("[SpellActions:DAMAGE] Caster unit %d: %s", cast and cast.caster or 0, casterUnit and casterUnit.name or "NOT FOUND")) end
    if casterUnit then
        -- Reset counter to 0 so unit stays engaged
        if RPE.Debug then RPE.Debug:Print(string.format("[SpellActions:DAMAGE] Resetting combat for caster %s", casterUnit.name)) end
        if type(casterUnit.ResetCombat) == "function" then
            casterUnit:ResetCombat()
        end
        -- Update engagement state
        if type(casterUnit.SetEngaged) == "function" then
            casterUnit:SetEngaged(true)
        end
    end

    -- Get caster's stats: use NPC's stats if caster is an NPC, otherwise use player profile
    local profile = cast and cast.profile
    casterUnit = nil
    if not profile and cast and cast.caster then
        -- Find the caster unit to check if it's an NPC
        casterUnit = findUnitById(cast.caster)
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            -- For NPCs, create a wrapper that acts like a profile with their stats
            profile = {
                GetStatValue = function(self, statId)
                    return tonumber(casterUnit.stats[statId] or 1) or 1
                end
            }
        end
    end
    
    local school  = tostring(args.school or "Physical")

    if not cast or not cast.def then
        RPE.Debug:Internal("[SpellActions:DAMAGE] Running without a spell definition (likely aura tick).")
    end

    local function rollAmount()
        local base = 0
        if type(args.amount) == "string" then
            base = tonumber(Formula:Roll(args.amount, profile)) or 0
        else
            base = tonumber(args.amount) or 0
        end

        local rank = 1
        if cast and cast.def and cast.def.rank then
            rank = tonumber(cast.def.rank) or 1
        elseif args and args.rank then
            rank = tonumber(args.rank) or 1
        end

        local perExpr = args.perRank
        if rank > 1 and perExpr and perExpr ~= "" then
            local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0
            base = base + (perAmount * (rank - 1))
        end

        -- Apply fudge factor from ruleset (default: 0)
        local fudge = 0
        if RPE.ActiveRules then
            local fudgeVal = RPE.ActiveRules:Get("fudge", 0)
            if type(fudgeVal) == "string" then
                fudge = tonumber(Formula:Roll(fudgeVal, profile)) or 0
            else
                fudge = tonumber(fudgeVal) or 0
            end
        end
        base = base + fudge

        return math.max(0, math.floor(base))
    end

    -- Per-target build (no local apply)
    local entries = {}
    for _, tgt in ipairs(targets) do
        -- Permission check: non-leader players can only damage enemies
        -- Allow damage if:
        -- 1. Caster is an NPC (NPCs can always damage)
        -- 2. Caster is the group leader
        -- 3. Target is an enemy NPC on a different team
        -- Skip damage if non-leader player tries to damage ally or another player
        local canDamage = true
        if not casterUnit or not casterUnit.isNPC then
            -- Caster is a player (not NPC)
            local isLeader = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()
            if not isLeader then
                -- Non-leader player: check if target is friendly
                local targetUnit = findUnitById(tonumber(tgt) or 0)
                if targetUnit and not targetUnit.isNPC then
                    -- Target is a player - non-leaders cannot damage other players
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Internal(("[SpellActions:DAMAGE] Non-leader player cannot damage other players"))
                    end
                    canDamage = false
                elseif targetUnit and targetUnit.isNPC then
                    -- Check if NPC is friendly (same team)
                    if casterUnit and targetUnit.team and casterUnit.team and casterUnit.team == targetUnit.team then
                        -- Target is a friendly NPC - non-leaders cannot damage allies
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(("[SpellActions:DAMAGE] Non-leader player cannot damage friendly NPCs"))
                        end
                        canDamage = false
                    end
                end
            end
        end

        if canDamage then
            local amt = rollAmount()
            if amt > 0 then
                local isCrit = false
                
                -- Determine if crits are allowed:
                -- - Direct spell damage: check cast.def.canCrit flag (defaults to true)
                -- - Aura tick damage: check dot_crits ruleset (defaults to false)
                local allowCrit = false
                if cast.def then
                    -- Direct spell damage: canCrit defaults to true
                    allowCrit = (cast.def.canCrit ~= false)
                else
                    -- Aura tick damage: check dot_crits ruleset
                    allowCrit = (RPE.ActiveRules and RPE.ActiveRules:Get("dot_crits") == 1) or false
                end
                
                if allowCrit and args._critThreshold then
                    -- Use the roll stored by CheckHit to determine crit
                    local roll = args._rolls and args._rolls[tgt]
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Internal(("  Crit lookup: tgt=%s, roll=%s, threshold=%.1f → %s"):format(
                            tostring(tgt), tostring(roll), args._critThreshold,
                            (roll and roll >= args._critThreshold) and "CRIT" or "normal"
                        ))
                    end
                    if roll and roll >= args._critThreshold then
                        isCrit = true
                        local mult = math.max(1, args._critMult or 2)
                        local origAmt = amt
                        amt = math.floor(amt * mult)
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(("  Crit multiplier applied: %d × %.1f = %d"):format(origAmt, mult, amt))
                        end
                    end
                end

                -- Parse threat value (supports formulas and stat references)
                local threatVal = args.threat
                if type(threatVal) == "string" then
                    threatVal = tonumber(Formula:Roll(threatVal, profile)) or 0
                else
                    threatVal = tonumber(threatVal) or 0
                end

                -- Resolve weapon school tokens (e.g., "$wep.mainhand$") to actual damage schools
                local resolvedSchool = school
                if type(resolvedSchool) == "string" then
                    local slot = resolvedSchool:match("^%$wep%.([%w_]+)%$")
                    if slot then
                        local norm = string.lower(slot)
                        if norm == "mh" then norm = "mainhand"
                        elseif norm == "oh" then norm = "offhand"
                        elseif norm == "rng" or norm == "wand" then norm = "ranged" end

                        -- Try to resolve equipped item from profile (GetEquipped API) or equipment table
                        local item = nil
                        if profile and type(profile.GetEquipped) == "function" then
                            local ok, id = pcall(profile.GetEquipped, profile, norm)
                            if ok and id then
                                if type(id) == "table" then item = id end
                                if type(id) == "string" then
                                    local reg = RPE.Core and RPE.Core.ItemRegistry
                                    if reg and type(reg.Get) == "function" then
                                        local ok2, def = pcall(reg.Get, reg, id)
                                        if ok2 and def then item = def end
                                    end
                                end
                            end
                        end
                        if not item and profile and type(profile.equipment) == "table" then
                            local ent = profile.equipment[norm]
                            if ent then
                                if type(ent) == "table" then item = ent end
                                if type(ent) == "string" then
                                    local reg = RPE.Core and RPE.Core.ItemRegistry
                                    if reg and type(reg.Get) == "function" then
                                        local ok2, def = pcall(reg.Get, reg, ent)
                                        if ok2 and def then item = def end
                                    end
                                end
                            end
                        end

                        if item then
                            local d = (type(item) == "table") and (item.data or item) or {}
                            local ds = d.damageSchool or d.school or d.damage_school
                            if ds and type(ds) == "string" and ds ~= "" then
                                resolvedSchool = ds
                            else
                                resolvedSchool = "Physical"  -- default if item has no damage school
                            end
                        else
                            resolvedSchool = "Physical"  -- default if weapon not found
                        end
                    end
                end

                entries[#entries+1] = {
                    target = coerceUnitId(tgt),
                    amount = amt,
                    school = resolvedSchool,
                    crit   = isCrit,
                    threat = threatVal,
                }
            end
        end
    end

    if Broadcast and Broadcast.Damage and #entries > 0 then
        -- Aggregate entries by target to combine multiple schools into one entry per target
        -- Store for deferred broadcasting at end of group
        local aggregatedByTarget = {}  -- { [targetId] = { target=tId, damageBySchool={school=amt, ...}, crit=bool, threat=amt } }
        for _, e in ipairs(entries) do
            local tgtId = tostring(e.target)
            if not aggregatedByTarget[tgtId] then
                aggregatedByTarget[tgtId] = {
                    target = e.target,
                    damageBySchool = {},
                    crit = e.crit,
                    threat = e.threat,
                }
            end
            -- Add this school's damage to the aggregated entry
            -- If multiple schools have same name, they add together
            aggregatedByTarget[tgtId].damageBySchool[e.school] = 
                (aggregatedByTarget[tgtId].damageBySchool[e.school] or 0) + e.amount
            -- If any instance is a crit, mark the aggregated entry as crit (for display)
            if e.crit then aggregatedByTarget[tgtId].crit = true end
        end
        
        -- Convert aggregated entries to list
        local aggregatedList = {}
        for _, agg in pairs(aggregatedByTarget) do
            table.insert(aggregatedList, agg)
        end
        
        -- For aura tick damage (cast.def == nil), apply damage locally to the target unit immediately
        -- This is needed because aura ticks don't go through the normal broadcast/Handle system
        if not cast.def then
            for _, agg in ipairs(aggregatedList) do
                local targetUnit = findUnitById(agg.target)
                if targetUnit and type(targetUnit.ApplyDamage) == "function" then
                    local totalDamage = 0
                    for _, amt in pairs(agg.damageBySchool) do
                        totalDamage = totalDamage + amt
                    end
                    targetUnit:ApplyDamage(totalDamage, agg.crit, 0)
                end
            end
        end
        
        -- Use the groupId passed from runActions (via cast._groupId)
        local groupId = cast and cast._groupId
        if not groupId then
            -- Fallback if no groupId was provided (shouldn't happen)
            groupId = tostring(cast and cast.def and cast.def.id or "unknown") .. "|" .. tostring(cast and cast._currentGroupPhase or "unknown")
        end
        
        -- Add to pending damage for this group (will be broadcasted when group finishes)
        if not _pendingDamageByGroup[groupId] then
            _pendingDamageByGroup[groupId] = {
                casterId = cast and cast.caster,
                entries = {},
            }
        end
        
        -- Add all aggregated entries to the group's pending damage
        for _, agg in ipairs(aggregatedList) do
            table.insert(_pendingDamageByGroup[groupId].entries, agg)
        end
        
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("DAMAGE entries queued for group broadcast: %d original -> %d targets"):format(#entries, #aggregatedList))
            for i, e in ipairs(aggregatedList) do
                local schoolStr = ""
                for school, amt in pairs(e.damageBySchool) do
                    if schoolStr ~= "" then schoolStr = schoolStr .. ", " end
                    schoolStr = schoolStr .. school .. ":" .. math.floor(amt)
                end
                RPE.Debug:Internal(("  [%d] target=%s schools=[%s] crit=%s threat=%s"):
                    format(i, tostring(e.target), schoolStr, tostring(e.crit), tostring(e.threat)))

                -- Show floating combat text for damage *dealt* by the controlled player (upwards).
                -- This is distinct from damage *received* (Unit will display that on the target when it's the local player).
                local controlledUnitId = GetMyUnitId and GetMyUnitId() or nil
                if controlledUnitId and tonumber(cast and cast.caster) == tonumber(controlledUnitId) and tonumber(e.target) ~= tonumber(controlledUnitId) then
                    if RPE.Core.CombatText and RPE.Core.CombatText.Screen and RPE.Core.CombatText.Screen.AddNumber then
                        -- Calculate total damage for float text
                        local totalDmg = 0
                        for _, amt in pairs(e.damageBySchool) do
                            totalDmg = totalDmg + amt
                        end
                        pcall(function()
                            RPE.Core.CombatText.Screen:AddNumber(totalDmg, "damageDealt", { isCrit = e.crit, direction = "UP" })
                        end)
                    end
                end
            end
        end
        
        -- Emit ON_HIT triggers for each school separately (for aura interactions)
        for _, e in ipairs(entries) do
            RPE.Core.AuraTriggers:Emit("ON_HIT", {}, cast.caster, e.target, {
                spell  = cast.def,
                amount = e.amount,
                isCrit = e.crit,
                school = e.school,
            })
        end
        
        -- Accumulate damage into pending combat messages (will be flushed after all actions)
        if #entries > 0 then
            local casterUnit = findUnitById(cast and cast.caster)
            local casterName = (RPE.Common and RPE.Common:FormatUnitName(casterUnit)) or (casterUnit and casterUnit.name) or tostring(cast and cast.caster or "")
            local castKey = tostring(cast and cast.def and cast.def.id or cast and cast.caster or "unknown")
            
            if not _pendingCombatMessages[castKey] then
                _pendingCombatMessages[castKey] = {}
            end
            
            -- Accumulate damage for each target
            for _, e in ipairs(entries) do
                if not _pendingCombatMessages[castKey][e.target] then
                    _pendingCombatMessages[castKey][e.target] = {
                        casterId = cast and cast.caster,
                        casterName = casterName,
                        schools = {},
                    }
                end
                
                table.insert(_pendingCombatMessages[castKey][e.target].schools, {
                    school = e.school,
                    amount = e.amount,
                })
            end
        end
    end
end)



-- HEAL: roll amount and heal all targets.
Actions:Register("HEAL", function(ctx, cast, targets, args)
    local ev      = ctx and ctx.event
    if not (ev and targets and #targets > 0) then return end

    -- Get caster's stats: use NPC's stats if caster is an NPC, otherwise use player profile
    local profile = cast and cast.profile
    if not profile and cast and cast.caster then
        -- Find the caster unit to check if it's an NPC
        local casterUnit = findUnitById(cast.caster)
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            -- For NPCs, create a wrapper that acts like a profile with their stats
            profile = {
                GetStatValue = function(self, statId)
                    return tonumber(casterUnit.stats[statId] or 1) or 1
                end
            }
        end
    end

    local function rollAmount()
        local base = 0
        if type(args.amount) == "string" then
            base = tonumber(Formula:Roll(args.amount, profile)) or 0
        else
            base = tonumber(args.amount) or 0
        end

        local rank = tonumber(cast and cast.rank) or 1
        local perExpr = args.perRank
        if rank > 1 and perExpr and perExpr ~= "" then
            local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0
            base = base + (perAmount * (rank - 1))
        end

        -- Apply fudge factor from ruleset (default: 0)
        local fudge = 0
        if RPE.ActiveRules then
            local fudgeVal = RPE.ActiveRules:Get("fudge", 0)
            if type(fudgeVal) == "string" then
                fudge = tonumber(Formula:Roll(fudgeVal, profile)) or 0
            else
                fudge = tonumber(fudgeVal) or 0
            end
        end
        base = base + fudge

        return math.max(0, math.floor(base))
    end

    -- Per-target build
    local entries = {}
    for _, tgt in ipairs(targets) do
        local amt = rollAmount()
        if amt > 0 then
            local isCrit = false
            
            -- Determine if crits are allowed:
            -- - Direct spell healing: check cast.def.canCrit flag (defaults to true)
            -- - Aura tick healing: check dot_crits ruleset (defaults to false)
            local allowCrit = false
            if cast.def then
                -- Direct spell healing: canCrit defaults to true
                allowCrit = (cast.def.canCrit ~= false)
            else
                -- Aura tick healing: check dot_crits ruleset
                allowCrit = (RPE.ActiveRules and RPE.ActiveRules:Get("dot_crits") == 1) or false
            end
            
            if allowCrit then
                local critMult = 2
                if args and args.critMult then
                    critMult = math.max(1, tonumber(args.critMult) or 2)
                elseif args and args._critMult then
                    critMult = args._critMult
                end
                
                if args._critThreshold then
                    -- Use the roll stored by CheckHit to determine crit
                    local roll = args._rolls and args._rolls[tgt]
                    if RPE and RPE.Debug and RPE.Debug.Print then
                        RPE.Debug:Internal(("  Crit lookup: tgt=%s, roll=%s, threshold=%.1f → %s"):format(
                            tostring(tgt), tostring(roll), args._critThreshold,
                            (roll and roll >= args._critThreshold) and "CRIT" or "normal"
                        ))
                    end
                    if roll and roll >= args._critThreshold then
                        isCrit = true
                        local origAmt = amt
                        amt = math.floor(amt * critMult)
                        if RPE and RPE.Debug and RPE.Debug.Print then
                            RPE.Debug:Internal(("  Crit multiplier applied: %d × %.1f = %d"):format(origAmt, critMult, amt))
                        end
                    end
                end
            end

            entries[#entries+1] = {
                target = coerceUnitId(tgt),   -- coerced by Broadcast:Heal
                amount = amt,
                crit   = isCrit,
            }
        end
    end

    if Broadcast and Broadcast.Heal and #entries > 0 then
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("HEAL entries to send: %d"):format(#entries))
            for i,e in ipairs(entries) do
                RPE.Debug:Internal(("  [%d] target=%s amount=%d crit=%s"):format(i, tostring(e.target), e.amount, tostring(e.crit)))
                -- Show floating combat text for healing *dealt* by the controlled player (upwards).
                local controlledUnitId = GetMyUnitId and GetMyUnitId() or nil
                if controlledUnitId and tonumber(cast and cast.caster) == tonumber(controlledUnitId) and tonumber(e.target) ~= tonumber(controlledUnitId) then
                    if RPE.Core.CombatText and RPE.Core.CombatText.Screen and RPE.Core.CombatText.Screen.AddNumber then
                        pcall(function()
                            RPE.Core.CombatText.Screen:AddNumber(e.amount, "heal", { isCrit = e.crit, direction = "UP" })
                        end)
                    end
                end
            end
        end

        Broadcast:Heal(cast and cast.caster, entries)
        
        -- Accumulate healing into pending combat messages (will be flushed after all actions)
        if #entries > 0 then
            local casterUnit = findUnitById(cast and cast.caster)
            local casterName = (RPE.Common and RPE.Common:FormatUnitName(casterUnit)) or (casterUnit and casterUnit.name) or tostring(cast and cast.caster or "")
            local castKey = tostring(cast and cast.def and cast.def.id or cast and cast.caster or "unknown")
            
            if not _pendingCombatMessages[castKey] then
                _pendingCombatMessages[castKey] = {}
            end
            
            -- Accumulate healing for each target
            for _, e in ipairs(entries) do
                if not _pendingCombatMessages[castKey][e.target] then
                    _pendingCombatMessages[castKey][e.target] = {
                        casterId = cast and cast.caster,
                        casterName = casterName,
                        healAmount = 0,
                    }
                end
                
                _pendingCombatMessages[castKey][e.target].healAmount = 
                    _pendingCombatMessages[castKey][e.target].healAmount + e.amount
            end
        end
    end
end)


-- SHIELD: apply absorption that reduces damage taken for a duration.
-- args:
--   amount: amount of absorption to grant
--   duration: number of turns the shield lasts (default 1)
Actions:Register("SHIELD", function(ctx, cast, targets, args)
    local ev = ctx and ctx.event
    if not (ev and targets and #targets > 0) then return end

    -- Get caster's stats: use NPC's stats if caster is an NPC, otherwise use player profile
    local profile = cast and cast.profile
    if not profile and cast and cast.caster then
        local casterUnit = findUnitById(cast.caster)
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            profile = {
                GetStatValue = function(self, statId)
                    return tonumber(casterUnit.stats[statId] or 1) or 1
                end
            }
        end
    end

    local function rollAmount()
        local base = 0
        if type(args.amount) == "string" then
            base = tonumber(Formula:Roll(args.amount, profile)) or 0
        else
            base = tonumber(args.amount) or 0
        end

        local rank = tonumber(cast and cast.rank) or 1
        local perExpr = args.perRank
        if rank > 1 and perExpr and perExpr ~= "" then
            local perAmount = tonumber(Formula:Roll(perExpr, profile)) or 0
            base = base + (perAmount * (rank - 1))
        end

        return math.max(0, math.floor(base))
    end

    local duration = tonumber(args.duration) or 1
    
    -- Per-target build
    local entries = {}
    for _, tgt in ipairs(targets) do
        local amt = rollAmount()
        if amt > 0 then
            entries[#entries+1] = {
                target = coerceUnitId(tgt),
                amount = amt,
                duration = duration,
            }
        end
    end

    if Broadcast and Broadcast.ApplyShield and #entries > 0 then
        if RPE.Debug and RPE.Debug.Print then
            RPE.Debug:Internal(("SHIELD entries to send: %d"):format(#entries))
            for i, e in ipairs(entries) do
                RPE.Debug:Internal(("  [%d] target=%s amount=%d duration=%d turns"):
                    format(i, tostring(e.target), e.amount, e.duration))
            end
        end

        Broadcast:ApplyShield(cast and cast.caster, entries)
        
        -- Accumulate shield into pending combat messages (will be flushed after all actions)
        if #entries > 0 then
            local casterUnit = findUnitById(cast and cast.caster)
            local casterName = (RPE.Common and RPE.Common:FormatUnitName(casterUnit)) or (casterUnit and casterUnit.name) or tostring(cast and cast.caster or "")
            local castKey = tostring(cast and cast.def and cast.def.id or cast and cast.caster or "unknown")
            
            if not _pendingCombatMessages[castKey] then
                _pendingCombatMessages[castKey] = {}
            end
            
            -- Accumulate shield for each target
            for _, e in ipairs(entries) do
                if not _pendingCombatMessages[castKey][e.target] then
                    _pendingCombatMessages[castKey][e.target] = {
                        casterId = cast and cast.caster,
                        casterName = casterName,
                        shieldAmount = 0,
                        shieldDuration = duration,
                    }
                end
                
                _pendingCombatMessages[castKey][e.target].shieldAmount = 
                    _pendingCombatMessages[castKey][e.target].shieldAmount + e.amount
            end
        end
    end
end)


-- Add near APPLY_AURA:
local function _hasRandom(expr)
    return type(expr) == "string"
        and (expr:find("%d+%s*[dD]%s*%d+") or expr:find("rand%(") or expr:find("%$rand"))
end

-- Replace APPLY_AURA with:
Actions:Register("APPLY_AURA", function(ctx, cast, targets, args)
    local auraId = args.auraId or args.id
    if not auraId then
        RPE.Debug:Error("APPLY_AURA: missing auraId")
        return
    end

    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then
        RPE.Debug:Error("APPLY_AURA: no AuraManager attached to event")
        return
    end

    -- Get caster's stats: use NPC's stats if caster is an NPC, otherwise use player profile
    local profile = cast and cast.profile
    if not profile and cast and cast.caster then
        local ev = ctx and ctx.event
        -- Find the caster unit to check if it's an NPC
        local casterUnit = findUnitById(cast.caster)
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            -- For NPCs, create a wrapper that acts like a profile with their stats
            profile = {
                GetStatValue = function(self, statId)
                    return tonumber(casterUnit.stats[statId] or 1) or 1
                end
            }
        end
    end

    for _, tgt in ipairs(targets or {}) do
        -- Build per-instance snapshot
        local snap = {}
        if type(args.snapshot) == "table" then
            for k, v in pairs(args.snapshot) do snap[k] = v end
        end
        if args.amount ~= nil then
            if _hasRandom(args.amount) then
                -- keep string so it re-rolls each tick
                snap.amount = args.amount
            else
                -- snapshot flat/stat-only formulas once
                snap.amount = Formula:Roll(args.amount, profile)
            end
        end
        if args.school ~= nil then snap.school = args.school end
        -- keep caster profile for $stat.*$ resolution on ticks
        if profile ~= nil then snap.profile = profile end

        local ok, res = mgr:Apply(
            cast and cast.caster or ctx.caster,
            tgt,
            auraId,
            {
                stacks          = tonumber(args.stacks) or 1,
                charges         = args.charges,
                rngSeed         = args.rngSeed,
                snapshot        = snap,               -- 👈 includes amount (string or number)
                stackingPolicy  = args.stackingPolicy,
                uniqueByCaster  = args.uniqueByCaster,
            }
        )

        if not ok then
            RPE.Debug:Error(("APPLY_AURA failed: aura=%s tgt=%s reason=%s"):
                format(auraId, tostring(tgt), tostring(res)))
        end
    end
end)



-- REMOVE_AURA: remove a specific aura.
Actions:Register("REMOVE_AURA", function(ctx, cast, targets, args)
    local auraId = args.auraId or args.id
    if not auraId then return end

    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then return end

    for _, tgt in ipairs(targets or {}) do
        mgr:Remove(tgt, auraId, cast and cast.caster)
    end
end)

-- EXTEND_AURA: extend duration by N turns.
Actions:Register("EXTEND_AURA", function(ctx, cast, targets, args)
    local auraId = args.auraId or args.id
    if not auraId then return end

    local turns = tonumber(args.turns or args.amount) or 1
    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then return end

    for _, tgt in ipairs(targets or {}) do
        local _, inst = mgr:Has(tgt, auraId, cast and cast.caster)
        if inst then
            inst:ExtendDuration(turns)
            mgr:_onRefreshed(inst, true)
        end
    end
end)

-- DISPEL: remove N harmful/helpful auras of certain types.
Actions:Register("DISPEL", function(ctx, cast, targets, args)
    local mgr = ctx.event and ctx.event._auraManager
    if not mgr then return end

    for _, tgt in ipairs(targets or {}) do
        mgr:Dispel(tgt, {
            types   = args.types,
            max     = args.max or 1,
            helpful = args.helpful or false,
        })
    end
end)


-- REDUCE_COOLDOWN: reduce remaining cooldown on a specific spell or shared group.
-- args:
--   spellId      = "HEALING_WORD"   -- target spell id   (preferred)
--   sharedGroup  = "POTION"         -- or a cooldown group key
--   amount       = 1                -- turns to reduce (default 1)
Actions:Register("REDUCE_COOLDOWN", function(ctx, cast, targets, args)
    local CD  = RPE.Core.Cooldowns
    if not (CD and cast and cast.caster) then return end

    local turn   = (ctx.event and ctx.event.turn) or 0
    local amount = tonumber(args.amount or args.turns) or 1

    if args.sharedGroup == "ALL" then
        -- Reduce cooldown for all spells for this caster
        local reg = RPE.Core.SpellRegistry
        if reg and reg.All then
            for id, def in pairs(reg:All()) do
                CD:Reduce(cast.caster, def, amount, turn)
            end
        end
        return
    end

    local def
    if args.sharedGroup then
        -- build a minimal def keyed to the shared group
        def = { id = "SG:" .. tostring(args.sharedGroup), cooldown = { sharedGroup = tostring(args.sharedGroup) } }
    elseif args.spellId then
        local reg = RPE.Core.SpellRegistry
        def = reg and reg:Get(args.spellId)
    end
    if not def then return end

    CD:Reduce(cast.caster, def, amount, turn)
end)


-- ADVANTAGE_LEVEL: grant advantage/disadvantage levels to a stat roll
-- SUMMON: summon an NPC to the caster's team
-- args:
--   npcId = "npc-12345" -- NPC registry ID to summon
Actions:Register("SUMMON", function(ctx, cast, targets, args)
    local ev = ctx and ctx.event
    if not (ev and ev.units) then return end
    
    local npcId = args.npcId
    if not npcId or npcId == "" then
        RPE.Debug:Error("[SpellActions:SUMMON] Missing npcId")
        return
    end
    
    local casterUnitId = tonumber(cast and cast.caster)
    if not casterUnitId or casterUnitId <= 0 then return end
    
    -- Get the caster's unit to retrieve their team
    local casterUnit = RPE.Common:FindUnitById(casterUnitId)
    local casterTeam = (casterUnit and tonumber(casterUnit.team)) or 1
    
    -- Get the NPC registry to find the NPC definition
    local NPCRegistry = RPE.Core and RPE.Core.NPCRegistry
    if not (NPCRegistry and NPCRegistry.Get) then
        RPE.Debug:Error("[SpellActions:SUMMON] NPCRegistry not available")
        return
    end
    
    local npcDef = NPCRegistry:Get(npcId)
    if not npcDef then
        -- Log available NPCs for debugging
        if RPE.Debug and RPE.Debug.Internal then
            local availableNPCs = {}
            for id, def in NPCRegistry:Pairs() do
                table.insert(availableNPCs, id)
            end
            RPE.Debug:Internal(("[SpellActions:SUMMON] Available NPCs: %s"):format(table.concat(availableNPCs, ", ")))
        end
        RPE.Debug:Error(("[SpellActions:SUMMON] NPC not found: %s"):format(npcId))
        return
    end
    
    -- Build unit seed from the registry prototype
    local seed = NPCRegistry:BuildUnitSeed(npcId, {
        team = casterTeam,
        active = true,
        hidden = false,
        flying = false,
    })
    seed.summonedBy = casterUnitId
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[SpellActions:SUMMON] Broadcasting summon for %s by unit %d on team %d"):format(
            npcId, casterUnitId, casterTeam))
    end
    
    -- Broadcast to supergroup leader so they can add it and include in next ADVANCE
    -- Don't add it locally - only the leader should add it
    if Broadcast and Broadcast.Summon then
        Broadcast:Summon(npcId, casterUnitId, casterTeam)
    else
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal("[SpellActions:SUMMON] ERROR: Broadcast or Broadcast.Summon not available")
        end
    end
end)

-- HIDE: hide the caster unit (sender hides self)
Actions:Register("HIDE", function(ctx, cast, targets, args)
    if not cast or not cast.caster then return end
    
    if RPE.Debug and RPE.Debug.Internal then
        RPE.Debug:Internal(("[SpellActions:HIDE] Caster %d hiding"):format(cast.caster))
    end
    
    -- Broadcast hide for the caster
    if Broadcast and Broadcast.Hide then
        Broadcast:Hide(cast.caster)
    end
end)

Actions:Register("GAIN_RESOURCE", function(ctx, cast, targets, args)
    local Resources = RPE.Core and RPE.Core.Resources
    if not Resources or not targets or #targets == 0 then return end

    -- Accept both "auraId" and "resourceId" for compatibility
    local resourceId = args.resourceId or args.auraId
    if not resourceId then return end

    -- Get caster's stats: use NPC's stats if caster is an NPC, otherwise use player profile
    local profile = cast and cast.profile
    if not profile and cast and cast.caster then
        local casterUnit = findUnitById(cast.caster)
        if casterUnit and casterUnit.isNPC and casterUnit.stats then
            profile = {
                GetStatValue = function(self, statId)
                    return tonumber(casterUnit.stats[statId] or 1) or 1
                end
            }
        end
    end

    -- Calculate amount (supports formulas)
    local amount = 0
    if type(args.amount) == "string" and Formula then
        amount = tonumber(Formula:Roll(args.amount, profile)) or 0
    else
        amount = tonumber(args.amount or 0)
    end
    if amount == 0 then return end

    local myUnitId = nil
    if RPE.Core and RPE.Core.ActiveEvent and RPE.Core.ActiveEvent.GetLocalPlayerUnitId then
        myUnitId = RPE.Core.ActiveEvent:GetLocalPlayerUnitId()
    end
    
    for _, tgt in ipairs(targets) do
        -- Only tick resources for the local player unit
        if tonumber(tgt) == tonumber(myUnitId) then
            Resources:Add(resourceId, amount)
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(('[SpellActions:GAIN_RESOURCE] Added %d %s to unit %s'):format(amount, resourceId, tostring(tgt)))
            end
        end
    end
end)

-- INTERRUPT: stop a target unit's spell casting
Actions:Register("INTERRUPT", function(ctx, cast, targets, args)
    if not (targets and #targets > 0) then return end

    for _, tgt in ipairs(targets) do
        local targetId = coerceUnitId(tgt)
        if targetId > 0 then
            local targetUnit = findUnitById(targetId)
            if targetUnit then
                if RPE.Debug and RPE.Debug.Internal then
                    RPE.Debug:Internal(('[SpellActions:INTERRUPT] Interrupting unit %d'):format(targetId))
                end
                
                -- Mark the unit as interrupted to prevent spell execution
                targetUnit._wasInterrupted = true
                
                -- Broadcast CLEAR_CASTING to stop the cast on all clients
                if Broadcast and Broadcast.SendClearCasting then
                    Broadcast:SendClearCasting(targetId)
                end
            end
        end
    end
end)

return Actions
