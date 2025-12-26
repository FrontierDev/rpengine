-- UI/Palettes/Draenei.lua
local C = RPE_UI and RPE_UI.Colors
if not C then return end

C.RegisterPalette("Draenei", {
    background = { 0.08, 0.06, 0.10, 0.96 },
    divider    = { 0.85, 0.70, 0.95, 0.85 },
    text       = { 0.95, 0.90, 1.00, 1.00 },
    textMuted  = { 0.80, 0.70, 0.85, 1.00 },
    highlight  = { 0.90, 0.65, 1.00, 0.08 },

    -- Optional: override extended semantic keys you care about
    progress_default  = { 0.70, 0.50, 0.85, 0.95 },
    progress_complete = { 0.95, 0.70, 1.00, 0.95 },
})
