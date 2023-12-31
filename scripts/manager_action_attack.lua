-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

  ActionsManager.registerTargetingHandler("attack", onTargeting);
  ActionsManager.registerModHandler("attack", modAttack);
  ActionsManager.registerResultHandler("attack", onAttack);
  -- callback for mirror/stoneskins
  ActionsManager.registerResultHandler("roll_against_mirrorimages", againstMirrors);
end

function handleApplyAttack(msgOOB)
  local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
  local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
  applyAttack(rSource, rTarget, msgOOB);
end

function notifyApplyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, rResults)
  if not rTarget then
    return;
  end

  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYATK;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sAttackType = sAttackType;
  msgOOB.nTotal = nTotal;
  msgOOB.sDesc = sDesc;
  msgOOB.sDMResults = rResults.sDMResults;
  msgOOB.sWeaponName = rResults.sWeaponName;
  msgOOB.sWeaponType = rResults.sWeaponType;
  msgOOB.sPCExtendedText = rResults.sPCExtendedText;
  
  --msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
  --msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
  msgOOB.sTargetType = sTargetType;
  msgOOB.sTargetNode = sTargetNode;  

  Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
  TableManager.processTableRoll("", msgOOB.sTable);
end

function notifyApplyHRFC(sTable)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
  
  msgOOB.sTable = sTable;

  Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
  local bRemoveOnMiss = false;
  local sOptRMMT = OptionsManager.getOption("RMMT");
  if sOptRMMT == "on" then
    bRemoveOnMiss = true;
  elseif sOptRMMT == "multi" then
    local aTargets = {};
    for _,vTargetGroup in ipairs(aTargeting) do
      for _,vTarget in ipairs(vTargetGroup) do
        table.insert(aTargets, vTarget);
      end
    end
    bRemoveOnMiss = (#aTargets > 1);
  end
  
  if bRemoveOnMiss then
    for _,vRoll in ipairs(rRolls) do
      vRoll.bRemoveOnMiss = "true";
    end
  end

  return aTargeting;
end

function getRoll(rActor, rAction)
  -- Build basic roll
  local rRoll = {};
  rRoll.sType = "attack";
  rRoll.aDice = { "d20" };
  rRoll.nMod = 0;
  rRoll.bWeapon = false;

  -- psionics, we need to hand these off since modRoll doesn't keep rAction
--UtilityManagerADND.logDebug("manger_action_attack.lua","modAttack","rAction.Psionic_DisciplineType",rAction.Psionic_DisciplineType);                      
  
  if (rAction) then 
    if (rAction.Psionic_DisciplineType ~= nil and rAction.Psionic_DisciplineType ~= "") then
      rRoll.bPsionic             = 'true';
    end
  --UtilityManagerADND.logDebug("manger_action_attack.lua","modAttack","rRoll.bPsionic",rRoll.bPsionic);   
    rRoll.sSpellSource           = rAction.sSpellSource or "";
    rRoll.Psionic_Source         = rAction.Psionic_Source or "";
    rRoll.Psionic_DisciplineType = rAction.Psionic_DisciplineType or "";
    rRoll.Psionic_MAC            = rAction.Psionic_MAC or 10;
    rRoll.Psionic_PSP            = rAction.Psionic_PSP or 0;
    rRoll.Psionic_PSPOnFail      = rAction.Psionic_PSPOnFail or 0;
    -----
    rRoll.nMod = rAction.modifier or 0;
    rRoll.bWeapon = rAction.bWeapon;
    if (rActor.itemPath and rActor.itemPath ~= "") then
      rRoll.itemPath = rActor.itemPath;
    end
    local bADV = rAction.bADV or false;
    local bDIS = rAction.bDIS or false;
    
    
    -- Build the description label
    rRoll.sDesc = "[ATTACK";
    if rAction.order and rAction.order > 1 then
        rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
    end
    if rAction.range then
        rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
        rRoll.range = rAction.range;
    end
--UtilityManagerADND.logDebug("manager_action_attack.lua","getRoll","rAction.label",rAction.label);
    rRoll.sAttackLabel = rAction.label;
        
    -- rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
    rRoll.sDesc = rRoll.sDesc .. "] ";

    -- Add crit range
    if rAction.nCritRange then
        rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. rAction.nCritRange .. "]";
    end
    
    -- Add ability modifiers
    if rAction.stat then
      local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
      if sAbilityEffect then
          rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
      end
    end
    
    -- Add advantage/disadvantage tags
    if bADV then
        rRoll.sDesc = rRoll.sDesc .. " [ADV]";
    end
    if bDIS then
        rRoll.sDesc = rRoll.sDesc .. " [DIS]";
    end
  else
    rRoll.sDesc = "[ATTACK][BASIC]";
  end
  return rRoll;
end

function performRoll(draginfo, rActor, rAction)
--UtilityManagerADND.logDebug("manager_action_attack.lua","performRoll","draginfo",draginfo);
  local rRoll = getRoll(rActor, rAction);

    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
        draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modAttack(rSource, rTarget, rRoll)
  clearCritState(rSource);
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  
  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
  local bPsionicPower =  rRoll.bPsionic == "true";
  --local nodeAttacker = ActorManager.getCreatureNode(rSource);
  local _, nodeAttacker = ActorManager.getTypeAndNode(rSource);

  -- Check for opportunity attack
  -- local bOpportunity = ModifierStack.getModifierKey("ATT_OPP") or Input.isShiftPressed();

  -- if bOpportunity then
    -- table.insert(aAddDesc, "[OPPORTUNITY]");
  -- end

  -- Check defense modifiers
  local nCoverMod = 0;
  local nConcealMod = 0;
  if ModifierStack.getModifierKey("DEF_COVER_25") then
    nCoverMod = -2;
    table.insert(aAddDesc, "[COVER 25%]");
  elseif ModifierStack.getModifierKey("DEF_COVER_50") then
    nCoverMod = -4;
    table.insert(aAddDesc, "[COVER 50%]");
  elseif ModifierStack.getModifierKey("DEF_COVER_75") then
    nCoverMod = -7;
    table.insert(aAddDesc, "[COVER 75%]");
  elseif ModifierStack.getModifierKey("DEF_COVER_90") then
    nCoverMod = -10;
    table.insert(aAddDesc, "[COVER 90%]");
  end
  if ModifierStack.getModifierKey("DEF_CONCEAL_25") then
    nConcealMod = -1;
    table.insert(aAddDesc, "[CONCEAL 25%]");
  elseif ModifierStack.getModifierKey("DEF_CONCEAL_50") then
    nConcealMod = -2;
    table.insert(aAddDesc, "[CONCEAL 50%]");
  elseif ModifierStack.getModifierKey("DEF_CONCEAL_75") then
    nConcealMod = -3;
    table.insert(aAddDesc, "[CONCEAL 75%]");
  elseif ModifierStack.getModifierKey("DEF_CONCEAL_90") then
    nConcealMod = -4;
    table.insert(aAddDesc, "[CONCEAL 90%]");
  end

  -- attack modifiers (shieldless, no-dex, attacking from rear)
  local nAtkModifier = 0;
  if ModifierStack.getModifierKey("ATK_FROMREAR") then
    nAtkModifier = nAtkModifier + 2;
    table.insert(aAddDesc, "[REAR]");
  end
 
  local nEncAtkMod = 0;
  --local sRank = CharManager.getEncumbranceRank2e(nodeChar);
  local sRank = DB.getValue(nodeAttacker,"speed.encumbrancerank","");
  if sRank == "Moderate" then
    nEncAtkMod = -1;
    table.insert(aAddDesc, "[ENC: " .. sRank .. "]");
  elseif sRank == "Heavy" then
    nEncAtkMod = -2;
    table.insert(aAddDesc, "[ENC: " .. sRank .. "]");
  elseif sRank == "Severe" or sRank == "MAX" then
    nEncAtkMod = -4;
    table.insert(aAddDesc, "[ENC: " .. sRank .. "]");
  end
  
  local bADV = false;
  local bDIS = false;

  local aAttackFilter = {};

-- UtilityManagerADND.logDebug("manager_action_attack.lua","modAttack","rSource",rSource);
-- UtilityManagerADND.logDebug("manager_action_attack.lua","modAttack","rTarget",rTarget);
-- UtilityManagerADND.logDebug("manager_action_attack.lua","modAttack","rRoll",rRoll);
  local nBaseAttack = 0;
  rRoll.nBaseAttack = nBaseAttack;

  if rSource then
    -- Determine attack type
    local sAttackType = string.match(rRoll.sDesc, "%[ATTACK.*%((%w+)%)%]");
    if not sAttackType then
      sAttackType = "M";
    end

    -- Determine ability used
    local sActionStat = nil;
    local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
    if sModStat then
      sActionStat = DataCommon.ability_stol[sModStat];
    end
    
    -- Build attack filter
    if sAttackType == "M" then
      table.insert(aAttackFilter, "melee");
    elseif sAttackType == "R" then
      table.insert(aAttackFilter, "ranged");
    elseif sAttackType == "P" then
      table.insert(aAttackFilter, "psionic");
      bPsionicPower = true;
    end
    if bOpportunity then
      table.insert(aAttackFilter, "opportunity");
    end

    -- Get attack effect modifiers
    local bEffects = false;
    local nEffectCount;
    
    -- add check for psionic and then look for "PSIATK" modifier
    if bPsionicPower then
      aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"PSIATK"}, false, aAttackFilter);
      if (nEffectCount > 0) then
        bEffects = true;
      end
    else -- otherwise get normal ATK mods
      aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter);
      if (nEffectCount > 0) then
        bEffects = true;
      end
    end

    -- Get condition modifiers
    -- if (EffectManager5E.hasEffect(rSource, "ADVATK", rTarget)) then
      -- bADV = true;
      -- bEffects = true;
    -- elseif (#(EffectManager5E.getEffectsByType(rSource, "ADVATK", aAttackFilter, rTarget)) > 0) then
      -- bADV = true;
      -- bEffects = true;
    -- end
    -- if EffectManager5E.hasEffect(rSource, "DISATK", rTarget) then
      -- bDIS = true;
      -- bEffects = true;
    -- elseif (#(EffectManager5E.getEffectsByType(rSource, "DISATK", aAttackFilter, rTarget)) > 0)  then
      -- bDIS = true;
      -- bEffects = true;
    -- end
    if EffectManager5E.hasEffectCondition(rSource, "Blinded") then
      if UtilityManagerADND.hasSkill(nodeAttacker,"blind%-fighting") then
        nAddMod = nAddMod - 2;
      else
        nAddMod = nAddMod - 4;
      end
      bEffects = true;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Incorporeal") then
      bEffects = true;
      table.insert(aAddDesc, "[INCORPOREAL]");
    end
    if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
      bEffects = true;
      nAddMod = nAddMod - 1;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Invisible") then
      bEffects = true;
      nAddMod = nAddMod + 2;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Prone") then
      bEffects = true;
      nAddMod = nAddMod - 2;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Restrained") then
      bEffects = true;
      nAddMod = nAddMod - 2;
    end
    if EffectManager5E.hasEffectCondition(rSource, "Charged") then
      if sAttackType == "M" then
        bEffects = true;
        nAddMod = nAddMod + 2;
      end
    end
    -- Get Base Attack modifier
    if (bPsionicPower) then
      nBaseAttack = getBaseAttackPsionic(rSource);
      rRoll.nBaseAttack = nBaseAttack;
    else 
      nBaseAttack = getBaseAttack(rSource);
      rRoll.nBaseAttack = nBaseAttack;
    end
    
-- UtilityManagerADND.logDebug("menulist.lua","addMenuItem","nAddMod1",nAddMod);    

    -- -- Get ability modifiers
    -- local nBonusStat, nBonusEffects = ActorManagerADND.getAbilityEffectsBonus(rSource, sActionStat,"hitadj");
    -- if nBonusEffects > 0 then
      -- bEffects = true;
      -- nAddMod = nAddMod + nBonusStat;
    -- end

    -- see if target has some effects that incur modifiers.
    if rTarget then
      if EffectManager5E.hasEffectCondition(rTarget, "Restrained") or EffectManager5E.hasEffectCondition(rTarget, "Stunned") then
        bEffects = true;
        nAddMod = nAddMod + 4;
      end
      if EffectManager5E.hasEffectCondition(rTarget, "Prone") or  EffectManager5E.hasEffectCondition(rTarget, "Unconscious") then
        if sAttackType == "M" then
          bEffects = true;
          nAddMod = nAddMod + 4;
        end
      end
    end
    
    -- Determine crit range
    local aCritRange = EffectManager5E.getEffectsByType(rSource, "CRIT");
    --local aCritRangeItem = EffectManager5E.getEffectsByType(rItemSource, "CRIT");
    --aCritRange = (aCritRange,aCritRangeItem);

    if #aCritRange > 0 then
      local nCritThreshold = 20;
      for _,v in ipairs(aCritRange) do
        if v.mod > 1 and v.mod < nCritThreshold then
          bEffects = true;
          nCritThreshold = v.mod;
        end
      end
      if nCritThreshold < 20 then
        local sRollCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
        local nRollCritThreshold = tonumber(sRollCritThreshold) or 20;
        if nCritThreshold < nRollCritThreshold then
          if string.match(rRoll.sDesc, " %[CRIT %d+%]") then
            rRoll.sDesc = string.gsub(rRoll.sDesc, " %[CRIT %d+%]", " [CRIT " .. nCritThreshold .. "]");
          else
            rRoll.sDesc = rRoll.sDesc ..  " [CRIT " .. nCritThreshold .. "]";
          end
        end
      end
    end

    -- If effects, then add them
    if bEffects then
      local sEffects = "";
      nAddMod = math.floor(nAddMod + 0.5);
      local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
      if sMod ~= "" then
        sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
      else
        sEffects = "[" .. Interface.getString("effects_tag") .. "]";
      end
      table.insert(aAddDesc, sEffects);
    end

    -- add THACO for this attack so drag/drop will be able to get it --celestian
    local nTHACO = 20 - rRoll.nBaseAttack;  
    if (bPsionicPower) then
      rRoll.sDesc = rRoll.sDesc .. " [MTHACO(" ..nTHACO.. ")] ";
    elseif bOptAscendingAC then
      rRoll.sDesc = rRoll.sDesc .. " [BAB(" .. rRoll.nBaseAttack .. ")] ";
    else
      rRoll.sDesc = rRoll.sDesc .. " [THACO(" ..nTHACO.. ")] ";
    end

  else    -- no rSource, they are drag/dropping the roll
  
    -- this will grab the THACO from the roll and use it at least --celestian
    local sTHACO = string.match(rRoll.sDesc, "%[THACO.*%((%d+)%)%]") or "20";
    local sBAB = string.match(rRoll.sDesc, "%[BAB.*%((%d+)%)%]");
    if not sTHACO then -- try for MTHACO then...
      sTHACO = string.match(rRoll.sDesc, "%[MTHACO.*%((%d+)%)%]") or "20";
    end
    if not sTHACO then -- if still nothing, just set to 20
        sTHACO = "20";
    end
    local nTHACO = tonumber(sTHACO) or 20;
    if nTHACO < 1 then
        nTHACO = 20;
    end
    if (sBAB and sBAB ~= "") then
      local nBAB = tonumber(sBAB) or 0;
      rRoll.nBaseAttack = nBAB;
    else
      rRoll.nBaseAttack = 20 - nTHACO;
    end
  end
  
  -- target under concealment
  if nConcealMod ~= 0 then
    nAddMod = nAddMod + nConcealMod;
  end
  -- target under cover
  if nCoverMod ~= 0 then
    nAddMod = nAddMod + nCoverMod;
  end
  -- ModifierStack
  if nAtkModifier ~= 0 then
    nAddMod = nAddMod + nAtkModifier;
  end
  -- encumbrance
  if  nEncAtkMod ~= 0 then
    nAddMod = nAddMod + nEncAtkMod ;
  end
  
  if #aAddDesc > 0 then
    rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
  end
  ActionsManager2.encodeDesktopMods(rRoll);
  for _,vDie in ipairs(aAddDice) do
    if vDie:sub(1,1) == "-" then
      table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
    else
      table.insert(rRoll.aDice, "p" .. vDie:sub(2));
    end
  end
  -- UtilityManagerADND.logDebug("manager_action_attack.lua modAttack nAddMod============",nAddMod);
  rRoll.nMod = rRoll.nMod + nAddMod;
  -- UtilityManagerADND.logDebug("manager_action_attack.lua","modAttack","rRoll============",rRoll);
  
  -- to disable advantage/disadvantage ... not AD&D -celestian
  bADV = false;
  bDIS = false;
  --
  ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function onAttack(rSource, rTarget, rRoll)
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  local bOptSHRR = (OptionsManager.getOption("SHRR") ~= "off");
  local bOptREVL = (OptionsManager.getOption("REVL") == "on");
  local is2e = (DataCommonADND.coreVersion == "2e");
  local bHitTarget = false;
  local sExtendedText = "";
  
  ActionsManager2.decodeAdvantage(rRoll);
  local nAttackMatrixRoll = ActionsManager.total(rRoll);
  

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

  local bIsSourcePC = (rSource and ActorManager.isPC(rSource));
  local bPsionic = rRoll.bPsionic == "true";
  local rAction = {};
  rAction.nTotal = ActionsManager.total(rRoll);

    -- add base attack bonus here(converted THACO to BaB remember?) so it doesn't confuse players and show up as a +tohit --celestian]
  -- if is2e then
    -- rAction.nTotal = rAction.nTotal + rRoll.nBaseAttack;
  -- end
    
  rAction.aMessages = {};
  
  local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus = ActorManagerADND.getDefenseValue(rSource, rTarget, rRoll);
  
  UtilityManagerADND.logDebug("manager_action_attack.lua 1",nDefenseVal);  

  --table.insert(rAction.aMessages, string.format(sFormat, nAtkEffectsBonus));
  if nAtkEffectsBonus ~= 0 then
    rAction.nTotal = rAction.nTotal + nAtkEffectsBonus;
    nAttackMatrixRoll = nAttackMatrixRoll + nAtkEffectsBonus;
    local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]"
    table.insert(rAction.aMessages, string.format(sFormat, nAtkEffectsBonus));
  end

  if nDefEffectsBonus ~= 0 then
    nDefenseVal = nDefenseVal + nDefEffectsBonus;
    local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]"
    table.insert(rAction.aMessages, string.format(sFormat, nDefEffectsBonus));
  end
  UtilityManagerADND.logDebug("manager_action_attack.lua 2",nDefenseVal);  
  --  local bCanCrit = true;
  -- insert AC hit
--UtilityManagerADND.logDebug("manager_action_attack.lua","onAttack","nDefenseVal",nDefenseVal);
  local nACHit = (20 - (rAction.nTotal + rRoll.nBaseAttack));
  if DataCommonADND.coreVersion == "1e" or DataCommonADND.coreVersion == "becmi" then
    local nodeForMatrix = ActorManager.getCreatureNode(rSource);
    nACHit = CombatManagerADND.getACHitFromMatrix(nodeForMatrix,nAttackMatrixRoll);
--UtilityManagerADND.logDebug("manager_action_attack.lua","onAttack","Matrix ACHit--------->",nACHit);  
  elseif bOptAscendingAC then   -- you can't have AscendingAC and 1e Matrix (right now)
    nACHit = (rAction.nTotal + rRoll.nBaseAttack);
  end
  
  if rTarget ~= nil then
    UtilityManagerADND.logDebug("manager_action_attack.lua LAST ",nDefenseVal);  
    if (nDefenseVal and nDefenseVal ~= 0) then
      
      -- target has encumbrance penalties
      --local nodeDefender = ActorManager.getCreatureNode(rTarget);
      local _, nodeDefender = ActorManager.getTypeAndNode(rTarget);
      local sRank = DB.getValue(nodeDefender,"speed.encumbrancerank","");
      if sRank == "Heavy" then
        table.insert(rAction.aMessages, "[ENC: " .. sRank .. "]" );
      elseif sRank == "Severe" or sRank == "MAX" then
        table.insert(rAction.aMessages, "[ENC: " .. sRank .. "]" );
      end
      
      -- adjust bCanCrit based on target AC, if they need roll+bab 20 to hit target ac then they cant crit
      -- bCanCrit = (not bPsionic and canCrit(rRoll.nBaseAttack,nDefenseVal));
      local nTargetAC = (20 - nDefenseVal);
      if bOptAscendingAC then
        nTargetAC = nDefenseVal;
      end
      if (bPsionic) then
        --rMessage.text = rMessage.text .. "[Hit-MAC: " .. nACHit .. " vs. ".. nTargetAC .." ]" .. table.concat(rAction.aMessages, " ");
        --rMessage.text = rMessage.text .. table.concat(rAction.aMessages, " ");
        table.insert(rAction.aMessages, "[Hit-MAC: " .. nACHit .. " vs. ".. nTargetAC .." ]" );
      else
        --rMessage.text = rMessage.text .. "[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]" .. table.concat(rAction.aMessages, " ");
        --rMessage.text = rMessage.text .. table.concat(rAction.aMessages, " ");
        table.insert(rAction.aMessages, "[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]" );
      end
    end
  elseif nDefenseVal and bPsionic and not rRoll.Psionic_DisciplineType:match("attack") then -- no source but nDefenseVal and not a psionic attack (it's a power)
    --bCanCrit = false;
    local nTargetAC = (20 - nDefenseVal);
      if bOptAscendingAC then
        nTargetAC = nDefenseVal;
      end
    --rMessage.text = rMessage.text .. "[Hit-MAC: " .. nACHit .. " vs. ".. nTargetAC .." ]" .. table.concat(rAction.aMessages, " ");
    --rMessage.text = rMessage.text .. table.concat(rAction.aMessages, " ");
  end
  
  if (bPsionic) then
    -- bCanCrit = false;
    table.insert(rAction.aMessages, string.format("[MAC: %d ]" , nACHit) );
    sExtendedText = sExtendedText .. string.format("[MAC: %d ]" , nACHit);
  else
    --"[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]"
    --table.insert(rAction.aMessages, "[Hit-AC: " .. nACHit .. " vs. ".. nTargetAC .." ]" );
    table.insert(rAction.aMessages, string.format("[AC: %d ]" , nACHit) );
    sExtendedText = sExtendedText .. string.format("[AC: %d ]" , nACHit);
  end
    
  
  local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
  local nCritThreshold = tonumber(sCritThreshold) or 20;
  if nCritThreshold < 2 or nCritThreshold > 20 then
    nCritThreshold = 20;
  end
  
  rAction.nFirstDie = 0;
  if #(rRoll.aDice) > 0 then
    rAction.nFirstDie = rRoll.aDice[1].result or 0;
  end
  
  if rAction.nFirstDie >= nCritThreshold then
    rAction.bSpecial = true;
    bHitTarget = true;
    rAction.sResult = "crit";
    --if not bCanCrit then
      --table.insert(rAction.aMessages, "[HIT-AUTOMATIC]");
    --else
    table.insert(rAction.aMessages, "[CRITICAL HIT]");
    --end
  elseif rAction.nFirstDie == 1 then
    rAction.sResult = "fumble";
    if bPsionic then
      local sAdjustPSPText = adjustPSPs(rSource,tonumber(rRoll.Psionic_PSPOnFail));
      rMessage.icon = "roll_psionic_hit";
      rMessage.text = rMessage.text .. sAdjustPSPText;
    end
    table.insert(rAction.aMessages, "[MISS-AUTOMATIC]");
    sExtendedText = sExtendedText .. "[MISS-AUTOMATIC]";
  elseif nDefenseVal and nDefenseVal ~= 0 then 
    local nTargetDecendingAC = (20 - nDefenseVal);
    local bMatrixHit = ( nTargetDecendingAC >= nACHit );
    local bHit = ((rAction.nTotal + rRoll.nBaseAttack) >= nDefenseVal or rAction.nFirstDie == 20);
    if (rTarget == nil and rRoll.Psionic_DisciplineType:match("attack")) then
      -- psionic attacks only work with a target, powers however have target MACs so... this lovely confusing mess.
    else if (is2e and bHit) or (not is2e and not bOptAscendingAC and bMatrixHit) then
    --UtilityManagerADND.logDebug("manager_action_attack.lua","onAttack","nDefenseVal",nDefenseVal);
    -- nFirstDie = natural roll, nat 20 == auto-hit, if you can't crit you can still hit on a 20
    -- if rAction.nTotal >= nDefenseVal or rAction.nFirstDie == 20 then
-------------------------------------
      bHitTarget = true;
      rMessage.font = "hitfont";
      rMessage.icon = "chat_hit";
      rAction.sResult = "hit";
      local sHitText = "[HIT]";
      if (rAction.nFirstDie == 20) then
        sHitText = "[HIT-AUTOMATIC]";
      end
      if bPsionic then
        rMessage.icon = "roll_psionic_hit";
      end
      -- if bPsionic then 
        -- table.insert(rAction.aMessages,adjustPSPs(rSource,tonumber(rRoll.Psionic_PSP)));
      -- end
      table.insert(rAction.aMessages, sHitText);
      sExtendedText = sExtendedText .. sHitText;
-------------------------------------
    else
      rMessage.font = "missfont";
      rMessage.icon = "chat_miss";
      rAction.sResult = "miss";
      if bPsionic then
        local sAdjustPSPText = adjustPSPs(rSource,tonumber(rRoll.Psionic_PSPOnFail));
        rMessage.icon = "roll_psionic_miss";
        rMessage.text = rMessage.text .. sAdjustPSPText;
      end
      sExtendedText = sExtendedText .. "[MISS]";
      table.insert(rAction.aMessages, "[MISS]");
    end
    
    end
  end

  if not rTarget then
    rMessage.text = rMessage.text .. " " .. table.concat(rAction.aMessages, " ");
  end
  
  Comm.deliverChatMessage(rMessage);
  
  if rTarget then
    --notifyApplyAttack(rSource, rTarget, rMessage.secret, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "),rRoll.sAttackLabel);
    local rResults = {};
    rResults.sDMResults = table.concat(rAction.aMessages, " ");
    rResults.sWeaponName = rRoll.sAttackLabel;
    rResults.sWeaponType = rRoll.range;
    rResults.sPCExtendedText = sExtendedText;
    
    notifyApplyAttack(rSource, rTarget, rMessage.secret, rRoll.sType, rRoll.sDesc, rAction.nTotal, rResults);
  end
  
  -- TRACK CRITICAL STATE
  if rAction.sResult == "crit" then
    setCritState(rSource, rTarget);
  end
  
  -- REMOVE TARGET ON MISS OPTION
  if rTarget then
    if (rAction.sResult == "miss" or rAction.sResult == "fumble") then
      if rRoll.bRemoveOnMiss then
        TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
      end
    end
  end
  
  -- HANDLE FUMBLE/CRIT HOUSE RULES
  local sOptionHRFC = OptionsManager.getOption("HRFC");
  if rAction.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
    notifyApplyHRFC("Fumble");
  end
  if rAction.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
    notifyApplyHRFC("Critical Hit");
  end
  
  -- check for MIRRORIMAGE and STONESKIN /etc...
  if rTarget and bHitTarget and not bPsionic then
    local _, nStoneSkinCount, _ = EffectManager5E.getEffectsBonus(rTarget, {"STONESKIN"}, false, nil);
    local _, nMirrorCount, nEffectCount = EffectManager5E.getEffectsBonus(rTarget, {"MIRRORIMAGE"}, false, nil);
    if (nStoneSkinCount > 0) then
      -- remove a stoneskin from count
      local nodeCT = ActorManager.getCTNode(rTarget);
      EffectManagerADND.removeEffectCount(nodeCT, "STONESKIN", 1);
      local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
      rMessage.text = "[STONESKIN HIT] " .. Interface.getString("chat_combat_hit_stoneskin");
      Comm.deliverChatMessage(rMessage);
    elseif nMirrorCount > 0 then
      local aMirrorDice = { "d100" };
      local rMirrorRoll = { sType = "roll_against_mirrorimages", sDesc = "[MIRROR-IMAGE]", aDice = aMirrorDice, nMod = 0 ,bSecret = false, sUser = User.getUsername()};
      ActionsManager.roll(rSource, rTarget, rMirrorRoll,false);
    else
      -- check to see if displaced
      local bDisplacedTarget = (EffectManager5E.hasEffect(rTarget, "DISPLACED", nil));
      -- local aEquipmentList = ItemManager2.getItemsEquipped(nodeCharTarget);
      local sDisplacementTag = "DISPLACEMENT_" .. UtilityManagerADND.alphaOnly(ActorManager.getDisplayName(rTarget));
      --if UtilityManagerADND.containsAny(aEquipmentList, "displacement" ) and not EffectManager5E.hasEffect(rSource, sDisplacementTag) then
      if bDisplacedTarget and not EffectManager5E.hasEffect(rSource, sDisplacementTag) then
        -- EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = sDisplacementTag, sLabel = sDisplacementTag, nDuration = 1, sUnits = "minute", nGMOnly = 1, }, false);
        EffectManager.notifyApply({ sName = sDisplacementTag, sLabel = sDisplacementTag, nDuration = 1, sUnits = "minute", nGMOnly = 1, }, rSource.sCTNode)
        local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
        rMessage.text = "[DISPLACEMENT] " .. string.format(Interface.getString("chat_combat_hit_displacement"));  
        Comm.deliverChatMessage(rMessage);
      end
    end
  end
end

--- see if the attack hit mirror/stoneskin instead
function againstMirrors(rSource, rTarget, rRoll)
  local nodeCT = ActorManager.getCTNode(rTarget);
  local nCheckTotal = ActionsManager.total(rRoll);
  local _, nMirrorCount, _ = EffectManager5E.getEffectsBonus(rTarget, {"MIRRORIMAGE"}, false, nil);
  
  if (nMirrorCount > 0) then
    -- calculate a percentage to hit mirror based on number of mirrors
    local fHitMirror = ((nMirrorCount / (1 + nMirrorCount)) * 100)
    local nHitMirror =  math.floor(fHitMirror-0.5); 

    -- if the percentage rolled less than/equal to the "to hit value" then we announce a mirror was hit.
    if (nCheckTotal <= nHitMirror) then
      -- remove a mirror from count
      EffectManagerADND.removeEffectCount(nodeCT, "MIRRORIMAGE", 1);
      local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
      rMessage.text = "[MIRROR-IMAGE HIT] " .. Interface.getString("chat_combat_hit_mirrorimage");
      Comm.deliverChatMessage(rMessage);
    end
  end
  -- remove a mirror
end
--- applyAttack
--function applyAttack(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults, sAttackLabel)
function applyAttack(rSource, rTarget, msgOOB)
  local bSecret = (tonumber(msgOOB.nSecret) == 1);
  local sAttackType = msgOOB.sAttackType; -- 'attack'
  local sDesc = msgOOB.sDesc;
  local nTotal = tonumber(msgOOB.nTotal) or 0;
  local sDMResults = msgOOB.sDMResults;
  local sWeaponName = msgOOB.sWeaponName; -- longsword
  local sWeaponType = msgOOB.sWeaponType; -- 'R' or 'M' or 'P'
  local sPCExtendedText = msgOOB.sPCExtendedText; -- includes AC hit
  
  local msgShort = {font = "msgfont"};
  local msgLong = {font = "msgfont"};

-- UtilityManagerADND.logDebug("manager_action_attack.lua","applyAttack","sAttackTypeFull",sAttackTypeFull);  
-- UtilityManagerADND.logDebug("manager_action_attack.lua","applyAttack","sDesc",sDesc);  

  msgShort.text = "Attack ->";
  msgLong.text = "Attack [" .. nTotal .. "] ->";

  -- add in [ATTACK (X)] so AudioOverseer can see type and miss/hit on same line for sound trigger
  --msgShort.text = msgShort.text .. sAttackTypeFull;

  local sAttackTypeFull = string.match(sDesc, "(%[ATTACK %(%a%)%])");
  if not sAttackTypeFull or sAttackTypeFull == "" then
    sAttackTypeFull = "[ATTACK (?)]";
  end
  msgLong.text = msgLong.text .. sAttackTypeFull;
  
  -- add in weapon used for attack for sound trigger search
  if (sWeaponType and sWeaponType ~= "") then
    msgShort.text = msgShort.text .. "(" .. sWeaponType .. ")";
  end
  if (sWeaponName and sWeaponName ~= "") then
    msgLong.text = msgLong.text .. " (" .. StringManager.capitalizeAll(sWeaponName) .. ")";
  end

  if rTarget then
    msgShort.text = msgShort.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
    msgLong.text = msgLong.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
  end
  
  if sDMResults ~= "" then
    msgLong.text = msgLong.text .. " " .. sDMResults;
    -- if (bOptSHRR or bOptREVL) then
      -- msgShort.text = msgShort.text .. " " .. sResults;
    -- end
  end
  
  if sPCExtendedText ~= "" then
    msgShort.text = msgShort.text .. sPCExtendedText;
  end
  
  local bPsionicPower = false;
  local sType = string.match(sDesc, "%[ATTACK %((%w+)%)%]");
  if sType and sType == "P" then
    bPsionicPower = true;
  end
  
  msgShort.icon = "roll_attack";
  if string.match(sDMResults, "%[CRITICAL HIT%]") then
        msgLong.font = "hitfont";
    msgLong.icon = "roll_attack_crit";
  elseif string.match(sDMResults, "HIT%]") then
    msgLong.font = "hitfont";
    if bPsionicPower then
      msgLong.icon = "roll_psionic_hit";
    else
      msgLong.icon = "roll_attack_hit";
    end
  elseif string.match(sDMResults, "MISS%]") then
    msgLong.font = "missfont";
    if bPsionicPower then
      msgLong.icon = "roll_psionic_miss";
    else
      msgLong.icon = "roll_attack_miss";
    end
  else
    msgLong.icon = "roll_attack";
  end
  
  ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

aCritState = {};

function setCritState(rSource, rTarget)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  if sSourceCT == "" then
    return;
  end
  local sTargetCT = "";
  if rTarget then
    sTargetCT = ActorManager.getCTNodeName(rTarget);
  end
  
  if not aCritState[sSourceCT] then
    aCritState[sSourceCT] = {};
  end
  table.insert(aCritState[sSourceCT], sTargetCT);
end

function clearCritState(rSource)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  if sSourceCT ~= "" then
    aCritState[sSourceCT] = nil;
  end
end

function isCrit(rSource, rTarget)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  if sSourceCT == "" then
    return;
  end
  local sTargetCT = "";
  if rTarget then
    sTargetCT = ActorManager.getCTNodeName(rTarget);
  end

  if not aCritState[sSourceCT] then
    return false;
  end
  
  for k,v in ipairs(aCritState[sSourceCT]) do
    if v == sTargetCT then
      table.remove(aCritState[sSourceCT], k);
      return true;
    end
  end
  
  return false;
end

-- get the base attach bonus using THACO value
function getBaseAttack(rActor)
  local nBaseAttack = 20 - getTHACO(rActor);
  return nBaseAttack;
end
function getTHACO(rActor)
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  
  local nTHACO = 20;
  --local nodeActor = ActorManager.getCreatureNode(rActor);
  local _, nodeActor = ActorManager.getTypeAndNode(rActor);
  if not nodeActor then
    return 0;
  end
  -- get pc thaco value
  if ActorManager.isPC(nodeActor) then
    nTHACO = DB.getValue(nodeActor, "combat.thaco.score", 20);
  else
  -- npc thaco calcs
    nTHACO = DB.getValue(nodeActor, "thaco", 20);
  end
  return nTHACO
end
-- get the base attach bonus using MTHACO value
function getBaseAttackPsionic(rActor)
  local nBaseAttack = 20 - getMTHACO(rActor);
  return nBaseAttack;
end
function getMTHACO(rActor)
  local nTHACO = 20;
  --local nodeActor = ActorManager.getCreatureNode(rActor);
  local _, nodeActor = ActorManager.getTypeAndNode(rActor);
  if not nodeActor then
    return 0;
  end
  nTHACO = DB.getValue(nodeActor, "combat.mthaco.score", 20);
  return nTHACO
end


-- commented this out, there is no such rule in AD&D, was a house rule I had in AD&D Core.
--
-- -- return true if the creature doesn't need a natural 20 to hit the target AC -- celestian
-- -- this assumes nBaB is base attack bonus and ascending AC values, not THACO and decending AC
-- function canCrit(nBaB,nAscendingAC,nRange)
    -- local bCanCrit = true;
    -- local nValidRange = 5;
    -- -- if nRange exists then we use it to adjust the crit window acceptance.
    -- -- nRange = 5, if need a 20 to hit nAscendingAC+5 then they would not be able to crit
    -- -- here incase I decide to use it. Default is, if they need a 20 to hit the target
    -- -- AC then we don't let them crit because it seems stupid they can crit only.
    -- if (nRange) then
        -- nValidRange = nRange;
    -- end
    -- local nAC = nAscendingAC + nValidRange;
    -- local nAttackRoll = 20 + nBaB;
    -- if (nAttackRoll <= nAC) then
        -- bCanCrit = false;
    -- end
    -- return bCanCrit;
-- end

-- return PSP cost string
function adjustPSPs(rSource,nPSPCost,bAdditive)
  local sText = ""
  if not updatePsionicPoints(rSource,nPSPCost,bAdditive) then
    sText = "[**INSUFFICIENT-PSP**]";
  else
    sText = "[PSPCOST:" .. nPSPCost .. "]";
  end
  return sText;
end

-- actually adjust the psp cost here
function updatePsionicPoints(rSource,nAdjustment,bAdditive)
  local sSourceCT = ActorManager.getCreatureNodeName(rSource);
  local node = DB.findNode(sSourceCT);
  if (node) then
    if (bAdditive) then
      ManagerPsionics.addPSP(node,nAdjustment);
      return true;
    else
      return ManagerPsionics.removePSP(node,nAdjustment);
    end
  end
  return false;
end