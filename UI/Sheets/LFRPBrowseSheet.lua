-- RPE_UI/Sheets/LFRPBrowseSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local Table    = RPE_UI.Elements.Table
local C        = RPE_UI.Colors

---@class LFRPBrowseSheet
---@field sheet VGroup
---@field table Table
---@field pageText Text
---@field currentPage number
---@field entriesPerPage number
---@field allData table
local LFRPBrowseSheet = {}
_G.RPE_UI.Windows.LFRPBrowseSheet = LFRPBrowseSheet
LFRPBrowseSheet.__index = LFRPBrowseSheet
LFRPBrowseSheet.Name = "LFRPBrowseSheet"

-- unique id helper
local _uid = 0
local function _name(prefix) _uid=_uid+1; return string.format("%s_%04d", prefix or "RPE_LFRP_Browse", _uid) end

function LFRPBrowseSheet.New(opts)
    local self = setmetatable({}, LFRPBrowseSheet)
    opts = opts or {}

    self.currentPage = 1
    self.entriesPerPage = 10
    self.allData = {}

    -- Root VGroup for the sheet
    self.sheet = VGroup:New("RPE_LFRP_BrowseSheet", {
        parent     = opts.parent,
        width      = 1, height = 1,
        point      = "TOP", relativePoint = "TOP",
        padding    = { left = 0, right = 0, top = 20, bottom = 20 },
        spacingY   = 10,
        alignH     = "CENTER",
        autoSize   = true,
    })

    -- === Title ===
    local titleText = Text:New(_name("RPE_LFRP_BrowseTitle"), {
        parent = self.sheet,
        text = RPE.Common.InlineIcons.RPE ..  " Looking for RP",
        fontTemplate = "GameFontNormalLarge",
    })
    if titleText.frame then
        titleText.frame:SetWidth(900)
        titleText.fs:SetJustifyH("CENTER")
    end
    self.sheet:Add(titleText)

    -- === Table ===
    self.table = Table:New(_name("RPE_LFRP_BrowseTable"), {
        parent = self.sheet,
        width = 900,
        height = 350,
    })
    self.table:SetColumns({
        { key = "trpName", title = "Name", width = 120 },
        { key = "guildName", title = "Guild", width = 120 },
        { key = "zoneName", title = "Zone", width = 120 },
        { key = "iAmStr", title = "I am", width = 180 },
        { key = "lookingForStr", title = "Looking for", width = 180 },
        { key = "recruitingStr", title = "Status", width = 100 },
    })
    self.sheet:Add(self.table)

    -- === Pagination Controls ===
    local paginationHGroup = HGroup:New(_name("RPE_LFRP_BrowsePagination"), {
        parent = self.sheet,
        spacingX = 12,
        alignH = "CENTER",
        alignV = "CENTER",
        autoSize = true,
    })
    self.sheet:Add(paginationHGroup)

    local prevBtn = TextBtn:New(_name("RPE_LFRP_BrowsePrevBtn"), {
        parent = paginationHGroup,
        width = 80,
        height = 28,
        text = "< Previous",
        noBorder = false,
        onClick = function()
            self:PreviousPage()
        end,
    })
    paginationHGroup:Add(prevBtn)

    self.pageText = Text:New(_name("RPE_LFRP_BrowsePageText"), {
        parent = paginationHGroup,
        text = "Page 1 of 1",
        fontTemplate = "GameFontNormal",
    })
    paginationHGroup:Add(self.pageText)

    local nextBtn = TextBtn:New(_name("RPE_LFRP_BrowseNextBtn"), {
        parent = paginationHGroup,
        width = 80,
        height = 28,
        text = "Next >",
        noBorder = false,
        onClick = function()
            self:NextPage()
        end,
    })
    paginationHGroup:Add(nextBtn)

    local closeBtn = TextBtn:New(_name("RPE_LFRP_BrowseCloseBtn"), {
        parent = paginationHGroup,
        width = 80,
        height = 28,
        text = "Close",
        noBorder = false,
        onClick = function()
            local win = RPE_UI.Common:GetWindow("LFRPBrowseWindow")
            if win then
                RPE_UI.Common:Toggle(win)
            end
        end,
    })
    paginationHGroup:Add(closeBtn)

    -- Register for data change notifications from PinManager
    local LFRP = RPE and RPE.Core and RPE.Core.LFRP
    local PinManager = LFRP and LFRP.PinManager
    if PinManager and PinManager.OnDataChange then
        PinManager:OnDataChange(function()
            self:RefreshData()
        end)
    end

    -- Initial refresh
    self:RefreshData()

    return self
end

--- Build label strings from choice IDs
function LFRPBrowseSheet:_buildLabelString(idArray, choiceTable)
    if not idArray or #idArray == 0 then
        return ""
    end
    
    local labels = {}
    for _, id in ipairs(idArray) do
        if id and id > 0 then
            local label = self:_getLabelForId(id, choiceTable)
            if label then
                table.insert(labels, label)
            end
        end
    end
    
    return table.concat(labels, ", ")
end

--- Get label for a choice ID
function LFRPBrowseSheet:_getLabelForId(id, choiceTable)
    if not choiceTable then return nil end
    
    for _, category in ipairs(choiceTable) do
        if category.choices then
            for _, choice in ipairs(category.choices) do
                if choice.id == id then
                    return choice.label
                end
            end
        end
    end
    return nil
end

--- Convert mapID to zone name
function LFRPBrowseSheet:_getZoneName(mapID)
    if not mapID then return "Unknown" end
    
    local mapInfo = C_Map.GetMapInfo(mapID)
    if mapInfo and mapInfo.name then
        return mapInfo.name
    end
    
    return "Unknown"
end

--- Refresh data from PinManager
function LFRPBrowseSheet:RefreshData()
    -- Get locationData from PinManager
    local LFRP = RPE and RPE.Core and RPE.Core.LFRP
    local PinManager = LFRP and LFRP.PinManager
    
    if not PinManager then
        self.allData = {}
        self:DisplayPage()
        return
    end
    
    -- Access locationData through a getter or direct access
    -- For now, we'll need to add a getter to PinManager
    local locationData = PinManager:GetLocationData()
    if not locationData then
        self.allData = {}
        self:DisplayPage()
        return
    end
    
    -- Build display data
    local Common = RPE and RPE.Common
    local iAmChoices = Common and Common.I_Am_Choices or {}
    local lookingForChoices = Common and Common.Looking_For_Choices or {}
    
    self.allData = {}
    
    -- Get local player info
    local localPlayerName = UnitName("player")
    local localPlayerGuild = GetGuildInfo("player")
    
    for _, poi in ipairs(locationData) do
        local displayName = poi.trpName and poi.trpName ~= "" and poi.trpName or poi.sender or "Unknown"
        local guildName = poi.guildName and poi.guildName ~= "" and poi.guildName or "—"
        local zoneName
        local isHidden = false
        
        if poi.broadcastLocation then
            zoneName = self:_getZoneName(poi.mapID)
        else
            zoneName = "(Hidden)"
            isHidden = true
        end
        
        local iAmStr = self:_buildLabelString(poi.iAm, iAmChoices)
        
        -- Add "Approachable" tag to iAm if applicable
        if poi.approachable == 1 then
            if iAmStr ~= "" then
                iAmStr = iAmStr .. ", Approachable"
            else
                iAmStr = "Approachable"
            end
        end
        
        local lookingForStr = self:_buildLabelString(poi.lookingFor, lookingForChoices)
        
        local recruitingStr = "Not recruiting"
        if poi.recruiting == 1 then
            recruitingStr = "Recruiting"
        elseif poi.recruiting == 2 then
            recruitingStr = "Recruitable"
        end
        
        -- Determine row color
        local rowColor = nil
        local isLocalPlayer = false
        if localPlayerName and poi.sender and poi.sender:match("^" .. localPlayerName:gsub("-", "%%-")) then
            -- This is the local player
            rowColor = "textModified"
            isLocalPlayer = true
        elseif localPlayerGuild and guildName ~= "—" and guildName == localPlayerGuild then
            -- This is a guild member
            rowColor = "textBonus"
        end
        
        table.insert(self.allData, {
            trpName = displayName,
            guildName = guildName,
            zoneName = zoneName,
            iAmStr = iAmStr ~= "" and iAmStr or "—",
            lookingForStr = lookingForStr ~= "" and lookingForStr or "—",
            recruitingStr = recruitingStr,
            rowColor = rowColor,
            isLocalPlayer = isLocalPlayer,
            isHidden = isHidden,
        })
    end
    
    -- Sort by: local player first, then zone (hidden last), then guild
    table.sort(self.allData, function(a, b)
        -- Local player always first
        if a.isLocalPlayer and not b.isLocalPlayer then return true end
        if b.isLocalPlayer and not a.isLocalPlayer then return false end
        
        -- Hidden players always last
        if a.isHidden and not b.isHidden then return false end
        if b.isHidden and not a.isHidden then return true end
        
        -- Then sort by zone
        if a.zoneName ~= b.zoneName then
            return a.zoneName < b.zoneName
        end
        
        -- Then sort by guild
        if a.guildName ~= b.guildName then
            return a.guildName < b.guildName
        end
        
        -- Then sort by name
        return a.trpName < b.trpName
    end)
    
    -- Reset to first page
    self.currentPage = 1
    self:DisplayPage()
end

--- Display the current page
function LFRPBrowseSheet:DisplayPage()
    local startIdx = (self.currentPage - 1) * self.entriesPerPage + 1
    local endIdx = math.min(startIdx + self.entriesPerPage - 1, #self.allData)
    
    local pageData = {}
    for i = startIdx, endIdx do
        if self.allData[i] then
            table.insert(pageData, self.allData[i])
        end
    end
    
    self.table:SetRows(pageData)
    self.table:Refresh()
    
    -- Update page text
    local totalPages = math.max(1, math.ceil(#self.allData / self.entriesPerPage))
    self.pageText:SetText(string.format("Page %d of %d", self.currentPage, totalPages))
end

--- Go to next page
function LFRPBrowseSheet:NextPage()
    local totalPages = math.max(1, math.ceil(#self.allData / self.entriesPerPage))
    if self.currentPage < totalPages then
        self.currentPage = self.currentPage + 1
        self:DisplayPage()
    end
end

--- Go to previous page
function LFRPBrowseSheet:PreviousPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:DisplayPage()
    end
end

function LFRPBrowseSheet:Show()
    if self.sheet and self.sheet.Show then
        self.sheet:Show()
        self:RefreshData()  -- Refresh when showing
    end
end

function LFRPBrowseSheet:Hide()
    if self.sheet and self.sheet.Hide then
        self.sheet:Hide()
    end
end

return LFRPBrowseSheet
