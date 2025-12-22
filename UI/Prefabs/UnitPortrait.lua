-- RPE_UI/Prefabs/UnitPortrait.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local Colors       = RPE_UI.Colors

---@class UnitPortrait: FrameElement
---@field frame Button
---@field unit table
---@field box Frame            -- portrait box (square area)
---@field bg Texture           -- soft bg for the box
---@field outline table        -- {top,bottom,left,right} colored by team
---@field texture Texture      -- 2D fallback
---@field model PlayerModel    -- 3D model (NPCs only)
---@field hp Frame             -- health bar frame
---@field hpBG Texture         -- health bar background
---@field hpFill Texture       -- health bar fill
---@field castBar Frame        -- cast bar frame
---@field castBarBG Texture    -- cast bar background
---@field castBarFill Texture  -- cast bar fill
---@field castBarText FontString -- cast bar text
---@field raidIcon Texture     -- raid marker icon (bottom-left of box)
---@field raidIconFrame Frame  -- raid marker icon frame
---@field flyingIcon Texture   -- flying unit icon
---@field flyingIconFrame Frame -- flying unit icon frame
---@field statusRow Frame      -- container under HP bar
---@field hiddenOverlay Frame  -- overlay for hidden units
---@field auraIconsFrame Frame -- vertical aura icons container
---@field healedIcon Button
---@field threatIcon Button
---@field attackedIcon Button
---@field disengagedIcon Button
---@field activeBuffsIcon Button
---@field activeDebuffsIcon Button
---@field _hpCur number
---@field _hpMax number
---@field _castTimeRemaining number
---@field _castTimeTotal number
---@field _castIcon string
---@field _iconSize number
---@field _auraIconSize number
---@field _iconGap number
---@field _noHealthBar boolean
---@field _buffsGlowTimer table
---@field _debuffsGlowTimer table
local UnitPortrait = setmetatable({}, { __index = FrameElement })
UnitPortrait.__index = UnitPortrait
RPE_UI.Prefabs.UnitPortrait = UnitPortrait

local function RealmSlug(s) return s and s:gsub("%s+", "") or "" end
local function FullNameFor(token)
    local n, r = UnitName(token)
    if not n then return nil end
    r = r and r ~= "" and RealmSlug(r) or RealmSlug(GetRealmName())
    return (n .. "-" .. r):lower()
end
local function ResolveUnitTokenByFullName(nameFullLower)
    if not nameFullLower then return nil end
    if FullNameFor("player") == nameFullLower then return "player" end
    for i = 1, 4 do local t = "party"..i; if FullNameFor(t) == nameFullLower then return t end end
    for i = 1, 40 do local t = "raid"..i;  if FullNameFor(t) == nameFullLower then return t end end
    return nil
end

local function SafeSetPortraitTexture(tex, unitToken)
    if tex and unitToken and UnitExists(unitToken) then
        SetPortraitTexture(tex, unitToken)
        return true
    end
    return false
end

-- Try palette first (team1, team2, team3...) then fall back to a small set
local FALLBACK_TEAM_COLORS = {
    [1] = { 0.35, 0.65, 1.00, 1.00 }, -- blue
    [2] = { 1.00, 0.40, 0.35, 1.00 }, -- red
    [3] = { 0.40, 0.90, 0.45, 1.00 }, -- green
    [4] = { 0.75, 0.55, 1.00, 1.00 }, -- purple
}
local function GetTeamColor(team)
    team = tonumber(team or 1) or 1

    -- Try palette key: "team1", "team2", ...
    if Colors and Colors.Get then
        local r,g,b,a = Colors.Get("team"..team)
        if r ~= nil then
            return r,g,b,a
        end
    end

    -- Fallbacks
    local fb = FALLBACK_TEAM_COLORS[team] or FALLBACK_TEAM_COLORS[1]
    return fb[1], fb[2], fb[3], fb[4]
end

local function CreateSquareOutline(parentFrame, colorGetter)
    local width = 2

    local top = parentFrame:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -width, width)
    top:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", width, width)
    top:SetHeight(width)

    local bottom = parentFrame:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", -width, -width)
    bottom:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", width, -width)
    bottom:SetHeight(width)

    local left = parentFrame:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -width, width)
    left:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", -width, -width)
    left:SetWidth(width)

    local right = parentFrame:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", width, width)
    right:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", width, -width)
    right:SetWidth(width)

    local function apply(team)
        local r,g,b,a = colorGetter(team)
        top:SetColorTexture(r, g, b, a)
        bottom:SetColorTexture(r, g, b, a)
        left:SetColorTexture(r, g, b, a)
        right:SetColorTexture(r, g, b, a)
    end

    return { top = top, bottom = bottom, left = left, right = right, Apply = apply }
end

---@param name string
---@param opts table
function UnitPortrait:New(name, opts)
    opts = opts or {}
    local parentFrame = (opts.parent and opts.parent.frame) or UIParent
    local size    = opts.size or 48
    local hpH     = math.max(2, math.floor((opts.healthBarHeight or 6)))
    local spacing = 4

    -- Precompute icon sizes
    local iconSize = math.max(12, math.floor(size * 0.35))
    local auraIconSize = math.max(10, math.floor(size * 0.25))  -- smaller aura icons
    local auraStackWidth = auraIconSize + 2  -- small gap between stacked auras
    
    -- Total height includes HP + cast bar + status icons row
    local totalH   = size + hpH + spacing + hpH + spacing + iconSize + spacing

    -- Total width includes aura stack on left + portrait
    local totalW = auraStackWidth + spacing + size

    -- Total height includes aura stack (2 icons) on the side
    local totalH_WithAuras = math.max(totalH, auraIconSize * 2 + spacing)

    -- Total height includes HP + status icons row
    local f = CreateFrame("Button", name, parentFrame)
    f:SetSize(totalW, totalH_WithAuras)

    -- Aura icons frame (left side, vertical stack)
    local auraIconsFrame = CreateFrame("Frame", nil, f)
    auraIconsFrame:SetSize(auraStackWidth, auraIconSize * 2 + spacing)
    auraIconsFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    -- Inner "box" region reserved for the portrait/model
    local box = CreateFrame("Frame", nil, f)
    box:SetSize(size, size)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", auraStackWidth + spacing, 0)

    -- Overlay for hidden units (semi-transparent grey) - create on top-level frame
    local hiddenOverlay = CreateFrame("Frame", nil, f)
    hiddenOverlay:SetAllPoints(box)
    hiddenOverlay:SetFrameLevel(box:GetFrameLevel() + 100)  -- Ensure it's well above everything
    
    local overlayTexture = hiddenOverlay:CreateTexture(nil, "BACKGROUND")
    overlayTexture:SetAllPoints()
    overlayTexture:SetTexture("Interface\\AddOns\\RPEngine\\UI\\Textures\\hidden_overlay.png")
    overlayTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    hiddenOverlay:Hide()

    -- Soft square background in the box - set to low frame level so it doesn't dim the model
    local bgFrame = CreateFrame("Frame", nil, box)
    bgFrame:SetAllPoints()
    bgFrame:SetFrameLevel(1)  -- Low level so it's behind the model
    bgFrame:Hide()
    
    if not opts.noBackground then
        local bg = bgFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        do
            local r,g,b,a = Colors.Get("background")
            if opts.unit.isNPC then
                bg:SetColorTexture(r, g, b, 0.35)
            else
                bg:SetColorTexture(0, 0, 0, 1)
            end
        end 
        bgFrame:Show()
    end

    -- Team-colored outline around the box
    local outline = CreateSquareOutline(box, GetTeamColor)

    -- 2D portrait (players + fallback)
    local portrait = box:CreateTexture(nil, "ARTWORK")
    portrait:SetAllPoints()
    portrait:Hide()
    self.icon = portrait

    -- 3D model (NPCs only)
    local model = CreateFrame("PlayerModel", nil, box)
    model:SetAllPoints()
    model:SetPortraitZoom(0.6)
    model:SetRotation(0.15*math.pi)
    model:SetPosition(0, 0, -0.2)
    model:SetFrameLevel(5)  -- Lower level so raid icon can be above it
    model:Hide()
    self.model = model

    -- Health bar under the box (unless noHealthBar is set)
    local hp = CreateFrame("Frame", nil, f)
    hp:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -spacing)
    hp:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -spacing)
    hp:SetHeight(hpH)
    if opts.noHealthBar then
        hp:Hide()
    end

    local hpBG = hp:CreateTexture(nil, "BACKGROUND")
    hpBG:SetAllPoints()
    hpBG:SetColorTexture(0, 0, 0, 0.7)

    local hpFill = hp:CreateTexture(nil, "ARTWORK")
    hpFill:SetPoint("LEFT", hp, "LEFT", 0, 0)
    hpFill:SetPoint("TOP",  hp, "TOP",  0, 0)
    hpFill:SetPoint("BOTTOM", hp, "BOTTOM", 0, 0)
    hpFill:SetWidth(0)
    hpFill:SetColorTexture(0.20, 0.85, 0.30, 1.0)

    -- Cast bar under the health bar (positioned relative to box to work even when hp is hidden)
    local castBar = CreateFrame("Frame", nil, f)
    castBar:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -spacing - hpH - spacing)
    castBar:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -spacing - hpH - spacing)
    castBar:SetHeight(hpH)

    local castBarBG = castBar:CreateTexture(nil, "BACKGROUND")
    castBarBG:SetAllPoints()
    castBarBG:SetColorTexture(0, 0, 0, 0.7)

    -- Cast icon (left side of bar)
    local castBarIcon = castBar:CreateTexture(nil, "ARTWORK")
    castBarIcon:SetSize(16, 16)
    castBarIcon:SetPoint("RIGHT", castBar, "LEFT", -2, 0)
    castBarIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    castBarIcon:Hide()

    local castBarFill = castBar:CreateTexture(nil, "ARTWORK")
    castBarFill:SetPoint("LEFT", castBar, "LEFT", 0, 0)
    castBarFill:SetPoint("TOP", castBar, "TOP", 0, 0)
    castBarFill:SetPoint("BOTTOM", castBar, "BOTTOM", 0, 0)
    castBarFill:SetWidth(0)
    do
        local r,g,b,a = Colors.Get("progress_cast")
        castBarFill:SetColorTexture(r, g, b, a)
    end

    -- Preview bar (fainter, shows ahead of actual progress)
    local castBarPreview = castBar:CreateTexture(nil, "ARTWORK")
    castBarPreview:SetPoint("LEFT", castBar, "LEFT", 0, 0)
    castBarPreview:SetPoint("TOP", castBar, "TOP", 0, 0)
    castBarPreview:SetPoint("BOTTOM", castBar, "BOTTOM", 0, 0)
    castBarPreview:SetWidth(0)
    do
        local r,g,b,a = Colors.Get("progress_cast")
        castBarPreview:SetColorTexture(r, g, b, a * 0.3)  -- Same color but fainter
    end
    castBarPreview:SetDrawLayer("ARTWORK", 0)  -- Behind main fill

    local castBarText = castBar:CreateFontString(nil, "OVERLAY")
    castBarText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    castBarText:SetPoint("LEFT", castBar, "LEFT", 4, 0)
    castBarText:SetTextColor(1, 1, 1, 1)
    castBarText:SetText("Casting...")
    castBarText:Hide()

    -- === Status icons row (under the cast bar) ===
    local statusRow = CreateFrame("Frame", nil, f)
    statusRow:SetPoint("TOPLEFT",  castBar.frame, "BOTTOMLEFT", 0, -spacing)
    statusRow:SetPoint("TOPRIGHT", castBar.frame, "BOTTOMRIGHT", 0, -spacing)
    statusRow:SetHeight(iconSize)

    -- === Aura icons row (below status row) ===
    local auraRow = CreateFrame("Frame", nil, f)
    auraRow:SetPoint("TOPLEFT",  statusRow, "BOTTOMLEFT", 0, -spacing)
    auraRow:SetPoint("TOPRIGHT", statusRow, "BOTTOMRIGHT", 0, -spacing)
    auraRow:SetHeight(iconSize)

    local function makeStatusIcon(parent, texturePath, tooltipText)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(iconSize, iconSize)
        btn:SetPoint("CENTER", parent, "CENTER", 0, 0) -- temp; real position set by LayoutStatusIcons
        btn:EnableMouse(true)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(texturePath)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        btn:Hide()
        return btn
    end

    local healedIcon = makeStatusIcon(
        statusRow,
        "Interface\\AddOns\\RPEngine\\UI\\Textures\\healed_last.png",
        "You healed or protected this unit last turn."
    )

    local threatIcon = makeStatusIcon(
        statusRow,
        "Interface\\AddOns\\RPEngine\\UI\\Textures\\threat.png",
        "You are at the top of this unit's threat table."
    )

    local attackedIcon = makeStatusIcon(
        statusRow,
        "Interface\\AddOns\\RPEngine\\UI\\Textures\\attacked_last.png",
        "You attacked this unit last turn."
    )

    local disengagedIcon = makeStatusIcon(
        statusRow,
        "Interface\\AddOns\\RPEngine\\UI\\Textures\\disengaged.png",
        "This unit is disengaged from combat."
    )

    -- Aura icons (vertical stack on left side)
    local function makeAuraIcon(parent, texturePath, tooltipText, colorKey)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(auraIconSize, auraIconSize)
        btn:SetPoint("CENTER", parent, "CENTER", 0, 0) -- temp; real position set by LayoutAuraIcons
        btn:EnableMouse(true)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(texturePath)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
        -- Apply color if provided
        if colorKey and Colors and Colors.Get then
            local r, g, b, a = Colors.Get(colorKey)
            if r ~= nil then
                tex:SetVertexColor(r, g, b, a or 1)
            end
        end

        btn:Hide()
        return btn
    end

    local activeBuffsIcon = makeAuraIcon(
        auraIconsFrame,
        "Interface\\AddOns\\RPEngine\\UI\\Textures\\active_buffs.png",
        "Active Beneficial Auras",
        "textBonus"
    )

    local activeDebuffsIcon = makeAuraIcon(
        auraIconsFrame,
        "Interface\\AddOns\\RPEngine\\UI\\Textures\\active_debuffs.png",
        "Active Harmful Auras",
        "textMalus"
    )

    -- Raid marker icon - initialize early (will be populated later)
    local raidIcon = nil
    local raidIconFrame = nil

    -- Flying icon frame - initialize early (will be populated later)
    local flyingIcon = nil
    local flyingIconFrame = nil

    -- Object wrapper
    local o = FrameElement.New(self, "UnitPortrait", f, opts.parent)
    o.unit     = opts.unit
    o.box      = box
    o.bg       = bg
    o.outline  = outline
    o.texture  = portrait
    o.model    = model
    o.hp       = hp
    o.hpBG     = hpBG
    o.hpFill   = hpFill
    o.castBar  = castBar
    o.castBarBG = castBarBG
    o.castBarIcon = castBarIcon
    o.castBarFill = castBarFill
    o.castBarPreview = castBarPreview
    o.castBarText = castBarText
    o.raidIcon = raidIcon
    o._hpCur   = nil
    o._hpMax   = nil
    o._castTimeRemaining = nil
    o._castTimeTotal = nil

    
    o.statusRow    = statusRow
    o.auraIconsFrame = auraIconsFrame
    o.healedIcon   = healedIcon
    o.threatIcon   = threatIcon
    o.attackedIcon = attackedIcon
    o.disengagedIcon = disengagedIcon
    o.activeBuffsIcon = activeBuffsIcon
    o.activeDebuffsIcon = activeDebuffsIcon
    o._iconSize = iconSize
    o._auraIconSize = auraIconSize
    o._iconGap  = 4
    o.hiddenOverlay = hiddenOverlay
    o._noHealthBar = opts.noHealthBar or false
    
    -- Pulse timers for aura icons
    o._buffsGlowTimer = nil
    o._debuffsGlowTimer = nil

    local portrait = o 
    
    -- Setup aura icon tooltips (now that o exists)
    activeBuffsIcon:SetScript("OnEnter", function()
        local auraLines = {}
        local localPlayerUnitId = nil
        
        if o.unit and o.unit.id then
            local ev = RPE.Core and RPE.Core.ActiveEvent
            if ev then
                -- Get local player's unit ID for coloring check
                if ev.localPlayerKey then
                    local localPlayerUnit = ev.units and ev.units[ev.localPlayerKey]
                    localPlayerUnitId = localPlayerUnit and localPlayerUnit.id
                end
                
                if ev._auraManager then
                    local auras = ev._auraManager:All(o.unit.id)
                    if auras then
                        for _, aura in ipairs(auras) do
                            if aura.def and aura.def.isHelpful and not aura.def.hidden then
                                table.insert(auraLines, aura)
                            end
                        end
                    end
                end
            end
        end
        
        -- Sort by remaining turns ascending
        table.sort(auraLines, function(a, b)
            return (a.remaining or 0) < (b.remaining or 0)
        end)
        
        local lines = {}
        local currentTurn = 0
        if o.unit and o.unit.id then
            local ev = RPE.Core and RPE.Core.ActiveEvent
            if ev then
                currentTurn = ev.turn or 0
            end
        end
        
        for _, aura in ipairs(auraLines) do
            local name = aura.def and aura.def.name or "Unknown"
            local icon = aura.def and aura.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
            local iconStr = "|T" .. icon .. ":16:16:0:0|t "
            
            -- Calculate remaining turns from expiresOn
            local remaining = 0
            if aura.expiresOn then
                remaining = math.max(0, aura.expiresOn - currentTurn)
            end
            
            -- Check if cast by local player
            local isLocalPlayerAura = localPlayerUnitId and aura.sourceId == localPlayerUnitId
            local r, g, b, a = 1, 1, 1, 1
            if isLocalPlayerAura then
                r, g, b, a = Colors.Get("textModified")
            end
            
            -- Build line with right field (always present, empty if 0 turns)
            local turnsText = ""
            if remaining > 0 then
                turnsText = remaining == 1 and "1 turn" or remaining .. " turns"
            end
            
            table.insert(lines, {
                left = iconStr .. name,
                right = turnsText,
                r = r, g = g, b = b
            })
        end
        
        if #lines == 0 then
            table.insert(lines, {
                text = "This unit has no buffs.",
                r = 0.7, g = 0.7, b = 0.7,
                wrap = false
            })
        end
        
        if Common and Common.ShowTooltip then
            Common:ShowTooltip(activeBuffsIcon, {
                title = "Active Buffs",
                lines = lines
            })
        else
            GameTooltip:SetOwner(activeBuffsIcon, "ANCHOR_RIGHT")
            GameTooltip:SetText("Active Buffs", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    activeBuffsIcon:SetScript("OnLeave", function()
        if Common and Common.HideTooltip then
            Common:HideTooltip()
        else
            GameTooltip:Hide()
        end
    end)
    
    activeDebuffsIcon:SetScript("OnEnter", function()
        local auraLines = {}
        local localPlayerUnitId = nil
        
        if o.unit and o.unit.id then
            local ev = RPE.Core and RPE.Core.ActiveEvent
            if ev then
                -- Get local player's unit ID for coloring check
                if ev.localPlayerKey then
                    local localPlayerUnit = ev.units and ev.units[ev.localPlayerKey]
                    localPlayerUnitId = localPlayerUnit and localPlayerUnit.id
                end
                
                if ev._auraManager then
                    local auras = ev._auraManager:All(o.unit.id)
                    if auras then
                        for _, aura in ipairs(auras) do
                            if aura.def and not aura.def.isHelpful and not aura.def.hidden then
                                table.insert(auraLines, aura)
                            end
                        end
                    end
                end
            end
        end
        
        -- Sort by remaining turns ascending
        table.sort(auraLines, function(a, b)
            return (a.remaining or 0) < (b.remaining or 0)
        end)
        
        local lines = {}
        local currentTurn = 0
        if o.unit and o.unit.id then
            local ev = RPE.Core and RPE.Core.ActiveEvent
            if ev then
                currentTurn = ev.turn or 0
            end
        end
        
        for _, aura in ipairs(auraLines) do
            local name = aura.def and aura.def.name or "Unknown"
            local icon = aura.def and aura.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
            local iconStr = "|T" .. icon .. ":16:16:0:0|t "
            
            -- Calculate remaining turns from expiresOn
            local remaining = 0
            if aura.expiresOn then
                remaining = math.max(0, aura.expiresOn - currentTurn)
            end
            
            -- Check if cast by local player
            local isLocalPlayerAura = localPlayerUnitId and aura.sourceId == localPlayerUnitId
            local r, g, b, a = 1, 1, 1, 1
            if isLocalPlayerAura then
                r, g, b, a = Colors.Get("textModified")
            end
            
            -- Build line with right field (always present, empty if 0 turns)
            local turnsText = ""
            if remaining > 0 then
                turnsText = remaining == 1 and "1 turn" or remaining .. " turns"
            end
            
            table.insert(lines, {
                left = iconStr .. name,
                right = turnsText,
                r = r, g = g, b = b
            })
        end
        
        if #lines == 0 then
            table.insert(lines, {
                text = "This unit has no debuffs.",
                r = 0.7, g = 0.7, b = 0.7,
                wrap = false
            })
        end
        
        if Common and Common.ShowTooltip then
            Common:ShowTooltip(activeDebuffsIcon, {
                title = "Active Debuffs",
                lines = lines
            })
        else
            GameTooltip:SetOwner(activeDebuffsIcon, "ANCHOR_RIGHT")
            GameTooltip:SetText("Active Debuffs", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    activeDebuffsIcon:SetScript("OnLeave", function()
        if Common and Common.HideTooltip then
            Common:HideTooltip()
        else
            GameTooltip:Hide()
        end
    end)

    -- Tooltip hover for the whole portrait
    f:SetScript("OnEnter", function()
        if o.unit then
            local isLeader = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()
            local ev = RPE.Core and RPE.Core.ActiveEvent
            local localPlayerKey = ev and ev.localPlayerKey
            local isAlly = localPlayerKey and o.unit.team and ev.units[localPlayerKey] and ev.units[localPlayerKey].team == o.unit.team
            
            -- Hidden units: only show tooltip to leader, or to allies
            if o.unit.hidden then
                if not isLeader and not isAlly then
                    Common:ShowTooltip(f, {
                        title = "Unknown Enemy",
                        titleColor = { 1, 0.2, 0.2 },
                        lines = {},
                    })
                    return
                end
                -- For leader or allies, show normal tooltip below
            end

            if o.unit.GetTooltip then
                local spec = o.unit:GetTooltip({ health = true, initiative = true })
                if spec then
                    Common:ShowTooltip(f, spec)
                end
            end
        end
    end)

    f:SetScript("OnLeave", function()
        Common:HideTooltip()
    end)

    f:SetScript("OnClick", function()
        if not portrait.unit then 
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal("[UnitPortrait:OnClick] No unit in portrait")
            end
            return 
        end
        
        local unit = portrait.unit
        if not unit.isNPC or not unit.spells or #unit.spells == 0 then 
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(("[UnitPortrait:OnClick] Not controllable: isNPC=%s, spells=%d"):format(
                    tostring(unit.isNPC), unit.spells and #unit.spells or 0))
            end
            return 
        end
        
        -- Check if player can control this NPC
        local isLeader = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()
        local canControl = isLeader
        
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[UnitPortrait:OnClick] Unit: %s (id=%d, summonedBy=%s), isLeader=%s"):format(
                unit.name, unit.id, tostring(unit.summonedBy), tostring(isLeader)))
        end
        
        -- If not leader, check if player summoned this pet
        if not canControl and unit.summonedBy then
            local ev = RPE.Core and RPE.Core.ActiveEvent
            local localPlayerUnitId = ev and ev.GetLocalPlayerUnitId and ev:GetLocalPlayerUnitId()
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(("[UnitPortrait:OnClick] Checking summoner: localPlayerUnitId=%s, unit.summonedBy=%s"):format(
                    tostring(localPlayerUnitId), tostring(unit.summonedBy)))
            end
            if localPlayerUnitId and unit.summonedBy and localPlayerUnitId == unit.summonedBy then
                canControl = true
            end
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(("[UnitPortrait:OnClick] Summoner check result: canControl=%s"):format(
                    tostring(canControl)))
            end
        end
        
        if not canControl then 
            if RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal(("[UnitPortrait:OnClick] Cannot control unit (not leader and not summoner)"))
            end
            return 
        end
        
        if RPE.Debug and RPE.Debug.Internal then
            RPE.Debug:Internal(("[UnitPortrait:OnClick] Can control unit, opening action bar"))
        end

        local SR = RPE.Core.SpellRegistry
        if not SR then return end

        local actions = {}
        for i, spellId in ipairs(unit.spells) do
            local spell = SR:Get(spellId)
            if spell then
                actions[i] = {
                    spellId   = spellId,
                    rank      = 1,
                    icon      = spell.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    isEnabled = true,
                }
            end
        end

        local actionBar = RPE.Core.Windows and RPE.Core.Windows.ActionBarWidget
        if actionBar then
            -- Pass unit.id and unit.name so spells can be cast as this unit and they can speak as it
            local Common = RPE and RPE.Common
            local displayName = Common and Common.FormatUnitName and Common:FormatUnitName(unit) or unit.name
            actionBar:SetTemporaryActions(actions, displayName, { 0.3, 0.2, 0.1, 0.95 }, unit.id, unit.name) -- brown tint
        end

        local PUW = RPE.Core.Windows and RPE.Core.Windows.PlayerUnitWidget
        if PUW then
            PUW:SetTemporaryStats(unit)
        end
    end)

    o:Refresh()
    o:ApplyTeamColor()
    o:ApplyRaidMarker()

    -- Raid marker icon (created on a dedicated frame with high level to render above model)
    local raidIconFrame = CreateFrame("Frame", nil, f)
    raidIconFrame:SetSize(size * 0.3, size * 0.3)  -- Smaller icon
    raidIconFrame:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", 2, 2)
    raidIconFrame:SetFrameLevel(20)  -- VERY high level to ensure it's above the model
    raidIconFrame:Hide()
    
    local raidIcon = raidIconFrame:CreateTexture(nil, "OVERLAY")
    raidIcon:SetAllPoints(raidIconFrame)
    raidIcon:SetDrawLayer("OVERLAY", 7)
    
    o.raidIcon = raidIcon
    o.raidIconFrame = raidIconFrame

    -- Flying icon (created on a dedicated frame with high level to render above model)
    local flyingIconFrame = CreateFrame("Frame", nil, f)
    flyingIconFrame:SetSize(size * 0.3, size * 0.3)  -- Smaller icon
    flyingIconFrame:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -2, 2)
    flyingIconFrame:SetFrameLevel(20)  -- VERY high level to ensure it's above the model
    flyingIconFrame:Hide()
    
    local flyingIcon = flyingIconFrame:CreateTexture(nil, "OVERLAY")
    flyingIcon:SetAllPoints(flyingIconFrame)
    flyingIcon:SetDrawLayer("OVERLAY", 7)
    
    o.flyingIcon = flyingIcon
    o.flyingIconFrame = flyingIconFrame
    -- Hidden by default until values are set
    o.hp:Hide()
    o.castBar:Hide()
    o.statusRow:Hide()
    o.healedIcon:Hide()
    o.threatIcon:Hide()
    o.attackedIcon:Hide()
    o.disengagedIcon:Hide()
    o.activeBuffsIcon:Hide()
    o.activeDebuffsIcon:Hide()

    return o
end

function UnitPortrait:SetUnit(u)
    self.unit = u
    self:Refresh()
    self:ApplyTeamColor()
    self:ApplyRaidMarker()
    self:ApplyFlyingIcon()
    self:UpdateStatusRowVisibility()
end

--- Greyscale / disable the portrait and all its visuals.
---@param flag boolean
function UnitPortrait:SetDisabled(flag)
    if flag then
        -- Entire frame non-interactive
        self.frame:Disable()

        -- 2D portrait
        if self.texture and self.texture.SetDesaturated then
            self.texture:SetDesaturated(true)
            self.texture:SetVertexColor(0.4, 0.4, 0.4)
        end

        -- 3D model fallback
        if self.model then
            self.model:SetAlpha(0.4)
        end

        -- Outline/border
        if self.outline then
            self.outline.top:SetVertexColor(0.4,0.4,0.4,1)
            self.outline.bottom:SetVertexColor(0.4,0.4,0.4,1)
            self.outline.left:SetVertexColor(0.4,0.4,0.4,1)
            self.outline.right:SetVertexColor(0.4,0.4,0.4,1)
        end

        -- Background
        if self.bg then
            self.bg:SetVertexColor(0.4,0.4,0.4,1)
        end

        -- Health bar
        if self.hpBG then self.hpBG:SetVertexColor(0.4,0.4,0.4,1) end
        if self.hpFill then self.hpFill:SetVertexColor(0.4,0.4,0.4,1) end

        self.frame:SetAlpha(0.6)

    else
        -- Re-enable frame
        self.frame:Enable()

        -- Portrait
        if self.texture and self.texture.SetDesaturated then
            self.texture:SetDesaturated(false)
            self.texture:SetVertexColor(1,1,1,1)
        end
        if self.model then
            self.model:SetAlpha(1.0)
        end

        -- Outline
        if self.outline and self.unit then
            self:ApplyTeamColor()
        end

        -- Background
        if self.bg then
            self.bg:SetVertexColor(1,1,1,1)
        end

        -- HP bar
        if self.hpBG then self.hpBG:SetVertexColor(0,0,0,0.7) end
        if self.hpFill then self.hpFill:SetVertexColor(0.20, 0.85, 0.30, 1.0) end

        self.frame:SetAlpha(1.0)
    end
end


function UnitPortrait:ApplyTeamColor()
    local team = self.unit and self.unit.team or 1
    if self.outline and self.outline.Apply then
        self.outline.Apply(team) -- note: not a method; no implicit self
    end
end

-- Raid marker rendering (strictly 1..8)
function UnitPortrait:ApplyRaidMarker()
    if not self.raidIcon then return end
    if not self.unit then
        if self.raidIconFrame then self.raidIconFrame:Hide() end
        return
    end
    
    local marker = self.unit.raidMarker
    if not marker then marker = nil end
    marker = tonumber(marker)
    
    if marker and marker >= 1 and marker <= 8 then
        self.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..marker)
        self.raidIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        self.raidIcon:SetDrawLayer("OVERLAY", 7)
        if self.raidIconFrame then 
            self.raidIconFrame:SetFrameLevel(20)  -- Ensure high level
            self.raidIconFrame:Show() 
        end
    else
        if self.raidIconFrame then self.raidIconFrame:Hide() end
    end
end

-- Flying unit icon rendering
function UnitPortrait:ApplyFlyingIcon()
    if not self.flyingIcon then return end
    if not self.unit then
        if self.flyingIconFrame then self.flyingIconFrame:Hide() end
        return
    end
    
    local isFlying = self.unit.flying
    
    if isFlying then
        self.flyingIcon:SetTexture("Interface\\Addons\\RPEngine\\UI\\Textures\\flying.png")
        self.flyingIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        self.flyingIcon:SetDrawLayer("OVERLAY", 7)
        if self.flyingIconFrame then 
            self.flyingIconFrame:SetFrameLevel(20)  -- Ensure high level
            self.flyingIconFrame:Show() 
        end
    else
        if self.flyingIconFrame then self.flyingIconFrame:Hide() end
    end
end

-- Public API for health; will show/hide bar automatically
function UnitPortrait:SetHealth(cur, max)
    cur = tonumber(cur)
    max = tonumber(max)
    self._hpCur, self._hpMax = cur, max
    
    if not (cur and max and max > 0) then
        self.hp:Hide()
        return
    end

    local pct = math.max(0, math.min(1, cur / max))
    local w = self.hp:GetWidth()
    if w <= 0 then
        C_Timer.After(0, function()
            if self.hp and self.hp:GetWidth() > 0 then
                self.hpFill:SetWidth(self.hp:GetWidth() * pct)
                -- Do NOT refresh absorption here - it was already set separately
            end
        end)
    else
        self.hpFill:SetWidth(w * pct)
        -- Do NOT refresh absorption here - it was already set separately
    end

    if cur ~= 0 then
        self.hp:Show()
    else
        self.hp:Hide()
    end
end

--- Set cast bar progress
---@param timeRemaining number -- turns remaining in cast
---@param timeTotal number -- total cast time in turns
---@param castName string -- name of what's being cast
---@param icon string|nil -- icon texture path for the spell (optional)
function UnitPortrait:SetCast(timeRemaining, timeTotal, castName, icon)
    timeRemaining = tonumber(timeRemaining)
    timeTotal = tonumber(timeTotal)
    self._castTimeRemaining = timeRemaining
    self._castTimeTotal = timeTotal
    self._castIcon = icon
    
    -- Only proceed if we have valid numeric values
    if timeRemaining == nil or timeTotal == nil or timeTotal <= 0 then
        return
    end

    self.castBar:Show()
    
    -- Show spell icon
    if icon then
        self.castBarIcon:SetTexture(icon)
        self.castBarIcon:Show()
    else
        self.castBarIcon:Hide()
    end
    
    -- Always update the main bar based on actual progress (animated)
    local pct = math.max(0, math.min(1, (timeTotal - timeRemaining) / timeTotal))
    local w = self.castBar:GetWidth()
    
        local function startPreviewAnimation()
        local function animatePreviewCycle()
            if not self.castBar or not self.castBar:IsShown() then return end
            
            local barWidth = self.castBar:GetWidth()
            if barWidth <= 0 then return end
            
            local startWidth = barWidth * 0.1  -- Start from 10%
            local endWidth = barWidth          -- End at 100%
            
            -- Animate preview bar from 10% to 100% over 3 seconds
            local animStartTime = GetTime()
            local function updatePreview()
                if not self.castBar or not self.castBar:IsShown() or not self.castBarPreview then
                    return
                end
                
                local elapsed = GetTime() - animStartTime
                if elapsed < 1 then
                    -- Animating
                    local pct_preview = elapsed / 1.0
                    local width = startWidth + (endWidth - startWidth) * pct_preview
                    self.castBarPreview:SetWidth(width)
                else
                    -- Cycle complete, restart
                    animatePreviewCycle()
                    return
                end
                
                -- Schedule next update
                C_Timer.After(0.016, updatePreview)  -- ~60fps
            end
            
            updatePreview()
        end
        
        animatePreviewCycle()
    end
    
    local function animateMainBar()
        if not self._animatingMainBar or not self.castBarFill then return end
        
        local now = GetTime()
        local elapsed = now - (self._mainBarAnimStartTime or now)
        local currentWidth = self.castBarFill:GetWidth()
        local targetWidth = self._mainBarTargetWidth or 0
        local diff = targetWidth - currentWidth
        
        if math.abs(diff) > 0.5 then
            -- Animate over 0.3 seconds
            local newWidth = currentWidth + diff * math.min(1, elapsed / 0.3)
            self.castBarFill:SetWidth(newWidth)
            C_Timer.After(0.016, animateMainBar)  -- Continue animation
        else
            -- Animation complete, snap to target
            self.castBarFill:SetWidth(targetWidth)
            self._animatingMainBar = false
            
            -- Now start preview animation if this is the first SetCast
            if not self._castAnimationActive then
                self._castAnimationActive = true
                startPreviewAnimation()
            end
            
            -- If bar is at 100%, schedule auto-clear after 1.5 seconds
            if targetWidth >= (self.castBar:GetWidth() or 1) then
                if self._autoClearTimer then
                    self._autoClearTimer:Cancel()
                end
                self._autoClearTimer = C_Timer.NewTimer(1.5, function()
                    self:ClearCast()
                end)
            end
        end
    end
    
    
    local function startMainBarAnimation()
        if w <= 0 then
            C_Timer.After(0, function()
                if self.castBar and self.castBar:GetWidth() > 0 then
                    local targetWidth = self.castBar:GetWidth() * pct
                    self._mainBarTargetWidth = targetWidth
                    self._mainBarAnimStartTime = GetTime()
                    self._animatingMainBar = true
                    animateMainBar()
                end
            end)
        else
            local targetWidth = w * pct
            self._mainBarTargetWidth = targetWidth
            self._mainBarAnimStartTime = GetTime()
            self._animatingMainBar = true
            animateMainBar()
        end
    end
    
    startMainBarAnimation()
end

--- Hide the cast bar
function UnitPortrait:ClearCast()
    if self._autoClearTimer then
        self._autoClearTimer:Cancel()
        self._autoClearTimer = nil
    end
    
    self.castBar:Hide()
    self.castBarIcon:Hide()
    self.castBarFill:SetWidth(0)
    self.castBarPreview:SetWidth(0)
    self.castBarText:Hide()
    self._castTimeRemaining = nil
    self._castTimeTotal = nil
    self._castAnimationActive = false
    self._animatingMainBar = false
end

--- Greyscale / disable the portrait and all its visuals.
function UnitPortrait:SetAbsorption(absorbAmount)
    absorbAmount = math.max(0, absorbAmount or 0)
    self._lastAbsorbAmount = absorbAmount  -- Store for refresh
    
    if not self.hpAbsorption then
        -- Create absorption texture if it doesn't exist
        self.hpAbsorption = self.hp:CreateTexture(nil, "ARTWORK")
        self.hpAbsorption:SetColorTexture(1, 1, 1, 0.6)  -- white, semi-transparent
    end

    
    if absorbAmount > 0 and self._hpMax and self._hpMax > 0 then
        -- Health and absorption both scale proportionally to max
        local healthValue = self._hpCur or 0
        local totalValue = healthValue + absorbAmount
        local totalPct = math.min(totalValue / self._hpMax, 1.0)
        
        -- Health proportion: what fraction of total is health?
        local healthPct
        if totalValue > 0 then
            healthPct = healthValue / totalValue
        else
            healthPct = 1.0
        end
        
        -- Health width is proportional to its share of the total capped value
        local barWidth = self.hp:GetWidth()
        
        -- If bar width is not yet set (layout not complete), defer calculation
        if barWidth <= 0 then
            if RPE and RPE.Debug and RPE.Debug.Internal then
                RPE.Debug:Internal("[UnitPortrait:SetAbsorption] Bar width not ready, deferring...")
            end
            C_Timer.After(0, function()
                if self.hp and self.hp:GetWidth() > 0 then
                    self:SetAbsorption(absorbAmount)
                end
            end)
            return
        end
        
        local healthW = barWidth * totalPct * healthPct
        local absorbW = barWidth * totalPct * (1 - healthPct)
        
        -- Update health fill width (was set in SetHealth, now update with absorption)
        self.hpFill:SetWidth(healthW)
        
        -- Position and size absorption segment
        self.hpAbsorption:SetHeight(self.hp:GetHeight())
        self.hpAbsorption:SetWidth(math.max(0, absorbW))
        self.hpAbsorption:SetPoint("LEFT", self.hp, "LEFT", healthW, 0)
        if absorbW > 0 then
            self.hpAbsorption:Show()
        else
            self.hpAbsorption:Hide()
        end
    else
        if self.hpAbsorption then
            self.hpAbsorption:SetWidth(0)
            self.hpAbsorption:Hide()
        end
    end
end

function UnitPortrait:UpdateStatusRowVisibility()
    if not self.statusRow then return end
    local anyShown = (self.healedIcon and self.healedIcon:IsShown())
        or (self.threatIcon and self.threatIcon:IsShown())
        or (self.attackedIcon and self.attackedIcon:IsShown())
        or (self.disengagedIcon and self.disengagedIcon:IsShown())
    if anyShown then
        self.statusRow:Show()
        self:LayoutStatusIcons()
    else
        self.statusRow:Hide()
    end
    
    -- Check aura icons visibility
    if not self.auraIconsFrame then return end
    local anyAuraShown = (self.activeBuffsIcon and self.activeBuffsIcon:IsShown())
        or (self.activeDebuffsIcon and self.activeDebuffsIcon:IsShown())
    if anyAuraShown then
        self.auraIconsFrame:Show()
        self:LayoutAuraIcons()
    else
        self.auraIconsFrame:Hide()
    end
end

function UnitPortrait:SetStatusIcons(healed, threat, attacked, disengaged)
    if self.healedIcon   then self.healedIcon:SetShown(healed and true or false) end
    if self.threatIcon   then self.threatIcon:SetShown(threat and true or false) end
    if self.attackedIcon then self.attackedIcon:SetShown(attacked and true or false) end
    if self.disengagedIcon then self.disengagedIcon:SetShown(disengaged and true or false) end
    self:UpdateStatusRowVisibility()
end

function UnitPortrait:SetHealedLast(flag)
    if self.healedIcon then self.healedIcon:SetShown(flag and true or false) end
    self:UpdateStatusRowVisibility()
end

function UnitPortrait:SetThreatTop(flag)
    if self.threatIcon then self.threatIcon:SetShown(flag and true or false) end
    self:UpdateStatusRowVisibility()
end

function UnitPortrait:SetAttackedLast(flag)
    if self.attackedIcon then self.attackedIcon:SetShown(flag and true or false) end
    self:UpdateStatusRowVisibility()
end

function UnitPortrait:SetDisengaged(flag)
    if self.disengagedIcon then self.disengagedIcon:SetShown(flag and true or false) end
    self:UpdateStatusRowVisibility()
end

function UnitPortrait:SetActiveBuffs(flag)
    if self.activeBuffsIcon then self.activeBuffsIcon:SetShown(flag and true or false) end
    self:UpdateStatusRowVisibility()
end

function UnitPortrait:SetActiveDebuffs(flag)
    if self.activeDebuffsIcon then self.activeDebuffsIcon:SetShown(flag and true or false) end
    self:UpdateStatusRowVisibility()
end

--- Start a continuous pulse glow on an aura icon
function UnitPortrait:StartAuraGlow(iconFrame, timerKey)
    if not iconFrame then return end
    
    -- Stop any existing glow on this icon
    if timerKey == "buffs" then
        if self._buffsGlowTimer then
            self._buffsGlowTimer:Cancel()
            self._buffsGlowTimer = nil
        end
    elseif timerKey == "debuffs" then
        if self._debuffsGlowTimer then
            self._debuffsGlowTimer:Cancel()
            self._debuffsGlowTimer = nil
        end
    end
    
    local function doPulse()
        if not iconFrame or not iconFrame:IsShown() then return end
        iconFrame:SetAlpha(0.6)
        UIFrameFadeIn(iconFrame, 0.5, 0.6, 1)
        C_Timer.After(0.5, function()
            if not iconFrame or not iconFrame:IsShown() then return end
            iconFrame:SetAlpha(1)
            UIFrameFadeOut(iconFrame, 0.5, 1, 0.6)
        end)
    end
    
    -- Do initial pulse
    doPulse()
    
    -- Set up repeating timer every 1 second
    local timer = C_Timer.NewTicker(1, doPulse)
    
    if timerKey == "buffs" then
        self._buffsGlowTimer = timer
    elseif timerKey == "debuffs" then
        self._debuffsGlowTimer = timer
    end
end

--- Stop the continuous glow on an aura icon
function UnitPortrait:StopAuraGlow(timerKey)
    if timerKey == "buffs" then
        if self._buffsGlowTimer then
            self._buffsGlowTimer:Cancel()
            self._buffsGlowTimer = nil
        end
        if self.activeBuffsIcon then
            self.activeBuffsIcon:SetAlpha(1)
        end
    elseif timerKey == "debuffs" then
        if self._debuffsGlowTimer then
            self._debuffsGlowTimer:Cancel()
            self._debuffsGlowTimer = nil
        end
        if self.activeDebuffsIcon then
            self.activeDebuffsIcon:SetAlpha(1)
        end
    end
end

function UnitPortrait:LayoutStatusIcons()
    if not self.statusRow then return end

    local icons = {}
    if self.healedIcon   and self.healedIcon:IsShown()   then table.insert(icons, self.healedIcon) end
    if self.threatIcon   and self.threatIcon:IsShown()   then table.insert(icons, self.threatIcon) end
    if self.attackedIcon and self.attackedIcon:IsShown() then table.insert(icons, self.attackedIcon) end
    if self.disengagedIcon and self.disengagedIcon:IsShown() then table.insert(icons, self.disengagedIcon) end

    local n = #icons
    if n == 0 then
        self.statusRow:Hide()
        return
    end

    self.statusRow:Show()

    local size = self._iconSize or 16
    local gap  = self._iconGap  or 4
    local total = n * size + (n - 1) * gap
    local startX = -total / 2 + size / 2

    for idx, btn in ipairs(icons) do
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", self.statusRow, "CENTER", startX + (idx - 1) * (size + gap), 0)
    end
end

function UnitPortrait:LayoutAuraIcons()
    if not self.auraIconsFrame then return end

    local icons = {}
    if self.activeBuffsIcon and self.activeBuffsIcon:IsShown() then table.insert(icons, self.activeBuffsIcon) end
    if self.activeDebuffsIcon and self.activeDebuffsIcon:IsShown() then table.insert(icons, self.activeDebuffsIcon) end

    local n = #icons
    if n == 0 then
        self.auraIconsFrame:Hide()
        return
    end

    self.auraIconsFrame:Show()

    -- Vertical stack: position top to bottom
    local gap = 2
    local auraIconSize = self._auraIconSize or 16
    local totalH = n * auraIconSize + (n - 1) * gap
    local startY = totalH / 2 - auraIconSize / 2

    for idx, btn in ipairs(icons) do
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", self.auraIconsFrame, "CENTER", 0, startY - (idx - 1) * (auraIconSize + gap))
    end
end

--- Check if unit has any active, non-hidden, beneficial auras
function UnitPortrait:HasActiveBuffs()
    if not self.unit or not self.unit.id then return false end
    
    local ev = RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local auras = ev._auraManager:All(self.unit.id)
    if not auras or #auras == 0 then return false end
    
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.isHelpful and not aura.def.hidden then
            return true
        end
    end
    return false
end

--- Check if unit has any active, non-hidden, harmful auras
function UnitPortrait:HasActiveDebuffs()
    if not self.unit or not self.unit.id then return false end
    
    local ev = RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    local auras = ev._auraManager:All(self.unit.id)
    if not auras or #auras == 0 then return false end
    
    for _, aura in ipairs(auras) do
        if aura.def and not aura.def.isHelpful and not aura.def.hidden then
            return true
        end
    end
    return false
end

--- Check if unit has any active, non-hidden beneficial auras from the local player
function UnitPortrait:HasLocalPlayerBuffs()
    if not self.unit or not self.unit.id then return false end
    
    local ev = RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    -- Get local player's unit ID
    local localPlayerUnitId = nil
    if ev.localPlayerKey then
        local localPlayerUnit = ev.units and ev.units[ev.localPlayerKey]
        localPlayerUnitId = localPlayerUnit and localPlayerUnit.id
    end
    
    if not localPlayerUnitId then return false end
    
    local auras = ev._auraManager:All(self.unit.id)
    if not auras or #auras == 0 then return false end
    
    for _, aura in ipairs(auras) do
        if aura.def and aura.def.isHelpful and not aura.def.hidden and aura.sourceId == localPlayerUnitId then
            return true
        end
    end
    return false
end

--- Check if unit has any active, non-hidden harmful auras from the local player
function UnitPortrait:HasLocalPlayerDebuffs()
    if not self.unit or not self.unit.id then return false end
    
    local ev = RPE.Core and RPE.Core.ActiveEvent
    if not (ev and ev._auraManager) then return false end
    
    -- Get local player's unit ID
    local localPlayerUnitId = nil
    if ev.localPlayerKey then
        local localPlayerUnit = ev.units and ev.units[ev.localPlayerKey]
        localPlayerUnitId = localPlayerUnit and localPlayerUnit.id
    end
    
    if not localPlayerUnitId then return false end
    
    local auras = ev._auraManager:All(self.unit.id)
    if not auras or #auras == 0 then return false end
    
    for _, aura in ipairs(auras) do
        if aura.def and not aura.def.isHelpful and not aura.def.hidden and aura.sourceId == localPlayerUnitId then
            return true
        end
    end
    return false
end

function UnitPortrait:Refresh()
    if not self.unit then return end

    -- Hidden overlay and masking
    local isMasked = self.unit.active and self.unit.hidden
    
    -- Determine if unit is an ally
    local ev = RPE.Core and RPE.Core.ActiveEvent
    local localPlayerKey = ev and ev.localPlayerKey
    local isAlly = localPlayerKey and self.unit.team and 
        ev.units[localPlayerKey] and 
        ev.units[localPlayerKey].team == self.unit.team

    -- Show hidden overlay for all hidden units (including allies)
    if self.hiddenOverlay then
        local showOverlay = self.unit.hidden
        self.hiddenOverlay:SetShown(showOverlay)
    end

    -- Inactive units: show translucent for leader only
    local isLeader = RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()
    if not self.unit.active and isLeader then
        -- Show translucent
        self.box:SetAlpha(0.4)
    else
        -- Normal or hidden
        self.box:SetAlpha(1)
    end

    -- Hide health bar for inactive units
    if self.hp then
        if self._noHealthBar then
            self.hp:Hide()
        else
            self.hp:SetShown(self.unit.active)
        end
    end

    -- Apply hidden portrait for masked units
    if isMasked then
        self.model:Hide()
        self.texture:SetTexture("Interface\\AddOns\\RPEngine\\UI\\Textures\\hidden.png")
        self.texture:SetDrawLayer("ARTWORK", 1)
        self.texture:Show()

        -- Hide raid marker and HP bar
        if self.raidIcon then self.raidIcon:Hide() end
        if self.hp then self.hp:Hide() end
        return
    end

    if not self.unit.isNPC then
        -- Player case (unchanged)
        local token = ResolveUnitTokenByFullName((self.unit.key or ""):lower())
        if token and UnitExists(token) then
            self.model:ClearModel()
            self.model:Hide()
            SetPortraitTexture(self.texture, token)
            self.texture:SetDrawLayer("ARTWORK", 1)
            self.texture:Show()
        else
            self.model:ClearModel()
            self.model:Hide()
            self.texture:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
            self.texture:SetDrawLayer("ARTWORK", 1)
            self.texture:Show()
        end
    else
        -- NPC case
        self.model:ClearModel()
        local fileId  = self.unit.fileDataId or self.unit.FileDataID
        local display = self.unit.modelDisplayId or self.unit.displayId or self.unit.ModelID

        if fileId then self.model:SetModel(fileId) end
        if display then self.model:SetDisplayInfo(display) end

        if fileId or display then
            self.model:SetCamDistanceScale(self.unit.cam or 1.0)
            self.model:SetRotation(self.unit.rot or 0)
            self.model:SetPosition(0, 0, self.unit.z or -0.35)
            self.model:Show()
            self.texture:Hide()
        else
            self.texture:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
            self.texture:Show()
            self.model:Hide()
        end
    end

    self:ApplyRaidMarker()
    
    -- Re-apply raid marker frame level after portrait rendering to ensure it's on top
    if self.raidIconFrame then
        self.raidIconFrame:SetFrameLevel(20)
    end
    
    self:ApplyFlyingIcon()
    
    -- Update disengaged icon based on unit's engagement state
    if self.unit and type(self.unit.IsDisengaged) == "function" then
        local isDisengaged = self.unit:IsDisengaged()
        RPE.Debug:Internal(("UnitPortrait:Refresh - %s turnsLastCombat=%d, IsDisengaged=%s"):format(
            self.unit.name or self.unit.key, 
            self.unit.turnsLastCombat or 999,
            tostring(isDisengaged)
        ))
        self:SetDisengaged(isDisengaged)
    else
        self:SetDisengaged(false)
    end
    
    -- Update active buff/debuff icons
    self:SetActiveBuffs(self:HasActiveBuffs())
    self:SetActiveDebuffs(self:HasActiveDebuffs())
    
    -- Pulse icons if they were cast by the local player
    if self:HasLocalPlayerBuffs() and self.activeBuffsIcon and self.activeBuffsIcon:IsShown() then
        self:StartAuraGlow(self.activeBuffsIcon, "buffs")
    else
        self:StopAuraGlow("buffs")
    end
    
    if self:HasLocalPlayerDebuffs() and self.activeDebuffsIcon and self.activeDebuffsIcon:IsShown() then
        self:StartAuraGlow(self.activeDebuffsIcon, "debuffs")
    else
        self:StopAuraGlow("debuffs")
    end
end

--- Greyscale the portrait image/model only (does NOT affect health, border, etc.)
---@param flag boolean
function UnitPortrait:SetDesaturated(flag)
    if self.texture and self.texture.SetDesaturated then
        self.texture:SetDesaturated(flag)
    end
    if self.texture and self.texture.SetVertexColor then
        if flag then
            self.texture:SetVertexColor(0.6, 0.6, 0.6)
        else
            self.texture:SetVertexColor(1, 1, 1)
        end
    end

    if self.model then
        if flag then
            self.model:SetAlpha(0.4)
        else
            self.model:SetAlpha(1.0)
        end
    end
end

return UnitPortrait
