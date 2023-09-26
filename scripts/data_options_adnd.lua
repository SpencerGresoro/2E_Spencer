-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


function onInit()
	registerDiceRolls();
	registerOptions();
	
	OptionsManager.registerCallback("OPTIONS_MENU", updateMenuStyle);
	OptionsManager.registerCallback("OPTIONAL_ENCUMBRANCE", updateForEncumbranceOption);

	DesktopManager.getSidebarDockWidth = getSidebarDockWidth_adnd;
	createBackupDBOnStartCheck();
end

function getSidebarDockWidth_adnd()
	-- override piece
	local bMenuStyle = (OptionsManager.getOption("OPTIONS_MENU") == 'menus' or OptionsManager.getOption("OPTIONS_MENU") == '');
	--  need these
	local _nSidebarVisibility = DesktopManager.getSidebarVisibilityState();
	local _szDockCategory = DesktopManager.getSidebarDockCategorySize();
	local _rcDockCategoryOffset = DesktopManager.getSidebarDockCategoryOffset();
	local _rcDockButtonOffset = DesktopManager.getSidebarDockButtonOffset();
	local _szDockButton = DesktopManager.getSidebarDockButtonSize();
	if (bMenuStyle) then
		_nSidebarVisibility = 4;
	end

	hideMenuBar();

	-- end override piece
	if _nSidebarVisibility <= 0 then
		local nDockCategoryWidth = _szDockCategory.w + (_rcDockCategoryOffset.left + _rcDockCategoryOffset.right);
		local nDockButtonWidth = _szDockButton.w + (_rcDockButtonOffset.left + _rcDockButtonOffset.right);
		return math.max(nDockCategoryWidth, nDockButtonWidth);
	end
	local nDockIconWidth = DesktopManager.getSidebarDockIconWidth();
	if _nSidebarVisibility == 1 then
		return nDockIconWidth * 2;
	end
	-- override piece
	if (_nSidebarVisibility == 4) then
		nDockIconWidth = -9;
	end
	-- end override piece
	return nDockIconWidth;
end


function registerDiceRolls()
	DiceRollManager.registerDamageKey();
	DiceRollManager.registerDamageTypeKey("acid", "life");
	DiceRollManager.registerDamageTypeKey("cold", "frost");
	DiceRollManager.registerDamageTypeKey("fire", "fire");
	DiceRollManager.registerDamageTypeKey("force", "arcane");
	DiceRollManager.registerDamageTypeKey("lightning", "lightning");
	DiceRollManager.registerDamageTypeKey("necrotic", "shadow");
	DiceRollManager.registerDamageTypeKey("poison", "life");
	DiceRollManager.registerDamageTypeKey("psychic", "shadow");
	DiceRollManager.registerDamageTypeKey("radiant", "light");
	DiceRollManager.registerDamageTypeKey("thunder", "storm");

	DiceRollManager.registerDamageTypeKey("bludgeoning");
	DiceRollManager.registerDamageTypeKey("piercing");
	DiceRollManager.registerDamageTypeKey("slashing");

	DiceRollManager.registerDamageTypeKey("adamantine");
	DiceRollManager.registerDamageTypeKey("cold-forged iron");
	DiceRollManager.registerDamageTypeKey("silver");

	DiceRollManager.registerDamageTypeKey("magic");

	DiceRollManager.registerHealKey();
	DiceRollManager.registerHealTypeKey("health", "light");
	DiceRollManager.registerHealTypeKey("temp", "water");
end



function registerOptions()
	-- Standard D&D options from 5E
	OptionsManager.registerOption2("RMMT", true, "option_header_client", "option_label_RMMT", "option_entry_cycler", 
		{ labels = "option_val_on|option_val_multi", values = "on|multi", baselabel = "option_val_off", baseval = "off", default = "multi" });

	OptionsManager.registerOption2("SHRR", false, "option_header_game", "option_label_SHRR", "option_entry_cycler", 
		{ labels = "option_val_on|option_val_friendly", values = "on|pc", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("PSMN", false, "option_header_game", "option_label_PSMN", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("INIT", false, "option_header_combat", "option_label_INIT", "option_entry_cycler", 
		{ labels = "option_val_on|option_val_group", values = "on|group", baselabel = "option_val_off", baseval = "off", default = "group" });
	OptionsManager.registerOption2("NPCD", false, "option_header_combat", "option_label_NPCD", "option_entry_cycler", 
		{ labels = "option_val_fixed", values = "fixed", baselabel = "option_val_variable", baseval = "off", default = "off" });
	OptionsManager.registerOption2("BARC", false, "option_header_combat", "option_label_BARC", "option_entry_cycler", 
		{ labels = "option_val_tiered", values = "tiered", baselabel = "option_val_standard", baseval = "", default = "" });
	OptionsManager.registerOption2("SHPC", false, "option_header_combat", "option_label_SHPC", "option_entry_cycler", 
		{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "detailed" });
	OptionsManager.registerOption2("SHNPC", false, "option_header_combat", "option_label_SHNPC", "option_entry_cycler", 
		{ labels = "option_val_detailed|option_val_status", values = "detailed|status", baselabel = "option_val_off", baseval = "off", default = "status" });
	OptionsManager.registerOption2("WNDC", false, "option_header_combat", "option_label_WNDC", "option_entry_cycler", 
		{ labels = "option_val_detailed", values = "detailed", baselabel = "option_val_simple", baseval = "off", default = "off" });

	OptionsManager.registerOption2("HRFC", false, "option_header_houserule", "option_label_HRFC", "option_entry_cycler", 
		{ labels = "option_val_fumbleandcrit|option_val_fumble|option_val_crit", values = "both|fumble|criticalhit", baselabel = "option_val_off", baseval = "", default = "" });
	OptionsManager.registerOption2("HRDD", false, "option_header_houserule", "option_label_HRDD", "option_entry_cycler", 
		{ labels = "option_val_standard|option_val_variant", values = "standard|variant", baselabel = "option_val_raw", baseval = "raw", default = "raw" });

	-- use Menus or Sidebar
	OptionsManager.registerOption2("OPTIONS_MENU", true, "option_header_client", "option_label_OPTION_MENU", "option_entry_cycler", 
		{ labels = "option_val_sidebar", values = "sidebar", baselabel = "option_val_menus", baseval = "menus", default = "menus" });

	-- GAME
	-- use Fighter Handbook armor damagepoint rules
	OptionsManager.registerOption2("OPTIONAL_ARMORDP", false, "option_header_adnd_options", "option_label_OPTIONAL_ARMORDB", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	-- use Fighter Handbook armor damagepoint rules
	OptionsManager.registerOption2("OPTIONAL_ENCUMBRANCE", false, "option_header_adnd_options", "option_label_OPTIONAL_ENCUMBRANCE", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	-- OptionsManager.registerOption2("OPTIONAL_ENCUMBRANCE_COIN", false, "option_header_adnd_options", "option_label_OPTIONAL_ENCUMBRANCE_COIN", "option_entry_cycler", 
	--	{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("HouseRule_DeathsDoor", false, "option_header_adnd_options", "option_label_ADND_DEATHSDOOR", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("OPTIONAL_INIT_SIZEMODS", false, "option_header_adnd_options", "option_label_OPTIONAL_INIT_SIZEMODS", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });

	-- JPG - 2022-09-25 - Removed option that already exists in CoreRPG

	-- re-register the version of this that CoreRPG does so that we can set the default ON since AD&D uses re-roll each round also --celestian
	OptionsManager.registerOption2("RNDS", false, "option_header_combat", "option_label_RNDS", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	-- PCs initiative type
	OptionsManager.registerOption2("PCVNPCINIT", false, "option_header_combat", "option_label_PCVNPCINIT", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	-- TOKEN OPTIONS 
	-- show npc effects to PC
	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
		{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	-- show npc health bars to PC
	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
		{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });

	-- show pc effects to PC
	OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
		{ labels = "option_val_tooltip|option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "tooltip|on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	-- show pc health bars to PC
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
		{ labels = "option_val_tooltip|option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "tooltip|bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	-- show name/tooltip
	-- OptionsManager.registerOption2("TNAM", false, "option_header_token", "option_label_TNAM", "option_entry_cycler", 
	-- 	{ labels = "option_val_tooltip|option_val_title|option_val_titlehover", values = "tooltip|on|hover", baselabel = "option_val_off", baseval = "off", default = "tooltip" });

	-- set "has initiative" highlight overlay token 
	OptionsManager.registerOption2("TOKEN_OPTION_INIT", false, "option_header_token", "option_label_TOKEN_OPTION_INIT", "option_entry_cycler", 
		{ labels = "option_val_has_init_token2|option_val_has_init_token3|option_val_has_init_token4|option_val_has_init_token5|option_val_has_init_token6", values = "2|3|4|5|6", baselabel = "option_val_has_init_token1", baseval = "1", default = "1" });

	--- HOUSE RULES
	OptionsManager.registerOption2("HRNH", false, "option_header_houserule", "option_label_HRNH", "option_entry_cycler", 
		{ labels = "option_val_max|option_val_random|option_val_80plus", values = "max|random|80plus", baselabel = "option_val_off", baseval = "off", default = "random" });
	OptionsManager.registerOption2("HouseRule_InitEachRound", false, "option_header_houserule", "option_label_HOUSE_RULE_INIT_EACH_ROUND", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("HouseRule_CRIT_TYPE", false, "option_header_houserule", "option_label_HR_CRIT", "option_entry_cycler", 
		{ labels = "option_val_hr_crit_maxdmg|option_val_hr_crit_timestwo|option_val_hr_crit_none", values = "max|timestwo|none", baselabel = "option_val_hr_crit_doubledice", baseval = "doubledice", default = "doubledice" });

	-- this is not a option in AD&D 2e?
	-- OptionsManager.registerOption2("HouseRule_ASCENDING_AC", false, "option_header_houserule", "option_label_HR_ASENDING_AC", "option_entry_cycler", 
	-- 	{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("OPTIONS_DBBACKUP", false, "option_header_system", "option_label_OPTION_DBBACKUP", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	-- OptionsManager.registerOption2("OPTIONS_EFFECT_AURA", false, "option_header_system", "option_label_OPTION_EFFECT_AURA", "option_entry_cycler", 
	--	{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
end

wMenuWindow = nil;
function registerWindowMenu(wWindow)
	if not wMenuWindow then
		wMenuWindow = wWindow;
		updateMenuStyle();
	end
end
wSidebarWindow = nil;
function registerWindowSidebar(wWindow)
	if not wSidebarWindow then
		wSidebarWindow = wWindow;
		updateMenuStyle();
	end
end


local nUpdateVersion = 35;
function updateMenuStyle()
	if wMenuWindow and wSidebarWindow then
UtilityManagerADND.logDebug("data_options_adnd.lua updateMenuStyle OPTIONS_MENU",OptionsManager.getOption("OPTIONS_MENU"));
		local bMenuStyle = (OptionsManager.getOption("OPTIONS_MENU") == 'menus' or OptionsManager.getOption("OPTIONS_MENU") == '');
		if bMenuStyle then
			enableMenuStyleButtons();
		else
			enableMenuStyleSidebar();
		end
		DesktopManager.saveSidebarVisibilityState()
	end
end

function enableMenuStyleButtons()
--	UtilityManagerADND.logDebug("data_options_adnd.lua","enableMenuStyleButtons");
	-- wSidebarWindow.setEnabled(false);
	-- wSidebarWindow.close();
	-- wMenuWindow.setEnabled(true);
	DesktopManager.setSidebarVisibilityState(4);
	DesktopManager.updateSidebarAnchorWindowPosition();
	wMenuWindow.setPosition(3,5, 0, false);
end

function hideMenuBar()
	local bMenuStyle = (OptionsManager.getOption("OPTIONS_MENU") == 'menus' or OptionsManager.getOption("OPTIONS_MENU") == '');
	if (wMenuWindow and not bMenuStyle) then
		wMenuWindow.setPosition(-90000,-90000, 0, false);
	end
end
function enableMenuStyleSidebar()
--	UtilityManagerADND.logDebug("data_options_adnd.lua","enableMenuStyleSidebar");
	-- wMenuWindow.setEnabled(false);
	-- wMenuWindow.close();
	-- wMenuWindow.setEnabled(true);
	-- wMenuWindow.setAnchor("left","shortcuts","right","absolute");
	-- wMenuWindow.setPosition(-90000,-90000, 0, false);
	hideMenuBar();
	-- wMenuWindow.onSizeChanged = hideMenuBar;
	-- local _nSidebarVisibility = DesktopManager.getSidebarVisibilityState();
	-- if _nSidebarVisibility == 4 then
	-- 	DesktopManager.setSidebarVisibilityState(0);
	-- end
	DesktopManager.setSidebarVisibilityState(0);
	DesktopManager.updateSidebarAnchorWindowPosition();
end


function createBackupDBOnStartCheck()
	if Session.IsHost and OptionsManager.getOption("OPTIONS_DBBACKUP") == 'on' then
		ChatManager.SystemMessage("Creating database backup. Saved to a unique file name. (db.script.#.xml)");
		DB.backup();
	end
end

-- recheck encumbrance settings with value changed.
function updateForEncumbranceOption()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		CharManager.calcWeightCarried(nodeChar)
	end
end

