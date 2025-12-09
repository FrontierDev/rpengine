-- RPE_UI/Prefabs/SpellGroups.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local VGroup      = RPE_UI.Elements.VerticalLayoutGroup
local HGroup      = RPE_UI.Elements.HorizontalLayoutGroup
local Text        = RPE_UI.Elements.Text
local Button      = RPE_UI.Elements.TextButton
local Input       = RPE_UI.Elements.Input
local IconBtn     = RPE_UI.Elements.IconButton
local Checkbox    = RPE_UI.Elements.Checkbox
local Dropdown    = RPE_UI.Elements.Dropdown
local Panel       = RPE_UI.Elements.Panel
local EditorTable = RPE_UI.Elements.EditorTable

---@class SpellGroups
local SpellGroups = {}
SpellGroups.__index = SpellGroups
RPE_UI.Prefabs.SpellGroups = SpellGroups

-- ---------------------------------------------------------------------------
-- Constants / Fallbacks
-- ---------------------------------------------------------------------------
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
-- Converts "equip.mainhand.mace, inventory.POTION" to { {key="equip.mainhand.mace"}, {key="inventory.POTION"} }
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
-- Converts { {key="equip.mainhand.mace"}, {key="inventory.POTION"} } to "equip.mainhand.mace, inventory.POTION"
local function format_requirements_csv(reqs)
  local parts = {}
  for _, r in ipairs(reqs or {}) do
    if r.key and r.key ~= "" then
      table.insert(parts, r.key)
    end
  end
  return table.concat(parts, ", ")
end

local function ensure_group(g)
  g.phase        = g.phase or "onResolve"
  g.logic        = g.logic or "ALL"
  g.requirements = g.requirements or {}
  g.actions      = g.actions or {}
  return g
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
  local total = math.max(1, #self._groups)
  local cur   = math.max(1, math.min(self._page or 1, total))
  if self.pageText then self.pageText:SetText(("Group %d / %d"):format(cur, total)) end
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

local function has_req(g, key)
  for _, r in ipairs(g.requirements or {}) do
    if r.key == key then return true end
  end
  return false
end

-- Updated to work with CSV requirement strings - kept for backward compatibility
local function set_req(g, key, enabled)
  -- This function is now deprecated in favor of directly setting g.requirements
  -- but kept for backward compatibility if needed
  g.requirements = g.requirements or {}
  for i = #g.requirements, 1, -1 do
    if g.requirements[i].key == key then table.remove(g.requirements, i) end
  end
  if enabled then table.insert(g.requirements, { key = key }) end
end

-- Schema resolver (accept multiple placements)
local function resolve_schemas(opts)
  if opts and opts.actionSchemas then return opts.actionSchemas end
  local R = _G.RPE
  if R and R.Core and R.Core.SpellActionSchemas then return R.Core.SpellActionSchemas end
  if R and R.SpellActionSchemas then return R.SpellActionSchemas end
  if _G.SpellActionSchemas then return _G.SpellActionSchemas end
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
  local row = HGroup:New((parent.frame:GetName() or "RPE_SG") .. "_F_" .. tostring(field.id or "x"), {
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
    local cb = Checkbox:New((row.frame:GetName() or "RPE_SG").."_CB_"..tostring(field.id or ""), {
      parent=row, checked = not not defv,
      onChanged=function(_, b) if is_rebinding(self) then return end; apply(b and true or false) end
    }); row:Add(cb)

  elseif type_ == "select" then
    local dd = Dropdown:New((row.frame:GetName() or "RPE_SG").."_DD_"..tostring(field.id or ""), {
      parent=row, width=160, height=22,
      value=(defv ~= nil) and defv or ((field.choices and field.choices[1]) or ""),
      choices=field.choices or {},
      onChanged=function(_, v) if is_rebinding(self) then return end; apply(v) end
    }); row:Add(dd)

  elseif type_ == "number" then
    local inp = Input:New((row.frame:GetName() or "RPE_SG").."_NUM_"..tostring(field.id or ""), {
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
    
    local tgt = HGroup:New((row.frame:GetName() or "RPE_SG").."_TargetSpec_"..tostring(field.id or ""), {
      parent=row, spacingX=6, alignV="CENTER", alignH="LEFT", autoSize=true,
    }); row:Add(tgt)

    local choices = {
      "CASTER", "SELF", "TARGET", "PRECAST",
      "ALLY_SINGLE", "ALLY_SINGLE_OR_SELF",
      "ENEMY_SINGLE", "ENEMY_SINGLE_OR_SELF",
      "ALL_ALLIES", "ALL_ENEMIES", "ALL_UNITS"
    }
    local dd = Dropdown:New((tgt.frame:GetName() or "RPE_SG").."_Ref", {
      parent=tgt, width=140, height=22, value=tv.targeter, choices=choices,
      onChanged=function(_, v)
          if is_rebinding(self) then return end
          if tv.targeter == v then return end
          tv.targeter = v
          apply(tv)
          if self and self._ownerSheet and self._ownerSheet.Relayout then self._ownerSheet:Relayout() end
      end
    }); tgt:Add(dd)

    local lblNum = Text:New((tgt.frame:GetName() or "RPE_SG").."_NumLbl", { parent=tgt, text="#", fontTemplate="GameFontHighlightSmall" })
    tgt:Add(lblNum)

    local num = Input:New((tgt.frame:GetName() or "RPE_SG").."_Max", {
      parent=tgt, width=50, height=20, text = (tv.maxTargets and tostring(tv.maxTargets)) or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        local n = tonumber(txt)
        tv.maxTargets = (n and n > 0) and math.floor(n) or nil
        apply(tv)
      end
    }); tgt:Add(num)

    local lblFlags = Text:New((tgt.frame:GetName() or "RPE_SG").."_FlagsLbl", { parent=tgt, text="Flags", fontTemplate="GameFontHighlightSmall" })
    tgt:Add(lblFlags)

    local flags = Input:New((tgt.frame:GetName() or "RPE_SG").."_Flags", {
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
    local wrapper = VGroup:New((row.frame:GetName() or "RPE_SG").."_ListWrap_"..tostring(field.id or ""), {
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
    local et = EditorTable.New((wrapper.frame:GetName() or "RPE_SG").."_List", {
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
    local lookupInput = Input:New((row.frame:GetName() or "RPE_SG").."_Lookup_Inp_"..tostring(field.id or ""), {
      parent=row, width=200, height=20, text = (defv ~= nil) and tostring(defv) or "",
      onChanged=function(_, txt)
        if is_rebinding(self) then return end
        apply(txt)
      end
    }); row:Add(lookupInput)

    -- Paste button
    local pasteBtn = IconBtn:New((row.frame:GetName() or "RPE_SG").."_Lookup_Paste_"..tostring(field.id or ""), {
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
          lookupInput:SetText(value)
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
    local lookupBtn = IconBtn:New((row.frame:GetName() or "RPE_SG").."_Lookup_Search_"..tostring(field.id or ""), {
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
    local inp = Input:New((row.frame:GetName() or "RPE_SG").."_TXT_"..tostring(field.id or ""), {
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
      -- if it’s still parented somewhere else or detached, move it under this card
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
-- Group body
-- ---------------------------------------------------------------------------
local function rebuild_group_body(self)
  begin_rebind(self)
  wipe_children(self.body)

  local gi = math.max(1, math.min(self._page or 1, #self._groups))
  local g  = ensure_group(self._groups[gi])

  -- Row A: Phase | Logic | + Add Action | Delete Group
  local rowA = HGroup:New(self.frame:GetName().."_RowA", { parent=self.body, spacingX=10, alignH="LEFT", alignV="CENTER", autoSize=true })
  self.body:Add(rowA)

  label(rowA, "Phase", 40)
  local phaseDD = Dropdown:New(rowA.frame:GetName().."_Phase", {
    parent=rowA, width=80, value=g.phase, choices=PHASES,
    onChanged=function(_, v) if is_rebinding(self) then return end; g.phase = v end
  }); rowA:Add(phaseDD)

  label(rowA, "Logic", 40)
  local logicDD = Dropdown:New(rowA.frame:GetName().."_Logic", {
    parent=rowA, width=80, value=g.logic, choices=LOGIC,
    onChanged=function(_, v) if is_rebinding(self) then return end; g.logic = v end
  }); rowA:Add(logicDD)

  local function getActionKeys()
    local schemas = self.schemas
    if schemas and schemas.AllKeys then
      local keys = schemas:AllKeys()
      if type(keys) == "table" and #keys > 0 then return keys end
    end
    return ACTION_KEYS_FALLBACK
  end

  local addAction = Button:New(rowA.frame:GetName().."_AddAction", {
    parent=rowA, width=90, height=22, text="+ Action",
    onClick=function()
      local keys = getActionKeys()
      local firstKey = keys[1] or "DAMAGE"
      table.insert(g.actions, { key = firstKey, args = {} })
      rebuild_group_body(self)
    end
  }); rowA:Add(addAction)

  local delGroup = Button:New(rowA.frame:GetName().."_DelGroup", {
    parent=rowA, width=90, height=22, text="|cffff4040Delete|r",
    onClick=function()
      table.remove(self._groups, gi)
      if #self._groups == 0 then table.insert(self._groups, ensure_group({})) end
      self._page = math.max(1, math.min(self._page, #self._groups))
      page_text(self)
      rebuild_group_body(self)
    end
  }); rowA:Add(delGroup)

  -- Row Req
  local req = HGroup:New(self.frame:GetName().."_ReqRow", { parent=self.body, spacingX=8, alignH="LEFT", alignV="CENTER", autoSize=true })
  self.body:Add(req)
  label(req, "Requirements", 86)
  local reqInput = Input:New(req.frame:GetName().."_Input", {
    parent=req, width=300, height=22, text=format_requirements_csv(g.requirements or {}),
    onChanged=function(_, csvStr)
      if is_rebinding(self) then return end
      g.requirements = parse_requirements_csv(csvStr)
      relayout_window(self)
    end
  }); req:Add(reqInput)

  -- Action cards
  for ai, a in ipairs(g.actions) do
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
      onClick=function() table.remove(g.actions, ai); rebuild_group_body(self) end
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
function SpellGroups:New(name, opts)
  opts = opts or {}
  local root = VGroup:New(name or "SpellGroups", { parent=opts.parent, spacingY=10, alignH="LEFT", alignV="TOP", autoSize=true })
  local self = setmetatable({
    frame       = root.frame,
    root        = root,
    _groups     = {},
    _page       = 1,
    _ownerSheet = opts.ownerSheet,
    schemas     = resolve_schemas(opts),  -- << resolve schemas here
  }, SpellGroups)

  -- Header
  local header = HGroup:New((name or "SpellGroups").."_Header", { parent=root, spacingX=10, alignH="LEFT", alignV="CENTER", autoSize=true })
  root:Add(header); self.header = header

  local prev = Button:New(header.frame:GetName().."_Prev", {
    parent=header, width=70, height=22, text="Prev", noBorder=true,
    onClick=function() if self._page > 1 then self._page = self._page - 1 end; page_text(self); rebuild_group_body(self) end
  }); header:Add(prev)

  self.pageText = Text:New(header.frame:GetName().."_PageText", { parent=header, text="Group 1 / 1", fontTemplate="GameFontNormalSmall" })
  header:Add(self.pageText)

  local next = Button:New(header.frame:GetName().."_Next", {
    parent=header, width=70, height=22, text="Next", noBorder=true,
    onClick=function() if self._page < #self._groups then self._page = self._page + 1 end; page_text(self); rebuild_group_body(self) end
  }); header:Add(next)

  local add = Button:New(header.frame:GetName().."_AddGroup", {
    parent=header, width=120, height=22, text="+ Add Group",
    onClick=function() table.insert(self._groups, ensure_group({})); self._page = #self._groups; page_text(self); rebuild_group_body(self) end
  }); header:Add(add)

  -- Body
  local body = VGroup:New((name or "SpellGroups").."_Body", { parent=root, spacingY=12, alignH="LEFT", alignV="TOP", autoSize=true })
  root:Add(body); self.body = body

  -- Init value
  self:SetValue(opts.value or opts.default or {
    { phase="onResolve", logic="ALL", requirements={}, actions={} }
  })

  return self
end

function SpellGroups:SetValue(groups)
  self._groups = {}
  if type(groups) == "table" and next(groups) then
    for _, g in ipairs(groups) do
      local copy = ensure_group(scopy(g)); copy.actions = {}
      for _, a in ipairs(g.actions or {}) do
        local ac = { key = a.key, args = scopy(a.args or {}) }
        for k, v in pairs(a) do
          if k ~= "key" and k ~= "args" and (type(k) ~= "string" or k:sub(1,1) ~= "_") then ac[k] = copy_value(v) end
        end
        table.insert(copy.actions, ac)
      end
      table.insert(self._groups, copy)
    end
  else
    table.insert(self._groups, ensure_group({}))
  end
  self._page = math.max(1, math.min(self._page or 1, #self._groups))
  page_text(self)
  rebuild_group_body(self)
end

function SpellGroups:GetValue()
  local out = {}
  for _, g in ipairs(self._groups) do
    local gg = {
      phase = g.phase or "onResolve",
      logic = g.logic or "ALL",
      requirements = (g.requirements and next(g.requirements)) and g.requirements or {},
      actions = {},
    }
    for _, a in ipairs(g.actions or {}) do
      if a.key then
        local aa = { key = a.key, args = scopy(a.args or {}) }
        for k, v in pairs(a) do
          if k ~= "key" and k ~= "args" and (type(k) ~= "string" or k:sub(1,1) ~= "_") then aa[k] = copy_value(v) end
        end
        table.insert(gg.actions, aa)
      end
    end
    if #gg.actions > 0 then table.insert(out, gg) end
  end
  return out
end

return SpellGroups
