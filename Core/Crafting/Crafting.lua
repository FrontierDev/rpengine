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
        
        -- Reset bar to 0 instantly (skip animation)
        if widget.bar then
            widget.bar.value = 0
            widget.bar.targetValue = 0
            if widget.bar.SetValue then
                widget.bar:SetValue(0, 1)
            end
        end
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
        if onDone then onDone() end
        -- Only fade out if there are no more items in the queue AFTER onDone processing
        if widget and widget.FadeOut and (#(self._queue or {}) == 0) and not self._isCasting then
            widget:FadeOut(0.8)
        end
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

    -- Skill up chance based on recipe difficulty
    if recipe.profession and recipe.skill then
        self:_trySkillUp(recipe, profile)
    end

    return true
end

-- ---------------------------------------------------------------------------
-- Skill up chance
-- ---------------------------------------------------------------------------
function Crafting:_trySkillUp(recipe, profile)
    local profName = recipe.profession
    local recipeSkill = tonumber(recipe.skill) or 0
    
    -- Get current profession data (normalize to lowercase key, remove spaces)
    local profs = profile.professions or {}
    local profKey = profName:lower():gsub(" ", "")
    local profData = profs[profKey]
    if not profData or not profData.level then 
        return 
    end
    
    local currentSkill = tonumber(profData.level) or 0
    local MAX_SKILL = 300
    
    -- Don't level up past max
    if currentSkill >= MAX_SKILL then return end
    
    -- Formula: (G - X) / (G - Y)
    -- G = 45 (green threshold)
    -- Y = 15 (yellow threshold)
    -- X = skill difference
    local G = 40
    local Y = 10
    local skillDiff = currentSkill - recipeSkill
    
    -- Only orange/yellow/green recipes can give skill ups
    if skillDiff < 0 then return end    -- red (below requirement)
    if skillDiff > 30 then return end   -- grey (too easy)
    
    -- Calculate odds
    local odds = (G - skillDiff) / (G - Y)
    odds = math.max(0, math.min(1, odds))  -- Clamp to [0, 1]
    
    -- Roll for skill up
    if math.random() < odds then
        profData.level = math.min(MAX_SKILL, currentSkill + 1)
        RPE.Debug:Skill(string.format("Your skill in %s increased to %d", profName, profData.level))
        
        -- Refresh ProfessionSheet UI if available
        local ProfessionSheet = RPE.Core and RPE.Core.Windows and RPE.Core.Windows.ProfessionSheet
        if ProfessionSheet and ProfessionSheet.Refresh then
            ProfessionSheet:Refresh()
        end
    end
end


-- ---------------------------------------------------------------------------
-- Max craftable
-- ---------------------------------------------------------------------------
function Crafting:_maxCraftable(recipe)
    if not recipe then return 0 end
    local req = recipe.reagents or (recipe.GetReagents and recipe:GetReagents()) or {}
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

-- Check if player has enough materials to craft qty times
function Crafting:_canCraft(recipe, qty)
    if not recipe then return false end
    qty = math.max(1, tonumber(qty) or 1)
    local profile = _profile()
    if not profile then return false end
    
    -- Check required reagents for full quantity
    local reagents = recipe.reagents or (recipe.GetReagents and recipe:GetReagents()) or {}
    for _, mat in ipairs(reagents) do
        local need = (tonumber(mat.qty) or 1) * qty
        if not profile:HasItem(tostring(mat.id), need) then
            return false
        end
    end
    return true
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
    local r = _getRecipeById(id)
    if not r then
        RPE.Debug:Warning(("Unknown recipe id: %s"):format(tostring(id)))
        return
    end
    qty = math.max(1, tonumber(qty) or 1)
    if not self:_canCraft(r, qty) then
        RPE.Debug:Warning(("Not enough materials to craft %s x%d"):format(r.name or id, qty))
        return
    end
    self:_enqueue(id, qty)
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
    if not self:_canCraft(r, m) then
        RPE.Debug:Warning(("Not enough materials to craft %s x%d"):format(r.name or id, m))
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

    -- Determine if this is the last item in the queue
    self._cancelCast = _runCast(self, recipe, castTime, onDone, onCancel)
end

setmetatable(Crafting, {
    __call = function(cls)
        cls._queue = cls._queue or {}
        return cls
    end
})

return Crafting
