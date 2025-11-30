-- UI/Palettes/WarmAmber.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("Default", {
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
})