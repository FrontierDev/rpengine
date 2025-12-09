-- RPE/Core/Language.lua
-- Language skill and comprehension system
-- Players learn languages and understand a percentage based on skill level (1-300)

RPE      = RPE or {}
RPE.Core = RPE.Core or {}

local LanguageTable = RPE.Core.LanguageTable

---@class Language
---@field playerLanguages table<string, integer>  -- language name -> skill level (1-300)
local Language = {}
Language.__index = Language
RPE.Core.Language = Language

---Create a new language system for a player
---@return Language
function Language.New()
    local o = {
        playerLanguages = {},  -- { ["Common"] = 300, ["Orcish"] = 150, ... }
    }

    RPE.Core.Language = Language
    RPE.Core.Language.playerLanguages = o.playerLanguages

    local lang = setmetatable(o, Language)
    -- Don't initialize defaults here - let ProfileDB decide based on whether profile has languages
    return lang
end

---Initialize faction-based default languages
function Language:InitializeDefaultLanguages()
    local playerFaction = UnitFactionGroup("player")
    
    if playerFaction == "Alliance" then
        self:SetLanguageSkill("Common", 300)
    elseif playerFaction == "Horde" then
        self:SetLanguageSkill("Orcish", 300)
    end
end

---Set a player's skill level in a language (1-300)
---@param languageName string
---@param skill integer
function Language:SetLanguageSkill(languageName, skill)
    skill = math.max(1, math.min(300, tonumber(skill) or 1))
    RPE.Debug:Internal(string.format("[Language.SetLanguageSkill] %s = %d", languageName, skill))
    self.playerLanguages[languageName] = skill
    
    -- Save to profile
    local ProfileDB = RPE.Profile and RPE.Profile.DB
    if ProfileDB then
        local profile = ProfileDB.GetOrCreateActive()
        if profile then
            -- Ensure languages table exists
            if not profile.languages then
                profile.languages = {}
            end
            profile.languages[languageName] = skill
            ProfileDB.SaveProfile(profile)
        end
    end
    
    -- Refresh UI if CharacterSheet is available
    if RPE.Core.Windows and RPE.Core.Windows.CharacterSheet then
        RPE.Core.Windows.CharacterSheet:Refresh()
    end
end

---Get a player's skill level in a language
---@param languageName string
---@return integer skill level (1-300), or 0 if not learned
function Language:GetLanguageSkill(languageName)
    return self.playerLanguages[languageName] or 0
end

---Check if player knows a language at all
---@param languageName string
---@return boolean
function Language:KnowsLanguage(languageName)
    return (self.playerLanguages[languageName] or 0) > 0
end

---Calculate comprehension fraction based on skill level
---@param skill integer (1-300)
---@return number (0.0 to 1.0)
local function getComprehensionFraction(skill)
    -- Linear scaling: skill 1 = 1%, skill 300 = 100%
    return math.max(0, math.min(1, (tonumber(skill) or 0) / 300))
end

---Obfuscate text by replacing words with gibberish based on language vocabulary
---@param text string
---@param languageName string
---@param comprehensionFraction number (0.0 to 1.0)
---@return string obfuscated text
local function obfuscateText(text, languageName, comprehensionFraction)
    if not text or text == "" then return text end
    if comprehensionFraction >= 1.0 then return text end  -- 100% understood, no obfuscation
    
    local wordlist = LanguageTable[languageName]
    if not wordlist then
        -- Unknown language: obfuscate everything
        return text:gsub("%S+", function() return "..." end)
    end
    
    local words = {}
    for w in text:gmatch("%S+") do
        table.insert(words, w)
    end
    
    -- Determine how many words to keep (understood)
    local numToKeep = math.floor(#words * comprehensionFraction)
    
    -- Randomly select which words to keep
    local indices = {}
    for i = 1, #words do table.insert(indices, i) end
    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    
    -- Mark indices to keep
    local keepMap = {}
    for i = 1, numToKeep do
        keepMap[indices[i]] = true
    end
    
    -- Process each word
    for i, word in ipairs(words) do
        if not keepMap[i] then
            -- Extract alphabetic core of the word
            local core = word:match("(%a+)")
            if core then
                local len = #core
                local pool = wordlist[len]
                if pool then
                    local replacement = pool[math.random(#pool)]
                    
                    -- Preserve capitalization of original
                    if core:match("^%u+$") then
                        replacement = replacement:upper()
                    elseif core:match("^%u") then
                        replacement = replacement:sub(1,1):upper() .. replacement:sub(2):lower()
                    else
                        replacement = replacement:lower()
                    end
                    
                    -- Replace core word while preserving surrounding punctuation
                    words[i] = word:gsub(core, replacement)
                else
                    -- No replacement available, use dots
                    words[i] = string.rep(".", #core)
                end
            end
        end
    end
    
    return table.concat(words, " ")
end

---Apply language obfuscation to text based on player's skill
---@param text string The text to obfuscate
---@param languageName string The language being spoken
---@return string The obfuscated (or unobfuscated) text
function Language:ObfuscateText(text, languageName)
    if not text or text == "" then return text end
    
    local skill = self:GetLanguageSkill(languageName)
    if skill >= 300 then
        -- Perfect understanding
        return text
    end
    
    if skill <= 0 then
        -- No understanding at all
        return obfuscateText(text, languageName, 0)
    end
    
    local fraction = getComprehensionFraction(skill)
    return obfuscateText(text, languageName, fraction)
end

---Get all learned languages
---@return table Array of { language=string, skill=integer }
function Language:GetLanguages()
    local result = {}
    for lang, skill in pairs(self.playerLanguages) do
        table.insert(result, { language = lang, skill = skill })
    end
    table.sort(result, function(a, b) return a.language < b.language end)
    return result
end

---Load languages from a profile table
---@param data table Profile data containing languages
function Language:LoadFromProfile(data)
    if not data then return end
    if not data.languages then return end
    
    -- Directly load languages without triggering saves
    for lang, skill in pairs(data.languages) do
        self.playerLanguages[lang] = skill
    end
end

---Save languages to a profile table
---@return table Profile data for languages
function Language:SaveToProfile()
    return { languages = self.playerLanguages }
end

return Language
