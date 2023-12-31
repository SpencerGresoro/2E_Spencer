-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


function onInit()
  local node = getDatabaseNode();
  DB.addHandler(DB.getPath(node, "abilitynoteslist"), "onChildUpdate", updateView);
  onLinkChanged();
  updateView();
end

function onClose()
  local node = getDatabaseNode();
  DB.removeHandler(DB.getPath(node, "abilitynoteslist"), "onChildUpdate", updateView);
  
end

function onDrop(x, y, draginfo)
-- UtilityManagerADND.logDebug("cta_selected.lua","onDrop","draginfo",draginfo);     

  local sClass, sRecord = draginfo.getShortcutData();
  local nodeCT = getDatabaseNode();
  local nodeEntry = nodeCT;
  if not bIsNPC then
    nodeEntry = CombatManagerADND.getNodeFromCT(nodeCT);
  end
--local bIsNPC = (not ActorManager.isPC(nodeEntry));
  if sClass == "charsheet" then
	CombatRecordManager.onRecordTypeEvent("charsheet", { sClass = "charsheet", nodeRecord = draginfo.getDatabaseNode() });
    return true;
  elseif sClass == "npc" then
	CombatRecordManager.onRecordTypeEvent("npc", { sClass = "npc", nodeRecord = draginfo.getDatabaseNode() });
    return true;
  elseif sClass == "battle" then
	CombatRecordManager.onRecordTypeEvent("battle", { sClass = "battle", nodeRecord = draginfo.getDatabaseNode() });
    return true;
  elseif sClass == 'item' or ItemManager2.isRefBaseItemClass(sClass) then 
    --return CombatManager.onDrop("", nodeEntry.getNodeName(), draginfo);
    return ItemManager.handleAnyDrop(nodeEntry, draginfo);
  elseif sClass == "reference_spell" or sClass == "power" then
    PowerManagerADND.onDropAddPower(draginfo,nodeEntry);
    return true;
  elseif draginfo.isType("effect") then
    -- replace this...
    -- return CombatManager.onDrop("ct", nodeCT.getNodeName(), draginfo);
    --with this?
    -- local sCTNode = UtilityManager.getWindowDatabasePath(getWindowAt(x,y));
    return CombatDropManager.handleAnyDrop(draginfo, nodeCT.getPath());
    --end replace      
  else
  -- what ever else ???
    -- CoreRPG combatmanager doesn't do sanity checking and causes lock-up.
    -- return CombatManager.onDrop("ct", nodeCT.getNodeName(), draginfo);
  end
  return true;
end

function onLinkChanged()
  local node = getDatabaseNode();
  -- If a PC, then set up the links to the char sheet
  local sClass, sRecord = DB.getValue(node,"link","","");
--UtilityManagerADND.logDebug("cta_selected.lua","onLinkChanged","sClass",sClass);  

  if sClass == "charsheet" then
    linkPCFields(DB.findNode(sRecord));
  elseif sClass == "npc" then
    linkNPCFields(DB.findNode(sRecord));
  end
  --onIDChanged();
end

-- hide certain thing when a pc is selected
function updateView()
  local node = getDatabaseNode();
  -- this will hide/show the ability notes section
  if DB.getChildCount(node,"abilitynoteslist") < 1 then
    self.actions.subwindow.ability_notes.setVisible(false);
  else
    self.actions.subwindow.ability_notes.setVisible(true);
  end
end

function linkNPCFields(nodeChar)
  if nodeChar then

  --local headerPath = header.subwindow;
  local savesPath = stats.subwindow.cta_saves_and_abilities_host.subwindow.cta_subwindow_savingthrows.subwindow;
  local abilityScoresPath = stats.subwindow.cta_saves_and_abilities_host.subwindow.cta_subwindow_ablity_scores.subwindow;
  
    --name.setLink(nodeChar.createChild("name", "string"), false);
    
    -- hptotal.setLink(nodeChar.createChild("hptotal", "number"));
    -- hptemp.setLink(nodeChar.createChild("hptemp", "number"));
    -- wounds.setLink(nodeChar.createChild("wounds", "number"));

        -- --- stats
    abilityScoresPath.strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
    abilityScoresPath.dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
    abilityScoresPath.constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
    abilityScoresPath.intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
    abilityScoresPath.wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
    abilityScoresPath.charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);

        --- saves
    savesPath.paralyzation.setLink(nodeChar.createChild("saves.paralyzation.score", "number"), true);
    savesPath.poison.setLink(nodeChar.createChild("saves.poison.score", "number"), true);
    savesPath.death.setLink(nodeChar.createChild("saves.death.score", "number"), true);
    savesPath.rod.setLink(nodeChar.createChild("saves.rod.score", "number"), true);
    savesPath.staff.setLink(nodeChar.createChild("saves.staff.score", "number"), true);
    savesPath.wand.setLink(nodeChar.createChild("saves.wand.score", "number"), true);
    savesPath.petrification.setLink(nodeChar.createChild("saves.petrification.score", "number"), true);
    savesPath.polymorph.setLink(nodeChar.createChild("saves.polymorph.score", "number"), true);
    savesPath.breath.setLink(nodeChar.createChild("saves.breath.score", "number"), true);
    savesPath.spell.setLink(nodeChar.createChild("saves.spell.score", "number"), true);

        -- combat
    --init.setLink(nodeChar.createChild("init", "number"), true);
    --thaco.setLink(nodeChar.createChild("thaco", "number"), true);
    --ac.setLink(nodeChar.createChild("ac", "number"), true);
    --speed.setLink(nodeChar.createChild("speed", "number"), true);
  end
end

function linkPCFields(nodeChar)
  if nodeChar then
    local headerPath = header.subwindow;
    local savesPath = stats.subwindow.cta_saves_and_abilities_host.subwindow.cta_subwindow_savingthrows.subwindow;
    local abilityScoresPath = stats.subwindow.cta_saves_and_abilities_host.subwindow.cta_subwindow_ablity_scores.subwindow;

    headerPath.name.setLink(nodeChar.createChild("name", "string"), true);

    -- disabled for now to test hpcurrent
    -- headerPath.hptotal.setLink(nodeChar.createChild("hp.total", "number"));
    headerPath.hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
    headerPath.wounds.setLink(nodeChar.createChild("hp.wounds", "number"));

    local thaco = headerPath.createControl('number_ct_crosslink_hidden','thaco');
    local ac = headerPath.createControl('number_ct_crosslink_hidden','ac');
    local speed = headerPath.createControl('string_ct_hidden','speed');
    
        
    --init.setLink(nodeChar.createChild("initiative.total", "number"), true);
    headerPath.thaco.setLink(nodeChar.createChild("combat.thaco.score", "number"), true);
    headerPath.ac.setLink(nodeChar.createChild("defenses.ac.total", "number"), true);
    headerPath.speed.setLink(nodeChar.createChild("speed.total", "string"), true);
    
    --
    abilityScoresPath.strength.setLink(nodeChar.createChild("abilities.strength.score", "number"), true);
    abilityScoresPath.dexterity.setLink(nodeChar.createChild("abilities.dexterity.score", "number"), true);
    abilityScoresPath.constitution.setLink(nodeChar.createChild("abilities.constitution.score", "number"), true);
    abilityScoresPath.intelligence.setLink(nodeChar.createChild("abilities.intelligence.score", "number"), true);
    abilityScoresPath.wisdom.setLink(nodeChar.createChild("abilities.wisdom.score", "number"), true);
    abilityScoresPath.charisma.setLink(nodeChar.createChild("abilities.charisma.score", "number"), true);
    
    --
    savesPath.paralyzation.setLink(nodeChar.createChild("saves.paralyzation.score", "number"), true);
    savesPath.poison.setLink(nodeChar.createChild("saves.poison.score", "number"), true);
    savesPath.death.setLink(nodeChar.createChild("saves.death.score", "number"), true);
    savesPath.rod.setLink(nodeChar.createChild("saves.rod.score", "number"), true);
    savesPath.staff.setLink(nodeChar.createChild("saves.staff.score", "number"), true);
    savesPath.wand.setLink(nodeChar.createChild("saves.wand.score", "number"), true);
    savesPath.petrification.setLink(nodeChar.createChild("saves.petrification.score", "number"), true);
    savesPath.polymorph.setLink(nodeChar.createChild("saves.polymorph.score", "number"), true);
    savesPath.breath.setLink(nodeChar.createChild("saves.breath.score", "number"), true);
    savesPath.spell.setLink(nodeChar.createChild("saves.spell.score", "number"), true);
  end
end
