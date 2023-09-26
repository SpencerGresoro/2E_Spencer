-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  local node = getDatabaseNode();
--UtilityManagerADND.logDebug("cta_combatants_host.lua","onInit","node",node);

  --DB.addHandler(DB.getPath(node, "*.hp.wounds"), "onChildUpdate", updateHPBars);

  --DB.addHandler(DB.getPath(node, "*.effects"), "onChildAdded", updateForEffectsChange);
  DB.addHandler(DB.getPath(node, "*.effects"), "onChildDeleted", updateForEffectsChange);
  --DB.addHandler(DB.getPath(node, "*.effects"), "onChildUpdate", updateForEffectsChange);
  DB.addHandler(DB.getPath(node, "*.effects.*.label"), "onUpdate", updateEffectChange);
  DB.addHandler(DB.getPath(node, "*.effects.*.isactive"), "onUpdate", updateEffectChange);

  DB.addHandler(DB.getPath(node, "*.targets"), "onChildUpdate", toggleSelectedTargets);
  DB.addHandler(DB.getPath(node, "*.targets"), "onChildDeleted", toggleSelectedTargets);
  DB.addHandler(DB.getPath(node, "*.targets"), "onChildAdded", toggleSelectedTargets);

  local nCount = DB.getChildCount(node.getParent(),"list");
  -- we dont run this unless we actually have nodes otherwise it'll
  -- add filler nodes into combattracker.*
  if nCount > 0 then
    clearCombatantsSelectedTargetIcon();
    
    -- first time start of CT, clear selected
    --clearSelect();
    --onListChanged();
  end
end

function onClose()
  local node = getDatabaseNode();
  --UtilityManagerADND.logDebug("cta_combatants_host.lua","onClose","node",node);
  
  --DB.removeHandler(DB.getPath(node, "*.effects"), "onChildAdded", updateForEffectsChange);
  DB.removeHandler(DB.getPath(node, "*.effects"), "onChildDeleted", updateForEffectsChange);
  --DB.removeHandler(DB.getPath(node, "*.effects"), "onChildUpdate", updateForEffectsChange);
  DB.removeHandler(DB.getPath(node, "*.effects.*.label"), "onUpdate", updateEffectChange);
  DB.removeHandler(DB.getPath(node, "*.effects.*.isactive"), "onUpdate", updateEffectChange);

  DB.removeHandler(DB.getPath(node, "*.targets"), "onChildUpdate", toggleSelectedTargets);
  DB.removeHandler(DB.getPath(node, "*.targets"), "onChildDeleted", toggleSelectedTargets);
  DB.removeHandler(DB.getPath(node, "*.targets"), "onChildAdded", toggleSelectedTargets);
  --DB.removeHandler("combattracker.list", "onChildAdded", updateWindowlist);
end

--[[
  Filter tokens that are not ct.visible == 1 out from CT
]]
function onFilter(w)
--  UtilityManagerADND.logDebug("cta_combatants_host.lua","onFilter","w.getDatabaseNode()",w.getDatabaseNode());

  -- local bVisible = (DB.getValue(w.getDatabaseNode(), "ct.visible",1) == 1);
  -- if not bVisible then
  --   return false;
  -- else
  --   return true;
  -- end

  return true;
end

--[[
  update effects for this CT entry
]]
function processEffectChanges(nodeCT)
--local nodeCT = nodeEntry.getParent();
local nodeChar = CombatManagerADND.getNodeFromCT(nodeCT);

--UtilityManagerADND.logDebug("cta_combatants_host.lua","processEffectChanges","nodeEntry-------------------->",nodeCT);
--if UtilityManagerADND.rateLimitOK(processEffectChanges,nodeCT,0.95) then
-- need to figure out how to avoid doing these calls.
  -- Causes a LOT of latency
  AbilityScoreADND.detailsUpdate(nodeChar);
  AbilityScoreADND.detailsPercentUpdate(nodeChar);
  AbilityScoreADND.updateForEffects(nodeChar);
  --
--end

CharManager.updateHealthScore(nodeChar);
end

--[[
  combattracket.list.id-XXXXXX.effects.id-XXXXXX.label
  combattracket.list.id-XXXXXX.effects.id-XXXXXX.isactive
]]
function updateEffectChange(nodeEntry)
  --local nodeEffect = nodeEntry.getParent();
  local nodeCT = nodeEntry.getChild("....");
  processEffectChanges(nodeCT);
end

--[[
  Run when we delete a effect
]]
function updateForEffectsChange(nodeEntry)
  --UtilityManagerADND.logDebug("cta_combatants_host.lua","updateForEffectsChange","nodeEntry-------------------->",nodeEntry);
  processEffectChanges(nodeEntry.getParent());
end

-- toggle selected targets for entry selected/target changes
function toggleSelectedTargets(nodeTargets)
--UtilityManagerADND.logDebug("cta_combatants_host.lua","toggleSelectedTargets","nodeTargets",nodeTargets);
  local nodeCT = nodeTargets.getParent();
  clearCombatantsSelectedTargetIcon();
  markCombatantsSelected(nodeCT);
end

-- update the hpbar in the combatants list.
function updateHPBars()
--UtilityManagerADND.logDebug("cta_combatants_host.lua","updateHPBars");
  for _,v in pairs(getWindows(true)) do
    if v.hpbar then
      v.hpbar.update();
    end
  end
end

function onListChanged()
  updateHPBars();
end

-- find the window in the windowlist for a specific nodeCT
function findWindowByNode(nodeCT)
  local win = nil;
  for _,v in pairs(getWindows(true)) do
    local node = v.getDatabaseNode();
    if node == nodeCT then
      win = v;
      break;
    end
  end
  
  return win;
end

function onDrop(x, y, draginfo)
--UtilityManagerADND.logDebug("cta_combatants_host.lua","onDrop","draginfo",draginfo);      
	-- dropping char,npc,encounter
	if draginfo.isType("shortcut") then
		if not Session.IsHost then
			return;
		end
    
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "charsheet" then
			CombatRecordManager.onRecordTypeEvent("charsheet", { sClass = "charsheet", nodeRecord = draginfo.getDatabaseNode() });
			return true;
		elseif sClass == "npc" then
			CombatRecordManager.onRecordTypeEvent("npc", { sClass = "npc", nodeRecord = draginfo.getDatabaseNode() });
			return true;
		elseif sClass == "battle" then
			CombatRecordManager.onRecordTypeEvent("battle", { sClass = "battle", nodeRecord = draginfo.getDatabaseNode() });
			return true;
		end
	end

  -- if moving a CT entry, set it to target init -1
  if draginfo.isType("reorder") then
    local sClass, sRecord = draginfo.getShortcutData();
    if sClass == "reorder_cta_initiative" and sRecord ~= "" then
      local win = getWindowAt(x,y);
      if win then
        local nodeInitTarget = win.getDatabaseNode();
        local nodeInitSource = DB.findNode(sRecord);
        if nodeInitTarget ~= nodeInitSource then
          --local nOrderSource = DB.getValue(nodeInitSource,"initresult",0);
          local nOrderTarget = (DB.getValue(nodeInitTarget,"initresult",0));
          --local nLastInit = CombatManagerADND.getLastInitiative();
          -- if the very last entry we want to put them below that one
          --if nOrderTarget >= nLastInit then
            --nOrderTarget = nLastInit + 1;
          --else
          -- otherwise we put them above the entry we selected
            --nOrderTarget = nOrderTarget - 1;
            nOrderTarget = nOrderTarget + 1;
          --end
          DB.setValue(nodeInitSource,"initresult","number",nOrderTarget);
          --DB.setValue(nodeInitTarget,"order","number",nOrderSource);
        end
        return true;
      end
    end
  end

  -- otherwise we assume it's an attack/damage/spell/effect
-- replace this
  -- local win = getWindowAt(x,y);
  -- if win then
  --   local nodeCT = win.getDatabaseNode();
  --   if nodeCT then
  --     return CombatManager.onDrop("ct", nodeCT.getNodeName(), draginfo);
  --   end
  -- end
--with this?
  local sCTNode = UtilityManager.getWindowDatabasePath(getWindowAt(x,y));
	return CombatDropManager.handleAnyDrop(draginfo, sCTNode);
--end replace
  -- return true;
end

-- on down click load the node into the main display window
function onClickDown(nButton, x, y)
--UtilityManagerADND.logDebug("cta_combatants_host.lua","onClickDown","nButton",nButton);
--  local selectedSubwindow =  window.parentcontrol.window.selected;
  if nButton == 1 then
    if not Input.isControlPressed() then
      local win = getWindowAt(x,y);
      if win then
        local nodeCT = win.getDatabaseNode();
        selectEntryCTA(nodeCT);
        return true;
      else
        -- clicked empty space, unselect any entry
        clearSelect();
      end
    end
  end
  return true;
end

--on release Select the token, if control, then "target"
function onClickRelease(nButton, x, y)
--UtilityManagerADND.logDebug("cta_combatants_host.lua","onClickRelease","nButton",nButton);
  local win = getWindowAt(x,y);
  if win then
    --return win.token.onClickRelease(nButton);
    if nButton == 1 then
      if Input.isControlPressed() then
        local nodeActive = getSelectedNode()
        if nodeActive then
          local nodeTarget = win.getDatabaseNode();
          if nodeTarget then
            TargetingManager.toggleCTTarget(nodeActive, nodeTarget);
          end
        end
      else
        local tokeninstance = CombatManager.getTokenFromCT(win.getDatabaseNode());
        if tokeninstance and tokeninstance.isActivable() then
          tokeninstance.setActive(not tokeninstance.isActive());
        end
      end
    
    else
      local tokeninstance = CombatManager.getTokenFromCT(win.getDatabaseNode());
      if tokeninstance then
        tokeninstance.setScale(1.0);
      end
    end
    return true;
  end
end

-- find the selected node
function getSelectedNode()
  local node = nil;
  for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
    if DB.getValue(nodeCT,"selected",0) == 1 then
      node = nodeCT;
      break;
    end
  end
  return node;
end

-- select entry and perform tasks related to first time viewing
function selectEntryCTA(nodeCT)
  if not nodeCT then
    return;
  end
  local isNPC = CombatManagerADND.isCTNodeNPC(nodeCT);
  local selectedSubwindow =  window.parentcontrol.window.selected;
--UtilityManagerADND.logDebug("cta_combatants_host.lua","selectEntry","selectedSubwindow",selectedSubwindow);            
  -- clear selected
  clearSelect();

-- JPG - 2022-09-25 - Updated to support full or delayed copy
	-- check if this has been source copied before...
	if isNPC then
		if not CombatRecordManagerADND.checkDelayedCopy(nodeCT) then
			return;
		end
	end
  
--UtilityManagerADND.logDebug("cta_combatants_host.lua","selectEntry","Selecting: nodeCT",nodeCT);    
  DB.setValue(nodeCT,"selected","number",1);
  selectedSubwindow.setValue('cta_main_selected_host',nodeCT);
  -- this allows us to see the PC's action/powers in the CT
  if not isNPC then
   local nodeChar = CombatManagerADND.getNodeFromCT(nodeCT);
   selectedSubwindow.subwindow.actions.setValue('cta_actions_host',nodeChar);
   selectedSubwindow.subwindow.skills.setValue('cta_skills_host',nodeChar);
  end
  --
  selectedSubwindow.setVisible(true);
  toggleCombatantsTargetIcons(nodeCT);
end

-- clear existing targeted combatants icons
-- set targeted combatants icons for nodeCT
function toggleCombatantsTargetIcons(nodeCT)
  clearCombatantsSelectedTargetIcon();
  markCombatantsSelected(nodeCT);
end

-- mark all combatant entries with red target if the "selected" entry has them targeted.
function markCombatantsSelected(nodeCT)
--UtilityManagerADND.logDebug("cta_combatants_host.lua","markCombatantsSelected","nodeCT",nodeCT); 
  for _, nodeTarget in pairs(DB.getChildren(nodeCT,"targets")) do
    local sNodeToken = DB.getValue(nodeTarget,"noderef");
    if sNodeToken then
      local nodeTarget = DB.findNode(sNodeToken);
      if nodeTarget then
      local win = findWindowByNode(nodeTarget);
        if win then
          win.targetsSelected.setVisible(true);
        end
      end
    end
  end -- for
end

-- clear the "combatant selected" icons.
function clearCombatantsSelectedTargetIcon()
  for _,win in pairs(getWindows(true)) do
    local node = win.getDatabaseNode();
      win.targetsSelected.setVisible(false);
    end
end

-- remove selected from any node in right windowlist
function clearSelect()
  local selectedSubwindow =  window.parentcontrol.window.selected;
  selectedSubwindow.setVisible(false);
  for _,win in ipairs(getWindows(true)) do
      local nodeCT = win.getDatabaseNode();
      DB.setValue(nodeCT,"selected","number",0);
  end
end

-- apply sort to combatants list based on initiative 
function onSortCompare(w1, w2)
	return CombatManager.onSortCompare(w1.getDatabaseNode(), w2.getDatabaseNode());
end

--[[
  This function is called from cta_entry.lua during delete(). It allows
  us to remove the node then do something after. If we tried that in cta_entry.lua
  we'd get an error because the windowlist entry would be gone.
]]
function removeEntry(node)
  --UtilityManagerADND.logDebug("cta_combatants_host.lua","removeEntry","node",node); 
  if node then
    node.delete();
    -- CombatManagerADND.buildCombatantNodesCache();
  end
end
