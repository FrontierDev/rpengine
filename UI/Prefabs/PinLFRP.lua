-- RPE_UI/Prefabs/PinLFRP.lua
-- Pin prefab for location-based roleplay map markers

RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local FrameElement = RPE_UI.Elements.FrameElement

---@class PinLFRP: FrameElement
---@field icon Texture
---@field label Text
local PinLFRP = setmetatable({}, { __index = FrameElement })
PinLFRP.__index = PinLFRP
RPE_UI.Prefabs.PinLFRP = PinLFRP

-- Build lookup tables for ID -> label mapping
local function _buildChoiceLookup(choicesTable)
    local lookup = {}
    for _, category in ipairs(choicesTable) do
        if category.choices then
            for _, choice in ipairs(category.choices) do
                if choice.id and choice.label then
                    lookup[choice.id] = choice.label
                end
            end
        end
    end
    return lookup
end

function PinLFRP:New(name, opts)
    opts = opts or {}
    
    local width = opts.width or 16
    local height = opts.height or 16
    local poiInfo = opts.poiInfo or {}
    local cluster = opts.cluster or nil
    local currentPlayerIndex = opts.currentPlayerIndex or 1

    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(width, height)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)

    ---@type PinLFRP
    local o = FrameElement.New(self, "PinLFRP", f, opts.parent)

    -- Icon
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(f)
    icon:SetTexture(poiInfo.icon or "Interface\\Addons\\RPEngine\\UI\\Textures\\rpe.png")
    o.icon = icon

    -- Store cluster and current player index
    o.cluster = cluster
    o.currentPlayerIndex = currentPlayerIndex

    -- Count label (only show if cluster has >1 member)
    if cluster and #cluster.members > 1 then
        local countLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countLabel:SetPoint("CENTER", f, "CENTER", 0, 0)
        countLabel:SetText(tostring(#cluster.members))
        countLabel:SetTextColor(1.0, 1.0, 1.0)
        o.countLabel = countLabel
    end

    -- Optional label for single poi (not used for clusters)
    if poiInfo.name and not cluster then
        local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOM", f, "TOP", 0, 2)
        label:SetText(poiInfo.name)
        o.label = label
    end

    o.poiInfo = poiInfo

    -- Hover tooltip showing LFRP settings
    f:SetScript("OnEnter", function()
        o:ShowTooltip()
    end)
    
    f:SetScript("OnLeave", function()
        o:HideTooltip()
    end)

    -- Left and right click to cycle through cluster members
    if cluster then
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                o:CycleToNextPlayer(1)
            elseif button == "RightButton" then
                o:CycleToPreviousPlayer(1)
            end
        end)
    end

    return o
end

function PinLFRP:CycleToNextPlayer(direction)
    if not self.cluster or #self.cluster.members <= 1 then return end
    
    self.currentPlayerIndex = self.currentPlayerIndex + direction
    if self.currentPlayerIndex > #self.cluster.members then
        self.currentPlayerIndex = 1
    end
    
    self:ShowTooltip()
end

function PinLFRP:CycleToPreviousPlayer(direction)
    if not self.cluster or #self.cluster.members <= 1 then return end
    
    self.currentPlayerIndex = self.currentPlayerIndex - direction
    if self.currentPlayerIndex < 1 then
        self.currentPlayerIndex = #self.cluster.members
    end
    
    self:ShowTooltip()
end

function PinLFRP:ShowTooltip()
    local Common = RPE and RPE.Common
    if not Common or not Common.ShowTooltip then return end
    
    -- If this is a cluster, get the current player being viewed
    local poi
    if self.cluster then
        if not self.currentPlayerIndex or self.currentPlayerIndex < 1 then
            self.currentPlayerIndex = 1
        end
        if self.currentPlayerIndex > #self.cluster.members then
            self.currentPlayerIndex = #self.cluster.members
        end
        poi = self.cluster.members[self.currentPlayerIndex]
    else
        poi = self.poiInfo
    end
    
    if not poi then return end
    
    local senderName = poi.trpName and poi.trpName ~= "" and poi.trpName or poi.sender or "Unknown"
    
    -- Build lookup tables from Common choice definitions
    local function _buildIDLookup(choicesTable)
        local lookup = {}
        for _, category in ipairs(choicesTable) do
            if category.choices then
                for _, choice in ipairs(category.choices) do
                    if choice.id and choice.label then
                        lookup[choice.id] = choice.label
                    end
                end
            end
        end
        return lookup
    end
    
    local iAmLookup = _buildIDLookup(Common.I_Am_Choices or {})
    local lookingForLookup = _buildIDLookup(Common.Looking_For_Choices or {})
    
    -- Build tooltip spec
    local spec = {
        title = senderName,
        lines = {},
    }
    
    -- Add guild name if available
    if poi.guildName and poi.guildName ~= "" then
        table.insert(spec.lines, {
            text = "<" .. poi.guildName .. ">",
            r = 1.0, g = 0.8, b = 0.0,
        })
    end
    
    -- Add event name if available
    if poi.eventName and poi.eventName ~= "" then
        table.insert(spec.lines, {
            text = " ",
        })
        table.insert(spec.lines, {
            left = "In Event:",
            right = poi.eventName,
            r = 0, g = 1, b = 0,
        })
        table.insert(spec.lines, {
            text = " ",
        })
    end
    
    -- Add iAm selections one per line
    if poi.iAm and #poi.iAm > 0 then
        local hasLabel = false
        for idx, id in ipairs(poi.iAm) do
            if id and id > 0 then
                local label = iAmLookup[id] or tostring(id)
                
                if not hasLabel then
                    table.insert(spec.lines, {
                        text = "I am:",
                        r = 1.0, g = 1.0, b = 1.0,
                    })
                    hasLabel = true
                end
                
                table.insert(spec.lines, {
                    text = "  • " .. label,
                    r = 0.8, g = 0.8, b = 0.8,
                })
            end
        end
    end
    
    -- Add lookingFor selections one per line
    if poi.lookingFor and #poi.lookingFor > 0 then
        local hasLabel = false
        for idx, id in ipairs(poi.lookingFor) do
            if id and id > 0 then
                local label = lookingForLookup[id] or tostring(id)
                
                if not hasLabel then
                    table.insert(spec.lines, {
                        text = "Looking for:",
                        r = 1.0, g = 1.0, b = 1.0,
                    })
                    hasLabel = true
                end
                
                table.insert(spec.lines, {
                    text = "  • " .. label,
                    r = 0.8, g = 0.8, b = 0.8,
                })
            end
        end
    end
    
    if poi.recruiting then
        local recruitingText = "Not recruiting"
        if poi.recruiting == 1 then
            recruitingText = "Recruiting"
        elseif poi.recruiting == 2 then
            recruitingText = "Recruitable"
        end
        table.insert(spec.lines, {
            left = "Guild Status:",
            right = recruitingText,
            r = 0.8, g = 0.8, b = 0.8,
        })
    end
    
    if poi.approachable then
        local approachableText = poi.approachable == 1 and "Yes" or "No"
        table.insert(spec.lines, {
            left = "Approachable:",
            right = approachableText,
            r = 0.8, g = 0.8, b = 0.8,
        })
    end
    
    -- Add cluster indicator at the bottom if in a cluster
    if self.cluster and #self.cluster.members > 1 then
        table.insert(spec.lines, {
            text = " ",
        })
        table.insert(spec.lines, {
            text = string.format("Player %d of %d", self.currentPlayerIndex, #self.cluster.members),
            r = 0.6, g = 0.6, b = 0.6,
        })
        table.insert(spec.lines, {
            text = "<LMB/RMB to Cycle>",
            r = 0.6, g = 0.6, b = 0.6,
        })
    end

        -- Add RPE version or developer status at the bottom
    if poi.dev then
        table.insert(spec.lines, {
            text = " ",
        })
        table.insert(spec.lines, {
            text = "RPE Developer",
            r = 1.0, g = 0.84, b = 0.0,
        })
    else
        table.insert(spec.lines, {
            text = " ",
        })
        table.insert(spec.lines, {
            text = "RPE v" .. (poi.addonVersion or "unknown"),
            r = 0.6, g = 0.6, b = 0.6,
        })
    end
    
    
    Common:ShowTooltip(self.frame, spec)
end

function PinLFRP:HideTooltip()
    local Common = RPE and RPE.Common
    if Common and Common.HideTooltip then
        Common:HideTooltip()
    end
end

return PinLFRP
