-- RPE_UI/Prefabs/PowerBalance.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C            = RPE_UI.Colors

---@class PowerBalance: FrameElement
---@field frame Frame
---@field bg Texture
---@field segments table[] @ { tex=Texture, targetW=number, currentW=number }
---@field dividers Texture[]
---@field values number[]
---@field total number
local PowerBalance = setmetatable({}, { __index = FrameElement })
PowerBalance.__index = PowerBalance
RPE_UI.Prefabs.PowerBalance = PowerBalance

function PowerBalance:New(name, opts)
    opts = opts or {}
    local parentFrame = opts.parent and opts.parent.frame or UIParent

    local f = CreateFrame("Frame", name, parentFrame)
    f:SetSize(opts.width or 300, opts.height or 20)
    f:SetPoint(opts.point or "CENTER", opts.relativeTo or parentFrame, opts.relativePoint or "CENTER", opts.x or 0, opts.y or 0)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    C.ApplyBackground(bg)

    ---@type PowerBalance
    local o = FrameElement.New(self, "PowerBalance", f, opts.parent)
    o.bg = bg
    o.segments = {}
    o.dividers = {}
    o.values = {}
    o.total = 0
    o._animSpeed = 8

    f:SetScript("OnUpdate", function(_, elapsed)
        o:UpdateAnimation(elapsed)
    end)

    return o
end

--- Calculate team values from the current event's units.
--- Sums up the HP of all members by their team number.
---@param event table|nil  -- defaults to RPE.Core.ActiveEvent
---@return number[] values, string[] styles
function PowerBalance:Calculate(event)
    event = event or (RPE and RPE.Core and RPE.Core.ActiveEvent)
    if not event or not event.units then return {}, {} end

    local totals = {}
    for _, u in pairs(event.units) do
        if u.team and u.hp then
            totals[u.team] = (totals[u.team] or 0) + (u.hp or 0)
        end
    end

    -- Sort by team index for consistency
    local values, styles = {}, {}
    local maxTeam = 0
    for t in pairs(totals) do if t > maxTeam then maxTeam = t end end
    for t = 1, maxTeam do
        values[#values+1] = totals[t] or 0
        styles[#styles+1] = "team" .. tostring(t)
    end

    self:SetValues(values, styles)
end


--- Set the segment values and optional styles
function PowerBalance:SetValues(values, styles)
    self.values = values or {}
    self.total = 0
    for _, v in ipairs(self.values) do
        self.total = self.total + v
    end
    if self.total <= 0 then return end

    local w = self.frame:GetWidth()
    local h = self.frame:GetHeight()

    -- Ensure segments exist
    for i, v in ipairs(self.values) do
        local pct = v / self.total
        local segW = w * pct

        local seg = self.segments[i]
        if not seg then
            local tex = self.frame:CreateTexture(nil, "ARTWORK")
            tex:SetHeight(h)
            seg = { tex = tex, targetW = segW, currentW = segW }
            self.segments[i] = seg
        end

        local style = (styles and styles[i]) or "progress_default"
        local r,g,b,a = C.Get(style)
        seg.tex:SetColorTexture(r,g,b,a or 1)

        seg.targetW = segW
        seg.tex:Show()
    end

    -- Hide unused old segments
    for j = #self.values+1, #self.segments do
        self.segments[j].tex:Hide()
    end

    -- Ensure correct number of dividers
    for i = 1, #self.values-1 do
        if not self.dividers[i] then
            local div = self.frame:CreateTexture(nil, "OVERLAY")
            div:SetWidth(1)
            div:SetHeight(h)
            C.ApplyDivider(div)
            self.dividers[i] = div
        end
        self.dividers[i]:Show()
    end
    for j = #self.values, #self.dividers do
        if self.dividers[j] then self.dividers[j]:Hide() end
    end
end

--- Smooth animation update (segments + dividers)
function PowerBalance:UpdateAnimation(elapsed)
    if not self.segments then return end
    local xOffset = 0

    for i, seg in ipairs(self.segments) do
        if seg.tex:IsShown() then
            local diff = seg.targetW - (seg.currentW or 0)
            if math.abs(diff) > 0.5 then
                seg.currentW = (seg.currentW or 0) + diff * math.min(1, elapsed * self._animSpeed)
            else
                seg.currentW = seg.targetW
            end

            seg.tex:ClearAllPoints()
            seg.tex:SetPoint("LEFT", self.frame, "LEFT", xOffset, 0)
            seg.tex:SetSize(seg.currentW, self.frame:GetHeight())

            xOffset = xOffset + seg.currentW

            -- Divider after this segment (except last one)
            if self.dividers[i] then
                self.dividers[i]:ClearAllPoints()
                self.dividers[i]:SetPoint("LEFT", self.frame, "LEFT", xOffset - 1, 0)
                self.dividers[i]:SetHeight(self.frame:GetHeight())
            end
        end
    end
end

return PowerBalance
