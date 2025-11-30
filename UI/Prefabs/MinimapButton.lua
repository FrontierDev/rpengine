-- RPE_UI/Prefabs/MinimapButton.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

---@class MinimapButton
---@field frame Button
local MinimapButton = {}
MinimapButton.__index = MinimapButton
RPE_UI.Prefabs.MinimapButton = MinimapButton

-- SavedVariables (hook into your global DB)
RPE_DB = RPE_DB or {}
RPE_DB.minimap = RPE_DB.minimap or { angle = 45, hide = false }

-- Internal helpers ------------------------------------------------------------
local function updatePosition(self)
    local angle = RPE_DB.minimap.angle or 45
    local radius = 106
    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius
    self.frame:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- -----------------------------------------------------------------------------
-- Constructor
-- -----------------------------------------------------------------------------
---@param name string
---@param opts table|nil
---@return MinimapButton
function MinimapButton:New(name, opts)
    opts = opts or {}

    local f = CreateFrame("Button", name, Minimap)
    f:SetSize(32, 32)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(8)

    -- Icon
    local icon = f:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(opts.icon or "Interface\\Addons\\RPEngine\\UI\\Textures\\rpe.png")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")

    -- Border (default Blizzard style)
    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")

    ---@type MinimapButton
    local o = setmetatable({}, self)
    o.frame = f
    o.icon = icon

    -- Dragging
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(btn)
        btn:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            local dx, dy = px / scale - mx, py / scale - my
            local angle = math.deg(math.atan2(dy, dx))
            RPE_DB.minimap.angle = angle
            updatePosition(o)
        end)
    end)
    f:SetScript("OnDragStop", function(btn)
        btn:SetScript("OnUpdate", nil)
    end)

    -- Clicks
    f:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            RPE_UI.Common:Toggle(RPE.Core.Windows.MainWindow) -- example toggle
        elseif btn == "RightButton" then
            RPE.Debug:NYI("Minimap right-click functions.")
        end
    end)

    -- Tooltip
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("RPEngine")
        GameTooltip:AddLine("Left-Click: Toggle main window", 1, 1, 1)
        GameTooltip:AddLine("Right-Click: Options", 1, 1, 1)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    if RPE_DB.minimap.hide then
        f:Hide()
    else
        updatePosition(o)
        f:Show()
    end

    return o
end

-- Public API
function MinimapButton:Show()
    RPE_DB.minimap.hide = false
    self.frame:Show()
end

function MinimapButton:Hide()
    RPE_DB.minimap.hide = true
    self.frame:Hide()
end

MinimapButton:New("RPE")

return MinimapButton
