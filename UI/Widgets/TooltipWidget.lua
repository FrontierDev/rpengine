-- RPE_UI/Windows/TooltipWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C            = RPE_UI.Colors

---@class TooltipWidget : FrameElement
---@field frame Frame
---@field lines FontString[]
---@field anchorFrame Frame|nil
---@field onlyWhenUIHidden boolean
---@field maxWidth number
local TooltipWidget = setmetatable({}, { __index = FrameElement })
TooltipWidget.__index = TooltipWidget
RPE_UI.Windows.TooltipWidget = TooltipWidget
TooltipWidget.Name = "TooltipWidget"

-- ==== utils ====

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

local function GetColor(key, fallback)
    if C and C.Get then
        local r,g,b,a = C.Get(key)
        return r or fallback[1], g or fallback[2], b or fallback[3], (a ~= nil and a) or fallback[4]
    end
    return fallback[1], fallback[2], fallback[3], fallback[4]
end

local function ApplyText(fs, variant)
    if C and C.ApplyText then
        C.ApplyText(fs, variant)
    end
end

-- ==== core ====

--- Create a WorldFrame-parented tooltip that survives Alt+Z
---@param opts { onlyWhenUIHidden?:boolean, maxWidth?:number, padX?:number, padY?:number, scaleWithUI?:boolean }
function TooltipWidget.New(opts)
    opts = opts or {}
    local parent = WorldFrame -- ensure visibility when UIParent hides
    local f = CreateFrame("Frame", "RPE_TooltipWidget_"..math.random(1e8), parent, "BackdropTemplate")
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:EnableMouse(false)  -- tooltips shouldn't block clicks

    -- Scale to match UIParent so sizes look right (WorldFrame is scale 1)
    f:SetIgnoreParentScale(true)
    local function SyncScale()
        local s = (UIParent and UIParent:GetScale()) or 1
        f:SetScale(s)
    end
    SyncScale()

    -- Auto-hide when UI is visible (so GameTooltip can be used), default true
    local onlyWhenUIHidden = (opts.onlyWhenUIHidden ~= false)

    local function UpdateVisibilityPolicy()
        if onlyWhenUIHidden and UIParent and UIParent:IsShown() then
            f:Hide()
        end
    end
    UIParent:HookScript("OnShow", UpdateVisibilityPolicy)
    UIParent:HookScript("OnHide", function() SyncScale() end)

    -- Rescale on system changes
    local scaler = CreateFrame("Frame", nil, f)
    scaler:RegisterEvent("UI_SCALE_CHANGED")
    scaler:RegisterEvent("DISPLAY_SIZE_CHANGED")
    scaler:SetScript("OnEvent", SyncScale)

    -- Styling
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    do
        local r,g,b,a = GetColor("background", {0.06,0.06,0.06,0.95})
        bg:SetColorTexture(r, g, b, clamp(a + 0.05, 0, 1))
    end

    -- thin border
    local border = CreateFrame("Frame", nil, f, "BackdropTemplate")
    border:SetAllPoints()
    if C and C.ApplyBorder then
        C.ApplyBorder(border)
    else
        local tl = f:CreateTexture(nil, "BORDER"); tl:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1);  tl:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1); tl:SetHeight(1); tl:SetColorTexture(0,0,0,0.9)
        local bl = f:CreateTexture(nil, "BORDER"); bl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -1, -1); bl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1); bl:SetHeight(1); bl:SetColorTexture(0,0,0,0.9)
        local ll = f:CreateTexture(nil, "BORDER"); ll:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1);  ll:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -1, -1); ll:SetWidth(1);  ll:SetColorTexture(0,0,0,0.9)
        local rl = f:CreateTexture(nil, "BORDER"); rl:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1);  rl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1); rl:SetWidth(1);  rl:SetColorTexture(0,0,0,0.9)
    end

    -- Create without a FrameElement parent, then attach to WorldFrame directly.
    local o = FrameElement.New(TooltipWidget, "TooltipWidget", f)  -- no parent
    f:SetParent(WorldFrame)  -- survive Alt+Z    o.onlyWhenUIHidden = onlyWhenUIHidden
    o.maxWidth = tonumber(opts.maxWidth) or 200
    o.padX = tonumber(opts.padX) or 10
    o.padY = tonumber(opts.padY) or 10
    o.lines = {}
    o.anchorFrame = nil
    o._cursorFollow = false

    f:Hide()
    return o
end

-- === Layout helpers ===

function TooltipWidget:ClearLines()
    for _, entry in ipairs(self.lines) do
        if type(entry) == "table" and entry[1] and entry[2] then
            for _, fs in ipairs(entry) do
                fs:Hide()
                fs:SetText("")
            end
        elseif entry.Hide then
            entry:Hide()
            if entry.SetText then entry:SetText("") end
        end
    end
    wipe(self.lines)
end



function TooltipWidget:_AcquireLine(fontTemplate)
    local fs = self.frame:CreateFontString(nil, "OVERLAY", fontTemplate or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetNonSpaceWrap(true)
    fs:SetWordWrap(true)
    fs:SetSpacing(2)
    table.insert(self.lines, fs)
    return fs
end

--- Set a title (first line, larger)
function TooltipWidget:SetText(text, r, g, b)
    self:ClearLines()
    local fs = self:_AcquireLine("GameFontHighlight")
    ApplyText(fs, "text")
    fs:SetTextColor(r or 1, g or 0.82, b or 0)
    fs:SetText(text or "")
end

-- Normalize color arg into r,g,b,a
local function _normColor(c, dr, dg, db, da)
    dr, dg, db, da = dr or 1, dg or 1, db or 1, da or 1
    if type(c) == "number" then
        -- grayscale shortcut: 1 -> white, 0.5 -> gray, etc.
        return c, c, c, 1
    elseif type(c) == "table" then
        local r = c.r or c[1] or dr
        local g = c.g or c[2] or dg
        local b = c.b or c[3] or db
        local a = c.a or c[4] or da
        return r, g, b, a
    elseif type(c) == "string" then
        -- (optional) hex support: "#RRGGBB" or "RRGGBBAA"
        local hex = c:gsub("^#", "")
        if #hex == 6 or #hex == 8 then
            local r = tonumber(hex:sub(1,2),16)/255
            local g = tonumber(hex:sub(3,4),16)/255
            local b = tonumber(hex:sub(5,6),16)/255
            local a = (#hex == 8) and (tonumber(hex:sub(7,8),16)/255) or 1
            return r, g, b, a
        end
    end
    return dr, dg, db, da
end


--- Add a single left-aligned line
function TooltipWidget:AddLine(text, col)
    local r, g, b, a = _normColor(col, 1, 1, 1, 1)
    local row = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.padX, -self.padY - (#self.lines * 14))
    row:SetJustifyH("LEFT"); row:SetText(text or "")
    row:SetTextColor(r, g, b, a)
    table.insert(self.lines, row)
end

function TooltipWidget:AddDoubleLine(left, right, ...)
    local args = {...}
    local lr, lg, lb, la, rr, rg, rb, ra

    if #args >= 6 then
        -- called as (l,r, lr,lg,lb, rr,rg,rb)
        lr,lg,lb,la = args[1] or 1, args[2] or 1, args[3] or 1, 1
        rr,rg,rb,ra = args[4] or 1, args[5] or 1, args[6] or 1, 1
    elseif #args >= 3 then
        -- (l,r, lr,lg,lb)
        lr,lg,lb,la = args[1] or 1, args[2] or 1, args[3] or 1, 1
        rr,rg,rb,ra = lr,lg,lb,la
    else
        -- (l,r, lcol, rcol) or nil
        lr,lg,lb,la = _normColor(args[1], 1,1,1,1)
        rr,rg,rb,ra = _normColor(args[2], 1,1,1,1)
    end

    local idx = #self.lines + 1

    local L = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    L:SetJustifyH("LEFT")
    L:SetText(left or "")
    L:SetTextColor(lr, lg, lb, la)

    local R = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    R:SetJustifyH("RIGHT")
    R:SetText(right or "")
    R:SetTextColor(rr, rg, rb, ra)

    table.insert(self.lines, {L, R})
end


--- Optional spacer
function TooltipWidget:AddSpacer(height)
    local s = self.frame:CreateTexture(nil, "ARTWORK")
    s:SetHeight(height or 6)
    s:SetColorTexture(0,0,0,0)
    table.insert(self.lines, s)
end

-- Compute size and pack lines
function TooltipWidget:_Pack()
    local y = -self.padY
    local maxW = self.maxWidth

    for _, obj in ipairs(self.lines) do
        if type(obj) == "table" and obj[1] and obj[2] then
            local L,R = obj[1], obj[2]
            L:ClearAllPoints()
            R:ClearAllPoints()
            L:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.padX, y)
            R:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -self.padX, y)
            local h = math.max(L:GetStringHeight(), R:GetStringHeight())
            y = y - h - 2
            L:Show(); R:Show()
        else
            local fs = obj
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.padX, y)
            fs:SetWidth(maxW - self.padX*2)
            local h = fs.GetStringHeight and fs:GetStringHeight() or 14
            y = y - h - 2
            fs:Show()
        end
    end

    local totalH = -y + self.padY
    self.frame:SetSize(maxW, totalH)
end

-- === Positioning & show/hide ===

--- Show near the mouse cursor (follows cursor while shown).
function TooltipWidget:ShowAtCursor(offsetX, offsetY)
    self._cursorFollow = true
    offsetX = offsetX or 18
    offsetY = offsetY or -18

    self:_Pack()
    self.frame:Show()

    local function OnUpdate(_)
        local cx, cy = GetCursorPosition()
        local scale = UIParent and UIParent:GetScale() or 1
        cx, cy = cx / scale, cy / scale
        -- Keep inside screen horizontally
        local w = self.frame:GetWidth() or 200
        local h = self.frame:GetHeight() or 60
        local sw = UIParent:GetWidth()
        local sh = UIParent:GetHeight()

        local x = clamp(cx + offsetX, 4, sw - w - 4)
        local y = clamp(cy + offsetY, h + 4, sh - 4)

        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOMLEFT", WorldFrame, "BOTTOMLEFT", x, y)
    end
    self.frame:SetScript("OnUpdate", OnUpdate)

    -- Policy: optionally hide when UI visible
    if self.onlyWhenUIHidden and UIParent:IsShown() then
        self.frame:Hide()
    end
end

--- Show anchored to a frame (like GameTooltip:SetOwner + SetPoint)
function TooltipWidget:ShowForFrame(owner, point, relPoint, x, y)
    self._cursorFollow = false
    self.anchorFrame = owner
    self:_Pack()

    self.frame:ClearAllPoints()
    self.frame:SetPoint(point or "TOPLEFT", owner, relPoint or "BOTTOMLEFT", x or 0, y or -6)
    self.frame:Show()

    -- Keep visible even if owner is under UIParent; we’re parented to WorldFrame
    if self.onlyWhenUIHidden and UIParent:IsShown() then
        self.frame:Hide()
    end
end

--- Absolute screen point (UI coordinates)
function TooltipWidget:ShowAtPoint(point, relative, relPoint, x, y)
    self._cursorFollow = false
    self:_Pack()
    self.frame:ClearAllPoints()
    self.frame:SetPoint(point or "CENTER", relative or WorldFrame, relPoint or "CENTER", x or 0, y or 0)
    self.frame:Show()

    if self.onlyWhenUIHidden and UIParent:IsShown() then
        self.frame:Hide()
    end
end

function TooltipWidget:Hide()
    self._cursorFollow = false
    self.frame:SetScript("OnUpdate", nil)
    self.frame:Hide()
end

-- Convenience to wire hover behavior to any button/frame
-- usage:
--   tooltip:BindHover(myButton, function(t)
--       t:SetText("Name")
--       t:AddLine("Body text...", 0.9,0.9,1)
--   end)
function TooltipWidget:BindHover(frame, buildLinesFn, anchorPoint, relPoint, ox, oy)
    if not frame then return end
    frame:EnableMouse(true)
    frame:HookScript("OnEnter", function()
        if buildLinesFn then
            self:ClearLines()
            buildLinesFn(self)
        end
        self:ShowForFrame(frame, anchorPoint or "TOPLEFT", relPoint or "BOTTOMLEFT", ox or 0, oy or -6)
    end)
    frame:HookScript("OnLeave", function() self:Hide() end)
end

return TooltipWidget
