-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
-- function onInit()

  -- local node = window.windowlist.window.getDatabaseNode();
  -- local bShowDetails = (node.getPath():match("^charsheet%.") ~= nil or node.getPath():match("^npc%.") ~= nil or node.getPath():match("^combattracker%.") ~= nil);
-- UtilityManagerADND.logDebug("power_group_header","node",node)       
-- UtilityManagerADND.logDebug("power_group_header","bShowDetails",bShowDetails)       
  -- link.setVisible(bShowDetails);

-- end

-- make sure we're in a NPC/PC/CT view of the item list before we show the "details" button.
function inValidSheet()
  local node = windowlist.window.getDatabaseNode();
  local bShowDetails = (node.getPath():match("^charsheet%.id%-%d+$") ~= nil or node.getPath():match("^npc%.id%-%d+$") ~= nil or node.getPath():match("^combattracker%.list%.id%-%d+$") ~= nil);
  return bShowDetails;
end

function onToggle()
  windowlist.onHeaderToggle(self);
end

local bFilter = true;
function setFilter(bNewFilter)
  bFilter = bNewFilter;
end
function getFilter()
  return bFilter;
end

local nodeGroup = nil;
function setNode(node)
  nodeGroup = node;
  if nodeGroup and inValidSheet() then
    link.setVisible(true);
  else
    link.setVisible(false);
  end
end
function getNode()
  return nodeGroup;
end

function deleteGroup()
  if nodeGroup then
    nodeGroup.delete();
  end
end

function setHeaderCategory(rGroup, sGroup, nLevel, bAllowDelete)
  local sIconName = "char_spells";
  
  if sGroup == "" then
    name.setValue(Interface.getString("char_label_powers"));
    name.setIcon("char_abilities_orange");
  else
    if rGroup.grouptype ~= "" then
      if not nLevel then
        name.setValue(sGroup);
      elseif nLevel == 0 then
        name.setValue(sGroup .. " (" .. Interface.getString("power_label_groupcantrips") .. ")");
      else
        name.setValue(sGroup .. " (" .. Interface.getString("level") .. " " .. nLevel .. ")");
      end
      if sGroup:match("Psionic") then 
        sIconName = "char_psion";
      end
      name.setIcon(sIconName);
      level.setValue(nLevel);
    else
      name.setValue(sGroup);
      name.setIcon("char_abilities_orange");
    end
    group.setValue(sGroup);
    setNode(rGroup.node);
    if bAllowDelete then
      idelete.setVisibility(true);
    end
  end
end

