local LanguageTable = {}
_G.RPT_Languages = LanguageTable

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
    [15] = {},
    [16] = {},
    [17] = { "Haldren-Lo-Modoss" }    
}

LanguageTable.Gnomish = {
    [1] = { "A", "C", "D", "E", "F", "G", "I", "O", "T" },
    [2] = { "Am", "Ga", "Ke", "Lo", "Ok", "So", "Ti", "Um", "Va", "We" },
    [3] = { "Bur", "Dun", "Fez", "Giz", "Gal", "Gar", "Her", "Mik", "Mor", "Mos", "Nid", "Rod", "Zah" },
    [4] = { "Buma", "Cost", "Dani", "Gear", "Gosh", "Grum", "Helm", "Hine", "Huge", "Lock", "Kahs", "Rand", "Riff", "Rune" },
    [5] = { "Algos", "Angor", "Dagem", "Frend", "Goten", "Haven", "Havis", "Mitta", "Modan", "Modor", "Nagin", "Tiras", "Thros", "Weird" },
    [6] = { "Danieb", "Drugan", "Dumssi", "Gizber", "Haldir", "Helmok", "Mergud", "Protos", "Revosh", "Rugosh", "Shermt", "Waldor" },
    [7] = { "Bergrim", "Costirm", "Ferdosr", "Ganrokh", "Geardum", "Godling", "Haidren", "Havagun", "Noxtyec", "Scrutin", "Sturome", "Thorneb" },
    [8] = {
        "Aldanoth", "Azregorn", "Bolthelm", "Botlikin", "Dimligar", "Gefrunon", "Godunmug", "Grumgizr", "Kahsgear", "Kahzregi",
        "Landivar", "Methrine", "Mikthros", "Misfaran", "Nandiger", "Thulmane"
    },
    [9] = { "Angordame", "Elodergim", "Elodmodor", "Naggirath", "Nockhavis" },
    [10] = {
        "Ahzodaugum", "Alegaskron", "Algosgoten", "Danavandar", "Dyrstagist", "Falhadrink", "Frendgalva",
        "Mosgodunan", "Mundgizber", "Naginbumat", "Sihnvulden", "Throsigear", "Vustrangin"
    },
    [11] = {
        "Ferdosmodan", "Gizbarlodun", "Haldjinagin", "Helmokheram", "Kahzhaldren", "Lockrevoshi", "Robuswaldir",
        "Skalfgizgar", "Thrunon'gol", "Thumanerand"
    }
}

LanguageTable.Draenic = {
    [1] = { "E", "G", "O", "X", "Y" },
    [2] = { "Az", "Il", "Me", "No", "Re", "Te", "Ul", "Ur", "Xi", "Za", "Ze" },
    [3] = { "Daz", "Gul", "Kar", "Laz", "Lek", "Lok", "Maz", "Ril", "Ruk", "Shi", "Tor", "Zar" },
    [4] = { "Alar", "Aman", "Amir", "Ante", "Ashj", "Kiel", "Maev", "Maez", "Orah", "Parn", "Raka", "Rikk", "Veni", "Zenn", "Zila" },
    [5] = { "Adare", "Belan", "Buras", "Enkil", "Golad", "Gular", "Kamil", "Melar", "Modas", "Nagas", "Refir", "Revos", "Soran", "Tiros", "Zekil", "Zekul" },
    [6] = { "Arakal", "Azgala", "Kazile", "Mannor", "Mishun", "Rakkan", "Rakkas", "Rethul", "Revola", "Thorje", "Tichar" },
    [7] = { "Amanare", "Belaros", "Danashj", "Faralos", "Faramos", "Gulamir", "Karaman", "Kieldaz", "Rethule", "Tiriosh", "Toralar", "Zennshi" },
    [8] = { "Amanalar", "Ashjraka", "Azgalada", "Azrathud", "Belankar", "Enkilzar", "Kirasath", "Maladath", "Mordanas", "Theramas" },
    [9] = { "Arakalada", "Kanrethad", "Melamagas", "Melarorah", "Nagasraka", "Naztheros", "Soranaman", "Teamanare", "Zilthuras" },
    [10] = { "Amanemodas", "Ashjrethul", "Benthadoom", "Kamilgolad", "Matheredor", "Pathrebosh", "Ticharamir", "Zennrakkan" },
    [11] = { "Archimtiros", "Ashjrakamas", "Mannorgulan", "Mishunadare", "Zekulrakkas" },
    [12] = { "Zennshinagas" }
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
    [11] = { "Fandu'talah", "Shari'adune" },
    [12] = { "Dor'ana'badu", "T'ase'mushal" },
    [13] = { "U'phol'belore" },
    [14] = { "Anu'dorannador", "Turus'il'amare" },
    [15] = { "Asto're'dunadah", "Shindu'falla'na" },
    [16] = {},
    [17] = { "Ando'meth'derador", "Anu'dorinni'talah", "Esh'thero'mannash", "Thoribas'no'thera" }
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
    [11] = { "Fandu'talah", "Shari'adune" },
    [12] = { "Dor'ana'badu", "T'ase'mushal" },
    [13] = { "U'phol'belore" },
    [14] = { "Turus'il'amare", "Anu'dorannador" },
    [15] = { "Asto're'dunadah" },
    [16] = { "Shindu'fallah'na" },
    [17] = { "Thoribas'no'thera", "Ando'meth'derador", "Anu'dorinni'talah", "Esh'thero'mannash" }
}

LanguageTable.Gutterspeak = {
    [1] = { "A", "E", "I", "O", "U", "Y" },
    [2] = { "An", "Ko", "Lo", "Lu", "Me", "Ne", "Re", "Ru", "Se", "Ti", "Va", "Ve" },
    [3] = { "Ash", "Bor", "Bur", "Far", "Gol", "Hir", "Lon", "Mos", "Nud", "Ras", "Ver", "Vil", "Wos" },
    [4] = { "Ador", "Agol", "Dana", "Goth", "Lars", "Noth", "Nuff", "Odes", "Ruff", "Thor", "Uden", "Veld", "Vohl", "Vrum" },
    [5] = { "Algos", "Barad", "Borne", "Eynes", "Ergin", "Garde", "Gloin", "Majis", "Melka", "Nagan", "Novas", "Regen", "Tiras", "Wirsh" },
    [6] = { "Aesire", "Aziris", "Daegil", "Danieb", "Ealdor", "Engoth", "Goibon", "Mandos", "Nevren", "Rogesh", "Rothas", "Ruftos", "Skilde", "Valesh", "Vandar", "Waldir" },
    [7] = { "Andovis", "Ewiddan", "Faergas", "Forthis", "Kaelsig", "Koshvel", "Lithtos", "Nandige", "Nostyec", "Novaedi", "Sturume", "Vassild" },
    [8] = { "Aldonoth", "Cynegold", "Endirvis", "Hamerung", "Landowar", "Lordaere", "Methrine", "Ruftvess", "Thorniss" },
    [9] = { "Aetwinter", "Danagarde", "Eloderung", "Firalaine", "Gloinador", "Gothalgos", "Regenthor", "Udenmajis", "Vandarwos", "Veldbarad" },
    [10] = { "Aelgestron", "Cynewalden", "Danavandar", "Dyrstigost", "Falhedring", "Vastrungen" },
    [11] = { "Agolandovis", "Bornevalesh", "Farlandowar", "Forthasador", "Thorlithtos", "Vassildador", "Wershaesire" },
    [12] = { "Adorstaerume", "Golveldbarad", "Mandosdaegil", "Nevrenrothas", "Waldirskilde" }
}

LanguageTable["Taur-ahe"] = {
    [1] = { "A", "E", "I", "N", "O" },
    [2] = { "Ba", "Ki", "Lo", "Ne", "Ni", "No", "Po", "Ta", "Te", "Tu", "Wa" },
    [3] = { "Aki", "Alo", "Awa", "Chi", "Ich", "Ish", "Kee", "Owa", "Paw", "Rah", "Uku", "Zhi" },
    [4] = { "A'ke", "Awak", "Balo", "Eche", "Isha", "Hale", "Halo", "Mani", "Nahe", "Shne", "Shte", "Tawa", "Towa" },
    [5] = { "A'hok", "A'iah", "Abalo", "Ahmen", "Anohe", "Ishte", "Kashu", "Nechi", "Nokee", "Pawni", "Poalo", "Porah", "Shush", "Ti'ha", "Tanka", "Yakee" },
    [6] = { "Aloaki", "Hetawa", "Ichnee", "Kichalo", "Lakota", "Lomani", "Neahok", "Nitawa", "Owachi", "Pawene", "Sho'wa", "Taisha", "Tatanka", "Washte" },
    [7] = { "Ishnelo", "Owakeri", "Pikialo", "Sechalo", "Shtealo", "Shteawa", "Tihikea" },
    [8] = { "Akiticha", "Awaihilo", "Ishnialo", "O'ba'chi", "Orahpajo", "Ovaktalo", "Owatanka", "Porahalo", "Shtumani", "Tatahalo", "Towateke" },
    [9] = { "Echeyakee", "Haloyakee", "Ishne'alo", "Tawaporah" },
    [10] = { "Awaka'nahe", "Ichnee'awa", "Ishamuhale", "Shteowachi" },
    [11] = { "Aloaki'shne", "Awakeekielo", "Lakota'mani", "Shtumanialo" },
    [12] = { "Awakeekielo", "Aloaki'shne" },
    [13] = { "Ishne'awahalo", "Neashushahmen" },
    [14] = { "Awakeeahmenalo" },
    [15] = { "Ishne'alo'porah" }
}

LanguageTable["Zandali"] = {
    [1] = { "A", "E", "H", "J", "M", "N", "O", "S", "U" },
    [2] = { "Di", "Fi", "Fu", "Im", "Ir", "Is", "Ju", "So", "Wi", "Yu" },
    [3] = { "Deh", "Dim", "Fus", "Han", "Mek", "Noh", "Sca", "Tor", "Weh", "Wha" },
    [4] = { "Cyaa", "Duti", "Iman", "Iyaz", "Riva", "Skam", "Ting", "Worl", "Yudo" },
    [5] = { "Ackee", "Atuad", "Caang", "Difus", "Nehjo", "Siame", "T'ief", "Wassa" },
    [6] = { "Bwoyar", "Deh'yo", "Fidong", "Honnah", "Icense", "Italaf", "Quashi", "Saakes", "Smadda", "Stoosh", "Wi'mek", "Yuutee" },
    [7] = { "Chakari", "Craaweh", "Flimeff", "Godehsi", "Lok'dim", "Reespek", "Rivasuf", "Tanponi", "Uptfeel", "Yahsoda", "Ziondeh" },
    [8] = { "Ginnalka", "Machette", "Nyamanpo", "Oondasta", "Wehnehjo", "Whutless", "Yeyewata", "Zutopong" },
    [9] = { "Fus'obeah", "Or'manley" }
}

LanguageTable["Shalassian"] = { 
    [1] = { "a", "e", "n", "i", "o", "d" },
    [2] = { "an", "do", "da", "lo", "ni", "al", "ri", "su", "no", "in" },
    [3] = { "nei", "anu", "ala", "ano", "dur", "tal", "ash", "dor", "fal", "tur", "nor", "osa", "vas", "anu", "tel" },
    [4] = { "alah", "mush", "diel", "anar", "thus", "andu", "dath", "shar", "fulo", "aman", "dieb", "rini", "rath" },
    [5] = { "adore", "thera", "shari", "eburi", "falla", "balah", "talah", "ishnu", "bandu", "fandu", "turus", "shano", "terro", "omnas", "an'ah", "tanos", "telar", "denil", "falar", "n'eth" },
    [6] = { "neph'o", "man'ar", "u'phol", "shando", "dorini", "ethala", "belore", "do'rah", "ishura", "t'as'e", "ith'el", "kanesh", "e'rath", "manari", "domaas", "ishnal", "maldin" },
    [7] = { "dor'ano", "aman'ni", "anoduna", "asto're", "alah'ni", "al'shar", "mush'al", "shan're", "in'alah", "arkhana", "to'reth", "vallath", "dorithur", "thoribas", "il'amare", "mandalas", "eraburis" },
    [8] = { "dal'dieb", "d'ana'no", "ith'nala", "an'ratha", "fala'andu", "shari'fal", "dune'adah", "thori'dal" },
    [9] = { "neph'anis", "banthalos", "dath'anar", "nar'thala", "sin'dorei", "tel'vasha" },
    [10] = { "isera'duna", "dorados'no", "thero'shan", "ash'therod", "shar'adore", "ru-shannah", "shal'dorei", "ash'thoras", "tenu'balah", "kal'theros", "nor'bethos", "tor'theras", "shal'assan" },
    [11] = { "shari'adune", "fandu'talah", "rath-domaas" },
    [12] = { "dor'ana'badu", "t'ase'mushal", "anar-ammenos" },
    [13] = { "u'phol'belore" },
    [14] = { "turus'il'amare", "anu'dorannador", "rath-anu'tanos", "rath-anu'telar" },
    [15] = { "shindu'falla'na", "asto're'dunadah" },
    [16] = { "anu'dorinni'talah", "ando'meth'derador", "esh'thero'mannash", "thoribas'no'thera" }
}

LanguageTable["Goblin"] = {
    [1] = { "z" },
    [2] = { "ak", "rt", "ik", "um", "fr", "bl", "zz", "ap", "un", "ek" },
    [3] = { "eet", "paf", "gak", "erk", "gip", "nap", "kik", "bap", "ikk", "grk" },
    [4] = { "tiga", "moof", "bitz", "akak", "ripl", "foop", "keek", "errk", "apap", "rakr" },
    [5] = { "fibit", "shibl", "nebit", "ababl", "iklik", "nubop", "krikl", "zibit" },
    [6] = { "amama", "apfap", "ripdip", "skoopl", "bapalu", "oggnog", "yipyip", "kaklak", "ikripl", "bipfiz", "kiklix", "nufazl" },
    [7] = { "bakfazl", "rapnukl", "fizbikl", "lapadap", "biglkip", "nibbipl", "fuzlpop", "gipfizy", "babbada" },
    [8] = { "igglepop", "ibbityip", "etiggara", "saklpapp", "ukklnukl", "bendippl", "ikerfafl", "ikspindl", "baksnazl", "kerpoppl", "hopskopl" },
    [9] = { "hapkranky", "skippykik" },
    [10] = { "nogglefrap" },
    [11] = { "rapnakskappypappl", "rripdipskiplip", "napfazzyboggin", "kikklpipkikkl", "nibbityfuzhips", "bubnobblepapkap", "hikkitybippl" },
}

LanguageTable["Vulpera"] = { -- languageID 285
    [1] = { "u", "i", "o", "y" },
    [2] = { "wa", "pa", "ho", "yi", "oo", "da", "aw", "au", "ii", "yy", "ak", "ik", "uk" },
    [3] = { "pow", "aoo", "woo", "wan", "bau", "gav", "arf", "yip", "yap", "bow", "hau", "haf", "vuf", "iiy", "iyw" },
    [4] = { "ring", "joff", "ahee", "wooo", "guau", "bork", "woof", "yiip", "yaap", "blaf", "woef", "keff", "gheu", "vuuf", "ghav", "bhuh" },
    [5] = { "hatti", "woooo", "waouh", "lally", "ouahn", "meong", "youwn", "wauwn", "yiuwn", "hittu", "hytou" },
    [6] = { "geding", "tchoff", "hattii", "wanwan", "baubau", "hauhau", "caicai", "yipyip" },
    [7] = { "frakaka", "bhuhbuh", "aheeaha", "wooowoo", "grrbork" },
    [8] = { "guauguau", "wuffwoef", "borkbork", "blafblaf", "gheugheu", "vuufwuff", "wuffvuwn" },
    [9] = { "ghavyouwn", "woefyouwn", "bhuhwauwn", "joffwauwn", "aheeowown", "ghavyouwn" },
    [10] = { "keffgeding", "woofhauhau", "vuufhattii", "borkwanwan", "blafhauhau" },
}

LanguageTable["Pandaren"] = { -- languageID unknown, truncated name-based vocabulary
    [1] = { "a", "i", "u", "e", "o", "n" },
    [2] = { "bu", "ji", "yu", "bo", "le", "lu", "li", "he", "qi", "tu", "fu", "an", "wu", "nu", "xi", "da", "yi", "qu", "za" },
    [3] = { "zhu", "jin", "chi", "shi", "zen", "bei", "ren", "wei", "hao", "zai", "gao", "mei", "dao", "yun", "xin", "wen", "jue", "zan" },
    [4] = { "chen", "xing", "yuan", "chun", "xiao", "feng", "shan", "quan", "shen", "ling", "yong", "tian", "zhen", "zhao", "ming" },
    [5] = { "zhong", "binan", "xiang", "sheng", "zheng", "guang", "liang", "bo'lu", "ji'an", "xi-ji", "wu-la", "da'le", "nu-he", "bomei", "huian", "wuzen", "yumei" },
    [6] = { "sri-la", "hei-ji", "zhi'lu", "jie-he", "xiu-tu", "hua'an", "jia-nu", "mei-da", "hui'le", "bu'yun", "yu-mei", "ji-zai", "bo-wei", "le-zhu", "li-ren", "qi'zen", "fu-jin", "daquan" },
    [7] = { "wen-bao", "gao-ran", "mandori", "gan-tao", "zai-yan", "zen-lei", "yin'lao", "quxiang", "qitian", "zhuquan", "chenxin", "wuzheng", "xiaoyun" },
    [8] = { "fengshan", "xiaofeng", "jingchun", "bomeiren", "meirenhe" },
    [9] = { "fengzhong", "zhengming", "chenliang", "zhongyuan", "yuquanren", "huiqufeng", "yinlaomei" },
    [10] = { "wuzhengzen", "jingyuanan" },
    [11] = { "fengshanren" },
    [12] = { "chen-xinfeng", "xinjing-chun" },
    [13] = { "fengshanliang", "zhengmingquan" },
}

LanguageTable["Draconic"] = { -- languageID 11
    [1] = { "a", "e", "i", "o", "u", "y", "g", "x" },
    [2] = { "il", "no", "az", "te", "ur", "za", "ze", "re", "ul", "me", "xi" },
    [3] = { "tor", "gul", "lok", "asj", "kar", "lek", "daz", "maz", "ril", "ruk", "laz", "shi", "zar" },
    [4] = { "ashj", "alar", "orah", "amir", "aman", "ante", "kiel", "maez", "maev", "veni", "raka", "zila", "zenn", "parn", "rikk" },
    [5] = { "melar", "rakir", "tiros", "modas", "belan", "zekul", "soran", "gular", "enkil", "adare", "golad", "buras", "nagas", "revos", "refir", "kamil" },
    [6] = { "rethul", "rakkan", "rakkas", "tichar", "mannor", "archim", "azgala", "karkun", "revola", "mishun", "arakal", "kazile", "thorje" },
    [7] = { "belaros", "tiriosh", "faramos", "danashj", "amanare", "faralos", "kieldaz", "karaman", "gulamir", "toralar", "rethule", "zennshi", "amanare" },
    [8] = { "maladath", "kirasath", "romathis", "theramas", "azrathud", "mordanas", "amanalar", "ashjraka", "azgalada", "rukadare", "sorankar", "enkilzar", "belankar" },
    [9] = { "naztheros", "zilthuras", "kanrethad", "melarorah", "arakalada", "soranaman", "nagasraka", "teamanare" },
    [10] = { "matheredor", "ticharamir", "pathrebosh", "benthadoom", "amanemodas", "enkilgular", "burasadare", "melarnagas", "zennrakkan", "ashjrethul", "kamilgolad" },
    [11] = { "zekulrakkas", "archimtiros", "mannorgulan", "mishunadare", "ashjrakamas" },
    [12] = { "zennshinagas" },
}

LanguageTable["Demonic"] = { -- languageID 8
    [1] = { "a", "e", "i", "o", "u", "y", "g", "x" },
    [2] = { "il", "no", "az", "te", "ur", "za", "ze", "re", "ul", "me", "xi" },
    [3] = { "tor", "gul", "lok", "asj", "kar", "lek", "daz", "maz", "ril", "ruk", "laz", "shi", "zar" },
    [4] = { "ashj", "alar", "orah", "amir", "aman", "ante", "kiel", "maez", "maev", "veni", "raka", "zila", "zenn", "parn", "rikk" },
    [5] = { "melar", "rakir", "tiros", "modas", "belan", "zekul", "soran", "gular", "enkil", "adare", "golad", "buras", "nagas", "revos", "refir", "kamil" },
    [6] = { "rethul", "rakkan", "rakkas", "tichar", "mannor", "archim", "azgala", "karkun", "revola", "mishun", "arakal", "kazile", "thorje" },
    [7] = { "belaros", "tiriosh", "faramos", "danashj", "amanare", "kieldaz", "karaman", "gulamir", "toralar", "rethule", "zennshi", "amanare" },
    [8] = { "maladath", "kirasath", "romathis", "theramas", "azrathud", "mordanas", "amanalar", "ashjraka", "azgalada", "rukadare", "sorankar", "enkilzar", "belankar" },
    [9] = { "naztheros", "zilthuras", "kanrethad", "melarorah", "arakalada", "soranaman", "nagasraka", "teamanare" },
    [10] = { "matheredor", "ticharamir", "pathrebosh", "benthadoom", "amanemodas", "enkilgular", "burasadare", "melarnagas", "zennrakkan", "ashjrethul", "kamilgolad" },
    [11] = { "zekulrakkas", "archimtiros", "mannorgulan", "mishunadare", "ashjrakamas" },
    [12] = { "zennshinagas" },
}

LanguageTable["Shath'Yar"] = { -- languageID 178
    [1] = { "i" },
    [2] = { "ez", "ga", "ky", "ma", "ni", "og", "za", "zz" },
    [3] = { "gag", "hoq", "lal", "maq", "nuq", "oou", "qam", "shn", "vaz", "vra", "yrr", "zuq" },
    [4] = { "agth", "amun", "arwi", "fssh", "ifis", "kyth", "nuul", "ongg", "puul", "qwaz", "qwor", "ryiu", "shfk", "thoq", "uull", "vwah", "vwyq", "w'oq", "wgah", "ywaq", "zaix", "zzof" },
    [5] = { "ag'rr", "agthu", "ak'uq", "anagg", "bo'al", "fhssh", "h'iwn", "hnakf", "huqth", "iilth", "iiyoq", "lwhuk", "on'ma", "plahf", "shkul", "shuul", "thyzz", "uulwi", "vorzz", "w'ssh", "yyqzz" },
    [6] = { "ag'xig", "al'tha", "an'qov", "an'zig", "bormaz", "c'toth", "far'al", "h'thon", "halahs", "iggksh", "ka'kar", "kaaxth", "marwol", "n'zoth", "qualar", "qvsakf", "shn'ma", "sk'tek", "skshgn", "ssaggh", "tallol", "tulall", "uhnish", "uovssh", "vormos", "yawifk", "yoq'al", "yu'gaz" },
    [7] = { "an'shel", "awtgssh", "guu'lal", "guulphg", "iiqaath", "kssh'ga", "mh'naus", "n'lyeth", "ph'magg", "qornaus", "shandai", "shg'cul", "shg'fhn", "sk'magg", "sk'yahf", "uul'gwa", "uulg'ma", "vwahuhn", "woth'gl", "yeh'glu", "yyg'far", "zyqtahg" },
    [8] = { "awtgsshu", "erh'ongg", "gul'kafh", "halsheth", "log'loth", "mar'kowa", "muoq'vsh", "phquathi", "qi'plahf", "qi'uothk", "sk'shuul", "sk'uuyat", "ta'thall", "thoth'al", "uhn'agth", "ye'tarin", "yoh'ghyl", "zuq'nish" },
    [9] = { "ag'thyzak", "ga'halahs", "lyrr'keth", "par'okoth", "phgwa'cul", "pwhn'guul", "ree'thael", "shath'yar", "shgla'yos", "shuul'wah", "sshoq'meg" },
    [10] = { "ak'agthshi", "shg'ullwaq", "sk'woth'gl" },
    [11] = { "ghawl'fwata", "naggwa'fssh", "yeq'kafhgyl" },
}

LanguageTable["Titan"] = { -- languageID 9
    [1] = {"a", "e", "i", "o", "u", "y", "g", "x"},
    [2] = {"il", "no", "az", "te", "ur", "za", "ze", "re", "ul", "me", "xi"},
    [3] = {"tor", "gul", "lok", "asj", "kar", "lek", "daz", "maz", "ril", "ruk", "laz", "shi", "zar"},
    [4] = {"ashj", "alar", "orah", "amir", "aman", "ante", "kiel", "maez", "maev", "veni", "raka", "zila", "zenn", "parn", "rikk"},
    [5] = {"melar", "rakir", "tiros", "modas", "belan", "zekul", "soran", "gular", "enkil", "adare", "golad", "buras", "nagas", "revos", "refir", "kamil"},
    [6] = {"rethul", "rakkan", "rakkas", "tichar", "mannor", "archim", "azgala", "karkun", "revola", "mishun", "arakal", "kazile", "thorje"},
    [7] = {"belaros", "tiriosh", "faramos", "danashj", "amanare", "faralos", "kieldaz", "karaman", "gulamir", "toralar", "rethule", "zennshi", "amanare"},
    [8] = {"maladath", "kirasath", "romathis", "theramas", "azrathud", "mordanas", "amanalar", "ashjraka", "azgalada", "rukadare", "sorankar", "enkilzar", "belankar"},
    [9] = {"naztheros", "zilthuras", "kanrethad", "melarorah", "arakalada", "soranaman", "nagasraka", "teamanare"},
    [10] = {"matheredor", "ticharamir", "pathrebosh", "benthadoom", "amanemodas", "enkilgular", "burasadare", "melarnagas", "zennrakkan", "kamilgolad", "ashjrethul"},
    [11] = {"ashjrakamas", "mishunadare", "mannorgulan", "archimtiros", "zekulrakkas"},
    [12] = {"zennshinagas"},
}

LanguageTable["Kalimag"] = { -- languageID 12
    [1] = {"a", "o", "k", "t", "g", "u"},
    [2] = {"ko", "ta", "gi", "ka", "tu", "os", "ma", "ra"},
    [3] = {"fel", "rok", "kir", "dor", "von", "nuk", "tor", "kan", "tas", "gun", "dra", "sto"},
    [4] = {"brom", "kras", "toro", "drae", "krin", "zoln", "fmer", "guto", "reth", "shin", "tols", "mahn"},
    [5] = {"bromo", "krast", "torin", "draek", "kranu", "zoern", "fmerk", "gatin", "roath", "shone", "talsa", "fraht"},
    [6] = {"korsul", "dratir", "drinor", "tadrom"},
    [7] = {"ben'nig", "ter'ran", "for'kin", "suz'ahn", "fel'tes", "toka'an", "telsrah", "dorvrem", "koaresh", "fiilrok", "chokgan", "fanroke"},
    [8] = {"kel'shae", "dak'kaun", "tchor'ah", "zela'von", "kis'tean", "ven'tiro", "taegoson", "kilagrin", "aasrugel"},
    [9] = {"gi'frazsh", "roc'grare", "quin'mahk", "ties'alla", "shodru'ga", "os'retiak", "desh'noka", "rohh'krah", "krast'ven", "draemierr", "mastrosum"},
    [10] = {"gi'azol'em", "nuk'tra'te", "zoln'nakaz", "gatin'roth", "ahn'torunt", "thukad'aaz", "gesh'throm", "brud'remek"},
    [11] = {"mok'tavaler", "tae'gel'kir", "dor'dra'tor", "aer'rohgmar", "torrath'unt", "ignan'kitch", "caus'tearic", "borg'helmak", "huut'vactah", "jolpat'krim", "tzench'drah", "kraus'ghosa", "dalgo'nizha", "korsukgrare"},
    [12] = {"moth'keretch", "vendo're'mik", "thloy'martok", "danal'korang", "sunep'kosach"},
    [13] = {"golgo'nishver", "kawee'fe'more", "tagha'senchal", "peng'yaas'ahn", "nash'lokan'ar", "derr'moran'ki", "moor'tosav'ak", "kis'an'tadrom", "bach'usiv'hal"},
}

LanguageTable["Nerubian"] = { -- languageID 307
    [1] = {"a", "s", "x", "j", "k"},
    [2] = {"ah", "hz", "ex", "iz", "ox", "uj", "ji", "vx", "xi", "yz", "kz", "zk", "az"},
    [3] = {"ahj", "tak", "raz", "rak", "nix", "xin", "xor", "ohx", "ahn", "toz", "iko", "ozu", "xif"},
    [4] = {"xizy", "anub", "ixxo", "zish", "xini", "oxin"},
    [5] = {"kahet", "nerub", "tyzix", "xinox", "rakaz"},
    [6] = {"ik'tik", "itzkal"},
    [7] = {"ohj'xin", "tak'ral", "jinitiz"},
    [8] = {"ahz'tazi", "oxitazij"},
    [9] = {"zinixitik"},
    [10] = {"Kraxizinaz"},
}

function LanguageTable:Translate(message, language, fraction)
    local wordlist = self[language]
    if not wordlist then return message end

    local words = {}
    for w in message:gmatch("%S+") do
        table.insert(words, w)
    end

    local numToTranslate = math.floor(#words * (fraction or 1))
    local indices = {}
    for i = 1, #words do table.insert(indices, i) end
    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    for i = 1, numToTranslate do
        local index = indices[i]
        local original = words[index]
        local core = original:match("(%a+)")
        if core then
            local len = #core
            local pool = wordlist[len]
            if pool then
                local replacement = pool[math.random(#pool)]
                -- Preserve capitalization
                if core:match("^%u+$") then
                    replacement = replacement:upper()
                elseif core:match("^%u") then
                    replacement = replacement:sub(1,1):upper() .. replacement:sub(2):lower()
                else
                    replacement = replacement:lower()
                end
                -- Rebuild with original punctuation
                words[index] = original:gsub(core, replacement)
            end
        end
    end

    return table.concat(words, " ")
end
