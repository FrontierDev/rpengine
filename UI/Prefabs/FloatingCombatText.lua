-- RPE_UI/Prefabs/FloatingCombatText.lua
-- Lightweight, pooled floating combat text widget.
-- Usage:
--   local FCT = RPE_UI.Prefabs.FloatingCombatText
--   local fct = FCT:New("RPE_FCT_Player", {
--       parent            = WorldFrame,   -- or any element/frame
--       setAllPoints      = true,
--       direction         = "UP",         -- "UP" | "DOWN" (default for entries)
--       onlyWhenUIHidden  = true,         -- if parent==WorldFrame: hide when UI is shown
--   })
--   fct:AddNumber(124, "damage", { isCrit = true })
--   fct:AddText("+25 XP", { variant = "xp", icon = 458724 })

RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = assert(RPE_UI.Elements.FrameElement, "FrameElement required")
local Colors       = assert(RPE_UI.Colors, "RPE_UI.Colors required")

---@class FloatingCombatText: FrameElement
---@field frame Frame
---@field maxActive integer
---@field duration number
---@field fadeStart number
---@field scrollDistance number
---@field direction "UP"|"DOWN"
---@field jitterX number
---@field jitterY number
---@field spawnRadiusMin number
---@field spawnRadiusMax number
---@field angleSpreadDeg number
---@field onlyWhenUIHidden boolean
---@field _pool table[]
---@field _active table[]
---@field _originX number
---@field _originY number
---@field _persistScaleProxy Frame|nil
local FloatingCombatText = setmetatable({}, { __index = FrameElement })
FloatingCombatText.__index = FloatingCombatText
RPE_UI.Prefabs.FloatingCombatText = FloatingCombatText
FloatingCombatText.Name = "FloatingCombatText"

local THEME = {
    damage      = { 1.00, 0.25, 0.20, 1.0 },
    damageDealt = { 1.00, 1.00, 1.00, 1.00 },
    heal        = { 0.25, 1.00, 0.35, 1.0 },
    xp          = { 0.65, 0.50, 1.00, 1.0 },
}

local function clamp01(x) return (x < 0 and 0) or (x > 1 and 1) or x end

-- Ease-out quad
local function easeOutQuad(t) t = clamp01(t); return 1 - (1 - t) * (1 - t) end

-- Helper: format numbers for AddNumber (centralized formatting)
local function formatNumberText(kind, amount, opts)
    opts = opts or {}
    if kind == "damage" then
        opts.variant = opts.variant or "damage"
        return string.format("-%s", tostring(amount)), opts
    elseif kind == "heal" then
        opts.variant = opts.variant or "heal"
        return string.format("+%s", tostring(amount)), opts
    else
        opts.variant = opts.variant or kind
        return tostring(amount), opts
    end
end

---@param name string
---@param opts table|nil
---@return FloatingCombatText
function FloatingCombatText:New(name, opts)
    opts = opts or {}

    local parentFrame = (opts.parent and opts.parent.frame) or opts.parent or UIParent
    local f = CreateFrame("Frame", name, parentFrame)
    if opts.setAllPoints then
        f:SetAllPoints(parentFrame)
    else
        f:SetSize(opts.width or 160, opts.height or 120)
        f:SetPoint(opts.point or "CENTER", opts.relativeTo or parentFrame, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)
    end
    f:EnableMouse(false)
    f:SetClampedToScreen(true)

    ---@type FloatingCombatText
    local selfObj = FrameElement.New(self, "FloatingCombatText", f, opts.parent and opts.parent.frame and opts.parent or nil)

    -- Config
    selfObj.maxActive      = math.max(1, tonumber(opts.maxActive or 24))
    selfObj.duration       = tonumber(opts.duration or 2.10)           -- seconds
    selfObj.fadeStart      = clamp01(opts.fadeStart or 0.55)
    selfObj.scrollDistance = tonumber(opts.scrollDistance or 72)       -- pixels
    selfObj.direction      = (opts.direction == "DOWN") and "DOWN" or "UP"
    selfObj.jitterX        = tonumber(opts.jitterX or 8)
    selfObj.jitterY        = tonumber(opts.jitterY or selfObj.jitterX)
    selfObj.spawnRadiusMin = tonumber(opts.spawnRadiusMin or 32)        -- px
    selfObj.spawnRadiusMax = tonumber(opts.spawnRadiusMax or 128)       -- px
    selfObj.angleSpreadDeg = tonumber(opts.angleSpreadDeg or 60)       -- degrees
    selfObj.baseScale      = tonumber(opts.baseScale or 1.5)
    selfObj.popScale       = tonumber(opts.popScale or 1.0)
    selfObj.critScale      = tonumber(opts.critScale or 1.0)
    selfObj.fontTemplate   = opts.fontTemplate or "GameFontHighlightLarge"
    selfObj.onlyWhenUIHidden = (opts.onlyWhenUIHidden == true)

    -- Pools
    selfObj._pool   = selfObj._pool or {}
    selfObj._active = selfObj._active or {}
    selfObj._originX = tonumber(opts.originX or 0)
    selfObj._originY = tonumber(opts.originY or 0)

    -- WorldFrame parenting extras: scale sync + optional hide when UI shown
    if parentFrame == WorldFrame then
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale()
            local s = (UIParent and UIParent.GetScale and UIParent:GetScale()) or 1
            f:SetScale(s)
        end

        local function UpdateMouseForUIVisibility()
            if not selfObj.onlyWhenUIHidden then return end
            local uiShown = (UIParent and UIParent.IsShown and UIParent:IsShown()) or false
            f:EnableMouse(not uiShown)
            if uiShown then selfObj:Hide() else selfObj:Show() end
        end

        -- Initial apply
        SyncScale()
        UpdateMouseForUIVisibility()

        -- React to UIParent show/hide
        if UIParent and UIParent.HookScript then
            UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
            UIParent:HookScript("OnHide", function() SyncScale(); UpdateMouseForUIVisibility() end)
        end

        -- Persist scale on resolution/scale changes
        selfObj._persistScaleProxy = selfObj._persistScaleProxy or CreateFrame("Frame")
        selfObj._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        selfObj._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        selfObj._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    f:SetScript("OnUpdate", function(_, dt) selfObj:_OnUpdate(dt or 0.016) end)
    return selfObj
end

-- Acquire/release pooled entry
local function acquire(self)
    local e = table.remove(self._pool)
    if e then
        e.frame:Show()
        e.fs:Show()
        if e.icon then e.icon:Show() end
        return e
    end

    local f = CreateFrame("Frame", nil, self.frame)
    f:SetSize(2, 2)
    f:EnableMouse(false)

    local fs = f:CreateFontString(nil, "OVERLAY", self.fontTemplate or "GameFontNormal")
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    fs:SetText("")
    do
        local r,g,b,a = Colors.Get("text")
        fs:SetTextColor(r, g, b, a)
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.75)
    end

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16,16)
    icon:Hide()

    return {
        frame = f,
        fs    = fs,
        icon  = icon,
        t     = 0,
        dur   = 1.0,
        startX = 0,
        startY = 0,
        driftX = 0,
        height = 60,
        fadeStart = 0.6,
        isCrit = false,
        baseScale = 1.0,
        popPeak   = 1.0,
        dirMult   = 1.0,
    }
end

local function release(self, e)
    if not e or not e.frame then return end
    e.frame:Hide()
    e.fs:SetText("")
    e.icon:SetTexture(nil)
    e.icon:Hide()
    table.insert(self._pool, e)
end

-- Internal: update all active entries
function FloatingCombatText:_OnUpdate(dt)
    if not self._active or #self._active == 0 then return end
    local i = 1
    while i <= #self._active do
        local e = self._active[i]
        e.t = e.t + dt
        local p = e.t / e.dur

        if p >= 1 then
            release(self, e)
            table.remove(self._active, i)
        else
            local yoff = e.height * easeOutQuad(p) * e.dirMult
            local xoff = e.driftX
            e.frame:ClearAllPoints()
            e.frame:SetPoint("CENTER", self.frame, "CENTER", e.startX + xoff, e.startY + yoff)

            -- Fade late
            if p >= e.fadeStart then
                local a = 1 - ((p - e.fadeStart) / (1 - e.fadeStart))
                e.frame:SetAlpha(a)
            else
                e.frame:SetAlpha(1)
            end

            -- Constant scale (no pop) so entry only translates smoothly
            local scale = e.baseScale or 1
            e.frame:SetScale(scale)

            i = i + 1
        end
    end
end



--- Add a floating text entry.
--- @param text string|number
--- @param opts table|nil  @fields:
---     x,y (numbers): spawn offset relative to widget center (default originX/Y)
---     color {r,g,b,a}: explicit text color
---     variant "damage"|"heal"|"xp"|...: quick themed colors
---     isCrit boolean: larger pop
---     icon number|string: texture fileID/path for a small icon to the left
---     duration number: override animation duration
---     distance number: override scroll distance
---     direction "UP"|"DOWN": override per-entry
---     jitterX/jitterY number: override horizontal/vertical jitter
---     spawnRadiusMin/spawnRadiusMax/angleSpreadDeg: per-entry spawn scatter overrides
function FloatingCombatText:AddText(text, opts)
    opts = opts or {}
    local e = acquire(self)

    -- Prepare text + color
    local fs = e.fs
    fs:SetText(tostring(text or ""))

    do
        local r,g,b,a
        if opts.color then
            r,g,b,a = opts.color[1], opts.color[2], opts.color[3], opts.color[4] or 1
        elseif opts.variant and THEME[opts.variant] then
            local c = THEME[opts.variant]; r,g,b,a = c[1],c[2],c[3],c[4]
        else
            r,g,b,a = Colors.Get("text")
        end
        fs:SetTextColor(r, g, b, a or 1)
        fs:SetShadowOffset(1, -1); fs:SetShadowColor(0, 0, 0, 0.8)
    end

    -- Optional icon
    local iconTex = e.icon
    local hasIcon = false
    if opts.icon then
        iconTex:SetTexture(opts.icon)
        iconTex:Show()
        hasIcon = true
    else
        iconTex:Hide()
    end

    -- Lay out fs + icon (icon to left, text centered overall)
    fs:ClearAllPoints()
    iconTex:ClearAllPoints()
    if hasIcon then
        iconTex:SetPoint("RIGHT", e.frame, "CENTER", -8, 0)
        fs:SetPoint("LEFT",  e.frame, "CENTER", -4, 0)
    else
        fs:SetPoint("CENTER", e.frame, "CENTER", 0, 0)
    end

    -- Entry params + randomized start around anchor, biased toward direction
    local dir = (opts.direction == "DOWN") and "DOWN"
            or (opts.direction == "UP" and "UP" or self.direction)
    local jitterX = tonumber(opts.jitterX or self.jitterX)
    local jitterY = tonumber(opts.jitterY or self.jitterY)

    e.dirMult    = (dir == "UP") and 1 or -1
    e.t          = 0
    e.dur        = tonumber(opts.duration or self.duration)
    e.fadeStart  = clamp01(opts.fadeStart or self.fadeStart)

    -- Base anchor (allows explicit x/y override)
    local baseX = tonumber((opts.x ~= nil and opts.x) or self._originX)
    local baseY = tonumber((opts.y ~= nil and opts.y) or self._originY)

    -- Polar spawn around the anchor, biased toward travel direction
    local baseAngle = (dir == "UP") and (math.pi * 0.5) or (-math.pi * 0.5)
    local spreadRad = math.rad(tonumber(opts.angleSpreadDeg or self.angleSpreadDeg) or 60)
    local halfSpread = spreadRad * 0.5
    local angle = baseAngle + ((math.random() * 2 - 1) * halfSpread)

    local rMin = tonumber(opts.spawnRadiusMin or self.spawnRadiusMin) or 6
    local rMax = tonumber(opts.spawnRadiusMax or self.spawnRadiusMax) or 16
    if rMax < rMin then rMax = rMin end
    local r = rMin + (math.random() * (rMax - rMin))

    local dx = math.cos(angle) * r
    local dy = math.sin(angle) * r

    -- Final start (with optional extra jitter)
    e.startX = baseX + dx + (jitterX > 0 and math.random(-jitterX, jitterX) or 0)
    e.startY = baseY + dy + (jitterY > 0 and math.random(-jitterY, jitterY) or 0)

    e.driftX     = 0
    e.height     = tonumber(opts.distance or self.scrollDistance)
    e.baseScale  = (opts.scale and tonumber(opts.scale) or self.baseScale) or 1
    e.isCrit     = (opts.isCrit == true)
    e.popPeak    = 1

    e.frame:SetAlpha(1)
    e.frame:SetScale(1)
    e.frame:ClearAllPoints()
    e.frame:SetPoint("CENTER", self.frame, "CENTER", e.startX, e.startY)
    e.frame:Show()

    -- Cull if too many
    if #self._active >= self.maxActive then
        local oldest = table.remove(self._active, 1)
        release(self, oldest)
    end

    table.insert(self._active, e)
end



function FloatingCombatText:AddNumber(amount, kind, opts)
    local txt, finalOpts = formatNumberText(kind, amount, opts)
    self:AddText(txt, finalOpts)
end

function FloatingCombatText:Clear()
    for i = #self._active, 1, -1 do
        release(self, self._active[i])
        table.remove(self._active, i)
    end
end

function FloatingCombatText:Destroy()
    self:Clear()
    if self._persistScaleProxy then
        self._persistScaleProxy:UnregisterAllEvents()
        self._persistScaleProxy:SetScript("OnEvent", nil)
        self._persistScaleProxy = nil
    end
    for i = #self._pool, 1, -1 do
        local e = self._pool[i]
        if e and e.frame then
            e.frame:Hide()
            e.frame:SetParent(nil)
        end
        self._pool[i] = nil
    end
    self._pool = {}
    FrameElement.Destroy(self)
end

return FloatingCombatText
