--
--
--
--

---
-- Various tools for managing actions (weapons)
---

--[[
    return dmgadj values for all profs attached to weapon
]] 
function getToDamageProfs(nodeWeapon)
  -- UtilityManagerADND.logDebug("manager_weapons.adnd.lua","getToDamageProfs","nodeWeapon",nodeWeapon);
    local nMod = 0;
    for _,v in pairs(DB.getChildren(nodeWeapon, "proflist")) do
      nMod = nMod + DB.getValue(v, "dmgadj", 0)
    end
    return nMod;
end
  
--[[
    get all the +hit modifiers from the profs 
    attached to this weapon
]]
function getToHitProfs(nodeWeapon)
    local nodeChar = nodeWeapon.getChild("...");
    local bisPC = (ActorManager.isPC(nodeChar)); 
    local nMod = 0;
    -- if no profs applied to weapon, then assume they use
    -- non-proficiency penalty with it
    if (bisPC and DB.getChildCount(nodeWeapon,"proflist")< 1) then 
      -- only pc's get a non-weapon_prof penalty
      nMod = DB.getValue(nodeChar,"proficiencies.weapon.penalty",0);
    else
      for _,v in pairs(DB.getChildren(nodeWeapon, "proflist")) do
        nMod = nMod + DB.getValue(v, "hitadj", 0)
      end
    end
    return nMod;
  end

  
--[[
    Return sDMG text for nodeDamage when updated
]]
function onDamageChanged(nodeDamage)
    local nodeWeapon = nodeDamage.getChild("...");
    local nodeChar = nodeWeapon.getChild("...");
    local rActor = ActorManager.resolveActor( nodeChar);
    local nMod = DB.getValue(nodeDamage, "bonus", 0);
  
    local nType = DB.getValue(nodeWeapon,"type",0);
    local sBaseAbility = "strength";
    if nType == 1 then
      sBaseAbility = "dexterity";
    end
  
    local sAbility = DB.getValue(nodeDamage, "stat", "");
    if sAbility == "base" or sAbility == "" then
      sAbility = sBaseAbility;
    end
  
    if sAbility ~= "none" and rActor then
      nMod = nMod + ActorManagerADND.getAbilityBonus(rActor, sAbility, "damageadj");
    end
    
    nMod = nMod + getToDamageProfs(nodeWeapon);
    local aDice = DB.getValue(nodeDamage, "dice", {});
    local sDamage = StringManager.convertDiceToString(DB.getValue(nodeDamage, "dice", {}), nMod);
    local sDMG = sDamage;
    local sType = DB.getValue(nodeDamage, "type", "");
    if sType ~= "" then
      sDamage = sDamage .. " " .. sType;
    end
  
    -- take first letter of each type in the damage type string and uppercase it for compact view.
    local aTypes = StringManager.split(sType,",",true);
    local sTypeLetters = "";
    if #aTypes > 0 then
      sTypeLetters = " ";
    end
    for nCount, sAType in pairs(aTypes) do
      local sSep = ",";
      if nCount >= #aTypes then
        sSep = "";
      end
      sTypeLetters = sTypeLetters .. string.upper(sAType:sub(1,1)) .. sSep;
    end

    return sDMG .. sTypeLetters, "Damage from attack: " .. sDamage ;
  end
  
  --[[
        Return the atk value
  ]]
  function onAttackChanged(nodeWeapon)
    local nodeChar = nodeWeapon.getChild("...");
    local rActor = ActorManager.resolveActor( nodeChar);
    local sAbility = DB.getValue(nodeWeapon, "attackstat", "");
    local nType = DB.getValue(nodeWeapon, "type",0);
    if sAbility == "" then
      if nType == 1 then
        sAbility = "dexterity";
      else
        sAbility = "strength";
      end
    end
  
    local nMod = DB.getValue(nodeWeapon, "attackbonus", 0) + ActorManagerADND.getAbilityBonus(rActor, sAbility, "hitadj");
    nMod = nMod + getToHitProfs(nodeWeapon);

    local sReturn = "";
    if nMod ~= 0 then
        sReturn = " " .. UtilityManagerADND.getNumberSign(nMod);
    end
    
    return sReturn;
  end

--[[

]]
function buildAttackAction(rActor,nodeWeapon)

  -- add weapon data to attack for reference
  -- UtilityManagerADND.logDebug("manager_weapons.adnd.lua","buildAttackAction","nodeWeapon",nodeWeapon);
  local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
  rActor.itemPath = sRecord;  

  local rAction = {};
    
  local aWeaponProps = StringManager.split(DB.getValue(nodeWeapon, "properties", ""):lower(), ",", true);
  
  --[[ This will make sure the weapon name only shows if the item is identified. NPCs items never show. ]]
  local bItemIdentified = (DB.getValue(nodeWeapon, "isidentified",1) == 1); 
  if bItemIdentified and ActorManager.isPC(rActor) then
    rAction.label = DB.getValue(nodeWeapon, "name","");
  else    
    rAction.label = DB.getValue(nodeWeapon, "nonid_name",DB.getValue(nodeWeapon, "name",""));
  end
  

  rAction.stat = DB.getValue(nodeWeapon, "attackstat", "");
  local nType = DB.getValue(nodeWeapon, "type",0);
  if nType == 2 then
    rAction.range = "R";
    if rAction.stat == "" then
      rAction.stat = "strength";
    end
  elseif nType == 1 then
    rAction.range = "R";
    if rAction.stat == "" then
      rAction.stat = "dexterity";
    end
  else
    rAction.range = "M";
    if rAction.stat == "" then
      rAction.stat = "strength";
    end
  end
  rAction.modifier = DB.getValue(nodeWeapon, "attackbonus", 0) + ActorManagerADND.getAbilityBonus(rActor, rAction.stat, "hitadj");
  
  rAction.modifier = rAction.modifier + getToHitProfs(nodeWeapon);
    
  rAction.bWeapon = true;
  
  -- Decrement ammo
  local nMaxAmmo = DB.getValue(nodeWeapon, "maxammo", 0);
  if nMaxAmmo > 0 then
    local nUsedAmmo = DB.getValue(nodeWeapon, "ammo", 0);
    if nUsedAmmo >= nMaxAmmo then
      ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
    else
      DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + 1);
    end
  end
  
  local nodeChar = nodeWeapon.getChild("...")

  -- Determine crit range
	local nCritThreshold = getCritRange(nodeChar, nodeWeapon);
	if nCritThreshold > 1 and nCritThreshold < 20 then
		rAction.nCritRange = nCritThreshold;
	end
  
  return rAction;
end

--[[

]]
function getRange(nodeWeapon)
	local nType = DB.getValue(nodeWeapon, "type", 0);
	if (nType == 1) or (nType == 2) then
		return "R";
	end
	return "M";
end

--[[

]]
function getPropertyNumber(v, sTargetPattern)
	local sProp = getProperty(v, sTargetPattern);
	if sProp then
		return tonumber(sProp) or 0;
	end
	return nil;
end
--[[

]]
function getProperty(v, sTargetPattern)
	local sProperties;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sProperties = DB.getValue(v, "properties", "");
	elseif sVarType == "string" then
		sProperties = v;
	else
		return nil;
	end

	local tProps = StringManager.split(sProperties:lower(), ",", true);
	for _,s in ipairs(tProps) do
		local result = s:match("^" .. sTargetPattern);
		if result then
			return result;
		end
	end
	return nil;
end
--[[

]]
WEAPON_PROP_CRITRANGE = "crit range %(?(%d+)%)?";
function getCritRange(nodeChar, nodeWeapon)
	local nCritThreshold = 20;

	if getRange(nodeWeapon) == "R" then
		nCritThreshold = DB.getValue(nodeChar, "weapon.critrange.ranged", 20);
	else
		nCritThreshold = DB.getValue(nodeChar, "weapon.critrange.melee", 20);
	end

	-- Check for crit range property
	local nPropCritRange = getPropertyNumber(nodeWeapon, WEAPON_PROP_CRITRANGE);
	if nPropCritRange and nPropCritRange < nCritThreshold then
		nCritThreshold = nPropCritRange;
	end

	return nCritThreshold;
end
--[[

]]
function onAttackAction(draginfo,rActor,nodeWeapon)
  
  local rAction = buildAttackAction(rActor,nodeWeapon);

  ActionAttack.performRoll(draginfo, rActor, rAction);
  
  return true;
end

--[[

]]
function buildDamageAction(rActor, nodeDamage)
  -- UtilityManagerADND.logDebug("manager_weapons.adnd.lua","buildDamageAction","nodeDamage",nodeDamage);

  local nodeWeapon = nodeDamage.getParent().getParent();

  -- UtilityManagerADND.logDebug("manager_weapons.adnd.lua","buildDamageAction","nodeWeapon",nodeWeapon);

  -- add weapon data to attack for reference
  local _, sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
  rActor.itemPath = sRecord;

  -- rActor.itemPath = nodeWeapon.getPath();
    
  local aWeaponProps = StringManager.split(DB.getValue(nodeWeapon, "properties", ""):lower(), ",", true);
  
  local rAction = {};
  rAction.bWeapon = true;
  rAction.label = DB.getValue(nodeWeapon, "name", "");
  local nType = DB.getValue(nodeWeapon,"type",0);
  if nType == 0 then
    rAction.range = "M";
  else
    rAction.range = "R";
  end

  local sBaseAbility = "strength";
  if nType == 1 then
    sBaseAbility = "dexterity";
  end
  
  rAction.clauses = {};
    
  local sDmgAbility = DB.getValue(nodeDamage, "stat", "");
  if sDmgAbility == "base" or sDmgAbility == "" then
      sDmgAbility = sBaseAbility;
  end
  local aDmgDice = DB.getValue(nodeDamage, "dice", {});
  local nDmgMod = DB.getValue(nodeDamage, "bonus", 0) + ActorManagerADND.getAbilityBonus(rActor, sDmgAbility, "damageadj");
  local sDmgType = DB.getValue(nodeDamage, "type", "");
  
  nDmgMod = nDmgMod + getToDamageProfs(nodeWeapon);
  
  -- this will check the properties on the weapon and apply addition damage types found
  local aWeaponDamageTypes = StringManager.split(sDmgType,",",true);
  for _,sProp in ipairs(aWeaponProps) do
    if StringManager.contains(DataCommon.dmgtypes, sProp) and 
        not StringManager.contains(aWeaponDamageTypes, sProp) then
      table.insert(aWeaponDamageTypes, sProp);
    end
  end
  sDmgType = table.concat(aWeaponDamageTypes,", ");
  --
  
  table.insert(rAction.clauses, { dice = aDmgDice, stat = sDmgAbility, modifier = nDmgMod, dmgtype = sDmgType });

  -- Check for reroll tag in weapon's properties
  local nReroll = 0;
  for _,vProperty in ipairs(aWeaponProps) do
    local nPropReroll = tonumber(vProperty:match("reroll (%d+)")) or 0;
    if nPropReroll > nReroll then
      nReroll = nPropReroll;
    end
  end
  if nReroll > 0 then
    rAction.label = rAction.label .. " [REROLL " .. nReroll .. "]";
  end
  
  return rAction;
end  
  --[[

]]
function onDamageActionSingle(draginfo,rActor,nodeDamage)
--UtilityManagerADND.logDebug("manager_Weapons_adnd.lua","onDamageActionSingle","draginfo",draginfo);          
--UtilityManagerADND.logDebug("manager_Weapons_adnd.lua","onDamageActionSingle","rActor1",rActor);          
  local rAction = buildDamageAction(rActor,nodeDamage);

  ActionDamage.performRoll(draginfo, rActor, rAction);
  return true;
end

--[[

]]
function builtInitiativeItem(nodeWeapon)
  local sName = DB.getValue(nodeWeapon,"name","");
  local nSpeedFactor = DB.getValue(nodeWeapon,"speedfactor",0);
  
  local rItem = {};
  rItem.sName = sName;
  rItem.nInit = nSpeedFactor;

  return rItem;
end

function onInitiative(draginfo,rActor,nodeAction)
  local rItem = builtInitiativeItem(nodeAction);
  ActionInit.performRoll(draginfo, rActor, nil, rItem);	
end