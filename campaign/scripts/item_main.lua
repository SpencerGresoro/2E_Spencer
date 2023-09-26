-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  OptionsManager.registerCallback("OPTIONAL_ARMORDP", update);
  update();
end
function onClose()
end

function VisDataCleared()
  update();
end

function InvisDataAdded()
  update();
end

function updateControl(sControl, bReadOnly, bID)
  if not self[sControl] then
    return false;
  end

  -- added test because items have attacks now but not other features
  if not self[sControl].update then
    return false;
  end
  
  if not bID then
    return self[sControl].update(bReadOnly, true);
  end
  
  return self[sControl].update(bReadOnly);
end

function update()
  local nodeRecord = getDatabaseNode();
  local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
  local bID = LibraryData.getIDState("item", nodeRecord);
      
  local bWeapon, sTypeLower, sSubtypeLower = ItemManager2.isWeapon(nodeRecord);
  local bArmor = ItemManager2.isArmor(nodeRecord);
  local bOtherArmor = ItemManager2.isProtectionOther(nodeRecord);
  local bWarding = ItemManager2.isWarding(nodeRecord);
  -- item can contain list of items used as pre-made packs.
  local bIsPack = (sTypeLower == 'equipment packs' or sSubtypeLower == 'equipment packs');
  
  local bPlayer = (not Session.IsHost);
  local bHost = Session.IsHost;

  local bSection1 = false;
  if Session.IsHost then
    if updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
  else
    updateControl("nonid_name", false);
  end
  if (Session.IsHost or not bID) then
    if updateControl("nonidentified", bReadOnly, true) then bSection1 = true; end;
  else
    updateControl("nonidentified", false);
  end

  local bSection2 = false;
  if updateControl("type", bReadOnly, bID) then bSection2 = true; end
  type.setReadOnlyState(bReadOnly);
  type.setVisible((type.getValue() ~= "" or not bReadOnly));
  type_label.setVisible((type.getValue() ~= "" or not bReadOnly));
  bSection2 = (type.getValue() ~= "");
  if updateControl("subtype", bReadOnly, bID) then bSection2 = true; end
  if updateControl("rarity", bReadOnly, bID) then bSection2 = true; end
  subtype.setReadOnlyState(bReadOnly);
  subtype.setVisible((subtype.getValue() ~= "" or not bReadOnly) and bID);
  subtype_label.setVisible((subtype.getValue() ~= "" or not bReadOnly) and bID);
  rarity.setReadOnlyState(bReadOnly);
  rarity.setVisible((rarity.getValue() ~= "" or not bReadOnly) and bID);
  rarity_label.setVisible((rarity.getValue() ~= "" or not bReadOnly) and bID);

  local bSection3 = false;
  if updateControl("cost", bReadOnly, bID) then bSection3 = true; end
  if updateControl("exp", bReadOnly, bID) then bSection3 = true; end
  if updateControl("weight", bReadOnly, true) then bSection3 = true; end
  
  local bSection4 = false;
  
  if updateControl("bonus", bReadOnly, bID and (bWeapon or bArmor or bWarding or bOtherArmor)) then bSection4 = true; end
  --if updateControl("ac", bReadOnly, bID and (bArmor or bWarding)) then bSection4 = true; end
  if updateControl("acbase", bReadOnly, bID and (bArmor or bWarding)) then bSection4 = true; end
  if updateControl("armordp", bReadOnly, bID and (bArmor or bWarding)) then bSection4 = true; end
  if updateControl("armordp_damage", bReadOnly, bID and (bArmor or bWarding)) then bSection4 = true; end
  -- right now this is a host/DM only section (baseAC/bonus)
  --armor_base_label.setVisible(bHost and not bReadOnly);
  --armortype.setVisible(bHost and not bReadOnly);
  local bShowDefenseSection = (bArmor or bWarding or bOtherArmor) and bHost and not bReadOnly;
  header_armor_and_modifier.setVisible(bShowDefenseSection);
  acbase_label.setVisible((bArmor or bWarding) and bHost and not bReadOnly);
  acbase.setVisible((bArmor or bWarding) and bHost and not bReadOnly);
  label_bonus.setVisible(bShowDefenseSection);
  bonus.setVisible(bShowDefenseSection);

  -- if not optional rule enabled we hide it.
  if OptionsManager.getOption("OPTIONAL_ARMORDP") ~= 'on' then
    armordp.setVisible(false);
    armordp_label.setVisible(false);
    armordp_damage.setVisible(false);
    armordp_damage_label.setVisible(false);
  end

  if updateControl("properties", bReadOnly, bID and (bWeapon or bArmor or bWarding or bOtherArmor)) then bSection4 = true; end
  
  local bSection6 = false;
  if updateControl("dmonly", bReadOnly, bID and Session.IsHost) then bSection6 = true; end

  local bSection5 = bID;
  description.setVisible(bID);
  description.setReadOnly(bReadOnly);
  
  -- item is a pack item, contains other items for pre-made packages.
  subitems_header.setVisible(bIsPack);
  windowlist_subitems.setVisible(bIsPack);
  subitems_iedit.setVisible(bIsPack);
  -- make sure edit is disabled if can't see
  if (not bIsPack) then
    subitems_iedit.setValue(0);
  end
  
  divider.setVisible(bSection1 and bSection2);
  divider2.setVisible((bSection1 or bSection2) and bSection3);
  divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
    
end

--
-- Drag/drop functions for NPC MAIN page/tab
--
function onDrop(x, y, draginfo)
  
  if draginfo.isType("shortcut") then
    local sClass, sRecord = draginfo.getShortcutData();
    
    -- Control+Drag/Drop of another ITEM on this ITEM will replace that ITEM's contents
    -- with the one you've dropped.
    local nodeItem = getDatabaseNode();
    local bLocked = (DB.getValue(nodeItem,"locked",0) == 1);
    local nodeSource = draginfo.getDatabaseNode();
    if not bLocked and Input.isControlPressed() and nodeSource then
      if (sClass == "item") then
        UtilityManagerADND.logDebug("item_main.lua","onDrop","Replacing contents of :",nodeItem, "with :",nodeSource);
        DB.deleteChild(nodeItem,"weaponlist");
        DB.deleteChild(nodeItem,"powers");
        DB.deleteChild(nodeItem,"effectlist");
        DB.deleteChild(nodeItem,"link");
        DB.deleteChild(nodeItem,"powermeta");
        DB.copyNode(nodeSource,nodeItem);
        UtilityManagerADND.replaceWindow(self.parentcontrol.window, "item", nodeItem.getPath());
        -- end was item
      elseif (sClass == "encounter") then
        local sText = DB.getValue(nodeSource,"text");
        local sCurrentText = DB.getValue(nodeItem,"description");
        if sText then
          DB.setValue(nodeItem,"description","formattedtext",sCurrentText .. sText);
        end
      end -- encounter
    end -- not locked
  end -- was shortcut
end
