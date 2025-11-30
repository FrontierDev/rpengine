-- RPE/Core/InteractionExecutor.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Executor = {}
RPE.Core.InteractionExecutor = Executor

-- Registered handlers by action type
local handlers = {}

--- Register a new handler for a given action.
---@param action string
---@param fn fun(opt:table, target:string)
function Executor.RegisterHandler(action, fn)
    if type(action) ~= "string" or type(fn) ~= "function" then return end
    handlers[action:upper()] = fn
end

--- Invoke a handler for the given option
---@param opt table
---@param target string
function Executor.Run(opt, target)
    if not opt or not opt.action then return end
    local fn = handlers[opt.action:upper()]
    if fn then
        fn(opt, target)
    end
end

-- === Default built-in handlers ===========================================

Executor.RegisterHandler("DIALOGUE", function(opt, target)
    RPE.Debug:Internal("Opening dialogue with " .. (target or "?"))
    -- TODO: open dialogue UI
end)

Executor.RegisterHandler("SHOP", function(opt, target)
    RPE.Debug:Internal("Opening shop with " .. (target or "?"))

    local win = _G.RPE and _G.RPE.Core and _G.RPE.Core.Windows and _G.RPE.Core.Windows.ShopWindow
    if not win then
        local ShopWindowClass = RPE_UI.Windows.ShopWindow
        win = ShopWindowClass.New()
        _G.RPE.Core.Windows.ShopWindow = win
    end

    win.items = {}

    if win.AddItems then
        win:AddItems(opt.args or {})
    end

    win.page = 1
    if win.Refresh then win:Refresh() end
    if win.Show then win:Show() end
end)


Executor.RegisterHandler("TRAIN", function(opt, target)
    local mode     = opt.args and opt.args.type or "RECIPES"
    local maxLevel = tonumber(opt.args and opt.args.maxLevel) or 0
    local flags    = opt.args and opt.args.flags or {}

    RPE.Debug:Internal(("Opening trainer (%s - %s) [maxLevel=%d]"):format(
        mode,
        type(flags) == "table" and table.concat(flags or {}, ",") or flags,
        maxLevel
    ))

    -- TrainerWindow class
    local TrainerWindowClass = _G.RPE_UI and _G.RPE_UI.Windows and _G.RPE_UI.Windows.TrainerWindow
    if not TrainerWindowClass then
        RPE.Debug:Error("TrainerWindow class is missing.")
        return
    end

    -- Create or reuse the window instance
    local win = _G.RPE.Core.Windows.TrainerWindow
    if not win then
        win = TrainerWindowClass.New()
        _G.RPE.Core.Windows.TrainerWindow = win
    end

    -- Apply trainer data
    if win.SetTrainerData then
        win:SetTrainerData({
            mode     = mode,
            flags    = flags,
            maxLevel = maxLevel,
            target   = target,
        })
    end

    -- Show the window
    if win.Show then win:Show() end
end)



Executor.RegisterHandler("AUCTION", function(opt, target)
    RPE.Debug:Internal("Opening auction house")
    -- TODO: auction UI
end)

Executor.RegisterHandler("SKIN", function(opt, target)
    RPE.Debug:Internal("Attempting to skin " .. (target or "?"))
    -- TODO: logic for item rolling
end)

Executor.RegisterHandler("SALVAGE_CLOTH", function(opt, target)
    RPE.Debug:Internal("Attempting to salvage cloth from " .. (target or "?"))
    -- TODO: logic for item rolling
end)

Executor.RegisterHandler("RAISE", function(opt, target)
    RPE.Debug:Internal("Attempting to raise the dead: " .. (target or "?"))
    -- TODO: undead logic
end)

return Executor
