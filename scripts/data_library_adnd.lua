-- data library for ad&d core ruleset
--
--
--

aListViews = {
	["npc"] = {
		["byletter"] = {
			aColumns = {
        { sName = "name", sType = "string", sHeading = "Name", nWidth=300, nSortOrder=1 },
        { sName = "hitDice", sType = "string", sHeading = "HD", bCentered=true }
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		["byhd"] = {
			aColumns = {
        { sName = "name", sType = "string", sHeading = "Name", nWidth=250, nSortOrder=1 },
        { sName = "hitDice", sType = "string", sHeading = "HD", bCentered=true }
			},
			aFilters = { },
			aGroups = { { sDBField = "hitDice", sPrefix = "HD" } },
		},
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=250, nSortOrder=1 },
				{ sName = "hitDice", sType = "string", sHeading = "HD", bCentered=true },
        { sName = "type", sType = "string", sHeading = "Type", bCentered=true }
			},
			aFilters = { },
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = { },
		},
	},
	["item"] = {
		["armor"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
				{ sName = "cost", sType = "string", sHeading = "Cost", bCentered=true },
				{ sName = "ac", sType = "number", sHeading = "AC", sTooltp = "Armor Class", nWidth=40, bCentered=true },
				{ sName = "weight", sType = "number", sHeading = "Weight", bCentered=true }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Armor" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Light Armor", "Medium Armor", "Heavy Armor", "Shield" },
		},

		["gear"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
				{ sName = "cost", sType = "string", sHeading = "Cost", bCentered=true },
				{ sName = "weight", sType = "number", sHeading = "Weight", bCentered=true },
				{ sName = "properties", sType = "string", sHeading = "Prop.", nWidth=200, bCentered=true }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Gear" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Equipment Packs", "Provisions", "Clothing", "Tool", "Container", "Tack And Harness" },
		},


    ["weapon"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
				{ sName = "cost", sType = "string", sHeading = "Cost", bCentered=true },
        { sName = "weight", sType = "number", sHeading = "Weight", bCentered=true },
        { sName = "properties", sType = "string", sHeading = "Prop.", nWidth=200, bCentered=true }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Weapon" }, 
				{ sCustom = "item_isidentified" } 
			},
			-- aGroups = { { sDBField = "subtype" } },
			-- aGroupValueOrder = { "Simple Melee Weapons", "Simple Ranged Weapons", "Martial Weapons", "Martial Melee Weapons", "Martial Ranged Weapons" },
		},
	},
  ["spell"] = {
		["arcane"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
        { sName = "level", sType = "number", sHeading = "Level", bCentered=true },
				{ sName = "castingtime", sType = "string", sHeading = "Cast Time", bCentered=true, nWidth=80 },
				{ sName = "range", sType = "string", sHeading = "Range", bCentered=true, nWidth=120,  },
        { sName = "components", sType = "string", sHeading = "Components", bCentered=true, nWidth=80 },
        { sName = "save", sType = "string", sHeading = "Save", bCentered=true, nWidth=80 }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Arcane" }, 
			},
			aGroups = { { sDBField = "level" } },
			aGroupValueOrder = { },
		},
		["divine"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
        { sName = "level", sType = "number", sHeading = "Level", bCentered=true },
				{ sName = "castingtime", sType = "string", sHeading = "Cast Time", bCentered=true, nWidth=80 },
				{ sName = "range", sType = "string", sHeading = "Range", bCentered=true, nWidth=120,  },
        { sName = "components", sType = "string", sHeading = "Components", bCentered=true, nWidth=80 },
        { sName = "save", sType = "string", sHeading = "Save", bCentered=true, nWidth=80 },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Divine" }, 
			},
			aGroups = { { sDBField = "level" } },
			aGroupValueOrder = { },
		},

		["bysphere"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
        { sName = "level", sType = "number", sHeading = "Level", bCentered=true },
				{ sName = "castingtime", sType = "string", sHeading = "Cast Time", bCentered=true, nWidth=80 },
				{ sName = "range", sType = "string", sHeading = "Range", bCentered=true, nWidth=120,  },
        { sName = "components", sType = "string", sHeading = "Components", bCentered=true, nWidth=80 },
        { sName = "save", sType = "string", sHeading = "Save", bCentered=true, nWidth=80 }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Divine" }, 
			},
			aGroups = { { sDBField = "sphere" } },
			aGroupValueOrder = { },
		},
		["byschool"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
        { sName = "level", sType = "number", sHeading = "Level", bCentered=true },
				{ sName = "castingtime", sType = "string", sHeading = "Cast Time", bCentered=true, nWidth=80 },
				{ sName = "range", sType = "string", sHeading = "Range", bCentered=true, nWidth=120,  },
        { sName = "components", sType = "string", sHeading = "Components", bCentered=true, nWidth=80 },
        { sName = "save", sType = "string", sHeading = "Save", bCentered=true, nWidth=80 }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Arcane" }, 
			},
			aGroups = { { sDBField = "school" } },
			aGroupValueOrder = { },
		},
  },
  ["skill"] = {
		["bystat"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeading = "Name", nWidth=200, nSortOrder=1 },
				{ sName = "stat", sType = "string", sHeading = "Stat", bCentered=true, nWidth=80, },
				{ sName = "base_check", sType = "number", sHeading = "Base", bCentered=true, nWidth=80 },
				{ sName = "adj_mod", sType = "number", sHeading = "Modifier", bCentered=true, nWidth=80,  }
			},
			aGroups = { { sDBField = "stat" } },
			aGroupValueOrder = { },
		},

  },
};

function onInit()
  -- we don't use vehicle records in AD&D, so hide them
  LibraryData.setRecordTypeInfo("vehicle", nil);
  LibraryData.setRecordViews(aListViews);
end
