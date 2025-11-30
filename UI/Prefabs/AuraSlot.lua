-- RPE_UI/Prefabs/AuraSlot.lua
RPE_UI          = RPE_UI or {}
RPE_UI.Prefabs  = RPE_UI.Prefabs or {}
RPE_UI.Elements = RPE_UI.Elements or {}

local IconButton = RPE_UI.Elements.IconButton
local Text       = RPE_UI.Elements.Text

---@class AuraSlot: IconButton
---@field bg Texture
---@field name Text
---@field subtitle Text
---@field glow Texture
---@field auraId string|nil
local AuraSlot = setmetatable({}, { __index = IconButton })
AuraSlot.__index = AuraSlot
RPE_UI.Prefabs.AuraSlot = AuraSlot

-- ===== component ===========================================================
function AuraSlot:New(name, opts)
    opts = opts or {}
    opts.width  = opts.width  or 40
    opts.height = opts.height or 40

    ---@type AuraSlot
    local o = IconButton.New(self, name, opts)
    local f = o.frame

    -- Empty-slot background
    if not o.bg then
        o.bg = f:CreateTexture(nil, "ARTWORK", nil, -1)
        o.bg:SetAllPoints()
    end
    o.bg:SetTexCoord(0, 1, 0, 1)
    o.bg:SetTexture(opts.bgTexture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")

    -- Hide IconButton's decorative borders
    if o.topBorder then o.topBorder:Hide() end
    if o.bottomBorder then o.bottomBorder:Hide() end

    -- Labels (hidden by default)
    o.name = Text:New(name .. "_Name", { parent=o, fontTemplate="GameFontHighlightSmall", textPoint="TOP", textY=-2 })
    o.name:SetAllPoints(f); o.name:Hide()

    o.subtitle = Text:New(name .. "_Subtitle", { parent=o, fontTemplate="GameFontNormalSmall", textPoint="BOTTOM", textY=2 })
    o.subtitle:SetAllPoints(f); o.subtitle:Hide()

    -- Hover glow
    o.glow = f:CreateTexture(nil, "OVERLAY")
    o.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    o.glow:SetBlendMode("ADD")
    o.glow:SetAlpha(0.8)
    o.glow:SetSize(f:GetWidth()*1.8, f:GetHeight()*1.8)
    o.glow:SetPoint("CENTER", f, "CENTER")
    o.glow:Hide()

    -- Tooltip
    f:HookScript("OnEnter", function(self)
        if not o.auraId then
            o.glow:Show()
            return
        end

        local reg  = RPE and RPE.Core and RPE.Core.AuraRegistry
        local aura = reg and reg.Get and reg:Get(o.auraId) or nil

        if aura then
            if type(aura.GetTooltip) == "function" then
                -- Aura object with built-in tooltip
                RPE.Common:ShowTooltip(self, aura:GetTooltip())
            else
                -- Raw table: build a simple tooltip
                local t = {
                    title = aura.name or tostring(o.auraId),
                    lines = {},
                }
                if aura.description and aura.description ~= "" then
                    table.insert(t.lines, { text = aura.description, wrap = true, r=0.85, g=0.85, b=0.85 })
                end
                RPE.Common:ShowTooltip(self, t)
            end
        else
            -- Not in active registry: fallback to dataset storage
            local displayName, desc
            local sv = _G.RPEngineDatasetDB
            if sv and sv.datasets then
                for _, ds in pairs(sv.datasets) do
                    local auras = ds and ds.auras
                    if auras then
                        local v = auras[o.auraId] or auras[tostring(o.auraId)]
                        if v then
                            displayName = v.name or displayName
                            desc        = v.description or desc
                            break
                        end
                    end
                end
            end
            displayName = displayName or tostring(o.auraId)

            local t = { title = displayName, lines = {} }
            if desc and desc ~= "" then
                table.insert(t.lines, { text = desc, wrap = true, r=0.85, g=0.85, b=0.85 })
            end
            table.insert(t.lines, { text = "This aura is not part of your active data.", r=1, g=0.25, b=0.25 })
            RPE.Common:ShowTooltip(self, t)
        end

        o.glow:Show()
    end)

    f:HookScript("OnLeave", function()
        o.glow:Hide()
        if RPE and RPE.Common and RPE.Common.HideTooltip then
            RPE.Common:HideTooltip()
        end
        if GameTooltip and GameTooltip:IsOwned(f) then GameTooltip:Hide() end
    end)

    -- Right-click context menu: Delete Entry
    f:HookScript("OnMouseDown", function(self, button)
        if button ~= "RightButton" or not o.auraId then return end

        RPE_UI.Common:ContextMenu(self, function(level, menuList)
            if level == 1 then
                local info = UIDropDownMenu_CreateInfo()
                info.isTitle = true; info.notCheckable = true
                info.text = o._dispName or tostring(o.auraId)
                UIDropDownMenu_AddButton(info, level)

                local del = UIDropDownMenu_CreateInfo()
                del.notCheckable = true
                del.text = "|cffff4040Delete Entry|r"
                del.func = function()
                    local DB = _G.RPE and _G.RPE.Profile and _G.RPE.Profile.DatasetDB
                    local ds = DB and DB:Get(o._datasetName or "")
                    if not (ds and ds.auras and ds.auras[o.auraId]) then return end
                    ds.auras[o.auraId] = nil

                    -- Save dataset
                    if DB and DB.Save then pcall(DB.Save, ds) end

                    -- Refresh registry
                    local reg = _G.RPE and _G.RPE.Core and _G.RPE.Core.AuraRegistry
                    if reg and reg.RefreshFromActiveDatasets then
                        reg:RefreshFromActiveDatasets()
                    elseif reg and reg.Init then
                        reg:Init()
                    end

                    -- Refresh editor sheet if present
                    local DW = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.DatasetWindow
                    if DW and DW._activePage and DW._activePage.Refresh then
                        DW._activePage:Refresh()
                        if DW._recalcSizeForContent then
                            DW:_recalcSizeForContent(DW._activePage.sheet)
                            if DW._resizeSoon then DW:_resizeSoon(DW._activePage.sheet) end
                        end
                    end
                end
                UIDropDownMenu_AddButton(del, level)
            end
        end)
    end)

    if not opts.icon then o.icon:SetTexture(nil) end
    return o
end

-- =========================
-- Public API
-- =========================
function AuraSlot:SetName(text)
    if text and text ~= "" then self.name:SetText(text); self.name:Show()
    else self.name:SetText(""); self.name:Hide() end
end

function AuraSlot:SetSubtitle(text)
    if text and text ~= "" then self.subtitle:SetText(text); self.subtitle:Show()
    else self.subtitle:SetText(""); self.subtitle:Hide() end
end

--- Accepts table payload or nil.
--- { id, icon, name }
function AuraSlot:SetAura(payload)
    if type(payload) == "table" then
        self.auraId    = payload.id
        self._dispName = payload.name
        self._datasetName = payload._datasetName -- track which dataset it belongs to
        self:SetIcon(payload.icon or nil)
    else
        self.auraId   = nil
        self._dispName = nil
        self._datasetName = nil
        self:SetIcon(nil)
    end
end

function AuraSlot:ClearAura()
    self:SetAura(nil)
end

return AuraSlot
