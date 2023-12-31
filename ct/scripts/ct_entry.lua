-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  
  UtilityManagerADND.logDebug("ct_entry.lua","onInit----");

  -- Set the displays to what should be shown
  setTargetingVisible();
  setAttributesVisible();
  setActiveVisible();
  setSpacingVisible();
  setEffectsVisible();

  -- Acquire token reference, if any
  linkToken();
  
  -- Set up the PC links
  onLinkChanged();
  
  -- Update the displays
  onFactionChanged();
  onHealthChanged();
      
  -- Register the deletion menu item for the host
  registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
  registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

  local node = getDatabaseNode();
  
  UtilityManagerADND.logDebug("ct_entry.lua","onInit","node",node);

  -- DB.addHandler(DB.getPath(node, "effects"), "onChildUpdate", updateForEffects);
  DB.addHandler(DB.getPath(node, "effects.*.label"), "onUpdate", updateForEffects);
  DB.addHandler(DB.getPath(node, "effects.*.isactive"), "onUpdate", updateForEffects);
  DB.addHandler(node.getPath() .. ".active", "onUpdate", toggleActiveUpdateFeatures);
  DB.addHandler("options.HouseRule_ASCENDING_AC", "onUpdate", updateAscendingValues);
  
  updateAscendingValues()
  updateForEffects();
  
  -- make sure first time load of map has proper indicator
  local bActive = (DB.getValue(node, "active", 0) == 1)
  TokenManagerADND.setTargetsForActive(node);
  CombatManagerADND.setHasInitiativeIndicator(node,bActive);
end

function onClose()
  local node = getDatabaseNode();
  -- DB.removeHandler(DB.getPath(node, "effects"), "onChildUpdate", updateForEffects);
  DB.removeHandler(DB.getPath(node, "effects.*.label"), "onUpdate", updateForEffects);
  DB.removeHandler(DB.getPath(node, "effects.*.isactive"), "onUpdate", updateForEffects);

  DB.removeHandler(node.getPath() .. ".active", "onUpdate", toggleActiveUpdateFeatures);
  DB.removeHandler("options.HouseRule_ASCENDING_AC", "onUpdate", updateAscendingValues);
end

-- go through what needs done for active changing.
function toggleActiveUpdateFeatures()
  toggleNPCCombat();
  TokenManagerADND.clearAllTargetsWidgets();
  toggleTargetTokenIndicators();
  clearSelectionToken();
end

-- clean any selected token, select active one
function clearSelectionToken()
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
--UtilityManagerADND.logDebug("ct_entry.lua","toggleTargetTokenIndicators","node",node);  
  TokenManagerADND.setTargetsForActive(nodeCT);
end

-- toggle combat tab when "active" is updated to 1. "active" means that entry has initiative --celestian
function toggleNPCCombat()
  local sClass, sRecord = link.getValue();
  local bNPC = (sClass ~= "charsheet");    
  if (bNPC) then
    local node = getDatabaseNode();
    local nActive = DB.getValue(node, "active", 0);
    activateactive.setValue(nActive);
  end
end

function updateDisplay()
  local sFaction = friendfoe.getStringValue();

  if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
    name.setFont("sheetlabel");
    nonid_name.setFont("sheetlabel");
    
    active_spacer_top.setVisible(true);
    active_spacer_bottom.setVisible(true);
    
    if sFaction == "friend" then
      setFrame("ctentrybox_friend_active");
    elseif sFaction == "neutral" then
      setFrame("ctentrybox_neutral_active");
    elseif sFaction == "foe" then
      setFrame("ctentrybox_foe_active");
    else
      setFrame("ctentrybox_active");
    end
  else
    name.setFont("sheettext");
    nonid_name.setFont("sheettext");
    
    active_spacer_top.setVisible(false);
    active_spacer_bottom.setVisible(false);
    
    if sFaction == "friend" then
      setFrame("ctentrybox_friend");
    elseif sFaction == "neutral" then
      setFrame("ctentrybox_neutral");
    elseif sFaction == "foe" then
      setFrame("ctentrybox_foe");
    else
      setFrame("ctentrybox");
    end
  end
end

function linkToken()
  local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
  if imageinstance then
    TokenManager.linkToken(getDatabaseNode(), imageinstance);
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
  
  -- Remember node name
  local sNode = node.getNodeName();
  
  -- Clear any effects first, so that saves aren't triggered when initiative advanced
  effects.reset(false);

  -- Move to the next actor, if this CT entry is active
  if DB.getValue(node, "active", 0) == 1 then
    CombatManager.nextActor();
  end

  -- Delete the database node and close the window
  local cList = windowlist;
  CombatManager.deleteCombatant(node);
  -- node.delete();

  -- Update list information (global subsection toggles, targeting)
  cList.onVisibilityToggle();
  cList.onEntrySectionToggle();
end

function onLinkChanged()
  -- If a PC, then set up the links to the char sheet
  local sClass, sRecord = link.getValue();
--UtilityManagerADND.logDebug("ct_Entry.lua","onLinkChanged","sRecord",sRecord);            
--UtilityManagerADND.logDebug("ct_Entry.lua","onLinkChanged","sClass",sClass);            
  if sClass == "charsheet" then
    linkPCFields();
    name.setLine(false);
  elseif sClass == "npc" then
    linkNPCFields();
    --name.setLine(false);
  end
  onIDChanged();
end

function onHealthChanged()
  local rActor = ActorManager.resolveActor(getDatabaseNode())
  local sColor = ActorHealthManager.getHealthColor(rActor);
  local nPercentWounded, sStatus = ActorHealthManager.getWoundPercent(rActor);

  wounds.setColor(sColor);
  status.setValue(sStatus);

  local sClass,_ = link.getValue();
  if sClass ~= "charsheet" then
    idelete.setVisibility((nPercentWounded >= 1));
  end
end

function onIDChanged()
  local nodeRecord = getDatabaseNode();
--UtilityManagerADND.logDebug("ct_entry.lua","onIDChanged","nodeRecord",nodeRecord);  
  local sClass = DB.getValue(nodeRecord, "link", "", "");

  if sClass == "npc" then
    local bID = LibraryData.getIDState("npc", nodeRecord, true);
    name.setVisible(bID);
    nonid_name.setVisible(not bID);
    isidentified.setVisible(true);
  else
    name.setVisible(true);
    nonid_name.setVisible(false);
    isidentified.setVisible(false);
  end
end

function onFactionChanged()
  -- Update the entry frame
  updateDisplay();

  -- If not a friend, then show visibility toggle
  if friendfoe.getStringValue() == "friend" then
    tokenvis.setVisible(false);
  else
    tokenvis.setVisible(true);
  end
end

function onVisibilityChanged()
  TokenManager.updateVisibility(getDatabaseNode());
  windowlist.onVisibilityToggle();
end

function onActiveChanged()
  setActiveVisible();
end
function linkNPCFields()
  local nodeChar = link.getTargetDatabaseNode();
  if nodeChar then
    --name.setLink(nodeChar.createChild("name", "string"), false);
    
    -- hptotal.setLink(nodeChar.createChild("hptotal", "number"));
    -- hptemp.setLink(nodeChar.createChild("hptemp", "number"));
    -- wounds.setLink(nodeChar.createChild("wounds", "number"));

        --- stats
    strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
    dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
    constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
    intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
    wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
    charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);

        --- saves
    paralyzation.setLink(nodeChar.createChild("saves.paralyzation.score", "number"), true);
    poison.setLink(nodeChar.createChild("saves.poison.score", "number"), true);
    death.setLink(nodeChar.createChild("saves.death.score", "number"), true);
    rod.setLink(nodeChar.createChild("saves.rod.score", "number"), true);
    staff.setLink(nodeChar.createChild("saves.staff.score", "number"), true);
    wand.setLink(nodeChar.createChild("saves.wand.score", "number"), true);
    petrification.setLink(nodeChar.createChild("saves.petrification.score", "number"), true);
    polymorph.setLink(nodeChar.createChild("saves.polymorph.score", "number"), true);
    breath.setLink(nodeChar.createChild("saves.breath.score", "number"), true);
    spell.setLink(nodeChar.createChild("saves.spell.score", "number"), true);

        -- combat
    init.setLink(nodeChar.createChild("init", "number"), true);
    thaco.setLink(nodeChar.createChild("thaco", "number"), true);
    ac.setLink(nodeChar.createChild("ac", "number"), true);
    --bab.setLink(nodeChar.createChild("bab", "number"), true);
    --ac_ascending.setLink(nodeChar.createChild("ac_ascending", "number"), true);
    speed.setLink(nodeChar.createChild("speed", "number"), true);
  end
end

function linkPCFields()
  local nodeChar = link.getTargetDatabaseNode();
  if nodeChar then
    name.setLink(nodeChar.createChild("name", "string"), true);

    hptotal.setLink(nodeChar.createChild("hp.total", "number"));
    hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
    wounds.setLink(nodeChar.createChild("hp.wounds", "number"));
    deathsavesuccess.setLink(nodeChar.createChild("hp.deathsavesuccess", "number"));
    deathsavefail.setLink(nodeChar.createChild("hp.deathsavefail", "number"));

    strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
    dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
    constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
    intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
    wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
    charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);

    paralyzation.setLink(nodeChar.createChild("saves.paralyzation.score", "number"), true);
    poison.setLink(nodeChar.createChild("saves.poison.score", "number"), true);
    death.setLink(nodeChar.createChild("saves.death.score", "number"), true);
    rod.setLink(nodeChar.createChild("saves.rod.score", "number"), true);
    staff.setLink(nodeChar.createChild("saves.staff.score", "number"), true);
    wand.setLink(nodeChar.createChild("saves.wand.score", "number"), true);
    petrification.setLink(nodeChar.createChild("saves.petrification.score", "number"), true);
    polymorph.setLink(nodeChar.createChild("saves.polymorph.score", "number"), true);
    breath.setLink(nodeChar.createChild("saves.breath.score", "number"), true);
    spell.setLink(nodeChar.createChild("saves.spell.score", "number"), true);

        
    init.setLink(nodeChar.createChild("initiative.total", "number"), true);
    thaco.setLink(nodeChar.createChild("combat.thaco.score", "number"), true);
    ac.setLink(nodeChar.createChild("defenses.ac.total", "number"), true);
    speed.setLink(nodeChar.createChild("speed.total", "number"), true);
  end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setTargetingVisible()
  local v = false;
  if activatetargeting.getValue() == 1 then
    v = true;
  end

  targetingicon.setVisible(v);
  
  sub_targeting.setVisible(v);
  
  frame_targeting.setVisible(v);

  target_summary.onTargetsChanged();
end

function setAttributesVisible()
  local v = false;
  if activateattributes.getValue() == 1 then
    v = true;
  end
  local sClass, sRecord = link.getValue();
  local bNPC = (sClass ~= "charsheet");
  
  attributesicon.setVisible(v);

  strength.setVisible(v);
  strength_label.setVisible(v);
  dexterity.setVisible(v);
  dexterity_label.setVisible(v);
  constitution.setVisible(v);
  constitution_label.setVisible(v);
  intelligence.setVisible(v);
  intelligence_label.setVisible(v);
  wisdom.setVisible(v);
  wisdom_label.setVisible(v);
  charisma.setVisible(v);
  charisma_label.setVisible(v);

--  attr_save_division_label.setVisible(v);

  paralyzation.setVisible(v);
  paralyzation_label.setVisible(v);
  poison.setVisible(v);
  poison_label.setVisible(v);
  
  death.setVisible(v);
  death_label.setVisible(v);
    
  rod.setVisible(v);
  rod_label.setVisible(v);
  staff.setVisible(v);
  staff_label.setVisible(v);
  wand.setVisible(v);
  wand_label.setVisible(v);

  petrification.setVisible(v);
  petrification_label.setVisible(v);
    
  polymorph.setVisible(v);
  polymorph_label.setVisible(v);

  breath.setVisible(v);
  breath_label.setVisible(v);

  spell.setVisible(v);
  spell_label.setVisible(v);

  spacer_attribute.setVisible(v);

  if bNPC then
    sub_skills.setVisible(v);
  else
    sub_skills.setVisible(false);
  end
  
  frame_attributes.setVisible(v);
end

function setActiveVisible()
  local v = false;
  if activateactive.getValue() == 1 then
    v = true;
  end

  local sClass, sRecord = link.getValue();
  local bNPC = (sClass ~= "charsheet");
    -- this forces combat section to be open up
  --if bNPC and active.getValue() == 1 then
--    v = true;
--  end
  
  activeicon.setVisible(v);

  -- reaction.setVisible(v);
  -- reaction_label.setVisible(v);
  
  thaco.setVisible(v);
  thacolabel.setVisible(v);
    
  init.setVisible(v);
  initlabel.setVisible(v);
  ac.setVisible(v);
  aclabel.setVisible(v);
  speed.setVisible(v);
  speedlabel.setVisible(v);
  
  spacer_action.setVisible(v);
  
  if bNPC then
    damage.setVisible(v);
    damagelabel.setVisible(v);
    
    specialdefenselabel.setVisible(v);
    specialDefense.setVisible(v);
    specialattackslabel.setVisible(v);
    specialAttacks.setVisible(v);
    
    sub_actions.setVisible(v);
  else
    damage.setVisible(false);
    damagelabel.setVisible(false);

    specialdefenselabel.setVisible(false);
    specialDefense.setVisible(false);
    specialattackslabel.setVisible(false);
    specialAttacks.setVisible(false);

    sub_actions.setVisible(false);
  end
  
  frame_active.setVisible(v);
end

function setSpacingVisible(v)
  local v = false;
  if activatespacing.getValue() == 1 then
    v = true;
  end

    local bNPC = (sClass ~= "charsheet");
    
  spacingicon.setVisible(v);
  
  space.setVisible(v);
  spacelabel.setVisible(v);
  reach.setVisible(v);
  reachlabel.setVisible(v);

  hitDice.setVisible(v);
  hitDicelabel.setVisible(v);
  
  if (bNPC) then
--level.setVisible(v);
--levellabel.setVisible(v);
  end
    
  morale.setVisible(v);
  moralelabel.setVisible(v);

  size.setVisible(v);
  sizelabel.setVisible(v);

  frame_spacing.setVisible(v);
end

function setEffectsVisible(v)
  local v = false;
  if activateeffects.getValue() == 1 then
    v = true;
  end
  
  effecticon.setVisible(v);
  
  effects.setVisible(v);
  effects_iadd.setVisible(v);
  for _,w in pairs(effects.getWindows()) do
    w.idelete.setValue(0);
  end
  
  frame_effects.setVisible(v);

  effect_summary.onEffectsChanged();
end

-- pass off the node to the effects manager 
function updateForEffects(effect)

  UtilityManagerADND.logDebug("ct_entry.lua","updateForEffects","effect",effect);

  local nodeChar = getDatabaseNode();
  local rActor = ActorManager.resolveActor(nodeChar);
  if ActorManager.isPC(rActor) then
    nodeChar = ActorManager.getCreatureNode(rActor);
  end
  
  local nodeCT = ActorManager.getCTNode(rTarget)
  EffectManagerADND.checkForAuraEffectUpdates(nodeCT);

  AbilityScoreADND.updateForEffects(nodeChar);
  CharManager.updateHealthScore(nodeChar);
end

function updateAscendingValues()
  local nodeCT = getDatabaseNode();
  local nodeChar = link.getTargetDatabaseNode();
  local bOptAscendingAC = (OptionsManager.getOption("HouseRule_ASCENDING_AC"):match("on") ~= nil);
  -- check that the sword icon is active
  local bActive = (activateactive.getValue() == 1)
  
  -- npc locations
  if not ActorManager.isPC(node) then
    -- this will setup values that are not already set
    local nTHACO = DB.getValue(nodeChar,"thaco",20);
    local nBAB = 0;
    if (nTHACO ~= 20 and nBAB == 0) then
      nBAB = 20 - nTHACO;
    end
    DB.setValue(nodeChar,"bab","number",nBAB);
    
    local nAC = DB.getValue(nodeChar,"ac",10);
    local nAscendingAC = 10;
    if (nAC < 10 and nAscendingAC == 10) then
      nAscendingAC = 20 - nAC;
    end
    --DB.setValue(nodeChar,"ac_ascending","number",nAscendingAC);
    ----
    
    nAC          = DB.getValue(nodeChar,"ac",10);
    nACAscending = DB.getValue(nodeChar,"ac_ascending",10);
    nTHACO       = DB.getValue(nodeChar,"thaco",20);
    nBAB         = DB.getValue(nodeChar,"bab",0);

    --bab.setVisible(bActive and bOptAscendingAC);
    --ac_ascending.setVisible(bActive and bOptAscendingAC);
    thaco.setVisible(bActive and not bOptAscendingAC);
    ac.setVisible(bActive and not bOptAscendingAC);
    
    if (bOptAscendingAC) then
      thacolabel.setValue("BAB");
      initlabel.setAnchor("left","bab","right","relative",10);
      speedlabel.setAnchor("left","ac_ascending","right","relative",10);
    else
      thacolabel.setValue("THACO");
      initlabel.setAnchor("left","thaco","right","relative",10);
      speedlabel.setAnchor("left","ac","right","relative",10);
    end
  end
end