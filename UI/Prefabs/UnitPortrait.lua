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
---@field raidIcon Texture     -- raid marker icon (bottom-left of box)
---@field statusRow Frame      -- container under HP bar
---@field hiddenOverlay Texture -- semi-transparent overlay for hidden units
---@field healedIcon Button
---@field threatIcon Button
---@field attackedIcon Button
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

    -- Precompute icon row size so we reserve full height
    local iconSize = math.max(12, math.floor(size * 0.35))
    local totalH   = size + hpH + spacing + iconSize + spacing

    -- Total height includes HP + status icons row
    local f = CreateFrame("Button", name, parentFrame)
    f:SetSize(size, totalH)

    -- Inner "box" region reserved for the portrait/model
    local box = CreateFrame("Frame", nil, f)
    box:SetSize(size, size)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    -- Overlay for hidden units (semi-transparent grey)
    local hiddenOverlay = box:CreateTexture(nil, "OVERLAY")
    hiddenOverlay:SetAllPoints()
    hiddenOverlay:SetTexture("Interface\\AddOns\\RPEngine\\UI\\Textures\\hidden_overlay.png")
    hiddenOverlay:SetTexCoord(0.07, 0.93, 0.07, 0.93)
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

    -- === Status icons row (under the health bar) ===
    local statusRow = CreateFrame("Frame", nil, f)
    statusRow:SetPoint("TOPLEFT",  hp, "BOTTOMLEFT", 0, -spacing)
    statusRow:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -spacing)
    statusRow:SetHeight(iconSize)

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
    o.raidIcon = raidIcon
    o._hpCur   = nil
    o._hpMax   = nil

    
    o.statusRow    = statusRow
    o.healedIcon   = healedIcon
    o.threatIcon   = threatIcon
    o.attackedIcon = attackedIcon
    o._iconSize = iconSize
    o._iconGap  = 4
    o.hiddenOverlay = hiddenOverlay
    o._noHealthBar = opts.noHealthBar or false

    local portrait = o 

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
            canControl = (localPlayerUnitId and unit.summonedBy and localPlayerUnitId == unit.summonedBy)
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

    -- Hidden by default until values are set
    o.hp:Hide()
    o.statusRow:Hide()
    o.healedIcon:Hide()
    o.threatIcon:Hide()
    o.attackedIcon:Hide()

    return o
end

function UnitPortrait:SetUnit(u)
    self.unit = u
    self:Refresh()
    self:ApplyTeamColor()
    self:ApplyRaidMarker()
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
            end
        end)
    else
        self.hpFill:SetWidth(w * pct)
    end

    if cur ~= 0 then
        self.hp:Show()
    else
        self.hp:Hide()
    end
end

function UnitPortrait:UpdateStatusRowVisibility()
    if not self.statusRow then return end
    local anyShown = (self.healedIcon and self.healedIcon:IsShown())
        or (self.threatIcon and self.threatIcon:IsShown())
        or (self.attackedIcon and self.attackedIcon:IsShown())
    if anyShown then
        self.statusRow:Show()
        self:LayoutStatusIcons()
    else
        self.statusRow:Hide()
    end
end

function UnitPortrait:SetStatusIcons(healed, threat, attacked)
    if self.healedIcon   then self.healedIcon:SetShown(healed and true or false) end
    if self.threatIcon   then self.threatIcon:SetShown(threat and true or false) end
    if self.attackedIcon then self.attackedIcon:SetShown(attacked and true or false) end
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

function UnitPortrait:LayoutStatusIcons()
    if not self.statusRow then return end

    local icons = {}
    if self.healedIcon   and self.healedIcon:IsShown()   then table.insert(icons, self.healedIcon) end
    if self.threatIcon   and self.threatIcon:IsShown()   then table.insert(icons, self.threatIcon) end
    if self.attackedIcon and self.attackedIcon:IsShown() then table.insert(icons, self.attackedIcon) end

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

    -- Show hidden overlay only for hidden ENEMIES (not allies)
    if self.hiddenOverlay then
        local showOverlay = self.unit.hidden and not isAlly
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

    -- Apply question mark portrait for masked units
    if isMasked then
        self.model:Hide()
        self.texture:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
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
