-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function isArmor(vRecord)
--UtilityManagerADND.logDebug("manager_item2.lua","isArmor","vRecord",vRecord);  
  local bIsArmor = false;

  local nodeItem;
  if type(vRecord) == "string" then
    nodeItem = DB.findNode(vRecord);
  elseif type(vRecord) == "databasenode" then
    nodeItem = vRecord;
  end
  if not nodeItem then
    return false, "", "";
  end
  
  local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
  local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

  if StringManager.contains(DataCommonADND.itemArmorTypes, sTypeLower) then
    bIsArmor = true;
  end
  if StringManager.contains(DataCommonADND.itemArmorTypes, sSubtypeLower) then
    bIsArmor = true;
  end
  if isShield(vRecord) then
    bIsArmor = true;
  end
  -- these are not armor, they are cloak/ring/robe
  -- if isProtectionOther(vRecord) then
  --   bIsArmor = true;
  -- end
  return bIsArmor, sTypeLower, sSubtypeLower;
end

-- shields
function isShield(vRecord)
  local bIsArmor = false;

  local nodeItem;
  if type(vRecord) == "string" then
    nodeItem = DB.findNode(vRecord);
  elseif type(vRecord) == "databasenode" then
    nodeItem = vRecord;
  end
  if not nodeItem then
    return false, "", "";
  end
  
  local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
  local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();
  if StringManager.contains(DataCommonADND.itemShieldArmorTypes, sTypeLower) then
    bIsArmor = true;
  end
  if StringManager.contains(DataCommonADND.itemShieldArmorTypes, sSubtypeLower) then
    bIsArmor = true;
  end
  return bIsArmor, sTypeLower, sSubtypeLower;
end


-- ring/cloak/robe
function isProtectionOther(vRecord)
  local bIsArmor = false;

  local nodeItem;
  if type(vRecord) == "string" then
    nodeItem = DB.findNode(vRecord);
  elseif type(vRecord) == "databasenode" then
    nodeItem = vRecord;
  end
  if not nodeItem then
    return false, "", "";
  end
  
  local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
  local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

  if StringManager.contains(DataCommonADND.itemOtherArmorTypes, sTypeLower) then
    bIsArmor = true;
  end
  if StringManager.contains(DataCommonADND.itemOtherArmorTypes, sSubtypeLower) then
    bIsArmor = true;
  end
  return bIsArmor, sTypeLower, sSubtypeLower;
end

-- is this a warding type of armor, bracers of defense/etc. Works with magic rings/cloaks basically
function isWarding(vRecord)
  local bWarding = false;

  local nodeItem;
  if type(vRecord) == "string" then
    nodeItem = DB.findNode(vRecord);
  elseif type(vRecord) == "databasenode" then
    nodeItem = vRecord;
  end
  if not nodeItem then
    return false, "", "";
  end
  
  local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
  local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

  if isItemAnyType("warding",sTypeLower,sSubtypeLower) then
    bWarding = true;
  end
  return bWarding, sTypeLower, sSubtypeLower;
end

function isWeapon(vRecord)
  local bIsWeapon = false;

  local nodeItem;
  if type(vRecord) == "string" then
    nodeItem = DB.findNode(vRecord);
  elseif type(vRecord) == "databasenode" then
    nodeItem = vRecord;
  end
  if not nodeItem then
    return false, "", "";
  end
  
  local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
  local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

  if (sTypeLower == "weapon") or (sSubtypeLower == "weapon") then
    bIsWeapon = true;
  end
  if sSubtypeLower == "ammunition" then
    bIsWeapon = false;
  end
  
  -- if it has objects in weaponlist node then it's a weapon
  if DB.getChildCount(nodeItem, "weaponlist") > 0 then
    bIsWeapon = true;
  end
  
  return bIsWeapon, sTypeLower, sSubtypeLower;
end

function isRefBaseItemClass(sClass)
	return StringManager.contains({"reference_armor", "reference_weapon", "reference_equipment", "reference_mountsandotheranimals", "reference_waterbornevehicles", "reference_vehicle"}, sClass);
end

function addItemToList2(sClass, nodeSource, nodeTarget, nodeTargetList)
--UtilityManagerADND.logDebug("manager_item2.lua","addItemToList2","sClass",sClass);
  if LibraryData.isRecordDisplayClass("item", sClass) then
    --if sClass == "reference_equipment" and DB.getChildCount(nodeSource, "subitems") > 0 then
    if DB.getChildCount(nodeSource, "subitems") > 0 then
      local bFound = false;
      for _,v in pairs(DB.getChildren(nodeSource, "subitems")) do
        local sSubClass, sSubRecord = DB.getValue(v, "link", "", "");
        local nSubCount = DB.getValue(v, "count", 1);
        if LibraryData.isRecordDisplayClass("item", sSubClass) then
          local nodeNew = ItemManager.addItemToList(nodeTargetList, sSubClass, sSubRecord);
          if nodeNew then
            bFound = true;
            if nSubCount > 1 then
              DB.setValue(nodeNew, "count", "number", DB.getValue(nodeNew, "count", 1) + nSubCount - 1);
            end
          end
        end
      end
      if bFound then
        return false;
      end
    end
    
    DB.copyNode(nodeSource, nodeTarget);
    DB.setValue(nodeTarget, "locked", "number", 1);

    -- Set the identified field
    if ((sClass == "reference_magicitem") and (not Session.IsHost)) then
      DB.setValue(nodeTarget, "isidentified", "number", 0);
    else
      DB.setValue(nodeTarget, "isidentified", "number", 1);
    end
      
    return true;
  end

  return false;
end

-- check to see if the armor worn by nodeChar is magic
function isWearingMagicArmor(nodeChar)
  local bMagic = false;
  local nodeMagicArmor = nil;
  for _,nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
    if DB.getValue(nodeItem, "carried", 0) == 2 then
      local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
      local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();
      local bIsArmor, _, _ = ItemManager2.isArmor(nodeItem);
      
      if bIsArmor and isItemAnyType("magic",sTypeLower,sSubtypeLower) then
        bMagic = true;
        nodeMagicArmor = nodeItem;
        break;
      end
    end
  end
  return bMagic, nodeMagicArmor;
end
-- check to see if a shield is equipped
function isWearingShield(nodeChar)
  local bShield = false;
  local nodeShield = nil;
  for _,nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
    if DB.getValue(nodeItem, "carried", 0) == 2 then
      local bIsShield, _, _ = ItemManager2.isShield(nodeItem);
      if bIsShield then
        bShield = true;
        nodeShield = nodeItem;
        break;
      end
    end
  end
  
  return bShield,nodeShield;
end

-- check to see if the armor worn by nodeChar matches sArmorCheck="plate,chain,leather"
function isWearingArmorNamed(nodeChar, aArmorTypeList)
-- UtilityManagerADND.logDebug("manager_item2.lua","isWearingArmorNamed","aArmorTypeList",aArmorTypeList);      
    local bMatch = false;
    local aArmorList = getArmorWorn(nodeChar);
     for _,sType in ipairs(aArmorTypeList) do
      sType = sType:lower();
      if UtilityManagerADND.containsAny(aArmorList, sType) then
        bMatch = true;
      end
    end

    return bMatch;
end

-- get a list of all the armor worn by this node
function getArmorWorn(nodeChar)
  local aArmorListNames = {};
  local aArmorNodesList = {};
  for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
    if DB.getValue(vNode, "carried", 0) == 2 then
-- UtilityManagerADND.logDebug("manager_item2.lua","getArmorWorn","vNode",DB.getValue(vNode,"name"));           
      local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(vNode);
-- UtilityManagerADND.logDebug("manager_item2.lua","getArmorWorn","bIsArmor",bIsArmor);           
      if bIsArmor then
        local sName = DB.getValue(vNode,"name",""):lower();
        table.insert(aArmorListNames, sName);    
        table.insert(aArmorNodesList, vNode);    
      end
    end
  end

  -- we scan the inventorylist_node list of nodes on the source NPC for armor/equipped items.
  local aItemNodes = UtilityManagerADND.getItemNodeListFromNPCinCT(nodeChar);
  for _,sItemNode in pairs(aItemNodes) do 
    -- this is on the NPC source record if it exists and where we look. It wont exist on the npc entry in the CT
    local nodeCheck = DB.findNode(sItemNode);
    if nodeCheck then
-- UtilityManagerADND.logDebug("manager_item2.lua","getArmorWorn","nodeCheck",DB.getValue(nodeCheck,"name"));           
      local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(nodeCheck);
-- UtilityManagerADND.logDebug("manager_item2.lua","getArmorWorn","nodeCheck bIsArmor",bIsArmor);            
      if bIsArmor then
        local sName = DB.getValue(nodeCheck,"name",""):lower();
        table.insert(aArmorListNames, sName);    
        table.insert(aArmorNodesList, nodeCheck);    
      end
    end
  end
  --
  return aArmorListNames, aArmorNodesList;
end

-- get a list of all the items equipped worn by this node
function getItemsEquipped(nodeChar)
  local aItemsEquipped = {};
  for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
    if DB.getValue(vNode, "carried", 0) == 2 then
      local sName = DB.getValue(vNode,"name",""):lower();
      table.insert(aItemsEquipped, sName);    
    end
  end
  --
  return aItemsEquipped;
end

function isItemType(sCheckType,sType)
  return (sType == sCheckType);
end
function isItemSubType(sCheckType,sSubType)
  return (sSubType == sCheckType);
end
function isItemAnyType(sCheckType,sType,sSubType)
  return (sType == sCheckType or sSubType == sCheckType);
end

