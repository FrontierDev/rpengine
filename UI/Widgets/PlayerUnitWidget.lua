-- RPE_UI/Windows/PlayerUnitWidget.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window    = RPE_UI.Elements.Window
local VGroup    = RPE_UI.Elements.VerticalLayoutGroup
local HGroup    = RPE_UI.Elements.HorizontalLayoutGroup
local Portrait  = RPE_UI.Prefabs.CharacterPortrait
local Progress  = RPE_UI.Prefabs.ProgressBar
local IconBtn   = RPE_UI.Elements.IconButton       -- small colored icons (lock/desaturate when zero)  [uses IconButton] 
local Text      = RPE_UI.Elements.Text             -- tiny counter overlay                             [uses Text]
local Resources = RPE.Core.Resources
local C         = RPE_UI.Colors
local AuraStripWidget = RPE_UI.Windows.AuraStripWidget

---@class PlayerUnitWidget
---@field root Window
---@field content HGroup
---@field portrait CharacterPortrait
---@field bars table<string, ProgressBar>
---@field tokensGroup VGroup
---@field tokens table<string, { btn: any, label: Text }>
---@field aurasGroup VGroup
---@field debuffStrip HGroup
---@field buffStrip HGroup
---@field auraIcons table<string, { btn: any, count: Text, turns: Text }>
---@field _originalResources table<string, number>
---@field _inTemporaryMode boolean Flag to prevent refresh from overwriting NPC health display
---@field _cachedBarsToShow table<string, boolean> Cache of which bars to show
local PlayerUnitWidget = {}
_G.RPE_UI.Windows.PlayerUnitWidget = PlayerUnitWidget
PlayerUnitWidget.__index = PlayerUnitWidget
PlayerUnitWidget.Name = "PlayerUnitWidget"

-- defaults (can be overridden in opts)
local DEFAULT_TOKEN_ICONS = {
    ACTION       = "Interface\\AddOns\\RPEngine\\UI\\Textures\\action.png",
    BONUS_ACTION = "Interface\\AddOns\\RPEngine\\UI\\Textures\\bonus_action.png",
    REACTION     = "Interface\\AddOns\\RPEngine\\UI\\Textures\\reaction.png",
}

local DEFAULT_TOKEN_COLORS = {
    ACTION        = { 1.00, 0.85, 0.25, 1.0 }, -- warm amber
    BONUS_ACTION  = { 0.35, 0.90, 1.00, 1.0 }, -- cyan/teal
    REACTION      = { 0.75, 0.55, 1.00, 1.0 }, -- violet
}

-- Build the UI
---@param opts { name?:string, resources?:string[], unit?:string, tokenIcons?:table<string,string>, tokenColors?:table<string,number[]>, tokenSize?:number }
function PlayerUnitWidget:BuildUI(opts)
    opts = opts or {}
    local resList    = opts.resources or { "HEALTH", "MANA" }
    local unit       = opts.unit or "player"
    local tokenIcons = opts.tokenIcons or DEFAULT_TOKEN_ICONS
    local tokenCols  = opts.tokenColors or DEFAULT_TOKEN_COLORS
    local tokenSize  = tonumber(opts.tokenSize) or 12

    -- Root window (auto-sized, transparent background)
    self.root = Window:New("RPE_PlayerUnitWidget_Window", {
        parent   = RPE.Core.Windows.ActionBarWidget and RPE.Core.Windows.ActionBarWidget.root or nil,
        width    = 1,
        height   = 1,
        autoSize = true,
        noBackground = true,
        point    = "CENTER",
        pointRelative = "TOPLEFT",
        x        = 0,
        y        = 32,
    })

    -- Horizontal layout: [tokens] [portrait] [bars]
    self.content = HGroup:New("RPE_PlayerUnitWidget_Content", {
        parent   = self.root,
        autoSize = true,
        spacingX = 8,
        alignV   = "CENTER",
        hasBackground = false,
    })
    self.root:Add(self.content)

    -- === LEFT: Action/Bonus/Reaction tokens (vertical stack) ===
    self.tokensGroup = VGroup:New("RPE_PlayerUnitWidget_Tokens", {
        parent   = self.content,
        autoSize = true,
        spacingY = 2,
        alignH   = "CENTER",
        padding  = { top = 0, bottom = 0, left = 0, right = 0 },
    })
    self.content:Add(self.tokensGroup) -- add FIRST so it appears left-most  [uses HorizontalLayoutGroup]

    self.tokens = {}
    local function makeToken(resId, iconPath, color)
        local panel = RPE_UI.Elements.Panel:New(("RPE_PlayerUnitWidget_Token_%s"):format(resId), {
            parent = self.tokensGroup,
            width  = tokenSize, height = tokenSize,
            hasBackground = false, noBackground = true,
            hasBorder = false, noBorder = true,
        })

        -- Icon texture
        local tex = panel.frame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(panel.frame)
        if iconPath then tex:SetTexture(iconPath) end
        if color then
            local r,g,b,a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
            tex:SetVertexColor(r, g, b, a)
        end

        -- Informative hover (Common:ShowTooltip(anchor, spec))
        panel.frame:EnableMouse(true)
        panel.frame:SetScript("OnEnter", function()
            local cur, max = Resources:Get(resId)
            local title = (resId:gsub("_", " "):lower():gsub("^%l", string.upper)) -- e.g. "BONUS_ACTION" -> "Bonus action"
            local spec = {
                title = title,
                lines = {
                    { left = ("%s Available"):format(cur or 0), right = nil, r = 1, g = 1, b = 1, wrap = false },
                }
            }
            if Common and Common.ShowTooltip then
                Common:ShowTooltip(panel.frame, spec)
            end
        end)

        panel.frame:SetScript("OnLeave", function()
            if Common and Common.HideTooltip then Common:HideTooltip() end
        end)

        self.tokensGroup:Add(panel)
        self.tokens[resId] = { panel = panel, icon = tex }
    end

    makeToken("ACTION",       tokenIcons.ACTION,       tokenCols.ACTION)
    makeToken("BONUS_ACTION", tokenIcons.BONUS_ACTION, tokenCols.BONUS_ACTION)
    makeToken("REACTION",     tokenIcons.REACTION,     tokenCols.REACTION)

    -- === PORTRAIT (center) ===
    self.portrait = Portrait:New("RPE_PlayerUnitWidget_Portrait", {
        parent = self.content,
        width  = 32,
        height = 32,
        unit   = unit,
        hasBackground = false, noBackground = true
    })
    self.content:Add(self.portrait)

    -- Right-click menu on portrait to select resources
    if self.portrait and self.portrait.frame then
        self.portrait.frame:SetScript("OnMouseUp", function(frame, button)
            if button == "RightButton" and not self._inTemporaryMode then
                self:ShowResourceMenu()
            end
        end)
    end

    -- === RIGHT: resource bars ===
    self.barsGroup = VGroup:New("RPE_PlayerUnitWidget_BarsGroup", {
        parent   = self.content,
        autoSize = true,
        spacingY = 4,
        alignH   = "LEFT",
    })
    self.content:Add(self.barsGroup)

    self.bars = {}
    
    -- Get profile
    local profile = RPE.Profile.DB.GetOrCreateActive()
    
    -- Try to load saved resource display settings for this dataset combination
    local Resources = RPE.Core and RPE.Core.Resources
    local resourcesToDisplay = Resources and Resources:GetDisplayedResources(profile) or { "HEALTH", "MANA" }
    
    -- Cache which bars to show for later use by RebuildResourceBars
    self._cachedBarsToShow = resourcesToDisplay or {}
    
    -- Build bars based on what should be displayed
    self:RebuildResourceBars(self._cachedBarsToShow)

    -- === RIGHT OF BARS: Aura strips ===
    -- === Aura strips (self-contained widget) ===
    local myId = RPE.Core.GetLocalPlayerUnitId()
    self.auras = AuraStripWidget.New({
        parent  = self.root,
        unitId  = myId,
        point   = "TOPRIGHT",
        pointRelative = "TOPRIGHT",
        x       = -72,
        y       = 0,
    })
    self.auraIcons = {}

    if RPE_UI.Common and RPE_UI.Common.RegisterWindow then
        RPE_UI.Common:RegisterWindow(self)
    end

    self:Refresh()
end

--- Refresh all resource bars + turn tokens.
function PlayerUnitWidget:Refresh()
    -- Skip refresh if in temporary mode (controlling another unit); keep NPC health display intact
    if self._inTemporaryMode then
        return
    end
    
    -- Ensure bars table exists
    if not self.bars then
        self.bars = {}
        return  -- Can't refresh if we have no bars yet
    end
    
    -- Get current display settings from profile
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if profile and profile.resourceDisplaySettings then
        local DatasetDB = RPE.Profile.DatasetDB
        local activeDatasets = DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter()
        local datasetKey = ""
        if activeDatasets and #activeDatasets > 0 then
            table.sort(activeDatasets)
            datasetKey = table.concat(activeDatasets, "|")
        else
            datasetKey = "none"
        end
        
        local settings = profile:_NormalizeResourceSettings(datasetKey)
        
        -- Hide all bars first
        for resId, bar in pairs(self.bars) do
            if bar and bar.frame then
                bar.frame:Hide()
            end
        end
        
        -- Show only bars that should be displayed
        if settings and settings.show then
            for _, resId in ipairs(settings.show) do
                local bar = self.bars[resId]
                if bar and bar.frame then
                    bar.frame:Show()
                end
            end
        end
    end
    
    -- === Existing bars/tokens refresh ===
    for resId, bar in pairs(self.bars or {}) do
        if bar and bar.frame and bar.frame:IsShown() then
            local cur, max = Resources:Get(resId)
            bar:SetValue(cur, max)
            
            -- Show absorption on HEALTH bar
            if resId == "HEALTH" then
                local ev = RPE.Core.ActiveEvent
                if ev and ev.units then
                    local localPlayerKey = ev.localPlayerKey
                    local playerUnit = localPlayerKey and ev.units[localPlayerKey]
                    local totalAbsorption = 0
                    
                    if playerUnit then
                        if RPE and RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal(string.format("[PlayerUnitWidget] Player unit found: %s, has absorption: %s", 
                                playerUnit.name or "unknown", 
                                playerUnit.absorption and "YES" or "NO"))
                        end
                        
                        if playerUnit.absorption then
                            for shieldId, shield in pairs(playerUnit.absorption) do
                                if shield.amount then
                                    totalAbsorption = totalAbsorption + shield.amount
                                    if RPE and RPE.Debug and RPE.Debug.Internal then
                                        RPE.Debug:Internal(string.format("[PlayerUnitWidget] Shield %s: amount=%d", shieldId, shield.amount))
                                    end
                                end
                            end
                        end
                    else
                        if RPE and RPE.Debug and RPE.Debug.Internal then
                            RPE.Debug:Internal("[PlayerUnitWidget] Player unit NOT found")
                        end
                    end
                    
                    if RPE and RPE.Debug and RPE.Debug.Internal then
                        RPE.Debug:Internal(string.format("[PlayerUnitWidget] Setting HEALTH absorption: %d / max %d", totalAbsorption, max))
                    end
                    
                    bar:SetAbsorption(totalAbsorption, max)
                else
                    if RPE and RPE.Debug and RPE.Debug.Internal then
                        RPE.Debug:Internal("[PlayerUnitWidget] No active event or units table")
                    end
                    bar:SetAbsorption(0, max)
                end
            end
        end
    end
    
    for resId, parts in pairs(self.tokens or {}) do
        local cur  = select(1, Resources:Get(resId))
        local icon = parts.icon or (parts.btn and parts.btn.icon)
        if icon then
            icon:SetAlpha((cur or 0) > 0 and 1.0 or 0.3)
        end
    end
end


function PlayerUnitWidget:Show() if self.root then self.root:Show() end end
function PlayerUnitWidget:Hide() if self.root then self.root:Hide() end end

--- Apply the stat's itemTooltipColor to a progress bar
function PlayerUnitWidget:_ApplyStatColor(bar, resourceId)
    if not bar then return end
    
    -- Get the stat definition from StatRegistry (which has itemTooltipColor)
    local StatRegistry = RPE.Core and RPE.Core.StatRegistry
    local statDef = StatRegistry and StatRegistry:Get(resourceId)
    
    if statDef and statDef.itemTooltipColor then
        local r, g, b = statDef.itemTooltipColor[1] or 1, statDef.itemTooltipColor[2] or 1, statDef.itemTooltipColor[3] or 1
        bar:SetColor(r, g, b, 1)
    end
end

function PlayerUnitWidget:ShowResourceMenu()
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile or not profile.stats then return end

    -- Always-used resources (always in use list, but shown in dropdown as locked)
    local alwaysUsed = {
        HEALTH = true,
        ACTION = true,
        BONUS_ACTION = true,
        REACTION = true,
    }

    -- Collect ALL RESOURCE category stats that don't start with "MAX_" (but exclude HEALTH as it's implicit)
    local allResources = {}
    for statId, stat in pairs(profile.stats) do
        if stat.category == "RESOURCE" and not statId:match("^MAX_") and statId ~= "HEALTH" then
            table.insert(allResources, { id = statId, name = stat.name or statId, alwaysUsed = alwaysUsed[statId] or false })
        end
    end

    if #allResources == 0 then return end

    -- Sort by name
    table.sort(allResources, function(a, b) return (a.name or "") < (b.name or "") end)

    -- Get current settings
    local useSet = {}
    local showSet = {}
    local DatasetDB = RPE.Profile.DatasetDB
    local activeDatasets = DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter()
    local datasetKey = ""
    if activeDatasets and #activeDatasets > 0 then
        table.sort(activeDatasets)
        datasetKey = table.concat(activeDatasets, "|")
    else
        datasetKey = "none"
    end
    
    -- Populate sets (always-used always in use list)
    -- Normalize settings in case they're in old format
    local settings = profile:_NormalizeResourceSettings(datasetKey)
    for _, resId in ipairs({"HEALTH", "ACTION", "BONUS_ACTION", "REACTION"}) do
        useSet[resId] = true
    end
    if settings then
        if settings.use then
            for _, resId in ipairs(settings.use) do
                useSet[resId] = true
            end
        end
        if settings.show then
            for _, resId in ipairs(settings.show) do
                showSet[resId] = true
            end
        end
    end

    -- Build menu via ContextMenu with two sections
    if RPE_UI.Common and RPE_UI.Common.ContextMenu then
        RPE_UI.Common:ContextMenu(self.portrait.frame, function(level, menuList)
            if level == 1 then
                -- USE section header
                local headerUse = UIDropDownMenu_CreateInfo()
                headerUse.text = "\124cff1eff00USE\124r"
                headerUse.isTitle = true
                headerUse.disabled = true
                UIDropDownMenu_AddButton(headerUse, level)

                -- USE section items
                for _, res in ipairs(allResources) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = res.name
                    info.checked = useSet[res.id]
                    info.disabled = res.alwaysUsed  -- Lock always-used resources
                    if not res.alwaysUsed then
                        local resourceId = res.id
                        info.func = function()
                            self:CycleResourceState(resourceId, "use")
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)
                end

                -- Separator
                local sep = UIDropDownMenu_CreateInfo()
                sep.disabled = true
                sep.notClickable = true
                sep.text = ""
                UIDropDownMenu_AddButton(sep, level)

                -- SHOW section header
                local headerShow = UIDropDownMenu_CreateInfo()
                headerShow.text = "\124cff6699ffSHOW\124r"
                headerShow.isTitle = true
                headerShow.disabled = true
                UIDropDownMenu_AddButton(headerShow, level)

                -- SHOW section items (same resources)
                for _, res in ipairs(allResources) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = res.name
                    info.checked = showSet[res.id]
                    -- Always-used can still be toggled for SHOW, but use is locked
                    local resourceId = res.id
                    info.func = function()
                        self:CycleResourceState(resourceId, "show")
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end)
    end
end

function PlayerUnitWidget:CycleResourceState(resourceId, section)
    local profile = RPE.Profile.DB.GetOrCreateActive()
    if not profile then return end
    
    -- Get dataset key
    local DatasetDB = RPE.Profile.DatasetDB
    local activeDatasets = DatasetDB and DatasetDB.GetActiveNamesForCurrentCharacter()
    local datasetKey = ""
    if activeDatasets and #activeDatasets > 0 then
        table.sort(activeDatasets)
        datasetKey = table.concat(activeDatasets, "|")
    else
        datasetKey = "none"
    end
    
    -- Initialize if needed and normalize settings
    if not profile.resourceDisplaySettings then
        profile.resourceDisplaySettings = {}
    end
    local settings = profile:_NormalizeResourceSettings(datasetKey)
    
    if section == "use" then
        -- Toggle in use list
        local idx = nil
        for i, resId in ipairs(settings.use or {}) do
            if resId == resourceId then
                idx = i
                break
            end
        end
        if idx then
            table.remove(settings.use, idx)
        else
            if not settings.use then settings.use = {} end
            table.insert(settings.use, resourceId)
        end
    elseif section == "show" then
        -- Toggle in show list
        local idx = nil
        for i, resId in ipairs(settings.show or {}) do
            if resId == resourceId then
                idx = i
                break
            end
        end
        if idx then
            table.remove(settings.show, idx)
        else
            if not settings.show then settings.show = {} end
            table.insert(settings.show, resourceId)
        end
    end
    
    -- Save to profile and rebuild bars with new display settings
    RPE.Profile.DB.SaveProfile(profile)
    
    -- Pass the profile explicitly so we read the same one we just saved
    local resourcesToDisplay = Resources:GetDisplayedResources(profile)
    self:RebuildResourceBars(resourcesToDisplay)
end

function PlayerUnitWidget:RebuildResourceBars(resourceList)
    if not self.barsGroup then 
        self.bars = {}  -- Ensure bars is always initialized
        return 
    end

    -- Destroy all existing bars
    for resId, bar in pairs(self.bars or {}) do
        if bar and bar.frame then
            bar.frame:Hide()
            bar.frame:SetParent(nil)
            bar.frame = nil
        end
    end
    self.bars = {}
    
    -- Clear the layout group's children
    self.barsGroup.children = {}
    
    -- Create bars in the order specified, with HEALTH always first
    local orderedResources = {}
    if resourceList and #resourceList > 0 then
        -- Add HEALTH first if it's in the list
        for _, resId in ipairs(resourceList) do
            if resId == "HEALTH" then
                table.insert(orderedResources, resId)
                break
            end
        end
        -- Add all other resources in order
        for _, resId in ipairs(resourceList) do
            if resId ~= "HEALTH" then
                table.insert(orderedResources, resId)
            end
        end
    end
    
    -- Create bars
    for _, resId in ipairs(orderedResources) do
        local bar = RPE_UI.Prefabs.ProgressBar:New("RPE_PlayerUnitWidget_Bar_" .. resId, {
            parent = self.barsGroup,
            width  = 160,
            height = 10,
            style  = "progress_" .. string.lower(resId),
        })
        bar:SetText(resId)
        self:_ApplyStatColor(bar, resId)
        self.barsGroup:Add(bar)
        self.bars[resId] = bar
    end
    
    -- Relayout
    if self.barsGroup.Relayout then
        self.barsGroup:Relayout()
    end
    
    -- Refresh to populate values
    self:Refresh()
end

function PlayerUnitWidget:_AddAuraIcon(parent, auraId, iconPath, isHelpful)
    local btn = IconBtn:New(("RPE_PlayerUnitWidget_Aura_%s"):format(auraId), {
        parent = parent,
        width  = 16, height = 16,
        icon   = iconPath,
        desaturated = not isHelpful,
    })
    parent:Add(btn)

    -- stack counter (bottom-right)
    local count = Text:New(btn.name .. "_Count", {
        parent = btn,
        fontTemplate = "GameFontNormalSmall",
        text = "",
        point = "BOTTOMRIGHT",
        textPoint = "BOTTOMRIGHT",
        autoSize = false,
    })

    -- turns remaining (top-right)
    local turns = Text:New(btn.name .. "_Turns", {
        parent = btn,
        fontTemplate = "GameFontNormalTiny",
        text = "",
        point = "TOPRIGHT",
        textPoint = "TOPRIGHT",
        autoSize = false,
    })

    self.auraIcons[auraId] = { btn = btn, count = count, turns = turns }
    return btn
end

--- Temporarily override stat/resource display with NPC values.
---@param unit EventUnit
function PlayerUnitWidget:SetTemporaryStats(unit)
    if not unit or not unit.isNPC then return end

    self._originalResources = self._originalResources or {}
    self._inTemporaryMode = true

    -- Save current player resource values
    for resId, bar in pairs(self.bars or {}) do
        local cur, max = Resources:Get(resId)
        self._originalResources[resId] = { cur = cur, max = max, shown = bar.frame:IsShown() }
    end

    -- Save the current cast bar state (player's cast if any)
    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    if CB then
        self._originalCast = CB.currentCast
    end

    -- Switch cast bar to controlled unit's active cast
    if CB then
        local event = RPE.Core.ActiveEvent
        local unitId = tonumber(unit.id) or 0
        local controlledCast = event and event:GetActiveCast(unitId)
        
        if controlledCast then
            -- Switch to controlled unit's cast
            local ctx = { event = event, resources = RPE.Core.Resources }
            CB:Begin(controlledCast, ctx)
        else
            -- No active cast for controlled unit, hide cast bar
            CB:Hide()
        end
    end

    -- Replace portrait with NPC model or fallback icon
    if self.portrait and self.portrait.portrait then
        local tex = self.portrait.portrait
        local displayId = unit.displayId or unit.modelDisplayId or unit.ModelID
        local fileId    = unit.fileDataId

        if displayId and SetPortraitTextureFromCreatureDisplayID then
            SetPortraitTextureFromCreatureDisplayID(tex, displayId)
            tex:SetTexCoord(0, 1, 0, 1)
        elseif fileId then
            tex:SetTexture(fileId)
            tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        else
            tex:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
            tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
    end

    -- Hide all bars except HEALTH
    for resId, bar in pairs(self.bars or {}) do
        if resId ~= "HEALTH" then
            bar:Hide()
        else
            bar:SetValue(unit.hp or 0, unit.hpMax or 1)
            
            -- Show NPC absorption on health bar
            local totalAbsorption = 0
            if unit.absorption then
                for _, shield in pairs(unit.absorption) do
                    if shield.amount then
                        totalAbsorption = totalAbsorption + shield.amount
                    end
                end
            end
            bar:SetAbsorption(totalAbsorption, unit.hpMax or 1)
            
            bar:Show()
        end
    end
end



--- Restore the player's original portrait and stats after leaving temporary mode.
function PlayerUnitWidget:RestoreStats()
    if not self._originalResources then return end

    self._inTemporaryMode = false

    -- Restore resource bars
    for resId, saved in pairs(self._originalResources) do
        local bar = self.bars and self.bars[resId]
        if bar and saved then
            bar:SetValue(saved.cur or 0, saved.max or 1)
            if saved.shown then
                bar:Show()
            else
                bar:Hide()
            end
        end
    end

    -- Restore player portrait
    if self.portrait and self.portrait.portrait then
        SetPortraitTexture(self.portrait.portrait, "player")
        self.portrait.portrait:SetTexCoord(0, 1, 0, 1)
    end

    self._originalResources = nil
    
    -- Don't restore the cast bar here - let ActionBarWidget:RestoreActions() handle it
    -- The cast bar should show the player's CURRENT cast, not the original one
    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    if CB then
        -- Just clear the original cast tracking; don't actually show/hide the cast bar
        -- RestoreActions() will handle the cast bar visibility
    end
    self._originalCast = nil
    
    -- Reset the active profile instance to ensure we're displaying the player's actual profile
    if RPE and RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.ResetActiveInstance then
        RPE.Profile.DB.ResetActiveInstance()
    end
    
    -- Force a refresh to ensure the latest player resources are displayed
    self:Refresh()
end

-- Constructor
function PlayerUnitWidget.New(opts)
    local self = setmetatable({}, PlayerUnitWidget)
    self:BuildUI(opts or {})
    return self
end

return PlayerUnitWidget
