-- RPE/Data/LanguageTable.lua
-- Language vocabulary tables for obfuscating and translating text based on player language skill
-- Language skill ranges from 1-300, where 300 = 100% comprehension

local LanguageTable = {}
RPE      = RPE or {}
RPE.Core = RPE.Core or {}
RPE.Core.LanguageTable = LanguageTable

LanguageTable.Common = {
    [1] = { "A", "E", "I", "O", "U", "Y" },
    [2] = { "An", "Ko", "Lo", "Lu", "Me", "Ne", "Re", "Ru", "Se", "Ti", "Va", "Ve" },
    [3] = { "Ash", "Bor", "Bur", "Far", "Gol", "Hir", "Lon", "Mod", "Nud", "Ras", "Ver", "Vil", "Vos" },
    [4] = { "Ador", "Agol", "Dana", "Goth", "Lars", "Noth", "Nuff", "Odes", "Ruff", "Thor", "Uden", "Veld", "Vohl", "Vrum" },
    [5] = { "Algos", "Barad", "Borne", "Melka", "Ergin", "Eynes", "Garde", "Gloin", "Majis", "Nagan", "Novas", "Regen", "Tiras", "Wirsh" },
    [6] = { "Aesire", "Aziris", "Daegil", "Danieb", "Ealdor", "Engoth", "Goibon", "Mandos", "Nevren", "Rogesh", "Rothas", "Ruftos", "Skilde", "Valesh", "Vandar", "Waldir" },
    [7] = { "Andovis", "Ewikkdan", "Faergas", "Forthis", "Kaelsig", "Koshvel", "Lithtos", "Nandige", "Nostyec", "Novaedi", "Sturume", "Vassild" },
    [8] = { "Aldonoth", "Cynegold", "Endirvis", "Hamerung", "Landowar", "Lordaere", "Methrine", "Ruftvess", "Thorniss" },
    [9] = { "Aetwinter", "Danagarde", "Eloderung", "Firalaine", "Gloinador", "Gothalgos", "Regenthor", "Udenmajis", "Vandarwos", "Veldbarad" },
    [10] = { "Aelgestron", "Cynewalden", "Danavandar", "Dyrstigost", "Falhedring", "Vastrungen" },
    [11] = { "Agolandovis", "Bornevalesh", "Dornevalesh", "Farlandowar", "Forthasador", "Thorlithtos", "Vassildador", "Wershaesire" },
    [12] = { "Golveldbarad", "Mandosdaegil", "Nevrenrothas", "Waldirskilde" }    
}

LanguageTable.Orcish = {
    [1] = { "A", "N", "G", "O", "L" },
    [2] = { "Ha", "Ko", "No", "Mu", "Ag", "Ka", "Gi", "Il" },
    [3] = { "Lok", "Tar", "Kaz", "Ruk", "Kek", "Mog", "Zug", "Gul", "Nuk", "Aaz", "Kil", "Ogg" },
    [4] = { "Rega", "Nogu", "Tago", "Uruk", "Kagg", "Zaga", "Grom", "Ogar", "Gesh", "Thok", "Dogg", "Maka", "Maza" },
    [5] = { "Regas", "Nogah", "Kazum", "Magan", "No'bu", "Golar", "Throm", "Zugas", "Re'ka", "No'ku", "Ro'th" },
    [6] = { "Thrakk", "Revash", "Nakazz", "Moguna", "No'gor", "Goth'a", "Raznos", "Ogerin", "Gezzno", "Thukad", "Makogg", "Aaz'no" },
    [7] = { "Lok'Tar", "Gul'rok", "Kazreth", "Tov'osh", "Zil'Nok", "Rath'is", "Kil'azi" },
    [8] = { "Throm'ka", "Osh'Kava", "Gul'nath", "Kog'zela", "Ragath'a", "Zuggossh", "Moth'aga" },
    [9] = { "Tov'nokaz", "Osh'kazil", "No'throma", "Gesh'nuka", "Lok'mogul", "Lok'bolar", "Ruk'ka'ha" },
    [10] = { "Regasnogah", "Kazum'nobu", "Throm'bola", "Gesh'zugas", "Maza'rotha", "Ogerin'naz" },
    [11] = { "Thrakk'reva", "Kaz'goth'no", "No'gor'goth", "Kil'azi'aga", "Zug-zug'ama", "Maza'thrakk" },
    [12] = { "Lokando'nash", "Ul'gammathar", "Golgonnashar", "Dalggo'mazah" },
    [13] = { "Khaz'rogg'ahn", "Moth'kazoroth" }
}

LanguageTable.Dwarvish = {
    [1] = { "A" },
    [2] = { "Am", "Ga", "Go", "Ke", "Lo", "Ok", "Ta", "Um", "We", "Zu" },
    [3] = { "Ahz", "Dum", "Dun", "Eft", "Gar", "Gor", "Hor", "Kha", "Mok", "Mos", "Red", "Ruk" },
    [4] = { "Gear", "Gosh", "Grum", "Guma", "Helm", "Hine", "Hoga", "Hrim", "Khaz", "Kost", "Loch", "Modr", "Rand", "Rune", "Thon" },
    [5] = { "Algaz", "Angor", "Dagum", "Frean", "Gimil", "Goten", "Havar", "Havas", "Mitta", "Modan", "Modor", "Scyld", "Skalf", "Thros", "Weard" },
    [6] = { "Bergum", "Drugan", "Farode", "Haldir", "Haldji", "Modgud", "Modoss", "Mogoth", "Robush", "Rugosh", "Skolde", "Syddan" },
    [7] = { "Dun-fel", "Ganrokh", "Geardum", "Godkend", "Haldren", "Havagun", "Kaelsag", "Kost-um", "Mok-kha", "Thorneb", "Zu-Modr" },
    [8] = { "Azregahn", "Gefrunon", "Golganar", "Khaz-dum", "Khazrega", "Misfaran", "Mogodune", "Moth-tur", "Ok-Hoga", "Thulmane" },
    [9] = { "Ahz-Dagum", "Angor-dum", "Arad-Khaz", "Gor-skalf", "Grum-mana", "Khaz-rand", "Kost-Guma", "Mund-helm" },
    [10] = { "Angor-Magi", "Gar-Mogoth", "Hoga-Modan", "Midd-Havas", "Nagga-roth", "Thros-gare" },
    [11] = { "Azgol-haman", "Dun-haldren", "Ge'ar-anvil", "Guma-syddan" },
    [12] = { "Robush-mogan", "Thros-am-Kha" },
    [13] = { "Gimil-thumane", "Gol'gethrunon", "Haldji-drugan" },
    [14] = { "Gosh-algaz-dun", "Scyld-modor-ok" },
}

LanguageTable.Darnassian = {
    [1] = { "A", "D", "E", "I", "N", "O" },
    [2] = { "Al", "An", "Da", "Do", "Lo", "Ni", "No", "Ri", "Su" },
    [3] = { "Ala", "Ano", "Anu", "Ash", "Dor", "Dur", "Fal", "Nei", "Nor", "Osa", "Tal", "Tur" },
    [4] = { "Alah", "Aman", "Anar", "Andu", "Dath", "Dieb", "Diel", "Fulo", "Mush", "Rini", "Shar", "Thus" },
    [5] = { "Adore", "Balah", "Bandu", "Eburi", "Fandu", "Ishnu", "Shano", "Shari", "Talah", "Terro", "Thera", "Turus" },
    [6] = { "Asto're", "Belore", "Do'rah", "Dorini", "Ethala", "Falla", "Ishura", "Man'ar", "Neph'o", "Shando", "T'as'e", "U'phol" },
    [7] = { "Al'shar", "Alah'ni", "Aman'ni", "Anoduna", "Dor'Ano", "Mush'al", "Shan're" },
    [8] = { "D'ana'no", "Dal'dieb", "Dorithur", "Eraburis", "Il'amare", "Mandalas", "Thoribas" },
    [9] = { "Banthalos", "Dath'anar", "Dune'adah", "Fala'andu", "Neph'anis", "Shari'fal", "Thori'dal" },
    [10] = { "Ash'therod", "Dorados'no", "Isera'duna", "Shar'adore", "Thero'shan" },
}

LanguageTable.Thalassian = {
    [1] = { "A", "N", "I", "O", "E", "D" },
    [2] = { "Da", "Lo", "An", "Ni", "Al", "Do", "Ri", "Su", "No" },
    [3] = { "Ano", "Dur", "Tal", "Nei", "Ash", "Dor", "Anu", "Fal", "Tur", "Ala", "Nor", "Osa" },
    [4] = { "Alah", "Andu", "Dath", "Mush", "Shar", "Thus", "Fulo", "Aman", "Diel", "Dieb", "Rini", "Anar" },
    [5] = { "Talah", "Adore", "Ishnu", "Bandu", "Balah", "Fandu", "Thera", "Turus", "Shari", "Shano", "Terro", "Eburi" },
    [6] = { "Dorini", "Shando", "Ethala", "Fallah", "Belore", "Do'rah", "Neph'o", "Man'ar", "Ishura", "U'phol", "T'as'e" },
    [7] = { "Asto're", "Anoduna", "Alah'ni", "Dor'Ano", "Al'shar", "Mush'al", "Aman'ni", "Shan're" },
    [8] = { "Mandalas", "Eraburis", "Dorithur", "Dal'dieb", "Thoribas", "D'ana'no", "Il'amare" },
    [9] = { "Neph'anis", "Dune'adah", "Banthalos", "Fala'andu", "Dath'anar", "Shari'fal", "Thori'dal" },
    [10] = { "Thero'shan", "Isera'duna", "Ash'therod", "Dorados'no", "Shar'adore" },
}

LanguageTable.Draenic = {
    [1] = { "E", "G", "O", "X", "Y" },
    [2] = { "Az", "Il", "Me", "No", "Re", "Te", "Ul", "Ur", "Xi", "Za", "Ze" },
    [3] = { "Daz", "Gul", "Kar", "Laz", "Lek", "Lok", "Maz", "Ril", "Ruk", "Shi", "Tor", "Zar" },
    [4] = { "Alar", "Aman", "Amir", "Ante", "Ashj", "Kiel", "Maev", "Maez", "Orah", "Parn", "Raka", "Rikk", "Veni", "Zenn", "Zila" },
    [5] = { "Adare", "Belan", "Buras", "Enkil", "Golad", "Gular", "Kamil", "Melar", "Modas", "Nagas", "Refir", "Revos", "Soran", "Tiros", "Zekil", "Zekul" },
    [6] = { "Arakal", "Azgala", "Kazile", "Mannor", "Mishun", "Rakkan", "Rakkas", "Rethul", "Revola", "Thorje", "Tichar" },
}

LanguageTable.Gnomish = {
    [1] = { "A", "C", "D", "E", "F", "G", "I", "O", "T" },
    [2] = { "Am", "Ga", "Ke", "Lo", "Ok", "So", "Ti", "Um", "Va", "We" },
    [3] = { "Bur", "Dun", "Fez", "Giz", "Gal", "Gar", "Her", "Mik", "Mor", "Mos", "Nid", "Rod", "Zah" },
    [4] = { "Buma", "Cost", "Dani", "Gear", "Gosh", "Grum", "Helm", "Hine", "Huge", "Lock", "Kahs", "Rand", "Riff", "Rune" },
    [5] = { "Algos", "Angor", "Dagem", "Frend", "Goten", "Haven", "Havis", "Mitta", "Modan", "Modor", "Nagin", "Tiras", "Thros", "Weird" },
}

LanguageTable.Taurahe = {
    [1] = { "A", "E", "I", "N", "O" },
    [2] = { "Ba", "Ki", "Lo", "Ne", "Ni", "No", "Po", "Ta", "Te", "Tu", "Wa" },
    [3] = { "Aki", "Alo", "Awa", "Chi", "Ich", "Ish", "Kee", "Owa", "Paw", "Rah", "Uku", "Zhi" },
    [4] = { "A'ke", "Awak", "Balo", "Eche", "Isha", "Hale", "Halo", "Mani", "Nahe", "Shne", "Shte", "Tawa", "Towa" },
    [5] = { "A'hok", "A'iah", "Abalo", "Ahmen", "Anohe", "Ishte", "Kashu", "Nechi", "Nokee", "Pawni", "Poalo", "Porah", "Shush", "Ti'ha", "Tanka", "Yakee" },
}

LanguageTable.Zandali = {
    [1] = { "A", "E", "H", "J", "M", "N", "O", "S", "U" },
    [2] = { "Di", "Fi", "Fu", "Im", "Ir", "Is", "Ju", "So", "Wi", "Yu" },
    [3] = { "Deh", "Dim", "Fus", "Han", "Mek", "Noh", "Sca", "Tor", "Weh", "Wha" },
    [4] = { "Cyaa", "Duti", "Iman", "Iyaz", "Riva", "Skam", "Ting", "Worl", "Yudo" },
    [5] = { "Ackee", "Atuad", "Caang", "Difus", "Nehjo", "Siame", "T'ief", "Wassa" },
}

LanguageTable.Draconic = {
    [1] = { "a", "e", "i", "o", "u", "y", "g", "x" },
    [2] = { "il", "no", "az", "te", "ur", "za", "ze", "re", "ul", "me", "xi" },
    [3] = { "tor", "gul", "lok", "asj", "kar", "lek", "daz", "maz", "ril", "ruk", "laz", "shi", "zar" },
    [4] = { "ashj", "alar", "orah", "amir", "aman", "ante", "kiel", "maez", "maev", "veni", "raka", "zila", "zenn", "parn", "rikk" },
    [5] = { "melar", "rakir", "tiros", "modas", "belan", "zekul", "soran", "gular", "enkil", "adare", "golad", "buras", "nagas", "revos", "refir", "kamil" },
}

---Get a sorted list of all available languages
---@return table Array of language names
function LanguageTable.GetLanguages()
    local languages = {}
    for langName, langData in pairs(LanguageTable) do
        if type(langData) == "table" then
            table.insert(languages, langName)
        end
    end
    table.sort(languages)
    return languages
end

return LanguageTable
