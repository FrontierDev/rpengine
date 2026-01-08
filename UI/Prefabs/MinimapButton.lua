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

-- Create the dropdown menu frame once at module load
local minimapMenuFrame = CreateFrame("Frame", "RPE_MinimapMenuDropdown", UIParent, "UIDropDownMenuTemplate")

local function GetOrCreatePaletteWindow()
    local PaletteWindowClass = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.PaletteWindow
    if not PaletteWindowClass then
        return nil
    end
    
    if not PaletteWindowClass.instance then
        PaletteWindowClass.instance = PaletteWindowClass:New()
    end
    return PaletteWindowClass.instance
end

local function InitializeMinimapMenu(level)
    if level == 1 then
        local info = UIDropDownMenu_CreateInfo()
        
        -- Main Window
        info.text = "Character Sheet"
        info.func = function()
            RPE_UI.Common:Toggle(RPE.Core.Windows.MainWindow)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Separator
        UIDropDownMenu_AddSeparator(level)
        
        -- Event
        info = UIDropDownMenu_CreateInfo()
        info.text = "Event Window"
        info.func = function()
            if not (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then
                RPE.Debug:Print("Only the supergroup leader can open the Event window.")
                return
            end
            local Event = RPE_UI.Common:GetWindow("EventWindow")
            if not Event then
                RPE.Debug:Error("Event window not found.")
                return
            end
            RPE_UI.Common:Toggle(Event)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Datasets
        info = UIDropDownMenu_CreateInfo()
        info.text = "Datasets Window"
        info.func = function()
            local Datasets = RPE_UI.Common:GetWindow("DatasetWindow")
            if not Datasets then
                RPE.Debug:Error("Dataset window not found.")
                return
            end
            RPE_UI.Common:Toggle(Datasets)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Rulesets
        info = UIDropDownMenu_CreateInfo()
        info.text = "Rulesets Window"
        info.func = function()
            if not (RPE.Core and RPE.Core.IsLeader and RPE.Core.IsLeader()) then
                RPE.Debug:Print("Only the supergroup leader can open the Ruleset window.")
                return
            end
            local Ruleset = RPE_UI.Common:GetWindow("Ruleset")
            if not Ruleset then
                RPE.Debug:Error("Ruleset window not found.")
                return
            end
            RPE_UI.Common:Toggle(Ruleset)
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- LFRP
        info = UIDropDownMenu_CreateInfo()
        info.text = "LFRP Window"
        info.func = function()
            local LFRPWindow = RPE_UI.Common:GetWindow("LFRPWindow")
            local isNewWindow = false
            if not LFRPWindow then
                if RPE_UI.Windows and RPE_UI.Windows.LFRPWindow then
                    LFRPWindow = RPE_UI.Windows.LFRPWindow.New()
                    RPE_UI.Common:Show(LFRPWindow)
                    isNewWindow = true
                else
                    RPE.Debug:Error("LFRP window class not found.")
                    return
                end
            end
            if not isNewWindow then
                RPE_UI.Common:Toggle(LFRPWindow)
            end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Chanter
        info = UIDropDownMenu_CreateInfo()
        info.text = "Chanter Window"
        info.func = function()
            local win = RPE_UI.Common:GetWindow("ChanterSenderWindow")
            local isNewWindow = false
            if not win then
                local C = _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.ChanterSenderWindow
                if C and C.New then
                    win = C.New({})
                    win:Show()
                    isNewWindow = true
                end
            end
            if not win then
                RPE.Debug:Error("Chanter window not found.")
                return
            end
            if not isNewWindow then
                RPE_UI.Common:Toggle(win)
            end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Palette
        info = UIDropDownMenu_CreateInfo()
        info.text = "Palette Window"
        info.func = function()
            local PaletteWindowClass = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.PaletteWindow
            if not PaletteWindowClass then
                RPE.Debug:Error("PaletteWindow not found.")
                CloseDropDownMenus()
                return
            end
            
            local isNewWindow = false
            if not PaletteWindowClass.instance then
                PaletteWindowClass.instance = PaletteWindowClass:New()
                isNewWindow = true
            end
            
            local paletteWin = PaletteWindowClass.instance
            if isNewWindow then
                paletteWin.root.frame:Show()
            else
                if paletteWin.root.frame:IsVisible() then
                    paletteWin.root.frame:Hide()
                else
                    paletteWin.root.frame:Show()
                end
            end
            paletteWin.root.frame:Raise()
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Separator
        UIDropDownMenu_AddSeparator(level)
        
        -- Use Chatbox
        info = UIDropDownMenu_CreateInfo()
        info.text = "Use Chatbox"
        info.func = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if not profile then
                RPE.Debug:Error("Profile not found.")
                CloseDropDownMenus()
                return
            end
            
            profile.showChatbox = not profile.showChatbox
            if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                RPE.Profile.DB.SaveProfile(profile)
            end
            
            local chatBox = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.Chat
            if chatBox then
                if profile.showChatbox then
                    chatBox:Show()
                else
                    chatBox:Hide()
                end
            end
            CloseDropDownMenus()
        end
        info.checked = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            return profile and profile.showChatbox
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Use Talking Heads
        info = UIDropDownMenu_CreateInfo()
        info.text = "Use Talking Heads"
        info.func = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if not profile then
                RPE.Debug:Error("Profile not found.")
                CloseDropDownMenus()
                return
            end
            
            profile.showTalkingHeads = not profile.showTalkingHeads
            if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                RPE.Profile.DB.SaveProfile(profile)
            end
            
            local speechBubbles = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.SpeechBubbles
            if speechBubbles then
                if profile.showTalkingHeads then
                    speechBubbles:Show()
                else
                    speechBubbles:Hide()
                end
            end
            CloseDropDownMenus()
        end
        info.checked = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            return profile and profile.showTalkingHeads
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Use Immersion Mode
        info = UIDropDownMenu_CreateInfo()
        info.text = "Use Immersion Mode"
        info.func = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            if not profile then
                RPE.Debug:Error("Profile not found.")
                CloseDropDownMenus()
                return
            end
            
            profile.immersionMode = not profile.immersionMode
            if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.SaveProfile then
                RPE.Profile.DB.SaveProfile(profile)
            end
            
            if RPE.Core then
                RPE.Core.ImmersionMode = profile.immersionMode
            end
            CloseDropDownMenus()
        end
        info.checked = function()
            local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
            return profile and profile.immersionMode
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

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
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    local isDragging = false
    
    f:SetScript("OnMouseDown", function(btn, button)
        if button == "LeftButton" then
            isDragging = true
            btn:SetScript("OnUpdate", function()
                local mx, my = Minimap:GetCenter()
                local px, py = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                local dx, dy = px / scale - mx, py / scale - my
                local angle = math.deg(math.atan2(dy, dx))
                RPE_DB.minimap.angle = angle
                updatePosition(o)
            end)
        end
    end)
    
    f:SetScript("OnMouseUp", function(btn, button)
        if button == "LeftButton" then
            isDragging = false
            btn:SetScript("OnUpdate", nil)
        end
    end)

    -- Clicks
    f:SetScript("OnClick", function(btn, clickedButton)
        if isDragging then return end
        
        if clickedButton == "LeftButton" then
            local Dashboard = RPE_UI.Common:GetWindow("DashboardWindow")
            local isNew = false
            if not Dashboard then
                if RPE_UI.Windows and RPE_UI.Windows.DashboardWindow then
                    Dashboard = RPE_UI.Windows.DashboardWindow.New()
                    isNew = true
                end
            end
            if Dashboard then
                if isNew then
                    Dashboard:Show()
                else
                    RPE_UI.Common:Toggle(Dashboard)
                end
            end
        elseif clickedButton == "RightButton" then
            RPE_UI.Common:ContextMenu(btn, InitializeMinimapMenu)
        end
    end)

    -- Tooltip
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("RPEngine")
        GameTooltip:AddLine("Left-Click: Toggle Dashboard", 1, 1, 1)
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
