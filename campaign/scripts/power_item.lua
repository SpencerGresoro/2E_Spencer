-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bFilter = true;
function setFilter(bNewFilter)
  bFilter = bNewFilter;
end
--function getFilter()
--  return bFilter;
--end

function onInit()
  local node = getDatabaseNode();
  DB.addHandler(DB.getPath(node, "powersource"), "onUpdate", updateItemSync);
    
-- tweak here for testing --celestian
  if windowlist == nil or not windowlist.isReadOnly() then
--    if not windowlist.isReadOnly() then
    registerMenuItem(Interface.getString("list_menu_cloneitem"), "insert", 4);
    registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
    registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

    registerMenuItem(Interface.getString("power_menu_addaction"), "pointer", 3);
    registerMenuItem(Interface.getString("power_menu_addcast"), "radial_sword", 3, 2);
    registerMenuItem(Interface.getString("power_menu_adddamage"), "radial_damage", 3, 3);
    registerMenuItem(Interface.getString("power_menu_addheal"), "radial_heal", 3, 4);
    registerMenuItem(Interface.getString("power_menu_addeffect"), "radial_effect", 3, 5);

    registerMenuItem(Interface.getString("power_menu_adddmg_psp"), "radial_dmg_psp", 3, 6);
    registerMenuItem(Interface.getString("power_menu_addheal_psp"), "radial_heal_psp", 3, 8);
    -- disabled, we don't reparse in AD&D Core right now --celestian
    --registerMenuItem(Interface.getString("power_menu_reparse"), "textlist", 4);
  end

  --Check to see if we should automatically parse attack description
  local nodeAttack = getDatabaseNode();
  local nParse = DB.getValue(nodeAttack, "parse", 0);
  if nParse ~= 0 then
    DB.setValue(nodeAttack, "parse", "number", 0);
    PowerManager.parsePCPower(nodeAttack);
  end
  
  onDisplayChanged();
  -- window list can be nil when using this for spell records (not PC/NPCs) --celestian
  if windowlist ~= nil then 
    windowlist.onChildWindowAdded(self);
  end

  toggleDetail();
  firstTimeSpellRecord();
  firstTimeItemRecord();
  updateItemSync();
end

function onClose()
  local node = getDatabaseNode();
  DB.removeHandler(DB.getPath(node, "powersource"), "onUpdate", updateItemSync);
end

  --[[ 
  If Item powers (in inventory) are not synced with Action->weapons/powers the "uses" will be incorrect. 
  That means uses are not going to match if the item is moved to someone else...
  
  This will link between powersource and the actions/powers entry.
  Added the handler because for whatever reason when you ID a item it processes the power_item
  before it adds the powersource. So we just check to see if the powersource changes and if it
  does we setup the links.
  This checks that we are either a npc, pc or in combattracker and a power_item control and NOT in 
  inventory. Anything else, we don't utlize sync for.
  ]]
function updateItemSync()
  local node = getDatabaseNode();
  if not node.getPath():match("%.inventorylist%.") and 
        (node.getPath():match("^charsheet%.") or 
         node.getPath():match("^npc%.") or 
         node.getPath():match("^combattracket%.list%.")) 
        and (self.getClass() == 'power_item' ) then
    local sPowerSource = DB.getValue(node,"powersource","");
    if sPowerSource and sPowerSource ~= "" then
      local nodePowerSource = DB.findNode(sPowerSource);
      if nodePowerSource then
        -- link these controls to the source db node.
        cast.setLink(nodePowerSource.createChild("cast", "number"),false);
        prepared.setLink(nodePowerSource.createChild("prepared", "number"),false);
        usesperiod.setLink(nodePowerSource.createChild("usesperiod", "string"),false);
      end
    end
  end
  -- end item sync
end

-- If level, group, type or memorization count changes we update visibility
function updateForMemorizationChanges()
  onDisplayChanged();
  toggleDetail();
end

-- filters out non-memorized spells when in "combat" mode.
function getFilter()
    local bShow = bFilter;
    local node = getDatabaseNode();
    local nodeChar = node.getChild("...");
    --local bisNPC = (not ActorManager.isPC(nodeChar));    
--    UtilityManagerADND.logDebug("power_item.lua","getFilter","node",node);
--    UtilityManagerADND.logDebug("power_item.lua","getFilter","nodeChar",nodeChar);

    local bMemorized = ((DB.getValue(node,"memorized_total",0) > 0) );
    local sMode = DB.getValue(nodeChar, "powermode", "");
    local nLevel = DB.getValue(node, "level",0);
    local sGroup = DB.getValue(node, "group",""):lower();
    -- make sure it's in group "Spells" and has level > 0
    -- for some reason some spells have sGroup of "spell" and some "spells"
    local bisCastSpell = ( (nLevel > 0) and (sGroup:match("^spell.?$")) );

    -- this is so when they cast a spell it doesn't go away instantly
    -- otherwise they can't use save/damage/heal/etc
    -- it's reset when they toggle mode to standard/preparation mode
    --local bWasMemorized = (DB.getValue(node,"wasmemorized",0) > 0);

-- if sMode == "combat" then 
-- local sName = DB.getValue(node, "name", "");
-- UtilityManagerADND.logDebug("power_item.lua","getFilter","sName",sName);
-- UtilityManagerADND.logDebug("power_item.lua","getFilter","nLevel",nLevel);
-- UtilityManagerADND.logDebug("power_item.lua","getFilter","bisCastSpell",bisCastSpell);
-- UtilityManagerADND.logDebug("power_item.lua","getFilter","sGroup",sGroup);
-- UtilityManagerADND.logDebug("power_item.lua","getFilter","sMode",sMode);
-- UtilityManagerADND.logDebug("power_item.lua","getFilter","bMemorized",bMemorized);
-- end
    
    if bisCastSpell and sMode == "combat" and bMemorized then
      bShow = true;
    elseif bisCastSpell and sMode == "combat" and not bMemorized then
      bShow = false;
    end
    
    return bShow;
end

-- if we're in a spell record and do
-- not need to see these
function firstTimeSpellRecord()
    if (string.match(getDatabaseNode().getPath(),"^spell")) then
      header.subwindow.group.setVisible(false);
      header.subwindow.shortdescription.setVisible(false);
      header.subwindow.name.setVisible(false);
    end
end

-- item record first time tweaks, otherwise we don't set.
-- give it a name of the item
-- set group start to whatever item type is
-- set usesperiod to "once", default to charged item
-- set default charges to 25
function firstTimeItemRecord()
  local nodeAttack = getDatabaseNode();
    if string.match(nodeAttack.getPath(),"^item") then
      local nodeItem = DB.getChild(nodeAttack, "...");
      if (name.getValue() == "") then
        local sName = DB.getValue(nodeItem,"name","");
        local sGroup = DB.getValue(nodeItem,"type","Item");
        name.setValue(sName);
        group.setValue(sGroup);
        usesperiod.setValue("once");
        local nCharges = 25;
        local sNameLower = sName:lower();
        local sGroupLower = sGroup:lower();
        if string.match(sNameLower,"rod") or string.match(sGroupLower,"rod") then
            nCharges = 50;
        elseif string.match(sNameLower,"wand") or string.match(sGroupLower,"wand") then
            nCharges = 100;
        end
        prepared.setValue(nCharges);
      end
    end
end

function onDisplayChanged()
    local sDisplayMode = DB.getValue(getDatabaseNode(), "...powerdisplaymode", "");
  
    -- this was a test to enable counters/etc to spells/powers
    -- celestian
    -- local node = getDatabaseNode();
    -- if node.getPath():match("^spell%.id%-") then
      -- header.subwindow.prepared.setVisible(true);
      -- header.subwindow.usepower.setVisible(true);
      -- header.subwindow.counter.setVisible(true);
      -- header.subwindow.usesperiod.setVisible(true);
      -- DB.setValue(node,"powermode","string",'preparation');
    -- end
    
    if sDisplayMode == "summary" then
        header.subwindow.group.setVisible(false);
        header.subwindow.shortdescription.setVisible(true);
        header.subwindow.actionsmini.setVisible(false);
        header.subwindow.castinitiative.setVisible(false);
        -- header.subwindow.memorizedcount.setVisible(false);
        -- header.subwindow.memorization_remove.setVisible(false);
        -- header.subwindow.memorization_add.setVisible(false);
    elseif sDisplayMode == "action" then
        header.subwindow.group.setVisible(false);
        header.subwindow.shortdescription.setVisible(false);
        header.subwindow.actionsmini.setVisible(true);
        header.subwindow.castinitiative.setVisible(true);
        -- header.subwindow.memorizedcount.setVisible(true);
        -- header.subwindow.memorization_remove.setVisible(true);
        -- header.subwindow.memorization_add.setVisible(true);
    else
        header.subwindow.group.setVisible(true);
        header.subwindow.shortdescription.setVisible(false);
        header.subwindow.actionsmini.setVisible(false);
        header.subwindow.castinitiative.setVisible(false);
        
        -- header.subwindow.memorizedcount.setVisible(false);
        -- header.subwindow.memorization_remove.setVisible(false);
        -- header.subwindow.memorization_add.setVisible(false);
    end

    -- if the spell can not be memorized, hide it
    -- if not PowerManager.canMemorizeSpell(getDatabaseNode()) then
        -- header.subwindow.memorizedcount.setVisible(false);
        -- header.subwindow.memorization_remove.setVisible(false);
        -- header.subwindow.memorization_add.setVisible(false);
    -- else
    -- end
end

-- add action for spell/item
function createAction(sType)
  local nodeAttack = getDatabaseNode();
  if nodeAttack then
    local nodeActions = nodeAttack.createChild("actions");
    if nodeActions then
      local nodeAction = nodeActions.createChild();
      if nodeAction then
        DB.setValue(nodeAction, "type", "string", sType);
      end
    end
  end
end

function onMenuSelection(selection, subselection)
  if selection == 6 and subselection == 7 then
    cleanUpMemorization(getDatabaseNode());
    getDatabaseNode().delete();

  elseif selection == 4 then
    local node = getDatabaseNode();
    local nodeParent = node.getParent();
    local nodeClone = nodeParent.createChild();
    DB.copyNode(node,nodeClone);
  elseif selection == 3 then
    if subselection == 2 then
      createAction("cast");
      activatedetail.setValue(1);
    elseif subselection == 3 then
      createAction("damage");
      activatedetail.setValue(1);
    elseif subselection == 4 then
      createAction("heal");
      activatedetail.setValue(1);
    elseif subselection == 5 then
      createAction("effect");
      activatedetail.setValue(1);
    elseif subselection == 6 then
      createAction("damage_psp");
      activatedetail.setValue(1);
    elseif subselection == 8 then
      createAction("heal_psp");
      activatedetail.setValue(1);
    end
  end
end

-- this is to clean up and dangling (deleted/removed) memorized spells (since we disabled player
-- edit options on the tics) when a player decides to delete a memorized spell
-- AD&D, -celestian
function cleanUpMemorization(nodeSpell)
    local nodeChar = nodeSpell.getChild("...");

    local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
    local nLevel = DB.getValue(nodeSpell, "level", 0);
    local nMemorized = DB.getValue(nodeSpell, "memorized_total", 0);
    local nUsedArcane = DB.getValue(nodeChar, "powermeta.spellslots" .. nLevel .. ".used", 0);
    local nLeftOver = nUsedArcane - nMemorized;

--UtilityManagerADND.logDebug("power_item.lua","cleanUpMemorization","nMemorized",nMemorized); 
--UtilityManagerADND.logDebug("power_item.lua","cleanUpMemorization","nUsedArcane",nUsedArcane); 
--UtilityManagerADND.logDebug("power_item.lua","cleanUpMemorization","nLeftOver",nLeftOver); 

    if (nMemorized > 0) then
      if (sSpellType == "arcane") then
        DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",nLeftOver);
      elseif (sSpellType == "divine") then
        DB.setValue(nodeChar,"powermeta.pactmagicslots" .. nLevel .. ".used","number",nLeftOver);
      else
        DB.setValue(nodeChar,"powermeta.spellslots" .. nLevel .. ".used","number",nLeftOver);
      end
    end
end

-- create a cast action
function createActionCast() 
  createAction("cast");
  activatedetail.setValue(1);
end

function toggleDetail()
  local status = (activatedetail.getValue() == 1);
--UtilityManagerADND.logDebug("------------power_item.lua","toggleDetail","status",status);    
  actions.setVisible(status);
  if footer_blank then
    footer_blank.setVisible(status);
  end
  --initiative.setVisible(status);
  local node = getDatabaseNode();
  -- if PowerManager.canMemorizeSpell(node) then
    -- memorization.setVisible(status);
  -- else
    -- memorization.setVisible(false);
  -- end
  
  for _,v in pairs(actions.getWindows()) do
    v.updateDisplay();
  end
end

function getDescription(bShowFull)
  local node = getDatabaseNode();
  
  local s = DB.getValue(node, "name", "");
  
  if bShowFull then
    local sShort = DB.getValue(node, "shortdescription", "");
    if sShort ~= "" then
      s = s .. " - " .. sShort;
    end
  end

  return s;
end

function usePower(bShowFull)
  local node = getDatabaseNode();
  ChatManager.Message(getDescription(bShowFull), true, ActorManager.resolveActor( node.getChild("...")));
end
