-- UI/Palettes/WarmAmber.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("WarmAmber", {
    background = { 0.12, 0.09, 0.05, 0.96 },
    divider    = { 0.95, 0.80, 0.40, 0.85 },
    text       = { 0.98, 0.96, 0.90, 1.00 },
    textMuted  = { 0.80, 0.72, 0.60, 1.00 },
    highlight  = { 1.00, 0.85, 0.30, 0.08 },

    -- Optional: override extended semantic keys you care about
    progress_default  = { 0.45, 0.32, 0.12, 0.95 },
    progress_complete = { 0.90, 0.68, 0.20, 0.95 },
})