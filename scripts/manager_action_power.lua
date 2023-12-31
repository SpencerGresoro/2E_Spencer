-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVEVS = "applysavevs";

function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVEVS, handleApplySave);

  ActionsManager.registerTargetingHandler("cast", onPowerTargeting);
  ActionsManager.registerTargetingHandler("powersave", onPowerTargeting);
  
  ActionsManager.registerModHandler("castsave", modCastSave);
  ActionsManager.registerModHandler("powersave", modCastSave);
  
  ActionsManager.registerResultHandler("cast", onPowerCast);
  ActionsManager.registerResultHandler("castsave", onCastSave);
  ActionsManager.registerResultHandler("powersave", onPowerSave);
end

function handleApplySave(msgOOB)
-- UtilityManagerADND.logDebug("manager_action_power.lua handleApplySave msgOOB",msgOOB);
  local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
  local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
  local sSaveType = msgOOB.sSaveType;
  local rJSON = Utility.decodeJSON(msgOOB.sJSONData);

  --local sSaveShort, sSaveDC = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
  if sSaveType then
    local sSave = DataCommon.saves_multi_name[sSaveType];
    if sSave then
      ActionSave.performRoll(nil, rTarget, sSave, msgOOB.nDC, (tonumber(msgOOB.nSecret) == 1), rSource, msgOOB.bRemoveOnMiss, msgOOB.sDesc,rJSON);
    end
  end
end

--function notifyApplySave(rSource, rTarget, bSecret, sDesc, nDC, bRemoveOnMiss, sSaveType)
function notifyApplySave(rSource, rTarget, rRoll, nDC)
--  UtilityManagerADND.logDebug("manager_action_power.lua","notifyApplySave","rSource",rSource);      
--  UtilityManagerADND.logDebug("manager_action_power.lua","notifyApplySave","rTarget",rTarget);      
  --UtilityManagerADND.logDebug("manager_action_power.lua","notifyApplySave","rRoll",rRoll);      
  if not rTarget then
    return;
  end

  local bSecret = rRoll.bSecret;
  local sDesc = rRoll.sDesc;
  local bRemoveOnMiss = rRoll.bRemoveOnMiss;
  local sSaveType = rRoll.sSaveType;

  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYSAVEVS;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sDesc = sDesc;
  msgOOB.nDC = nDC;

    local sSave = sSaveType;
    if (sSaveType) then
        msgOOB.sSaveType = sSaveType;
    else
        msgOOB.sSaveType = "";
    end

  -- msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
  -- msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
  msgOOB.sTargetType = sTargetType;
  msgOOB.sTargetNode = sTargetNode;  

  if bRemoveOnMiss then
    msgOOB.bRemoveOnMiss = 1;
  end

  rJSON = {};
  rJSON.initialized = "SET"
  rJSON.sPowerProperties = rRoll.sPowerProperties;
  -- ...
  msgOOB.sJSONData = Utility.encodeJSON(rJSON);

  if ActorManager.isPC(rTarget) then
    local nodePC = ActorManager.getCreatureNode(rTarget);
    if nodePC then
      if Session.IsHost then
        local sOwner = DB.getOwner(nodePC);
        if sOwner ~= "" then
          for _,vUser in ipairs(User.getActiveUsers()) do
            if vUser == sOwner then
              for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
                if nodePC.getName() == vIdentity then
                  Comm.deliverOOBMessage(msgOOB, sOwner);
                  return;
                end
              end
            end
          end
        end
      else
        if DB.isOwner(nodePC) then
          handleApplySave(msgOOB);
          return;
        end
      end
    end
  end

  Comm.deliverOOBMessage(msgOOB, "");
end

function onPowerTargeting(rSource, aTargeting, rRolls)
  local bRemoveOnMiss = false;
  local sOptRMMT = OptionsManager.getOption("RMMT");
  if sOptRMMT == "on" then
    bRemoveOnMiss = true;
  elseif sOptRMMT == "multi" then
    local aTargets = {};
    for _,vTargetGroup in ipairs(aTargeting) do
      for _,vTarget in ipairs(vTargetGroup) do
        table.insert(aTargets, vTarget);
      end
    end
    bRemoveOnMiss = (#aTargets > 1);
  end
  
  if bRemoveOnMiss then
    for _,vRoll in ipairs(rRolls) do
      vRoll.bRemoveOnMiss = "true";
    end
  end
  return aTargeting;
end

function getPowerCastRoll(rActor, rAction)
  --UtilityManagerADND.logDebug("manager_action_power.lua","getPowerCastRoll","rAction",rAction); 
  local rRoll = {};
  rRoll.sType = "cast";
  rRoll.aDice = {};
  rRoll.nMod = 0;
  
  rRoll.sDesc = "[CAST";
  if rAction.order and rAction.order > 1 then
    rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
  end
  rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
  
  return rRoll;
end

-- sort out saves for targets from actions tab button "save" -celestian
function getSaveVsRoll(rActor, rAction)
--UtilityManagerADND.logDebug("manager_action_power.lua","getSaveVsRoll","rAction.savemod",rAction.savemod);    
-- UtilityManagerADND.logDebug("manager_action_power.lua getSaveVsRoll rAction",rAction);    
    
  local rRoll = {};
  rRoll.sType = "powersave";
  rRoll.aDice = {};
  rRoll.nMod = rAction.savemod or 0;
  rRoll.sSaveType = rAction.save;
  rRoll.sPowerProperties = rAction.properties;
  local sSaveDisplayText = StringManager.capitalize(rAction.save);
  local sSaveType = DataCommon.saves_multi_name[rAction.save];

  rRoll.sDesc = "[SAVE VS";
  if rAction.order and rAction.order > 1 then
    rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
  end
  rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
--  if DataCommon.ability_ltos[rAction.save] then
  if sSaveDisplayText and rAction.savemod ~= 0 then
    --rRoll.sDesc = rRoll.sDesc .. " [" .. DataCommon.ability_ltos[rAction.save] .. " DC " .. rAction.savemod .. "]";
    rRoll.sDesc = rRoll.sDesc .. " [" .. sSaveDisplayText .. " ADJ " .. rAction.savemod .. "]";
  end
  if rAction.onmissdamage == "half" then
    rRoll.sDesc = rRoll.sDesc .. " [HALF ON SAVE]";
  end

  return rRoll;
end

function performSaveVsRoll(draginfo, rActor, rAction)
  local rRoll = getSaveVsRoll(rActor, rAction);
  --UtilityManagerADND.logDebug("manager_action_power.lua","performSaveVsRoll","rRoll",rRoll);    
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modCastSave(rSource, rTarget, rRoll)
  -- if ModifierStack.getModifierKey("DEF_SCOVER") then
    -- rRoll.sDesc = rRoll.sDesc .. " [COVER -5]";
  -- elseif ModifierStack.getModifierKey("DEF_COVER") then
    -- rRoll.sDesc = rRoll.sDesc .. " [COVER -2]";
  -- end
--  UtilityManagerADND.logDebug("manager_action_power.lua","modCastSave","rRoll2",rRoll);    
end

function onPowerCast(rSource, rTarget, rRoll)
  --UtilityManagerADND.logDebug("manager_action_power.lua","onPowerCast","rRoll",rRoll);    
  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  rMessage.dice = nil;
  rMessage.icon = "roll_cast";

  if rTarget then
    rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
  end
  
  Comm.deliverChatMessage(rMessage);
end

function onCastSave(rSource, rTarget, rRoll)
  -- UtilityManagerADND.logDebug("manager_action_power.lua onCastSave rRoll",rRoll);    
  if rTarget and rRoll.sSaveType then
    -- local nodeTarget = ActorManager.getCreatureNode(rTarget);
    local _, nodeTarget = ActorManager.getTypeAndNode(rTarget);
    -- get Target score to save
    local sSave = DataCommon.saves_multi_name[rRoll.sSaveType];
    local nSaveTarget = DB.getValue(nodeTarget, "saves." .. sSave .. ".score",0);
    -- flip value, if minues to save, make target higher (harder)
    -- if positive, it will lower the target making easier -celestian
    -- nSaveTarget = nSaveTarget - (rRoll.nMod); 
    
    --notifyApplySave(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, nSaveTarget, rRoll.bRemoveOnMiss, rRoll.sSaveType);
    notifyApplySave(rSource, rTarget, rRoll, nSaveTarget);
    
    return true;
  end

  return false;
end

function onPowerSave(rSource, rTarget, rRoll)
  --UtilityManagerADND.logDebug("manager_action_power.lua","onPowerSave","rRoll",rRoll);    
  if onCastSave(rSource, rTarget, rRoll) then
    return;
  end

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  Comm.deliverChatMessage(rMessage);
end
