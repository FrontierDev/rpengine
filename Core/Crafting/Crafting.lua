-- Interface/AddOns/RPEngine/Core/Crafting/Crafting.lua
-- Orchestrates crafting: queuing, cast bar, perform-on-finish, repeat until empty.

RPE       = RPE or {}
RPE.Core  = RPE.Core or {}
RPE.Debug = RPE.Debug or { Print=function() end, Warning=function() end, Error=function() end }

local Recipe         = RPE.Core and RPE.Core.Recipe
local RecipeRegistry = RPE.Core and RPE.Core.RecipeRegistry
local CastBarWidget  = RPE_UI and RPE_UI.Windows and RPE_UI.Windows.CastBarWidget
local Common         = RPE.Common or {}

---@class Crafting
---@field _queue { recipeId:string, qty:number }[]
---@field _current { recipeId:string, remaining:number }|nil
---@field _widget any|nil
---@field _isCasting boolean
local Crafting = {}
Crafting.__index = Crafting
RPE.Core.Crafting = Crafting

Crafting.DEFAULT_CAST_TIME = 2.0 -- seconds if recipe has no castTime

-- ---------------------------------------------------------------------------
-- Profile accessor
-- ---------------------------------------------------------------------------
local function _profile()
    if RPE.Profile and RPE.Profile.DB and RPE.Profile.DB.GetOrCreateActive then
        return RPE.Profile.DB.GetOrCreateActive()
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- RecipeRegistry accessor
-- ---------------------------------------------------------------------------
local function _getRecipeById(id)
    if not RecipeRegistry or not id then return nil end
    if RecipeRegistry.GetById then return RecipeRegistry:GetById(id) end
    if RecipeRegistry.Get then return RecipeRegistry:Get(id) end
    if RecipeRegistry.GetRecipe then return RecipeRegistry:GetRecipe(id) end
    local map = rawget(RecipeRegistry, "_map")
    if type(map) == "table" then return map[id] end
    return nil
end

-- ---------------------------------------------------------------------------
-- Cast bar
-- ---------------------------------------------------------------------------
local function _ensureWidget(self)
    local CB = RPE.Core.Windows and RPE.Core.Windows.CastBarWidget
    if not CB then
        if RPE_UI and RPE_UI.Windows and RPE_UI.Windows.CastBarWidget and RPE_UI.Windows.CastBarWidget.New then
            CB = RPE_UI.Windows.CastBarWidget.New()
            RPE.Core.Windows.CastBarWidget = CB
            if RPE.Debug and RPE.Debug.Print then
                RPE.Debug:Internal("Created CastBarWidget for crafting.")
            end
        end
    end
    self._widget = CB
    return CB
end

local function _runCast(self, recipe, durationSec, onDone, onCancel)
    local widget = _ensureWidget(self)
    local icon = nil
    local outItem = recipe and recipe.GetOutputItem and recipe:GetOutputItem() or nil
    if outItem and outItem.icon then icon = outItem.icon end
    local name = (recipe and (recipe.name or recipe.id)) or "Crafting"

    if widget then
        if widget.SetSpell then
            widget:SetSpell({ name = name, icon = icon })
        elseif widget.icon and widget.icon.SetIcon then
            widget.icon:SetIcon(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        if widget.SetTitle then
            widget:SetTitle(name)
        elseif widget.title and widget.title.SetText then
            widget.title:SetText(name)
        end
        if widget.Show then widget:Show() end
    end

    local start = GetTime()
    local total = math.max(0.1, tonumber(durationSec) or Crafting.DEFAULT_CAST_TIME)

    local ticker = C_Timer.NewTicker(0.02, function()
        local elapsed = GetTime() - start
        local done = math.min(elapsed, total)
        if widget and widget.bar and widget.bar.SetValue then
            widget.bar:SetValue(done, total)
        end
    end)

    C_Timer.After(total, function()
        if ticker then ticker:Cancel() end
        if widget and widget.bar and widget.bar.SetValue then
            widget.bar:SetValue(total, total)
            if widget.bar.TriggerFlash then widget.bar:TriggerFlash() end
        end
        if widget and widget.FadeOut then widget:FadeOut(0.8) end
        if onDone then onDone() end
    end)

    return function(reason)
        if ticker then ticker:Cancel() end
        if widget and widget.Interrupt then widget:Interrupt(nil, reason or "Cancelled") end
        if onCancel then onCancel(reason) end
    end
end

-- ---------------------------------------------------------------------------
-- Perform recipe once
-- ---------------------------------------------------------------------------
function Crafting:_performOnce(recipe)
    if not recipe then return false end
    local profile = _profile()
    if not profile then
        RPE.Debug:Error("Crafting: No active profile available.")
        return false
    end

    -- Required reagents (use recipe.reagents)
    local reagents = recipe.reagents or (recipe.GetReagents and recipe:GetReagents()) or {}
    for _, mat in ipairs(reagents) do
        local need = tonumber(mat.qty) or 0
        if need > 0 and not profile:HasItem(tostring(mat.id), need) then
            RPE.Debug:Warning(("Missing reagent %s (need %d)"):format(tostring(mat.id), need))
            return false
        end
    end
    -- Consume reagents
    for _, mat in ipairs(reagents) do
        local need = tonumber(mat.qty) or 0
        if need > 0 then
            profile:RemoveItem(tostring(mat.id), need)
        end
    end

    -- Optional reagents
    local optional = recipe.optional or {}
    for _, mat in ipairs(optional) do
        local need = tonumber(mat.qty) or 0
        if need > 0 and profile:HasItem(tostring(mat.id), need) then
            profile:RemoveItem(tostring(mat.id), need)
        end
    end

    -- Output
    local outId  = recipe.outputItemId
    local outQty = (recipe.GetOutputQty and tonumber(recipe:GetOutputQty())) or tonumber(recipe.outputQty) or 1
    if outId and outQty > 0 then
        profile:AddItem(tostring(outId), outQty)
        RPE.Debug:Print(("Crafted %s x%d"):format(outId, outQty))
    else
        RPE.Debug:Warning("Recipe has no output item defined.")
    end

    return true
end


-- ---------------------------------------------------------------------------
-- Max craftable
-- ---------------------------------------------------------------------------
function Crafting:_maxCraftable(recipe)
    if not recipe then return 0 end
    local req = recipe.required or (recipe.GetRequired and recipe:GetRequired()) or {}
    if #req == 0 then return 9999 end
    local profile = _profile()
    local maxCount = math.huge
    for _, mat in ipairs(req) do
        local have = profile:GetItemQty(tostring(mat.id))
        local per  = math.max(1, tonumber(mat.qty) or 1)
        maxCount = math.min(maxCount, math.floor(have / per))
    end
    if maxCount == math.huge then maxCount = 0 end
    return math.max(0, maxCount)
end

-- ---------------------------------------------------------------------------
-- Queue
-- ---------------------------------------------------------------------------
function Crafting:Clear()
    self._queue = {}
    self._current = nil
    self._isCasting = false
end

function Crafting:_enqueue(recipeId, qty)
    self._queue = self._queue or {}
    table.insert(self._queue, { recipeId = tostring(recipeId), qty = math.max(1, tonumber(qty) or 1) })
end

function Crafting:CraftRecipe(recipeOrId, qty)
    local id = (type(recipeOrId) == "table" and recipeOrId.id) or tostring(recipeOrId)
    if not id then return end
    self:_enqueue(id, math.max(1, tonumber(qty) or 1))
    self:_pump()
end

function Crafting:CraftRecipeAll(recipeOrId)
    local id = (type(recipeOrId) == "table" and recipeOrId.id) or tostring(recipeOrId)
    if not id then return end
    local r = _getRecipeById(id)
    if not r then
        RPE.Debug:Warning(("Unknown recipe id (All): %s"):format(tostring(id)))
        return
    end
    local m = self:_maxCraftable(r)
    if m <= 0 then
        RPE.Debug:Warning(("No materials available to craft %s."):format(id))
        return
    end
    self:_enqueue(id, m)
    self:_pump()
end

function Crafting:Cancel(reason)
    self._queue = {}
    self._current = nil
    if self._cancelCast then self._cancelCast(reason or "Cancelled") end
    self._cancelCast = nil
    self._isCasting = false
end

function Crafting:_pump()
    if self._isCasting then return end
    self._queue = self._queue or {}

    local nextEntry = table.remove(self._queue, 1)
    if not nextEntry then return end

    local r = _getRecipeById(nextEntry.recipeId)
    if not r then
        RPE.Debug:Error(("Unknown recipe id: %s"):format(tostring(nextEntry.recipeId)))
        return self:_pump()
    end

    self._current = { recipeId = r.id, remaining = nextEntry.qty }
    self:_startOne(r)
end

function Crafting:_startOne(recipe)
    self._isCasting = true

    local castTime = tonumber(recipe.castTime) or Crafting.DEFAULT_CAST_TIME
    local function onDone()
        local ok = self:_performOnce(recipe)
        if not ok then
            self._isCasting = false
            self._current = nil
            self:_pump()
            return
        end

        if self._current and self._current.remaining then
            self._current.remaining = self._current.remaining - 1
        end

        if self._current and (self._current.remaining or 0) > 0 then
            C_Timer.After(0.05, function()
                self._isCasting = false
                self:_startOne(recipe)
            end)
        else
            self._isCasting = false
            self._current = nil
            self:_pump()
        end
    end

    local function onCancel()
        self._isCasting = false
        self._current = nil
        self:_pump()
    end

    self._cancelCast = _runCast(self, recipe, castTime, onDone, onCancel)
end

setmetatable(Crafting, {
    __call = function(cls)
        cls._queue = cls._queue or {}
        return cls
    end
})

return Crafting
