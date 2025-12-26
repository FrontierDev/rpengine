-- UI/Palettes/NightElf.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("NightElf", {
    background = { 0.06, 0.08, 0.12, 0.96 },
    divider    = { 0.80, 0.85, 1.00, 0.85 },
    text       = { 0.95, 0.98, 1.00, 1.00 },
    textMuted  = { 0.70, 0.80, 0.90, 1.00 },
    highlight  = { 0.75, 0.85, 1.00, 0.08 },

    -- Optional: override extended semantic keys you care about
    progress_default  = { 0.50, 0.65, 0.90, 0.95 },
    progress_complete = { 0.75, 0.90, 1.00, 0.95 },
})
