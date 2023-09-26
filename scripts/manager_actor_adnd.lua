-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--[[
  Originally sources from 5E and last compared during the v2021-11-15 update of 5e --celestian
]]
function onInit()
  ActorHealthManager.isDyingOrDeadStatus = isDyingOrDeadStatus_adnd;
  initActorHealth();
end

--[[
  Had to override this function because they do static comparisions and our sStatus can be Dying (#)  there # has a number is in.
]]
function isDyingOrDeadStatus_adnd(sStatus)
  local lowerStatus = string.lower(sStatus)
  return string.find(lowerStatus, "dead") or string.find(lowerStatus, "dying") or string.find(lowerStatus, "destroyed")
end

function initActorHealth()
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_UNCONSCIOUS, ColorManager.COLOR_HEALTH_DYING_OR_DEAD);

	ActorHealthManager.getWoundPercent = getWoundPercent;
end

function getWoundPercent(rActor)
  local sNodeType, node = ActorManager.getTypeAndNode(rActor);
  local nHP = 0;
  local nWounds = 0;
-- UtilityManagerADND.logDebug("manager_actor_adnd.lua","getWoundPercent","sNodeType",sNodeType);
  if sNodeType == "pc" then
    nHP = math.max(DB.getValue(node, "hp.total", 0), 0);
    nWounds = math.max(DB.getValue(node, "hp.wounds", 0), 0);
  elseif sNodeType == "ct" then
    nHP = math.max(DB.getValue(node, "hptotal", 0), 0);
    nWounds = math.max(DB.getValue(node, "wounds", 0), 0);
  end
  
  local nPercentWounded = 0;
  if nHP > 0 then
    nPercentWounded = nWounds / nHP;
  end
  
  local bDeathsDoor = OptionsManager.isOption("HouseRule_DeathsDoor", "on"); -- using deaths door aD&D rule
  local sStatus = ActorHealthManager.STATUS_HEALTHY;
  local nLeftOverHP = (nHP - nWounds);
    -- AD&D goes to -10 then dead with deaths door
  local nDEAD_AT = -10;
  if not bDeathsDoor then
    nDEAD_AT = 0;
  end
  if nPercentWounded >= 1 then
   -- had to remove the hasEffect() checks as it caused a recursive loop with
   -- the new Aura system
    --if nLeftOverHP <= nDEAD_AT or EffectManager5E.hasEffect(rActor, "Dead") then
    if nLeftOverHP <= nDEAD_AT then
      sStatus = ActorHealthManager.STATUS_DEAD;
      --    elseif EffectManager5E.hasEffect(rActor, "Stable") then
      --      sStatus = "Unconscious";
    else
      sStatus = ActorHealthManager.STATUS_DYING;
    end
    if nLeftOverHP < 1 then
        sStatus = sStatus .. " (" .. nLeftOverHP .. ")";
    end
	elseif OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= .75 then
			sStatus = ActorHealthManager.STATUS_CRITICAL;
		elseif nPercentWounded >= .5 then
			sStatus = ActorHealthManager.STATUS_HEAVY;
		elseif nPercentWounded >= .25 then
			sStatus = ActorHealthManager.STATUS_MODERATE;
		elseif nPercentWounded > 0 then
			sStatus = ActorHealthManager.STATUS_LIGHT;
		else
			sStatus = ActorHealthManager.STATUS_HEALTHY;
		end
	else
		if nPercentWounded >= .5 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_HEAVY;
		elseif nPercentWounded > 0 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_WOUNDED;
		else
			sStatus = ActorHealthManager.STATUS_HEALTHY;
		end
	end
  return nPercentWounded, sStatus;
end

function getWoundPercentPSP(rActor)
  local sNodeType, node = ActorManager.getTypeAndNode(rActor);
  local nHP = 0;
  local nWounds = 0;
-- UtilityManagerADND.logDebug("manager_actor_adnd.lua","getWoundPercent","sNodeType",sNodeType);
  if sNodeType == "pc" then
    nHP = math.max(DB.getValue(node, "combat.psp.score", 0), 0);
    nWounds = math.max(DB.getValue(node, "combat.psp.expended", 0), 0);
  -- elseif sNodeType == "ct" then
  --   nHP = math.max(DB.getValue(node, "hptotal", 0), 0);
  --   nWounds = math.max(DB.getValue(node, "wounds", 0), 0);
  end
  
  local nPercentWounded = 0;
  if nHP > 0 then
    nPercentWounded = nWounds / nHP;
  end
  
  local sStatus = ActorHealthManager.STATUS_HEALTHY;
  local nLeftOverHP = (nHP - nWounds);
  if nPercentWounded >= 1 then
    if nLeftOverHP <= 0 then
      sStatus = "Opened";
    else
      if not EffectManager5E.hasEffect(rActor, "OpenedMind") then
        sStatus = "OpenedMind";
      end
      if nLeftOverHP < 1 then
        sStatus = sStatus .. " (" .. nLeftOverHP .. ")";
      end
    end
	elseif OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= .75 then
			sStatus = ActorHealthManager.STATUS_CRITICAL;
		elseif nPercentWounded >= .5 then
			sStatus = ActorHealthManager.STATUS_HEAVY;
		elseif nPercentWounded >= .25 then
			sStatus = ActorHealthManager.STATUS_MODERATE;
		elseif nPercentWounded > 0 then
			sStatus = ActorHealthManager.STATUS_LIGHT;
		else
			sStatus = ActorHealthManager.STATUS_HEALTHY;
		end
	else
		if nPercentWounded >= .5 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_HEAVY;
		elseif nPercentWounded > 0 then
			sStatus = ActorHealthManager.STATUS_SIMPLE_WOUNDED;
		else
			sStatus = ActorHealthManager.STATUS_HEALTHY;
		end
	end
  
  return nPercentWounded, sStatus;
end


function getClassLevel(nodeActor, sValue)
  local sClassName = DataCommon.class_valuetoname[sValue];
  if not sClassName then
    return 0;
  end
  sClassName = sClassName:lower();
  
  for _, vNode in pairs(DB.getChildren(nodeActor, "classes")) do
    if DB.getValue(vNode, "name", ""):lower() == sClassName then
      return DB.getValue(vNode, "level", 0);
    end
  end
  
  return 0;
end

function getAbilityScore(rActor, sAbility)
  if not sAbility then
    return -1;
  end
  local nodeActor = ActorManager.getCreatureNode(rActor);
  if not nodeActor then
    return -1;
  end
  
  local nStatScore = -1;
  
  local sShort = string.sub(string.lower(sAbility), 1, 3);
  if sShort == "lev" then
    nStatScore = DB.getValue(nodeActor, "level", 0);
  elseif sShort == "prf" then
    nStatScore = DB.getValue(nodeActor, "profbonus", 0);
  elseif sShort == "str" then
    nStatScore = DB.getValue(nodeActor, "abilities.strength.score", 0);
  elseif sShort == "dex" then
    nStatScore = DB.getValue(nodeActor, "abilities.dexterity.score", 0);
  elseif sShort == "con" then
    nStatScore = DB.getValue(nodeActor, "abilities.constitution.score", 0);
  elseif sShort == "int" then
    nStatScore = DB.getValue(nodeActor, "abilities.intelligence.score", 0);
  elseif sShort == "wis" then
    nStatScore = DB.getValue(nodeActor, "abilities.wisdom.score", 0);
  elseif sShort == "cha" then
    nStatScore = DB.getValue(nodeActor, "abilities.charisma.score", 0);
  elseif StringManager.contains(DataCommon.classes, sAbility) then
    nStatScore = getClassLevel(nodeActor, sAbility);
  end
  
  return nStatScore;
end

-- sAbility "strength, dexterity, constitution/etc"
-- sType "hitadj, damageadj, saveadj, defenseadj
function getAbilityBonus(rActor, sAbility, sType)
  local nAbilityAdj = 0;
  
  if not sType then
   return 0;
  end

  if not sAbility then
   return 0;
  end

  local nodeActor = ActorManager.getCreatureNode(rActor);
  if not nodeActor then
    return 0;
  end

  local nStatScore = getAbilityScore(rActor, sAbility);
  if nStatScore < 0 then
    return 0;
  end
  
  if sType then
    if (sType == "hitadj") then
      local nHitAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".hitadj", 0);
      nAbilityAdj = nHitAdj;
    elseif (sType == "damageadj") then
      local nDamageAdj = 0;
      if (sAbility == "strength") then
        nDamageAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".dmgadj", 0);
      end
      nAbilityAdj = nDamageAdj;
    elseif (sType == "defenseadj") then
      local nDefAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".defenseadj", 0);
      nAbilityAdj = nDefAdj;
    elseif (sType == "reactionadj") then
      local nReactionAdj = DB.getValue(nodeActor, "abilities.".. sAbility .. ".reactionadj", 0);
      nAbilityAdj = nReactionAdj;
    end
  end

  return nAbilityAdj;
end

function getSave(rActor, sSave)
--UtilityManagerADND.logDebug("manager_actor_adnd.lua","getSave","sSave",sSave);
  local bADV = false;
  local bDIS = false;
  local nValue = getAbilityBonus(rActor, sSave, "saveadj");
  local nValue = 0;
  local aAddText = {};
  
  local nodeActor = ActorManager.getCreatureNode(rActor);
  if ActorManager.isPC(rActor) then
    nValue = DB.getValue(nodeActor, "saves." .. sSave .. ".modifier", 0);
  else
    -- need to get save value for npcs someday 
    local sSaves = DB.getValue(nodeActor, "savingthrows", "");
    for _,v in ipairs(StringManager.split(sSaves, ",;\r", true)) do
      local sAbility, sSign, sMod = string.match(v, "(%w+)%s*([%+%-–]?)(%d+)");
      if sAbility then
        if DataCommon.ability_stol[sAbility:upper()] then
          sAbility = DataCommon.ability_stol[sAbility:upper()];
        elseif DataCommon.ability_ltos[sAbility:lower()] then
          sAbility = sAbility:lower();
        else
          sAbility = nil;
        end
        
        if sAbility == sSave then
          nValue = tonumber(sMod) or 0;
          if sSign == "-" or sSign == "–" then
            nValue = 0 - nValue;
          end
          break;
        end
      end
    end
  end
  
  return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

function getCheck(rActor, sCheck, sSkill)
  local bADV = false;
  local bDIS = false;
  local nValue = getAbilityBonus(rActor, sCheck, "check");
  local aAddText = {};

  return nValue, bADV, bDIS, table.concat(aAddText, " ");
end


-- this is to convert decending AC (below MAC 10 stuff) to ascending AC
-- 20 - (-5) = 25, 20 - 5 = 15 and so on
function convertToAscendingAC(nDefense)
  if (nDefense < 10) then
    nDefense = (20 - nDefense);
  end
  return nDefense;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
  local nDefense = 10;
  local bPsionic = false;
  
  if (rRoll) then -- need to get defense value from psionic power
    bPsionic = rRoll.bPsionic == "true";
    if (bPsionic) then
      nDefense = tonumber(rRoll.Psionic_MAC) or 10;
      nDefense = convertToAscendingAC(nDefense);
    end
  end

  if not rDefender and rRoll and bPsionic then -- no defender but psionic power target
    return nDefense, 0, 0, false, false;
  elseif not rDefender or not rRoll then
    return nil, 0, 0, false, false;
  end
  

  -- Base calculations
  local sAttack = rRoll.sDesc;
  
  local sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]");
  local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]");
  local nCover = tonumber(string.match(sAttack, "%[COVER %-(%d)%]")) or 0;
  local bRearAtk = string.match(sAttack, "%[REAR%]");
  
  local bNoDex = ModifierStack.getModifierKey("ATK_NODEXTERITY");
  local bNoShield = ModifierStack.getModifierKey("ATK_SHIELDLESS");
  local bIgnoreArmor = ModifierStack.getModifierKey("ATK_IGNORE_ARMOR");
  
  -- Effects
  local nAttackEffectMod = 0;
  local nDefenseEffectMod = 0;
  local bADV = false;
  local bDIS = false;
  
  local sDefenseStat = "dexterity";

  local bIsPC = ActorManager.isPC(rDefender);
  local nodeDefender = ActorManager.getCreatureNode(rDefender);
  if not nodeDefender then
    return nil, 0, 0, false, false;
  end

  if bPsionic then -- calculate defenses for psionics
    if rRoll.Psionic_DisciplineType:match("attack") then -- mental attack
      nDefense = DB.getValue(nodeDefender,"combat.mac.score",10);
      -- need to get effects/adjustments for MAC/BMAC/etc.
      -- grab BAC value if exists in effects
      local nBonusMACBase, nBonusMACBaseEffects = EffectManager5E.getEffectsBonus(rDefender, "BMAC",true);
      if (nBonusMACBaseEffects > 0 and nBonusMACBase < nDefense) then
        nDefense = nBonusMACBase;
      end
      local nBonusMAC, nBonusMACEffects = EffectManager5E.getEffectsBonus(rDefender, "MAC",true);
      if (nBonusMACEffects > 0) then
        -- we minus the mod because +1 is good, -1 is bad, but lower MAC is better.
        nDefense = nDefense - nBonusMAC;
      end
    else -- using a power with a MAC
      nDefense = tonumber(rRoll.Psionic_MAC) or 10;
    end
    nDefense = convertToAscendingAC(nDefense);

    -- if psionic attack, check psionic defenses
    if rRoll.Psionic_DisciplineType == "attack" then
      local nodeSpell = DB.findNode(rRoll.sSpellSource);
      if (nodeSpell) then
        local sSpellName = DB.getValue(nodeSpell,"name",""):lower();
        if sSpellName ~= "" then 
          nAttackEffectMod = getPsionicAttackVersusDefenseMode(rDefender,rAttacker,sSpellName,nAttackEffectMod);
        end
      end
    end

  else -- calculate defenses for melee/range attacks
    local nACTemp = 0;
    local nACBase = 10;
    local nACArmor = 0;
    local nACShield = 0;
    local nACMisc = 0;
    
  --UtilityManagerADND.logDebug("manager_actor_adnd.lua","getDefenseValue","rRoll.range",rRoll.range);  

    local bAttackRanged = (rRoll.range and rRoll.range == "R");
    local bAttackMelee = (rRoll.range and rRoll.range == "M");

    local nBaseRangeAC = 10;
    local nRangeACEffect = 0;
    local nRangeACMod = 0;
    local nRangeACModEffect = 0;

    local nBaseMeleeAC = 10;
    local nMeleeACEffect = 0;
    local nMeleeACMod = 0;
    local nMeleeACModEffect = 0;
    
    -- grab BAC value if exists in effects
    local nBonusACBase, nBonusACEffects = EffectManager5E.getEffectsBonus(rDefender, "BAC",true);

    if (bAttackMelee) then
      nBaseMeleeAC, nMeleeACEffect = EffectManager5E.getEffectsBonus(rDefender, "BMELEEAC",true);
      nMeleeACMod, nMeleeACModEffect = EffectManager5E.getEffectsBonus(rDefender, "MELEEAC",true);
    end
    
    if (bAttackRanged) then
      nBaseRangeAC, nRangeACEffect = EffectManager5E.getEffectsBonus(rDefender, "BRANGEAC",true);
      nRangeACMod, nRangeACModEffect = EffectManager5E.getEffectsBonus(rDefender, "RANGEAC",true);
    end
    
    local bProne = false;
    local bParalyzed = false;
    local bRestrainedStunned = false;
    if EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) then
      bParalyzed = true;
    end
    if EffectManager5E.hasEffect(rDefender, "Prone", rAttacker) then
      bProne = true;
    end
    if EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
      bRestrainedStunned = true;
    end
    if EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) then
      bRestrainedStunned = true;
    end
    if EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) then
      bProne = true;
    end
    
    -- if PC
    if bIsPC then
      nACTemp = DB.getValue(nodeDefender, "defenses.ac.temporary",0);
      nACBase = DB.getValue(nodeDefender, "defenses.ac.base",10);
      nACArmor = DB.getValue(nodeDefender, "defenses.ac.armor",0);
      nACShield = DB.getValue(nodeDefender, "defenses.ac.shield",0);
      nACMisc = DB.getValue(nodeDefender, "defenses.ac.misc",0);

    if bIgnoreArmor then
      nDefense = 10;
    else
      nDefense = nACBase;
    end
    
    else
      -- ELSE NPC

      -- FGU API returns null if "ac" is 0 for players... API not being changed so just going to set default to 0 with all
      -- the confusion that comes with that.
      -- See thread: https://www.fantasygrounds.com/forums/showthread.php?74469-Issue-getting-data-from-CT-entry

      nDefense = DB.getValue(nodeDefender, "ac",0);

    end

    -- use BAC style effects if exist
    if nBonusACEffects > 0 then
      if nBonusACBase < nDefense then
        nDefense = nBonusACBase;
      end
    end
    if (bAttackMelee and nMeleeACEffect > 0) then
      if (nBaseMeleeAC < nDefense) then
        nDefense = nBaseMeleeAC;
      end
    end
    if (bAttackRanged and nRangeACEffect > 0) then
      if (nBaseRangeAC < nDefense) then
        nDefense = nBaseRangeAC;
      end
    end
    if (bAttackMelee and nMeleeACModEffect > 0) then
      nACTemp = nACTemp + (nACTemp - nMeleeACMod); -- (minus the mod, +3 is good, so we reduce AC by 3, -3 would be worse)
    end
    if (bAttackRanged and nRangeACModEffect > 0) then
      nACTemp = nACTemp + (nACTemp - nRangeACMod); -- (minus the mod, +3 is good, so we reduce AC by 3, -3 would be worse)
    end
    -- 
    
    if bIsPC then
      -- dont get shield bonus if you attacked from rear
      -- check to see if casting, noshield while casting
      -- or if you are prone
      if bNoShield or bRearAtk or bProne or bParalyzed or bRestrainedStunned or 
        --ActionSave.hasConcentrationEffects(rDefender) or 
        EffectManager5E.hasEffect(rDefender, "NOSHIELD", nil) or 
        EffectManager5E.hasEffect(rDefender, "SHIELDLESS", nil) or 
        EffectManager5E.hasEffect(rDefender, "Charged", nil) then
        nDefense = nDefense + nACTemp + nACArmor + nACMisc;
      else
        nDefense = nDefense + nACTemp + nACArmor + nACShield + nACMisc;
      end
    else -- npc
      nDefense = nDefense + nACTemp; -- nACTemp are "modifiders"
    end
    
  --UtilityManagerADND.logDebug("manager_actor_adnd.lua","getDefenseValue","nDefense",nDefense);
    
    -- disable NPC's ability to adjust AC from DEX. Set their AC in the NPC AC field
    -- if "NODEX" effect set we ignore dex in AC calculation
    if bIsPC then
      -- check to see if casting or if has NODEX effect, if so dont apply dex AC
      -- if attacking from rear no dex! if prone, they get no dex.
      -- also, make sure modifier
      if bNoDex or bRearAtk or bProne or bParalyzed or bRestrainedStunned or 
          ActionSave.hasConcentrationEffects(rDefender) or 
          EffectManager5E.hasEffect(rDefender, "BLINDED", nil) or 
          EffectManager5E.hasEffect(rDefender, "Charged", nil) or 
          EffectManager5E.hasEffect(rDefender, "NODEX", nil) or 
          EffectManager5E.hasEffect(rDefender, "NO-DEXTERITY", nil) then
      -- dont apply dex in these cases
      else
      -- apply dex
        local nDefenseStatMod = getAbilityBonus(rDefender, sDefenseStat, "defenseadj");
--UtilityManagerADND.logDebug("manager_actor_adnd.lua","getDefenseValue","nDefenseStatMod",nDefenseStatMod);        
        nDefense = nDefense + nDefenseStatMod;
      end
    end
      
    -- flip ac to ascending since rest of the code uses ascending AC (but we show decending).
    -- this is just to make things easier sharing code with 5E. 
    -- Mathmatically it's the same and display shows what AD&Ders expect.
    nDefense = convertToAscendingAC(nDefense);
    --
    
    if ActorManager.hasCT(rDefender) then
      local nBonusStat = 0;
      local nBonusSituational = 0;
      local nBonusAC = 0;
      
      local aAttackFilter = {};
      if sAttackType == "M" then
        table.insert(aAttackFilter, "melee");
      elseif sAttackType == "R" then
        table.insert(aAttackFilter, "ranged");
      end
      if bOpportunity then
        table.insert(aAttackFilter, "opportunity");
      end

      local aBonusTargetedAttackDice, nBonusTargetedAttack = EffectManager5E.getEffectsBonus(rAttacker, "ATK", false, aAttackFilter, rDefender, true);
      nAttackEffectMod = nAttackEffectMod + StringManager.evalDice(aBonusTargetedAttackDice, nBonusTargetedAttack);
            
      local aACEffects, nACEffectCount = EffectManager5E.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
      for _,v in pairs(aACEffects) do
        nBonusAC = nBonusAC + v.mod;
      end
      
      -- minus 1 ac because the charged.
      if EffectManager5E.hasEffect(rDefender, "Charged", nil) then
        nBonusAC = nBonusAC -1;
      end
      if EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
        nBonusAC = nBonusAC + 4;
      end
      
      -- this makes DEX: -3 worsen AC by 3, wtf... 5e code?
      --
      -- nBonusStat = getAbilityEffectsBonus(rDefender, sDefenseStat);
      --
      -- if we ever remove the persistant stat for ability scores 
      -- and go to "effect check" only then we'll need to revisit this.
      
      -- AC is 4 worse when blinded
      if EffectManager5E.hasEffect(rDefender, "BLINDED", nil) then
        nBonusAC = nBonusAC - 4;
      end
 
      -- encumbrance penalties
      --local sRank = CharManager.getEncumbranceRank2e(nodeDefender);
      local sRank = DB.getValue(nodeDefender,"speed.encumbrancerank","");
      if sRank == "Heavy" then
        nBonusAC = nBonusAC -1;
      elseif sRank == "Severe" or sRank == "MAX" then
        nBonusAC = nBonusAC -3;
      end
      
      nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
    end
    
  end -- end if bPsionic
  
-- UtilityManagerADND.logDebug("manager_actor_adnd.lua","getDefenseValue","nDefense",nDefense);
-- UtilityManagerADND.logDebug("manager_actor_adnd.lua","getDefenseValue","nAttackEffectMod",nAttackEffectMod);
-- UtilityManagerADND.logDebug("manager_actor_adnd.lua","getDefenseValue","nDefenseEffectMod",nDefenseEffectMod);

  -- Results
  return nDefense, nAttackEffectMod, nDefenseEffectMod;
end

function isAlignment(rActor, sAlignCheck)
  local nCheckLawChaosAxis = 0;
  local nCheckGoodEvilAxis = 0;
  local aCheckSplit = StringManager.split(sAlignCheck:lower(), " ", true);
  for _,v in ipairs(aCheckSplit) do
    if nCheckLawChaosAxis == 0 and DataCommon.alignment_lawchaos[v] then
      nCheckLawChaosAxis = DataCommon.alignment_lawchaos[v];
    end
    if nCheckGoodEvilAxis == 0 and DataCommon.alignment_goodevil[v] then
      nCheckGoodEvilAxis = DataCommon.alignment_goodevil[v];
    end
  end
  if nCheckLawChaosAxis == 0 and nCheckGoodEvilAxis == 0 then
    return false;
  end
  
  local nActorLawChaosAxis = 2;
  local nActorGoodEvilAxis = 2;
  local nodeActor = ActorManager.getCreatureNode(rActor);
  local sField = "alignment";
  local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), " ", true);
  for _,v in ipairs(aActorSplit) do
    if nActorLawChaosAxis == 2 and DataCommon.alignment_lawchaos[v] then
      nActorLawChaosAxis = DataCommon.alignment_lawchaos[v];
    end
    if nActorGoodEvilAxis == 2 and DataCommon.alignment_goodevil[v] then
      nActorGoodEvilAxis = DataCommon.alignment_goodevil[v];
    end
  end
  
  local bLCReturn = true;
  if nCheckLawChaosAxis > 0 then
    if nActorLawChaosAxis > 0 then
      bLCReturn = (nActorLawChaosAxis == nCheckLawChaosAxis);
    else
      bLCReturn = false;
    end
  end
  
  local bGEReturn = true;
  if nCheckGoodEvilAxis > 0 then
    if nActorGoodEvilAxis > 0 then
      bGEReturn = (nActorGoodEvilAxis == nCheckGoodEvilAxis);
    else
      bGEReturn = false;
    end
  end
  
  return (bLCReturn and bGEReturn);
end

function isSize(rActor, sSizeCheck)
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","rActor",rActor)
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","sSizeCheck",sSizeCheck)

  local sSizeCheckLower = StringManager.trim(sSizeCheck:lower());

  local sCheckOp = sSizeCheckLower:match("^[<>]?=?");
  if sCheckOp then
    sSizeCheckLower = StringManager.trim(sSizeCheckLower:sub(#sCheckOp + 1));
  end
  
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","sCheckOp",sCheckOp)
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","sSizeCheckLower",sSizeCheckLower)

  local nCheckSize = 0;
  if DataCommon.creaturesize[sSizeCheckLower] then
    nCheckSize = DataCommon.creaturesize[sSizeCheckLower];
  end
  if nCheckSize == 0 then
    return false;
  end
  
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","nCheckSize",nCheckSize)

  local nActorSize = 0;
  local nodeActor = ActorManager.getCreatureNode(rActor);
  local sField = "size";
  local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), " ", true);

  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","aActorSplit",aActorSplit)

  for _,v in ipairs(aActorSplit) do
    
    -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","v",v)
    -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","DataCommon.creaturesize[v]",DataCommon.creaturesize[v])

    if nActorSize == 0 and DataCommon.creaturesize[v] then
      nActorSize = DataCommon.creaturesize[v];
      break;
    end
  end
  if nActorSize == 0 then
    nActorSize = 3;
  end
  
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","nActorSize",nActorSize)

  local bReturn = true;
  if sCheckOp then
    if sCheckOp == "<" then
      bReturn = (nActorSize < nCheckSize);
    elseif sCheckOp == ">" then
      bReturn = (nActorSize > nCheckSize);
    elseif sCheckOp == "<=" then
      bReturn = (nActorSize <= nCheckSize);
    elseif sCheckOp == ">=" then
      bReturn = (nActorSize >= nCheckSize);
    else
      bReturn = (nActorSize == nCheckSize);
    end
  else
    bReturn = (nActorSize == nCheckSize);
  end
  
  -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isSize","bReturn",bReturn)

  return bReturn;
end

function getCreatureTypeHelper(sTypeCheck, bUseDefaultType)
  local aCheckSplit = StringManager.split(sTypeCheck:lower(), ", %(%)", true);
  
  local aTypeCheck = {};
  local aSubTypeCheck = {};
  
  -- Handle half races
  local nHalfRace = 0;
  for k = 1, #aCheckSplit do
    if aCheckSplit[k]:sub(1, #DataCommon.creaturehalftype) == DataCommon.creaturehalftype then
      aCheckSplit[k] = aCheckSplit[k]:sub(#DataCommon.creaturehalftype + 1);
      nHalfRace = nHalfRace + 1;
    end
  end
  if nHalfRace == 1 then
    if not StringManager.contains (aCheckSplit, DataCommon.creaturehalftypesubrace) then
      table.insert(aCheckSplit, DataCommon.creaturehalftypesubrace);
    end
  end
  
  -- Check each word combo in the creature type string against standard creature types and subtypes
  for k = 1, #aCheckSplit do
    for _,sMainType in ipairs(DataCommon.creaturetype) do
      local aMainTypeSplit = StringManager.split(sMainType, " ", true);
      if #aMainTypeSplit > 0 then
        local bMatch = true;
        for i = 1, #aMainTypeSplit do
          if aMainTypeSplit[i] ~= aCheckSplit[k - 1 + i] then
            bMatch = false;
            break;
          end
        end
        if bMatch then
          table.insert(aTypeCheck, sMainType);
          k = k + (#aMainTypeSplit - 1);
        end
      end
    end
    for _,sSubType in ipairs(DataCommon.creaturesubtype) do
      local aSubTypeSplit = StringManager.split(sSubType, " ", true);
      if #aSubTypeSplit > 0 then
        local bMatch = true;
        for i = 1, #aSubTypeSplit do
          if aSubTypeSplit[i] ~= aCheckSplit[k - 1 + i] then
            bMatch = false;
            break;
          end
        end
        if bMatch then
          table.insert(aSubTypeCheck, sSubType);
          k = k + (#aSubTypeSplit - 1);
        end
      end
    end
  end
  
  -- Make sure we have a default creature type (if requested)
  if bUseDefaultType then
    if #aTypeCheck == 0 then
      table.insert(aTypeCheck, DataCommon.creaturedefaulttype);
    end
  end
  
  -- Combine into a single list
  for _,vSubType in ipairs(aSubTypeCheck) do
    table.insert(aTypeCheck, vSubType);
  end
  
  return aTypeCheck;
end

function isCreatureType(rActor, sTypeCheck)
  -- I dont like having static list of types
  --local aTypeCheck = getCreatureTypeHelper(sTypeCheck, false);
  -- so ... just split on comma
  local aTypeCheck = StringManager.split(sTypeCheck:lower(), ",", true);

  if #aTypeCheck == 0 then
    return false;
  end
  local nodeActor = ActorManager.getCreatureNode(rActor);
  local sField = "race";
  if not ActorManager.isPC(rActor) then
    sField = "type";
  end

  -- I dont like having static list of types
  --local aTypeActor = getCreatureTypeHelper(DB.getValue(nodeActor, sField, ""), true);
  -- so split on comma and go.
  local sTypeString = DB.getValue(nodeActor, sField, "")
  local aTypeActor = StringManager.split(sTypeString:lower(), ",", true);
  local bReturn = false;
  for kCheck,vCheck in ipairs(aTypeCheck) do
    if StringManager.contains(aTypeActor, vCheck) then
      bReturn = true;
      break;
    end
  end
--UtilityManagerADND.logDebug("manager_actor_adnd","isCreatureType","bReturn",bReturn);  
  return bReturn;
end

-- get a attack modifier value with an attack type versus a defense type
function getPsionicAttackVersusDefenseMode(rDefender,rAttacker,sSpellName,nAttackEffectMod)
  local nAttackMod = nAttackEffectMod;
  local nAtkIndex = getPsionicAttackIndex(sSpellName);
  local nDefIndex = getPsionicDefenseIndex(rDefender,rAttacker);
  if (nAtkIndex > 0 and nDefIndex > 0) then
    -- get the modifier for the attack type versus index using psionic_attack_v_defense_table
    local nAdjustment = DataCommonADND.psionic_attack_v_defense_table[nAtkIndex][nDefIndex];
    nAttackMod = nAttackMod + nAdjustment;
  end
  return nAttackMod;
end
--get the psionic attack index # of this attack name
function getPsionicAttackIndex(sName)
  local nIndex = 0;
  for sValue,index in pairs(DataCommonADND.psionic_attack_index) do
    if (sValue == sName) then
      nIndex = index;
      break;
    end
  end

  return nIndex;
end
--flip through all of the psionic defenses and find (first) one that is
--exists in the defense psionic_defense_index and return it's index. 
function getPsionicDefenseIndex(rDefender,rAttacker)
  local nIndex = 0;
  for sValue,index in pairs(DataCommonADND.psionic_defense_index) do
    if EffectManager5E.hasEffect(rDefender, sValue, rAttacker) then
      nIndex = index;
      break;
    end
  end

  return nIndex;
end

-- check to see if the armor worn by rActor matches sArmorCheck
function isArmorType(rActor, sArmorCheck)
    local bMatch = false;
    --local nodeActor = ActorManager.getCreatureNode(rActor);
    local _, nodeActor = ActorManager.getTypeAndNode(rActor);
    local aCheckSplit = StringManager.split(sArmorCheck:lower(), ",", true);
    local aArmorList = ItemManager2.getArmorWorn(nodeActor);
     for _,v in ipairs(aCheckSplit) do
      -- v==armor type
       if StringManager.contains(aArmorList, v) then
        bMatch = true;
       end
    end

    return bMatch;
end
-- return any targets a Combat Tracker node currently has.
function getTargetNodes(rActor)
    local nodeCT = ActorManager.getCTNode(rActor);
    local aTargetRefs = {};
    if (nodeCT ~= nil) then
      local nodeTargets = DB.getChildren(nodeCT,"targets");
      for _,node in pairs(nodeTargets) do
        local sNodeRef = DB.getValue(node,"noderef","");
        local nodeRef = DB.findNode(sNodeRef);
        if nodeRef ~= nil then
          table.insert(aTargetRefs,nodeRef.getPath());
        end
      end
    end -- nodeCT != nil
    return aTargetRefs;
end
-- check to see if the rActor has sClassCheck
function isClassType(rActor, sClassCheck)
    local bMatch = false;
    --local nodeActor = ActorManager.getCreatureNode(rActor);
    local _, nodeActor = ActorManager.getTypeAndNode(rActor);
    local aCheckSplit = StringManager.split(sClassCheck:lower(), ",", true);
     for _,v in ipairs(aCheckSplit) do
      -- v==class name
       if CharManager.hasClass(nodeActor,v) then
        bMatch = true;
       end
    end

    return bMatch;
end

--[[

Get range between rActor's targets and return true of in nRange

]]
function isRangeBetween(rActor,rTarget, nRange) 
  -- UtilityManagerADND.logDebug("manager_actor_adnd","isRangeBetween","rActor",rActor)
  -- UtilityManagerADND.logDebug("manager_actor_adnd","isRangeBetween","rTarget",rTarget)
  -- UtilityManagerADND.logDebug("manager_actor_adnd","isRangeBetween","nRange",nRange)

  local bResult = false;
  if (rTarget) then
    local sourceCT = ActorManager.getCTNode(rActor);
    local targetCT = ActorManager.getCTNode(rTarget);
    local tokenTarget = CombatManager.getTokenFromCT(targetCT);
    local tokenSource = CombatManager.getTokenFromCT(sourceCT);
    local nDistanceBetween = TokenManagerADND.getTokenDistanceBetween(tokenSource,tokenTarget);
    bResult = nDistanceBetween <= nRange;

    -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isRangeBetween","nDistanceBetween",nDistanceBetween)
    -- UtilityManagerADND.logDebug("manager_actor_adnd.lua","isRangeBetween","bResult",bResult)

  end
  return bResult;
end
