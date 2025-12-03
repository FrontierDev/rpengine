-- Common:lua
-- Basically helpers.
Common = {}
RPE = RPE or {}
RPE.Common = Common

Common.SocketTextures = {
    Red = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Red",
    Yellow = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Yellow",
    Blue = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Blue",
    Meta = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta",
    Cog = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Cogwheel"
}

-- Common icons
Common.InlineIcons = {
    Info = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\info.png:12:12|t",
    Warning = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\warning.png:12:12|t",
    Error = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\error.png:12:12|t",
    Health = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\health.png:12:12|t",
    Mana = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\mana.png:12:12|t",
    Check = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\check.png:12:12|t",
    Hidden = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\hidden.png:12:12|t",
    Flying = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\flying.png:12:12|t",
    Reaction = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\reaction.png:12:12|t",
    Cancel = "|TInterface\\Buttons\\UI-GroupLoot-Pass-Up:12:12|t",
    Dice = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\dice.png:12:12|t",
    Combat = "|TInterface\\AddOns\\RPEngine\\UI\\Textures\\parry.png:12:12|t",
    Socket_Red = ("|T%s:12:12|t"):format(Common.SocketTextures.Red),
    Socket_Blue = ("|T%s:12:12|t"):format(Common.SocketTextures.Blue),
    Socket_Yellow = ("|T%s:12:12|t"):format(Common.SocketTextures.Yellow),
    Socket_Meta = ("|T%s:12:12|t"):format(Common.SocketTextures.Meta),
    Socket_Cog = ("|T%s:12:12|t"):format(Common.SocketTextures.Cog),
}

Common.QualityColors = {
    common    = { r = 1.00, g = 1.00, b = 1.00 }, -- white
    uncommon  = { r = 0.12, g = 1.00, b = 0.00 }, -- green
    rare      = { r = 0.00, g = 0.44, b = 0.87 }, -- blue
    epic      = { r = 0.64, g = 0.21, b = 0.93 }, -- purple
    legendary = { r = 1.00, g = 0.50, b = 0.00 }, -- orange
}

Common.DamageSchools = { "Physical", "Force", "Fire", "Frost", "Cold", "Nature", "Acid", "Lightning", "Poison", "Shadow", "Necrotic", "Holy", "Radiant", "Arcane", "Psychic", "Fel" }

-- Shared colors for grouped damage schools
local damageSchoolColors = {
    physical   = { r = 0.8, g = 0.8, b = 0.8 },      -- light gray (Physical, Force)
    fire       = { r = 1.0, g = 0.5, b = 0.0 },      -- orange (Fire)
    frost      = { r = 0.5, g = 0.8, b = 1.0 },      -- light blue (Frost, Cold)
    nature     = { r = 0.4, g = 1.0, b = 0.4 },      -- light green (Nature, Acid, Lightning, Poison)
    shadow     = { r = 0.6, g = 0.4, b = 0.8 },      -- purple (Shadow, Necrotic)
    holy       = { r = 1.0, g = 0.9, b = 0.5 },      -- light yellow/gold (Holy, Radiant)
    arcane     = { r = 0.6, g = 0.8, b = 1.0 },      -- light blue-purple (Arcane, Psychic)
    fel        = { r = 0.7, g = 0.1, b = 0.9 },      -- bright purple (Fel)
}

Common.DamageSchoolInfo = {
    Physical = {
        color = damageSchoolColors.physical,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\melee.png",
    },
    Force = {
        color = damageSchoolColors.physical,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Fire = {
        color = damageSchoolColors.fire,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Frost = {
        color = damageSchoolColors.frost,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Cold = {
        color = damageSchoolColors.frost,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Nature = {
        color = damageSchoolColors.nature,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Acid = {
        color = damageSchoolColors.nature,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Lightning = {
        color = damageSchoolColors.nature,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Poison = {
        color = damageSchoolColors.nature,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Shadow = {
        color = damageSchoolColors.shadow,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Necrotic = {
        color = damageSchoolColors.shadow,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Holy = {
        color = damageSchoolColors.holy,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Radiant = {
        color = damageSchoolColors.holy,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Arcane = {
        color = damageSchoolColors.arcane,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Psychic = {
        color = damageSchoolColors.arcane,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
    Fel = {
        color = damageSchoolColors.fel,
        icon = "Interface\\AddOns\\RPEngine\\UI\\Textures\\spell.png",
    },
}

Common.RarityRank = {
    common    = 1,
    uncommon  = 2,
    rare      = 3,
    epic      = 4,
    legendary = 5,
}

function Common:GenerateGUID(prefix)
    -- Two 16-bit chunks → 8 hex digits
    local hi = math.random(0, 0xFFFF)
    local lo = math.random(0, 0xFFFF)
    local guid = string.format("%04x%04x", hi, lo)
    return string.format("%s-%s", prefix or "ID", guid)
end

function Common:CanonicalizeName(name)
    if not name then return nil end
    -- Blizzard names are case-insensitive, so we can just lower-case everything
    -- OR use proper capitalization if you prefer. Simplest is lowercase:
    return name:lower()
end
-- Stat lookup hook.
function Common:StatLookup(profile, id)
    RPE.Stats:GetValue(id)
end

--- Format a unit's display name for UI output
-- For non-NPCs with realm names (e.g. "Ortellus-ArgentDawn"), strips the realm and capitalizes properly
-- For NPCs, returns the name as-is
---@param unit table Unit object with .name and .isNPC fields
---@return string Formatted display name
function Common:FormatUnitName(unit)
    if not unit then return "Unknown" end
    local name = unit.name or unit.key or "Unknown"
    
    -- Only format non-NPC player names
    if not unit.isNPC and name:find("-") then
        name = name:match("^[^-]+") or name
        name = name:sub(1,1):upper() .. name:sub(2):lower()
    end
    
    return name
end

function Common:GetEquipment()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    local eq = profile.equipment

    return eq
end

function Common:GetInventory()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    local inv = profile.items
    
    return inv
end

function Common:GetAllUnits()
    local event = RPE.Core.ActiveEvent
    return event.units
end

function Common:Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

--- Colour a name (string) by item quality.
---@param name string
---@param quality string  -- e.g. "common","uncommon","rare","epic","legendary"
---@return string
function Common:ColorByQuality(name, quality)
    if not name or name == "" then return "" end
    local qc = self.QualityColors[quality or "common"]
    if not qc then return name end
    local r, g, b = qc.r or 1, qc.g or 1, qc.b or 1
    local hex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
    return ("|cff%s%s|r"):format(hex, name)
end

--- Parse a text string, replacing placeholders with live values.
--- Supported placeholders:
---   $stat.STATID$   → replaced with the effective stat value
---@param text string
---@param profile table|nil  -- optional CharacterProfile (defaults to active)
---@return string
function Common:ParseText(text, profile)
    if type(text) ~= "string" or text == "" then return text end

    -- Default to the active profile if not passed
    if not profile and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        profile = RPE.Profile.DB.GetOrCreateActive()
    end

    local function repl(kind, id)
        kind = (kind or ""):lower()
        if kind == "stat" and id and id ~= "" then
            local v = nil
            if profile and profile.GetStatValue then
                v = profile:GetStatValue(id)
            elseif RPE.Stats and RPE.Stats.GetValue then
                v = RPE.Stats:GetValue(id)
            end
            if v == nil then v = 0 end
            if type(v) == "number" and v ~= math.floor(v) then
                return string.format("%.2f", v)
            else
                return tostring(v)
            end
        end
        -- If we don't know how to handle it, leave the token as-is
        return "$" .. tostring(kind) .. "." .. tostring(id) .. "$"
    end

    -- Match $kind.ID$ (letters/numbers/underscore in ID)
    return (text:gsub("%$(%w+)%.([%w_]+)%$", repl))
end

function Common:ShowTooltip(anchor, spec)
    if not anchor then return end

    -- Normalize spec
    if type(spec) == "string" then
        spec = { title = spec, lines = {} }
    elseif type(spec) ~= "table" then
        spec = { title = tostring(spec or ""), lines = {} }
    end

    local fake   = RPE and RPE.Core and RPE.Core.Tooltip
    local uiShown = UIParent and UIParent:IsShown()

    local function addLines(tip, isFake)
        for _, ln in ipairs(spec.lines or {}) do
            if ln.left and ln.right then
                -- normal double line
                if isFake and not tip.AddDoubleLine then
                    tip:AddLine(("%s   %s"):format(ln.left or "", ln.right or ""),
                                isFake and {ln.r or 1, ln.g or 1, ln.b or 1} or ln.r or 1, ln.g or 1, ln.b or 1)
                else
                    if isFake then
                        tip:AddDoubleLine(ln.left or "", ln.right or "",
                            {ln.r or 1, ln.g or 1, ln.b or 1},
                            {ln.r2 or ln.r or 1, ln.g2 or ln.g or 1, ln.b2 or ln.b or 1})
                    else
                        tip:AddDoubleLine(ln.left or "", ln.right or "",
                            ln.r or 1, ln.g or 1, ln.b or 1,
                            ln.r2 or ln.r or 1, ln.g2 or ln.g or 1, ln.b2 or ln.b or 1)
                    end
                end
            elseif ln.left then
                -- single left column line
                if isFake then
                    tip:AddLine(ln.left, {ln.r or 1, ln.g or 1, ln.b or 1})
                else
                    tip:AddLine(ln.left, ln.r or 1, ln.g or 1, ln.b or 1, ln.wrap ~= false)
                end
            elseif ln.text then
                -- plain text line
                if isFake then
                    tip:AddLine(ln.text, {ln.r or 0.9, ln.g or 0.9, ln.b or 0.9})
                else
                    tip:AddLine(ln.text, ln.r or 0.9, ln.g or 0.9, ln.b or 0.9, ln.wrap ~= false)
                end
            end
        end
    end


    if fake and not uiShown then
        fake:ClearLines()
        if spec.title then fake:SetText(spec.title) end
        addLines(fake, true)
        fake:ShowForFrame(anchor, "BOTTOM", "TOP", 0, 6)
    else
        GameTooltip:Hide()  -- full reset of previous lines
        GameTooltip:SetOwner(anchor, "ANCHOR_TOP")

        if spec.title then
            if spec.titleColor then
                GameTooltip:SetText(spec.title,
                    spec.titleColor[1] or 1,
                    spec.titleColor[2] or 0.82,
                    spec.titleColor[3] or 0)
            else
                GameTooltip:SetText(spec.title)
            end
        end

        addLines(GameTooltip, false)
        GameTooltip:Show()
    end
end


function Common:HideTooltip()
    local fake = RPE and RPE.Core and RPE.Core.Tooltip
    local uiShown = UIParent and UIParent:IsShown()

    if fake and not uiShown then
        fake:Hide()
    else
        GameTooltip:Hide()
    end
end

-- ===== Event / Unit / Profile helpers (method style) =====
function Common:Event()
    return RPE.Core.ActiveEvent
end

function Common:LocalPlayerKey()
    local ev = self:Event()
    if ev and ev.localPlayerKey then return ev.localPlayerKey end
    if UnitName and GetRealmName then
        local n = UnitName("player")
        local r = (GetRealmName() or ""):gsub("%s+", "")
        if n and r and n ~= "" and r ~= "" then
            return (n .. "-" .. r):lower()
        end
    end
    return nil
end

function Common:LocalPlayerId()
    local ev = self:Event()
    if not (ev and ev.units) then return nil end
    local key = ev.localPlayerKey or self:LocalPlayerKey()
    local u = key and ev.units[key] or nil
    return u and tonumber(u.id) or nil
end

function Common:LocalPlayerTeam()
    local ev = self:Event()
    if not (ev and ev.units) then return nil end
    local key = ev.localPlayerKey or self:LocalPlayerKey()
    local u = key and ev.units[key] or nil
    return u and tonumber(u.team) or nil
end

---Find an EventUnit by numeric id; returns (unit, key) or (nil, nil).
function Common:FindUnitById(uid)
    local ev = self:Event()
    if not (ev and ev.units) then return nil, nil end
    for k, u in pairs(ev.units) do
        if tonumber(u.id) == tonumber(uid) then
            return u, k
        end
    end
    return nil, nil
end

---Find an EventUnit by its key; returns (unit, key) or (nil, nil).
---@param unitKey string
---@return EventUnit|nil, string|nil
function Common:FindUnitByKey(unitKey)
    local ev = self:Event()
    if not (ev and ev.units) or not unitKey then return nil, nil end
    for k, u in pairs(ev.units) do
        if u.key == unitKey then
            return u, k
        end
    end
    return nil, nil
end


---Resolve a CharacterProfile for an EventUnit (local->active, others->by name)
function Common:ProfileForUnit(u)
    if not u then return nil end
    local lk = self:LocalPlayerKey()
    if u.key and lk and u.key == lk then
        return RPE.Profile.DB.GetOrCreateActive()
    end
    -- For NPCs, return a temporary runtime profile-like object using unit ID as identifier
    -- This prevents creating persistent DB profiles for runtime NPCs
    if u.id then
        return { name = "npc:" .. tostring(u.id) }
    end
    return nil
end

---Aura stat eligibility: local player OR (NPC and player is leader/solo)
function Common:IsAuraStatsEligibleTarget(u)
    if not u then return false end
    local lk = self:LocalPlayerKey()
    if u.key and lk and u.key == lk then return true end
    local isNPC = (u.isNPC == true) or (u.isPlayer == false)
    if not isNPC then return false end
    if IsInGroup and UnitIsGroupLeader and IsInGroup() then
        return UnitIsGroupLeader("player")
    end
    return true -- solo counts as leader
end

---Roll dice with optional advantage/disadvantage
---@param spec string              -- dice spec like "1d20", "2d6"
---@param advantages table|nil     -- { hit=N, defense=N, all=N, [spellId]=N }
---@param disadvantages table|nil  -- same structure
---@param rollType string|nil      -- "hit", "defense", "all", or spell ID (for advantage/disadvantage lookup)
---@return number                  -- the selected roll (highest if advantage, lowest if disadvantage, only if normal)
function Common:Roll(spec, advantages, disadvantages, rollType)
    -- If advantages/disadvantages provided, use Advantage system
    if advantages or disadvantages then
        local Advantage = RPE.Core and RPE.Core.Advantage
        if Advantage and Advantage.RollWithMode then
            local selectedRoll = Advantage:RollWithMode(spec, advantages, disadvantages, rollType)
            return selectedRoll
        end
    end
    
    -- Fallback: standard roll without advantage/disadvantage
    spec = tostring(spec or "")
    local n, d = spec:match("^(%d+)%s*[dD]%s*(%d+)$")
    n = tonumber(n) or 1
    d = tonumber(d) or 100
    local total = 0
    for i = 1, n do
        total = total + math.random(1, d)
    end
    return total
end

-------------------------------------------------------------------------------
-- Recipe colour level (for professions)
-------------------------------------------------------------------------------

--- Return the colour code for a recipe based on player's profession level.
---@param playerLevel number  Player's current skill level in the profession
---@param recipeLevel number  Required skill level for the recipe
---@return string colorHex    A WoW-style hex colour (e.g. "|cffff0000")
function Common:GetRecipeColor(playerLevel, recipeLevel)
    playerLevel = tonumber(playerLevel) or 0
    recipeLevel = tonumber(recipeLevel) or 0
    local diff = playerLevel - recipeLevel

    -- Below required level
    if diff < 0 then
        return "|cffff0000" -- red
    -- Equal or just learned
    elseif diff == 0 then
        return "|cffff7f00" -- orange
    -- Within +15 levels
    elseif diff <= 15 then
        return "|cffffff00" -- yellow
    -- Within +30 levels
    elseif diff <= 30 then
        return "|cff00ff00" -- green
    -- Beyond +50 levels
    elseif diff >= 50 then
        return "|cff808080" -- grey
    else
        -- fallback in between (green→grey transition)
        return "|cff80ff80"
    end
end

function Common:FormatCopper(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperOnly = copper % 100

    local parts = {}
    if gold > 0 then table.insert(parts, gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t") end
    if silver > 0 then table.insert(parts, silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t") end
    if copperOnly > 0 or #parts == 0 then table.insert(parts, copperOnly .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t") end

    return table.concat(parts, " ")
end