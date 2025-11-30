-- UI/Palettes/Horde.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("Horde", {
    -- Horde = crimson + iron/black
    background = { 0.12, 0.05, 0.05, 0.96 }, -- deep maroon
    divider    = { 0.75, 0.40, 0.25, 0.90 }, -- copper/iron edge lines
    text       = { 0.96, 0.94, 0.90, 1.00 }, -- parchment
    textMuted  = { 0.82, 0.74, 0.68, 1.00 }, -- dusty parchment
    highlight  = { 0.90, 0.25, 0.18, 0.10 }, -- subtle crimson hover

    turnIcon   = { 0.90, 0.30, 0.30, 1.00 },

    -- Progress + bars
    progress_default  = { 0.75, 0.20, 0.20, 0.95 }, -- blood red
    progress_complete = { 0.90, 0.60, 0.30, 0.95 }, -- copper/gold
    progress_cast     = { 0.90, 0.60, 0.30, 0.90 },
    progress_mana     = { 0.20, 0.45, 0.70, 0.95 },
    progress_health   = { 0.30, 0.65, 0.25, 0.95 },

    -- Team accents
    team1 = { 0.85, 0.20, 0.20, 0.90 }, -- red
    team2 = { 0.15, 0.15, 0.15, 0.90 }, -- near-black
})
