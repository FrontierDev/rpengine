-- UI/Colors.lua
-- Exposes: RPE_UI.Colors
RPE_UI        = RPE_UI or {}
RPE_UI.Colors = RPE_UI.Colors or {}

local C = RPE_UI.Colors

-- ===== Default base palette (stable keys) =====
-- Keep keys stable so elements can rely on them.
local DEFAULT = {
    background = { 0.10, 0.10, 0.14, 0.95 },
    divider    = { 0.90, 0.80, 0.60, 0.85 },
    text       = { 0.95, 0.95, 0.98, 1.00 },
    textMuted  = { 0.75, 0.75, 0.80, 1.00 },
    highlight  = { 1.00, 1.00, 1.00, 0.08 }, -- hover overlays, etc.

    -- Extended semantic keys already used by widgets/progress bars
    turnIcon   = { 0.55, 0.75, 0.95, 1.00 },

    textBonus    = { 0.55, 0.95, 0.65, 1.00 },
    textMalus    = { 0.95, 0.55, 0.55, 1.00 },
    textModified = { 0.55, 0.75, 0.95, 1.00 },

    progress_default       = { 0.20, 0.55, 0.30, 0.90 },
    progress_cancel        = { 0.65, 0.20, 0.20, 0.90 },
    progress_complete      = { 0.25, 0.45, 0.75, 0.90 },
    progress_xp            = { 0.45, 0.30, 0.65, 0.90 },
    progress_health        = { 0.20, 0.55, 0.30, 0.90 },
    progress_mana          = { 0.20, 0.55, 0.70, 0.90 },
    progress_interrupted   = { 0.75, 0.45, 0.20, 0.90 },
    progress_cast          = { 0.75, 0.45, 0.20, 0.90 },

    progress_event         = { 0.75, 0.45, 0.20, 0.85 },
    progress_eventcomplete = { 0.20, 0.55, 0.30, 0.90 },

    team1 = { 0.25, 0.45, 0.75, 0.90 },
    team2 = { 0.65, 0.20, 0.20, 0.90 },
    team3 = { 0.45, 0.30, 0.65, 0.90 },
    team4 = { 0.20, 0.55, 0.30, 0.90 },
}

-- Active palette (mutable)
C.palette = {}
local function copyInto(dst, src)
    for k,v in pairs(src) do
        if type(v) == "table" then
            dst[k] = { v[1], v[2], v[3], v[4] }
        else
            dst[k] = v
        end
    end
end
copyInto(C.palette, DEFAULT)

-- ===== Registry + consumers =====
C._palettes  = {}          -- name -> table(colors)
C._active    = "Default"
C._consumers = setmetatable({}, { __mode = "k" })  -- weak keys

function C.RegisterPalette(name, colorsTable)
    if type(name) ~= "string" or name == "" then return end
    if type(colorsTable) ~= "table" then return end
    C._palettes[name] = colorsTable
end

function C.ListPalettes()
    local t = {}
    for k in pairs(C._palettes) do table.insert(t, k) end
    table.sort(t)
    return t
end

function C.GetActivePaletteName()
    return C._active or "Default"
end

-- Merge a palette onto DEFAULT, then notify
local function apply(colorsTable)
    -- reset to default, then overlay
    copyInto(C.palette, DEFAULT)
    for k, v in pairs(colorsTable or {}) do
        if type(v) == "table" then
            C.palette[k] = { v[1], v[2], v[3], v[4] }
        else
            C.palette[k] = v
        end
    end

    -- notify all registered UI objects
    for obj,_ in pairs(C._consumers) do
        local ok, err = pcall(function()
            if obj.ApplyPalette then obj:ApplyPalette() end
        end)
        if not ok then
            -- swallow, but useful for dev
            if RPE and RPE.Debug and RPE.Debug.Error then
                RPE.Debug:Error("Palette consumer error: "..tostring(err))
            end
        end
    end
end

--- Apply by name (registered) or by table.
function C.ApplyPalette(nameOrTable)
    if type(nameOrTable) == "string" then
        local t = C._palettes[nameOrTable]
        if t then
            C._active = nameOrTable
            apply(t)
            return true
        end
        -- unknown -> keep current, return false
        return false
    elseif type(nameOrTable) == "table" then
        C._active = "(Custom)"
        apply(nameOrTable)
        return true
    end
    return false
end

--- UI controls can register to receive ApplyPalette() calls automatically.
function C.RegisterConsumer(obj)
    if type(obj) == "table" then C._consumers[obj] = true end
end
function C.UnregisterConsumer(obj)
    if obj and C._consumers[obj] then C._consumers[obj] = nil end
end

-- ===== Simple API =====
function C.Set(key, r, g, b, a)
    if not key then return end
    local p = C.palette[key]
    if not p then
        C.palette[key] = { r or 1, g or 1, b or 1, a or 1 }
        return
    end
    p[1], p[2], p[3], p[4] = r or p[1], g or p[2], b or p[3], a or p[4]
end

function C.Get(key)
    local p = C.palette[key]
    if not p then return 1, 1, 1, 1 end
    return p[1], p[2], p[3], p[4]
end

-- ===== Tiny helpers (unchanged public surface) =====
function C.ApplyBackground(frameOrTex)
    local r,g,b,a = C.Get("background")
    if frameOrTex and frameOrTex.SetColorTexture then
        frameOrTex:SetColorTexture(r, g, b, a)
    end
end

function C.ApplyDivider(tex)
    local r,g,b,a = C.Get("divider")
    if tex and tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a)
    end
end

function C.ApplyText(fs, variant)
    local r,g,b,a = C.Get(variant or "text")
    if fs and fs.SetTextColor then
        fs:SetTextColor(r, g, b, a or 1)
    end
end

function C.ApplyHighlight(tex)
    local r,g,b,a = C.Get("highlight")
    if tex and tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a)
    end
end

-- Register the built-in default
C.RegisterPalette("Default", DEFAULT)

-- Optional: a tiny slash helper to switch quickly: /rpepal <name>
