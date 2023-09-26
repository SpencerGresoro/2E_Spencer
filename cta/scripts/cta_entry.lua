-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--UtilityManagerADND.logDebug("cta_entry.lua","onInit",getDatabaseNode());
--UtilityManagerADND.logDebug("cta_entry.lua","onInit:name",DB.getValue(getDatabaseNode(),"name",""));
  -- Register the deletion menu item for the host
  registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
  registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
  
  local node = getDatabaseNode();
  local rActor = ActorManager.resolveActor(node);
  local bIsNPC = (not ActorManager.isPC(rActor));
  
  
  DB.addHandler(node.getPath() .. ".selected", "onUpdate", toggleSelected);
  DB.addHandler(node.getPath() .. ".active", "onUpdate", toggleActive);
  DB.addHandler(node.getPath() .. ".name_hidden", "onUpdate", toggleHiddenName);
  DB.addHandler(node.getPath() .. ".link", "onUpdate", toggleNPCControls);

  if bIsNPC then
    DB.addHandler(node.getPath() .. ".hptotal", "onUpdate", onHealthChanged);
    DB.addHandler(node.getPath() .. ".wounds", "onUpdate", onHealthChanged);
  else
    local nodeChar = CombatManagerADND.getNodeFromCT(node);
    DB.addHandler(nodeChar.getPath() .. ".hp.total", "onUpdate", onHealthChanged);
    DB.addHandler(nodeChar.getPath() .. ".hp.wounds", "onUpdate", onHealthChanged);
  end

  toggleSelected();
  toggleActive();
  toggleHiddenName();
  onLinkChanged();
  toggleNPCControls();
  onHealthChanged();
  
  -- make sure first time load of map has proper indicator
  local bActive = (DB.getValue(node, "active", 0) == 1)
  TokenManagerADND.setTargetsForActive(node);
  CombatManagerADND.setHasInitiativeIndicator(node,bActive);
end

function onClose()
  local node = getDatabaseNode();
  local rActor = ActorManager.resolveActor(node);
  local bIsNPC = (not ActorManager.isPC(rActor));
  DB.removeHandler(node.getPath() .. ".selected", "onUpdate", toggleSelected);
  DB.removeHandler(node.getPath() .. ".active", "onUpdate", toggleActive);
  DB.removeHandler(node.getPath() .. ".name_hidden", "onUpdate", toggleHiddenName);
  DB.removeHandler(node.getPath() .. ".link", "onUpdate", toggleNPCControls);

  if bIsNPC then
    DB.removeHandler(node.getPath() .. ".hptotal", "onUpdate", onHealthChanged);
    DB.removeHandler(node.getPath() .. ".wounds", "onUpdate", onHealthChanged);
  else
    local nodeChar = CombatManagerADND.getNodeFromCT(node);
    DB.removeHandler(nodeChar.getPath() .. ".hp.total", "onUpdate", onHealthChanged);
    DB.removeHandler(nodeChar.getPath() .. ".hp.wounds", "onUpdate", onHealthChanged);
  end
  
end

function onHealthChanged()
  local node = getDatabaseNode();
--UtilityManagerADND.logDebug("cta_Entry.lua","onHealthChanged","node",node);   
  local rActor = ActorManager.resolveActor(node);
  local bIsNPC = (not ActorManager.isPC(rActor));
  if bIsNPC then
    local nPercentWounded,_ = ActorHealthManager.getWoundPercent(rActor);
    local bDead = (nPercentWounded >= 1);
    idelete.setVisibility(bDead);
    if bDead then
      removeAsTarget(node);
    end
  end

--UtilityManagerADND.logDebug("cta_Entry.lua","onHealthChanged","node",node);            
  local nHPMax = DB.getValue(node,"hptotal",0);
  local nHPWounds = DB.getValue(node,"wounds",0);
  if not bIsNPC then
    local nodeChar = CombatManagerADND.getNodeFromCT(node);
    nHPMax = DB.getValue(nodeChar,"hp.total",0);
    nHPWounds = DB.getValue(nodeChar,"hp.wounds",0);
  end
  local nHPCurrent = (nHPMax - nHPWounds);
  DB.setValue(node,"hpcurrent","number",nHPCurrent);
end

-- remove this node from all targets
function removeAsTarget(nodeRemoveAsTarget)
  for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
    for _, nodeTarget in pairs(DB.getChildren(nodeCT,"targets")) do
      local sNodeTarget = DB.getValue(nodeTarget,"noderef");
      if sNodeTarget and sNodeTarget == nodeRemoveAsTarget.getPath() then 
        TokenManagerADND.setTokenTargetedIndicator(nodeRemoveAsTarget,false);
        nodeTarget.delete();
        break;
      end
    end -- for  
  end
end
      
function toggleNPCControls()
  local node = getDatabaseNode();
  local sClass, sRecord = DB.getValue(node,"link","","");
--UtilityManagerADND.logDebug("cta_Entry.lua","toggleNPCControls","sClass",sClass);    
  if CombatManagerADND.isCTNodePC(node) then
    onLinkChanged();
    name_hidden.setVisible(false);
    isidentified.setVisible(false);
    tokenvis.setVisible(false);
  else
    name_hidden.setVisible(true);
    isidentified.setVisible(true);
    tokenvis.setVisible(true);
  end
end

function toggleHiddenName()
  local nodeCT = getDatabaseNode();
  local sHidden = DB.getValue(nodeCT,"name_hidden");
  if sHidden and sHidden ~= "" then
    name_hidden.setVisible(true);
  else
    name_hidden.setVisible(false);
  end
end

-- select the proper frame/color for this entry
function getBackground(node,bHoverState)
  local sFriendFoe = DB.getValue(node,"friendfoe","");
  local bSelected = (DB.getValue(node,"selected",0) == 1);
  local bActive = (DB.getValue(node,"active",0) == 1);
  
  if bHoverState then bSelected = bHoverState; end;
  
  local sColor = "4B0082";
  local sFrame = "field-goldenrod";
  
  if bActive then
    if sFriendFoe == "friend" then
      sColor = "FFFFFF";
      sFrame = "ctaentrybox_friend";
    elseif sFriendFoe == "neutral" then
      sColor = "FFFFFF";
      sFrame = "ctaentrybox_neutral";
    elseif sFriendFoe == "foe" then
      sColor = "FFFFFF";
      sFrame = "ctaentrybox_foe";
    elseif sFriendFoe == "" then
      sColor = "FFFFFF";
      sFrame = "ctaentrybox_neutral";
    end
  else
    if sFriendFoe == "friend" then
      sColor = "2F4F4F";
      sFrame = "ctaentrybox_friend";
    elseif sFriendFoe == "neutral" then
      sColor = "DAA520";
      sFrame = "ctaentrybox_neutral";
    elseif sFriendFoe == "foe" then
      sColor = "800000";
      sFrame = "ctaentrybox_foe";
    elseif sFriendFoe == "" then
      sColor = "808080";
      sFrame = "ctaentrybox_neutral";
    end
  end
  
  if bSelected or bActive then
    return sFrame, sColor;
  else
    return sFrame, nil;
  end
end

-- Toggle the active token (who has initiative) and clean up
-- previous widgets/etc.
function toggleActive()
  local node = getDatabaseNode();
  local bActive = (DB.getValue(node,"active",0) == 1);
  local sFrame, sColor = getBackground(node);
  TokenManagerADND.clearAllTargetsWidgets();
  toggleTargetTokenIndicators();
  if bActive then
    setBackColor(sColor);
    setFrame(sFrame);
    clearMapSelectedToken();
  end
end

-- clean any selected token, select active one
-- a side effect of doing this is if the map is NOT opened it will open the map
function clearMapSelectedToken()
  local nodeCT = getDatabaseNode();
  local tokenMap = CombatManager.getTokenFromCT(nodeCT);
  local imageControl = ImageManager.getImageControl(tokenMap, true);
  if imageControl then
    imageControl.clearSelectedTokens();
    imageControl.selectToken( tokenMap, true ) ;
  end
  TokenManagerADND.resetIndicators(nodeCT, false);
end

function toggleTargetTokenIndicators()
  local nodeCT = getDatabaseNode();
--UtilityManagerADND.logDebug("cta_entry.lua","toggleTargetTokenIndicators","node",node);  
  TokenManagerADND.setTargetsForActive(nodeCT);
end
--
function toggleSelected()
  local node = getDatabaseNode();
  local bSelected = (DB.getValue(node,"selected",0) == 1);
  local sFrame, sColor = getBackground(node);
  setBackColor(sColor);
  setFrame(sFrame);
  if bSelected then
    windowlist.window.parentcontrol.window.selected.setBackColor(sColor);
    windowlist.window.parentcontrol.window.selected.setFrame(sFrame);
  end
end

function onMenuSelection(selection, subselection)
  if selection == 6 and subselection == 7 then
    delete();
  end
end

function delete()
  local node = getDatabaseNode();
  if not node then
    close();
    return;
  end

  CombatManager.onPreDeleteCombatantEvent(node);

  -- Clear any effects first, so that saves aren't triggered when initiative advanced
  --effects.reset(false);

  -- Move to the next actor, if this CT entry is active
  if DB.getValue(node, "active", 0) == 1 then
    CombatManager.nextActor();
  end

  -- Delete the entry above this so that commands can be executed after.
  -- otherwise the node doesn't exist (here!) so things break
  windowlist.removeEntry(node);
 
end

function onClickRelease(nButton, x, y)
--UtilityManagerADND.logDebug("cta_entry.lua","onClickRelease","Name",name.getValue());
--UtilityManagerADND.logDebug("cta_entry.lua","onClickRelease","nButton",nButton);
end

function onFactionChanged()
  toggleSelected();

--UtilityManagerADND.logDebug("cta_entry.lua","onFactionChanged",sFriendFoe);
end

-- "name" identification changed for the npc
function onIDChanged(nValue)
--UtilityManagerADND.logDebug("cta_entry.lua","onIDChanged",nValue);
end

function onVisibilityChanged(nValue)
--UtilityManagerADND.logDebug("cta_entry.lua","onVisibilityChanged",nValue);
TokenManager.updateVisibility(getDatabaseNode());
end


function onLinkChanged()
  local node = getDatabaseNode();
  -- If a PC, then set up the links to the char sheet
  local sClass, sRecord = DB.getValue(node,"link","","");
--UtilityManagerADND.logDebug("cta_Entry.lua","onLinkChanged","sClass",sClass);            
  if sClass == "charsheet" then
    linkPCFields(DB.findNode(sRecord));
  elseif sClass == "npc" then
    -- linkNPCFields(DB.findNode(sRecord));
  end
  --onIDChanged();
end

-- we link back to character sheet for these values.
function linkPCFields(nodeChar)
  if nodeChar then
    if not hptotal and not hptemp and not wounds then 
--UtilityManagerADND.logDebug("cta_entry.lua","linkPCFields",nodeChar);
      name.setLink(nodeChar.createChild("name", "string"), true);
      local hptotal = createControl('number_ct_crosslink_hidden','hptotal');
      local hptemp = createControl('number_ct_crosslink_hidden','hptemp');
      local wounds = createControl('number_ct_crosslink_hidden','wounds');

      local senses = createControl('string_ct_hidden','senses');
      
      hptotal.setLink(nodeChar.createChild("hp.total", "number"),true);
      hptemp.setLink(nodeChar.createChild("hp.temporary", "number"),true);
      wounds.setLink(nodeChar.createChild("hp.wounds", "number"),true);

      senses.setLink(nodeChar.createChild("senses", "string"),true);
    end

    -- local ac = createControl('number_ct_crosslink_hidden','hptemp');
    -- ac.setLink(nodeChar.createChild("defenses.ac.total", "number"),true);
  end
end
