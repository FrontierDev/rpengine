-- RPE_UI/Widgets/SpeechBubbleWidget.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.Windows = RPE.Core.Windows or {}

RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local Window = RPE_UI.Elements.Window
local C = RPE_UI.Colors

---@class SpeechBubbleWidget
---@field root Window
---@field bubbles table Array of active speech bubbles
---@field bubblePool table Pool of reusable bubble frames
local SpeechBubbleWidget = {}
SpeechBubbleWidget.__index = SpeechBubbleWidget
RPE_UI.Windows.SpeechBubbleWidget = SpeechBubbleWidget
SpeechBubbleWidget.Name = "SpeechBubbleWidget"

local BUBBLE_FADE_DURATION = 3  -- seconds before fading
local BUBBLE_FADE_OUT_TIME = 0.5  -- fade out duration
local PORTRAIT_SIZE = 50
local MIN_BUBBLE_WIDTH = 200
local MAX_BUBBLE_WIDTH = 400
local PADDING = 8

function SpeechBubbleWidget:BuildUI(opts)
    opts = opts or {}
    local parentFrame = (RPE.Core and RPE.Core.ImmersionMode) and WorldFrame or UIParent

    -- Speech bubbles should always be visible when showing (especially from chat box)
    self.onlyWhenUIHidden = false

    -- Root window - anchor to TOP of screen by default
    self.root = Window:New("RPE_SpeechBubble_Window", {
        parent = parentFrame,
        width  = 1, height = 1,
        autoSize = true,
        noBackground = true,
        point  = "TOP",
        pointRelative = "TOP",
        x = 0,
        y = 0,
    })

    -- If a chat box widget root frame is provided, anchor ABOVE it
    if opts.chatBoxRoot then
        self.root.frame:ClearAllPoints()
        self.root.frame:SetPoint("TOP", opts.chatBoxRoot, "TOP", 0, 300)
    end

    -- Immersion polish
    if parentFrame == WorldFrame then
        local f = self.root.frame
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetIgnoreParentScale(true)

        local function SyncScale() f:SetScale(UIParent and UIParent:GetScale() or 1) end
        local function UpdateMouseForUIVisibility()
            if not self.onlyWhenUIHidden then return end
            f:EnableMouse(not (UIParent and UIParent:IsShown()))
            if UIParent and UIParent:IsShown() then
                self:Hide()
            else
                self:Show()
            end
        end
        SyncScale(); UpdateMouseForUIVisibility()
        UIParent:HookScript("OnShow", function() SyncScale(); UpdateMouseForUIVisibility() end)
        UIParent:HookScript("OnHide", function() SyncScale(); UpdateMouseForUIVisibility() end)

        self._persistScaleProxy = self._persistScaleProxy or CreateFrame("Frame")
        self._persistScaleProxy:RegisterEvent("UI_SCALE_CHANGED")
        self._persistScaleProxy:RegisterEvent("DISPLAY_SIZE_CHANGED")
        self._persistScaleProxy:SetScript("OnEvent", SyncScale)
    end

    -- Initialize bubble storage
    self.bubbles = {}
    self.bubblePool = {}
end

-- Create or reuse a speech bubble frame
function SpeechBubbleWidget:_GetBubbleFrame()
    local bubble = table.remove(self.bubblePool)
    if bubble then
        bubble:Show()
        return bubble
    end

    -- Container frame (will auto-size)
    local bubble = CreateFrame("Frame", nil, self.root.frame)
    bubble:SetSize(300, 60)  -- Initial size, will be adjusted

    -- Background with translucent color
    local bg = bubble:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local r, g, b, a = C.Get("background")
    bg:SetColorTexture(r, g, b, a)
    bubble._bg = bg

    -- Top border (team colored)
    local topBorder = bubble:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT", bubble, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", bubble, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(1)
    bubble._topBorder = topBorder

    -- Bottom border (team colored)
    local botBorder = bubble:CreateTexture(nil, "BORDER")
    botBorder:SetPoint("BOTTOMLEFT", bubble, "BOTTOMLEFT", 0, 0)
    botBorder:SetPoint("BOTTOMRIGHT", bubble, "BOTTOMRIGHT", 0, 0)
    botBorder:SetHeight(1)
    bubble._botBorder = botBorder

    -- Left border (subtle)
    local leftBorder = bubble:CreateTexture(nil, "BORDER")
    leftBorder:SetPoint("TOPLEFT", bubble, "TOPLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", bubble, "BOTTOMLEFT", 0, 0)
    leftBorder:SetWidth(1)
    leftBorder:SetColorTexture(0.3, 0.3, 0.35, 0.6)

    -- Right border (subtle)
    local rightBorder = bubble:CreateTexture(nil, "BORDER")
    rightBorder:SetPoint("TOPRIGHT", bubble, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", bubble, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetWidth(1)
    rightBorder:SetColorTexture(0.3, 0.3, 0.35, 0.6)

    -- Portrait container (for both texture and UnitPortrait)
    local portraitContainer = CreateFrame("Frame", nil, bubble)
    portraitContainer:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    bubble._portraitContainer = portraitContainer

    -- Portrait (texture-based for players)
    local portrait = bubble:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    bubble._portrait = portrait
    bubble._isEnemy = false  -- Will be set when showing

    -- Sender name (using textMuted color from palette)
    local name = bubble:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    name:SetJustifyH("LEFT")
    name:SetJustifyV("TOP")
    local r, g, b, a = C.Get("textMuted")
    name:SetTextColor(r, g, b, a)
    bubble._name = name

    -- Message text (wrapping)
    local text = bubble:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    text:SetTextColor(0.9, 0.9, 0.95, 1.0)
    bubble._text = text

    bubble._teamColor = 1  -- Will be set when showing
    bubble._npcPortrait = nil  -- Will hold UnitPortrait if needed

    return bubble
end

-- Return bubble to pool
function SpeechBubbleWidget:_ReturnBubbleFrame(bubble)
    bubble:Hide()
    table.insert(self.bubblePool, bubble)
end

-- Determine team color for a unit
function SpeechBubbleWidget:_GetTeamColor(unitToken)
    if not unitToken or not UnitExists(unitToken) then
        return C.Get("team1")  -- Default to team1 (blue)
    end

    -- Player's own messages are always team1 (blue)
    local playerName = UnitName("player")
    if UnitName(unitToken) == playerName then
        return C.Get("team1")  -- Player is always team1 (blue)
    end

    -- Check if friendly or hostile
    if UnitIsFriend("player", unitToken) then
        -- Party/raid members
        if UnitInParty(unitToken) or UnitInRaid(unitToken) then
            return C.Get("team1")  -- Party/raid team color (blue)
        else
            return C.Get("team1")  -- Other friendly also team1
        end
    else
        return C.Get("team4")  -- Enemy/hostile (green)
    end
end

-- Reposition bubble elements (portrait left for allies, right for enemies; name always top-left)
function SpeechBubbleWidget:_RepositionBubbleElements(bubble, isEnemy)
    bubble._isEnemy = isEnemy
    
    -- Clear old points
    bubble._portraitContainer:ClearAllPoints()
    bubble._portrait:ClearAllPoints()
    bubble._name:ClearAllPoints()
    bubble._text:ClearAllPoints()
    
    if isEnemy then
        -- Enemy: portrait on right side, text/name on left side
        bubble._portraitContainer:SetPoint("RIGHT", bubble, "RIGHT", -PADDING, 0)
        
        -- Name top-left, constrained by portrait
        bubble._name:SetPoint("TOPLEFT", bubble, "TOPLEFT", PADDING, -PADDING)
        bubble._name:SetPoint("RIGHT", bubble._portraitContainer, "LEFT", -PADDING, 0)
        
        -- Text below name, same width constraint
        bubble._text:SetPoint("TOPLEFT", bubble._name, "BOTTOMLEFT", 0, -2)
        bubble._text:SetPoint("RIGHT", bubble._portraitContainer, "LEFT", -PADDING, 0)
    else
        -- Ally: portrait on left side, text/name on right side
        bubble._portraitContainer:SetPoint("LEFT", bubble, "LEFT", PADDING, 0)
        
        -- Name top-left of right side (after portrait)
        bubble._name:SetPoint("TOPLEFT", bubble._portraitContainer, "TOPRIGHT", PADDING, 0)
        bubble._name:SetPoint("RIGHT", bubble, "RIGHT", -PADDING, 0)
        
        -- Text below name, same width constraint
        bubble._text:SetPoint("TOPLEFT", bubble._name, "BOTTOMLEFT", 0, -2)
        bubble._text:SetPoint("RIGHT", bubble, "RIGHT", -PADDING, 0)
    end
    
    bubble._portrait:SetAllPoints(bubble._portraitContainer)
end

-- Display a speech bubble for a say/yell message
function SpeechBubbleWidget:ShowBubble(unitToken, senderName, message, npcUnit, language)
    if not senderName or not message then return end

    -- Message is already obfuscated by Handle.lua, use it directly
    local displayMessage = message

    local bubble = self:_GetBubbleFrame()

    -- Handle portrait display: UnitPortrait for NPCs, texture for players
    local isNPC = npcUnit and npcUnit.isNPC
    if isNPC then
        -- For NPCs, create/update a UnitPortrait parented directly to bubble
        if not bubble._npcPortrait then
            local UnitPortrait = RPE_UI and RPE_UI.Prefabs and RPE_UI.Prefabs.UnitPortrait
            if UnitPortrait then
                bubble._npcPortrait = UnitPortrait:New(
                    "RPE_SpeechBubble_NPCPortrait_" .. tostring(math.random(1, 1e9)),
                    {
                        parent = nil,  -- Will manually position
                        unit = npcUnit,
                        size = PORTRAIT_SIZE,
                        noBackground = true,
                        noHealthBar = true,
                    }
                )
                bubble._npcPortrait.frame:SetParent(bubble)
                bubble._npcPortrait.frame:SetAllPoints(bubble._portraitContainer)
                bubble._npcPortrait.frame:EnableMouse(false)
                bubble._portrait:Hide()
            end
        else
            bubble._npcPortrait:SetUnit(npcUnit)
            bubble._npcPortrait.frame:Show()
        end
    else
        -- For player units, use texture portrait
        if bubble._npcPortrait and bubble._npcPortrait.frame then
            bubble._npcPortrait.frame:Hide()
        end
        bubble._portrait:Show()
        if unitToken and UnitExists(unitToken) then
            SetPortraitTexture(bubble._portrait, unitToken)
        else
            bubble._portrait:SetTexture(nil)
        end
    end

    -- Set team color borders and determine if enemy
    local r, g, b, a
    local isEnemy = false
    if isNPC then
        -- For NPCs, use their team to determine color and positioning
        local npcTeam = npcUnit.team or 1
        local localPlayerTeam = 1
        local ev = RPE and RPE.Core and RPE.Core.ActiveEvent
        if ev and ev.localPlayerKey and ev.units then
            local localUnit = ev.units[ev.localPlayerKey]
            if localUnit then localPlayerTeam = localUnit.team or 1 end
        end
        isEnemy = (npcTeam ~= localPlayerTeam)
        
        -- Get color for NPC's team
        if C.Get then
            r, g, b, a = C.Get("team" .. tostring(npcTeam))
        end
        if not r then
            r, g, b, a = 0.5, 0.8, 0.5, 1.0  -- Fallback neutral green
        end
    elseif unitToken then
        r, g, b, a = self:_GetTeamColor(unitToken)
        isEnemy = not UnitIsFriend("player", unitToken)
    else
        -- Fallback color
        r, g, b, a = 0.5, 0.8, 0.5, 1.0
    end
    
    if bubble._topBorder then
        bubble._topBorder:SetColorTexture(r, g, b, 1.0)
    end
    if bubble._botBorder then
        bubble._botBorder:SetColorTexture(r, g, b, 1.0)
    end
    
    -- Reposition elements (portrait left for allies, right for enemies)
    self:_RepositionBubbleElements(bubble, isEnemy)

    -- Set name and message
    bubble._name:SetText(senderName)
    -- Determine if language should be shown (hide for default languages)
    local playerFaction = UnitFactionGroup("player")
    local defaultLanguage = (playerFaction == "Alliance") and "Common" or "Orcish"
    local languagePrefix = language and language ~= defaultLanguage and ("[" .. language .. "] ") or ""
    bubble._text:SetText(languagePrefix .. displayMessage)

    -- Calculate available width for text (accounting for portrait and padding)
    local textWidth = MAX_BUBBLE_WIDTH - PORTRAIT_SIZE - PADDING * 4
    bubble._text:SetWidth(textWidth)
    
    -- Now get actual heights after width constraint
    local textHeight = bubble._text:GetStringHeight()
    local nameHeight = bubble._name:GetStringHeight()
    
    -- Calculate total height (portrait size or text content, whichever is larger)
    local totalHeight = math.max(PORTRAIT_SIZE + PADDING * 2, nameHeight + textHeight + PADDING * 3)
    
    bubble:SetSize(MAX_BUBBLE_WIDTH, totalHeight)

    -- Position bubble (stack vertically upward - new bubbles at top)
    local yOffset = #self.bubbles * (totalHeight + 8)
    bubble:SetPoint("TOP", self.root.frame, "TOP", 0, yOffset)

    -- Store bubble with fade timer (includes portrait for fading)
    local bubbleData = {
        frame = bubble,
        portrait = bubble._npcPortrait and bubble._npcPortrait.frame or bubble._portrait,
        startTime = GetTime(),
        fadeStartTime = GetTime() + BUBBLE_FADE_DURATION,
    }
    table.insert(self.bubbles, bubbleData)

    -- Ensure root is visible
    self:Show()

    -- Set up or restart update handler
    if not self._updateHandler then
        self._updateHandler = CreateFrame("Frame")
    end
    self._updateHandler:SetScript("OnUpdate", function()
        self:_UpdateBubbles()
    end)
end

-- Update bubble fade and positioning
function SpeechBubbleWidget:_UpdateBubbles()
    local currentTime = GetTime()
    local toRemove = {}

    for idx, bubbleData in ipairs(self.bubbles) do
        local bubble = bubbleData.frame
        local age = currentTime - bubbleData.startTime

        -- Check if bubble should fade out
        if currentTime >= bubbleData.fadeStartTime then
            local fadeAge = currentTime - bubbleData.fadeStartTime
            if fadeAge >= BUBBLE_FADE_OUT_TIME then
                -- Fully faded, remove
                table.insert(toRemove, idx)
            else
                -- Fade out (apply to both bubble and portrait)
                local fadeAlpha = 1.0 - (fadeAge / BUBBLE_FADE_OUT_TIME)
                bubble:SetAlpha(fadeAlpha)
                if bubbleData.portrait then
                    bubbleData.portrait:SetAlpha(fadeAlpha)
                end
            end
        else
            -- Fully visible
            bubble:SetAlpha(1.0)
            if bubbleData.portrait then
                bubbleData.portrait:SetAlpha(1.0)
            end
        end
    end

    -- Remove faded bubbles and return to pool
    for i = #toRemove, 1, -1 do
        local idx = toRemove[i]
        local bubbleData = self.bubbles[idx]
        self:_ReturnBubbleFrame(bubbleData.frame)
        table.remove(self.bubbles, idx)
    end

    -- Reposition remaining bubbles
    for idx, bubbleData in ipairs(self.bubbles) do
        local bubbleHeight = bubbleData.frame:GetHeight()
        local yOffset = (idx - 1) * (bubbleHeight + 8)
        bubbleData.frame:SetPoint("TOP", self.root.frame, "TOP", 0, yOffset)
    end

    -- Stop update if no bubbles
    if #self.bubbles == 0 and self._updateHandler then
        self._updateHandler:SetScript("OnUpdate", nil)
        self._updateHandler = nil
    end
end

function SpeechBubbleWidget:Show()
    -- Check profile setting - never show if disabled
    local profile = RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive and RPE.Profile.DB.GetOrCreateActive()
    if profile and not profile.showTalkingHeads then
        return
    end
    
    if self.root and self.root.Show then self.root:Show() end
end

function SpeechBubbleWidget:Hide()
    if self.root and self.root.Hide then self.root:Hide() end
end

-- ====== boilerplate ======

function SpeechBubbleWidget.New(opts)
    local self = setmetatable({}, SpeechBubbleWidget)
    self:BuildUI(opts or {})
    return self
end

return SpeechBubbleWidget
