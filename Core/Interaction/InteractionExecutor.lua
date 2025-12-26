-- RPE/Core/InteractionExecutor.lua
RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local Executor = {}
RPE.Core.InteractionExecutor = Executor

-- Track NPCs that have been looted (guid -> true)
local lootedNPCs = {}

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

--- Check if an NPC has already been looted
---@param guid string
---@return boolean
function Executor.HasBeenLooted(guid)
    return lootedNPCs[guid] or false
end

--- Mark an NPC as looted
---@param guid string
function Executor.MarkAsLooted(guid)
    if guid then
        lootedNPCs[guid] = true
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
    
    if not opt.output or #opt.output == 0 then return end
    
    local profile = RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
    if not profile then return end
    
    local guid = UnitGUID("target")
    
    local Common = RPE.Common
    local Formula = RPE.Core.Formula
    
    for _, outputSpec in ipairs(opt.output) do
        -- Check if roll succeeds based on chance
        if not outputSpec.chance or math.random() <= outputSpec.chance then
            -- Roll quantity using Formula:Roll() for dice notation
            local qty = 1
            if outputSpec.qty then
                if type(outputSpec.qty) == "string" then
                    qty = Formula:Roll(outputSpec.qty, profile)
                else
                    qty = tonumber(outputSpec.qty) or 1
                end
            end
            
            qty = math.floor(math.max(0, qty))
            if qty > 0 then
                profile:AddItem(outputSpec.itemId, qty)
            end
        end
    end
    
    -- Mark this NPC as looted
    if guid then
        Executor.MarkAsLooted(guid)
    end
end)

Executor.RegisterHandler("SALVAGE_CLOTH", function(opt, target)
    RPE.Debug:Internal("Attempting to salvage cloth from " .. (target or "?"))
    
    if not opt.output or #opt.output == 0 then return end
    
    local profile = RPE.Profile.DB and RPE.Profile.DB:GetOrCreateActive()
    if not profile then return end
    
    local guid = UnitGUID("target")
    
    local Common = RPE.Common
    local Formula = RPE.Core.Formula
    
    for _, outputSpec in ipairs(opt.output) do
        -- Check if roll succeeds based on chance
        if not outputSpec.chance or math.random() <= outputSpec.chance then
            -- Roll quantity using Formula:Roll() for dice notation
            local qty = 1
            if outputSpec.qty then
                if type(outputSpec.qty) == "string" then
                    qty = Formula:Roll(outputSpec.qty, profile)
                else
                    qty = tonumber(outputSpec.qty) or 1
                end
            end
            
            qty = math.floor(math.max(0, qty))
            if qty > 0 then
                profile:AddItem(outputSpec.itemId, qty)
            end
        end
    end
    
    -- Mark this NPC as looted
    if guid then
        Executor.MarkAsLooted(guid)
    end
end)

Executor.RegisterHandler("RAISE", function(opt, target)
    RPE.Debug:Internal("Attempting to raise the dead: " .. (target or "?"))
    -- TODO: undead logic
end)

return Executor
