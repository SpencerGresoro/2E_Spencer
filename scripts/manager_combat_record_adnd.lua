-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DELAYED_COPY = false;
local _tInitialCopy = {
	"ac",
	"alignment",
	"hd",
	"hdtext",
	"hitDice",
	"hp",
	"initiative",
	"saves",
	"size",
	"source",
	"specialAttacks",
	"specialDefense",
	"token",
	"type",
};
local _tDelayedCopy = {
	"abilities",
	"abilitynoteslist",
	"combat",
	"coins",
	"arcane",
	"divine",
	"effectlist",
	"encumbrance",
	"inventorylist",
	"languagelist",
	"powermeta",
	"powergroup",
	"powers",
	"proficiencies",
	"proficiencylist",
	"psionic",
	"surprise",
	"skilllist",
	"text",
	"turn",
	"weaponlist",
	"actext",
	"climate",
	"damage",
	"diet",
	"frequency",
	"intelligence_text",
	"level",
	"magicresistance",
	"morale",
	"numberappearing",
	"numberattacks",
	"organization",
	"size",
	"speed",
	"thaco",
	"treasure",
	"xp",
};
-- Ignored (set by onNPCPostAdd)
-- local _tIgnoredCopy = {
-- 	"name",
-- 	"nonid_name",
-- 	"powerdisplaymode",
-- 	"powermode",
-- };

-- JPG - 2022-09-25 - Updated to use latest functions and removed CoreRPG duplication
function onInit()
	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", getNPCSpaceReach);
	if Session.IsHost then
		CombatRecordManager.setRecordTypeCallback("npc", onNPCAdd);
		CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
		CombatRecordManager.setRecordTypePostAddCallback("charsheet", onPCPostAdd);
	end
end

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatRecordManagerADND
function getNPCSpaceReach(rActor)
	local nSpace = GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;
	
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nSpace, nReach;
	end

	local sSize = StringManager.trim(DB.getValue(nodeActor, "size", ""):lower());
	if sSize == "large" then
		nSpace = nSpace * 2;
	elseif sSize == "huge" then
		nSpace = nSpace * 3;
	elseif sSize == "gargantuan" then
		nSpace = nSpace * 4;
	end

	return nSpace, nReach;
end

-- JPG - 2022-09-25 - Updated function to most recent CoreRPG methodology
function onPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	-- Update CT effects
	helperAddEffects(tCustom);
end

-- JPG - 2022-09-25 - Updated function to most recent CoreRPG methodology
function onNPCAdd(tCustom)
	if not tCustom.nodeRecord then
		return false;
	end
	tCustom.nodeCT = CombatManager.createCombatantNode();
	if not tCustom.nodeCT then
		return false;
	end

	helperAddHiddenName(tCustom);

	if DELAYED_COPY then
		helperCopyCTSourceToNode(tCustom.nodeRecord, tCustom.nodeCT, _tInitialCopy);
	else
		DB.copyNode(tCustom.nodeRecord, tCustom.nodeCT);
	end

	DB.setValue(tCustom.nodeCT, "locked", "number", 1);

	-- Remove any combatant specific information
	DB.setValue(tCustom.nodeCT, "active", "number", 0);
	DB.setValue(tCustom.nodeCT, "tokenrefid", "string", "");
	DB.setValue(tCustom.nodeCT, "tokenrefnode", "string", "");
	DB.deleteChildren(tCustom.nodeCT, "effects");

	CombatRecordManager.handleStandardCombatAddFields(tCustom);
	CombatRecordManager.handleStandardCombatAddSpaceReach(tCustom);
	CombatRecordManager.handleStandardCombatAddPlacement(tCustom);
	return true;
end
-- NOTE: If delayed copy no longer needed, function can be vastly simplified
-- function onNPCAdd(tCustom)
-- 	helperAddHiddenName(tCustom);
-- 	CombatRecordManager.addNPC(tCustom);
-- 	return true;
-- end

-- JPG - 2022-09-25 - Updated function to most recent CoreRPG methodology
function onNPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	-- Save hidden name data
	helperAddHiddenName2(tCustom);

	-- Handle game system specific size considerations
	helperAddSize(tCustom);

	-- Calculate and set HP
	helperAddHP(tCustom);

	-- Update CT effects
	helperAddEffects(tCustom);

	-- Set mode/display default to standard/actions
	DB.setValue(tCustom.nodeCT, "powermode", "string", "standard");
	DB.setValue(tCustom.nodeCT, "powerdisplaymode", "string", "action");

	-- Sanitize special attack/defense
	helperAddSpecialAD(tCustom);

	-- Roll initiative and sort
	helperAddInit(tCustom);

	-- Special handling for NPCs added from battles
	helperAddBattleNPC(tCustom);
end
function helperAddHiddenName(tCustom)
	if not tCustom.sName then
		tCustom.sName = DB.getValue(tCustom.nodeRecord, "name", "");
	end
	tCustom.sNameHidden = tCustom.sName:match("%(.*%)");
	tCustom.sName = StringManager.trim(tCustom.sName:gsub("%(.*%)", ""));
end
function helperAddHiddenName2(tCustom)
	-- save DM only "hiddten text" if necessary to display in host CT
	if (tCustom.sNameHidden or "") ~= "" then
		DB.setValue(tCustom.nodeCT, "name_hidden", "string", tCustom.sNameHidden);
	end
end
function helperAddSize(tCustom)
	-- base modifier for initiative
	-- we set modifiers based on size per DMG for AD&D -celestian
	DB.setValue(tCustom.nodeCT, "init", "number", 0);

	-- Determine size
	local sSize = StringManager.trim(DB.getValue(tCustom.nodeCT, "size", "")):lower();
	local sSizeNoLower = StringManager.trim(DB.getValue(tCustom.nodeCT, "size", ""));
	if sSize == "tiny" or string.find(sSizeNoLower, "T") then
		DB.setValue(tCustom.nodeCT, "init", "number", 0);
	elseif sSize == "small" or string.find(sSizeNoLower, "S") then
		DB.setValue(tCustom.nodeCT, "init", "number", 3);
	elseif sSize == "medium" or string.find(sSizeNoLower, "M") then
		DB.setValue(tCustom.nodeCT, "init", "number", 3);
	elseif sSize == "large" or string.find(sSizeNoLower, "L") then
		DB.setValue(tCustom.nodeCT, "init", "number", 6);
	elseif string.find(sSizeNoLower, "GIANT") then
		DB.setValue(tCustom.nodeCT, "space", "number", 10);
		DB.setValue(tCustom.nodeCT, "init", "number", 6);
	elseif sSize == "huge" or string.find(sSizeNoLower, "H") then
		DB.setValue(tCustom.nodeCT, "space", "number", 10);
		DB.setValue(tCustom.nodeCT, "init", "number", 9);
	elseif sSize == "gargantuan" or string.find(sSizeNoLower, "G") then
		DB.setValue(tCustom.nodeCT, "space", "number", 15);
		DB.setValue(tCustom.nodeCT, "init", "number", 12);
	end

	-- allow custom TOKEN_SIZE: XX 
	if sSizeNoLower:find("TOKEN_SIZE:%s?%d+") then
		local sTokenSize = sSizeNoLower:match("TOKEN_SIZE:%s?(%d+)");
		local nTokenSize = tonumber(sTokenSize) or 5;
		DB.setValue(tCustom.nodeCT, "space", "number", nTokenSize);
	end
	-- allow custom TOKEN_REACH: XX 
	if sSizeNoLower:find("TOKEN_REACH:%s?%d+") then
		local sTokenReach = sSizeNoLower:match("TOKEN_REACH:%s?(%d+)");
		local nTokenReach = tonumber(sTokenReach) or 5;
		DB.setValue(tCustom.nodeCT, "reach", "number", nTokenReach);
	end
end
function helperAddHP(tCustom)
	local nHP = rollNPCHitPoints(tCustom.nodeRecord);
	DB.setValue(tCustom.nodeCT, "wounds", "number", 0);
	DB.setValue(tCustom.nodeCT, "hptotal", "number", nHP);
	-- we store "base" here also using current total.
	DB.setValue(tCustom.nodeCT, "hpbase", "number", nHP);
end
function helperAddEffects(tCustom)
	-- check to see if npc effects exists and if so apply --celestian
	EffectManagerADND.updateCharEffects(tCustom.nodeRecord, tCustom.nodeCT);

	-- now flip through inventory and pass each to updateEffects()
	-- so that if they have a combat_effect it will be applied.
	for _,nodeItem in pairs(DB.getChildren(tCustom.nodeRecord, "inventorylist")) do
		EffectManagerADND.updateItemEffects(nodeItem, tCustom.nodeCT);
	end
end
function helperAddSpecialAD(tCustom)
	local sSA = DB.getValue(tCustom.nodeCT, "specialAttacks", ""):lower();
	if sSA:match("nil") or sSA:match("see desc") then
		DB.setValue(tCustom.nodeCT, "specialAttacks", "string", "");
	end

	local sSD = DB.getValue(tCustom.nodeCT, "specialDefense", ""):lower();
	if sSD:match("nil") or sSD:match("see desc") then
		DB.setValue(tCustom.nodeCT, "specialDefense", "string", "");
	end
end
function helperAddInit(tCustom)
	-- if the combat window initiative is set to something, use it instead --celestian
	local nInitMod = DB.getValue(tCustom.nodeRecord, "initiative.total", 0);
	if nInitMod ~= 0 then
		DB.setValue(tCustom.nodeCT, "init", "number", nInitMod);
	else
		DB.setValue(tCustom.nodeCT, "initiative.misc", "number", DB.getValue(tCustom.nodeCT, "init",0));
	end

	-- Roll initiative and sort
	local sOptINIT = OptionsManager.getOption("INIT");
	if (nInitMod == 0) then
		nInitMod = DB.getValue(tCustom.nodeCT, "init", 0);
	end
	local nInitiativeRoll = math.random(DataCommonADND.nDefaultInitiativeDice) + nInitMod;
	if sOptINIT == "group" then
		if tCustom.nodeCTLastMatch then
			local nLastInit = DB.getValue(tCustom.nodeCTLastMatch, "initresult", 0);
			DB.setValue(tCustom.nodeCT, "initresult", "number", nLastInit);
		else
			DB.setValue(tCustom.nodeCT, "initresult", "number", nInitiativeRoll);
		end
	elseif sOptINIT == "on" then
		DB.setValue(tCustom.nodeCT, "initresult", "number", nInitiativeRoll);
	end
end
function helperAddBattleNPC(tCustom)
	if not tCustom.tBattleEntry or not tCustom.tBattleEntry.nodeBattleEntry then
		return;
	end

	local nHP = DB.getValue(tCustom.tBattleEntry.nodeBattleEntry, "hp", 0);
	if (nHP ~= 0) then
		DB.setValue(tCustom.nodeCT, "hp", "number", nHP);
		DB.setValue(tCustom.nodeCT, "hpbase", "number", nHP);
		DB.setValue(tCustom.nodeCT, "hptotal", "number", nHP);
	end

	local nAC = DB.getValue(tCustom.tBattleEntry.nodeBattleEntry, "ac", 11);
	if (nAC <= 10) then
		DB.setValue(tCustom.nodeCT, "ac", "number", nAC);
	end

	local sItemList = DB.getValue(tCustom.tBattleEntry.nodeBattleEntry, "items", "");
	if (sItemList ~= "") then
		local nodeItems = DB.createChild(tCustom.nodeCT, "inventorylist");
		for _,sItem in ipairs(StringManager.split(sItemList, ";", true)) do
			local nodeSourceItem = UtilityManagerADND.getItemNodeByName(sItem);
			if nodeSourceItem then
				local nodeItem = DB.createChild(nodeItems);
				DB.copyNode(nodeSourceItem, nodeItem);
				DB.setValue(nodeItem, "locked", "number", 1);
			 	-- //TODO make it so you can set number of items?
				DB.setValue(nodeItem, "count", "number", 1);
				DB.setValue(nodeItem, "isidentified", "number", 1);
				CharManager.addToPowerDB(nodeItem);
			else
				local sError = string.format("Encounter [%s], unable to find item [%s] for NPC [%s].", DB.getValue(tCustom.nodeRecord, "name", ""), sItem, DB.getValue(tCustom.nodeCT, "name", ""));
				ChatManager.SystemMessage(sError);
			end
		end
	end

	local sWeaponList = DB.getValue(tCustom.tBattleEntry.nodeBattleEntry, "weapons", "");
	if (sWeaponList ~= "") then
		for _,sWeapon in ipairs(StringManager.split(sWeaponList, ";", true)) do
			if not UtilityManagerADND.hasWeaponNamed(tCustom.nodeCT,sWeapon) then 
				local nodeSourceWeapon = UtilityManagerADND.getWeaponNodeByName(sWeapon);
				if nodeSourceWeapon then
					local nodeWeapons = DB.createChild(tCustom.nodeCT, "weaponlist");
					for _,v in pairs(DB.getChildren(nodeSourceWeapon, "weaponlist")) do
						local nodeWeapon = DB.createChild(nodeWeapons);
						DB.copyNode(v, nodeWeapon);
						DB.setValue(nodeWeapon, "itemnote.name", "string", DB.getValue(v, "name", ""));
						DB.setValue(nodeWeapon, "itemnote.text", "formattedtext", DB.getValue(v, "text", ""));
						DB.setValue(nodeWeapon, "itemnote.locked", "number", 1);
					end
				else
					local sError = string.format("Encounter [%s], unable to find weapon [%s] for NPC [%s].", DB.getValue(tCustom.nodeRecord, "name", ""), sWeapon, DB.getValue(tCustom.nodeCT, "name", ""));
					ChatManager.SystemMessage(sError);
				end
			end
		end
	end

	local sSpellsList = DB.getValue(tCustom.tBattleEntry.nodeBattleEntry, "spells", "");
	if (sSpellsList ~= "") then
		local tSpells = StringManager.split(sSpellsList, ";", true);
		CombatManagerADND.addSpellsFromList(tCustom.nodeCT, tSpells);
	end
end

-- generate hitpoint value for NPC and return it
function rollNPCHitPoints(nodeNPC)
	-- Set current hit points
	local sOptHRNH = OptionsManager.getOption("HRNH");
	local nHP = DB.getValue(nodeNPC, "hp", 0);
	if (nHP == 0) then -- if HP value not set, we roll'm
		local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
		if sOptHRNH == "max" and sHD ~= "" then
			-- max hp
			nHP = StringManager.evalDiceString(sHD, true, true);
		elseif sOptHRNH == "random" and sHD ~= "" then
			nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
		elseif sOptHRNH == "80plus" and sHD ~= "" then        
			-- roll hp, if it's less than 80% of what max then set to 80% of max
			-- i.e. if hp max is 100, 80% of that is 80. If the random is less than
			-- that the value will be set to 80.
			local nMaxHP = StringManager.evalDiceString(sHD, true, true);
			local n80 = math.floor(nMaxHP * 0.8);
			nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
			if (nHP < n80) then
				nHP = n80;
			end
		end
	end
	return nHP
end

--  NOTE: Return boolean on success
function checkDelayedCopy(nodeCT)
	if not DELAYED_COPY then
		return true;
	end

	if DB.getValue(nodeCT, "sourceloaded", 0) == 1 then
		return true;
	end

	local sClass,sRecord = DB.getValue(nodeCT, "sourcelink", "", "");
	if sClass ~= "npc" or sRecord == "" then
		return false;
	end

	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return false;
	end

	helperCopyCTSourceToNode(nodeSource, nodeCT, _tDelayedCopy);

	-- clear out effects that came from the SOURCE when dropped
	-- we added them incase they were useful before loading into selected
	for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
		local sEffectSource = DB.getValue(nodeEffect,"source_name","");
		if sEffectSource:match('inventorylist%.') then
			nodeEffect.delete();
		end
	end
 	-- add effects to the target from anything in inventory
	for _,nodeItem in pairs(DB.getChildren(nodeCT, "inventorylist")) do
		EffectManagerADND.updateItemEffects(nodeItem,nodeCT);
	end

	-- flag it as source loaded now that we did
	DB.setValue(nodeCT,"sourceloaded", "number", 1);
	return true;
end
-- this takes data from nodeNPC and places the important data needed into nodeCT.
function helperCopyCTSourceToNode(nodeSource, nodeCT, tChildren)
	for _,sNodeName in pairs(tChildren) do 
		copySourceToNodeCTHelper(nodeSource,nodeCT,sNodeName);
	end
end
-- this copies specific nodes under source to destination
-- copySourceToNodeCTHelper(nodeSource,nodeDest,"powers")
function copySourceToNodeCTHelper(nodeSource, nodeDest, sNode)
	if DB.getChild(nodeSource, sNode) ~= nil then
		local nChildCount = DB.getChildCount(nodeSource, sNode);
		-- we do this so if we copy to a node that already has children
		-- it will create new ids for the incoming copies so it doesn't replace existing.
		if nChildCount > 0 and isIDListedChildren(nodeSource, sNode) then
			local nodeDestAdded = nodeDest.createChild(sNode);
			for _,nodeSourceFound in pairs(DB.getChildren(nodeSource, sNode)) do
				local nodeCopy = nodeDestAdded.createChild();
				DB.copyNode(nodeSourceFound, nodeCopy);
			end
		else
			DB.copyNode(DB.getPath(nodeSource, sNode), DB.getPath(nodeDest, sNode));
		end
	end
end
-- see if children are id listed nodes, id-00000 type.
function isIDListedChildren(node,sTag)
	local bID = false;
	for _,nodeChecked in pairs(DB.getChildren(node, sTag)) do
		local sPath, sModule = DB.getPath(nodeChecked):match("([^@]*)@(.*)");
		if not sPath then 
			sPath = DB.getPath(nodeChecked);
		end
		if sPath:match("%.id%-%d+$") then
			bID = true;
			break;
		end
	end
	return bID;
end
