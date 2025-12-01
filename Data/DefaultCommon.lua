RPE = RPE or {}
RPE.Data = RPE.Data or {}
RPE.Data.Default = RPE.Data.Default or {}

RPE.Data.Default.INTERACTIONS_COMMON = {
	["ixn-blacksmithing-supplies"] = {
		id = "ixn-7df7f24d",
		options = {
			{
				args = {
					maxStock = "inf",
                    maxRarity = "uncommon",
                    matchAll = false,
					tags = "blacksmithing",
				},
				action = "SHOP",
				   label = "Shop",
            },
		},
		target = "Blacksmithing Supplies",
	},
    
	["ixn-blacksmithing-trainer"] = {
		id = "ixn-blacksmithing-trainer",
		options = {
			{
				args = {
					maxLevel = "300",
                    type = "PROFESSION",
					flags = "blacksmithing",
				},
				action = "TRAIN",
				   label = "Blacksmithing Trainer",
            },
		},
		target = "Blacksmithing Trainer",
	},	
    
    ["ixn-dead-humanoid"] = {
		id = "ixn-dead-humanoid",
        options = {
            {
                label = "Salvage",
                action = "SALVAGE",
                requiresDead = 1,
                output = {
                    { itemId = "linen_cloth", qty = "1d3", chance = 1.0 },
                },
            },
        -- 	{
        -- 		label = "Raise Dead",
        -- 		action = "RAISE",
        --         requiresDead = 1,
        -- 		args = {
        --             
        --         },
        -- 	},
		},
		target = "type:humanoid",
	},

    ["ixn-dead-beast"] = {
		id = "ixn-dead-beast",
        options = {
            {
                label = "Skin",
                action = "SKIN",
                requiresDead = 1,
                output = {
                    { itemId = "light_leather", qty = "1d2", chance = 1.0 },
                },
            },
        -- 	{
        -- 		label = "Raise Dead",
        -- 		action = "RAISE",
        --         requiresDead = 1,
        -- 		args = {
        --             
        --         },
        -- 	},
		},
		target = "type:beast",
	},
}

RPE.Data.Default.REAGENTS_COMMON = {
    iron_ingot = {
        id = "iron_ingot",
        name = "Iron Ingot",
        category = "MATERIAL",
        icon = 133232, -- INV_Ingot_08
        stackable = true,
        maxStack = 20,
        basePriceU = 50,
        vendorSellable = true,
        rarity = "common",
        data = {},
        tags = { "material", "crafting", "blacksmithing" },
    },    

    linen_cloth = {
        id = "linen_cloth",
        name = "Linen Cloth",
        category = "MATERIAL",
        icon = 132889, -- INV_Misc_Cloth_Linen_02
        stackable = true,
        maxStack = 20,
        basePriceU = 2.5,
        vendorSellable = true,
        rarity = "common",
        data = {},
        tags = { "material", "crafting", "tailoring" },
    },  

    light_leather = {
        id = "light_leather",
        name = "Light Leather",
        category = "MATERIAL",
        icon = 134252, -- INV_Misc_LeatherScrap_02
        stackable = true,
        maxStack = 20,
        basePriceU = 5,
        vendorSellable = true,
        rarity = "common",
        data = {},
        tags = { "material", "crafting", "skinning", "leatherworking" },
    }
}