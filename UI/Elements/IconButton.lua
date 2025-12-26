-- RPE_UI/Elements/IconButton.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement
local C = RPE_UI.Colors

---@class IconButton: FrameElement
---@field frame Button
---@field bg Texture|nil
---@field topBorder Texture|nil
---@field bottomBorder Texture|nil
---@field icon Texture
---@field onClick fun(self:IconButton, button?:string)|nil
---@field _locked boolean
---@field _baseR number
---@field _baseG number
---@field _baseB number
---@field _baseA number
---@field _hoverR number
---@field _hoverG number
---@field _hoverB number
---@field _hoverA number
local IconButton = setmetatable({}, { __index = FrameElement })
IconButton.__index = IconButton
RPE_UI.Elements.IconButton = IconButton

function IconButton:New(name, opts)
    opts = opts or {}
    local parentFrame = (opts.parent and opts.parent.frame) or UIParent

    local f = CreateFrame("Button", name, parentFrame)
    f:SetSize(opts.width or 32, opts.height or 32)
    f:SetPoint(opts.point or "TOPLEFT", opts.relativeTo or parentFrame, opts.relativePoint or "TOPLEFT", opts.x or 0, opts.y or 0)
    f:RegisterForClicks("LeftButtonUp")
    f:SetMotionScriptsWhileDisabled(true)

    -- Optional background & borders
    local bgTex, top, bottom
    if not opts.noBackground then
        local br,bg,bB,ba = C.Get("background")
        bgTex = f:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints()
        bgTex:SetColorTexture(br,bg,bB,ba)

        top = f:CreateTexture(nil, "BORDER")
        top:SetPoint("TOPLEFT", f, "TOPLEFT")
        top:SetPoint("TOPRIGHT", f, "TOPRIGHT")
        top:SetHeight(1)
        C.ApplyDivider(top)

        bottom = f:CreateTexture(nil, "BORDER")
        bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
        bottom:SetHeight(1)
        C.ApplyDivider(bottom)
    end

    -- Cache normal & hover vertex colors (before icon creation)
    local baseR, baseG, baseB, baseA = 1, 1, 1, 1
    local hovFactor = opts.hoverBrightenFactor or 1.3  -- Brighten on hover (was 0.85 for darken)
    local hovR, hovG, hovB, hovA = math.min(baseR * hovFactor, 1), math.min(baseG * hovFactor, 1), math.min(baseB * hovFactor, 1), baseA

    -- Icon
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    if opts.icon then icon:SetTexture(opts.icon) end
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetVertexColor(baseR, baseG, baseB, baseA)  -- Start with base color, not hover

    ---@type IconButton
    local o = FrameElement.New(self, "IconButton", f, opts.parent)
    o.bg, o.topBorder, o.bottomBorder, o.icon = bgTex, top, bottom, icon
    o.onClick = opts.onClick
    o._locked = false
    o._baseR, o._baseG, o._baseB, o._baseA = baseR, baseG, baseB, baseA
    o._hoverR, o._hoverG, o._hoverB, o._hoverA = hovR, hovG, hovB, hovA

    -- Hover handlers
    f:SetScript("OnEnter", function()
        if not o._locked and o.icon and o.icon.SetVertexColor then
            o.icon:SetVertexColor(o._hoverR, o._hoverG, o._hoverB, o._hoverA)
        end
        
        -- Show tooltip if provided (use dynamic tooltip if available, otherwise use opts)
        local tooltip = o._tooltipText or opts.tooltip
        if tooltip and type(tooltip) == "string" then
            local Common = RPE and RPE.Common
            if Common and Common.ShowTooltip then
                local firstLine = tooltip:match("^([^\n]+)")
                local rest = tooltip:sub(#firstLine + 2)  -- everything after first line
                Common:ShowTooltip(f, {
                    title = firstLine or tooltip,
                    lines = rest and rest ~= "" and {{ text = rest }} or {}
                })
            end
        end
    end)

    f:SetScript("OnLeave", function()
        if o.icon and o.icon.SetVertexColor then
            o.icon:SetVertexColor(o._baseR, o._baseG, o._baseB, o._baseA)
        end
        
        -- Hide tooltip
        local Common = RPE and RPE.Common
        if Common and Common.HideTooltip then
            Common:HideTooltip()
        end
    end)

    -- Click handler
    f:SetScript("OnClick", function(_, btn)
        if o.onClick and not o._locked then
            PlaySoundFile("Interface\\UChatScrollButton", "Master")
            o.onClick(o, btn)
        end
    end)

    return o
end

function IconButton:SetIcon(path)
    if self.icon then self.icon:SetTexture(path) end
end

function IconButton:SetTooltip(tooltipText)
    -- Update the tooltip that will be shown on hover
    self._tooltipText = tooltipText
end

function IconButton:GetTooltip()
    return self._tooltipText
end

function IconButton:SetOnClick(fn)
    self.onClick = fn
end

function IconButton:SetColor(r, g, b, a)
    self._baseR = r or 1
    self._baseG = g or 1
    self._baseB = b or 1
    self._baseA = a ~= nil and a or 1
    
    -- Update hover colors to maintain the color scheme
    local hovFactor = 1.3
    self._hoverR = math.min(self._baseR * hovFactor, 1)
    self._hoverG = math.min(self._baseG * hovFactor, 1)
    self._hoverB = math.min(self._baseB * hovFactor, 1)
    self._hoverA = self._baseA
    
    if self.icon and self.icon.SetVertexColor then
        self.icon:SetVertexColor(self._baseR, self._baseG, self._baseB, self._baseA)
    end
end
function IconButton:Lock()
    if self._locked then return end
    self._locked = true
    if self.frame and self.frame.Disable then self.frame:Disable() end
    if self.icon then
        if self.icon.SetDesaturated then self.icon:SetDesaturated(true) end
        if self.icon.SetVertexColor then self.icon:SetVertexColor(1, 1, 1, 0.7) end
    end
    local dr,dg,db,da = RPE_UI.Colors.Get("divider")
    if self.topBorder then self.topBorder:SetColorTexture(dr,dg,db,(da or 1)*0.5) end
    if self.bottomBorder then self.bottomBorder:SetColorTexture(dr,dg,db,(da or 1)*0.5) end
end

function IconButton:Unlock()
    if not self._locked then return end
    self._locked = false
    if self.frame and self.frame.Enable then self.frame:Enable() end
    if self.icon then
        if self.icon.SetDesaturated then self.icon:SetDesaturated(false) end
        if self.icon.SetVertexColor then
            self.icon:SetVertexColor(self._baseR, self._baseG, self._baseB, self._baseA)
        end
    end
    local dr,dg,db,da = RPE_UI.Colors.Get("divider")
    if self.topBorder then self.topBorder:SetColorTexture(dr,dg,db,da) end
    if self.bottomBorder then self.bottomBorder:SetColorTexture(dr,dg,db,da) end
end

return IconButton
