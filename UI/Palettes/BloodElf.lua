-- UI/Palettes/BloodElf.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("BloodElf", {
    background = { 0.15, 0.05, 0.05, 0.96 },
    divider    = { 1.00, 0.70, 0.20, 0.85 },
    text       = { 1.00, 0.95, 0.85, 1.00 },
    textMuted  = { 0.85, 0.65, 0.50, 1.00 },
    highlight  = { 1.00, 0.65, 0.20, 0.08 },

    -- Optional: override extended semantic keys you care about
    progress_default  = { 0.70, 0.30, 0.10, 0.95 },
    progress_complete = { 1.00, 0.70, 0.20, 0.95 },
})
