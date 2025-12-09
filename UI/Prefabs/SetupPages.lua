-- RPE_UI/Prefabs/SetupPages.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local VGroup            = RPE_UI.Elements.VerticalLayoutGroup
local HGroup            = RPE_UI.Elements.HorizontalLayoutGroup
local Text              = RPE_UI.Elements.Text
local Button            = RPE_UI.Elements.TextButton
local Input             = RPE_UI.Elements.Input
local IconBtn           = RPE_UI.Elements.IconButton
local Checkbox          = RPE_UI.Elements.Checkbox
local Dropdown          = RPE_UI.Elements.Dropdown
local MultiSelectDropdown = RPE_UI.Elements.MultiSelectDropdown
local Panel             = RPE_UI.Elements.Panel
local EditorTable       = RPE_UI.Elements.EditorTable

---@class SetupPages
---@field frame any
---@field root any
---@field header any
---@field pageText any
---@field body any
---@field _pages table[]
---@field _page integer
---@field _ownerSheet any
---@field schemas any
---@field _rebinding integer
---@field onSave fun()|nil
local SetupPages = {}
SetupPages.__index = SetupPages
RPE_UI.Prefabs.SetupPages = SetupPages

-- ---------------------------------------------------------------------------
-- Constants / Fallbacks
-- ---------------------------------------------------------------------------
local PAGE_TYPES = { "SELECT_RACE", "SELECT_CLASS", "SELECT_STATS", "SELECT_LANGUAGE", "SELECT_SPELLS", "SELECT_ITEMS", "SELECT_PROFESSIONS" }
local PHASES = { "onStart", "onResolve", "onTick" }
local LOGIC  = { "ALL", "ANY", "NOT" }
local ACTION_KEYS_FALLBACK = { "DAMAGE", "HEAL", "APPLY_AURA", "REDUCE_COOLDOWN", "SUMMON", "HIDE" }

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------
local function scopy(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = scopy(v) end
  return o
end

local function copy_value(v) return (type(v) == "table") and scopy(v) or v end

-- Parses requirement CSV string into table format
local function parse_requirements_csv(csvStr)
  local reqs = {}
  if csvStr and csvStr ~= "" then
    for part in csvStr:gmatch("[^,]+") do
      local trimmed = part:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then
        table.insert(reqs, { key = trimmed })
      end
    end
  end
  return reqs
end

-- Formats requirement table back to CSV string
local function format_requirements_csv(reqs)
  local parts = {}
  for _, r in ipairs(reqs or {}) do
    if r.key and r.key ~= "" then
      table.insert(parts, r.key)
    end
  end
  return table.concat(parts, ", ")
end

local function ensure_page(p)
  p.pageType     = p.pageType or "SELECT_RACE"
  p.enabled      = p.enabled ~= false  -- default true
  p.title        = p.title or ""
  p.phase        = p.phase or "onResolve"
  p.logic        = p.logic or "ALL"
  p.actions      = p.actions or {}
  p.incrementBy  = p.incrementBy or 1
  return p
end


local function label(parent, text, width)
  local l = Text:New((parent.frame:GetName() or tostring(parent)) .. "_Lbl_" .. (text or "lbl"), {
    parent = parent, text = text or "", fontTemplate = "GameFontHighlightSmall", justifyH = "LEFT"
  })
  if width and l.frame and l.frame.SetWidth then l.frame:SetWidth(width) end
  parent:Add(l)
  return l
end

local function page_text(self)
  local total = math.max(1, #self._pages)
  local cur   = math.max(1, math.min(self._page or 1, total))
  if self.pageText then self.pageText:SetText(("Page %d / %d"):format(cur, total)) end
end

local function relayout_window(self)
  if self.root and self.root.Relayout then self.root:Relayout() end
  local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
  local target = self._ownerSheet or self.root
  if DW and DW._recalcSizeForContent then
    DW:_recalcSizeForContent(target)
    if DW._resizeSoon then DW:_resizeSoon(target) end
  end
end

local function wipe_children(group)
  if not (group and group.children) then return end
  for i = #group.children, 1, -1 do
    local ch = group.children[i]
    if ch and ch.frame and ch.frame.SetParent then ch.frame:SetParent(nil) end
    if ch and ch.Hide then ch:Hide() end
    group.children[i] = nil
  end
  if group.RequestAutoSize then group:RequestAutoSize() end
end

-- Schema resolver (accept multiple placements)
local function resolve_schemas(opts)
  if opts and opts.actionSchemas then return opts.actionSchemas end
  local R = _G.RPE
  if R and R.Core and R.Core.SpellActionSchemas then return R.Core.SpellActionSchemas end
  if R and R.SpellActionSchemas then return R.SpellActionSchemas end
  -- if _G.SpellActionSchemas then return _G.SpellActionSchemas end
  return nil
end

-- ---------------------------------------------------------------------------
-- Rebind guards (mute handlers while rebuilding UI)
-- ---------------------------------------------------------------------------
local function begin_rebind(self) self._rebinding = (self._rebinding or 0) + 1 end
local function end_rebind(self)   self._rebinding = math.max(0, (self._rebinding or 1) - 1) end
local function is_rebinding(self) return (self._rebinding or 0) > 0 end

-- ---------------------------------------------------------------------------
-- Field builder
-- ---------------------------------------------------------------------------
local function build_field_control(self, parent, a, field)
  local row = HGroup:New((parent.frame:GetName() or "RPE_SP") .. "_F_" .. tostring(field.id or "x"), {
    parent=parent, spacingX=8, alignV="CENTER", alignH="LEFT", autoSize=true,
  })
  parent:Add(row)

  local title = (field.label or field.id or "?") .. (field.required and " *" or "")
  label(row, title, 100)

  local type_  = (field.type or "input"):lower()
  local scope  = (field.scope or "args")

  local function get_current()
    if scope == "action" then return a[field.id] else return a.args and a.args[field.id] end
  end
  local function apply(v)
    if scope == "action" then a[field.id] = v
    else a.args = a.args or {}; a.args[field.id] = v end
  end

  local defv = get_current()
  if defv == nil and field.default ~= nil then
    if not (type_ == "input" and field.parse == "csv" and type(field.default) ~= "table") then
      defv = field.default
      apply(defv)
    end
  end

  if type_ == "checkbox" then
    local cb = Checkbox:New((row.frame:GetName() or "RPE_SP").."_CB_"..tostring(field.id or ""), {
      parent=row, checked = not not defv,
      onChanged=function(_, b) if is_rebinding(self) then return end; apply(b and true or false) end
    }); row:Add(cb)

  elseif type_ == "select" then
    local dd = Dropdown:New((row.frame:GetName() or "RPE_SP").."_DD_"..tostring(field.id or ""), {
      parent=row, width=160, height=22,
      value=(defv ~= nil) and defv or ((field.choices and field.choices[1]) or ""),
      choices=field.choices or {},
      onChanged=function(_, v) if is_rebinding(self) then return end; apply(v) end
    }); row:Add(dd)

  elseif type_ == "number" then
    local inp = Input:New((row.frame:GetName() or "RPE_SP").."_NUM_"..tostring(field.id or ""), {
      parent=row, width=100, height=20, text = (defv ~= nil) and tostring(defv) or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        local n = tonumber(txt); apply(n ~= nil and n or txt)
      end
    }); row:Add(inp)

  elseif type_ == "target_spec" then
    local tv = defv
    if type(tv) ~= "table" then
        tv = { targeter = tv or "caster" }
    else
        tv.targeter = tv.targeter or "caster"
    end
    
    local tgt = HGroup:New((row.frame:GetName() or "RPE_SP").."_TargetSpec_"..tostring(field.id or ""), {
      parent=row, spacingX=6, alignV="CENTER", alignH="LEFT", autoSize=true,
    }); row:Add(tgt)

    local choices = {
      "CASTER", "SELF", "TARGET", "PRECAST",
      "ALLY_SINGLE", "ALLY_SINGLE_OR_SELF",
      "ENEMY_SINGLE", "ENEMY_SINGLE_OR_SELF",
      "ALL_ALLIES", "ALL_ENEMIES", "ALL_UNITS"
    }
    local dd = Dropdown:New((tgt.frame:GetName() or "RPE_SP").."_Ref", {
      parent=tgt, width=140, height=22, value=tv.targeter, choices=choices,
      onChanged=function(_, v)
          if is_rebinding(self) then return end
          if tv.targeter == v then return end
          tv.targeter = v
          apply(tv)
          if self and self._ownerSheet and self._ownerSheet.Relayout then self._ownerSheet:Relayout() end
      end
    }); tgt:Add(dd)

    local lblNum = Text:New((tgt.frame:GetName() or "RPE_SP").."_NumLbl", { parent=tgt, text="#", fontTemplate="GameFontHighlightSmall" })
    tgt:Add(lblNum)

    local num = Input:New((tgt.frame:GetName() or "RPE_SP").."_Max", {
      parent=tgt, width=50, height=20, text = (tv.maxTargets and tostring(tv.maxTargets)) or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        local n = tonumber(txt)
        tv.maxTargets = (n and n > 0) and math.floor(n) or nil
        apply(tv)
      end
    }); tgt:Add(num)

    local lblFlags = Text:New((tgt.frame:GetName() or "RPE_SP").."_FlagsLbl", { parent=tgt, text="Flags", fontTemplate="GameFontHighlightSmall" })
    tgt:Add(lblFlags)

    local flags = Input:New((tgt.frame:GetName() or "RPE_SP").."_Flags", {
      parent=tgt, width=60, height=20, text = tv.flags and tostring(tv.flags) or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        txt = (txt and txt:gsub("^%s+",""):gsub("%s+$","")) or ""
        tv.flags = (txt ~= "") and txt or nil
        apply(tv)
      end
    }); tgt:Add(flags)

    apply(tv)

  elseif type_ == "list" and EditorTable then
    local wrapper = VGroup:New((row.frame:GetName() or "RPE_SP").."_ListWrap_"..tostring(field.id or ""), {
      parent=row, spacingY=4, alignV="TOP", alignH="LEFT", autoSize=true
    }); row:Add(wrapper)

    local function as_list(v)
      if type(v) == "table" then return v
      elseif v == nil or v == "" then return {}
      else return { tostring(v) } end
    end
    local function list_to_rows(lst) local rows = {}; for _, s in ipairs(lst or {}) do rows[#rows+1] = { value = s } end; return rows end
    local function rows_to_list(rows) local out = {}; for _, r in ipairs(rows or {}) do local v=r.value; if v and tostring(v)~="" then out[#out+1]=tostring(v) end end; return out end

    local startRows = list_to_rows(as_list(defv))
    local et = EditorTable.New((wrapper.frame:GetName() or "RPE_SP").."_List", {
      parent  = wrapper,
      data    = startRows,
      minRows = 1,
      columns = { { id = "value", header = field.itemLabel or "Value", type = field.itemType or "input", choices = field.choices } },
    })
    wrapper:Add(et.root or et)
    if et.SetOnChange then et:SetOnChange(function() if is_rebinding(self) then return end; apply(rows_to_list(et:GetData())) end) end
    apply(as_list(defv))

  elseif type_ == "lookup" then
    -- Lookup field: input + paste button + lookup button
    local lookupInput = Input:New((row.frame:GetName() or "RPE_SP").."_Lookup_Inp_"..tostring(field.id or ""), {
      parent=row, width=200, height=20, text = (defv ~= nil) and tostring(defv) or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        apply(txt)
      end
    }); row:Add(lookupInput)

    -- Paste button
    local pasteBtn = IconBtn:New((row.frame:GetName() or "RPE_SP").."_Lookup_Paste_"..tostring(field.id or ""), {
      parent = row, width = 16, height = 16,
      icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\paste.png",
      noBackground = true, hasBackground = false,
      noBorder = true, hasBorder = false,
      tooltip = "Paste from Clipboard",
      onClick = function()
        local Clipboard = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.Clipboard
        if not Clipboard then
          if RPE and RPE.Debug then
            RPE.Debug:Warning("Clipboard widget not available")
          end
          return
        end
        
        local pattern = field.pattern or "^aura%-[a-fA-F0-9]+$"
        local value = Clipboard:GetClipboardText(pattern)
        if value then
          pcall(function() lookupInput:SetText(value) end)
          if is_rebinding(self) then return end
          apply(value)
        else
          if RPE and RPE.Debug then
            RPE.Debug:Warning("Clipboard is empty or content does not match pattern")
          end
        end
      end,
    })
    row:Add(pasteBtn)

    -- Lookup button
    local lookupBtn = IconBtn:New((row.frame:GetName() or "RPE_SP").."_Lookup_Search_"..tostring(field.id or ""), {
      parent = row, width = 16, height = 16,
      icon = "Interface\\Addons\\RPEngine\\UI\\Textures\\lookup.png",
      noBackground = true, hasBackground = false,
      noBorder = true, hasBorder = false,
      tooltip = "Lookup",
      onClick = function()
        -- TODO: implement lookup functionality
      end,
    })
    row:Add(lookupBtn)

  else
    local function join_list_csv(v)
      if type(v) == "table" then local tmp={}; for i=1,#v do tmp[i]=v[i]~=nil and tostring(v[i]) or "" end; return table.concat(tmp, ", ") end
      return (v ~= nil) and tostring(v) or ""
    end
    local function split_csv_list(s)
      local out = {}; for token in tostring(s or ""):gmatch("[^,]+") do local t=token:match("^%s*(.-)%s*$"); if t~="" then out[#out+1]=t end end; return out
    end

    local initialText = (field.parse == "csv") and join_list_csv(defv) or ((defv ~= nil) and tostring(defv) or "")
    local inp = Input:New((row.frame:GetName() or "RPE_SP").."_TXT_"..tostring(field.id or ""), {
      parent=row, width=260, height=20, text = initialText,
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        if field.parse == "csv" then apply(split_csv_list(txt)) else apply(txt) end
      end
    }); row:Add(inp)
  end
end

-- Build (or rebuild) the args UI for an action based on its key
local function rebuild_action_args(self, card, a)
  begin_rebind(self)

  -- Ensure an args container exists AND is parented to the current card
  if a._argsBox then
    local needsAttach = true
    if a._argsBox.frame and a._argsBox.frame.GetParent then
      needsAttach = (a._argsBox.frame:GetParent() ~= card.frame)
    end
    if needsAttach then
      -- if it's still parented somewhere else or detached, move it under this card
      if a._argsBox.frame and a._argsBox.frame.SetParent then
        a._argsBox.frame:SetParent(card.frame)
      end
      if card.Add then card:Add(a._argsBox) end
    end
    wipe_children(a._argsBox)
  else
    a._argsBox = VGroup:New(card.frame:GetName().."_ArgsBox", {
      parent=card, spacingY=4, alignH="LEFT", alignV="TOP", autoSize=true
    })
    card:Add(a._argsBox)
  end

  -- seed + build from schema (unchanged)
  local def = self.schemas and self.schemas.Get and self.schemas:Get(a.key or "DAMAGE")
  if not (def and def.fields) then
    a.args = a.args or {}
    build_field_control(self, a._argsBox, a, {
      id="amount", label="Amount", type="input",
      default=(a.args and a.args.amount) or ""
    })
    relayout_window(self); end_rebind(self); return
  end

  a.args = a.args or {}
  for _, field in ipairs(def.fields) do
    local scope = (field.scope or "args")
    if scope == "action" then
      if a[field.id] == nil and field.default ~= nil
         and not (field.type == "input" and field.parse == "csv" and type(field.default) ~= "table") then
        a[field.id] = scopy(field.default)
      end
    else
      if a.args[field.id] == nil and field.default ~= nil
         and not (field.type == "input" and field.parse == "csv" and type(field.default) ~= "table") then
        a.args[field.id] = scopy(field.default)
      end
    end
    build_field_control(self, a._argsBox, a, field)
  end

  relayout_window(self)
  end_rebind(self)
end

-- ---------------------------------------------------------------------------
-- Page body
-- ---------------------------------------------------------------------------
local function rebuild_page_body(self)
  begin_rebind(self)
  wipe_children(self.body)

  local pi = math.max(1, math.min(self._page or 1, #self._pages))
  local p  = ensure_page(self._pages[pi])

  -- Row A: PageType | Delete Page
  local rowA = HGroup:New(self.frame:GetName().."_RowA", { parent=self.body, spacingX=10, alignH="LEFT", alignV="CENTER", autoSize=true })
  self.body:Add(rowA)

  label(rowA, "Type", 40)
  local typeDD = Dropdown:New(rowA.frame:GetName().."_Type", {
    parent=rowA, width=120, value=p.pageType, choices=PAGE_TYPES,
    onChanged=function(_, v) 
      if is_rebinding(self) then return end
      p.pageType = v
      rebuild_page_body(self)
    end
  }); rowA:Add(typeDD)

  local delPage = Button:New(rowA.frame:GetName().."_DelPage", {
    parent=rowA, width=90, height=22, text="|cffff4040Delete|r",
    onClick=function()
      table.remove(self._pages, pi)
      if #self._pages == 0 then table.insert(self._pages, ensure_page({})) end
      self._page = math.max(1, math.min(self._page, #self._pages))
      page_text(self)
      rebuild_page_body(self)
    end
  }); rowA:Add(delPage)

  -- Row B: Enabled | Title
  local rowB = HGroup:New(self.frame:GetName().."_RowB", { parent=self.body, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
  self.body:Add(rowB)

  label(rowB, "Enabled", 60)
  local enabledCB = Checkbox:New(rowB.frame:GetName().."_Enabled", {
    parent=rowB, checked = not not p.enabled,
    onChanged=function(_, b) if is_rebinding(self) then return end; p.enabled = b and true or false end
  }); rowB:Add(enabledCB)

  label(rowB, "Title", 50)
  local titleInput = Input:New(rowB.frame:GetName().."_Title", {
    parent=rowB, width=250, height=20, text = p.title or "",
    onChanged=function(_, txt)
      if is_rebinding(self) then return end
      p.title = txt
    end
  }); rowB:Add(titleInput)

  -- SELECT_STATS specific fields (in vertical group)
  if p.pageType == "SELECT_STATS" then
    local statsGroup = VGroup:New(self.frame:GetName().."_StatsGroup", {
      parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true
    })
    self.body:Add(statsGroup)

    local rowC1 = HGroup:New(self.frame:GetName().."_RowC1", { parent=statsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    statsGroup:Add(rowC1)
    label(rowC1, "Stat Type", 80)
    local statTypeDD = Dropdown:New(rowC1.frame:GetName().."_StatType", {
      parent=rowC1, width=140, value=p.statType or "STANDARD_ARRAY", 
      choices={ "STANDARD_ARRAY", "POINT_BUY", "SIMPLE_ASSIGN", "FROM_CLASS", "FROM_RACE" },
      onChanged=function(_, v) if is_rebinding(self) then return end; p.statType = v end
    }); rowC1:Add(statTypeDD)

    local rowC2 = HGroup:New(self.frame:GetName().."_RowC2", { parent=statsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    statsGroup:Add(rowC2)
    label(rowC2, "Stats (CSV)", 80)
    local statsInput = Input:New(rowC2.frame:GetName().."_Stats", {
      parent=rowC2, width=350, height=20, text = p.stats or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.stats = txt
      end
    }); rowC2:Add(statsInput)

    local rowC3 = HGroup:New(self.frame:GetName().."_RowC3", { parent=statsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    statsGroup:Add(rowC3)
    label(rowC3, "Max Per Stat", 80)
    local maxStatInput = Input:New(rowC3.frame:GetName().."_MaxStat", {
      parent=rowC3, width=100, height=20, text = p.maxPerStat or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.maxPerStat = tonumber(txt) or txt
      end
    }); rowC3:Add(maxStatInput)

    local rowC4 = HGroup:New(self.frame:GetName().."_RowC4", { parent=statsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    statsGroup:Add(rowC4)
    label(rowC4, "Max Points", 80)
    local maxPointsInput = Input:New(rowC4.frame:GetName().."_MaxPoints", {
      parent=rowC4, width=100, height=20, text = p.maxPoints or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.maxPoints = tonumber(txt) or txt
      end
    }); rowC4:Add(maxPointsInput)

    local rowC5 = HGroup:New(self.frame:GetName().."_RowC5", { parent=statsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    statsGroup:Add(rowC5)
    label(rowC5, "Increment By", 80)
    local incrementByInput = Input:New(rowC5.frame:GetName().."_IncrementBy", {
      parent=rowC5, width=100, height=20, text = p.incrementBy or "1",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.incrementBy = tonumber(txt) or 1
      end
    }); rowC5:Add(incrementByInput)
  end

  -- SELECT_RACE specific fields
  if p.pageType == "SELECT_RACE" then
    local DBG = _G.RPE and _G.RPE.Debug
    if DBG then DBG:Internal("[SetupPages] Building SELECT_RACE page editor") end
    if DBG then DBG:Internal("[SetupPages] Current p.customRaces: " .. (p.customRaces and #p.customRaces or 0)) end
    
    local raceGroup = VGroup:New(self.frame:GetName().."_RaceGroup", {
      parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true
    })
    self.body:Add(raceGroup)

    -- Custom Races EditorTable (ONLY for SELECT_RACE pages)
    local customRacesLabel = Text:New(self.frame:GetName().."_CustomRacesLabel", {
      parent=raceGroup, text="Custom Races:", fontSize=11
    })
    raceGroup:Add(customRacesLabel)

    local initialData = p.customRaces or {}

    local customRacesTable = EditorTable.New(self.frame:GetName().."_CustomRacesTable", {
      parent=raceGroup,
      columns={
        { id="id", header="Race ID", type="input", width=150 },
        { id="name", header="Race Name", type="input", width=200 },
        { id="icon", header="Icon (numeric)", type="number", width=100 },
      },
      data=initialData,
      minRows=1,
    })
    raceGroup:Add(customRacesTable.root)
    
    customRacesTable:SetOnChange(function()
      if is_rebinding(self) then return end
      p.customRaces = customRacesTable:GetData()
      if DBG then 
        DBG:Print("[SetupPages] OnChange: Custom races updated")
        DBG:Print("[SetupPages] p.customRaces now has " .. #(p.customRaces or {}) .. " entries")
      end
    end)
    
    -- Store reference to table in p so we can access it in GetValue
    p._customRacesTable = customRacesTable
  end

  -- SELECT_CLASS specific fields
  if p.pageType == "SELECT_CLASS" then
    local DBG = _G.RPE and _G.RPE.Debug
    if DBG then DBG:Print("[SetupPages] Building SELECT_CLASS page editor") end
    if DBG then DBG:Print("[SetupPages] Current p.customClasses: " .. (p.customClasses and #p.customClasses or 0)) end
    
    local classGroup = VGroup:New(self.frame:GetName().."_ClassGroup", {
      parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true
    })
    self.body:Add(classGroup)

    -- Custom Classes EditorTable (ONLY for SELECT_CLASS pages)
    local customClassesLabel = Text:New(self.frame:GetName().."_CustomClassesLabel", {
      parent=classGroup, text="Custom Classes:", fontSize=11
    })
    classGroup:Add(customClassesLabel)

    local initialData = p.customClasses or {}
    
    local customClassesTable = EditorTable.New(self.frame:GetName().."_CustomClassesTable", {
      parent=classGroup,
      columns={
        { id="id", header="Class ID", type="input", width=150 },
        { id="name", header="Class Name", type="input", width=200 },
        { id="icon", header="Icon (numeric)", type="number", width=100 },
      },
      data=initialData,
      minRows=1,
    })
    classGroup:Add(customClassesTable.root)
    
    customClassesTable:SetOnChange(function()
      if is_rebinding(self) then return end
      p.customClasses = customClassesTable:GetData()
      if DBG then 
        DBG:Print("[SetupPages] OnChange: Custom classes updated")
        DBG:Print("[SetupPages] p.customClasses now has " .. #(p.customClasses or {}) .. " entries")
      end
    end)
    
    -- Store reference to table in p so we can access it in GetValue
    p._customClassesTable = customClassesTable
  end

  -- SELECT_SPELLS specific fields
  if p.pageType == "SELECT_SPELLS" then
    local spellsGroup = VGroup:New(self.frame:GetName().."_SpellsGroup", {
      parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true
    })
    self.body:Add(spellsGroup)

    -- Checkboxes
    local checkboxRow1 = HGroup:New(self.frame:GetName().."_CheckRow1", { parent=spellsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    spellsGroup:Add(checkboxRow1)
    label(checkboxRow1, "Allow Racial", 100)
    local allowRacialCB = Checkbox:New(checkboxRow1.frame:GetName().."_AllowRacial", {
      parent=checkboxRow1, checked = p.allowRacial ~= false,
      onChanged=function(_, b) if is_rebinding(self) then return end; p.allowRacial = b and true or false end
    }); checkboxRow1:Add(allowRacialCB)

    local checkboxRow2 = HGroup:New(self.frame:GetName().."_CheckRow2", { parent=spellsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    spellsGroup:Add(checkboxRow2)
    label(checkboxRow2, "Restrict to Class", 100)
    local restrictToClassCB = Checkbox:New(checkboxRow2.frame:GetName().."_RestrictToClass", {
      parent=checkboxRow2, checked = p.restrictToClass or false,
      onChanged=function(_, b) if is_rebinding(self) then return end; p.restrictToClass = b and true or false end
    }); checkboxRow2:Add(restrictToClassCB)

    local checkboxRow3 = HGroup:New(self.frame:GetName().."_CheckRow3", { parent=spellsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    spellsGroup:Add(checkboxRow3)
    label(checkboxRow3, "First Rank Only", 100)
    local firstRankOnlyCB = Checkbox:New(checkboxRow3.frame:GetName().."_FirstRankOnly", {
      parent=checkboxRow3, checked = p.firstRankOnly or false,
      onChanged=function(_, b) if is_rebinding(self) then return end; p.firstRankOnly = b and true or false end
    }); checkboxRow3:Add(firstRankOnlyCB)

    -- Input fields
    local inputRow1 = HGroup:New(self.frame:GetName().."_InputRow1", { parent=spellsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    spellsGroup:Add(inputRow1)
    label(inputRow1, "Max Spell Points", 100)
    local maxSpellPointsInput = Input:New(inputRow1.frame:GetName().."_MaxPoints", {
      parent=inputRow1, width=100, height=20, text = p.maxSpellPoints or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.maxSpellPoints = tonumber(txt) or txt
      end
    }); inputRow1:Add(maxSpellPointsInput)

    local inputRow2 = HGroup:New(self.frame:GetName().."_InputRow2", { parent=spellsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    spellsGroup:Add(inputRow2)
    label(inputRow2, "Max Spells Total", 100)
    local maxSpellsTotalInput = Input:New(inputRow2.frame:GetName().."_MaxTotal", {
      parent=inputRow2, width=100, height=20, text = p.maxSpellsTotal or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.maxSpellsTotal = tonumber(txt) or txt
      end
    }); inputRow2:Add(maxSpellsTotalInput)
  end

  -- SELECT_ITEMS specific fields
  if p.pageType == "SELECT_ITEMS" then
    local itemsGroup = VGroup:New(self.frame:GetName().."_ItemsGroup", {
      parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true
    })
    self.body:Add(itemsGroup)

    -- Max Allowance input
    local allowanceRow = HGroup:New(self.frame:GetName().."_AllowanceRow", { parent=itemsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    itemsGroup:Add(allowanceRow)
    label(allowanceRow, "Max Allowance", 100)
    local maxAllowanceInput = Input:New(allowanceRow.frame:GetName().."_MaxAllowance", {
      parent=allowanceRow, width=100, height=20, text = p.maxAllowance or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.maxAllowance = tonumber(txt) or txt
      end
    }); allowanceRow:Add(maxAllowanceInput)

    -- Include Tags input (comma-separated)
    local includeRow = HGroup:New(self.frame:GetName().."_IncludeRow", { parent=itemsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    itemsGroup:Add(includeRow)
    label(includeRow, "Include Tags", 100)
    local includeTagsInput = Input:New(includeRow.frame:GetName().."_IncludeTags", {
      parent=includeRow, width=200, height=20, text = p.includeTags or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.includeTags = txt
      end
    }); includeRow:Add(includeTagsInput)

    -- Exclude Tags input (comma-separated)
    local excludeRow = HGroup:New(self.frame:GetName().."_ExcludeRow", { parent=itemsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    itemsGroup:Add(excludeRow)
    label(excludeRow, "Exclude Tags", 100)
    local excludeTagsInput = Input:New(excludeRow.frame:GetName().."_ExcludeTags", {
      parent=excludeRow, width=200, height=20, text = p.excludeTags or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.excludeTags = txt
      end
    }); excludeRow:Add(excludeTagsInput)

    -- Max Rarity dropdown (common, uncommon, rare, epic, legendary)
    local rarityRow = HGroup:New(self.frame:GetName().."_RarityRow", { parent=itemsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    itemsGroup:Add(rarityRow)
    label(rarityRow, "Max Rarity", 100)
    local rarityDD = Dropdown:New(rarityRow.frame:GetName().."_MaxRarity", {
      parent=rarityRow, width=100, value=p.maxRarity or "legendary", choices={"common", "uncommon", "rare", "epic", "legendary"},
      onChanged=function(_, v)
        if is_rebinding(self) then return end
        p.maxRarity = v
      end
    }); rarityRow:Add(rarityDD)

    -- Category filter multi-select dropdown
    local categoryRow = HGroup:New(self.frame:GetName().."_CategoryRow", { parent=itemsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    itemsGroup:Add(categoryRow)
    label(categoryRow, "Allowed Categories", 100)
    
    -- Parse comma-separated categories into a table
    local function parseCategoryString(str)
      if not str or str == "" then return {} end
      local result = {}
      for cat in str:gmatch("[^,]+") do
        result[#result + 1] = cat:match("^%s*(.-)%s*$")
      end
      return result
    end
    
    local categoryChoices = {"CONSUMABLE", "EQUIPMENT", "MATERIAL", "QUEST", "MISC"}
    local selectedCategories = parseCategoryString(p.allowedCategory or "")
    
    local categoryDD = MultiSelectDropdown:New(categoryRow.frame:GetName().."_AllowedCategory", {
      parent=categoryRow, width=200, choices=categoryChoices, values=selectedCategories,
      onChanged=function(_, values)
        if is_rebinding(self) then return end
        p.allowedCategory = table.concat(values, ",")
      end
    })
    categoryRow:Add(categoryDD)
  end

  -- SELECT_PROFESSIONS specific fields
  if p.pageType == "SELECT_PROFESSIONS" then
    local profsGroup = VGroup:New(self.frame:GetName().."_ProfsGroup", {
      parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true
    })
    self.body:Add(profsGroup)

    -- Max Level input
    local maxLevelRow = HGroup:New(self.frame:GetName().."_MaxLevelRow", { parent=profsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    profsGroup:Add(maxLevelRow)
    label(maxLevelRow, "Max Profession Level", 130)
    local maxLevelInput = Input:New(maxLevelRow.frame:GetName().."_MaxLevel", {
      parent=maxLevelRow, width=80, height=20, text = tostring(p.maxLevel or 1),
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.maxLevel = tonumber(txt) or 1
      end
    }); maxLevelRow:Add(maxLevelInput)

    -- Profession Points Allowance input (0 = unlimited)
    local pointsRow = HGroup:New(self.frame:GetName().."_PointsRow", { parent=profsGroup, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    profsGroup:Add(pointsRow)
    label(pointsRow, "Prof Points Allowed", 130)
    local pointsInput = Input:New(pointsRow.frame:GetName().."_PointsAllowance", {
      parent=pointsRow, width=80, height=20, text = tostring(p.professionPointsAllowance or 0),
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        p.professionPointsAllowance = tonumber(txt) or 0
      end
    }); pointsRow:Add(pointsInput)
  end

  local function getActionKeys()
    local schemas = self.schemas
    if schemas and schemas.AllKeys then
      local keys = schemas:AllKeys()
      if type(keys) == "table" and #keys > 0 then return keys end
    end
    return ACTION_KEYS_FALLBACK
  end

  -- Action cards
  for ai, a in ipairs(p.actions) do
    local card = VGroup:New(self.frame:GetName()..("_Action_%d"):format(ai), { parent=self.body, spacingY=6, alignH="LEFT", alignV="TOP", autoSize=true })
    self.body:Add(card)

    local r1 = HGroup:New(card.frame:GetName().."_R1", { parent=card, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
    card:Add(r1)

    label(r1, "Key", 40)
    local keyDD = Dropdown:New(r1.frame:GetName().."_Key", {
      parent=r1, width=170, value=a.key or "DAMAGE", choices=getActionKeys(),
      onChanged=function(_, v)
        if is_rebinding(self) then return end
        if v == a.key then return end
        a.key = v
        a.args = {}
        for k in pairs(a) do
          if k ~= "key" and k ~= "args" and type(k) ~= "function" and (type(k) ~= "string" or k:sub(1,1) ~= "_") then a[k] = nil end
        end
        rebuild_action_args(self, card, a)
      end
    }); r1:Add(keyDD)

    local delBtn = Button:New(r1.frame:GetName().."_Del", {
      parent=r1, width=26, height=20, text="×",
      onClick=function() table.remove(p.actions, ai); rebuild_page_body(self) end
    }); r1:Add(delBtn)

    -- Dynamic args area from schema
    rebuild_action_args(self, card, a)
  end

  -- Spacer
  local spacer = Panel and Panel:New(self.frame:GetName().."_BottomSpacer", { parent=self.body, width=1, height=40 })
    or VGroup:New(self.frame:GetName().."_BottomSpacer", { parent=self.body, width=1, height=40, autoSize=false })
  self.body:Add(spacer)

  relayout_window(self)
  end_rebind(self)
end

-- ---------------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------------
function SetupPages:New(name, opts)
  opts = opts or {}
  local root = VGroup:New(name or "SetupPages", { parent=opts.parent, spacingY=10, alignH="LEFT", alignV="TOP", autoSize=true })
  local self = setmetatable({
    frame       = root.frame,
    root        = root,
    _pages      = {},
    _page       = 1,
    _ownerSheet = opts.ownerSheet,
    schemas     = resolve_schemas(opts),  -- << resolve schemas here
    onSave      = opts.onSave,  -- << capture callback from opts
  }, SetupPages)

  -- Header
  local header = HGroup:New((name or "SetupPages").."_Header", { parent=root, spacingX=10, alignH="LEFT", alignV="CENTER", autoSize=true })
  root:Add(header); self.header = header

  local prev = Button:New(header.frame:GetName().."_Prev", {
    parent=header, width=70, height=22, text="Prev", noBorder=true,
    onClick=function() if self._page > 1 then self._page = self._page - 1 end; page_text(self); rebuild_page_body(self) end
  }); header:Add(prev)

  self.pageText = Text:New(header.frame:GetName().."_PageText", { parent=header, text="Page 1 / 1", fontTemplate="GameFontNormalSmall" })
  header:Add(self.pageText)

  local next = Button:New(header.frame:GetName().."_Next", {
    parent=header, width=70, height=22, text="Next", noBorder=true,
    onClick=function() if self._page < #self._pages then self._page = self._page + 1 end; page_text(self); rebuild_page_body(self) end
  }); header:Add(next)

  local add = Button:New(header.frame:GetName().."_AddPage", {
    parent=header, width=120, height=22, text="+ Add Page",
    onClick=function() table.insert(self._pages, ensure_page({})); self._page = #self._pages; page_text(self); rebuild_page_body(self) end
  }); header:Add(add)

  local save = Button:New(header.frame:GetName().."_Save", {
    parent=header, width=140, height=22, text="Save Setup Wizard",
    onClick=function()
      if self.onSave and type(self.onSave) == "function" then
        pcall(self.onSave)
      end
    end
  }); header:Add(save)

  -- Body
  local body = VGroup:New((name or "SetupPages").."_Body", { parent=root, spacingY=12, alignH="LEFT", alignV="TOP", autoSize=true })
  root:Add(body); self.body = body

  -- Init with empty pages - will be populated via SetValue when Refresh is called
  self:SetValue({})

  return self
end

function SetupPages:SetValue(pages)
  self._pages = {}
  if type(pages) == "table" and next(pages) then
    for _, p in ipairs(pages) do
      local copy = ensure_page(scopy(p)); copy.actions = {}
      -- Preserve customRaces for SELECT_RACE pages
      if p.pageType == "SELECT_RACE" and p.customRaces then
        copy.customRaces = scopy(p.customRaces)
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupPages] SetValue: Loading customRaces with " .. #(p.customRaces or {}) .. " entries") end
      end
      -- Preserve customClasses for SELECT_CLASS pages
      if p.pageType == "SELECT_CLASS" and p.customClasses then
        copy.customClasses = scopy(p.customClasses)
        local DBG = _G.RPE and _G.RPE.Debug
        if DBG then DBG:Internal("[SetupPages] SetValue: Loading customClasses with " .. #(p.customClasses or {}) .. " entries") end
      end
      -- Preserve SELECT_SPELLS fields
      if p.pageType == "SELECT_SPELLS" then
        copy.allowRacial = p.allowRacial ~= false
        copy.restrictToClass = p.restrictToClass or false
        copy.firstRankOnly = p.firstRankOnly or false
        copy.maxSpellPoints = p.maxSpellPoints
        copy.maxSpellsTotal = p.maxSpellsTotal
      end
      -- Preserve SELECT_ITEMS fields
      if p.pageType == "SELECT_ITEMS" then
        copy.maxAllowance = p.maxAllowance
        copy.includeTags = p.includeTags or ""
        copy.excludeTags = p.excludeTags or ""
        copy.maxRarity = p.maxRarity or "legendary"
        copy.allowedCategory = p.allowedCategory or ""
      end
      -- Preserve SELECT_PROFESSIONS fields
      if p.pageType == "SELECT_PROFESSIONS" then
        copy.maxLevel = p.maxLevel or 1
        copy.professionPointsAllowance = p.professionPointsAllowance or 0
      end
      for _, a in ipairs(p.actions or {}) do
        local ac = { key = a.key, args = scopy(a.args or {}) }
        for k, v in pairs(a) do
          if k ~= "key" and k ~= "args" and (type(k) ~= "string" or k:sub(1,1) ~= "_") then ac[k] = copy_value(v) end
        end
        table.insert(copy.actions, ac)
      end
      table.insert(self._pages, copy)
    end
  else
    -- Default to one SELECT_RACE page if none provided
    table.insert(self._pages, ensure_page({ pageType = "SELECT_RACE" }))
  end
  self._page = math.max(1, math.min(self._page or 1, #self._pages))
  page_text(self)
  rebuild_page_body(self)
end

function SetupPages:GetValue()
  local out = {}
  for _, p in ipairs(self._pages) do
    local pp = {
      pageType = p.pageType or "SELECT_RACE",
      enabled = p.enabled ~= false,
      title = p.title or "",
      phase = p.phase or "onResolve",
      logic = p.logic or "ALL",
      actions = {},
    }
    
    -- Add SELECT_STATS specific fields
    if p.pageType == "SELECT_STATS" then
      pp.statType = p.statType or "STANDARD_ARRAY"
      pp.stats = p.stats or ""
      pp.maxPerStat = p.maxPerStat
      pp.maxPoints = p.maxPoints
      pp.incrementBy = p.incrementBy or 1
    end
    
    -- Add SELECT_RACE specific fields
    if p.pageType == "SELECT_RACE" then
      -- Get data directly from the table if it exists, otherwise use p.customRaces
      local racesData = {}
      if p._customRacesTable and p._customRacesTable.GetData then
        racesData = p._customRacesTable:GetData()
      else
        racesData = p.customRaces or {}
      end
      pp.customRaces = scopy(racesData)
      local DBG = _G.RPE and _G.RPE.Debug
      if DBG then DBG:Internal("[SetupPages] GetValue: Serializing customRaces with " .. #(pp.customRaces or {}) .. " entries") end
    end
    
    -- Add SELECT_CLASS specific fields
    if p.pageType == "SELECT_CLASS" then
      -- Get data directly from the table if it exists, otherwise use p.customClasses
      local classesData = {}
      if p._customClassesTable and p._customClassesTable.GetData then
        classesData = p._customClassesTable:GetData()
      else
        classesData = p.customClasses or {}
      end
      pp.customClasses = scopy(classesData)
      local DBG = _G.RPE and _G.RPE.Debug
      if DBG then DBG:Internal("[SetupPages] GetValue: Serializing customClasses with " .. #(pp.customClasses or {}) .. " entries") end
    end
    
    -- Add SELECT_SPELLS specific fields
    if p.pageType == "SELECT_SPELLS" then
      pp.allowRacial = p.allowRacial ~= false
      pp.restrictToClass = p.restrictToClass or false
      pp.firstRankOnly = p.firstRankOnly or false
      pp.maxSpellPoints = p.maxSpellPoints
      pp.maxSpellsTotal = p.maxSpellsTotal
    end
    
    -- Add SELECT_ITEMS specific fields
    if p.pageType == "SELECT_ITEMS" then
      pp.maxAllowance = p.maxAllowance
      pp.includeTags = p.includeTags or ""
      pp.excludeTags = p.excludeTags or ""
      pp.maxRarity = p.maxRarity or "legendary"
      pp.allowedCategory = p.allowedCategory or ""
    end
    
    -- Add SELECT_PROFESSIONS specific fields
    if p.pageType == "SELECT_PROFESSIONS" then
      pp.maxLevel = p.maxLevel or 1
      pp.professionPointsAllowance = p.professionPointsAllowance or 0
    end
    
    for _, a in ipairs(p.actions or {}) do
      if a.key then
        local aa = { key = a.key, args = scopy(a.args or {}) }
        for k, v in pairs(a) do
          if k ~= "key" and k ~= "args" and (type(k) ~= "string" or k:sub(1,1) ~= "_") then aa[k] = copy_value(v) end
        end
        table.insert(pp.actions, aa)
      end
    end
    table.insert(out, pp)
  end
  return out
end

return SetupPages
