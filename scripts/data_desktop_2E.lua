-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);

	for k,v in pairs(aDataModuleSet) do
		for _,v2 in ipairs(v) do
			Desktop.addDataModuleSet(k, v2);
		end
	end

	DecalManager.setDefault("images/decals/dnd2_decal.png@2E Assets");

	ColorManager.setButtonIconColor("FFFFFF");
end

-- -- Shown in Modifiers window
-- -- NOTE: Set strings for "modifier_category_*" and "modifier_label_*"
_tModifierWindowPresets =
{
	{ 
		sCategory = "attack",
		tPresets = 
		{
			"ATK_SHIELDLESS",
			"ATK_FROMREAR",
			"ATK_NODEXTERITY",
			"ATK_IGNORE_ARMOR",
			"DEF_COVER_25",
			"DEF_CONCEAL_25",
			"DEF_COVER_50",
			"DEF_CONCEAL_50",
			"DEF_COVER_75",
			"DEF_CONCEAL_75",
			"DEF_COVER_90",
			"DEF_CONCEAL_90"
		},
	},
	{ 
		sCategory = "damage",
		tPresets = { 
			"DMG_CRIT",
			"DMG_MAX",
			"",
			"DMG_HALF",
		}
	},
};

--[[
	This is a bit messy but you dont stack cover/conceal?
]]
_tModifierExclusionSets =
{
	{ "DEF_COVER_25", "DEF_CONCEAL_25" },
	{ "DEF_COVER_25", "DEF_CONCEAL_50" },
	{ "DEF_COVER_25", "DEF_CONCEAL_75" },
	{ "DEF_COVER_25", "DEF_CONCEAL_90" },

	{ "DEF_COVER_50", "DEF_CONCEAL_25" },
	{ "DEF_COVER_50", "DEF_CONCEAL_50" },
	{ "DEF_COVER_50", "DEF_CONCEAL_75" },
	{ "DEF_COVER_50", "DEF_CONCEAL_90" },

	{ "DEF_COVER_75", "DEF_CONCEAL_25" },
	{ "DEF_COVER_75", "DEF_CONCEAL_50" },
	{ "DEF_COVER_75", "DEF_CONCEAL_75" },
	{ "DEF_COVER_75", "DEF_CONCEAL_90" },

	{ "DEF_COVER_90", "DEF_CONCEAL_25" },
	{ "DEF_COVER_90", "DEF_CONCEAL_50" },
	{ "DEF_COVER_90", "DEF_CONCEAL_75" },
	{ "DEF_COVER_90", "DEF_CONCEAL_90" },

	{ "DEF_COVER_25", "DEF_COVER_50" },
	{ "DEF_COVER_25", "DEF_COVER_75" },
	{ "DEF_COVER_25", "DEF_COVER_90" },

	{ "DEF_COVER_50", "DEF_COVER_25" },
	{ "DEF_COVER_50", "DEF_COVER_75" },
	{ "DEF_COVER_50", "DEF_COVER_90" },

	{ "DEF_COVER_75", "DEF_COVER_25" },
	{ "DEF_COVER_75", "DEF_COVER_50" },
	{ "DEF_COVER_75", "DEF_COVER_90" },

	{ "DEF_COVER_90", "DEF_COVER_25" },
	{ "DEF_COVER_90", "DEF_COVER_50" },
	{ "DEF_COVER_90", "DEF_COVER_75" },

	{ "DEF_CONCEAL_25", "DEF_CONCEAL_50" },
	{ "DEF_CONCEAL_25", "DEF_CONCEAL_75" },
	{ "DEF_CONCEAL_25", "DEF_CONCEAL_90" },

	{ "DEF_CONCEAL_50", "DEF_CONCEAL_25" },
	{ "DEF_CONCEAL_50", "DEF_CONCEAL_75" },
	{ "DEF_CONCEAL_50", "DEF_CONCEAL_90" },

	{ "DEF_CONCEAL_75", "DEF_CONCEAL_25" },
	{ "DEF_CONCEAL_75", "DEF_CONCEAL_50" },
	{ "DEF_CONCEAL_75", "DEF_CONCEAL_90" },

	{ "DEF_CONCEAL_90", "DEF_CONCEAL_25" },
	{ "DEF_CONCEAL_90", "DEF_CONCEAL_50" },
	{ "DEF_CONCEAL_90", "DEF_CONCEAL_75" },
};

aDataModuleSet = 
{
	["client"] =
	{
		{
			name = "2E - Core Rules",
			modules =
			{
				{ name = "AD&D 2E Players Handbook", storeid = "WOTC2EPHB", displayname = "AD&D 2E Players Handbook" },
			},
		},
		{
			name = "2E - Rules, Class, Race Books",
			modules =
			{
				{ name = "AD&D 2E Players Handbook", storeid = "WOTC2EPHB", displayname = "AD&D 2E Players Handbook" },
				{ name = "AD&D 2E Tome of Magic", storeid = "WOTC2ETSR2121", displayname = "AD&D 2E Tome of Magic" },
				{ name = "AD&D 2E Demihuman Deities", storeid = "WOTC2E09585", displayname = "AD&D 2E Demihuman Deities" },
				{ name = "AD&D 2E Faiths & Avatars", storeid = "WOTC2ETSR9516", displayname = "AD&D 2E Faiths & Avatars" },
				{ name = "AD&D 2E Complete Book of Elves", storeid = "WOTC2ECBOE", displayname = "AD&D 2E Complete Book of Elves" },
				{ name = "AD&D 2E Complete Bard's Handbook", storeid = "WOTC2ECBH", displayname = "AD&D 2E Complete Bard's Handbook" },
				{ name = "AD&D 2E Complete Druid's Handbook", storeid = "WOTC2ECDH", displayname = "AD&D 2E Complete Druid's Handbook" },
				{ name = "AD&D 2E Complete Fighter's Handbook", storeid = "WOTC2ECFH", displayname = "AD&D 2E Complete Fighter's Handbook" },
				{ name = "AD&D 2E Complete Paladin's Handbook", storeid = "WOTC2ECPH", displayname = "AD&D 2E Complete Paladin's Handbook" },
				{ name = "AD&D 2E Complete Priest's Handbook", storeid = "WOTC2ECPrH", displayname = "AD&D 2E Complete Priest's Handbook" },
				{ name = "AD&D 2E Complete Ranger's Handbook", storeid = "WOTC2ECRH", displayname = "AD&D 2E Complete Ranger's Handbook" },
				{ name = "AD&D 2E Complete Thief's Handbook", storeid = "WOTC2ECTH", displayname = "AD&D 2E Complete Thief's Handbook" },
				{ name = "AD&D 2E Complete Wizard's Handbook", storeid = "WOTC2ECWH", displayname = "AD&D 2E Complete Wizard's Handbook" },
			},
		},
	},
	["local"] =
	{
		{
			name = "2E - Core Rules",
			modules =
			{
				{ name = "AD&D 2E Players Handbook", storeid = "WOTC2EPHB", displayname = "AD&D 2E Players Handbook" },
				{ name = "AD&D 2E Dungeon Master Guide", storeid = "WOTC2EDMG", displayname = "AD&D 2E Dungeon Master Guide" },
				{ name = "AD&D 2E Monstrous Manual", storeid = "WOTC2EMM", displayname = "AD&D 2E Monstrous Manual" },
			},
		},
		{
			name = "2E - Rules, Class, Race Books",
			modules =
			{
				{ name = "AD&D 2E Players Handbook", storeid = "WOTC2EPHB", displayname = "AD&D 2E Players Handbook" },
				{ name = "AD&D 2E Dungeon Master Guide", storeid = "WOTC2EDMG", displayname = "AD&D 2E Dungeon Master Guide" },
				{ name = "AD&D 2E Monstrous Manual", storeid = "WOTC2EMM", displayname = "AD&D 2E Monstrous Manual" },
				{ name = "AD&D 2E Tome of Magic", storeid = "WOTC2ETSR2121", displayname = "AD&D 2E Tome of Magic" },
				{ name = "AD&D 2E Demihuman Deities", storeid = "WOTC2E09585", displayname = "AD&D 2E Demihuman Deities" },
				{ name = "AD&D 2E Faiths & Avatars", storeid = "WOTC2ETSR9516", displayname = "AD&D 2E Faiths & Avatars" },
				{ name = "AD&D 2E Complete Book of Elves", storeid = "WOTC2ECBOE", displayname = "AD&D 2E Complete Book of Elves" },
				{ name = "AD&D 2E Complete Bard's Handbook", storeid = "WOTC2ECBH", displayname = "AD&D 2E Complete Bard's Handbook" },
				{ name = "AD&D 2E Complete Druid's Handbook", storeid = "WOTC2ECDH", displayname = "AD&D 2E Complete Druid's Handbook" },
				{ name = "AD&D 2E Complete Fighter's Handbook", storeid = "WOTC2ECFH", displayname = "AD&D 2E Complete Fighter's Handbook" },
				{ name = "AD&D 2E Complete Paladin's Handbook", storeid = "WOTC2ECPH", displayname = "AD&D 2E Complete Paladin's Handbook" },
				{ name = "AD&D 2E Complete Priest's Handbook", storeid = "WOTC2ECPrH", displayname = "AD&D 2E Complete Priest's Handbook" },
				{ name = "AD&D 2E Complete Ranger's Handbook", storeid = "WOTC2ECRH", displayname = "AD&D 2E Complete Ranger's Handbook" },
				{ name = "AD&D 2E Complete Thief's Handbook", storeid = "WOTC2ECTH", displayname = "AD&D 2E Complete Thief's Handbook" },
				{ name = "AD&D 2E Complete Wizard's Handbook", storeid = "WOTC2ECWH", displayname = "AD&D 2E Complete Wizard's Handbook" },
			},
		},
  },
	["host"] =
	{
		{
			name = "2E - Core Rules",
			modules =
			{
				{ name = "AD&D 2E Players Handbook", storeid = "WOTC2EPHB", displayname = "AD&D 2E Players Handbook" },
				{ name = "AD&D 2E Dungeon Master Guide", storeid = "WOTC2EDMG", displayname = "AD&D 2E Dungeon Master Guide" },
				{ name = "AD&D 2E Monstrous Manual", storeid = "WOTC2EMM", displayname = "AD&D 2E Monstrous Manual" },
			},
		},
		{
			name = "2E - Rules, Class, Race Books",
			modules =
			{
				{ name = "AD&D 2E Players Handbook", storeid = "WOTC2EPHB", displayname = "AD&D 2E Players Handbook" },
				{ name = "AD&D 2E Dungeon Master Guide", storeid = "WOTC2EDMG", displayname = "AD&D 2E Dungeon Master Guide" },
				{ name = "AD&D 2E Monstrous Manual", storeid = "WOTC2EMM", displayname = "AD&D 2E Monstrous Manual" },
				{ name = "AD&D 2E Tome of Magic", storeid = "WOTC2ETSR2121", displayname = "AD&D 2E Tome of Magic" },
				{ name = "AD&D 2E Demihuman Deities", storeid = "WOTC2E09585", displayname = "AD&D 2E Demihuman Deities" },
				{ name = "AD&D 2E Faiths & Avatars", storeid = "WOTC2ETSR9516", displayname = "AD&D 2E Faiths & Avatars" },
				{ name = "AD&D 2E Complete Book of Elves", storeid = "WOTC2ECBOE", displayname = "AD&D 2E Complete Book of Elves" },
				{ name = "AD&D 2E Complete Bard's Handbook", storeid = "WOTC2ECBH", displayname = "AD&D 2E Complete Bard's Handbook" },
				{ name = "AD&D 2E Complete Druid's Handbook", storeid = "WOTC2ECDH", displayname = "AD&D 2E Complete Druid's Handbook" },
				{ name = "AD&D 2E Complete Fighter's Handbook", storeid = "WOTC2ECFH", displayname = "AD&D 2E Complete Fighter's Handbook" },
				{ name = "AD&D 2E Complete Paladin's Handbook", storeid = "WOTC2ECPH", displayname = "AD&D 2E Complete Paladin's Handbook" },
				{ name = "AD&D 2E Complete Priest's Handbook", storeid = "WOTC2ECPrH", displayname = "AD&D 2E Complete Priest's Handbook" },
				{ name = "AD&D 2E Complete Ranger's Handbook", storeid = "WOTC2ECRH", displayname = "AD&D 2E Complete Ranger's Handbook" },
				{ name = "AD&D 2E Complete Thief's Handbook", storeid = "WOTC2ECTH", displayname = "AD&D 2E Complete Thief's Handbook" },
				{ name = "AD&D 2E Complete Wizard's Handbook", storeid = "WOTC2ECWH", displayname = "AD&D 2E Complete Wizard's Handbook" },
			},
		},
	},
};
