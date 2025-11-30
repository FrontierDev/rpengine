-- RPE/Core/InteractionManager.lua
-- Detects player target changes and reports available interactions.

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local InteractionRegistry = assert(RPE.Core.InteractionRegistry, "InteractionRegistry required")
local UI = _G.RPE_UI and _G.RPE_UI.Windows
local InteractionWidget = UI and UI.InteractionWidget

---@class InteractionManager
---@field frame Frame
local InteractionManager = {}
RPE.Core.InteractionManager = InteractionManager

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function GetNPCTitleFromTooltip()
    if not UnitExists("target") or UnitIsPlayer("target") then return nil end

    if not RPE_TempTooltip then
        RPE_TempTooltip = CreateFrame("GameTooltip", "RPE_TempTooltip", UIParent, "GameTooltipTemplate")
    end

    RPE_TempTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    RPE_TempTooltip:SetUnit("target")

    local title = _G["RPE_TempTooltipTextLeft2"] and _G["RPE_TempTooltipTextLeft2"]:GetText()
    RPE_TempTooltip:Hide()

    return title
end

local function GetTargetInfo()
    if not UnitExists("target") or UnitIsPlayer("target") then return nil end

    local name = UnitName("target")
    local guid = UnitGUID("target") or ""
    local id   = guid:match("-(%d+)-%x+$") or ""
    local title = GetNPCTitleFromTooltip()
    local creatureType = UnitCreatureType("target") or "(unknown)"

    -- Player's current location
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or 0
    local loc = "(unknown)"
    if mapID and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            loc = string.format("%.1f, %.1f (Map %d)", pos.x * 100, pos.y * 100, mapID)
        end
    end

    return {
        name = name,
        id = id,
        title = title,
        guid = guid,
        creatureType = creatureType,
        mapID = mapID,
        location = loc,
    }
end

-- ---------------------------------------------------------------------------
-- Matching logic
-- ---------------------------------------------------------------------------

local function FilterInteractionsByMapAndType(matches, info)
    local filtered = {}
    local isDead = UnitIsDead("target") or false

    for _, inter in ipairs(matches) do
        -- Type-based rule (e.g., "type:beast")
        if inter.target and inter.target:match("^type:") then
            local ruleType = inter.target:match("^type:(.+)$")

            if ruleType and info.creatureType and info.creatureType:lower() == ruleType:lower() then
                -- Check each option individually for map & dead-state
                local validOpts = {}
                for _, opt in ipairs(inter.options or {}) do
                    local validMap = true
                    local validDead = true

                    -- Map restriction
                    if opt.mapID then
                        validMap = false
                        for _, allowedMap in ipairs(opt.mapID) do
                            if tonumber(allowedMap) == tonumber(info.mapID) then
                                validMap = true
                                break
                            end
                        end
                    end

                    -- Dead state restriction
                    if opt.requiresDead then
                        validDead = isDead
                    end

                    if validMap and validDead then
                        -- Clone the interaction but include only this valid option
                        local clone = {
                            id = inter.id,
                            target = inter.target,
                            options = { opt },
                        }
                        table.insert(filtered, clone)
                    end
                end
            end
        else
            -- Normal ID/title interaction (no type: prefix)
            local validOpts = {}
            for _, opt in ipairs(inter.options or {}) do
                local validMap = true
                local validDead = true

                if opt.mapID then
                    validMap = false
                    for _, allowedMap in ipairs(opt.mapID) do
                        if tonumber(allowedMap) == tonumber(info.mapID) then
                            validMap = true
                            break
                        end
                    end
                end

                if opt.requiresDead then
                    validDead = isDead
                end

                if validMap and validDead then
                    table.insert(validOpts, opt)
                end
            end

            if #validOpts > 0 then
                -- Keep only the valid options for this interaction
                table.insert(filtered, {
                    id = inter.id,
                    target = inter.target,
                    options = validOpts,
                })
            end
        end
    end

    return filtered
end


-- ---------------------------------------------------------------------------
-- Main handler
-- ---------------------------------------------------------------------------

local hideTimer = nil

local function HideWidgetSafe()
    if not InteractionWidget or not InteractionWidget.root then return end
    if InteractionWidget.root.frame and InteractionWidget.root.frame:IsShown() then
        InteractionWidget:Hide()
    end
end

local function OnTargetChanged()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end

    local info = GetTargetInfo()
    if not info then
        hideTimer = C_Timer.NewTimer(0.15, HideWidgetSafe)
        return
    end

    -- Fetch direct matches (ID or title)
    local matches = InteractionRegistry:GetForNPC(info.id, info.title)

    -- Also fetch all interactions to look for type: rules
    local all = InteractionRegistry:All()
    for _, inter in pairs(all) do
        if inter.target and inter.target:match("^type:") then
            table.insert(matches, inter)
        end
    end

    local filtered = FilterInteractionsByMapAndType(matches, info)

    if not filtered or #filtered == 0 then
        hideTimer = C_Timer.NewTimer(0.15, HideWidgetSafe)
        return
    end

    -- Display widget
    if not InteractionWidget or not InteractionWidget.root then
        if _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.InteractionWidget then
            InteractionWidget = _G.RPE_UI.Windows.InteractionWidget.New({})
        end
    end

    if InteractionWidget and InteractionWidget.ShowInteractions then
        InteractionWidget:ShowInteractions(filtered, info.name or "", info.title or "")
    end
end

-- ---------------------------------------------------------------------------
-- Actions
-- ---------------------------------------------------------------------------

---@param opt table  -- the option table (contains label, action, args, etc.)
---@param info table -- NPC target info (id, name, creatureType, etc.)
function InteractionManager:RunAction(opt, info)
    if not opt or not opt.action then return end

    local action = string.upper(opt.action)
    local handlerName = "Handle_" .. action
    local handler = self[handlerName]

    if type(handler) == "function" then
        handler(self, opt, info)
    else
        RPE.Debug:Error(("Unknown interaction action: %s"):format(tostring(action)))
    end
end

function InteractionManager:Handle_DIALOGUE(opt, info)
    -- TODO: Hook into your dialogue UI
end

function InteractionManager:Handle_SKIN(opt, info)
    -- TODO: Hook into loot system, drop logic, etc.
end

function InteractionManager:Handle_TRAIN(opt, info)
end

function InteractionManager:Handle_SHOP(opt, info)
end

function InteractionManager:Handle_AUCTION(opt, info)
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------

function InteractionManager:Init()
    if self.frame then return end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:SetScript("OnEvent", OnTargetChanged)

    self.frame = f
end

-- Auto-initialize
InteractionManager:Init()

return InteractionManager
