--
-- AD&D Specific combat needs
--

PC_LASTINIT = 0;
NPC_LASTINIT = 0;
OOB_MSGTYPE_CHANGEINIT = "changeinitiative";

--This could us a window to bulk delete/add
--w/o triggering cache rebuild?
--disableCombatantsCache = false;

-- JPG - 2022-09-25 - Updated to use latest functions and remove CoreRPG duplication
function onInit()
	-- This can be used where we set flags on tokens in the CT
	-- that are not "in" the combat tracker. Allowing you to pre-load
	-- all the NPCs on the map and then only "show" those visible.
	-- Celestian
	-- replace default CombatManager.getCombatantNodes()
	-- disabled ct.visible feature
	-- CombatManager.setCustomGetCombatantNodes(getCombatantNodes_adnd);
	-- buildCombatantNodesCache();

	-- replace default roll with adnd_roll to allow
	-- control-dice click to prompt for manual roll
	ActionsManager.roll = adnd_roll;

	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_CHANGEINIT, handleInitiativeChange);
	--if Session.IsHost then
	DB.addHandler("combattracker.list.*.active", "onUpdate", updateInititiativeIndicator);
	OptionsManager.registerCallback("TOKEN_OPTION_INIT", initiativeTokenChanged);
	updateAllInititiativeIndicators();
	--end

	CombatManager.setCustomSort(sortfuncADnD);
	CombatManager.setCustomCombatReset(resetInit);
	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnStart(onTurnStart);

	Interface.onHotkeyActivated = onHotkey;
end

function onHotkey(draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "combattrackerdelayactor" then
		CombatManagerADND.delayTurn(CombatManager.getActiveCT());
		return true;
	end
end

-- set the new initiative with "root" permissions
function handleInitiativeChange(msgOOB)
  local nodeCT = DB.findNode(msgOOB.sCTRecord);
  if nodeCT then
    DB.setValue(nodeCT,"initresult","number",msgOOB.nNewInit);
  end
end
-- players dont have permissions to edit CT records
-- this hands it off to manage it for them
function notifyInitiativeChange(nodeCT,nNewInit)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_CHANGEINIT;
  msgOOB.nNewInit = nNewInit;
  msgOOB.sCTRecord = nodeCT.getPath();
	Comm.deliverOOBMessage(msgOOB, "");
end

-- In AD&D we don't remove effects unless shorter than 10 rounds (Turn) 
function clearExpiringEffects()
	function checkEffectExpire(nodeEffect)
		local sLabel = DB.getValue(nodeEffect, "label", "");
		local nDuration = DB.getValue(nodeEffect, "duration", 0);
		local sApply = DB.getValue(nodeEffect, "apply", "");
		--local bLongTerm = (nDuration ~= 0);
    	local bExpiringSoon = (nDuration <= 10 and nDuration ~= 0);
    
		if bExpiringSoon or sApply ~= "" or sLabel == "" then
			nodeEffect.delete();
		end
	end
	CombatManager.callForEachCombatantEffect(checkEffectExpire);
end

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function resetInit()
	function resetCombatantInit(nodeCT)
		DB.setValue(nodeCT, "initresult", "number", 0);
		DB.setValue(nodeCT, "reaction", "number", 0);

		--set not rolled initiative portrait icon to active on new round
		CharlistManagerADND.turnOffInitRolled(nodeCT);
	end
	CombatManager.callForEachCombatant(resetCombatantInit);
end
-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function rollInit(sType)
	CombatManager.rollTypeInit(sType, rollEntryInit);
end
function rollRandomInit(nMod, bADV)
	local nInitResult = math.random(DataCommonADND.nDefaultInitiativeDice);
	if bADV then
		nInitResult = math.max(nInitResult, math.random(DataCommonADND.nDefaultInitiativeDice));
	end
	nInitResult = nInitResult + nMod;
	return nInitResult;
end
function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end

  	local bOptPCVNPCINIT = (OptionsManager.getOption("PCVNPCINIT") == 'on');
	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	-- Get any effect modifiers
	local rActor = ActorManager.resolveActor(nodeEntry);
	local aEffectDice, nEffectBonus = EffectManager5E.getEffectsBonus(rActor, "INIT");
	local nInitMOD = StringManager.evalDice(aEffectDice, nEffectBonus);
	
	-- Check for the ADVINIT effect
	local bADV = EffectManager5E.hasEffectCondition(rActor, "ADVINIT");

	-- For PCs, we always roll unique initiative
	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	if sClass == "charsheet" then
    local nodeChar = DB.findNode(sRecord);
    local nInitPC = DB.getValue(nodeChar,"initiative.total",0);
    local nInitResult = 0;
    if bOptPCVNPCINIT then
      if PC_LASTINIT == 0 then
        nInitResult = rollRandomInit(0, bADV);

        -- this is to make sure we dont have same initiative
        -- give the benefit to players.
        if nInitResult == NPC_LASTINIT then
          nInitResult = NPC_LASTINIT - 1;
        end

        PC_LASTINIT = nInitResult;
      else
        nInitResult = PC_LASTINIT;
      end
    else
      nInitResult = rollRandomInit(nInitPC + nInitMOD, bADV);
    end
    
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	else -- it's an npc
    --[[ We're using PC versus NPC initiative. So both sides roll once w/o modifiers ]]
    if bOptPCVNPCINIT then
      -- we capture these values to compare against friends and put them in "PC" group
      local nodeNPC = DB.findNode(sRecord);
      local bIsFriend = (DB.getValue(nodeNPC,"friendfoe","foe") == "friend");

      local nInitResult = 0;
      if NPC_LASTINIT == 0 or (bIsFriend and PC_LASTINIT == 0) then
        nInitResult = rollRandomInit(0, bADV);
        if (bIsFriend) then
          PC_LASTINIT = nInitResult;
        else
          -- this is to make sure we dont have same initiative
          -- give the benefit to players.
          if nInitResult == PC_LASTINIT then
            nInitResult = PC_LASTINIT + 1;
          end

          NPC_LASTINIT = nInitResult;
        end
      else
        if (bIsFriend) then
          nInitResult = PC_LASTINIT;
        else
          nInitResult = NPC_LASTINIT;
        end
      end
      DB.setValue(nodeEntry, "initresult", "number", nInitResult);
      return;
    end

    -- for npcs we allow them to have custom initiative. Check for it 
    -- and set nInit.
    local nTotal = DB.getValue(nodeEntry,"initiative.total",0);
    -- flip through weaponlist, get the largest speedfactor as default
    local nSpeedFactor = 0;
    for _,nodeWeapon in pairs(DB.getChildren(nodeEntry, "weaponlist")) do
      local nSpeed = DB.getValue(nodeWeapon,"speedfactor",0);
      if nSpeed > nSpeedFactor then
        nSpeedFactor = nSpeed;
      end
    end
    if nSpeedFactor ~= 0 then
      nInit = nSpeedFactor + nInitMOD ;
    elseif (nTotal ~= 0) then 
      nInit = nTotal + nInitMOD ;
    end

    --[[ IF we ignore size/mods, clear nInit ]]
    if OptionsManager.getOption("OPTIONAL_INIT_SIZEMODS") ~= "on" then
      nInit = 0;
    end
    -- For NPCs, if NPC init option is not group, then roll unique initiative
    local sOptINIT = OptionsManager.getOption("INIT");
    if sOptINIT ~= "group" then
      -- if they have custom init then we use it.
      local nInitResult = rollRandomInit(nInit, bADV);
      DB.setValue(nodeEntry, "initresult", "number", nInitResult);
      return;
    end

    -- For NPCs with group option enabled
    -- Get the entry's database node name and creature name
    local sStripName = CombatManager.stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
    if sStripName == "" then
      local nInitResult = rollRandomInit(nInit, bADV);
      DB.setValue(nodeEntry, "initresult", "number", nInitResult);
      return;
    end
      
    -- Iterate through list looking for other creature's with same name and faction
    local nLastInit = nil;
    local sEntryFaction = DB.getValue(nodeEntry, "friendfoe", "");
    for _,v in pairs(CombatManager.getCombatantNodes()) do
      if v.getName() ~= nodeEntry.getName() then
        if DB.getValue(v, "friendfoe", "") == sEntryFaction then
          local sTemp = CombatManager.stripCreatureNumber(DB.getValue(v, "name", ""));
          if sTemp == sStripName then
            local nChildInit = DB.getValue(v, "initresult", 0);
            if nChildInit ~= -10000 then
              nLastInit = nChildInit;
            end
          end
        end
      end
    end
    -- If we found similar creatures, then match the initiative of the last one found
    if nLastInit then
      DB.setValue(nodeEntry, "initresult", "number", nLastInit);
    else
      local nInitResult = rollRandomInit(nInit, bADV);
      DB.setValue(nodeEntry, "initresult", "number", nInitResult);
    end
  end
end

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function resetHealth(nodeCT, bLong)
	if bLong then
		DB.setValue(nodeCT, "wounds", "number", 0);
		DB.setValue(nodeCT, "hptemp", "number", 0);
		DB.setValue(nodeCT, "deathsavesuccess", "number", 0);
		DB.setValue(nodeCT, "deathsavefail", "number", 0);
		
		EffectManager.removeEffect(nodeCT, "Stable");
		
		local nExhaustMod = EffectManager5E.getEffectsBonus(ActorManager.resolveActor( nodeCT), {"EXHAUSTION"}, true);
		if nExhaustMod > 0 then
			nExhaustMod = nExhaustMod - 1;
			EffectManager5E.removeEffectByType(nodeCT, "EXHAUSTION");
			if nExhaustMod > 0 then
				EffectManager.addEffect("", "", nodeCT, { sName = "EXHAUSTION: " .. nExhaustMod, nDuration = 0 }, false);
			end
		end
	end
end
-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function rest(bLong)
	CombatManager.resetInit();
	CombatManagerADND.clearExpiringEffects();

	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local bHandled = false;
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sClass == "charsheet" and sRecord ~= "" then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				CharManager.rest(nodePC, bLong);
				bHandled = true;
			end
		end
		
		if not bHandled then
			CombatManagerADND.resetHealth(v, bLong);
		end
	end
end

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function onRoundStart(nCurrent)
	PC_LASTINIT = 0;
	NPC_LASTINIT = 0;

	if OptionsManager.isOption("HouseRule_InitEachRound", "on") then
		CombatManagerADND.rollInit();
	end

	-- toggle portrait initiative icon
	CharlistManagerADND.turnOffAllInitRolled();
	-- toggle all "initrun" values to not run
	CharlistManagerADND.turnOffAllInitRun();
end
-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function onTurnStart(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "reaction", "number", 0);
	
	-- Check for death saves (based on option)
	if OptionsManager.isOption("HRST", "on") then
		if nodeEntry then
			local sClass, sRecord = DB.getValue(nodeEntry, "link");
			if sClass == "charsheet" and sRecord then
				local nHP = DB.getValue(nodeEntry, "hptotal", 0);
				local nWounds = DB.getValue(nodeEntry, "wounds", 0);
				local nDeathSaveFail = DB.getValue(nodeEntry, "deathsavefail", 0);
				if (nHP > 0) and (nWounds >= nHP) and (nDeathSaveFail < 3) then
					local rActor = ActorManager.resolveActor( sRecord);
					if not EffectManager5E.hasEffect(rActor, "Stable") then
						ActionSave.performDeathRoll(nil, rActor, true);
					end
				end
			end
		end
	end
end

--
--	Initiative indicator functions
--

-- create the "has initiative" indicator widget
function createHasInitiativeWidget(tokenCT,nodeCT)
  -- this is 1-4
  local sOptHasInitToken = OptionsManager.getOption("TOKEN_OPTION_INIT");
  local sInitiativeIconName = "token_has_initiative";
  if sOptHasInitToken then
    sInitiativeIconName = sInitiativeIconName .. sOptHasInitToken;
  else
    sInitiativeIconName = sInitiativeIconName .. "1";
  end

  local nWidth, nHeight = tokenCT.getSize();
  --local nScale = tokenCT.getScale();
  local sName = DB.getValue(nodeCT,"name","Unknown");
  local sNONID_Name = DB.getValue(nodeCT,"nonid_name","NONID-NA");
  local bNPC_ID = LibraryData.getIDState("npc", nodeCT, true);
  -- make sure we only show the ID'd name if the creature is "ID'd". -- celestian
  if not ActorManager.isPC(nodeCT) then
    if not bNPC_ID then
      sName = sNONID_Name;
    end
  end

  local widgetInitIndicator = tokenCT.addBitmapWidget(sInitiativeIconName);
  widgetInitIndicator.setBitmap(sInitiativeIconName);
  widgetInitIndicator.setName("initiativeindicator");
  --widgetInitIndicator.setTooltipText(sName .. " has initiative.");
  --widgetInitIndicator.setPosition("top", 0, 0);
  widgetInitIndicator.setPosition("center", 0, 0);

    --widgetInitIndicator.setEnabled(false);
  widgetInitIndicator.setEnabled(false);
  local nDU = GameSystem.getDistanceUnitsPerGrid();
  local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU)*100;
  local nSizeValue = nSpace+math.ceil(nSpace*.1);
  widgetInitIndicator.setSize(nSizeValue,nSizeValue); -- 110% size (slightly bigger than token)

  return widgetInitIndicator;
end
-- get widget-
function getHasInitiativeWidget(nodeCT)
--UtilityManagerADND.logDebug("manager_combat_adnd","getHasInitiativeWidget","nodeField",nodeField);     
  local widgetInitIndicator = nil;
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  if (tokenCT) then
    widgetInitIndicator = tokenCT.findWidget("initiativeindicator");
  end
  return widgetInitIndicator;
end
-- show/hide widget
function setHasInitiativeIndicator(nodeCT,bShowINIT)
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  if tokenCT then
    local widgetInitIndicator = getHasInitiativeWidget(nodeCT);
    if widgetInitIndicator and bShowINIT then -- show existing widget
      widgetInitIndicator.setVisible(bShowINIT);
    elseif not widgetInitIndicator and bShowINIT then -- create widget, show
      widgetInitIndicator = createHasInitiativeWidget(tokenCT,nodeCT);
      widgetInitIndicator.setVisible(bShowINIT);
    elseif widgetInitIndicator and not bShowINIT then -- destroy widget, not needed
      widgetInitIndicator.destroy();
    end
  else
  --UtilityManagerADND.logDebug("manager_combat_adnd.lua","setHasInitiativeIndicator","nodeCT",nodeCT);  
  --UtilityManagerADND.logDebug("manager_combat_adnd.lua","setHasInitiativeIndicator","tokenCT",tokenCT);  
  end
end
-- update the display "token" for has initiative indicator
function initiativeTokenChanged()
  -- delete any initiative widgets.
  for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
    local tokenCT = CombatManager.getTokenFromCT(nodeCT);
    if tokenCT then
      local widgetInitIndicator = getHasInitiativeWidget(nodeCT);
      if widgetInitIndicator then
        widgetInitIndicator.destroy();
      end
    end
  end
  -- set widget for active token
  updateAllInititiativeIndicators();
end
-- update has initiative first time start up
function updateAllInititiativeIndicators()
  for _,vChild in pairs(CombatManager.getCombatantNodes()) do
    local bActive = (DB.getValue(vChild,"active",0) == 1);
    setHasInitiativeIndicator(vChild,bActive);
  end
  --shuffleActiveTokenToTop();
end
-- update has initiative first time start up
function updateInititiativeIndicator(nodeField)
  local nodeCT = nodeField.getParent();
  local bActive = (DB.getValue(nodeCT,"active",0) == 1);
  setHasInitiativeIndicator(nodeCT,bActive);
  --shuffleActiveTokenToTop();
end

-- make sure the token SELECTABLE on top of the pile when it gains initiative
-- this also pops up the image at startup if it's not currently visible.
-- visually in FGC it's on the bottom, tooltip and click to move will show proper one
-- function shuffleActiveTokenToTop()
  -- local nodeCT = CombatManager.getActiveCT();
  -- if nodeCT then
    -- local tokenCT = CombatManager.getTokenFromCT(nodeCT);
    -- if tokenCT then
      -- TokenManagerADND.selectTokenInPile(tokenCT);
    -- end
  -- end
-- end

--
--	AD&D Style ordering (low to high initiative)
--

function sortfuncADnD(node2, node1)
  local bHost = Session.IsHost;
  local sOptCTSI = OptionsManager.getOption("CTSI");
  
  local sFaction1 = DB.getValue(node1, "friendfoe", "");
  local sFaction2 = DB.getValue(node2, "friendfoe", "");
  
  local bShowInit1 = bHost or ((sOptCTSI == "friend") and (sFaction1 == "friend")) or (sOptCTSI == "on");
  local bShowInit2 = bHost or ((sOptCTSI == "friend") and (sFaction2 == "friend")) or (sOptCTSI == "on");
  
  if bShowInit1 ~= bShowInit2 then
    if bShowInit1 then
      return true;
    elseif bShowInit2 then
      return false;
    end
  else
    if bShowInit1 then
      local nValue1 = DB.getValue(node1, "initresult", 0);
      local nValue2 = DB.getValue(node2, "initresult", 0);
      if nValue1 ~= nValue2 then
        return nValue1 > nValue2;
      end
      
      nValue1 = DB.getValue(node1, "init", 0);
      nValue2 = DB.getValue(node2, "init", 0);
      if nValue1 ~= nValue2 then
        return nValue1 > nValue2;
      end
    else
      if sFaction1 ~= sFaction2 then
        if sFaction1 == "friend" then
          return true;
        elseif sFaction2 == "friend" then
          return false;
        end
      end
    end
  end
  
  local sValue1 = DB.getValue(node1, "name", "");
  local sValue2 = DB.getValue(node2, "name", "");
  if sValue1 ~= sValue2 then
    return sValue1 < sValue2;
  end

  return node1.getNodeName() < node2.getNodeName();
end

--
--	General functions
--

-- return boolean, is PC from CT node test
function isCTNodePC(nodeCT)
  local isPC = false;
  local sClassLink, sRecordLink = DB.getValue(nodeCT,"link","","");
  if sClassLink == 'charsheet' then
    isPC = true;
  end
  return isPC;
end
-- return boolean, is NPC from CT node test
function isCTNodeNPC(nodeCT)
  local isNPC = false;
  local sClassLink, sRecordLink = DB.getValue(nodeCT,"link","","");
  if sClassLink == 'npc' then
    isNPC = true;
  end
  return isNPC;
end
-- return the full "sheet" node from a combattracker node.
function getNodeFromCT(nodeCT)
  local nodeChar = nil;
  if type(nodeCT) == "string" then
    nodeCT = DB.findNode(nodeCT);
  end
  local sClass, sRecord = DB.getValue(nodeCT,"link","","");
  if sClass and sRecord then
    if (sClass == 'charsheet' or sClass == 'npc') and DB.findNode(sRecord) then
      nodeChar = DB.findNode(sRecord);
    end
  end
  return nodeChar;
end

--
--	NPC functions
--

-- calculate npc level from HD and return it -celestian
-- move to manager_action_save.lua?
function getNPCLevelFromHitDice(sHitDice,nodeNPC) 
    local nLevel = 1;
    local nHitDice = 0;
    --local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    if (sHitDice) then
      -- UtilityManagerADND.logDebug("","getNPCLevelFromHitDice","sHitDice",sHitDice)
        -- Match #-#, #+# or just #
        -- (\d+)([\-\+])?(\d+)?
        -- Full match  0-4  `12+3`
        -- Group 1.  0-2  `12`
        -- Group 2.  2-3  `+`
        -- Group 3.  3-4  `3`
        local nAdjustment = 0;
        local match1, match2, match3 = sHitDice:match("(%d+)([%-+])(%d+)");
        
        -- UtilityManagerADND.logDebug("","getNPCLevelFromHitDice","match1",match1)
        -- UtilityManagerADND.logDebug("","getNPCLevelFromHitDice","match2",match2)
        -- UtilityManagerADND.logDebug("","getNPCLevelFromHitDice","match3",match3)

        if (match1 and not match2) then -- single digit
            nHitDice = tonumber(match1);
        elseif (match1 and match2 and match3) then -- match x-x or x+x
            nHitDice = tonumber(match1);
            -- minus
            if (match2 == "-") then
                nAdjustment = tonumber(match2 .. match3);
            else -- plus
                nAdjustment = tonumber(match3);
            end
            if (nAdjustment ~= 0) then
                local nFourCount = (nAdjustment/4);
                if (nFourCount < 0) then
                    nFourCount = math.ceil(nFourCount);
                else
                    nFourCount = math.floor(nFourCount);
                end
                nLevel = (nHitDice+nFourCount);
            else -- adjust = 0
                nLevel = nHitDice;
            end -- nAdjustment
        else -- didn't find X-X or X+x-x
            match1 = sHitDice:match("(%d+)");
            if (match1) then -- single digit
                nHitDice = tonumber(match1);
                nLevel = nHitDice;
            else
                -- pop up menu and ask them for a decent value? -celestian
                if nodeNPC then
                  UtilityManagerADND.logDebug("Unable to find a working hitDice [" .. sHitDice .. "] for " .. DB.getValue(nodeNPC, "name", "<no-name>") .." to calculate saves. It should be # or #+# or #-#."); 
                else
                  ChatManager.SystemMessage("Invalid hitDice [" .. sHitDice .. "]"); 
                end
                nAdjustment = 0;
                nHitDice = 0;
            end
        end
    end -- hitDice
    
    return nLevel;
end

-- get NPC HitDice for use on Matrix chart.
-- Smaller than 1-1 (-1)
-- 1-1
-- 1
-- 1+
-- ...
-- 16+
function getNPCHitDice(nodeNPC)
--UtilityManagerADND.logDebug("manager_combat_adnd","getNPCHitDice","nodeNPC",nodeNPC);  
  local sSantizedHitDice = "-1";
  local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
  local s1, s2, s3 = sHitDice:match("(%d+)([%-+])(%d+)");
  if s1 and s2 and s3 then
    -- deal with 1+,1-2,1-1
    if s1 == "1" then
      if s2 == "+" then
        sSantizedHitDice = "1+";
      elseif (s2 == "-") and ((tonumber(s3) or 0) < 1) then -- if 1-X and X > 1
        sSantizedHitDice = "-1";
      else
        sSantizedHitDice = "1-1";
      end
    else
      local nHD = tonumber(s1) or 16;
      if nHD > 16 then
        sSantizedHitDice = "16";
      else
        sSantizedHitDice = s1;
      end
    end
  elseif s1 then
    sSantizedHitDice = s1;
  else -- no string matched
    sSantizedHitDice = sHitDice:match("(%d+)");
  end
  
--UtilityManagerADND.logDebug("manager_combat_adnd","getNPCHitDice","sSantizedHitDice",sSantizedHitDice);  
  return sSantizedHitDice;
end

-- return the Best ac hit from a roll for this NPC
function getACHitFromMatrixForNPC(nodeNPC,nRoll)
  local nACHit = 20;
  local sHitDice = getNPCHitDice(nodeNPC);
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForNPC","DataCommonADND.aMatrix",DataCommonADND.aMatrix);         
  if DataCommonADND.aMatrix[sHitDice] then
    local aMatrixRolls = DataCommonADND.aMatrix[sHitDice];
-- UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForNPC","DataCommonADND.aMatrix[sHitDice]",DataCommonADND.aMatrix[sHitDice]);         
-- UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForNPC","aMatrixRolls",aMatrixRolls);         
--    for i=21,1,-1 do
-- use #aMatrixRolls for counter instead. This should get the number from the array instead of hardcoded
-- did this so that could use same code for 1e and becmi since becmi uses 19 to -10 and 1e uses 10 to -10
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForNPC","#aMatrixRolls",#aMatrixRolls);
    local nACBase = 11;
    if (DataCommonADND.coreVersion == "becmi") then 
      nACBase = 20;
    end
    for i=#aMatrixRolls,1,-1 do
      local sCurrentTHAC = "thac" .. i;
      local nAC = nACBase - i;
      local nCurrentTHAC = aMatrixRolls[i];
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForNPC","nCurrentTHAC",nCurrentTHAC);        
      --if nCurrentTHAC == nRoll then
      if nRoll >= nCurrentTHAC then
        -- find first AC that matches our roll
        nACHit = nAC;
        break;
      end
    end
    
  end
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForNPC","nACHit",nACHit);    
  return nACHit;
end

-- return the Best ac hit from a roll for PC
function getACHitFromMatrixForPC(nodePC,nRoll)
  local nACHit = 20;
  local nodeCombat = nodePC.createChild("combat"); -- make sure these exist
  local nodeMATRIX = nodeCombat.createChild("matrix"); -- make sure these exist
  
  -- default value is 1e.
  local nLowAC = -10;
  local nHighAC = 10;
  local nTotalACs = 11;
  
  if (DataCommonADND.coreVersion == "becmi") then
    nLowAC = -20;
    nHighAC = 19;
    nTotalACs = 20;
  end
  
  -- starting from AC -10 and work up till we find match to our nRoll
  for i=nLowAC,nHighAC,1 do
    local sCurrentTHAC = "thac" .. i;
    local nAC = i;
    local nCurrentTHAC = DB.getValue(nodeMATRIX,sCurrentTHAC, 100);
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForPC","nCurrentTHAC",nCurrentTHAC);      
    if nRoll >= nCurrentTHAC then
      -- find first AC that matches our roll
      nACHit = i;
      break;
    end
  end
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrixForPC","nACHit",nACHit);        
  return nACHit;
end

-- return best AC Hit for this node (pc/npc) from Matrix with this nRoll
function getACHitFromMatrix(node,nRoll)
  local nACHit = 20;
  -- get the link from the combattracker record to see what this is.
	local bisPC = (node.getPath():match("^charsheet%."));
  if (bisPC) then
    nACHit = getACHitFromMatrixForPC(node,nRoll);
  else
    -- NPCs get this from matrix for HD value
    nACHit = getACHitFromMatrixForNPC(node,nRoll);
  end
  
--UtilityManagerADND.logDebug("manager_combat_adnd","getACHitFromMatrix","nACHit",nACHit);        
  return nACHit;
end

-- Set NPC Saves -celestian
-- move to manager_action_save.lua?
function updateNPCSaves(nodeEntry, nodeNPC, bForceUpdate)
--    UtilityManagerADND.logDebug("manager_combat2.lua","updateNPCSaves","nodeNPC",nodeNPC);
    if  (bForceUpdate) or (DB.getChildCount(nodeNPC, "saves") <= 0) then
        for i=1,10,1 do
            local sSave = DataCommon.saves[i];
            local nSave = DB.getValue(nodeNPC, "saves." .. sSave .. ".score", -1);
            if (nSave <= 0 or bForceUpdate) then
                ActionSave.setNPCSave(nodeEntry, sSave, nodeNPC)
            end
        end
    end
end
-- set Level, Arcane/Divine levels based on HD "level"
function updateNPCLevels(nodeNPC, bForceUpdate) 
    if  (bForceUpdate) then
      local nLevel = getNPCLevelFromHitDice(DB.getValue(nodeNPC,"hitDice","1"),nodeNPC);
      DB.setValue(nodeNPC, "arcane.totalLevel","number",nLevel);
      DB.setValue(nodeNPC, "divine.totalLevel","number",nLevel);
      DB.setValue(nodeNPC, "psionic.totalLevel","number",nLevel);
      DB.setValue(nodeNPC, "level","number",nLevel);
    end
end

--
-- CoreRPG replaced functions for customizations
--

-- replace default roll with adnd_roll to allow
-- control-dice click to prompt for manual roll
function adnd_roll(rSource, vTargets, rRoll, bMultiTarget)
	if ActionsManager.doesRollHaveDice(rRoll) then
		DiceManager.onPreEncodeRoll(rRoll);
	
		if not rRoll.bTower and (OptionsManager.isOption("MANUALROLL", "on") or (Session.IsHost and Input.isControlPressed())) then
			ManualRollManager.addRoll(rRoll, rSource, vTargets);
		else
			local rThrow = ActionsManager.buildThrow(rSource, vTargets, rRoll, bMultiTarget);
			Comm.throwDice(rThrow);
		end
	else
		if bMultiTarget then
			ActionsManager.handleResolution(rRoll, rSource, vTargets);
		else
			ActionsManager.handleResolution(rRoll, rSource, { vTargets });
		end
	end
end   

--
--	Helper functions
--

--[[
  Add spells in list "fireball;light;hold person" or using specific type "divine;hold person;cure light wounds;arcane;light;fireball"
  to nodeEntry in "powers"
]]
function addSpellsFromList(nodeEntry,aSpells)
  -- UtilityManagerADND.logDebug("manager_combat_adnd.lua","addSpellsFromList","nodeEntry",nodeEntry);  
  -- UtilityManagerADND.logDebug("manager_combat_adnd.lua","addSpellsFromList","sSpellsList",sSpellsList);
  if aSpells and #aSpells > 0 then
    local sType = '';
    for _, sSpell in pairs(aSpells) do
      -- UtilityManagerADND.logDebug("manager_combat_adnd.lua","addSpellsFromList","sSpell",sSpell);
      -- if spelltype in list then we switch sType to that
      if (sSpell:lower() == 'arcane' or sSpell:lower() == 'divine') then
        sType = sSpell;
      else
        local nodeSpell = ManagerImportADND.findSpell(sSpell,sType);
        if (nodeSpell) then
          ManagerImportADND.addSpell(nodeEntry,nodeSpell)
        else
          ChatManager.SystemMessage("addSpellsFromList: Could not find spell [" .. sSpell .. "] in spell records to add to NPC.");
        end
      end
    end -- aSpells
  end
end

function isWeaponProfApplied(nodeWeapon,sProfName)
  local bSelected = false;
  for _,nodeAppliedProf in pairs(DB.getChildren(nodeWeapon, "proflist")) do
    local sName = DB.getValue(nodeAppliedProf,"prof","");
    if sName == sProfName then
      bSelected = true;
      break;
    end
  end
  return bSelected;
end
-- find a weapon prof by name on nodeChar
function getWeaponProfNodeByName(nodeChar,sProfName)
  local nodeProf = nil;
  for _,node in pairs(DB.getChildren(nodeChar, "proficiencylist")) do
    local sName = DB.getValue(node,"name","");
    if sName == sProfName then
      nodeProf = node;
      break;
    end
  end
  return nodeProf;
end

-- apply/remove weapon prof from a weapon
function setWeaponProfApplication(nodeWeapon, sProfName, bApplied)
  if not sProfName or sProfName == '' then
    return nil;
  end
  local nodeRemove = nil;
  for _,nodeAppliedProf in pairs(DB.getChildren(nodeWeapon, "proflist")) do
    local sName = DB.getValue(nodeAppliedProf,"prof","");
    if sName == sProfName then
      nodeRemove = nodeAppliedProf;
      break;
    end
  end
  if nodeRemove and not bApplied then
    nodeRemove.delete();
  end
  if not nodeRemove and bApplied then
    local nodeProfList = DB.createChild(nodeWeapon,"proflist");
    local nodeNewProf = nodeProfList.createChild();
    DB.setValue(nodeNewProf,"prof","string",sProfName);
  end
end

-- make sure that we do not already have a prof selected for this 
function weaponProfExists(nodeWeapon,sProf)
  local bExists = false;
  
  for _,nodeProfs in pairs(DB.getChildren(nodeWeapon, "proflist")) do
    local sProfSelected = DB.getValue(nodeProfs,"prof","");
    if (sProf == sProfSelected) then
      bExists = true;
      break;
    end
  end
  
  return bExists;
end    

-- chat function to send message related to CT actions
function showCTMessageADND(nodeEntry,sChatText)
    --local sName = ActorManager.getDisplayName(nodeEntry);
    local bHidden = CombatManager.isCTHidden(nodeEntry);
    local bPC = ActorManager.isPC(ActorManager.resolveActor(nodeEntry));
    
    local msgDM = {font = "narratorfont", icon = "turn_flag"};
    local msgPlayer = {font = "narratorfont", icon = "turn_flag"};
    msgDM.text = sChatText;
    msgPlayer.text = sChatText;
    if bHidden or not bPC then
      msgDM.secret = true;
      Comm.addChatMessage(msgDM);
    end
    
    --if bPC and not bHidden then
    if not bHidden then
      Comm.deliverChatMessage(msgPlayer);
    end
end

-- return the initiative value of the last entry with initiative.
function getLastInitiative()
  local nLastInit = -100;
  for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
    local nInit = DB.getValue(nodeCT,"initresult",0);
    if nInit > nLastInit then
      nLastInit = nInit;
    end
  end
  return nLastInit;
end

--[[
  Push current player initiative to end of round
]]
function delayTurn(nodeCT)
  if nodeCT then
      local nLastInit = CombatManagerADND.getLastInitiative();
      CombatManagerADND.showCTMessageADND(nodeEntry,DB.getValue(nodeCT,"name","") .. " " .. Interface.getString("char_initdelay_message"));
      CombatManager.nextActor();
      -- this has to go last!
      DB.setValue(nodeCT,"initresult","number",nLastInit + 1);
  end
end

--[[
  This builds a cache array that is updated when ctnodes are added or removed or the ct.visible changes
]]
-- aCTFilteredEntries = {};
-- function buildCombatantNodesCache()
-- -- UtilityManagerADND.logDebug("manager_combat_adnd","buildCombatantNodesCache");
-- local aCTUnfilteredEntries = DB.getChildren("combattracker.list");
--   -- local aCTFilteredEntries = {};
--   aCTFilteredEntries = {};
--   for _,node in pairs(aCTUnfilteredEntries) do
--     local bCTVisible = (DB.getValue(node,"ct.visible",1) == 1);
--     if bCTVisible then
--       table.insert(aCTFilteredEntries,node);
--     end
--   end
-- end

--[[
  Get a list of combatants from the CT that are supposed to be visible in the CT
  (and don't get the ones not flagged as in the CT)

  This does not work from client side. Have to figure out a way to run this as host
  
]]
-- function getCombatantNodes_adnd(bForce)
--   if (not aCTFilteredEntries or bForce) then
--     aCTFilteredEntries = buildCombatantNodesCache();
--   elseif (not disableCombatantsCache) then
--     checkForIntegrity();
--   end
--   return aCTFilteredEntries;
-- end
-- [[ original ]]
-- function getCombatantNodes_adnd()
--   local aCTUnfilteredEntries = DB.getChildren("combattracker.list");
--   aCTFilteredEntries = {};
--   for _,node in pairs(aCTUnfilteredEntries) do
--     local bCTVisible = (DB.getValue(node,"ct.visible",1) == 1);
--     if bCTVisible then
--       table.insert(aCTFilteredEntries,node);
--     end
--   end
--   return aCTFilteredEntries;
-- end
-- --[[ 
--   Make sure the cache is good 
-- ]]
-- function checkForIntegrity() 
--   for _,node in pairs(aCTFilteredEntries) do
--     -- if "type" doesnt come back as databasenode and instead "error", the node was deleted and we rebuild
--     if (type(node) ~= 'databasenode') then
--       --UtilityManagerADND.logDebug("manager_combat_adnd","checkCombatantNodesCacheForIntegrity","typeof node",type(node))
--       UtilityManagerADND.logDebug("manager_combat_adnd","checkForIntegrity","rebuilding cache due to integrity.");
--       buildCombatantNodesCache();
--       break;
--     end
--   end
-- end

--[[
	At some point we need to get ALL the tokens, not just the tokens
	marked as active. This function will get unfiltered list of all the 
	tokens in the same imageControl as this token
]]--
-- function getCTFromTokenUnfiltered(token)
-- 	if not token then
-- 		return nil;
-- 	end
	
-- 	local nodeContainer = token.getContainerNode();
-- 	local nID = token.getId();

-- 	return getCTFromTokenRefUnfiltered(nodeContainer, nID);
-- end
-- function getCTFromTokenRefUnfiltered(vContainer, nId)
-- 	local sContainerNode = nil;
-- 	if type(vContainer) == "string" then
-- 		sContainerNode = vContainer;
-- 	elseif type(vContainer) == "databasenode" then
-- 		sContainerNode = vContainer.getNodeName();
-- 	else
-- 		return nil;
-- 	end
	
-- 	for _,v in pairs(DB.getChildren("combattracker.list")) do
-- 		local sCTContainerName = DB.getValue(v, "tokenrefnode", "");
-- 		local nCTId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
-- 		if (sCTContainerName == sContainerNode) and (nCTId == nId) then
-- 			return v;
-- 		end
-- 	end
	
-- 	return nil;
-- end

--[[
  Get list of active combatant windows for various locations
]]
-- function getCombatantWindows(aWindowList)
--     local aCTFilteredEntries = {};
  
--     for _,windowControl in pairs(aWindowList) do
--       local node = windowControl.getDatabaseNode();
--       if node then
--         local bCTVisible = (DB.getValue(node,"ct.visible",1) == 1);
--         if bCTVisible then
--           --local nodeToken = CombatManager.getTokenFromCT(node);
--           --local imageControl = ImageManager.getImageControl(nodeToken, true);
--           table.insert(aCTFilteredEntries,windowControl);
--         end
--       end
--     end
  
--   return aCTFilteredEntries;
-- end

--
--	XP FUNCTIONS
--

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function calcBattleXP(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	local nXP = 0;
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if nodeNPC then
				nXP = nXP + (DB.getValue(vNPCItem, "count", 0) * DB.getValue(nodeNPC, "xp", 0));
			else
				local sMsg = string.format(Interface.getString("enc_message_refreshxp_missingnpclink"), DB.getValue(vNPCItem, "name", ""));
				ChatManager.SystemMessage(sMsg);
			end
		end
	end
	
	DB.setValue(nodeBattle, "exp", "number", nXP);
end
	
-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function calcBattleCR(nodeBattle)
	calcBattleXP(nodeBattle);

	local nXP = DB.getValue(nodeBattle, "exp", 0);

	local sCR = "";
	if nXP > 0 then
		if nXP <= 10 then
			sCR = "0";
		elseif nXP <= 25 then
			sCR = "1/8";
		elseif nXP <= 50 then
			sCR = "1/4";
		elseif nXP <= 100 then
			sCR = "1/2";
		elseif nXP <= 200 then
			sCR = "1";
		elseif nXP <= 450 then
			sCR = "2";
		elseif nXP <= 700 then
			sCR = "3";
		elseif nXP <= 1100 then
			sCR = "4";
		elseif nXP <= 1800 then
			sCR = "5";
		elseif nXP <= 2300 then
			sCR = "6";
		elseif nXP <= 2900 then
			sCR = "7";
		elseif nXP <= 3900 then
			sCR = "8";
		elseif nXP <= 5000 then
			sCR = "9";
		elseif nXP <= 5900 then
			sCR = "10";
		elseif nXP <= 7200 then
			sCR = "11";
		elseif nXP <= 8400 then
			sCR = "12";
		elseif nXP <= 10000 then
			sCR = "13";
		elseif nXP <= 11500 then
			sCR = "14";
		elseif nXP <= 13000 then
			sCR = "15";
		elseif nXP <= 15000 then
			sCR = "16";
		elseif nXP <= 18000 then
			sCR = "17";
		elseif nXP <= 20000 then
			sCR = "18";
		elseif nXP <= 22000 then
			sCR = "19";
		elseif nXP <= 25000 then
			sCR = "20";
		elseif nXP <= 33000 then
			sCR = "21";
		elseif nXP <= 41000 then
			sCR = "22";
		elseif nXP <= 50000 then
			sCR = "23";
		elseif nXP <= 62000 then
			sCR = "24";
		elseif nXP <= 75000 then
			sCR = "25";
		elseif nXP <= 90000 then
			sCR = "26";
		elseif nXP <= 105000 then
			sCR = "27";
		elseif nXP <= 120000 then
			sCR = "28";
		elseif nXP <= 135000 then
			sCR = "29";
		elseif nXP <= 155000 then
			sCR = "30";
		else
			sCR = "31+";
		end
	end

	DB.setValue(nodeBattle, "cr", "string", sCR);
end

--
--	COMBAT ACTION FUNCTIONS
--

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function addRightClickDiceToClauses(rRoll)
	if #rRoll.clauses > 0 then
		local nOrigDamageDice = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nOrigDamageDice = nOrigDamageDice + #vClause.dice;
		end
		if #rRoll.aDice > nOrigDamageDice then
			local v = rRoll.clauses[#rRoll.clauses].dice;
			for i = nOrigDamageDice + 1,#rRoll.aDice do
				if type(rRoll.aDice[i]) == "table" then
					table.insert(rRoll.clauses[1].dice, rRoll.aDice[i].type);
				else
					table.insert(rRoll.clauses[1].dice, rRoll.aDice[i]);
				end
			end
		end
	end
end

--
-- PARSE CT ATTACK LINE
--

-- JPG - 2022-09-25 - Migrated CombatManager2 to CombatManagerADND
function parseAttackLine(sLine)
	local rPower = nil;
	
	local nIntroStart, nIntroEnd, sName = sLine:find("([^%[]*)[%[]?");
	if nIntroStart then
		rPower = {};
		rPower.name = StringManager.trim(sName);
		rPower.aAbilities = {};

		nIndex = nIntroEnd;
		local nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nIntroEnd);
		while nAbilityStart do
			if sAbility == "M" or sAbility == "R" then
				rPower.range = sAbility;

			elseif sAbility:sub(1,4) == "ATK:" and #sAbility > 4 then
				local rAttack = {};
				rAttack.sType = "attack";
				rAttack.nStart = nAbilityStart + 1;
				rAttack.nEnd = nAbilityEnd;
				rAttack.label = rPower.name;
				rAttack.range = rPower.range;
				local sAttack, sCritRange = sAbility:sub(7):match("([+-]?%d+)%s*%((%d+)%)");
				if sAttack then
					rAttack.modifier = tonumber(sAttack) or 0;
					rAttack.nCritRange = tonumber(sCritRange) or 0;
					if rAttack.nCritRange < 2 or rAttack.nCritRange > 19 then
						rAttack.nCritRange = nil;
					end
				else
					rAttack.modifier = tonumber(sAbility:sub(5)) or 0;
				end
				table.insert(rPower.aAbilities, rAttack);

			elseif sAbility:sub(1,7) == "SAVEVS:" and #sAbility > 7 then
				local aWords = StringManager.parseWords(sAbility:sub(7));
				
				local rSave = {};
				rSave.sType = "powersave";
				rSave.nStart = nAbilityStart + 1;
				rSave.nEnd = nAbilityEnd;
				rSave.label = rPower.name;
				rSave.save = aWords[1];
				rSave.savemod = tonumber(aWords[2]) or 0;
				if StringManager.isWord(aWords[3], "H") then
					rSave.onmissdamage = "half";
				end
				if StringManager.isWord(aWords[3], "magic") or StringManager.isWord(aWords[4], "magic") then
					rSave.magic = true;
				end
				table.insert(rPower.aAbilities, rSave);

			elseif sAbility:sub(1,4) == "DMG:" and #sAbility > 4 then
				local rDamage = {};
				rDamage.sType = "damage";
				rDamage.nStart = nAbilityStart + 1;
				rDamage.nEnd = nAbilityEnd;
				rDamage.label = rPower.name;
				rDamage.range = rPower.range;
				rDamage.clauses = {};
				
				local aPowerWords = StringManager.parseWords(sAbility:sub(5));
				local i = 1;
				while aPowerWords[i] do
					if StringManager.isDiceString(aPowerWords[i]) then
						local aDmgDiceStr = {};
						table.insert(aDmgDiceStr, aPowerWords[i]);
						while StringManager.isDiceString(aPowerWords[i+1]) do
							table.insert(aDmgDiceStr, aPowerWords[i+1]);
							i = i + 1;
						end
						local aClause = {};
						aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aDmgDiceStr));
						
						local aDmgType = {};
						while aPowerWords[i+1] and not StringManager.isDiceString(aPowerWords[i+1]) and not StringManager.isWord(aPowerWords[i+1], {"and", "plus"}) do
							table.insert(aDmgType, aPowerWords[i+1]);
							i = i + 1;
						end
						aClause.dmgtype = table.concat(aDmgType, ",");
						
						table.insert(rDamage.clauses, aClause);
					end
					
					i = i + 1;
				end
				table.insert(rPower.aAbilities, rDamage);

			elseif sAbility:sub(1,5) == "HEAL:" and #sAbility > 5 then
				local rHeal = {};
				rHeal.sType = "heal";
				rHeal.nStart = nAbilityStart + 1;
				rHeal.nEnd = nAbilityEnd;
				rHeal.label = rPower.name;
				rHeal.clauses = {};

				local aPowerWords = StringManager.parseWords(sAbility:sub(6));
				local i = 1;
				local aHealDiceStr = {};
				while StringManager.isDiceString(aPowerWords[i]) do
					table.insert(aHealDiceStr, aPowerWords[i]);
					i = i + 1;
				end

				local aClause = {};
				aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aHealDiceStr));
				table.insert(rHeal.clauses, aClause);
				
				if StringManager.isWord(aPowerWords[i], "temp") then
					rHeal.subtype = "temp";
				end

				table.insert(rPower.aAbilities, rHeal);
				
			elseif sAbility:sub(1,4) == "EFF:" and #sAbility > 4 then
				local rEffect = EffectManager5E.decodeEffectFromCT(sAbility);
				if rEffect then
					rEffect.nStart = nAbilityStart + 1;
					rEffect.nEnd = nAbilityEnd;
					table.insert(rPower.aAbilities, rEffect);
				end
			
			elseif sAbility:sub(1,2) == "R:" and #sAbility == 3 then
				local rUsage = {};
				rUsage.sType = "usage";

				local nUsedStart, nUsedEnd, sUsage = string.find(sLine, "%[(USED)%]", nIndex);
				if nUsedStart then
					rUsage.nStart = nUsedStart + 1;
					rUsage.nEnd = nUsedEnd;
				else
					rUsage.nStart = nAbilityStart + 1;
					rUsage.nEnd = nAbilityEnd;
					sUsage = sAbility;
				end
				table.insert(rPower.aAbilities, rUsage);
				
				rPower.sUsage = sUsage;
				rPower.nUsageStart = rUsage.nStart;
				rPower.nUsageEnd = rUsage.nEnd;
			end
			
			nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nAbilityEnd + 1);
		end
	end
	
	return rPower;
end
