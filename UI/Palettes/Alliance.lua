-- UI/Palettes/Alliance.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("Alliance", {
    -- Alliance = blue + gold
    background = { 0.09, 0.12, 0.20, 0.96 }, -- deep navy
    divider    = { 0.95, 0.84, 0.40, 0.90 }, -- bright gold edge lines
    text       = { 0.95, 0.96, 0.99, 1.00 }, -- near-white
    textMuted  = { 0.74, 0.78, 0.88, 1.00 }, -- muted steel-blue
    highlight  = { 0.98, 0.82, 0.30, 0.10 }, -- subtle gold hover

    turnIcon   = { 0.48, 0.68, 0.98, 1.00 },

    -- Progress + bars
    progress_default  = { 0.22, 0.46, 0.82, 0.95 }, -- Alliance blue
    progress_complete = { 0.90, 0.76, 0.30, 0.95 }, -- gold
    progress_cast     = { 0.90, 0.76, 0.30, 0.90 },
    progress_mana     = { 0.25, 0.55, 0.90, 0.95 },
    progress_health   = { 0.20, 0.65, 0.30, 0.95 },

    -- Team accents (for lists, badges, etc.)
    team1 = { 0.25, 0.45, 0.90, 0.90 }, -- blue
    team2 = { 0.90, 0.76, 0.30, 0.90 }, -- gold
})
