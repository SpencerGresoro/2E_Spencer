--
--
--
--
function onInit()
  local node = getDatabaseNode();
  DB.addHandler(DB.getPath(node, "isidentified"), "onUpdate", updateForID);
  
  if not string.match(node.getPath(),"^charsheet") and not Session.IsHost then
    return;
  end        
  updateForID();
end
      
function onClose()
  local node = getDatabaseNode();
  DB.removeHandler(DB.getPath(node, "isidentified"), "onUpdate", updateForID);
end

function updateControl(sControl, bID)
  if not self[sControl] then
    return false;
  end

  self[sControl].setVisible(bID);
  self[sControl .. '_label'].setVisible(bID);
  
  return self[sControl].isVisible();
end

-- hide name/properties on items not identified.
function updateForID()
  local nodeRecord = getDatabaseNode();
  local bID = (Session.IsHost or LibraryData.getIDState("item", nodeRecord, true));
  
  
  updateControl("name", bID);
  updateControl("properties", bID);
  updateControl("attackbonus", bID);
  label_atkplus.setVisible(bID);
end 

-- allows drag/drop of dice to damage and profs to apply
function onDrop(x, y, draginfo)
  local sDragType = draginfo.getType();
  local sClass = draginfo.getShortcutData();
  if sDragType == "dice" then
    local w = list.addEntry(true);
    for _, vDie in ipairs(draginfo.getDiceData()) do
      w.dice.addDie(vDie.type);
    end
    return true;
  elseif sDragType == "number" then
    local w = list.addEntry(true);
    w.bonus.setValue(draginfo.getNumberData());
    return true;
  -- add prof to weapon
  elseif sDragType == "shortcut" and draginfo.getShortcutData() == "ref_proficiency_item" then
    local nodeWeapon = getDatabaseNode();
    local nodeProfDragged = draginfo.getDatabaseNode();
    local sProfSelected = DB.getValue(nodeProfDragged,"name","");
    if not CombatManagerADND.weaponProfExists(nodeWeapon,sProfSelected) then
      local nodeProfList = DB.createChild(nodeWeapon,"proflist");
      local nodeProf = nodeProfList.createChild();
      DB.setValue(nodeProf,"prof","string",DB.getValue(nodeProfDragged,"name"));
      return true;
    end
  end
end
