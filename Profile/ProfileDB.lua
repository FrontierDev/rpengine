-- RPE/Profile/ProfileDB.lua
-- Persistence layer for CharacterProfile objects using RPEngineProfilesDB.

RPE = RPE or {}
RPE.Profile = RPE.Profile or {}

local CharacterProfile = RPE.Profile.CharacterProfile

-- SavedVariables root (declared in .toc as `## SavedVariables: RPEngineProfilesDB`)
_G.RPEngineProfilesDB = _G.RPEngineProfilesDB or {}

local DB_SCHEMA_VERSION = 1
local loaded = false
local _activeInstance = nil  -- In-memory instance of active profile, persists for the session

local ProfileDB = {}
RPE.Profile.DB = ProfileDB  -- <-- do NOT overwrite RPE.Profile

-- === Internal helpers ===
local function GetCharacterKey()
    local name = UnitName and UnitName("player") or "Player"
    local realm = GetRealmName and GetRealmName() or "Realm"
    return (name or "Player") .. "-" .. (realm or "Realm")
end

local function EnsureDB()
    local db = _G.RPEngineProfilesDB
    db._schema = db._schema or DB_SCHEMA_VERSION
    db.currentByChar = db.currentByChar or {}   -- [ "Name-Realm" ] = "ProfileName"
    db.profiles = db.profiles or {}             -- [ "ProfileName" ] = serialized CharacterProfile
    db.lastLFRPChannel = db.lastLFRPChannel or {}  -- [ "Name-Realm" ] = "ChannelName"
    return db
end

-- === Public API ===
--- Load the *active* profile for the current character, if set and present.
---@return CharacterProfile|nil
function ProfileDB.LoadActiveForCurrentCharacter()
    if loaded then 
        return _activeInstance
    end  -- only load once per session

    local db = EnsureDB()
    local key = GetCharacterKey()
    local profName = db.currentByChar[key]
    if not profName or profName == "" then return nil end

    local t = db.profiles[profName]
    if not t then
        db.currentByChar[key] = nil
        return nil
    end

    local profile = CharacterProfile.FromTable(t)
    -- Equipment stat mods are already recalculated in CharacterProfile constructor via RecalculateEquipmentStats()
    -- Do NOT call Equip() here as it would double-apply the mods via applyEquipMods() using +1 delta

    loaded = true
    return profile
end

--- Set which profile name should auto-load for the current character.
---@param profileName string
function ProfileDB.SetActiveProfileNameForCurrentCharacter(profileName)
    assert(type(profileName) == "string" and profileName ~= "", "Active profile name required")
    local db = EnsureDB()
    local key = GetCharacterKey()
    db.currentByChar[key] = profileName
end

--- Save (upsert) a profile by name.
---@param profile CharacterProfile
function ProfileDB.SaveProfile(profile)
    assert(getmetatable(profile) == CharacterProfile, "SaveProfile: CharacterProfile expected")
    
    -- Guard: only allow saving profiles for the current player character
    -- NPC profiles should NEVER be persisted to the database
    local playerName = UnitName("player")
    if profile.name and profile.name:lower() ~= (playerName or ""):lower() then
        RPE.Debug:Error(string.format(
            "Attempted to save NPC profile '%s' for player '%s' - rejected", 
            profile.name, playerName))
        return
    end
    
    local db = EnsureDB()
    profile.updatedAt = time() or profile.updatedAt
    db.profiles[profile.name] = profile:ToTable()
end

--- Get an existing profile by name (or nil).
---@param name string
---@return CharacterProfile|nil
function ProfileDB.GetByName(name)
    local db = EnsureDB()
    local t = db.profiles[name]
    return t and CharacterProfile.FromTable(t) or nil
end

--- Create a new profile with this name (fails if name exists).
---@param name string
---@param opts table|nil
---@return CharacterProfile
function ProfileDB.CreateNew(name, opts)
    assert(type(name) == "string" and name ~= "", "CreateNew: name required")
    local db = EnsureDB()
    assert(db.profiles[name] == nil, "CreateNew: profile with this name already exists")

    local p = CharacterProfile:New(name, opts)
    db.profiles[name] = p:ToTable()

    -- *** make sure this character points at the new profile ***
    local key = GetCharacterKey()
    db.currentByChar[key] = name

    return p
end



--- Get or create a profile by name.
---@param name string
---@param opts table|nil
---@return CharacterProfile
function ProfileDB.GetOrCreateByName(name, opts)
    local existing = ProfileDB.GetByName(name)

    if existing then 
        return existing
    end

    return ProfileDB.CreateNew(name, opts)
end

--- Get or create the active profile for the current character.
--- If none is mapped, defaults to the *character's name* as the profile name.
---@return CharacterProfile
function ProfileDB.GetOrCreateActive()
    -- Return the same instance that was loaded at login
    if _activeInstance then
        return _activeInstance
    end
    
    local db = EnsureDB()
    local key = GetCharacterKey()
    local profName = db.currentByChar[key]

    if not profName or profName == "" then
        local charName = UnitName and UnitName("player") or "Player"
        profName = tostring(charName)
        db.currentByChar[key] = profName
    end

    local profile = ProfileDB.GetOrCreateByName(profName)
    _activeInstance = profile  -- Cache it for session
    
    -- Update developer status for the profile based on current player
    if profile and type(profile.UpdateDeveloperStatus) == "function" then
        profile:UpdateDeveloperStatus()
    end
    
    -- Re-apply equipped item mods now that profile is fully set up as active
    if profile and profile._ReapplyEquipMods then
        profile:_ReapplyEquipMods()
    end
    
    return profile
end

--- Reset the active instance cache (useful when exiting temporary mode to refresh which profile is active)
function ProfileDB.ResetActiveInstance()
    _activeInstance = nil
    loaded = false  -- Allow LoadActiveForCurrentCharacter to reload from DB next time
end

--- Rename a profile. Also updates any character mappings pointing to it.
---@param oldName string
---@param newName string
function ProfileDB.Rename(oldName, newName)
    assert(type(oldName) == "string" and oldName ~= "", "Rename: oldName required")
    assert(type(newName) == "string" and newName ~= "", "Rename: newName required")

    local db = EnsureDB()
    assert(db.profiles[oldName], "Rename: source profile not found")
    assert(not db.profiles[newName], "Rename: target name already exists")

    -- Move data
    db.profiles[newName] = db.profiles[oldName]
    db.profiles[newName].name = newName
    db.profiles[oldName] = nil

    -- Update character mappings
    for k, v in pairs(db.currentByChar) do
        if v == oldName then
            db.currentByChar[k] = newName
        end
    end
end

--- Delete a profile by name. Clears character mappings referencing it.
---@param name string
function ProfileDB.Delete(name)
    local db = EnsureDB()
    if not db.profiles[name] then return end

    db.profiles[name] = nil
    for k, v in pairs(db.currentByChar) do
        if v == name then
            db.currentByChar[k] = nil
        end
    end
end

--- Wipe and recreate the active profile for the current character.
---@param opts table|nil
---@return CharacterProfile
function ProfileDB.RecreateActive(opts)
    local db = EnsureDB()
    local key = GetCharacterKey()
    local oldName = db.currentByChar[key]

    if oldName and db.profiles[oldName] then
        db.profiles[oldName] = nil
    end

    -- Default to character's name as profile name
    local charName = UnitName and UnitName("player") or "Player"
    local newName = tostring(charName)

    db.currentByChar[key] = newName
    local p = CharacterProfile:New(newName, opts)
    db.profiles[newName] = p:ToTable()

    return p
end

--- List all profile names.
---@return string[]
function ProfileDB.ListNames()
    local db = EnsureDB()
    local out = {}
    for k, _ in pairs(db.profiles) do
        table.insert(out, k)
    end
    table.sort(out)
    return out
end

--- Save the last LFRP channel name for the current character.
---@param channelName string
function ProfileDB.SetLastLFRPChannel(channelName)
    local db = EnsureDB()
    local key = GetCharacterKey()
    db.lastLFRPChannel[key] = channelName
    RPE.Debug:Internal(string.format("[LFRP] Saved channel '%s' for key '%s'", tostring(channelName), tostring(key)))
end

--- Get the last LFRP channel name for the current character.
---@return string|nil
function ProfileDB.GetLastLFRPChannel()
    local db = EnsureDB()
    local key = GetCharacterKey()
    local channel = db.lastLFRPChannel[key]
    RPE.Debug:Internal(string.format("[LFRP] Retrieved channel for key '%s': %s", tostring(key), tostring(channel or "nil")))
    -- Ensure we return a string or nil, never a table
    if type(channel) == "string" then
        return channel
    end
    return nil
end

--- Initialize the UI after profile is loaded. Called by PLAYER_LOGIN.
function ProfileDB.InitializeUI()
    local profile = ProfileDB.GetOrCreateActive()
    
    -- Recalculate equipment stats once after profile is fully loaded and ready
    if profile and type(profile.RecalculateEquipmentStats) == "function" then
        profile:RecalculateEquipmentStats()
    end
    
    -- Initialize the Language system with profile data
    local Language = RPE.Core and RPE.Core.Language
    if Language then
        local lang = Language.New()
        -- Load languages from profile if they exist
        if profile.languages and next(profile.languages) ~= nil then
            lang:LoadFromProfile(profile)
        else
            -- No saved languages, initialize with faction defaults
            lang:InitializeDefaultLanguages()
        end
    end
    
    -- Create the main window with all sheets
    RPE_UI.Windows.MainWindow.New()

    -- Create Event window
    local eventWindow = RPE_UI.Windows.EventWindow.New()

    -- Equipment stats already recalculated in constructor, no need to do it again

    RPE.Core.Resources:Init()

    -- Refresh the character and statistics sheets with the loaded profile
    if RPE_UI.Windows.CharacterSheetInstance and RPE_UI.Windows.CharacterSheetInstance.Refresh then
        RPE_UI.Windows.CharacterSheetInstance:Refresh()
    end
    if RPE_UI.Windows.StatisticSheetInstance and RPE_UI.Windows.StatisticSheetInstance.Refresh then
        RPE_UI.Windows.StatisticSheetInstance:Refresh()
    end

    -- Resize MainWindow to fit the loaded stats
    local mainWindow = _G.RPE.Core.Windows.MainWindow
    if mainWindow and mainWindow.ShowTab then
        mainWindow:ShowTab("statistics")
    end

    -- Apply the user's chosen palette (or Default) BEFORE creating any windows
    if RPE_UI and RPE_UI.Colors and RPE_UI.Colors.ApplyPalette then
        RPE_UI.Colors.ApplyPalette(profile and profile:GetPaletteName() or "Default")
    end

    RPE.Core = RPE.Core or {}
    if not RPE.Core.Tooltip then
        RPE.Core.Tooltip = RPE_UI.Windows.TooltipWidget.New({
            onlyWhenUIHidden = true,  -- auto-hide when UI is visible
            maxWidth = 200,
        })
    end

    -- Create the chat box once
    RPE.Core.Windows      = RPE.Core.Windows or {}
    RPE.Core.Windows.Chat = RPE.Core.Windows.Chat or RPE_UI.Windows.ChatBoxWidget.New({
        point = "BOTTOMLEFT", rel = "BOTTOMLEFT", x = 280, y = 80,
        onlyWhenUIHidden = true,  -- default: show automatically only when UI is hidden by Alt+Z
        -- onlyWhenUIHidden = false, -- uncomment if you want it visible all the time
    })


    RPE.Core.CombatText = RPE.Core.CombatText or {}
    local fct = RPE_UI.Prefabs.FloatingCombatText:New("RPE_FCT_Player", {
        parent       = WorldFrame,
        setAllPoints = true,
        direction    = "UP",
    })
    -- Attach methods directly for compatibility
    -- Compatibility: use AddNumber for floating combat text
    fct.ShowDamageReceived = function(inst, amount, isCrit)
        inst:AddNumber(amount, "damage", { isCrit = isCrit })
    end
    
    fct.ShowHealReceived = function(inst, amount, isCrit)
        inst:AddNumber(amount, "heal", { isCrit = isCrit })
    end
    RPE.Core.CombatText.Screen = fct

    -- Create the action bar widget and hide it.
    local ABW = RPE.Core.Windows.ActionBarWidget or RPE_UI.Windows.ActionBarWidget.New({
        numSlots = RPE.ActiveRules:Get("action_bar_slots") or 5,
        slotSize = 32,
        spacing  = 4,
        point = "BOTTOM", rel = "BOTTOM", y = 160,
    })
    ABW:LoadFromProfile(RPE.Profile.DB:GetOrCreateActive())
    ABW:Hide() -- if not needed immediately

    -- Keep hidden until /rpe
    local main = RPE_UI.Windows.MainWindow and _G.RPE.Core.Windows.MainWindow
    if main and main.Hide then main:Hide() end
    if RPE.Core.Windows.Chat then RPE_UI.Common:Hide(RPE.Core.Windows.Chat) end
    if RPE.Core.Windows.EventWindow then RPE_UI.Common:Hide(RPE.Core.Windows.EventWindow) end
end-- Auto-save on logout
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
        local profile = RPE.Profile.DB.GetOrCreateActive()
        if profile then
            RPE.Profile.DB.SaveProfile(profile)
        end
    elseif event == "PLAYER_LOGIN" then
        -- Leave the last LFRP channel we were in before leaving this realm
        local lastChannel = ProfileDB.GetLastLFRPChannel()
        RPE.Debug:Internal(string.format("[LFRP] Last channel for this character: %s", tostring(lastChannel or "none")))
        if lastChannel and lastChannel ~= "" then
            ChatFrame1EditBox:SetText("/leave " .. lastChannel)
            ChatEdit_SendText(ChatFrame1EditBox, 0)
        end
        
        ProfileDB.InitializeUI()
    end
end)