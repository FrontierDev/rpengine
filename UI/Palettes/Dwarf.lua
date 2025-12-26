-- UI/Palettes/Dwarf.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("Dwarf", {
    background = { 0.08, 0.07, 0.06, 0.96 },
    divider    = { 0.65, 0.58, 0.50, 0.85 },
    text       = { 0.88, 0.85, 0.80, 1.00 },
    textMuted  = { 0.65, 0.60, 0.55, 1.00 },
    highlight  = { 0.60, 0.52, 0.45, 0.08 },

    -- Optional: override extended semantic keys you care about
    progress_default  = { 0.45, 0.38, 0.30, 0.95 },
    progress_complete = { 0.65, 0.58, 0.50, 0.95 },
})
