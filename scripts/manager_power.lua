-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

SPELL_LEVELS = 9;

-------------------
-- POWER MANAGEMENT
-------------------

-- Reset powers used
function resetPowers(nodeCaster, bLong)
  local aListGroups = {};
  
  -- Build list of power groups
  for _,vGroup in pairs(DB.getChildren(nodeCaster, "powergroup")) do
    local sGroup = DB.getValue(vGroup, "name", "");
    if not aListGroups[sGroup] then
      local rGroup = {};
      rGroup.sName = sGroup;
      rGroup.sType = DB.getValue(vGroup, "castertype", "");
      rGroup.nUses = DB.getValue(vGroup, "uses", 0);
      rGroup.sUsesPeriod = DB.getValue(vGroup, "usesperiod", "");
      rGroup.nodeGroup = vGroup;
      
      aListGroups[sGroup] = rGroup;
    end
  end
  
  -- Reset power usage
  for _,vPower in pairs(DB.getChildren(nodeCaster, "powers")) do
    local bReset = true;

    local sGroup = DB.getValue(vPower, "group", "");
    local rGroup = aListGroups[sGroup];
    local bCaster = (rGroup and rGroup.sType ~= "");
    
    if not bCaster then
      if rGroup and (rGroup.nUses > 0) then
        if rGroup.sUsesPeriod == "once" then
          bReset = false;
        elseif not bLong and rGroup.sUsesPeriod ~= "enc" then
          bReset = false;
        end
      else
        local sPowerUsesPeriod = DB.getValue(vPower, "usesperiod", "");
        if sPowerUsesPeriod == "once" then
          bReset = false;
        elseif not bLong and sPowerUsesPeriod ~= "enc" then
          bReset = false;
        end
      end
    elseif bCaster and bLong then
      -- memorized spells reset on daily rest.
      local nMemorized_Total = DB.getValue(vPower, "memorized_total",0);
      if nMemorized_Total > 0 then
        DB.setValue(vPower, "memorized","number", nMemorized_Total);
      end
    end
    
    if bReset then
      DB.setValue(vPower, "cast", "number", 0);
    end
  end
  
    -- disabled this because we dont clear the slots till they are cast.
    -- 5e did it differently.
    
  -- -- Reset spell slots
  -- for i = 1, SPELL_LEVELS do
    -- DB.setValue(nodeCaster, "powermeta.pactmagicslots" .. i .. ".used", "number", 0);
  -- end
  -- if bLong then
    -- for i = 1, SPELL_LEVELS do
      -- DB.setValue(nodeCaster, "powermeta.spellslots" .. i .. ".used", "number", 0);
    -- end
  -- end
  
  
end

-- add spells dropped on to sheet -celestian
function addPower(sClass, nodeSource, nodeCreature, sGroup)
  -- Validate
  if not nodeSource or not nodeCreature then
    return nil;
  end
--UtilityManagerADND.logDebug("manager_power.lua","addPower","nodeSource",nodeSource);    
--UtilityManagerADND.logDebug("manager_power.lua","addPower","nodeCreature",nodeCreature);    

  -- Create the powers list entry
  local nodePowers = nodeCreature.createChild("powers");
--UtilityManagerADND.logDebug("manager_power.lua","addPower","nodePowers",nodePowers);    
  if not nodePowers then
    return nil;
  end
  
    -- Create the new power entry
    local nodeNewPower = nodePowers.createChild();
    if not nodeNewPower then
        return nil;
    end
    DB.copyNode(nodeSource, nodeNewPower);
    
    -- -- Determine group setting
    if sGroup then
        DB.setValue(nodeNewPower, "group", "string", sGroup);
    end

    local bHasActions = (DB.getChildCount(nodeNewPower, "actions") > 0);
--UtilityManagerADND.logDebug("manager_power.lua","addPower","bHasActions",bHasActions);    
        
    -- add "cast" action, set to group "Spells" if nothing found
    if (not bHasActions) then
        local sType = DB.getValue(nodeNewPower,"type",""):lower();
        
--UtilityManagerADND.logDebug("manager_power.lua","addPower","nodeNewPower",nodeNewPower);    
        -- setup at least cast
        local nodeActions = nodeNewPower.createChild("actions");
        local nodeAction = nodeActions.createChild();        
        DB.setValue(nodeAction, "type", "string", "cast");
        if (sType:match("psionic")) then
          --<atktype type="string">psionic</atktype>
          DB.setValue(nodeAction, "atktype", "string", "psionic");      
        else
          DB.setValue(nodeAction, "savetype", "string", "spell");      
        end
        
        -- -- add these so that spells copied from other players/sources
        -- -- get setup immediately --celestian
        -- local sTypeSource = DB.getValue(nodeSource,"type","");
        -- DB.setValue(nodeNewPower,"type","string",sTypeSource);
        -- local sCastingTimeSource = DB.getValue(nodeSource,"castingtime","");
        -- DB.setValue(nodeNewPower,"castingtime","string",sCastingTimeSource);
        -- local nLevelSource = DB.getValue(nodeSource,"level",0);
        -- DB.setValue(nodeNewPower,"level","number",nLevelSource);
        -- --
        
        -- -- Copy the power details over
        -- DB.copyNode(nodeSource, nodeNewPower);
        
        -- -- Determine group setting
        -- if sGroup then
            -- DB.setValue(nodeNewPower, "group", "string", sGroup);
        -- end
        
        -- -- Class specific handling
        -- if sClass == "reference_spell" or sClass == "power" then
            -- -- DEPRECATED: Used to add spell slot of matching spell level, but deprecated since handled by class drops and doesn't work for warlock
        -- else
            -- -- Remove level data
            -- DB.deleteChild(nodeNewPower, "level");
            
            -- -- Copy text to description
            -- local nodeText = nodeNewPower.getChild("text");
            -- if nodeText then
                -- local nodeDesc = nodeNewPower.createChild("description", "formattedtext");
                -- DB.copyNode(nodeText, nodeDesc);
                -- nodeText.delete();
            -- end
        -- end
        
        -- -- Set locked state for editing detailed record
        -- DB.setValue(nodeNewPower, "locked", "number", 1);
        
        -- -- Parse power details to create actions
        -- local bNeedsActions = false; -- does this power already have actions?
        -- if DB.getChildCount(nodeNewPower, "actions") == 0 then
            -- parsePCPower(nodeNewPower);
            -- bNeedsActions = true;
        -- end
        
        -- -- add cast bar for spells with level and type -celestian
        -- -- also setup vars for castinitiative 
        -- local nLevel = nodeNewPower.getChild("level").getValue();
        -- local sSpellType = nodeNewPower.getChild("type").getValue():lower();
        -- local sCastingTime = nodeNewPower.getChild("castingtime").getValue():lower();
        -- local nCastTime = getCastingTime(sCastingTime,nLevel);
        -- if bNeedsActions then
            -- if (nLevel > 0 and (sSpellType == "arcane" or sSpellType == "divine")) then
                -- local nodeActions = nodeNewPower.createChild("actions");
                -- if nodeActions then
                    -- local nodeAction = nodeActions.createChild();
                    -- if nodeAction then
                        -- DB.setValue(nodeAction, "type", "string", "cast");
                        -- -- set "savetype" to "spell"
                        -- DB.setValue(nodeAction, "savetype", "string", "spell");      
                        -- -- initiative setting
                        -- DB.setValue(nodeAction, "....castinitiative", "number", nCastTime);
                    -- end
                -- end
            -- end
        -- end
    end
    return nodeNewPower;
end

-- parse the castingtime of a spell and turn into "init modifier" -celestian
-- function getCastingTime(sCastingTime,nSpellLevel)
    -- local nCastTime = 1;
    -- local nCastBase = sCastingTime:match("(%d+)") or nSpellLevel;
    -- local sLeftover = sCastingTime:match("%d+(.*)") or "";
    
    -- nCastTime = nCastBase;
    -- -- if something other than number/space in string...
    -- if string.len(sLeftover) > 1 then 
        -- sLeftover = sLeftover:gsub(" ","");
        -- if (StringManager.isWord(sLeftover, {"round","rd","rds","rd.","rn","rn."})) then
            -- nCastTime = nCastBase * 10;
        -- else
            -- -- anything more than this we really shouldn't be rolling for init
            -- nCastTime = 999;
        -- end
    -- end
    
    -- return nCastTime;
-- end

-------------------------
-- POWER ACTION DISPLAY
-------------------------

function getPowerActionOutputOrder(nodeAction)
  if not nodeAction then
    return 1;
  end
  local nodeActionList = nodeAction.getParent();
  if not nodeActionList then
    return 1;
  end
  
  -- First, pull some ability attributes
  local sType = DB.getValue(nodeAction, "type", "");
  local nOrder = DB.getValue(nodeAction, "order", 0);
  
  -- Iterate through list node
  local nOutputOrder = 1;
  for k, v in pairs(nodeActionList.getChildren()) do
    if DB.getValue(v, "type", "") == sType then
      if DB.getValue(v, "order", 0) < nOrder then
        nOutputOrder = nOutputOrder + 1;
      end
    end
  end
  
  return nOutputOrder;
end

function getPowerRoll(rActor, nodeAction, sSubRoll)

  --UtilityManagerADND.logDebug("manager_power.lua","getPowerRoll","rActor",rActor)
  --UtilityManagerADND.logDebug("manager_power.lua","getPowerRoll","nodeAction",nodeAction)
  --UtilityManagerADND.logDebug("manager_power.lua","getPowerRoll","sSubRoll",sSubRoll)

  if not nodeAction then
    return;
  end
  
  local sType = DB.getValue(nodeAction, "type", "");
  local sAttackType = DB.getValue(nodeAction, "atktype", "");
  local rAction = {};
  rAction.type = sType;
  rAction.label = DB.getValue(nodeAction, "...name", "");
  rAction.order = getPowerActionOutputOrder(nodeAction);
  
  local nodeSpell = nodeAction.getChild("...");
  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local nPSPCost = DB.getValue(nodeSpell,"pspcost",0);
  local nPSPCostFail = DB.getValue(nodeSpell,"pspfail",0);
  local nMAC = DB.getValue(nodeSpell,"mac",10);
  local sDiscipline = DB.getValue(nodeSpell,"discipline","");
  local sDisciplineType = DB.getValue(nodeSpell,"disciplinetype","");
  if ((sDiscipline ~= "" and nPSPCost > 0) or (sSpellType == "psionic") or (sAttackType == "psionic") ) then
    rAction.Psionic_Source = nodeSpell.getPath();
  end
  if (sSpellType and sSpellType ~= "") then
    rAction.sSpellSource = nodeSpell.getPath(); -- incase we need to use this elsewhere...
  end
  rAction.Psionic_DisciplineType = sDisciplineType:lower();
  rAction.Psionic_MAC = nMAC;
  rAction.Psionic_PSP = nPSPCost;
  rAction.Psionic_PSPOnFail = nPSPCostFail;
  
  if sType == "cast" then
    rAction.subtype = sSubRoll;
    rAction.onmissdamage = DB.getValue(nodeAction, "onmissdamage", "");
    -- this can be used to store damage types or various other data and then
    -- negotiate a save version spell that is fire bonuses? -- celestian
    rAction.properties = DB.getValue(nodeAction, "properties", "");
    --
    if sAttackType ~= "" then
      local nGroupMod, sGroupStat = getGroupAttackBonus(rActor, nodeAction, "");
    
      if sAttackType == "melee" then
        rAction.range = "M";
      elseif sAttackType == "ranged" then
        rAction.range = "R";
      elseif sAttackType == "psionic" then
        rAction.range = "P";
      end
      
      local nGroupMod, sGroupStat = getGroupAttackBonus(rActor, nodeAction, "base");

      local sAttackBase = DB.getValue(nodeAction, "atkbase", "");
      if sAttackBase == "fixed" then
        rAction.modifier = DB.getValue(nodeAction, "atkmod", 0);
      elseif sAttackBase == "ability" then
        local sAbility = DB.getValue(nodeAction, "atkstat", "");
        if sAbility == "base" then
          sAbility = sGroupStat;
        end
        local nAttackProf = DB.getValue(nodeAction, "atkprof", 1);
        
        rAction.modifier = ActorManagerADND.getAbilityBonus(rActor, sAbility, "hitadj") + DB.getValue(nodeAction, "atkmod", 0);
        if nAttackProf == 1 then
          rAction.modifier = rAction.modifier + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
        end
        rAction.stat = sAbility;
      else
        rAction.modifier = nGroupMod + DB.getValue(nodeAction, "atkmod", 0);
        rAction.stat = sGroupStat;
      end
    end
    
    local sSaveType = DB.getValue(nodeAction, "savetype", ""):lower();
    if sSaveType ~= "" then
      local nGroupDC, sGroupStat = PowerManager.getGroupSaveDC(rActor, nodeAction, sSaveType);
      if sSaveType == "base" then
        sSaveType = sGroupStat;
      end
      rAction.save = sSaveType;
      local sSaveBase = DB.getValue(nodeAction, "savedcbase", "");
      if sSaveBase == "fixed" then
        rAction.savemod = DB.getValue(nodeAction, "savedcmod", 0);
      elseif sSaveBase == "ability" then
        local sAbility = DB.getValue(nodeAction, "savedcstat", "");
        if sAbility == "base" then
          sAbility = sGroupStat;
        end
        --local nSaveProf = DB.getValue(nodeAction, "savedcprof", 1);
        --rAction.savemod = 8 + ActorManagerADND.getAbilityBonus(rActor, sAbility) + DB.getValue(nodeAction, "savedcmod", 0);
        --if nSaveProf == 1 then
        --  rAction.savemod = rAction.savemod + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
        --end
        rAction.savemod = DB.getValue(nodeAction, "savedcmod", 0);
      else
        rAction.savemod = nGroupDC + DB.getValue(nodeAction, "savedcmod", 0);
      end
    else
      rAction.save = "";
      rAction.savemod = 0;
    end
    
  elseif sType == "damage_psp" then
    rAction.clauses = getActionDamagePSP(rActor, nodeAction);
  elseif sType == "heal_psp" then
    rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
    rAction.subtype = DB.getValue(nodeAction, "healtype", "");
    rAction.clauses = getActionHealPSP(rActor, nodeAction);
  elseif sType == "damage" then
    rAction.clauses = getActionDamage(rActor, nodeAction);
  elseif sType == "heal" then
    rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
    rAction.subtype = DB.getValue(nodeAction, "healtype", "");
    
    rAction.clauses = getActionHeal(rActor, nodeAction);
    
  elseif sType == "effect" then
    local sEffect = DB.getValue(nodeAction, "label", "");
    if string.match(sEffect, "%[BASE%]") then
      local sStat = getGroupStat(rActor, nodeAction);
      if DataCommon.ability_ltos[sStat] then
        string.gsub(sEffect, "%[BASE%]", "[" .. DataCommon.ability_ltos[sStat] .. "]");
      end
    end
    rAction.sName = EffectManager5E.evalEffect(rActor, sEffect);

    rAction.sApply = DB.getValue(nodeAction, "apply", "");
    rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
   
    -- roll dice for duration if exists --celestian
    local nRollDuration = 0;
    local dDurationDice = DB.getValue(nodeAction, "durdice");
    local nModDice = DB.getValue(nodeAction, "durmod", 0);
    local nDurationValue = PowerManager.getLevelBasedDurationValue(nodeAction);
    if (nDurationValue > 0) then
      nModDice = nModDice + nDurationValue;
    end
    if (dDurationDice and dDurationDice ~= "") then
        nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
    else
        nRollDuration = nModDice;
    end
    rAction.nDuration = nRollDuration;
    rAction.sUnits = DB.getValue(nodeAction, "durunit", "");
    local sVisibility = DB.getValue(nodeAction, "visibility", "");
    if (sVisibility:match("hide")) then
      rAction.nGMOnly = 1;
    else
      rAction.nGMOnly = 0;
    end
  end

  return rAction;
end


function performAction(draginfo, nodeAction, sSubRoll)
--UtilityManagerADND.logDebug("manager_power.lua","performAction","nodeAction",nodeAction);
--UtilityManagerADND.logDebug("manager_power.lua","performAction","sSubRoll",sSubRoll);
  if not nodeAction then
    return;
  end
  local rActor = ActorManager.resolveActor( nodeAction.getChild("....."));
  if not rActor then
    return;
  end
--UtilityManagerADND.logDebug("manager_power.lua","performAction","rActor",rActor);

    -- add itemPath to rActor so that when effects are checked we can 
    -- make compare against action only effects
    local nodeWeapon = nodeAction.getChild("...");
    local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
    rActor.itemPath = sRecord;
    if (draginfo and rActor.itemPath and rActor.itemPath ~= "") then
      draginfo.setMetaData("itemPath",rActor.itemPath);
    end
    --
    
    -- capture this and increment spells used -celestian
    local sType = DB.getValue(nodeAction, "type", "");
    -- check that sSubRoll is nil so we dont remove memorization for a save.
    if sType == "cast" and not sSubRoll then 
      if not castMemorizedSpell(nodeAction) then 
        -- spell wasn't memorized so stop here
        return; 
      end

      -- mark one use of this used
      if not incrementUse(nodeAction) then
        -- no uses left, stop
        return;
      end

    end
    
    
    local rAction = getPowerRoll(rActor, nodeAction, sSubRoll);

    -- expend PSPs if not psionic attack
    if (rAction.type ~= "cast" and rAction.Psionic_Source) then
      local nPSPCost = tonumber(rAction.Psionic_PSP);
      local sPSPCost = ""..nPSPCost;
      if not ActionAttack.updatePsionicPoints(rActor,nPSPCost) then
        sPSPCost = "INSUFFCIENT-PSP REMAINING!";
      end
       local rMessage = {};
      rMessage.text = rActor.sName .. ": expend psp->" .. sPSPCost;
      rMessage.secret = true;
      rMessage.font = "missfont";
      rMessage.icon = "power_casterspontaneous";
      Comm.deliverChatMessage(rMessage);
    end

    local sRollType = nil;
    local rRolls = {};
    
    if rAction.type == "cast" then
      if not rAction.subtype then
          table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
      end
      
      if not rAction.subtype or rAction.subtype == "atk" then
          if rAction.range then
              table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
          end
      end

      if not rAction.subtype or rAction.subtype == "save" then
        if rAction.save and rAction.save ~= "" then
          local rRoll = ActionPower.getSaveVsRoll(rActor, rAction);
          if not rAction.subtype then
            rRoll.sType = "powersave";
          end
          table.insert(rRolls, rRoll);
        end
      end
    elseif rAction.type == "damage" then
        table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
        
    elseif rAction.type == "heal" then
        table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));

    elseif rAction.type == "effect" then
        local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
        if rRoll then
          table.insert(rRolls, rRoll);
        end
    elseif rAction.type == "damage_psp" then
        table.insert(rRolls, ActionDamagePSP.getRoll(rActor, rAction));
        
    elseif rAction.type == "heal_psp" then
        table.insert(rRolls, ActionHealPSP.getRoll(rActor, rAction));

    end
    
    if #rRolls > 0 then
        ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
    end
end

function getGroupFromAction(rActor, nodeAction)
  local sGroup = DB.getValue(nodeAction, "...group", "");
  for _,v in pairs(DB.getChildren(ActorManager.getCreatureNode(rActor), "powergroup")) do
    if DB.getValue(v, "name", "") == sGroup then
      return v;
    end
  end
  return nil;
end

function getGroupStat(rActor, nodeAction)
  local vGroup = getGroupFromAction(rActor, nodeAction);
  return DB.getValue(vGroup, "stat", "");
end

function getGroupAttackBonus(rActor, nodeAction)
  local vGroup = getGroupFromAction(rActor, nodeAction);

  local sGroupAtkStat = DB.getValue(vGroup, "atkstat", "");
  if sGroupAtkStat == "" then
    sGroupAtkStat = DB.getValue(vGroup, "stat", "");
  end
  local nGroupAtkProf = DB.getValue(vGroup, "atkprof", 1);
  
  local nGroupAtkMod = ActorManagerADND.getAbilityBonus(rActor, sGroupAtkStat, "hitadj");
  if nGroupAtkProf == 1 then
    nGroupAtkMod = nGroupAtkMod + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
  end
  nGroupAtkMod = nGroupAtkMod + DB.getValue(vGroup, "atkmod", 0);
  
  return nGroupAtkMod, sGroupAtkStat;
end

function getGroupSaveDC(rActor, nodeAction)
  local vGroup = getGroupFromAction(rActor, nodeAction);

  local sGroupSaveStat = DB.getValue(vGroup, "savestat", "");
  if sGroupSaveStat == "" then
    sGroupSaveStat = DB.getValue(vGroup, "stat", "");
  end
  local nGroupSaveProf = DB.getValue(vGroup, "saveprof", 1);
  
--  local nGroupSaveDC = 8 + ActorManagerADND.getAbilityBonus(rActor, sGroupSaveStat);
  local nGroupSaveDC = 0;
  --if nGroupSaveProf == 1 then
  --  nGroupSaveDC = nGroupSaveDC + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
  --end
  nGroupSaveDC = nGroupSaveDC + DB.getValue(vGroup, "savemod", 0);
  
  return nGroupSaveDC, sGroupSaveStat;
end

function getGroupDamageHealBonus(rActor, nodeAction, sStat)
  if sStat == "base" then
    sStat = getGroupStat(rActor, nodeAction);
  end
  local nMod = ActorManagerADND.getAbilityBonus(rActor, sStat);
  return nMod, sStat;
end

function getActionDamageText(nodeAction)
  local nodeActor = nodeAction.getChild(".....")
  local rActor = ActorManager.resolveActor( nodeActor);

  local clauses = PowerManager.getActionDamage(rActor, nodeAction);
  
  local aOutput = {};
  local aDamage = ActionDamage.getDamageStrings(clauses);
  for _,rDamage in ipairs(aDamage) do
    local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
    if sDice ~= "" then
      if rDamage.sType ~= "" then
        table.insert(aOutput, string.format("%s %s", sDice, rDamage.sType));
      else
        table.insert(aOutput, sDice);
      end
    end
  end
  
  return table.concat(aOutput, " + ");
end

function getActionDamage(rActor, nodeAction)
  if not nodeAction then
    return {};
  end

  local nodeCaster = ActorManager.getCreatureNode(rActor);
  
  local clauses = {};
  local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeAction, "damagelist"));
  for _,v in ipairs(aDamageNodes) do
    local sDmgAbility = DB.getValue(v, "stat", "");
    local sDmgType = DB.getValue(v, "type", "");
    
    local nodeCaster = ActorManager.getCreatureNode(rActor);
    local nDmgMod, aDmgDice = getLevelBasedDiceValues(nodeCaster,ActorManager.isPC(rActor), nodeAction, v)
    
    if sDmgAbility ~= "none" and sDmgAbility ~= "" and rActor then
      nDmgMod = nDmgMod + ActorManagerADND.getAbilityBonus(rActor, sDmgAbility, "damageadj");
    end
  
    local nDmgStatMod;
    nDmgStatMod, sDmgAbility = getGroupDamageHealBonus(rActor, nodeAction, sDmgAbility);
    nDmgMod = nDmgMod + nDmgStatMod;

    table.insert(clauses, { dice = aDmgDice, stat = sDmgAbility, modifier = nDmgMod, dmgtype = sDmgType });
  end

  return clauses;
end

function getActionHealText(nodeAction)
  local nodeActor = nodeAction.getChild(".....")
  local rActor = ActorManager.resolveActor( nodeActor);

  local clauses = PowerManager.getActionHeal(rActor, nodeAction);
  
  local aHealDice = {};
  local nHealMod = 0;
  for _,vClause in ipairs(clauses) do
    for _,vDie in ipairs(vClause.dice) do
      table.insert(aHealDice, vDie);
    end
    nHealMod = nHealMod + vClause.modifier;
  end
  
  local sHeal = StringManager.convertDiceToString(aHealDice, nHealMod);
  if DB.getValue(nodeAction, "healtype", "") == "temp" then
    sHeal = sHeal .. " temporary";
  end
  
  local sTargeting = DB.getValue(nodeAction, "healtargeting", "");
  if sTargeting == "self" then
    sHeal = sHeal .. " [SELF]";
  end
  
  return sHeal;
end

function getActionHeal(rActor, nodeAction)
  if not nodeAction then
    return;
  end
  
  local clauses = {};
  local aHealNodes = UtilityManager.getSortedTable(DB.getChildren(nodeAction, "heallist"));
  for _,v in ipairs(aHealNodes) do
    local sAbility = DB.getValue(v, "stat", "");
    -- local aDice = DB.getValue(v, "dice", {});
    -- local nMod = DB.getValue(v, "bonus", 0);

    local nodeCaster = ActorManager.getCreatureNode(rActor);
    local nMod,aDice = getLevelBasedDiceValues(nodeCaster,ActorManager.isPC(rActor), nodeAction, v)
    
    local nStatMod;
    nStatMod, sAbility = getGroupDamageHealBonus(rActor, nodeAction, sAbility);
    nMod = nMod + nStatMod;
    
    
    table.insert(clauses, { dice = aDice, stat = sAbility, modifier = nMod });
  end

  return clauses;
end

-- bits of code to sort out level for dice
function getLevelBasedDiceValues(nodeCaster, isPC, node, nodeAction)
  local nDiceCount = 0;
  local aDice = DB.getValue(nodeAction, "dice", {});
  local nMod = DB.getValue(nodeAction, "bonus", 0);
  local sCasterType = DB.getValue(nodeAction, "castertype", "");
  local nCasterMax = DB.getValue(nodeAction, "castermax", 20);
  local nCustomValue = DB.getValue(nodeAction, "customvalue", 0);
  local aDmgDiceCustom = DB.getValue(nodeAction, "dicecustom", {});
  local nodeSpell = node.getChild("...");
  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local nCasterLevel = getCasterLevelByType(nodeCaster,sSpellType,isPC);
  -- local nCasterLevel = 1;
  -- local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
    -- if (sSpellType:match("arcane")) then
      -- nCasterLevel = DB.getValue(nodeCaster, "arcane.totalLevel",1);
    -- elseif (sSpellType:match("divine")) then
      -- nCasterLevel = DB.getValue(nodeCaster, "divine.totalLevel",1);
    -- elseif (sSpellType:match("psionic")) then
      -- nCasterLevel = DB.getValue(nodeCaster, "psionic.totalLevel",1);
    -- else
      -- if (isPC) then
        -- -- use spelltype name and match it with class and return that level
        -- nCasterLevel = CharManager.getClassLevelByName(nodeCaster,sSpellType);
        -- if (nCasterLevel <= 0) then
          -- nCasterLevel = CharManager.getActiveClassMaxLevel(nodeCaster);
        -- end
      -- else
        -- nCasterLevel = DB.getValue(nodeCaster, "level",1);
      -- end
    -- end
  -- if castertype ~= "" then setup the dice
  if (sCasterType ~= nil) then
    -- make sure nCasterLevel is not larger than max size
    if nCasterMax > 0 and nCasterLevel > nCasterMax then
      nCasterLevel = nCasterMax;
    end
    -- match the caster level number on end of string
    local sCasterLevel = sCasterType:match("casterlevelby(%d+)");
    if sCasterType == "casterlevel" then
      nDiceCount = nCasterLevel;
    elseif sCasterLevel then
      local nDividedBy = tonumber(sCasterLevel) or 1;
      nDiceCount = math.floor(nCasterLevel/nDividedBy);
    else
      nDiceCount = 1;
    end
    if nDiceCount > 0 then
      -- if using customvalue multiply it by CL value and add that to +mod total
      if (nCustomValue > 0) then
        nMod = nMod + (nCustomValue * nDiceCount); -- nDiceCount is CL value
      end
      local aNewDmgDice = {}
      local nDiceIndex = 0;
      -- roll count number of "dice" LEVEL D {DICE}
      for count = 1, nDiceCount do
        for i = 1, #aDice do
          nDiceIndex = nDiceIndex + 1;
          aNewDmgDice[nDiceIndex] = aDice[i];
        end
      end
      -- add in custom plain dice now
      for i = 1, #aDmgDiceCustom do
        nDiceIndex = nDiceIndex + 1;
        aNewDmgDice[nDiceIndex] = aDmgDiceCustom[i];
      end
      
      aDice = aNewDmgDice;
    end
  end
  -- end sort out level for dice count

  -- return adjusted modifier and dice
  return nMod, aDice;
end

--
-- memorization
--

-- can memory a spell type 
function canMemorizeSpellType(nLevel, sSpellType)
  return (nLevel>0 and (isArcaneSpellType(sSpellType) or isDivineSpellType(sSpellType) and not isPsionicPowerType(sSpellType)) );
end
-- return true if the spell can be memorized.
function canMemorizeSpell(nodeSpell)
--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","nodeSpell",nodeSpell);
  local nLevel = DB.getValue(nodeSpell, "level", 0);
  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local sGroup = DB.getValue(nodeSpell, "group", ""):lower();
  local sNodePath = nodeSpell.getPath();
  local nodeCaster = nodeSpell.getChild("...");
  local sCasterType = getGroupCasterType(nodeCaster,sGroup);
--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","sCasterType",sCasterType);
--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","nLevel",nLevel);
--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","sSpellType",sSpellType);
--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","sGroup",sGroup);
--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","sNodePath",sNodePath);    

  local bCanMemorize = (canMemorizeSpellType(nLevel, sSpellType) and sCasterType == "memorization");
  -- if this is coming from spell record then no, nothing will memorize
  if string.match(sNodePath,"^spell") ~= nil or string.match(sNodePath,"^item") ~= nil or string.match(sNodePath,"^class") ~= nil then
    bCanMemorize = false;
  end
  -- -- if the group the action is in, is NOT a spell then no, no memorization
  -- if string.match(sGroup,"^spell.?$") == nil then
    -- bCanMemorize = false;
  -- end

--UtilityManagerADND.logDebug("manager_power.lua","canMemorizeSpell","bCanMemorize3",bCanMemorize);    
    return bCanMemorize;
end

-- commit a spell to memoriy --celestian
function memorizeSpell(nodeSpell)
--UtilityManagerADND.logDebug("manager_power.lua","memorizeSpell","nodeSpell",nodeSpell);
    local bSuccess = true;
  if not nodeSpell then
    return false;
  end
  local nodeChar = nodeSpell.getChild("...");
  if not nodeChar then
    return false;
  end
  local bisNPC = (not ActorManager.isPC(nodeChar)); 
      
  
  local sName = DB.getValue(nodeSpell, "name", "");
  local sCasterType = DB.getValue(nodeSpell, "castertype", "");
  local nLevel = DB.getValue(nodeSpell, "level", 0);
  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local sSource = DB.getValue(nodeSpell, "source", ""):lower();
  local sCastTime = DB.getValue(nodeSpell, "castingtime", "");
  local sDuration = DB.getValue(nodeSpell, "duration", "");
  local nMemorized = DB.getValue(nodeSpell, "memorized", 0);
  local nMemorized_Total = DB.getValue(nodeSpell, "memorized_total", 0);
  
  --if (nLevel>0 and (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource) or isDivineSpellType(sSpellType) or isDivineSpellType(sSource)and not isPsionicPowerType(sSpellType)) ) then
--  if canMemorizeSpellType(nLevel, sSpellType) then
  if canMemorizeSpell(nodeSpell) then
    local nUsedArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0);
    local nMaxArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".max", 0);
    local nUsedDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".used", 0);
    local nMaxDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".max", 0);

    if (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource)) then
      if (hasFreeSlot(nMemorized,nMaxArcane,nUsedArcane) or bisNPC) then
        DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",(nUsedArcane+1));
        DB.setValue(nodeSpell,"memorized","number",(nMemorized+1));
        DB.setValue(nodeSpell,"memorized_total","number",(nMemorized+1));
        --ChatManager.Message(Interface.getString("message_youmemorize") .. " " .. sName .. ".", true, ActorManager.resolveActor( nodeChar));
        local sMsg = string.format(Interface.getString("message_youmemorize"), DB.getValue(nodeChar, "name", ""),sName);
        ChatManager.SystemMessage(sMsg);
      else
        -- not enough slots left
        bSuccess = false;
        --ChatManager.Message(Interface.getString("message_nomoreslots"), true, ActorManager.resolveActor( nodeChar));
        local sMsg = string.format(Interface.getString("message_nomoreslots"), DB.getValue(nodeChar, "name", ""));
        ChatManager.SystemMessage(sMsg);
      end
    elseif (isDivineSpellType(sSpellType) or isDivineSpellType(sSource)) then
      if (hasFreeSlot(nMemorized,nMaxDivine,nUsedDivine) or bisNPC) then
        DB.setValue(nodeChar,"powermeta.pactmagicslots" .. nLevel .. ".used","number",(nUsedDivine+1));
        DB.setValue(nodeSpell,"memorized","number",(nMemorized+1));
        DB.setValue(nodeSpell,"memorized_total","number",(nMemorized+1));
        --ChatManager.Message(Interface.getString("message_youmemorize") .. " " .. sName .. ".", true, ActorManager.resolveActor( nodeChar));
        local sMsg = string.format(Interface.getString("message_youmemorize"), DB.getValue(nodeChar, "name", ""),sName);
        ChatManager.SystemMessage(sMsg);
      else
        -- not enough slots left
        bSuccess = false;
        --ChatManager.Message(Interface.getString("message_nomoreslots"), true, ActorManager.resolveActor( nodeChar));
        local sMsg = string.format(Interface.getString("message_nomoreslots"), DB.getValue(nodeChar, "name", ""));
        ChatManager.SystemMessage(sMsg);
      end
    end -- spelltype
    -- not a memorize'able spell
  else
    ChatManager.SystemMessage(string.format(Interface.getString("message_notaspelltomem"), DB.getValue(nodeChar, "name", "")));
  end
    
    return bSuccess;
end

--[[ 
Do some sanity checking on memorized slots, it gets a bit messy when
DMs start to edit values and there are slots already memorized. This 
will at least keep them from memorizing to many.

nMemorized = number of slots memorized on the spell
nMaxSpell = total spell slots open for this type/level
nUsedSpell = total spell slots used for this type/level

check to see if we have slots for this spell
]]--
function hasFreeSlot(nMemorized, nMaxSpell,nUsedSpell)
  local bOpen = false;
  if nMemorized < nMaxSpell and nUsedSpell+1 <= nMaxSpell then
    bOpen = true;
  end
  
  return bOpen;
end

-- increment the cast count, on any group BUT "Spells"
function incrementUse(node)
--  UtilityManagerADND.logDebug("manager_power.lua","incrementUse","node",node);  
  local nodeSpell = node.getChild("...");
  if not nodeSpell then
    return false;
  end
  local nodeChar = nodeSpell.getChild("...");
  if not nodeChar then
    return false;
  end

  local sGroup = DB.getValue(nodeSpell, "group", ""):lower();
  --local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local bPsionic = string.match(sGroup,"^psionic"); --(sSpellType:match("psionic));
  local bSpellCasting = string.match(sGroup,"^spells");

  local sActionType = DB.getValue(node,"type","");
  local bisNPC = (not ActorManager.isPC(nodeChar));
  local bHadCharge = true;
  local nPrepared = DB.getValue(nodeSpell, "prepared", 0);

  if not bPsionic and not bSpellCasting and sActionType == "cast" then
    local nCast = DB.getValue(nodeSpell, "cast", 0);
    --UtilityManagerADND.logDebug("manager_power.lua","incrementUse","nCast",nCast);    
    if (nPrepared >= (nCast+1) or bisNPC) then -- ignore check for npcs
      DB.setValue(nodeSpell, "cast","number", (nCast+1));
      bHadCharge = true;
    else
      --bHadCharge = false;
      bHadCharge = true; -- we let the effect happen and just spam with text error
      local sFormat = Interface.getString("message_nouseleft");
      local sMsg = string.format(sFormat, DB.getValue(nodeSpell, "name", ""));
      ChatManager.Message(sMsg, true, ActorManager.resolveActor( nodeChar));            
    end
  end

    return bHadCharge;
end

-- remove memorized spell slot
function removeMemorizedSpell(node)
--UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","node",node);
  -- we remove spells from casting the spell OR from the 
  -- quick actions/buttons so need to see where we are
  local nodeSpell = node; -- assume from quick buttons
  if node.getPath():match("%.actions%.") then
  -- we're casting the spell, so from within *.actions.*
    nodeSpell = node.getChild("...");
  end
--UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nodeSpell",nodeSpell);
  --local nodeSpell = node.getChild("...");
  if not nodeSpell then
    return;
  end
  local nodeChar = nodeSpell.getChild("...");
  if not nodeChar then
    return false;
  end
  local bSuccess = false;
  local nLevel = DB.getValue(nodeSpell, "level", 0);
  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local sSource = DB.getValue(nodeSpell, "source", ""):lower();
  local nMemorized_Total = DB.getValue(nodeSpell, "memorized_total", 0);
  local nMemorized = DB.getValue(nodeSpell, "memorized", 0);    
  
  if canMemorizeSpell(nodeSpell) then
    local nUsedArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0);
    local nMaxArcane  = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".max", 0);
    local nUsedDivine = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".used", 0);
    local nMaxDivine  = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. nLevel .. ".max", 0);

-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nMemorized_Total",nMemorized_Total);    
-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nMemorized",nMemorized);    
-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nUsedArcane",nUsedArcane);    
-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nMaxArcane",nMaxArcane);    
-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nUsedDivine",nUsedDivine);    
-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nMaxDivine",nMaxDivine);    
    -- we dont stop them from casting the spell but we do 
    -- spam text that they didnt have it memorized
    if (nMemorized_Total <= 0) then
      -- total is 0 or less, removed any lingering memorized spells if they exist
      DB.setValue(nodeSpell,"memorized","number",0);
      -- didnt have any more memorized copies of the spell to cast
      --bSuccess = false;
      local sChatText = string.format(Interface.getString("message_notmemorized"),DB.getValue(nodeChar,"name",""));
      ChatManager.Message(sChatText, true, ActorManager.resolveActor( nodeChar));
      --bSuccess = true;
    elseif nMemorized_Total >= 1 then -- we make sure we have spell slots to remove here...
      DB.setValue(nodeSpell,"memorized_total","number",(nMemorized_Total-1));
      if (isArcaneSpellType(sSpellType) or isArcaneSpellType(sSource)) then
        local nLeftOver = (nUsedArcane - 1);
        if nLeftOver < 0 then nLeftOver = 0; end
        DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",nLeftOver);
      elseif (isDivineSpellType(sSpellType) or isDivineSpellType(sSource)) then
        local nLeftOver = (nUsedDivine - 1);
        if nLeftOver < 0 then nLeftOver = 0; end
        DB.setValue(nodeChar,"powermeta.pactmagicslots" .. nLevel .. ".used","number",nLeftOver);
      end
      DB.setValue(nodeSpell,"memorized","number",(nMemorized-1));
      bSuccess = true;
    end
    
  else
    ChatManager.SystemMessage(string.format(Interface.getString("message_notaspelltoremove"), DB.getValue(nodeChar, "name", "")));
  end
  return bSuccess;
end

-- cast memorized spell
function castMemorizedSpell(node)
--UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","node",node);
  -- we remove spells from casting the spell OR from the 
  -- quick actions/buttons so need to see where we are
  local nodeSpell = node; -- assume from quick buttons
  if node.getPath():match("%.actions%.") then
  -- we're casting the spell, so from within *.actions.*
    nodeSpell = node.getChild("...");
  end
  if not nodeSpell then
    return;
  end
  local nodeChar = nodeSpell.getChild("...");
  if not nodeChar then
    return false;
  end

  local bSuccess = true;
  local bisNPC = (not ActorManager.isPC(nodeChar));
  --local nLevel = DB.getValue(nodeSpell, "level", 0);
  --local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  --local sSource = DB.getValue(nodeSpell, "source", ""):lower();
  local nMemorized = DB.getValue(nodeSpell, "memorized", 0);
  --local nMemorized_Total = DB.getValue(nodeSpell, "memorized_total", 0);

-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nMemorized",nMemorized);
-- UtilityManagerADND.logDebug("manager_power.lua","removeMemorizedSpell","nMemorized_Total",nMemorized_Total);
    
  -- this should let 5e spells work
  if canMemorizeSpell(nodeSpell) then
    -- we dont stop them from casting the spell but we do 
    -- spam text that they didnt have it memorized
    if (nMemorized <= 0 and not bisNPC and not Session.IsHost) then
      -- didnt have any more memorized copies of the spell to cast
      --bSuccess = false;
      local sChatText = string.format(Interface.getString("message_notmemorized"),DB.getValue(nodeChar,"name",""));
      ChatManager.Message(sChatText, true, ActorManager.resolveActor( nodeChar));
    end
    -- we make sure we have spell slots to remove here...
    if nMemorized >= 1 then
      DB.setValue(nodeSpell,"memorized","number",(nMemorized-1));
    end
  end
  return bSuccess;
end


-- return true if spelltype is valid arcane spell type
function isArcaneSpellType(sSpellType)
  local bValid = false;
  
  for _,sArcaneName in pairs(DataCommonADND.arcaneSpellClasses) do
    if string.find(sSpellType:lower(),sArcaneName) then
      bValid = true;
      break;
    end
  end
  return bValid
end
function isDivineSpellType(sSpellType)
  local bValid = false;
  for _,sDivineName in pairs(DataCommonADND.divineSpellClasses) do
    if string.find(sSpellType:lower(),sDivineName) then
      bValid = true;
      break;
    end
  end
  return bValid
end
function isPsionicPowerType(sSpellType)
  local sTypeLower = sSpellType:lower();
  local bValid = sTypeLower:match("psionic");
  return bValid
end

-- bits of code to sort out level for duration values
function getLevelBasedDurationValue(nodeAction)
  local nodeCaster = nodeAction.getChild(".....");
  local rActor = ActorManager.resolveActor( nodeCaster);
  local isPC = (ActorManager.isPC(nodeCaster));    
  local nDurationValue = DB.getValue(nodeAction, "durvalue", 0);
  local nCasterLevel = 1;
  local nMultiplier = 0;
  local sCasterType = DB.getValue(nodeAction, "castertype", "");
  local nCasterMax = DB.getValue(nodeAction, "castermax", 20);
  local nodeSpell = nodeAction.getChild("...");
  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
--UtilityManagerADND.logDebug("manager_power.lua","getLevelBasedDurationValue","nodeAction",nodeAction);  
  if (sSpellType:match("arcane")) then
    nCasterLevel = DB.getValue(nodeCaster, "arcane.totalLevel",1);
  elseif (sSpellType:match("divine")) then
    nCasterLevel = DB.getValue(nodeCaster, "divine.totalLevel",1);
  elseif (sSpellType:match("psionic")) then
    nCasterLevel = DB.getValue(nodeCaster, "psionic.totalLevel",1);
  else
    if (isPC) then
      nCasterLevel = CharManager.getActiveClassMaxLevel(nodeCaster);
    else
      nCasterLevel = DB.getValue(nodeCaster, "level",1);
    end
  end
  -- get sSpellType "ARCANE: X" effect modifier?
  local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rActor, {sSpellType:upper()}, false);
  if nEffectCount > 0 then
    local nAddTotal = StringManager.evalDice(aAddDice, nAddMod);
    nCasterLevel = nCasterLevel + nAddTotal;
  end
  
--UtilityManagerADND.logDebug("manager_power.lua","getLevelBasedDurationValue","nodeCaster",nodeCaster);  
--UtilityManagerADND.logDebug("manager_power.lua","getLevelBasedDurationValue","nCasterLevel",nCasterLevel);  

  -- if castertype ~= "" then setup the dice
  if (sCasterType ~= nil) then
    -- make sure dice count is not larger than max size
    if nCasterMax > 0 and nCasterLevel > nCasterMax then
      nCasterLevel = nCasterMax;
    end
    -- match the caster level number on end of string
    local sCasterLevel = sCasterType:match("casterlevelby(%d+)");
    if sCasterType == "casterlevel" then
      nMultiplier = nCasterLevel;
    elseif sCasterLevel then
      local nDividedBy = tonumber(sCasterLevel) or 1;
      nMultiplier = math.floor(nCasterLevel/nDividedBy);      
    else
      nMultiplier = 1;
    end
    -- all that to now multiple durationValue * level
    if (nMultiplier>0 and nDurationValue > 0) then
      nDurationValue = (nMultiplier * nDurationValue);
    end
  end
  -- end sort out level for dice count

  return nDurationValue;
end

-- psionic nonsense
function getActionDamagePSP(rActor, nodeAction)
  if not nodeAction then
    return {};
  end

  local nodeCaster = ActorManager.getCreatureNode(rActor);
  
  local clauses = {};
  local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeAction, "damagepsplist"));
  for _,v in ipairs(aDamageNodes) do
    local sDmgAbility = DB.getValue(v, "stat", "");
    local sDmgType = DB.getValue(v, "type", "");
    
    local nodeCaster = ActorManager.getCreatureNode(rActor);
    local nDmgMod, aDmgDice = getLevelBasedDiceValues(nodeCaster,ActorManager.isPC(rActor), nodeAction, v)
    
    local nDmgStatMod;
    nDmgStatMod, sDmgAbility = getGroupDamageHealBonus(rActor, nodeAction, sDmgAbility);
    nDmgMod = nDmgMod + nDmgStatMod;

    table.insert(clauses, { dice = aDmgDice, stat = sDmgAbility, modifier = nDmgMod, dmgtype = sDmgType });
  end

  return clauses;
end

function getActionDamagePSPText(nodeAction)
  local nodeActor = nodeAction.getChild(".....")
  local rActor = ActorManager.resolveActor( nodeActor);

  local clauses = PowerManager.getActionDamagePSP(rActor, nodeAction);
  
--UtilityManagerADND.logDebug("manager_power.lua","getActionDamagePSPText","clauses",clauses);
  
  local aOutput = {};
  local aDamage = ActionDamagePSP.getDamageStrings(clauses);
  for _,rDamage in ipairs(aDamage) do
    local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
    if sDice ~= "" then
      if rDamage.sType ~= "" then
        table.insert(aOutput, string.format("%s %s", sDice, rDamage.sType));
      else
        table.insert(aOutput, sDice);
      end
    end
  end
  
  return table.concat(aOutput, " + ");
end

function getActionHealPSP(rActor, nodeAction)
  if not nodeAction then
    return;
  end
  
  local clauses = {};
  local aHealNodes = UtilityManager.getSortedTable(DB.getChildren(nodeAction, "healpsplist"));
  for _,v in ipairs(aHealNodes) do
    local sAbility = DB.getValue(v, "stat", "");
    -- local aDice = DB.getValue(v, "dice", {});
    -- local nMod = DB.getValue(v, "bonus", 0);

    local nodeCaster = ActorManager.getCreatureNode(rActor);
    local nMod,aDice = getLevelBasedDiceValues(nodeCaster,ActorManager.isPC(rActor), nodeAction, v)
    
    local nStatMod;
    nStatMod, sAbility = getGroupDamageHealBonus(rActor, nodeAction, sAbility);
    nMod = nMod + nStatMod;
    
    
    table.insert(clauses, { dice = aDice, stat = sAbility, modifier = nMod });
  end

  return clauses;
end


function getActionHealPSPText(nodeAction)
  local nodeActor = nodeAction.getChild(".....")
  local rActor = ActorManager.resolveActor( nodeActor);

  local clauses = PowerManager.getActionHealPSP(rActor, nodeAction);
  
  local aHealDice = {};
  local nHealMod = 0;
  for _,vClause in ipairs(clauses) do
    for _,vDie in ipairs(vClause.dice) do
      table.insert(aHealDice, vDie);
    end
    nHealMod = nHealMod + vClause.modifier;
  end
  
  --UtilityManagerADND.logDebug("manager_power.lua","getActionHealPSPText","aHealDice",aHealDice);
  
  local sHeal = StringManager.convertDiceToString(aHealDice, nHealMod);
  if DB.getValue(nodeAction, "healtype", "") == "temp" then
    sHeal = sHeal .. " temporary";
  end
  
  local sTargeting = DB.getValue(nodeAction, "healtargeting", "");
  if sTargeting == "self" then
    sHeal = sHeal .. " [SELF]";
  end
  
  return sHeal;
end

-- get the casterlevel for sSpellType (arcane,divine or type from spell)
function getCasterLevelByType(nodeCaster,sSpellType,bIsPC)
  local rActor = ActorManager.resolveActor( nodeCaster);
--UtilityManagerADND.logDebug("manager_power.lua","getCasterLevelByType","nodeCaster",nodeCaster);  
--UtilityManagerADND.logDebug("manager_power.lua","getCasterLevelByType","sSpellType",sSpellType);  
--UtilityManagerADND.logDebug("manager_power.lua","getCasterLevelByType","bIsPC",bIsPC);  
  local nCasterLevel = 1;
  sSpellType = sSpellType:lower();
  -- if spelltype set to a number we use that as the "caster level"
  if sSpellType:match("^%d+$") then
    nCasterLevel = tonumber(sSpellType) or 1;
  else
    if (sSpellType:match("arcane")) then
      -- local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rActor, {"ARCANELEVEL"}, false);
      nCasterLevel = DB.getValue(nodeCaster, "arcane.totalLevel",1);
    elseif (sSpellType:match("divine")) then
      -- local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rActor, {"DIVINELEVEL"}, false);
      nCasterLevel = DB.getValue(nodeCaster, "divine.totalLevel",1);
    elseif (sSpellType:match("psionic")) then
      -- local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rActor, {"PSIONICLEVEL"}, false);
      nCasterLevel = DB.getValue(nodeCaster, "psionic.totalLevel",1);
    elseif (bIsPC) then
      -- use spelltype name and match it with class and return that level
      nCasterLevel = CharManager.getClassLevelByName(nodeCaster,sSpellType);
      if (nCasterLevel <= 0) then
        nCasterLevel = 1;
      end
      -- if (nCasterLevel <= 0) then
        -- nCasterLevel = CharManager.getActiveClassMaxLevel(nodeCaster);
      -- end
    elseif (not bIsPC) then -- npcs default to their HD/level
      nCasterLevel = DB.getValue(nodeCaster, "level",1);
    end
    
    -- get sSpellType "ARCANE: X" effect modifier?
    local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rActor, {sSpellType:upper()}, false);
    if nEffectCount > 0 then
      local nAddTotal = StringManager.evalDice(aAddDice, nAddMod);
      nCasterLevel = nCasterLevel + nAddTotal;
    end
  end -- sSpellType == Number
    
    --UtilityManagerADND.logDebug("manager_power.lua","getCasterLevelByType","nCasterLevel",nCasterLevel);  
  return nCasterLevel;
end

-- return castertype sGroupName
function getGroupCasterType(nodeCaster,sGroupName)
  sCasterType = nil;
  for _,nodeGroup in pairs(DB.getChildren(nodeCaster, "powergroup")) do
    local sGroup = DB.getValue(nodeGroup, "name", "");
    if sGroupName:lower() == sGroup:lower() then
      sCasterType = DB.getValue(nodeGroup,"castertype","");
      break;
    end
  end
  return sCasterType;
end

