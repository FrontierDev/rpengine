-- RPE_UI/Sheets/RecipeEditorSheet.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Elements = RPE_UI.Elements or {}
RPE_UI.Windows  = RPE_UI.Windows or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}

local VGroup  = RPE_UI.Elements.VerticalLayoutGroup
local HGroup  = RPE_UI.Elements.HorizontalLayoutGroup
local Text    = RPE_UI.Elements.Text
local TextBtn = RPE_UI.Elements.TextButton
local Input   = RPE_UI.Elements.Input

local Common  = _G.RPE_UI and _G.RPE_UI.Common

---@class RecipeEditorSheet
local RecipeEditorSheet = {}
_G.RPE_UI.Windows.RecipeEditorSheet = RecipeEditorSheet
RecipeEditorSheet.__index = RecipeEditorSheet
RecipeEditorSheet.Name = "RecipeEditorSheet"

-- ==== Dataset helpers =======================================================

function RecipeEditorSheet:SetEditingDataset(name)
    if type(name) == "string" and name ~= "" then self.editingName = name else self.editingName = nil end
end

function RecipeEditorSheet:GetEditingDataset()
    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
    if not (DB and self.editingName) then return nil end
    for _, fname in ipairs({ "GetByName","GetByKey","Get" }) do
        local fn = DB[fname]
        if type(fn) == "function" then
            local ok, ds = pcall(fn, DB, self.editingName); if ok and ds then return ds end
            local ok2, ds2 = pcall(fn, self.editingName);  if ok2 and ds2 then return ds2 end
        end
    end
    return nil
end

function RecipeEditorSheet:OnDatasetEditChanged(name)
    self:SetEditingDataset(name)
    self._page = 1
    if self.Refresh then self:Refresh() end
end

-- ==== Helpers ===============================================================
local function _trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end
local function _newGUID(prefix) return (Common and Common.GenerateGUID and Common:GenerateGUID(prefix or "REC")) or string.format("%s-%04x%04x", prefix or "REC", math.random(0,0xFFFF), math.random(0,0xFFFF)) end

local function _recipesBucket(ds) return (ds and ds.extra and ds.extra.recipes) or {} end

local function _collectRecipesSorted(ds)
    local list = {}
    for id, t in pairs(_recipesBucket(ds)) do
        t = t or {}
        list[#list+1] = {
            id           = id,
            name         = t.name or id,
            profession   = t.profession or "Unknown",
            category     = t.category or "Basics",
            outputItemId = t.outputItemId or "(none)",
            skill        = tonumber(t.skill) or 0,
            quality      = t.quality or "common",
        }
    end
    table.sort(list, function(a,b)
        local an, bn = tostring(a.name or ""):lower(), tostring(b.name or ""):lower()
        if an ~= bn then return an < bn end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

local function _updatePageText(self, totalPages, totalFiltered)
    totalPages = math.max(1,totalPages or 1)
    local cur  = math.max(1,math.min(self._page or 1,totalPages))
    if self.pageText and self.pageText.SetText then
        local count = tonumber(totalFiltered or 0) or 0
        self.pageText:SetText(("Page %d / %d  ·  %d result%s"):format(cur,totalPages,count,(count==1) and "" or "s"))
    end
end

-- ==== Save helper ===========================================================
local function _saveRecipe(ds, recipeId, v)
    if not (ds and recipeId and v) then return nil end
    ds.extra = ds.extra or {}; ds.extra.recipes = ds.extra.recipes or {}
    ds.extra.recipes[recipeId] = {
        id           = recipeId,
        name         = _trim(v.name or recipeId),
        profession   = v.profession or "Blacksmithing",
        category     = v.category or "Basics",
        skill        = tonumber(v.skill) or 1,
        quality      = v.quality or "uncommon",
        outputItemId = v.outputItemId or "item_placeholder",
        outputQty    = tonumber(v.outputQty) or 1,
        tools        = v.tools or { "Hammer","Anvil" },
        reagents     = v.reagents or { {id="copper_bar", qty=2}, {id="rough_stone", qty=1} },
        optional     = v.optional or {},
        cost         = (function()
            local costTbl = {}
            if type(v.cost) == "table" then
                for _, entry in ipairs(v.cost) do
                    if entry.key and entry.value then
                        costTbl[entry.key] = tonumber(entry.value) or entry.value
                    end
                end
            end
            return costTbl
        end)(),
    }
    return recipeId
end

-- ==== Wizard schema =========================================================
local function _buildEditSchema(recipeId, def)
    def = def or {}
    return {
        title="Edit Recipe: "..tostring(recipeId),
        pages={
            { title="Basics", elements={
                { id="name",       label="Name",        type="input",  default=def.name or recipeId, required=true },
                { id="profession", label="Profession",  type="select",
                  choices={"Alchemy","Blacksmithing","Cooking","Enchanting","Engineering","First Aid","Fishing","Herbalism","Leatherworking","Mining","Skinning","Tailoring"},
                  default=def.profession or "Blacksmithing" },
                { id="category",   label="Category",    type="input",  default=def.category or "Basics" },
                { id="skill",      label="Skill Req",   type="number", default=tonumber(def.skill) or 1 },
                { id="quality",    label="Quality",     type="select",
                  choices={"common","uncommon","rare","epic","legendary"}, default=def.quality or "uncommon" },
            }},
            { title="Output", elements={
                { id="outputItemId", label="Output Item Id", type="lookup", pattern="^item%-[a-fA-F0-9]+$", default=def.outputItemId or "item-placeholder" },
                { id="outputQty",    label="Output Qty",    type="number", default=tonumber(def.outputQty) or 1 },
            }},
            { title="Reagents", elements={
                { id="reagents", label="Reagents", type="editor_table",
                  columns={{id="id",header="Item Id",type="lookup",pattern="^item%-[a-fA-F0-9]+$",width=240},{id="qty",header="Qty",type="number",width=60}},
                  default=def.reagents or {} },
            }},
            { title="Optional Reagents", elements={
                { id="optional", label="Optional", type="editor_table",
                  columns={{id="id",header="Item Id",type="lookup",pattern="^item%-[a-fA-F0-9]+$",width=240},{id="qty",header="Qty",type="number",width=60}},
                  default=def.optional or {} },
            }},
            { title="Tools", elements={
                { id="tools", label="Tools", type="list", default=def.tools or {"Hammer","Anvil"} },
            }},
            { title="Costs", elements={
                { id="cost", label="Recipe Costs", type="editor_table",
                  columns = {
                      { id="key",   header="Type / Item Id", type="lookup", pattern="^item%-[a-fA-F0-9]+$", width=240 },
                      { id="value", header="Amount",         type="number", width=80 },
                  },
                  default = (function()
                      local t = {}
                      if def.cost and type(def.cost) == "table" then
                          for k, v in pairs(def.cost) do
                              table.insert(t, { key=k, value=v })
                          end
                      end
                      return t
                  end)(),
                },
            }},
        },
        labelWidth=150, navSaveAlways=true,
    }
end

-- ==== Row binding ===========================================================
local function _bindRow(self,row,entry)
    row._entry=entry
    if not row.frame then return end
    if not entry then if row.frame.Hide then row.frame:Hide() end return end
    if row.frame.Show then row.frame:Show() end
    if row._nameText and row._nameText.SetText then row._nameText:SetText(entry.name or entry.id) end
end

local function _buildRow(self, idx)
    local row = HGroup:New(("RPE_RecipeEditor_Row_%d"):format(idx), {
        parent  = self.list, width = 1, height = 24,
        spacingX = 10, alignV = "CENTER", alignH = "LEFT",
        autoSize = true,
    })
    self.list:Add(row)

    local nameText = Text:New(("RPE_RecipeEditor_RowName_%d"):format(idx), {
        parent = row, text = "—", fontTemplate = "GameFontNormal",
    })
    row:Add(nameText)
    row._nameText = nameText

    -- ... button (context menu trigger)
    local moreBtn = TextBtn:New(("RPE_RecipeEditor_RowMenu_%d"):format(idx), {
        parent = row, width = 28, height = 22, text = "...",
        hasBorder = false, noBorder = true,
        onClick = function()
            local entry = row._entry
            if not entry or not (Common and Common.ContextMenu) then return end

            Common:ContextMenu(row.frame or UIParent, function(level)
                if level ~= 1 then return end

                -- Title
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true; info.notCheckable = true
                info.text = entry.name or entry.id
                UIDropDownMenu_AddButton(info, level)

                -- Edit
                UIDropDownMenu_AddButton({
                    text = "Edit",
                    notCheckable = true,
                    func = function()
                        local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                        if DW and DW.ShowWizard then
                            local ds   = self:GetEditingDataset()
                            local full = (ds and ds.extra and ds.extra.recipes and ds.extra.recipes[entry.id]) or entry
                            DW:ShowWizard({
                                schema = _buildEditSchema(entry.id, full),
                                isEdit = true,
                                onSave = function(values)
                                    local ds2 = self:GetEditingDataset()
                                    local okId = _saveRecipe(ds2, entry.id, values)
                                    if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                        pcall(_G.RPE.Profile.DatasetDB.Save, ds2)
                                    end
                                    self:Refresh()
                                end,
                            })
                        end
                    end,
                }, level)

                -- Clone
                UIDropDownMenu_AddButton({
                    text = "Clone",
                    notCheckable = true,
                    func = function()
                        local newId = _newGUID("REC")
                        local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                        if DW and DW.ShowWizard then
                            local ds   = self:GetEditingDataset()
                            local full = (ds and ds.extra and ds.extra.recipes and ds.extra.recipes[entry.id]) or entry
                            DW:ShowWizard({
                                schema = _buildEditSchema(newId, full),
                                isEdit = false,
                                onSave = function(values)
                                    local ds2 = self:GetEditingDataset()
                                    local okId = _saveRecipe(ds2, newId, values)
                                    if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                                        pcall(_G.RPE.Profile.DatasetDB.Save, ds2)
                                    end
                                    self:Refresh()
                                end,
                            })
                        end
                    end,
                }, level)

                -- Delete
                UIDropDownMenu_AddButton({
                    text = "|cffff4040Delete Entry|r",
                    notCheckable = true,
                    func = function()
                        local ds = self:GetEditingDataset()
                        if not (ds and ds.extra and ds.extra.recipes and ds.extra.recipes[entry.id]) then return end
                        ds.extra.recipes[entry.id] = nil
                        if _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then
                            pcall(_G.RPE.Profile.DatasetDB.Save, ds)
                        end
                        self:Refresh()
                    end,
                }, level)
            end)
        end,
    })
    row:Add(moreBtn)
    row._moreBtn = moreBtn

    -- Right-click menu on entire row
    if row and row.frame and row.frame.HookScript then
        row.frame:HookScript("OnMouseDown", function(_, button)
            if button == "RightButton" and moreBtn and moreBtn.onClick then
                moreBtn.onClick()
            end
        end)
    end

    if row.frame and row.frame.Hide then row.frame:Hide() end
    return row
end


-- ==== Build UI ==============================================================
function RecipeEditorSheet:BuildUI(opts)
    opts=opts or {}
    self.parent=opts.parent; self.rowsPerPage=12; self._page=1; self._perPage=self.rowsPerPage; self._query=""
    self:SetEditingDataset(opts and opts.editingName)

    self.sheet=VGroup:New("RPE_RecipeEditor_Sheet",{parent=self.parent,width=1,height=1,point="TOP",relativePoint="TOP",x=0,y=0,padding={left=12,right=12,top=12,bottom=12},spacingY=10,alignV="TOP",alignH="CENTER",autoSize=true})

    -- Search bar
    self.searchBar=HGroup:New("RPE_RecipeEditor_SearchBar",{parent=self.sheet,width=1,spacingX=8,alignH="LEFT",alignV="CENTER",autoSize=true})
    self.searchBar:Add(Text:New("RPE_RecipeEditor_SearchLabel",{parent=self.searchBar,text="Search:",fontTemplate="GameFontNormalSmall"}))
    self.searchInput=Input:New("RPE_RecipeEditor_SearchInput",{parent=self.searchBar,width=220,placeholder="name, profession, item id...",onEnterPressed=function(value) self._query=_trim(value or ""); self._page=1; self:Refresh() end})
    self.searchBar:Add(self.searchInput)
    self.resultsText=Text:New("RPE_RecipeEditor_ResultsText",{parent=self.searchBar,text="",fontTemplate="GameFontNormalSmall"})
    local spacer=Text:New("RPE_RecipeEditor_SearchSpacer",{parent=self.searchBar,text="",width=1,height=1}); spacer.flex=1; self.searchBar:Add(spacer); self.searchBar:Add(self.resultsText)
    self.sheet:Add(self.searchBar)

    -- Nav (New + Pager)
    self.navWrap=HGroup:New("RPE_RecipeEditor_NavWrap",{parent=self.sheet,width=1,spacingX=10,alignV="CENTER",alignH="CENTER",autoSize=true})
    self.newBtn=TextBtn:New("RPE_RecipeEditor_New",{parent=self.navWrap,width=96,height=22,text="New Recipe",onClick=function()
        local DW=_G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
        if DW and DW.ShowWizard then
            local newId=_newGUID("REC")
            DW:ShowWizard({schema=_buildEditSchema(newId,{}),isEdit=false,onSave=function(values) local ds=self:GetEditingDataset(); local okId=_saveRecipe(ds,newId,values); if okId and _G.RPE.Profile and _G.RPE.Profile.DatasetDB.Save then pcall(_G.RPE.Profile.DatasetDB.Save,ds) end; self:Refresh() end})
        end
    end}); self.navWrap:Add(self.newBtn)

    self.pager=HGroup:New("RPE_RecipeEditor_Nav",{parent=self.navWrap,spacingX=10,alignV="CENTER",autoSize=true})
    self.prevBtn=TextBtn:New("RPE_RecipeEditor_Prev",{parent=self.pager,width=70,height=22,text="Prev",noBorder=true,onClick=function() self:_setPage((self._page or 1)-1) end})
    self.pager:Add(self.prevBtn)
    self.pageText=Text:New("RPE_RecipeEditor_PageText",{parent=self.pager,text="Page 1 / 1",fontTemplate="GameFontNormalSmall"})
    self.pager:Add(self.pageText)
    self.nextBtn=TextBtn:New("RPE_RecipeEditor_Next",{parent=self.pager,width=70,height=22,text="Next",noBorder=true,onClick=function() self:_setPage((self._page or 1)+1) end})
    self.pager:Add(self.nextBtn)
    self.navWrap:Add(self.pager); self.sheet:Add(self.navWrap)

    -- List
    self.list=VGroup:New("RPE_RecipeEditor_List",{parent=self.sheet,width=1,spacingY=8,alignV="TOP",alignH="LEFT",autoSize=true})
    self.sheet:Add(self.list)
    self._rows={}; for i=1,self._perPage do self._rows[i]=_buildRow(self,i) end

    self:Refresh()
    return self.sheet
end

-- ==== Paging ================================================================
function RecipeEditorSheet:_setPage(p)
    local total=#(self._filtered or {}); local per=self._perPage or (#self._rows)
    local totalPages=math.max(1,math.ceil(math.max(0,total)/math.max(1,per)))
    local newP=math.max(1,math.min(tonumber(p) or 1,totalPages))
    if newP~=self._page then self._page=newP; self:_rebindPage() end
    _updatePageText(self,totalPages,total)
end

function RecipeEditorSheet:_rebindPage()
    local per=self._perPage or (#self._rows); local page=math.max(1,self._page or 1)
    local start=(page-1)*per+1; local total=#(self._filtered or {})
    for i=1,per do local row=self._rows[i]; local entry=(start+(i-1) <= total) and self._filtered[start+(i-1)] or nil; if row then _bindRow(self,row,entry) end end
end

function RecipeEditorSheet:Refresh()
    local ds=self:GetEditingDataset()
    self._entries=_collectRecipesSorted(ds)
    -- filter
    local query=(self._query or ""):lower()
    if query~="" then
        local f={}; for _,e in ipairs(self._entries) do
            local s=(e.name or ""):lower()..(e.id or ""):lower()..(e.profession or ""):lower()..(e.outputItemId or ""):lower()
            if s:find(query,1,true) then f[#f+1]=e end
        end; self._filtered=f
    else self._filtered=self._entries end
    local total=#self._filtered; local per=self._perPage or (#self._rows); local totalPages=math.max(1,math.ceil(total/math.max(1,per)))
    if (self._page or 1)>totalPages then self._page=totalPages end; if (self._page or 0)<1 then self._page=1 end
    self:_rebindPage(); _updatePageText(self,totalPages,total)
    if self.resultsText and self.resultsText.SetText then self.resultsText:SetText(("%d total"):format(total)) end
end

function RecipeEditorSheet.New(opts) local self=setmetatable({},RecipeEditorSheet); self:SetEditingDataset(opts and opts.editingName); self:BuildUI(opts or {}); return self end

return RecipeEditorSheet
