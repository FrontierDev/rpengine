-- RPEngine UI Palette: Dark Iron Dwarf
-- Inspired by WoW's Dark Iron Dwarf racial theme

local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("darkiron", {
    -- Dark Iron Dwarf = iron + lava
    background = { 0.12, 0.10, 0.13, 0.97 }, -- volcanic iron
    divider    = { 0.85, 0.35, 0.10, 0.85 }, -- lava edge lines
    text       = { 0.95, 0.85, 0.70, 1.00 }, -- warm ashen
    textMuted  = { 0.55, 0.45, 0.38, 1.00 }, -- muted iron
    highlight  = { 1.00, 0.45, 0.10, 0.18 }, -- fiery orange hover

    turnIcon   = { 0.85, 0.35, 0.10, 1.00 },

    -- Progress + bars
    progress_default  = { 0.35, 0.18, 0.13, 0.95 }, -- iron
    progress_complete = { 1.00, 0.45, 0.10, 0.95 }, -- lava
    progress_cast     = { 1.00, 0.45, 0.10, 0.90 },
    progress_xp            = { 0.45, 0.30, 0.65, 0.90 },
    progress_health        = { 0.20, 0.55, 0.30, 0.90 },
    progress_mana          = { 0.20, 0.55, 0.70, 0.90 },
    progress_interrupted   = { 0.75, 0.45, 0.20, 0.90 },

    progress_event         = { 0.75, 0.45, 0.20, 0.85 },
    progress_eventcomplete = { 0.20, 0.55, 0.30, 0.90 },

    -- Team accents (for lists, badges, etc.)
    team1 = { 0.35, 0.18, 0.13, 0.90 }, -- iron
    team2 = { 1.00, 0.45, 0.10, 0.90 }, -- lava
})
