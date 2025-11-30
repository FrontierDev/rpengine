-- RPE_UI/Windows/Ruleset.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}

local Window   = RPE_UI.Elements.Window
local HGroup   = RPE_UI.Elements.HorizontalLayoutGroup
local VGroup   = RPE_UI.Elements.VerticalLayoutGroup
local Text     = RPE_UI.Elements.Text
local TextBtn  = RPE_UI.Elements.TextButton
local IconBtn  = RPE_UI.Elements.IconButton
local FrameElement = RPE_UI.Elements.FrameElement

-- Data layer
local RulesetDB      = RPE.Profile and RPE.Profile.RulesetDB
local RulesetProfile = RPE.Profile and RPE.Profile.RulesetProfile

---@class Ruleset
---@field Name string
---@field root Window
---@field sheet VGroup
---@field header HGroup
---@field body VGroup
---@field footer HGroup
---@field title Text
---@field active RulesetProfile|nil
---@field rows table[]
---@field page number
local Ruleset = {}
_G.RPE_UI.Windows.Ruleset = Ruleset
Ruleset.__index = Ruleset
Ruleset.Name = "Ruleset"

-- ---- Local EditField (simple EditBox wrapper) ------------------------------
---@class EditField: FrameElement
---@field edit EditBox
local EditField = setmetatable({}, { __index = FrameElement })
EditField.__index = EditField

local function _ApplyBoxLook(box)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontNormal")
    box:SetJustifyH("LEFT")
    box:SetTextInsets(6, 6, 3, 3)
end

function EditField:New(name, opts)
    opts = opts or {}
    local parentFrame = (opts.parent and opts.parent.frame) or UIParent
    local f = CreateFrame("EditBox", name, parentFrame, "InputBoxTemplate")
    f:SetSize(opts.width or 160, opts.height or 22)
    f:SetAutoFocus(false)
    f:SetMultiLine(false)
    _ApplyBoxLook(f)
    if opts.text then f:SetText(tostring(opts.text)) end
    local o = FrameElement.New(self, "EditField", f, opts.parent)
    o.edit = f
    f:SetScript("OnEnterPressed", function() f:ClearFocus(); if opts.onCommit then opts.onCommit(o,f:GetText()) end end)
    f:SetScript("OnEditFocusLost", function() if opts.onCommit then opts.onCommit(o,f:GetText()) end end)
    return o
end
function EditField:SetText(t) self.edit:SetText(t or "") end
function EditField:GetText() return self.edit:GetText() end

-- ---------------------------------------------------------------------------

function Ruleset:BuildUI(opts)
    opts = opts or {}
    self.root = Window:New("RPE_RS_Window", {
        width  = opts.width  or 480,
        height = opts.height or 480,
        point  = opts.point  or "CENTER",
        x = opts.x or 0, y = opts.y or 0,
        autoSize = false,
    })
    self.sheet = VGroup:New("RPE_RS_Sheet", {
        parent = self.root,
        width = 1, height = 1,
        point = "TOP", relativePoint = "TOP",
        padding = { left=0,right=0,top=12,bottom=12 },
        spacingY = 12, alignH="CENTER", autoSize=true,
    })

    self:HeaderGroup()
    self.sheet:Add(self.header)

    self:BodyGroup()
    self.sheet:Add(self.body)

    self:FooterGroup()

    self.page = 1

    -- when the window shows, ensure we load the current active ruleset
    self.root.frame:HookScript("OnShow", function()
        local rs = RulesetDB and RulesetDB.LoadActiveForCurrentCharacter and RulesetDB.LoadActiveForCurrentCharacter()
        if rs then
            self:SetRuleset(rs)
        else
            self:RefreshRuleList()
        end
    end)


    if _G.RPE_UI and _G.RPE_UI.Common then
        RPE.Debug:Internal("Registering Ruleset window...")
        RPE_UI.Common:RegisterWindow(self)
    else
        RPE.Debug:Error("RPE_UI.Common not found; Ruleset window not registered.")
    end
end


function Ruleset:HeaderGroup()
    self.header = HGroup:New("RPE_RS_Header", {
        parent=self.sheet, width=680, height=28,
        spacingX=12, alignV="CENTER", autoSize=true,
    })
    self.newRulesetBtn = TextBtn:New("RPE_RS_NewRulesetBtn", {
        parent=self.header,width=120,height=24,text="New Ruleset",
        onClick=function() self:CreateAndActivateRuleset() end,
    })
    self.loadRulesetBtn = TextBtn:New("RPE_RS_LoadRulesetBtn", {
        parent=self.header,width=120,height=24,text="Load Ruleset",
        onClick=function() RPE.Debug:NYI("Ruleset load dialog.") end,
    })
    self.saveRulesetBtn = TextBtn:New("RPE_RS_SaveRulesetBtn", {
        parent=self.header,width=120,height=24,text="Save Ruleset",
        onClick=function()
            if self.active then RulesetDB.Save(self.active) end
        end,
    })
    self.header:Add(self.newRulesetBtn)
    self.header:Add(self.loadRulesetBtn)
    self.header:Add(self.saveRulesetBtn)
end

function Ruleset:BodyGroup()
    self.body = VGroup:New("RPE_RS_Body", {
        parent=self.sheet, width=680,
        alignH="LEFT", autoSize=true,
    })
    self.rows = {}
end

function Ruleset:FooterGroup()
    self.footer = HGroup:New("RPE_RS_Footer", {
        parent = self.root,       -- anchor directly to window, not sheet
        width = 480,
        height = 28,
        spacingX = 12,
        alignV = "CENTER",
        autoSize = true,
        point = "BOTTOM",         -- anchor to bottom of window
        relativePoint = "BOTTOM",
        x = 0, y = 12,
    })

    self.prevBtn = TextBtn:New("RPE_RS_PrevBtn", {
        parent=self.footer,width=80,height=24,text="Prev",
        onClick=function()
            if self.page>1 then self.page=self.page-1; self:RefreshRuleList() end
        end,
    })
    self.pageLabel = Text:New("RPE_RS_PageLabel", {
        parent=self.footer,text="Page 1/1",fontTemplate="GameFontNormal",
    })
    self.nextBtn = TextBtn:New("RPE_RS_NextBtn", {
        parent=self.footer,width=80,height=24,text="Next",
        onClick=function()
            if self.page<self.totalPages then self.page=self.page+1; self:RefreshRuleList() end
        end,
    })
    self.addBtn = TextBtn:New("RPE_RS_AddRuleBtn", {
        parent=self.footer,width=140,height=24,text="Add Rule",
        onClick=function()
            if not self.active then return end
            local base,n,newKey="NewRule",1,"NewRule"
            while self.active.rules[newKey]~=nil do
                n=n+1; newKey=base..n
            end
            self.active.rules[newKey]="" 
            RulesetDB.Save(self.active)
            self:RefreshRuleList()
        end
    })

    -- always show page controls, even if no ruleset
    self.footer:Add(self.prevBtn)
    self.footer:Add(self.pageLabel)
    self.footer:Add(self.nextBtn)
    self.footer:Add(self.addBtn)
end


-- ---------------------------------------------------------------------------

function Ruleset:CreateAndActivateRuleset()
    if not RulesetDB then return end

    -- Generate a unique name like "Ruleset HHMMSS"
    local suffix = date("%H%M%S")
    local base   = "Ruleset " .. suffix
    local name   = base
    local idx    = 1
    while RulesetDB.GetByName(name) do
        idx  = idx + 1
        name = base .. " (" .. idx .. ")"
    end

    -- Create, save, and mark as active for this character
    local rs = RulesetDB.CreateNew(name, { rules = {} })
    RulesetDB.Save(rs)
    RulesetDB.SetActiveForCurrentCharacter(rs.name)

    if RPE.ActiveRules then
        RPE.ActiveRules:SetRuleset(rs)
    end

    -- Activate in the UI
    self.active = rs
    self.page   = 1
    self:RefreshRuleList()
end

function Ruleset:SetRuleset(profileOrTable)
    if not profileOrTable then return end
    if getmetatable(profileOrTable) == RulesetProfile then
        self.active = profileOrTable
    elseif type(profileOrTable) == "table" then
        self.active = RulesetProfile.FromTable(profileOrTable)
    end
    if self.active then
        -- Remember as active for this character
        RulesetDB.SetActiveForCurrentCharacter(self.active.name)
        -- self.title:SetText(("Ruleset — %s"):format(self.active.name))
    end
    self:RefreshRuleList()
end

function Ruleset:RefreshRuleList()
    for i=#self.body.children,1,-1 do
        local c=self.body.children[i]
        if c.Destroy then c:Destroy() end
        table.remove(self.body.children,i)
    end
    self.rows={}

    if not self.active then
        local hint=Text:New("RPE_RS_NoActiveHint",{
            parent=self.body,
            text="No active ruleset. Click 'New Ruleset' to begin.",
            fontTemplate="GameFontDisable",justifyH="LEFT",
        })
        self.body:Add(hint)
        self.addBtn:Hide()
        self.pageLabel:SetText("Page 0/0")
        return
    end

    self.addBtn:Show()

    local keys={}
    for k in pairs(self.active.rules or {}) do table.insert(keys,k) end
    table.sort(keys)
    local total=#keys
    local perPage=11
    self.totalPages=math.max(1,math.ceil(total/perPage))
    if self.page>self.totalPages then self.page=self.totalPages end
    local start=(self.page-1)*perPage+1
    local finish=math.min(start+perPage-1,total)

    local keyW,valW=120,360

    if total>0 then
        local header=HGroup:New("RPE_RS_ListHeader",{
            parent=self.body,width=680,height=20,
            alignV="CENTER",spacingX=8,autoSize=true,
        })
        local hdrKey=Text:New("RPE_RS_ColKey",{parent=header,text="Rule",width=keyW,height=20,fontTemplate="GameFontHighlightSmall",justifyH="LEFT"})
        local hdrVal=Text:New("RPE_RS_ColValue",{parent=header,text="Value",width=valW,height=20,fontTemplate="GameFontHighlightSmall",justifyH="LEFT"})
        header:Add(hdrKey); header:Add(hdrVal)
        self.body:Add(header)
    end

    for i=start,finish do
        local key=keys[i]
        local val=self.active.rules[key]
        local row=HGroup:New("RPE_RS_RuleRow_"..key,{
            parent=self.body,width=680,height=24,
            spacingX=8,alignV="CENTER",autoSize=true,
        })
        local keyField=EditField:New("RPE_RS_Key_"..key,{
            parent=row,width=keyW,height=22,text=tostring(key),
            onCommit=function(_,newKey)
                newKey=(newKey or ""):gsub("^%s*(.-)%s*$","%1")
                if newKey=="" or newKey==key then return end
                if not self.active.rules[newKey] then
                    self.active.rules[newKey]=self.active.rules[key]
                    self.active.rules[key]=nil
                    RulesetDB.Save(self.active)
                    self:RefreshRuleList()
                end
            end
        })
        local valField=EditField:New("RPE_RS_Val_"..key,{
            parent=row,width=valW,height=22,text=tostring(val),
            onCommit=function(_,newVal) self.active.rules[key]=newVal; RulesetDB.Save(self.active) end
        })
        local removeBtn = IconBtn:New("RPE_RS_Remove_"..key, {
            parent = row,
            width = 22, height = 22,
            noBackground = true,
            icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", -- or any icon path you like
            onClick = function()
                self.active.rules[key] = nil
                RulesetDB.Save(self.active)
                self:RefreshRuleList()
            end
        })

        row:Add(keyField)
        row:Add(valField)
        row:Add(removeBtn)
        self.body:Add(row)

        table.insert(self.rows, { row=row, keyField=keyField, valField=valField, removeBtn=removeBtn })
    end

    self.pageLabel:SetText(("Page %d/%d"):format(self.page,self.totalPages))
end

function Ruleset.New(opts)
    local self=setmetatable({},Ruleset)
    self:BuildUI(opts or {})
    return self
end
