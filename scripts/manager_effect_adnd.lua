
--
-- Effects on Items, apply to character in CT
--
--

function onInit()
  -- do we need this for the override to work properly?
  --EffectManager.registerEffectVar("nInit", { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true });
  -- I think there is a bug in manager_effect.lua where they reference "aEffectVarMap["nInit"].vDBDefault" which doesn't exist.
  --
  
  if Session.IsHost then
    -- watch the combatracker/npc inventory list
    DB.addHandler("combattracker.list.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("combattracker.list.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);

    -- watch the character/pc inventory list
    DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", updateItemEffectsForEdit);
    DB.addHandler("charsheet.*.inventorylist", "onChildDeleted", updateFromDeletedInventory);
  end
    --CoreRPG replacements
    ActionsManager.decodeActors = decodeActors;
    -- AD&D Core ONLY!!! (need this because we use Ascending initiative, not high to low
    EffectManager.setInitAscending(true);
    --EffectManager.processEffects = processEffects;
    
    --[[
        This ensures that the setCustomInitChange() doesn't also run
        the CoreRPG version. The "setCustomInitChange() actually adds to a array
        of functions. Since CoreRPG does this it's also run there... not what we want. 
        Want want to override completely.
    ]]--
    CombatManager.onInitChangeEvent = processEffects;
    --
    
    --CombatManager.setCustomInitChange(processEffects);
    CombatManager.addCombatantFieldChangeHandler("initresult", "onUpdate", updateForInitiative);
    CombatManager.addCombatantFieldChangeHandler("initrolled", "onUpdate", updateForInitiativeRolled);
    
    
    -- used for AD&D Core ONLY
    --ActionsManager.resolveAction = resolveAction;
    --EffectManager5E.parseEffectComp = parseEffectComp;
    EffectManager5E.evalAbilityHelper = evalAbilityHelper;
    EffectManager.setCustomOnEffectActorStartTurn(onEffectActorStartTurn);
    
    EffectManager.setCustomOnEffectAddStart(adndOnEffectAddStart);
    EffectManager.setCustomOnEffectAddEnd(adndOnEffectAddEnd);
    EffectManager5E.applyOngoingDamageAdjustment = applyOngoingDamageAdjustment;
    EffectManager5E.getEffectsBonusByType = getEffectsBonusByType;
    EffectManager5E.onEffectTextEncode = onEffectTextEncode;

    -- this is for ARMOR() effect type
    --IFT: ARMOR(plate,platemail);ATK: 2 and it will then give you +2 to hit versus targets that are wearing plate/platemail armor.
    EffectManager5E.checkConditional = checkConditional; 
    -- this was for debug/testing
    --ActorManager.getTypeAndNode = getTypeAndNodeADND;
    
    -- 5E effects replacements
    EffectManager5E.checkConditionalHelper = checkConditionalHelper;
    EffectManager5E.getEffectsByType = getEffectsByType;
    EffectManager5E.hasEffect = hasEffect;
    
    -- used for 5E extension ONLY
    --ActionAttack.performRoll = manager_action_attack_performRoll;
    --ActionDamage.performRoll = manager_action_damage_performRoll;
    --PowerManager.performAction = manager_power_performAction;
    
    -- option in house rule section, enable/disable allow PCs to edit advanced effects.
  OptionsManager.registerOption2("ADND_AE_EDIT", false, "option_header_houserule", "option_label_ADND_AE_EDIT", "option_entry_cycler", 
      { labels = "option_label_ADND_AE_enabled" , values = "enabled", baselabel = "option_label_ADND_AE_disabled", baseval = "disabled", default = "disabled" });    
end

function onClose()
  -- DB.removeHandler("charsheet.*.inventorylist.*.carried", "onUpdate", inventoryUpdateItemEffects);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.effect", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.durdice", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.durmod", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.name", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.durunit", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.visibility", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*.effectlist.*.actiononly", "onUpdate", updateItemEffectsForEdit);
  -- DB.removeHandler("charsheet.*.inventorylist.*", "onChildDeleted", updateFromDeletedInventory);
end
------------------------------------------------------

-- run from addHandler for updated item effect options
function inventoryUpdateItemEffects(nodeField)
  --if UtilityManagerADND.rateLimitOK(updateItemEffects,nodeField,1) then
    updateItemEffects(DB.getChild(nodeField, ".."));
--  end
end
-- update single item from edit for *.effect handler
function updateItemEffectsForEdit(nodeField)
    checkEffectsAfterEdit(DB.getChild(nodeField, ".."));
end
-- find the effect for this source and delete and re-build
function checkEffectsAfterEdit(itemNode)
  local nodeChar = nil
  local bIDUpdated = false;
  if itemNode.getPath():match("%.effectlist%.") then
    nodeChar = DB.getChild(itemNode, ".....");
  else
    nodeChar = DB.getChild(itemNode, "...");
    bIDUpdated = true;
  end
  local nodeCT = CharManager.getCTNodeByNodeChar(nodeChar);
  if nodeCT then
    for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
      local sLabel = DB.getValue(nodeEffect, "label", "");
      local sEffSource = DB.getValue(nodeEffect, "source_name", "");
      -- see if the node exists and if it's in an inventory node
      local nodeEffectFound = DB.findNode(sEffSource);
      if (nodeEffectFound  and string.match(sEffSource,"inventorylist")) then
        local nodeEffectItem = nodeEffectFound.getChild("...");
        if nodeEffectFound == itemNode then -- effect hide/show edit
          nodeEffect.delete();
          updateItemEffects(DB.getChild(itemNode, "..."));
        elseif nodeEffectItem == itemNode then -- id state was changed
          nodeEffect.delete();
          updateItemEffects(nodeEffectItem);
        end
      end
    end
  end
end
-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function updateFromDeletedInventory(node)
    local nodeChar = DB.getChild(node, "..");
    local bisNPC = (not ActorManager.isPC(nodeChar));
    local nodeTarget = nodeChar;
    local nodeCT = CharManager.getCTNodeByNodeChar(nodeChar);
    -- if we're already in a combattracker situation (npcs)
    if bisNPC and string.match(nodeChar.getPath(),"^combattracker") then
      nodeCT = nodeChar;
    end
    if nodeCT then
      -- check that we still have the combat effect source item
      -- otherwise remove it
      --if UtilityManagerADND.rateLimitOK(checkEffectsAfterDelete,nodeCT,1) then
        checkEffectsAfterDelete(nodeCT);
      --end
    end
  --onEncumbranceChanged();
end

-- this checks to see if an effect is missing a associated item that applied the effect 
-- when items are deleted and then clears that effect if it's missing.
function checkEffectsAfterDelete(nodeChar)
    local sUser = User.getUsername();
    for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
        local sLabel = DB.getValue(nodeEffect, "label", "");
        local sEffSource = DB.getValue(nodeEffect, "source_name", "");
        -- see if the node exists and if it's in an inventory node
        local nodeFound = DB.findNode(sEffSource);
        local bDeleted = ((nodeFound == nil) and string.match(sEffSource,"inventorylist"));
        if (bDeleted) then
            local msg = {font = "msgfont", icon = "roll_effect"};
            msg.text = "Effect ['" .. sLabel .. "'] ";
            msg.text = msg.text .. "removed [from " .. DB.getValue(nodeChar, "name", "") .. "]";
            -- HANDLE APPLIED BY SETTING
            if sEffSource and sEffSource ~= "" then
              msg.text = msg.text .. " [by Deletion]";
            end
            if EffectManager.isGMEffect(nodeChar, nodeEffect) then
                if sUser == "" then
                    msg.secret = true;
                    Comm.addChatMessage(msg);
                elseif sUser ~= "" then
                    Comm.addChatMessage(msg);
                    Comm.deliverChatMessage(msg, sUser);
                end
            else
                Comm.deliverChatMessage(msg);
            end
            nodeEffect.delete();
        end
        
    end
end


---------------------------------------


-- add the effect if the item is equipped and doesn't exist already
function updateItemEffects(nodeItem,nodeChar)
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects1","nodeItem",nodeItem);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","Session.IsHost",Session.IsHost);
    if not nodeChar then
      nodeChar = DB.getChild(nodeItem, "...");
    end
    if not nodeChar then
      return;
    end
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
    local sName = DB.getValue(nodeItem, "name", "");
    -- we swap the node to the combat tracker node
    -- so the "effect" is written to the right node
    if not string.match(nodeChar.getPath(),"^combattracker") then
      nodeChar = CharManager.getCTNodeByNodeChar(nodeChar);
    end
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","nodeChar3",nodeChar);
    -- if not in the combat tracker bail
    if not nodeChar then
      return;
    end
    
    local nCarried = DB.getValue(nodeItem, "carried", 0);
    local bEquipped = (nCarried == 2);
    local nIdentified = DB.getValue(nodeItem, "isidentified", 1);
    -- local bOptionID = OptionsManager.isOption("MIID", "on");
    -- if not bOptionID then 
        -- nIdentified = 1;
    -- end
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","sUser",sUser);
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","nodeChar",nodeChar);
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","nodeItem",nodeItem);
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","nCarried",nCarried);
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","bEquipped",bEquipped);
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffects","nIdentified",nIdentified);

    for _,nodeItemEffect in pairs(DB.getChildren(nodeItem, "effectlist")) do
        updateItemEffect(nodeItemEffect, sName, nodeChar, nil, bEquipped, nIdentified);
    end -- for item's effects list
end

-- update single effect for item
-- update single effect for item
function updateItemEffect(nodeItemEffect, sName, nodeChar, sUser, bEquipped, nIdentified)
    local sCharacterName = DB.getValue(nodeChar, "name", "");
    local sItemSource = nodeItemEffect.getPath();
    local sLabel = DB.getValue(nodeItemEffect, "effect", "");
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffect","bEquipped",bEquipped);    
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffect","nodeItemEffect",nodeItemEffect);  
    if sLabel and sLabel ~= "" then -- if we have effect string
        local bFound = false;
        for _,nodeEffect in pairs(DB.getChildren(nodeChar, "effects")) do
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
            local nDMOnly = DB.getValue(nodeEffect, "isgmonly", 0);
            if (nActive ~= 0) then
                local sEffSource = DB.getValue(nodeEffect, "source_name", "");
                if (sEffSource == sItemSource) then
                    bFound = true;
                    if (not bEquipped) then
                        sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly, sUser)
                        nodeEffect.delete();
                        break;
                    end -- not equipped
                end -- effect source == item source
            end -- was active
        end -- nodeEffect for
        
        if (not bFound and bEquipped) then
            local rEffect = {};
            local nRollDuration = 0;
            local dDurationDice = DB.getValue(nodeItemEffect, "durdice");
            local nModDice = DB.getValue(nodeItemEffect, "durmod", 0);
            if (dDurationDice and dDurationDice ~= "") then
                nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
            else
                nRollDuration = nModDice;
            end
            local nDMOnly = 0;
            local sVisibility = DB.getValue(nodeItemEffect, "visibility", "");
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffect","sVisibility",sVisibility);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateItemEffect","nIdentified",nIdentified);

            if sVisibility == "hide" then
                nDMOnly = 1;
            elseif sVisibility == "show"  then
                nDMOnly = 0;
            elseif nIdentified == 0 then
                nDMOnly = 1;
            elseif nIdentified > 0  then
                nDMOnly = 0;
            end

            local isNPC = CombatManagerADND.isCTNodeNPC(nodeChar);            
            if isNPC then
              local bTokenVis = (DB.getValue(nodeChar,"tokenvis",1) == 1);
              if not bTokenVis then
                nDMOnly = 1; -- hide if token not visible
              end
            end

            rEffect.nDuration = nRollDuration;
            rEffect.sName = sName .. ";" .. sLabel;
            rEffect.sLabel = sLabel; 
            rEffect.sUnits = DB.getValue(nodeItemEffect, "durunit", "");
            rEffect.nInit = 0;
            rEffect.sSource = sItemSource;
            rEffect.nGMOnly = nDMOnly;
            rEffect.sApply = "";
            
            sendEffectAddedMessage(nodeChar, rEffect, sLabel, nDMOnly, sUser)
            EffectManager.addEffect("", "", nodeChar, rEffect, false);
        end
    end
end


-- flip through all pc/npc effectslist (generally do this in addNPC()/addPC()
-- nodeChar: node of PC/NPC in PC/NPCs record list
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffects(nodeChar,nodeEntry)
    for _,nodeCharEffect in pairs(DB.getChildren(nodeChar, "effectlist")) do
        updateCharEffect(nodeCharEffect,nodeEntry);
    end -- for item's effects list 
end
-- apply effect from npc/pc/item to the node
-- nodeCharEffect: node in effectlist on PC/NPC
-- nodeEntry: node in combat tracker for PC/NPC
function updateCharEffect(nodeCharEffect,nodeEntry)
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateCharEffect","nodeCharEffect",nodeCharEffect);    
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateCharEffect","nodeEntry",nodeEntry);    
  local sUser = User.getUsername();
  local sName = DB.getValue(nodeEntry, "name", "");
  local sLabel = DB.getValue(nodeCharEffect, "effect", "");
  local nRollDuration = 0;
  local dDurationDice = DB.getValue(nodeCharEffect, "durdice");
  local nModDice = DB.getValue(nodeCharEffect, "durmod", 0);
  if (dDurationDice and dDurationDice ~= "") then
      nRollDuration = StringManager.evalDice(dDurationDice, nModDice);
  else
      nRollDuration = nModDice;
  end
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateCharEffect","nRollDuration",nRollDuration);
  local nDMOnly = 0;
  local sVisibility = DB.getValue(nodeCharEffect, "visibility", "");
  if sVisibility == "show" then
      nDMOnly = 0;
  elseif sVisibility == "hide" then
      nDMOnly = 1;
  end
  local bisPC = ActorManager.isPC(nodeEntry);
  if (not bisPC) then
    nDMOnly = 1; -- npcs effects always hidden from PCs when we first drag/drop into CT
  end
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateCharEffect","bisPC",bisPC);    
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","updateCharEffect","sVisibility",sVisibility);

  local rEffect = {};
  rEffect.nDuration = nRollDuration;
  --rEffect.sName = sName .. ";" .. sLabel;
  rEffect.sName = sLabel;
  rEffect.sLabel = sLabel; 
  rEffect.sUnits = DB.getValue(nodeCharEffect, "durunit", "");
  rEffect.nInit = 0;
  --rEffect.sSource = nodeEntry.getPath();
  rEffect.nGMOnly = nDMOnly;
  rEffect.sApply = "";
  --EffectManager.addEffect("", "", nodeEntry, rEffect, true);
  
  --notifyEffectAdd(nodeEntry,rEffect);
  EffectManager.addEffect("", "", nodeEntry, rEffect, false);
  sendEffectAddedMessage(nodeEntry, rEffect, sLabel, nDMOnly);
end

-- get the Connected Player's name that has this identity
function getUserFromNode(node)
  local sNodePath = node.getPath();
  local _, sRecord = DB.getValue(node, "link", "", "");    
  local sUser = nil;
  for _,vUser in ipairs(User.getActiveUsers()) do
    for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
      if (sRecord == ("charsheet." .. vIdentity)) then
        sUser = vUser;
        break;
      end
    end
  end
  return sUser;
end

-- build message to send that effect removed
function sendEffectRemovedMessage(nodeChar, nodeEffect, sLabel, nDMOnly)
  local sUser = getUserFromNode(nodeChar);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","sendEffectRemovedMessage","sUser",sUser);  
  local sCharacterName = DB.getValue(nodeChar, "name", "");
  -- Build output message
  local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeChar),sUser);
  msg.font = "msgfont";
  msg.icon = "roll_effect";
  
  msg.text = "Advanced Effect ['" .. sLabel .. "'] ";
  msg.text = msg.text .. "removed [from " .. sCharacterName .. "]";
  -- HANDLE APPLIED BY SETTING
  local sEffSource = DB.getValue(nodeEffect, "source_name", "");    
  if sEffSource and sEffSource ~= "" then
      msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(sEffSource), "name", "") .. "]";
  end
  sendRawMessage(sUser,nDMOnly,msg);
end
-- build message to send that effect added
function sendEffectAddedMessage(nodeCT, rNewEffect, sLabel, nDMOnly)
  local sUser = getUserFromNode(nodeCT);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","sendEffectAddedMessage","sUser",sUser);  
  -- Build output message
  local msg = ChatManager.createBaseMessage(ActorManager.resolveActor(nodeCT),sUser);
  msg.font = "msgfont";
  msg.icon = "roll_effect";

  msg.text = "Advanced Effect ['" .. rNewEffect.sName .. "'] ";
  msg.text = msg.text .. "-> [to " .. DB.getValue(nodeCT, "name", "") .. "]";
  if rNewEffect.sSource and rNewEffect.sSource ~= "" then
    msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
  end
    sendRawMessage(sUser,nDMOnly,msg);
end
-- send message
function sendRawMessage(sUser, nDMOnly, msg)
  local sIdentity = nil;
  if sUser and sUser ~= "" then 
    sIdentity = User.getCurrentIdentity(sUser) or nil;
  end
  if sIdentity then
    msg.icon = "portrait_" .. User.getCurrentIdentity(sUser) .. "_chat";
  end
  if nDMOnly == 1 then
      msg.secret = true;
      Comm.addChatMessage(msg);
  elseif nDMOnly ~= 1 then 
      --Comm.addChatMessage(msg);
      Comm.deliverChatMessage(msg);
  end
end

-- pass effect to here to see if the effect is being triggered
-- by an item and if so if it's valid
function isValidCheckEffect(rActor,nodeEffect)
    local bResult = false;
    local nActive = DB.getValue(nodeEffect, "isactive", 0);
    local bItem = false;
    local bActionItemUsed = false;
    local bActionOnly = false;
    local nodeItem = nil;

    local sSource = DB.getValue(nodeEffect,"source_name","");
    -- if source is a valid node and we can find "actiononly"
    -- setting then we set it.
    local node = DB.findNode(sSource);
    if (node) then
        nodeItem = node.getChild("...");
        if nodeItem then
            bActionOnly = (DB.getValue(node,"actiononly",0) ~= 0);
        end
    end

    -- if there is a itemPath do some sanity checking
    if (rActor.itemPath and rActor.itemPath ~= "") then 
        -- here is where we get the node path of the item, not the 
        -- effectslist entry
        if ((DB.findNode(rActor.itemPath) ~= nil)) then
            if (node and node ~= nil and nodeItem and nodeItem ) then
                local sNodePath = nodeItem.getPath();
                if bActionOnly and sNodePath ~= "" and (sNodePath == rActor.itemPath) then
                    bActionItemUsed = true;
                    bItem = true;
                else
                    bActionItemUsed = false;
                    bItem = true; -- is item but doesn't match source path for this effect
                end
            end
        end
    end
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","isValidCheckEffect","nActive",nActive);    
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","isValidCheckEffect","bActionOnly",bActionOnly);    
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","isValidCheckEffect","bActionItemUsed",bActionItemUsed);    
    if nActive ~= 0 and bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and not bActionOnly and bActionItemUsed then
        bResult = true;
    elseif nActive ~= 0 and bActionOnly and not bActionItemUsed then
        bResult = false;
    elseif nActive ~= 0 then
        bResult = true;
    end
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","isValidCheckEffect","bResult",bResult);    
  -- if ( nActive ~= 0 and ( not bItem or (bItem and bActionItemUsed) ) ) then
        -- bResult = true;
    -- elseif nActive ~= 0 and bActionOnly and not (bItem or bActionItemUsed) then
        -- bResult = false;
    -- elseif nActive ~= 0 and (not bActionOnly and bItem) then
        -- bResult = true;
    -- end
    return bResult;
end



--
--          REPLACEMENT FUNCTIONS
--
-- CoreRPG EffectManager manager_effect_adnd.lua 
-- AD&D CORE ONLY
local aEffectVarMap = {
  ["sName"] = { sDBType = "string", sDBField = "label" },
  ["nGMOnly"] = { sDBType = "number", sDBField = "isgmonly" },
  ["sSource"] = { sDBType = "string", sDBField = "source_name", bClearOnUntargetedDrop = true },
  ["sTarget"] = { sDBType = "string", bClearOnUntargetedDrop = true },
  ["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
  ["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
};
-- replace CoreRPG EffectManager manager_effect_adnd.lua onInit() with this
-- AD&D CORE ONLY
function manager_effect_onInit()
  --CombatManager.setCustomInitChange(manager_effect_processEffects);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);
end

-- replace 5E EffectManager5E manager_effect_5E.lua evalAbilityHelper() with this
-- AD&D CORE ONLY
function evalAbilityHelper(rActor, sEffectAbility)
  -- local sSign, sModifier, sShortAbility = sEffectAbility:match("^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$");
  
  -- local nAbility = nil;
  -- if sShortAbility == "STR" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "strength");
  -- elseif sShortAbility == "DEX" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "dexterity");
  -- elseif sShortAbility == "CON" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "constitution");
  -- elseif sShortAbility == "INT" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "intelligence");
  -- elseif sShortAbility == "WIS" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "wisdom");
  -- elseif sShortAbility == "CHA" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "charisma");
  -- elseif sShortAbility == "LVL" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "level");
  -- elseif sShortAbility == "PRF" then
    -- nAbility = ActorManagerADND.getAbilityBonus(rActor, "prf");
  -- end
  
  -- if nAbility then
    -- if sSign == "-" then
      -- nAbility = 0 - nAbility;
    -- end
    -- if sModifier == "H" then
      -- if nAbility > 0 then
        -- nAbility = math.floor(nAbility / 2);
      -- else
        -- nAbility = math.ceil(nAbility / 2);
      -- end
    -- elseif sModifier == "2" then
      -- nAbility = nAbility * 2;
    -- end
  -- end
  
  -- return nAbility;
    return 0;
end

-- replace CoreRPG ActionsManager manager_actions.lua decodeActors() with this
function decodeActors(draginfo)
--UtilityManagerADND.logDebug("manager_effect_Adnd.lua","decodeActors","draginfo",draginfo);
  local rSource = nil;
  local aTargets = {};
    
  
  for k,v in ipairs(draginfo.getShortcutList()) do
    if k == 1 then
      -- rSource = ActorManager.getActor(v.class, v.recordname);
      rSource = ActorManager.resolveActor(v.recordname);
    else
      -- local rTarget = ActorManager.getActor(v.class, v.recordname);
      local rTarget = ActorManager.resolveActor(v.recordname);
      if rTarget then
        table.insert(aTargets, rTarget);
      end
    end
  end

  -- itemPath data filled if itemPath if exists
  local sItemPath = draginfo.getMetaData("itemPath");
  local sSpellPath = draginfo.getMetaData("spellPath");
--UtilityManagerADND.logDebug("manager_effect_Adnd.lua","decodeActors","sItemPath",sItemPath);
  if (sItemPath and sItemPath ~= "") then
      rSource.itemPath = sItemPath;
  end
  if (sSpellPath and sSpellPath ~= "") then
      rSource.spellPath = sSpellPath;
  end
  --
    
  return rSource, aTargets;
end

-- replace 5E EffectManager5E manager_effect_5E.lua getEffectsByType() with this
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","==rActor",rActor);    
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","==sEffectType",sEffectType);    
  if not rActor then
    return {};
  end
  local results = {};
  
  -- Set up filters
  local aRangeFilter = {};
  local aOtherFilter = {};
  if aFilter then
    for _,v in pairs(aFilter) do
      if type(v) ~= "string" then
        table.insert(aOtherFilter, v);
      elseif StringManager.contains(DataCommon.rangetypes, v) then
        table.insert(aRangeFilter, v);
      else
        table.insert(aOtherFilter, v);
      end
    end
  end

  -- Iterate through effects
  -- 
  --for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
  -- TESTING VV
  for _,v in ipairs(getEffectsList(ActorManager.getCTNode(rActor))) do
    -- Check active
    local nActive = DB.getValue(v, "isactive", 0);
    --if ( nActive ~= 0 and ( not bItemTriggered or (bItemTriggered and bItemSource) ) ) then
    if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
      local sLabel = DB.getValue(v, "label", "");
      local sApply = DB.getValue(v, "apply", "");

      -- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
      local bTargeted = EffectManager.isTargetedEffect(v);
      if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
        local aEffectComps = EffectManager.parseEffect(sLabel);
        -- Look for type/subtype match
        local nMatch = 0;
        for kEffectComp,sEffectComp in ipairs(aEffectComps) do
          local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
          -- Handle conditionals
          if rEffectComp.type == "IF" then
            if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
              break;
            end
          elseif rEffectComp.type == "IFT" then
            if not rFilterActor then
              break;
            end
            if not EffectManager5E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
              break;
            end
            bTargeted = true;
          -- Compare other attributes
          else
            -- Strip energy/bonus types for subtype comparison
            local aEffectRangeFilter = {};
            local aEffectOtherFilter = {};
            local j = 1;
            while rEffectComp.remainder[j] do
              local s = rEffectComp.remainder[j];
              if #s > 0 and ((s:sub(1,1) == "!") or (s:sub(1,1) == "~")) then
                s = s:sub(2);
              end
              if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" or 
                  StringManager.contains(DataCommon.bonustypes, s) or
                  StringManager.contains(DataCommon.powertypes, s) or
                  StringManager.contains(DataCommon.conditions, s) or
                  StringManager.contains(DataCommon.connectors, s) then
                -- SKIP
              elseif StringManager.contains(DataCommon.rangetypes, s) then
                table.insert(aEffectRangeFilter, s);
              else
                table.insert(aEffectOtherFilter, s);
              end
              
              j = j + 1;
            end
          
            -- Check for match
            local comp_match = false;
--,UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","==rEffectComp.type",rEffectComp.type);            
            if rEffectComp.type == sEffectType then

              -- Check effect targeting
              if bTargetedOnly and not bTargeted then
                comp_match = false;
              else
                comp_match = true;
              end

              -- Check filters
              if #aEffectRangeFilter > 0 then
                local bRangeMatch = false;
                for _,v2 in pairs(aRangeFilter) do
                  if StringManager.contains(aEffectRangeFilter, v2) then
                    bRangeMatch = true;
                    break;
                  end
                end
                if not bRangeMatch then
                  comp_match = false;
                end
              end
              if #aEffectOtherFilter > 0 then
                local bOtherMatch = false;
                for _,v2 in pairs(aOtherFilter) do
                  if type(v2) == "table" then
                    local bOtherTableMatch = true;
                    for k3, v3 in pairs(v2) do
                      if not StringManager.contains(aEffectOtherFilter, v3) then
                        bOtherTableMatch = false;
                        break;
                      end
                    end
                    if bOtherTableMatch then
                      bOtherMatch = true;
                      break;
                    end
                  elseif StringManager.contains(aEffectOtherFilter, v2) then
                    bOtherMatch = true;
                    break;
                  end
                end
                if not bOtherMatch then
                  comp_match = false;
                end
              end
            end

            -- Match!
            if comp_match then
              nMatch = kEffectComp;
              if nActive == 1 then
                table.insert(results, rEffectComp);
              end
            end
          end
        end -- END EFFECT COMPONENT LOOP

-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","END EFFECT COMPONENT LOOP");    
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","nMatch",nMatch);    
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","sApply",sApply);    
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsByType","v",v);    

        -- Remove one shot effects
        if nMatch > 0 then
          if nActive == 2 then
            DB.setValue(v, "isactive", "number", 1);
          else
            if sApply == "action" then
              EffectManager.notifyExpire(v, 0);
            elseif sApply == "roll" then
              EffectManager.notifyExpire(v, 0, true);
            elseif sApply == "single" then
              EffectManager.notifyExpire(v, nMatch, true);
            end
          end
        end
      end -- END TARGET CHECK
    end  -- END ACTIVE CHECK
  end  -- END EFFECT LOOP
  
  -- RESULTS
  return results;
end

-- replace 5E EffectManager5E manager_effect_5E.lua hasEffect() with this
function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
  if not sEffect or not rActor then
    return false;
  end
  local sLowerEffect = sEffect:lower();
  
  -- Iterate through each effect
  local aMatch = {};
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","hasEffect","rActor",rActor);    
  --for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
  for _,v in ipairs(getEffectsList(ActorManager.getCTNode(rActor))) do
    local nActive = DB.getValue(v, "isactive", 0);
    if (EffectManagerADND.isValidCheckEffect(rActor,v)) then
      -- Parse each effect label
      local sLabel = DB.getValue(v, "label", "");
      local bTargeted = EffectManager.isTargetedEffect(v);
      local aEffectComps = EffectManager.parseEffect(sLabel);

      -- Iterate through each effect component looking for a type match
      local nMatch = 0;
      for kEffectComp,sEffectComp in ipairs(aEffectComps) do
        local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
        -- Handle conditionals
        if rEffectComp.type == "IF" then
          if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder) then
            break;
          end
        elseif rEffectComp.type == "IFT" then
          if not rTarget then
            break;
          end
          if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
            break;
          end
        -- Check for match
        elseif rEffectComp.original:lower() == sLowerEffect then
          if bTargeted and not bIgnoreEffectTargets then
            if EffectManager.isEffectTarget(v, rTarget) then
              nMatch = kEffectComp;
            end
          elseif not bTargetedOnly then
            nMatch = kEffectComp;
          end
      end
    end

      -- If matched, then remove one-off effects
      if nMatch > 0 then
        if nActive == 2 then
          DB.setValue(v, "isactive", "number", 1);
        else
          table.insert(aMatch, v);
          local sApply = DB.getValue(v, "apply", "");
          if sApply == "action" then
            EffectManager.notifyExpire(v, 0);
          elseif sApply == "roll" then
            EffectManager.notifyExpire(v, 0, true);
          elseif sApply == "single" then
            EffectManager.notifyExpire(v, nMatch, true);
          end
        end
      end
    end
  end
  
  if #aMatch > 0 then
    return true;
  end
  return false;
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditional() with this
function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
  local bReturn = true;
  
  if not aIgnore then
    aIgnore = {};
  end
  table.insert(aIgnore, nodeEffect.getNodeName());
  
  for _,v in ipairs(aConditions) do
    local sLower = v:lower();
    if sLower == DataCommon.healthstatusfull then
      local nPercentWounded,_ = ActorHealthManager.getWoundPercent(rActor);
      if nPercentWounded > 0 then
        bReturn = false;
      end
    elseif sLower == DataCommon.healthstatushalf then
      local nPercentWounded,_ = ActorHealthManager.getWoundPercent(rActor);
      if nPercentWounded < .5 then
        bReturn = false;
      end
    elseif sLower == DataCommon.healthstatuswounded then
      local nPercentWounded,_ = ActorHealthManager.getWoundPercent(rActor);
      if nPercentWounded == 0 then
        bReturn = false;
      end
    elseif StringManager.contains(DataCommon.conditions, sLower) then
      if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
        bReturn = false;
      end
    elseif StringManager.contains(DataCommon.conditionaltags, sLower) then
      if not EffectManager5E.checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
        bReturn = false;
      end
    else
      local sAlignCheck = sLower:match("^align%s*%(([^)]+)%)$");
      local sSizeCheck = sLower:match("^size%s*%(([^)]+)%)$");
      local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
      local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
      local sArmorCheck = sLower:match("^armor%s*%(([^)]+)%)$");
      local sClassCheck = sLower:match("^class%s*%(([^)]+)%)$");

      local sDistanceBetweenCheck = sLower:match("^range%s*%(([^)]+)%)$");
      
      if sAlignCheck then
        if not ActorManagerADND.isAlignment(rActor, sAlignCheck) then
          bReturn = false;
        end
      elseif sSizeCheck then
        if not ActorManagerADND.isSize(rActor, sSizeCheck) then
          bReturn = false;
        end
      elseif sTypeCheck then
        if not ActorManagerADND.isCreatureType(rActor, sTypeCheck) then
          bReturn = false;
        end
      elseif sCustomCheck then
        if not EffectManager5E.checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
          bReturn = false;
        end
      elseif sArmorCheck then
        if not ActorManagerADND.isArmorType(rActor, sArmorCheck) then
          bReturn = false;
        end
      elseif sDistanceBetweenCheck then
        local nRange = tonumber(sDistanceBetweenCheck) or 0;
        if not ActorManagerADND.isRangeBetween(rActor, rTarget, nRange) then
          bReturn = false;
        end
      elseif sClassCheck then
        if not ActorManagerADND.isClassType(rActor, sClassCheck) then
          bReturn = false;
        end
      end
    end
  end
  
  table.remove(aIgnore);

  -- UtilityManagerADND.logDebug("manager_effect_adnd.lua","checkConditional","bReturn",bReturn)

  return bReturn;
end

--replace 5E onEffectTextEncode
function onEffectTextEncode(rEffect)
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","onEffectTextEncode","rEffect",rEffect);
	local aMessage = {};
	
	if rEffect.sUnits and rEffect.sUnits ~= "" then
		local sOutputUnits = nil;
		if rEffect.sUnits == "minute" then
			sOutputUnits = "TRN";
		elseif rEffect.sUnits == "hour" then
			sOutputUnits = "HR";
		elseif rEffect.sUnits == "day" then
			sOutputUnits = "DAY";
		end

		if sOutputUnits then
			table.insert(aMessage, "[UNITS " .. sOutputUnits .. "]");
		end
	end
	if rEffect.sTargeting and rEffect.sTargeting ~= "" then
		table.insert(aMessage, "[" .. rEffect.sTargeting:upper() .. "]");
	end
	if rEffect.sApply and rEffect.sApply ~= "" then
		table.insert(aMessage, "[" .. rEffect.sApply:upper() .. "]");
	end
	
	return table.concat(aMessage, " ");
end

-- replace 5E EffectManager5E manager_effect_5E.lua checkConditionalHelper() with this
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
  if not rActor then
    return false;
  end
  
  --for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
  for _,v in ipairs(getEffectsList(ActorManager.getCTNode(rActor))) do
    local nActive = DB.getValue(v, "isactive", 0);
    if (EffectManagerADND.isValidCheckEffect(rActor,v) and not StringManager.contains(aIgnore, v.getNodeName())) then
    --if nActive ~= 0 and not StringManager.contains(aIgnore, v.getNodeName()) then
      -- Parse each effect label
      local sLabel = DB.getValue(v, "label", "");
      local aEffectComps = EffectManager.parseEffect(sLabel);

      -- Iterate through each effect component looking for a type match
      for kEffectComp, sEffectComp in ipairs(aEffectComps) do
        local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);

        -- CHECK CONDITIONALS
        if rEffectComp.type == "IF" then
          if not EffectManager5E.checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
            break;
          end
        elseif rEffectComp.type == "IFT" then
          if not rTarget then
            break;
          end
          if not EffectManager5E.checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
            break;
          end
        
        -- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif rEffectComp.original:lower() == sEffect then
					if EffectManager.isTargetedEffect(v) then
						if EffectManager.isEffectTarget(v, rTarget) then
							return true;
						end
					else
						return true;
					end
				end
        
      end
    end
  end
  
  return false;
end

-- these functions we run with initiative value changes
function updateForInitiative(nodeField)
  updateEffectsForNewInitiative(nodeField);
end

-- run these functions when initiative is ROLLED
function updateForInitiativeRolled(nodeField)
  if CharlistManagerADND then
    CharlistManagerADND.onUpdate(nodeField);
  end
end

-- when player's initiative changes we run this to update effect for new "initiative" if it's not 0
function updateEffectsForNewInitiative(nodeField)
  local nodeCT = nodeField.getParent();
  local nInitResult = DB.getValue(nodeCT,"initresult",0);
  for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
    local nInit = DB.getValue(nodeEffect,"init",0);
    if (nInit ~= 0) then 
      -- change effect init to the new value rolled
      DB.setValue(nodeEffect,"init","number", nInitResult);
    end
  end
end

---- replace for Psionic nonsense
function onEffectActorStartTurn(nodeActor, nodeEffect)
  local sEffName = DB.getValue(nodeEffect, "label", "");
  local aEffectComps = EffectManager.parseEffect(sEffName);
  for _,sEffectComp in ipairs(aEffectComps) do
    local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);
    -- Conditionals
    if rEffectComp.type == "IFT" then
      break;
    elseif rEffectComp.type == "IF" then
      local rActor = ActorManager.resolveActor(nodeActor);
      if not EffectManager5E.checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
        break;
      end
    
    -- Ongoing damage and regeneration
    elseif rEffectComp.type == "DMGO" or rEffectComp.type == "REGEN" or rEffectComp.type == "DMGPSPO" then
      local nActive = DB.getValue(nodeEffect, "isactive", 0);
      if nActive == 2 then
        local rActor = ActorManager.resolveActor(nodeActor);
        if rEffectComp.type == "REGEN" and 
            (ActorHealthManager.getWoundPercent(rActor) >= 1) then 
          break;
        end
        DB.setValue(nodeEffect, "isactive", "number", 1);
      else
        EffectManager5E.applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
      end

    -- NPC power recharge
    elseif rEffectComp.type == "RCHG" then
      local nActive = DB.getValue(nodeEffect, "isactive", 0);
      if nActive == 2 then
        DB.setValue(nodeEffect, "isactive", "number", 1);
      else
        EffectManager5E.applyRecharge(nodeActor, nodeEffect, rEffectComp);
      end
    end
  end
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
  if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
    return;
  end
  
  local rTarget = ActorManager.resolveActor( nodeActor);
  if rEffectComp.type == "REGEN" then
    local rActor = ActorManager.resolveActor(nodeActor);
    local nPercentWounded,_ = ActorHealthManager.getWoundPercent(rActor);
    
    -- If not wounded, then return
    if nPercentWounded <= 0 then
      return;
    end
    -- Regeneration does not work once creature falls below 1 hit point
    if nPercentWounded >= 1 then
      return;
    end
    
    local rAction = {};
    rAction.label = "Regeneration";
    rAction.clauses = {};
    
    local aClause = {};
    aClause.dice = rEffectComp.dice;
    aClause.modifier = rEffectComp.mod;
    table.insert(rAction.clauses, aClause);
    
    local rRoll = ActionHeal.getRoll(nil, rAction);
    if EffectManager.isGMEffect(nodeActor, nodeEffect) then
      rRoll.bSecret = true;
    end
    ActionsManager.actionDirect(nil, "heal", { rRoll }, { { rTarget } });
  elseif rEffectComp.type == "DMGO" then
    local rAction = {};
    rAction.label = "Ongoing damage";
    rAction.clauses = {};
    
    local aClause = {};
    aClause.dice = rEffectComp.dice;
    aClause.modifier = rEffectComp.mod;
    aClause.dmgtype = string.lower(table.concat(rEffectComp.remainder, ","));
    table.insert(rAction.clauses, aClause);
    
    local rRoll = ActionDamage.getRoll(nil, rAction);
    if EffectManager.isGMEffect(nodeActor, nodeEffect) then
      rRoll.bSecret = true;
    end
    ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
  elseif rEffectComp.type == "DMGPSPO" then
    local rAction = {};
    rAction.label = "Ongoing PSP expenditure";
    rAction.clauses = {};
    
    local aClause = {};
    aClause.dice = rEffectComp.dice;
    aClause.modifier = rEffectComp.mod;
    aClause.dmgtype = string.lower(table.concat(rEffectComp.remainder, ","));
    table.insert(rAction.clauses, aClause);
    
    local rRoll = ActionDamagePSP.getRoll(nil, rAction);
    if EffectManager.isGMEffect(nodeActor, nodeEffect) then
      rRoll.bSecret = true;
    end
    ActionsManager.actionDirect(nil, "damage_psp", { rRoll }, { { rTarget } });
  end
end
---- end psionic work

-- replaces the 5E onEffectAddStart()
-- Replace [$STRING_MACROS] here at the start?
local nTIME_TURN = 10;
local nTIME_HOUR = 60;
local nTIME_DAY  = (24 * nTIME_HOUR);
function adndOnEffectAddStart(rNewEffect)
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddStart","rNewEffect",rNewEffect);
	rNewEffect.nDuration = rNewEffect.nDuration or 1;
	if rNewEffect.sUnits == "minute" then
		rNewEffect.nDuration = rNewEffect.nDuration * nTIME_TURN;
	elseif rNewEffect.sUnits == "hour"  then
    rNewEffect.nDuration = rNewEffect.nDuration * nTIME_HOUR;
  elseif rNewEffect.sUnits == "day" then
    rNewEffect.nDuration = rNewEffect.nDuration * nTIME_DAY;
	end
	rNewEffect.sUnits = "";

  local sSource = rNewEffect.sSource;
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddStart","sSource",sSource); 
  if sSource and sSource ~= '' then
    local nodeSource = DB.findNode(sSource);
    if nodeSource then
      local sNewName = rNewEffect.sName;
      -- --- Match $NAME and replace them with the nodeSource name
      sNewName = sNewName:gsub("%[%$NAME%]",DB.getValue(nodeSource,"name","NO-NAME-FOUND"));
      
      -- finally set the string to efffect
      rNewEffect.sName = sNewName;
    end
  end
end

-- AD&D Core only function, rolls dice rolls in [xDx] boxes
-- used for STR: [1d5] style effects, only rolled when applied.
-- moved to AddEnd instead of start because here we get the target node and
-- we can do stuff fancy stuff since we have target node 
-- like [$STR/2] or [$LVL*10], [$ARCANE*10] [$DIVINE*12] 
-- (generic level, arcane level, divine level)
function adndOnEffectAddEnd(nodeTargetEffect, rNewEffect)
  if (not nodeTargetEffect) then
    UtilityManager.logDebug("adndOnEffectAddEnd Error:",nodeTargetEffect, rNewEffect)
    return;
  end

  local nodeTarget = nodeTargetEffect.getChild("...");
  local nodeChar = ActorManager.getCreatureNode(nodeTarget);
  local bisPC = ActorManager.isPC(nodeTarget);
  local bNodeSourceIsPC = false;
  local nodeCaster = nil;
  if (bisPC) then
    nodeCaster = nodeChar;
  else
    nodeCaster = nodeTarget;
  end
  
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeTargetEffect",nodeTargetEffect); 
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeTarget",nodeTarget); 
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeCaster",nodeCaster); 
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeChar",nodeChar); 
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","rNewEffect",rNewEffect); 
  -- setup a nodeSource 
  local sSource = rNewEffect.sSource;
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","sSource",sSource);   
  local nodeSource = nodeCaster; -- if no sSource then it's based from the caster?
  if (sSource and sSource ~= "") then 
    nodeSource = DB.findNode(sSource);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeSource1",nodeSource); 
    if (nodeSource) then
      bNodeSourceIsPC = ActorManager.isPC(nodeSource);
      if bNodeSourceIsPC then
        nodeSource = ActorManager.getCreatureNode(nodeSource);
      end
    end
  else
    --nodeSource = nodeCaster;
  end
  -- end nodeSource
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","->>nodeCaster2",nodeCaster); 
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","nodeSource2",nodeSource); 

  local sEffectFullString = "";
  local sName = rNewEffect.sName;
    -- split the name/label for effect for each:
    -- STRING: tag;STRING: tag;STRING: tag; 
    -- to table of "STRING: tag"
  local aEachEffect = StringManager.split(sName,";",true);
  -- flip through each sEffectName and look for dice
  for _,sEffectName in pairs(aEachEffect) do
    local sNewName = sEffectName;
    -- match some string values for replacement, $NAME

  -- MATCH [1d6] string in effect text 
    for sDice in string.gmatch(sEffectName,"%[(%d+[dD]%d+)%]") do
      local aDice,nMod = StringManager.convertStringToDice(sDice);
      local nRoll = StringManager.evalDice(aDice,nMod);
      sNewName = sNewName:gsub("%[%d+[dD]%d+%]",tostring(nRoll));
-- UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","Dice rolled for effect:",sEffectName,"nRoll=",nRoll);
    end  -- for sDice
    
    local sMidExtra = sNewName:match(":(.*)-%[(.*)%]")

    -- find anything else in []'s and consider it a math function with macros
    -- like [$STR*2] or [$DEX/3] or [$LEVEL*10]
    local nStart, nEnd, sFound = sNewName:find("%[(.*)%]");
    if nStart and nEnd and sFound then     
      for sMacro in string.gmatch(sFound,"%$(%w+)") do
        -- match STR|DEX|CON/etc..
        local sStatName = DataCommon.ability_stol[sMacro];
        if (sStatName) then
          if bisPC then
            local nodeChar = ActorManager.getCreatureNode(nodeTarget);
            nScore = DB.getValue(nodeChar,"abilities." .. sStatName .. ".total",0);
          else
            nScore = DB.getValue(nodeTarget,"abilities." .. sStatName .. ".total",0);
          end
        sFound = sFound:gsub("%$" .. sMacro,tostring(nScore));
        end -- end found sStatName

        -- these need to be run by the source, not the target.
        if nodeCaster then
          -- -- match for $LEVEL
          if sFound:match("%$LEVEL") then
            --sFound = sFound:gsub("%$LEVEL",tostring(CharManager.getActiveClassMaxLevel(nodeCaster)));
            -- Source of the spell is the level variant.
            sFound = sFound:gsub("%$LEVEL",tostring(CharManager.getActiveClassMaxLevel(nodeSource)));
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","adndOnEffectAddEnd","sFound",sFound);             
          end
          -- -- match for $ARCANE
          if sFound:match("%$ARCANE") then
--            sFound = sFound:gsub("%$ARCANE",tostring(PowerManager.getCasterLevelByType(nodeCaster,"arcane",bNodeSourceIsPC)));
            sFound = sFound:gsub("%$ARCANE",tostring(PowerManager.getCasterLevelByType(nodeSource,"arcane",bNodeSourceIsPC)));
          end
          -- -- match for $DIVINE
          if sFound:match("%$DIVINE") then
--            sFound = sFound:gsub("%$DIVINE",tostring(PowerManager.getCasterLevelByType(nodeCaster,"divine",bNodeSourceIsPC)));
            sFound = sFound:gsub("%$DIVINE",tostring(PowerManager.getCasterLevelByType(nodeSource,"divine",bNodeSourceIsPC)));
          end
          -- TODO -- celestian
          -- Add test to check each class [$CLASSNAME] so you can match $MONK or $THIEF so they can get a specific level.
          local aClassList = CharManager.getAllClassNames(nodeSource);
          for _, sClass in pairs(aClassList) do
           local sFindClass = "%$" .. sClass:upper();
           if sFound:match(sFindClass) then
             sFound = sFound:gsub(sFindClass,tostring(CharManager.getClassLevelByName(nodeSource,sClass)));
           end
          end -- aClassList
        end
        --^^ require source
        
        -- target of effect needed macros
        
        -- -- match for $MAXHP
        if sFound:match("%$MAXHP") then
          local nMaxHP = DB.getValue(nodeTarget,"hptotal",0);
          sFound = sFound:gsub("%$MAXHP",tostring(nMaxHP));
        end
        --- match for $CURRENTHP
        if sFound:match("%$CURRENTHP") then
          local nMaxHP = DB.getValue(nodeTarget,"hptotal",0);
          local nWounds = DB.getValue(nodeTarget,"wounds",0);
          local nCurrentHP = nMaxHP - nWounds;
          sFound = sFound:gsub("%$CURRENTHP",tostring(nCurrentHP));
        end
        --- match for $WOUNDS
        if sFound:match("%$WOUNDS") then
          local nWounds = DB.getValue(nodeTarget,"wounds",0);
          sFound = sFound:gsub("%$WOUNDS",tostring(nWounds));
        end
        
      end -- end sMacro for
      
      local nDiceResult = StringManager.evalDiceMathExpression(sFound);   
      -- disabled rounding for DMGX/HEALX so math would work (1.7 or 0.3).
      if not sEffectName:match("^DMGX") and not sEffectName:match("^HEALX") then
        nDiceResult = math.floor(nDiceResult);
      end
      sNewName = UtilityManagerADND.replaceStringAt(sNewName,tostring(nDiceResult),nStart,nEnd);
    end

    local sSep = "";
    if sEffectFullString ~= "" then
      sSep = ";";
    end
    sEffectFullString = sEffectFullString .. sSep .. sNewName;
  end -- for sEffectName
  
  -- we changed the effect name so update
  if (sEffectFullString ~= "") then
    --DB.setValue(nodeTargetEffect,"name","string",sEffectFullString);
    
    DB.setValue(nodeTargetEffect,"label","string",sEffectFullString);
    rNewEffect.sName = sEffectFullString; -- so the chat output is also updated
  end
end

--
-- AD&D Core Only, for Base Str/Dex/etc. handles the BSTR, BPSTR/etc style abilites settings
--
function getEffectsBonusByType(rActor, aEffectType, bAddEmptyBonus, aFilter, rFilterActor, bTargetedOnly)
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsBonusByType","rActor",rActor);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsBonusByType","aEffectType",aEffectType);
  if not rActor or not aEffectType then
    return {}, 0;
  end
  
  -- MAKE BONUS TYPE INTO TABLE, IF NEEDED
  if type(aEffectType) ~= "table" then
    aEffectType = { aEffectType };
  end
  
  -- PER EFFECT TYPE VARIABLES
  local results = {};
  local bonuses = {};
  local penalties = {};
  local nEffectCount = 0;
  
  for k, v in pairs(aEffectType) do
    -- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
    local aEffectsByType = EffectManager5E.getEffectsByType(rActor, v, aFilter, rFilterActor, bTargetedOnly);
--UtilityManagerADND.logDebug("manager_effect_adnd.lua","getEffectsBonusByType","aEffectsByType",aEffectsByType);    

    -- ITERATE THROUGH EFFECTS THAT MATCHED
    for k2,v2 in pairs(aEffectsByType) do
      -- LOOK FOR ENERGY OR BONUS TYPES
      local dmg_type = nil;
      local mod_type = nil;
      local low_type = nil;
      -- this handles the BSTR, BPSTR/etc style abilites settings --celestian

      -- get highest value base
      if (StringManager.contains(DataCommonADND.basetypes, v2.type)) then
        mod_type = v2.type;
      end
      -- get lowest value base
      if (StringManager.contains(DataCommonADND.lowtypes, v2.type)) then
        low_type = v2.type;
      end
      
      for _,v3 in pairs(v2.remainder) do
        if StringManager.contains(DataCommon.dmgtypes, v3) or StringManager.contains(DataCommon.conditions, v3) or v3 == "all" then
          dmg_type = v3;
          break;
        elseif StringManager.contains(DataCommon.bonustypes, v3) or StringManager.contains(DataCommon.powertypes, s) then
          mod_type = v3;
          break;
        end
      end
      
      -- IF MODIFIER TYPE IS UNTYPED, THEN APPEND MODIFIERS
      -- (SUPPORTS DICE)
      if dmg_type or (not mod_type and not low_type) then
        -- ADD EFFECT RESULTS 
        local new_key = dmg_type or "";
        local new_results = results[new_key] or {dice = {}, mod = 0, remainder = {}};

        -- BUILD THE NEW RESULT
        for _,v3 in pairs(v2.dice) do
          table.insert(new_results.dice, v3); 
        end
        if bAddEmptyBonus then
          new_results.mod = new_results.mod + v2.mod;
        else
          new_results.mod = math.max(new_results.mod, v2.mod);
        end
        for _,v3 in pairs(v2.remainder) do
          table.insert(new_results.remainder, v3);
        end

        -- SET THE NEW DICE RESULTS BASED ON ENERGY TYPE
        results[new_key] = new_results;
      
      elseif (low_type) then -- get lowest base value, used for base AC (low is good)
        if (not bonuses[low_type]) then
          bonuses[low_type] = v2.mod;
        elseif (v2.mod < bonuses[low_type]) then
          bonuses[low_type] = v2.mod;
        end
      -- OTHERWISE, TRACK BONUSES AND PENALTIES BY MODIFIER TYPE 
      -- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
      else
        local bStackable = StringManager.contains(DataCommon.stackablebonustypes, mod_type);
        if v2.mod >= 0 then
          if bStackable then
            bonuses[mod_type] = (bonuses[mod_type] or 0) + v2.mod;
          else
            bonuses[mod_type] = math.max(v2.mod, bonuses[mod_type] or 0);
          end
        elseif v2.mod < 0 then
          if bStackable then
            penalties[mod_type] = (penalties[mod_type] or 0) + v2.mod;
          else
            penalties[mod_type] = math.min(v2.mod, penalties[mod_type] or 0);
          end
        end

      end
      
      -- INCREMENT EFFECT COUNT
      nEffectCount = nEffectCount + 1;
    end
  end

  -- COMBINE BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
  for k2,v2 in pairs(bonuses) do
    if results[k2] then
      results[k2].mod = results[k2].mod + v2;
    else
      results[k2] = {dice = {}, mod = v2, remainder = {}};
    end
  end
  for k2,v2 in pairs(penalties) do
    if results[k2] then
      results[k2].mod = results[k2].mod + v2;
    else
      results[k2] = {dice = {}, mod = v2, remainder = {}};
    end
  end

  return results, nEffectCount;
end

-- find effect by name (MIRRORIMAGE, AC, STONESKIN) and return array of nodes
-- Looks for:
-- "sEffectName : ##"
function getEffectNodesByName(nodeCT,sEffectName)
  local nodesFound = {}
  
  for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
    local sLabel = DB.getValue(nodeEffect,"label","");
    if (sLabel:find(sEffectName .. "%s?:%s?%d+")) then
      table.insert(nodesFound,nodeEffect);
    end
  end

  return nodesFound;
end

-- remove count from nodeEffect value
--- MIRRORIMAGE: 13 or STONESKIN: 2
function removeEffectCount(nodeCT, sEffectName, nRemoveCount)
  local nodeEffect = (getEffectNodesByName(nodeCT,sEffectName)[1]);
  if (nodeEffect) then 
    local sLabel = DB.getValue(nodeEffect,"label","");
    local sCount = sLabel:match(sEffectName .. ":%s?(%d+)");
    local nCount = tonumber(sCount) or 0;
    nCount = nCount - nRemoveCount;
    if nCount > 0 then
      -- replace the first one with this new count
      local sReplacedLabel = sLabel:gsub(sLabel,sEffectName .. ":" .. nCount,1);
      if Session.IsHost then
        DB.setValue(nodeEffect,"label","string",sReplacedLabel);
      else 
        -- send to OOB 
        AHDB.setValue(nodeEffect,"label","string",sReplacedLabel);
      end
    else
      EffectManager.removeEffect(nodeCT, sLabel);
    end
  end
end

---
--- Temporary replacement till 3.3.8+ is released?
--- https://www.fantasygrounds.com/forums/showthread.php?47601-The-Source-of-an-effect-question-why-it-s-based-on-CT-Actor-and-not-the-origin
--- CoreRPG scripts/manager_action_effect.lua onEffect()
--- 
-- function bugfix_onEffect(rSource, rTarget, rRoll)
-- --UtilityManagerADND.logDebug("manager_effect_adnd.lua","bugfix_onEffect","rSource",rSource);
-- --UtilityManagerADND.logDebug("manager_effect_adnd.lua","bugfix_onEffect","rTarget",rTarget);
-- --UtilityManagerADND.logDebug("manager_effect_adnd.lua","bugfix_onEffect","rRoll",rRoll);
	-- -- Decode effect from roll
	-- local rEffect = EffectManager.decodeEffect(rRoll);
	-- if not rEffect then
		-- ChatManager.SystemMessage(Interface.getString("ct_error_effectdecodefail"));
		-- return;
	-- end
	
	-- -- If no target, then report to chat window and exit
	-- if not rTarget then
		-- EffectManager.onUntargetedDrop(rEffect);
		-- rRoll.sDesc = EffectManager.encodeEffectAsText(rEffect);

		-- -- Report effect to chat window
		-- local rMessage = ActionsManager.createActionMessage(nil, rRoll);
		-- rMessage.icon = "roll_effect";
		-- Comm.deliverChatMessage(rMessage);
		-- return;
	-- end

	-- -- If target not in combat tracker, then we're done
	-- local sTargetCT = ActorManager.getCTNodeName(rTarget);
	-- if sTargetCT == "" then
		-- ChatManager.SystemMessage(Interface.getString("ct_error_effectdroptargetnotinct"));
		-- return;
	-- end

	-- -- If effect is not a CT effect drag, then figure out source and init
	-- if rEffect.sSource == "" then
		-- local sSourceCT = "";
    -- -- bugfix
    -- if rSource then
			-- sSourceCT = ActorManager.getCTNodeName(rSource);
-- --UtilityManagerADND.logDebug("manager_effect_adnd.lua","onEffect","sSourceCT",sSourceCT);
		-- end    
    -- -- end bugfix
		-- if sSourceCT == "" then
			-- local nodeTempCT = nil;
			-- if Session.IsHost then
				-- nodeTempCT = CombatManager.getActiveCT();
			-- else
				-- nodeTempCT = CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity());
			-- end
			-- if nodeTempCT then
				-- sSourceCT = nodeTempCT.getNodeName();
			-- end
		-- end
		-- if sSourceCT ~= "" then
			-- rEffect.sSource = sSourceCT;
			-- EffectManager.onEffectSourceChanged(rEffect, DB.findNode(sSourceCT));
		-- end
	-- end
	
	-- -- If source is same as target, then don't specify a source
	-- if rEffect.sSource == sTargetCT then
		-- rEffect.sSource = "";
	-- end
	
	-- -- If source is non-friendly faction and target does not exist or is non-friendly, then effect should be GM only
	-- if (rSource and ActorManager.getFaction(rSource) ~= "friend") and (not rTarget or ActorManager.getFaction(rTarget) ~= "friend") then
		-- rEffect.nGMOnly = 1;
	-- end
	
	-- -- Resolve
	-- -- If shift-dragging, then apply to the source actor targets, then target the effect to the drop target
	-- if rRoll.aTargets then
		-- local aTargets = StringManager.split(rRoll.aTargets, "|");
		-- for _,v in ipairs(aTargets) do
			-- rEffect.sTarget = sTargetCT;
			-- EffectManager.notifyApply(rEffect, v);
		-- end
	
	-- -- Otherwise, just apply effect to drop target normally
	-- else
		-- EffectManager.notifyApply(rEffect, sTargetCT);
	-- end
-- end

--[[ 
  Get all effects and effects with auras that affect nodeCT. 
  In general, this typically replaces 
  "for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do ... end"
  in various functions.
  
  AURA [range] [target]
  range  = distance 5, 10, 13, etc
  target = all, foe, friend, neutral
  
]]
function getEffectsList(nodeCT)
--UtilityManagerADND.logDebug("manager_effect_adnd","getEffectsList","nodeCT:",DB.getValue(nodeCT,"name",""));   
local aEffectList = {};

  if nodeCT then
    for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
      -- we ignore AURA effects here, add them later 
      -- to check if they affect us
      if not isAuraEffect(nodeEffect) then
        table.insert(aEffectList,nodeEffect);
      end
    end

    -- this will get auras of my own that are in effect on me.
    local aEffectListMyAuras = getAuraEffects(nodeCT,nodeCT,0);
    -- get auras affecting me from nearby tokens
    local aEffectListAuras = getEffectAurasFromAllTokens(nodeCT);
    -- append all effects to one array
    UtilityManagerADND.concatTables(aEffectList,aEffectListMyAuras);
    UtilityManagerADND.concatTables(aEffectList,aEffectListAuras);

  -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectsList","aEffectList2",aEffectList);   
  end

  return aEffectList;
end

--[[ This will return ONLY effects that are auras and effecting this nodeCT ]]
function getEffectsListAuras(nodeCT)
-- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectsListAuras","nodeCT",nodeCT);   
  local aEffectList = {};
  if nodeCT then
    -- this will get auras of my own that are in effect on me.
    local aEffectListMyAuras = getAuraEffects(nodeCT,nodeCT,0);
    -- get auras affecting me from nearby tokens
    local aEffectListAuras = getEffectAurasFromAllTokens(nodeCT);
    -- append all effects to one array
    UtilityManagerADND.concatTables(aEffectList,aEffectListMyAuras);
    UtilityManagerADND.concatTables(aEffectList,aEffectListAuras);
  end
  return aEffectList;
end

-- get effects that have auras within range.
function getEffectAurasFromAllTokens(nodeSourceCT)
-- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","nodeSourceCT",nodeSourceCT);        
  local aAuraEffects = {};
  local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","tokenSource",tokenSource);   

  if aAuraEffects and tokenSource then
    local imageControl = ImageManager.getImageControl(tokenSource, true);
    if imageControl then
      for _, tokenTarget in pairs(imageControl.getTokens()) do
-- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","tokenTarget",tokenTarget);   
        local nDistance = TokenManagerADND.getTokenDistanceBetween(tokenSource,tokenTarget);
        local imageSource = ImageManager.getImageControl(tokenSource);
        local imageTarget = ImageManager.getImageControl(tokenTarget);    
        local nSourceID = tokenSource.getId();
        local nTargetID = tokenTarget.getId();
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","nSourceID",nSourceID);   
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","nTargetID",nTargetID);   

        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","nDistance",nDistance);   
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","imageSource",imageSource);   
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","imageTarget",imageTarget);   

        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","nSourceID ~= nTargetID",nSourceID ~= nTargetID)
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","imageSource and imageTarget",imageSource and imageTarget)
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","imageSource == imageTarget",imageSource == imageTarget)
        -- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","imageSource.hasGrid()",imageSource.hasGrid())
        if nSourceID ~= nTargetID and imageSource and imageTarget and 
            imageSource == imageTarget then
            local nodeTargetCT = CombatManager.getCTFromToken(tokenTarget);
-- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","nodeTargetCT",nodeTargetCT);        
            --local aTargetAuras = getEffectsList(nodeTargetCT,{'aura'});
            local aTargetAuras = getAuraEffects(nodeTargetCT,nodeSourceCT,nDistance);
            UtilityManagerADND.concatTables(aAuraEffects,aTargetAuras);
-- UtilityManagerADND.logDebug("manager_effect_adnd","getEffectAurasFromAllTokens","aTargetAuras",aTargetAuras);        
        end
        
      end
    end
  end
  return aAuraEffects;
end

--[[ 
  Get all effects that have "AURA" in them that are active
  between source->target
]]
function getAuraEffects(nodeSourceCT,nodeTargetCT,nDistance)
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","nodeSourceCT",nodeSourceCT);    
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","nodeTargetCT",nodeTargetCT);    
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","nDistance",nDistance);    
  local aAuraEffects = {};
  local sTargetFF = DB.getValue(nodeTargetCT,"friendfoe","");
  local sSourceFF = DB.getValue(nodeSourceCT,"friendfoe","");
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","sTargetFF",sTargetFF);  
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","sSourceFF",sSourceFF);  
  for _,nodeEffect in pairs(DB.getChildren(nodeSourceCT, "effects")) do
    -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","nodeEffect",nodeEffect);  
    local nActive = DB.getValue(nodeEffect, "isactive", 0);
    if nActive == 1 then 
      local nRange, sFaction, sColor = getAuraValues(nodeEffect);
      -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","sFaction",sFaction);  
      -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","sColor",sColor);  
      -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","nRange",nRange);    
    if nRange > 0 then
        local bValid = false;
        -- FGU does fuzzy math with values in distances (ignores .5)
        if (nDistance <= nRange) then
          -- does the faction match for target?
          if sFaction == 'all' then
            bValid = true;
            -- if target is same faction they are friendly
          elseif sFaction == 'friend' and (sTargetFF == sSourceFF) then
            bValid = true;
            -- if target is not same faction it's a foe
          elseif sFaction == 'foe' and (sTargetFF ~= sSourceFF) then
            bValid = true;
            -- neutral is just plain neutral
          elseif sFaction == 'neutral' and (sTargetFF == 'neutral') then
            bValid = true;
          end
          -- UtilityManagerADND.logDebug("manager_effect_adnd","getAuraEffects","bValid",bValid);  
          -- found active aura, add to list
          if bValid then
            table.insert(aAuraEffects,nodeEffect);
          end
        end
        -- if we found an AURA we go to next, checking the rest
        -- you shouldn't have multiple auras in a single effect label
        break;
      end
    end
  end
  return aAuraEffects;
end


-- does effect contain AURA: X XX ?
function isAuraEffect(nodeEffect)
  return (getAuraEffect(nodeEffect) ~= nil);
end
-- return the "aura" portion of an effect label
function getAuraEffect(nodeEffect)
  local sAura = nil;
  local sLabel = DB.getValue(nodeEffect,"label","");
  local aEntries = StringManager.split(sLabel,";",true);
  for _,sEffect in ipairs(aEntries) do
    if sEffect:match("^AURA[%s]?:") then
      sAura = sEffect;
      break;
    end
  end
  return sAura;
end
-- get range,faction and color from an effect string
function getAuraValues(nodeEffect)
  local nRange   = -1;
  local sRange   = nil;
  local sFaction = nil;
  local sColor   = nil;
  local sColorDefault = "2EDAA520";
  local sEffect  = getAuraEffect(nodeEffect);
  if sEffect then
    -- Define the pattern
    local pattern = "^AURA%s?:%s?(%d+)%s*([#%w]*)%s*([%w-]*)$";

    -- Attempt to match the string
    sRange, sColor, sFaction = sEffect:match(pattern)

    if not sRange then
        UtilityManager.logDebug("Error: Invalid aura. Correct example: 'AURA: 20 red foe' or 'AURA: 20 red foe;ATK -2'");
        return null;
    end
    -- sRange, sFaction , sColor = sEffect:match("^AURA[%s]?:[%s]?(%d+) ([%w]+) ([a-zA-Z0-9%#]+)");
    nRange = tonumber(sRange) or 0;
    if not sFaction then
      sFaction = "all";
    end

    if not sColor or sColor == "" or sColor:match("^#") then
      sColor = sColorDefault; -- default is goldenrod
    elseif DataCommonADND.auraColors[sColor] then
      sColor = "2E" .. DataCommonADND.auraColors[sColor]
    elseif sColor:lower() == 'none' then
      sColor = "00000000";
    elseif sColor:len() == 6 then
      sColor = "2E" .. sColor
    elseif sColor:len() <= 7  then -- bogus color code
      sColor = sColorDefault; -- default is goldenrod
    end
    --UtilityManagerADND.logDebug("manager_effects_adnd.lua","getAuraValues","sColor",sColor);
  end
  return nRange, sFaction, sColor;
end
function getAuraRange(nodeEffect)
  local nRange,_,_ = getAuraValues(nodeEffect);
  return (nRange);
end
function getAuraFaction(nodeEffect)
  local _,sFaction,_ = getAuraValues(nodeEffect);
  return (sFaction);
end
function getAuraColor(nodeEffect)
  local _,_,sColor = getAuraValues(nodeEffect);
  return (sColor);
end

--
-- EFFECT TURN CHANGE HANDLING
--
-- overridden to use getEffectsList()
local nInitDirection = 1;
function processEffects(nodeCurrentActor, nodeNewActor)
--UtilityManagerADND.logDebug("manager_effect_adnd","processEffects","nodeCurrentActor",nodeCurrentActor);
	-- Get sorted combatant list
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries == 0 then
		return;
	end
		
	-- Set up current and new initiative values for effect processing
	local nCurrentInit;
	if nodeCurrentActor then
		nCurrentInit = DB.getValue(nodeCurrentActor, "initresult", 0); 
	elseif nInitDirection > 0 then
		nCurrentInit = -10000;
	else
		nCurrentInit = 10000;
	end
	local nNewInit;
	if nodeNewActor then
		nNewInit = DB.getValue(nodeNewActor, "initresult", 0);
	elseif nInitDirection > 0 then
		nNewInit = 10000;
	else
		nNewInit = -10000;
	end
	
	-- For each actor, advance durations, and process start of turn special effects
	local bProcessSpecialStart = (nodeCurrentActor == nil);
	local bProcessSpecialEnd = (nodeCurrentActor == nil);
	for i = 1,#aEntries do
		local nodeActor = aEntries[i];
		
		if nodeActor == nodeCurrentActor then
			bProcessSpecialEnd = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialEnd = false;
		end

    local nodeCT = ActorManager.getCTNode(nodeActor);

    -- FOR DELAY ACTION? -celestian
    -- skip this section if the player has already had a "round" in the initiative.
    local bHadInitAlready = (DB.getValue(nodeCT,"initrun",0)==1);
--UtilityManagerADND.logDebug("manager_effect_adnd","processEffects","NAME",DB.getValue(nodeCT,"name"));        
--UtilityManagerADND.logDebug("manager_effect_adnd","processEffects","DB.getValue(nodeCT,initrun,0)",DB.getValue(nodeCT,"initrun",0));    
--UtilityManagerADND.logDebug("manager_effect_adnd","processEffects","bHadInitAlready",bHadInitAlready);    
    if not bHadInitAlready then 

      -- Check each effect
      -- get effects on the token and process (expire/etc)
      for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
        -- skip aura processing, its special, otherwise process
        if not isAuraEffect(nodeEffect) then
          EffectManager.processEffect(nodeActor, nodeEffect, nCurrentInit, nNewInit, bProcessSpecialStart, bProcessSpecialEnd);
        else
          -- all we do with auras on token is tick down duration...we process aura effects later
          processAuraEffectDuration(nodeActor,nodeEffect,nCurrentInit, nNewInit);
        end
        
        -- this sets the value that they've had initiative already so we only run effects once.
      end
      -- if bProcessSpecialEnd then this actor is the active init CT so we 
      -- do not process them again
      if bProcessSpecialEnd then
        DB.setValue(nodeCT,"initrun","number",1);
      end
    end
    
    -- get auras affecting token and process now
    for _,nodeEffect in ipairs(getEffectsListAuras(nodeCT)) do
      if (bProcessSpecialStart) then
        onEffectActorStartTurn(nodeActor, nodeEffect);
      end
      --EffectManager.processEffect(nodeActor, nodeEffect, nCurrentInit, nNewInit, bProcessSpecialStart, bProcessSpecialEnd);
    end
  
		if nodeActor == nodeCurrentActor then
			bProcessSpecialStart = true;
		elseif nodeActor == nodeNewActor then
			bProcessSpecialStart = false;
		end
	end -- END ACTOR LOOP
end

--[[
  This is to process durations for auras. They are kinda special because they are "shown" on 
  a token but are not the source of it, so what we do is only run duration checks for auras 
  and pass them through here.

]]
-- local aEffectVarMap = {
-- 	["nDuration"] = { sDBType = "number", sDBField = "duration", vDBDefault = 1, sDisplay = "[D: %d]" },
-- 	["nInit"] = { sDBType = "number", sDBField = "init", sSourceChangeSet = "initresult", bClearOnUntargetedDrop = true },
-- };
function processAuraEffectDuration(nodeActor,nodeEffect,nCurrentInit, nNewInit)
  if aEffectVarMap["nInit"] then
    local nEffInit = DB.getValue(nodeEffect, aEffectVarMap["nInit"].sDBField, aEffectVarMap["nInit"].vDBDefault or 0);
  
    -- Apply start of effect initiative changes
    if ((nInitDirection > 0) and (nEffInit > nCurrentInit and nEffInit <= nNewInit)) or (nEffInit < nCurrentInit and nEffInit >= nNewInit) then
      -- Start turn
      if aEffectVarMap["nDuration"] then
        local nDuration = DB.getValue(nodeEffect, aEffectVarMap["nDuration"].sDBField, 0);
        if nDuration > 0 then
          nDuration = nDuration - 1;
          if nDuration <= 0 then
            EffectManager.expireEffect(nodeActor, nodeEffect, 0);
            return;
          end
          DB.setValue(nodeEffect, "duration", "number", nDuration);
        end
      end
    end
  end
end
