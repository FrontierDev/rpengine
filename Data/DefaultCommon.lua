RPE = RPE or {}
RPE.Data = RPE.Data or {}
RPE.Data.Default = RPE.Data.Default or {}

RPE.Data.Default.INTERACTIONS_COMMON = {
	-- Blacksmithing
	["ixn-blacksmithing-supplies"] = {
		id = "ixn-blacksmithing-supplies",
		options = {
			{
				label = "Blacksmithing Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "blacksmithing",
				},
			},
		},
		target = "Blacksmithing Supplies",
	},
	["ixn-blacksmithing-trainer"] = {
		id = "ixn-blacksmithing-trainer",
		options = {
			{
				label = "Blacksmithing Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "blacksmithing",
				},
			},
		},
		target = "Blacksmithing Trainer",
	},

	-- Tailoring
	["ixn-tailoring-supplies"] = {
		id = "ixn-tailoring-supplies",
		options = {
			{
				label = "Tailoring Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "tailoring",
				},
			},
		},
		target = "Tailoring Supplies",
	},
	["ixn-tailoring-trainer"] = {
		id = "ixn-tailoring-trainer",
		options = {
			{
				label = "Tailoring Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "tailoring",
				},
			},
		},
		target = "Tailoring Trainer",
	},

	-- Leatherworking
	["ixn-leatherworking-supplies"] = {
		id = "ixn-leatherworking-supplies",
		options = {
			{
				label = "Leatherworking Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "leatherworking",
				},
			},
		},
		target = "Leatherworking Supplies",
	},
	["ixn-leatherworking-trainer"] = {
		id = "ixn-leatherworking-trainer",
		options = {
			{
				label = "Leatherworking Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "leatherworking",
				},
			},
		},
		target = "Leatherworking Trainer",
	},

	-- Alchemy
	["ixn-alchemy-supplies"] = {
		id = "ixn-alchemy-supplies",
		options = {
			{
				label = "Alchemy Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "alchemy",
				},
			},
		},
		target = "Alchemy Supplies",
	},

	["ixn-alchemy-trainer"] = {
		id = "ixn-alchemy-trainer",
		options = {
			{
				label = "Alchemy Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "alchemy",
				},
			},
		},
		target = "Alchemy Trainer",
	},

	-- Herbalism (gatherer, usually mobile)
	["ixn-herbalism-trainer"] = {
		id = "ixn-herbalism-trainer",
		options = {
			{
				label = "Herbalism Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "herbalism",
				},
			},
		},
		target = "Herbalism Trainer",
	},

	-- Mining (gatherer, usually mobile)
	["ixn-mining-trainer"] = {
		id = "ixn-mining-trainer",
		options = {
			{
				label = "Mining Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "mining",
				},
			},
		},
		target = "Mining Trainer",
	},

	-- Fishing (gatherer, usually mobile)
	["ixn-fishing-trainer"] = {
		id = "ixn-fishing-trainer",
		options = {
			{
				label = "Fishing Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "fishing",
				},
			},
		},
		target = "Fishing Trainer",
	},

	-- Enchanting
	["ixn-enchanting-supplies"] = {
		id = "ixn-enchanting-supplies",
		options = {
			{
				label = "Enchanting Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "enchanting",
				},
			},
		},
		target = "Enchanting Supplies",
	},

	["ixn-enchanting-trainer"] = {
		id = "ixn-enchanting-trainer",
		options = {
			{
				label = "Enchanting Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "enchanting",
				},
			},
		},
		target = "Enchanting Trainer",
	},

	-- Engineering
	["ixn-engineering-supplies"] = {
		id = "ixn-engineering-supplies",
		options = {
			{
				label = "Engineering Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "engineering",
				},
			},
		},
		target = "Engineering Supplies",
	},
	["ixn-engineering-trainer"] = {
		id = "ixn-engineering-trainer",
		options = {
			{
				label = "Engineering Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "engineering",
				},
			},
		},
		target = "Engineering Trainer",
	},

	-- Jewelcrafting
	["ixn-jewelcrafting-supplies"] = {
		id = "ixn-jewelcrafting-supplies",
		options = {
			{
				label = "Jewelcrafting Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "jewelcrafting",
				},
			},
		},
		target = "Jewelcrafting Supplies",
	},
	["ixn-jewelcrafting-trainer"] = {
		id = "ixn-jewelcrafting-trainer",
		options = {
			{
				label = "Jewelcrafting Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "jewelcrafting",
				},
			},
		},
		target = "Jewelcrafting Trainer",
	},

	-- Inscription
	["ixn-inscription-supplies"] = {
		id = "ixn-inscription-supplies",
		options = {
			{
				label = "Inscription Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "inscription",
				},
			},
		},
		target = "Inscription Supplies",
	},
	["ixn-inscription-trainer"] = {
		id = "ixn-inscription-trainer",
		options = {
			{
				label = "Inscription Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "inscription",
				},
			},
		},
		target = "Inscription Trainer",
	},

	-- Cooking
	["ixn-cooking-supplies"] = {
		id = "ixn-cooking-supplies",
		options = {
			{
				label = "Cooking Supplies",
				action = "SHOP",
				args = {
					maxStock = "inf",
					maxRarity = "uncommon",
					matchAll = false,
					tags = "cooking",
				},
			},
		},
		target = "Cooking Supplies",
	},

	["ixn-cooking-trainer"] = {
		id = "ixn-cooking-trainer",
		options = {
			{
				label = "Cooking Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "cooking",
				},
			},
		},
		target = "Cooking Trainer",
	},

	-- First Aid
	["ixn-first-aid-trainer"] = {
		id = "ixn-first-aid-trainer",
		options = {
			{
				label = "First Aid Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "first-aid",
				},
			},
		},
		target = "Bandage Trainer",
	},

	-- Skinning (gatherer)
	["ixn-skinning-trainer"] = {
		id = "ixn-skinning-trainer",
		options = {
			{
				label = "Skinning Trainer",
				action = "TRAIN",
				args = {
					maxLevel = "300",
					type = "PROFESSION",
					flags = "skinning",
				},
			},
		},
		target = "Skinning Trainer",
	},

	-- Dead humanoid - salvage cloth
	["ixn-dead-humanoid"] = {
		id = "ixn-dead-humanoid",
		options = {
			{
				label = "Salvage",
				action = "SALVAGE",
				requiresDead = 1,
				output = {
					{ itemId = "item-r2589", qty = "1d3", chance = 1.0 },
				},
			},
		},
		target = "type:humanoid",
	},

	-- Dead beast - skin leather
	["ixn-dead-beast"] = {
		id = "ixn-dead-beast",
		options = {
			{
				label = "Skin",
				action = "SKIN",
				requiresDead = 1,
				output = {
					{ itemId = "item-r2318", qty = "1d2", chance = 1.0 },
				},
			},
		},
		target = "type:beast",
	},

	-- Paladin Trainer
	["ixn-paladin-trainer"] = {
		id = "ixn-paladin-trainer",
		options = {
			{
				label = "Train",
				action = "TRAIN",
				args = {
					type = "SPELLS",
					tags = "paladin",
				},
			},
		},
		target = "Paladin Trainer",
	},
}