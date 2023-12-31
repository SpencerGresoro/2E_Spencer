-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
OOB_MSGTYPE_APPLYCONC = "applyconc";

function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCONC, handleApplyConc);

  ActionsManager.registerModHandler("save", modSave);
  ActionsManager.registerResultHandler("save", onSave);

  ActionsManager.registerResultHandler("concentration", onConcentrationRoll);
    -- callback for mirror/stoneskins
  ActionsManager.registerResultHandler("roll_against_magic_resist", checkMagicResist);

end

function handleApplySave(msgOOB)
-- UtilityManagerADND.logDebug("manager_action_save.lua handleApplySave msgOOB",msgOOB);     
  local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
  local rOrigin = ActorManager.resolveActor(msgOOB.sTargetNode);
  
  local rAction = {};
  rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
  rAction.sDesc = msgOOB.sDesc;
  rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
  rAction.sSaveDesc = msgOOB.sSaveDesc;
  rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
  rAction.sResult = msgOOB.sResult;
  rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);
  
  -- local rJSON = Utility.decodeJSON(msgOOB.sJSONData);
  local rJSON = Utility.decodeJSON(msgOOB.sJSONData);
  rAction.properties = rJSON.sPowerProperties;

  applySave(rSource, rOrigin, rAction , rJSON);
end

function notifyApplySave(rSource, bSecret, rRoll)
-- UtilityManagerADND.logDebug("manager_action_save.lua notifyApplySave rSource",rSource);    
-- UtilityManagerADND.logDebug("manager_action_save.lua notifyApplySave rRoll",rRoll);    
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sDesc = rRoll.sDesc;
  msgOOB.nTotal = ActionsManager.total(rRoll);
  msgOOB.sSaveDesc = rRoll.sSaveDesc;
  msgOOB.nTarget = rRoll.nTarget;
  msgOOB.sResult = rRoll.sResult;
  msgOOB.sPowerProperties = rRoll.sPowerProperties;
  if rRoll.bRemoveOnMiss then msgOOB.nRemoveOnMiss = 1; end

  -- msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;  

  if rRoll.sSource ~= "" then
    msgOOB.sTargetNode = rRoll.sSource;
  else
    msgOOB.sTargetNode = "";
  end
  
  rJSON = {};
  rJSON.initialized = "SET"
  rJSON.sPowerProperties = rRoll.sPowerProperties;
  -- ...
  msgOOB.sJSONData = Utility.encodeJSON(rJSON);  

  Comm.deliverOOBMessage(msgOOB, "");
end

function performRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc,rJSON)
-- UtilityManagerADND.logDebug("manager_action_save.lua performRoll draginfo",draginfo);  
-- UtilityManagerADND.logDebug("manager_action_save.lua performRoll rJSON",rJSON);  
-- UtilityManagerADND.logDebug("manager_action_save.lua performRoll rJSON",nTargetDC);  
  local rRoll = {};
  rRoll.rJSON = rJSON;
  rRoll.sType = "save";
  rRoll.aDice = { "d20" };
  local nMod, bADV, bDIS, sAddText = ActorManagerADND.getSave(rActor, sSave);
  rRoll.nMod = nMod;
  local sPrettySaveText = DataCommon.saves_stol[sSave];
  rRoll.sDesc = "[SAVE] vs. " .. StringManager.capitalize(sPrettySaveText);
  if sAddText and sAddText ~= "" then
    rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
  end
  -- if bADV then
  --   rRoll.sDesc = rRoll.sDesc .. " [ADV]";
  -- end
  -- if bDIS then
  --   rRoll.sDesc = rRoll.sDesc .. " [DIS]";
  -- end
  rRoll.bSecret = bSecretRoll;
  
  rRoll.nTarget = nTargetDC;

  if bRemoveOnMiss then
    rRoll.bRemoveOnMiss = "true";
  end
  if sSaveDesc then
    rRoll.sSaveDesc = sSaveDesc;
  end
  if rSource then
    rRoll.sSource = ActorManager.getCTNodeName(rSource);
  end

  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSave(rSource, rTarget, rRoll)
  --UtilityManagerADND.logDebug("manager_action_save","modSave","rSource",rSource);
  --UtilityManagerADND.logDebug("manager_action_save","modSave","rTarget",rTarget);
  --UtilityManagerADND.logDebug("manager_action_save","modSave","rRoll",rRoll);
  local bAutoFail = false;

  local sSave = nil;
  if rRoll.sDesc:match("%[DEATH%]") then
    sSave = "death";
  elseif rRoll.sDesc:match("%[CONCENTRATION%]") then
    sSave = "concentration";
  else
    sSave = rRoll.sDesc:match("%[SAVE%] vs%. (%w+)");
    if sSave then
      sSave = sSave:lower();
    end
  end

  local bADV = false;
  local bDIS = false;
  if rRoll.sDesc:match(" %[ADV%]") then
    bADV = true;
    rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
  end
  if rRoll.sDesc:match(" %[DIS%]") then
    bDIS = true;
    rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
  end

  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
  
  local nCover = 0;
  -- if sSave == "dexterity" then
    -- if rRoll.sSaveDesc then
      -- nCover = tonumber(rRoll.sSaveDesc:match("%[COVER %-(%d)%]")) or 0;
    -- else
      -- if ModifierStack.getModifierKey("DEF_SCOVER") then
        -- nCover = 5;
      -- elseif ModifierStack.getModifierKey("DEF_COVER") then
        -- nCover = 2;
      -- end
    -- end
  -- end
  
  -- Check defense modifiers
  local nCoverMod = 0;
  local nConcealMod = 0;
  local nTraitSaveMod = 0;
  if ModifierStack.getModifierKey("DEF_COVER_25") then
    nCoverMod = 2;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[COVER 25%]";
  end
  if ModifierStack.getModifierKey("DEF_COVER_50") then
    nCoverMod = 4;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[COVER 50%]";
  end
  if ModifierStack.getModifierKey("DEF_COVER_75") then
    nCoverMod = 7;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[COVER 75%]";
  end
  if ModifierStack.getModifierKey("DEF_COVER_90") then
    nCoverMod = 10;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[COVER 90%]";
  end
  if ModifierStack.getModifierKey("DEF_CONCEAL_25") then
    nConcealMod = 1;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[CONCEALED 25%]";
  end
  if ModifierStack.getModifierKey("DEF_CONCEAL_50") then
    nConcealMod = 2;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[CONCEALED 50%]";
  end
  if ModifierStack.getModifierKey("DEF_CONCEAL_75") then
    nConcealMod = 3;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[CONCEALED 75%]";
  end
  if ModifierStack.getModifierKey("DEF_CONCEAL_90") then
    nConcealMod = 4;
    rRoll.sDesc = rRoll.sDesc .. " " .. "[CONCEALED 90%]";
  end
  
  if rSource then
    local bEffects = false;
    
    -- Build filter
    local aSaveFilter = {};
    if sSave then
      table.insert(aSaveFilter, sSave);
    end

    -- Get effect modifiers
    local rSaveSource = nil;
    if rRoll.sSource then
      rSaveSource = ActorManager.resolveActor( rRoll.sSource);
    end

    -- Grab the SAVE values. 
    -- Cast powers have a properties field which is where the types association is derived.
    -- valid types are all DataCommon.dmgtypes and DataCommon.powertypes
    -- SAVE:X = save applied to all
    -- SAVE:X,type,type = save applies only to those types. 
    -- 
    --local aSaveList = EffectManager5E.getEffectsBonusByType(rTarget, {"SAVE"}, true, {rRoll.sSaveType}, rTarget, true);
    local aSaveTypeList = EffectManager5E.getEffectsByType(rSource, "SAVE", aSaveFilter, rSaveSource);
    -- local aSaveList, nEffectCount = EffectManager5E.getEffectsBonusByType(rSource, {'SAVE'}, true, {}, nil);
    -- UtilityManagerADND.logDebug("manager_action_save.lua","modSave","aSaveList",aSaveList);  
    local aProperties = {};     
    if rRoll.rJSON and rRoll.rJSON.sPowerProperties then
      local sProperties = rRoll.rJSON.sPowerProperties:lower() or "";
      aProperties = StringManager.split(sProperties, ",", true);
      -- this is here because for whatever reason having rRoll.rJSON doesn't pass through the resultHandler.
      -- we need this in onSave()
      rRoll.sPowerProperties = rRoll.rJSON.sPowerProperties;
    end

    for k, v in pairs(aSaveTypeList) do
      -- if the save effect has a remainder, it has a type, SAVE: 4,fire,cold,acid
      if #v.remainder > 0 then
        -- if properties doesn't exist we dont need to check
        if #aProperties > 0 then
          for _,sPowerProperty in ipairs(aProperties) do
            -- if the property is a damage/power type and it exists in the effect type
            if (StringManager.contains(DataCommon.dmgtypes,sPowerProperty) or StringManager.contains(DataCommon.powertypes,sPowerProperty)) and 
              StringManager.contains(v.remainder,sPowerProperty) then
                -- UtilityManagerADND.logDebug("manager_action_save.lua","modSave","FOUND MATCH","sPowerProperty",sPowerProperty); 
                rRoll.sDesc = rRoll.sDesc  .. ' [' .. StringManager.capitalize(sPowerProperty) .. UtilityManagerADND.getNumberSign(v.mod) .. ']';
                nAddMod = nAddMod + v.mod;
                bEffects = true;
                break;
            end
          end
        end
      else
        -- no remainder so we have plain SAVE:X
        -- UtilityManagerADND.logDebug("manager_action_save.lua","modSave","no remainder so we have plain SAVE:X");
        bEffects = true;
        nAddMod = nAddMod + v.mod;
      end
    end

    ---

  -- Get save modifiers
    local nBonusSave, nBonusSaveEffects = EffectManager5E.getEffectsBonus(rSource, sSave:upper(),true);
    if nBonusSaveEffects > 0 then
      bEffects = true;
      nAddMod = nAddMod + nBonusSave;
    end
    
    -- Save is 4 worse when blinded
    if EffectManager5E.hasEffect(rSource, "BLINDED", nil) then
      bEffects = true;
      nAddMod = nAddMod - 4;
    end
    -- check racial traits for adjustments
    nTraitSaveMod = getRacialSaveAdjustments(rSource,sSave);
    if nTraitSaveMod > 0 then
      rRoll.sDesc = rRoll.sDesc .. " [CON +" .. nTraitSaveMod .. "]";
    end
    
    -- conceal save bonuses
    if EffectManager5E.hasEffect(rSource, "CONCEAL25", nil) then
      bEffects = true;
      nCover = 1;
    end
    
    if EffectManager5E.hasEffect(rSource, "CONCEAL50", nil) then
      bEffects = true;
      nCover = 2;
    end
    
    if EffectManager5E.hasEffect(rSource, "CONCEAL75", nil) then
      bEffects = true;
      nCover = 3;
    end
    
    if EffectManager5E.hasEffect(rSource, "CONCEAL90", nil) then
      bEffects = true;
      nCover = 4;
    end
    
    -- cover save bonuses
    if EffectManager5E.hasEffect(rSource, "COVER25", nil) then
      bEffects = true;
      nCover = 2;
    end
    if EffectManager5E.hasEffect(rSource, "COVER50", nil) then
      bEffects = true;
      nCover = 4;
    end
    
    if EffectManager5E.hasEffect(rSource, "COVER75", nil) then
      bEffects = true;
      nCover = 7;
    end
    
    if EffectManager5E.hasEffect(rSource, "COVER90", nil) then
      bEffects = true;
      nCover = 10;
    end

    if rRoll.sSaveDesc then
      if rRoll.sSaveDesc:match("%[MAGIC%]") then
        -- added my own checks here for MR:%d+ where %d+ is a percent --celestian
        if EffectManager5E.hasEffectCondition(rSource, "MR") then
          bEffects = true;
        end
      end
      -- looking for "[SAVE VS] Acid Spew [Breath ADJ -3]" type entries
      local sSaveMod = rRoll.sSaveDesc:match("%[SAVE VS%] [%w%s]+ %[[%w]+ ADJ [%-%d]+%]");
      if sSaveMod then
        local sAdjustmentMod = rRoll.sSaveDesc:match("%[SAVE VS%] [%w%s]+ %[[%w]+ ADJ ([%-%d]+)%]") or 0;
        local nAdjustmentMod = tonumber(sAdjustmentMod) or 0;
        rRoll.nMod = rRoll.nMod + nAdjustmentMod;
        local sAdjChar = "+";
        if nAdjustmentMod < 0 then sAdjChar = ""; end;
        rRoll.sDesc = rRoll.sDesc .. " " .. "[ADJ " .. sAdjChar .. sAdjustmentMod .. "]";
      end
    end
    
    -- Get exhaustion modifiers
    local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
    if nExhaustCount > 0 then
      bEffects = true;
      if nExhaustMod >= 3 then
        bDIS = true;
      end
    end
    
    -- If effects apply, then add note
    if bEffects then
      for _, vDie in ipairs(aAddDice) do
        if vDie:sub(1,1) == "-" then
          table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
        else
          table.insert(rRoll.aDice, "p" .. vDie:sub(2));
        end
      end
      rRoll.nMod = rRoll.nMod + nAddMod;
      
      local sEffects = "";
      local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
      if sMod ~= "" then
        sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
      else
        sEffects = "[" .. Interface.getString("effects_tag") .. "]";
      end
      rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
    end
  end

    
  -- apply ModifierStack if existed.
  if nConcealMod ~= 0 then
    nCover = nConcealMod;
  end
  -- cover is last because it's better than concealed.
  if nCoverMod ~= 0 then
    nCover = nCoverMod;
  end
  -- if we have cover/concealment apply those
  if nCover ~= 0 then
    rRoll.nMod = rRoll.nMod + nCover;
    --rRoll.sDesc = rRoll.sDesc .. string.format(" [COVER +%d]", nCover);
  end
  -- do they get bonus to save for this from race?
  if nTraitSaveMod > 0 then
    rRoll.nMod = rRoll.nMod + nTraitSaveMod;
  end
  
  ActionsManager2.encodeDesktopMods(rRoll);
    bADV = false;    -- don't use advantage/disadvantage in AD&D --celestian
    bDIS = false;
  ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
  
  if bAutoFail then
    rRoll.sDesc = rRoll.sDesc .. " [AUTOFAIL]";
  end
end

function onSave(rSource, rTarget, rRoll)
--UtilityManagerADND.logDebug("manager_action_save.lua","onSave","rSource",rSource);    
--UtilityManagerADND.logDebug("manager_action_save.lua","onSave","rTarget",rTarget);    
--UtilityManagerADND.logDebug("manager_action_save.lua","onSave","rRoll",rRoll);    
  ActionsManager2.decodeAdvantage(rRoll);

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  Comm.deliverChatMessage(rMessage);

  local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
  if not bAutoFail and rRoll.nTarget then
    notifyApplySave(rSource, rMessage.secret, rRoll);
  end
end

function applySave(rSource, rOrigin, rAction,rJSON)
  local msgShort = {font = "msgfont"};
  local msgLong = {font = "msgfont"};
--UtilityManagerADND.logDebug("manager_action_save.lua","applySave","nMagicResist",nMagicResist);  
--UtilityManagerADND.logDebug("manager_action_save.lua","applySave","rSource",rSource);  
--UtilityManagerADND.logDebug("manager_action_save.lua","applySave","rOrigin",rOrigin);  
--UtilityManagerADND.logDebug("manager_action_save.lua","applySave","rAction",rAction);  
--UtilityManagerADND.logDebug("manager_action_save.lua","applySave","rJSON",rJSON);  
  
  msgShort.text = "Save";
  msgLong.text = "Save [" .. rAction.nTotal ..  "]";
  if rAction.nTarget > 0 then
    msgLong.text = msgLong.text .. " [Target " .. rAction.nTarget .. "]";
  end
  msgShort.text = msgShort.text .. " ->";
  msgLong.text = msgLong.text .. " ->";
  if rSource then
    msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
    msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
  end
  if rOrigin then
    msgShort.text = msgShort.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
    msgLong.text = msgLong.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
  end
  
  msgShort.icon = "roll_cast";
    
  local sAttack = "";
  local bHalfMatch = false;
  if rAction.sSaveDesc then
    sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
    bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
  end
  rAction.sResult = "";
  
  if rAction.nTarget > 0 then
    if rAction.nTotal >= rAction.nTarget then
      local sSuccessText = Interface.getString("success");
      if rOrigin then
        sSuccessText = Interface.getString("target-saved");
      end
      msgLong.text = msgLong.text .. " [" .. sSuccessText .. "]";
      msgLong.icon = "chat_success";msgLong.font = "successfont";
      if rSource then
        local bHalfDamage = bHalfMatch;
        local bAvoidDamage = false;
        if bHalfDamage then
            if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
              bAvoidDamage = true;
              msgLong.text = msgLong.text .. " [AVOIDANCE]";
            elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
                local sSave = rAction.sDesc:match("%[SAVE%] vs%. (%w+)");
                if sSave then
                  sSave = sSave:lower();
                end
                if sSave == "dexterity" then
                  bAvoidDamage = true;
                  msgLong.text = msgLong.text .. " [EVASION]";
                end
            end
        end
          
        if bAvoidDamage then
          rAction.sResult = "none";
          rAction.bRemoveOnMiss = false;
        elseif bHalfDamage then
          rAction.sResult = "half_success";
          rAction.bRemoveOnMiss = false;
        end
        
        if rOrigin and rAction.bRemoveOnMiss then
          TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
        end
      end
    else
      local sFailureText = Interface.getString("failure");
      if rOrigin then
        sFailureText = Interface.getString("target-failed");
      end    
      msgLong.text = msgLong.text .. " [".. sFailureText .. "]";
      msgLong.icon = "chat_fail";  msgLong.font = "failfont";
      if rSource then
        local bHalfDamage = false;
        if bHalfMatch then
          if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
            bHalfDamage = true;
            msgLong.text = msgLong.text .. " [AVOIDANCE]";
          elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
            local sSave = rAction.sDesc:match("%[SAVE%] vs%. (%w+)");
            if sSave then
              sSave = sSave:lower();
            end
            if sSave == "dexterity" then
              bHalfDamage = true;
              msgLong.text = msgLong.text .. " [EVASION]";
            end
          end
        end
        
        if bHalfDamage then
          rAction.sResult = "half_failure";
        end
      end
    end
  end

  --ActionsManager.messageResult(rAction.bSecret, rSource, rOrigin, msgLong, msgShort);
  ActionsManager.outputResult(rAction.bSecret, rSource, rTarget, msgLong, msgShort);
  
  if rSource and rOrigin then
    ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
  end
  
  --local _, nActiveMR, _ = EffectManager5E.getEffectsBonus(rSource, {"MR"}, false, nil);
  local nActiveMR = 0;

    -- Grab the MR values. 
    -- Cast powers have a properties field which is where the types association is derived.
    -- valid types are all DataCommon.dmgtypes and DataCommon.powertypes
    -- MR:X = save applied to all
    -- MR:X,type,type = save applies only to those types. 

  if rJSON and rJSON.sPowerProperties then
    local sProperties = rJSON.sPowerProperties:lower() or "";
    local aProperties = StringManager.split(sProperties, ",", true);
    local aSaveTypeList = EffectManager5E.getEffectsByType(rSource, "MR", {}, {});
    -- UtilityManagerADND.logDebug("manager_action_save.lua","applySave","aProperties",aProperties);       
    -- UtilityManagerADND.logDebug("manager_action_save.lua","applySave","aSaveTypeList",aSaveTypeList);       
    for k, v in pairs(aSaveTypeList) do
      -- if the save effect has a remainder, it has a type, MR: 4,fire,cold,acid
      if #v.remainder > 0 then
        -- if properties doesn't exist we dont need to check
        if #aProperties > 0 then
          for _,sPowerProperty in ipairs(aProperties) do
            -- UtilityManagerADND.logDebug("manager_action_save.lua","applySave","sPowerProperty",sPowerProperty);                
            -- if the property is a damage/power type and it exists in the effect type
            if (StringManager.contains(DataCommon.dmgtypes,sPowerProperty) or StringManager.contains(DataCommon.powertypes,sPowerProperty)) and 
              StringManager.contains(v.remainder,sPowerProperty) then
                -- UtilityManagerADND.logDebug("manager_action_save.lua","applySave","MR FOUND MATCH",' [' .. StringManager.capitalize(sPowerProperty) .. " " .. v.mod .. ']'); 
                --rRoll.sDesc = rRoll.sDesc  .. ' [' .. StringManager.capitalize(sPowerProperty) .. " " .. v.mod .. ']';
                if nActiveMR < v.mod then
                  nActiveMR = v.mod;
                end
                break;
            end
          end
        end
      else
        -- no remainder so we have plain MR:X
        -- UtilityManagerADND.logDebug("manager_action_save.lua","applySave","NO MR MATCH FOR ",' [' .. v.mod .. ']'); 
        if nActiveMR < v.mod then
          nActiveMR = v.mod;
        end
      end
    end
    -- -- this MR had a parameter but did not match a property.
    -- if bMRSpecial and not bMRSpecialExist then
    --   nActiveMR = 0;
    -- end
  else
    --UtilityManagerADND.logDebug("manager_action_save.lua","applySave","no spell properties");
  end
  ---
--  local _, nMagicResist, _ = EffectManager5E.getEffectsBonus(rSource, {"MR"}, false, nil);

  -- send a magic resist to handlers
  if nActiveMR > 0 then
    local aMRDice = { "d100" };
    local rMRRoll = { nActiveMR = nActiveMR, sType = "roll_against_magic_resist", sDesc = "[MAGIC-RESIST " .. nActiveMR .. "]", aDice = aMRDice, nMod = 0 ,bSecret = rAction.bSecret, sUser = User.getUsername()};
    ActionsManager.roll(rOrigin, rSource, rMRRoll, false);  
  end
end

--
--  Concentration saving throw
--
-- function hasConcentrationEffects(rSource)
  -- return #(getConcentrationEffects(rSource)) > 0;
-- end
-- check to see if rSource has any effects "(C)";
function hasConcentrationEffects(rSource)
  local nodeCT = ActorManager.getCTNode(rSource);
  local bHas = false;
  for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
    local sLabel = DB.getValue(nodeEffect, "label", "")
    if sLabel:match("%([cC]%)") then
      bHas = true;
      break;
    end
  end
  
  return bHas;
end

-- this returns a list of ALL effects "(C)"
function getConcentrationEffects(rSource)
  local aEffects = {};
  
  local sCTNodeSource = ActorManager.getCTNodeName(rSource);
  if sCTNodeSource then
    -- local sCTNodeSource = nodeCTSource.getPath();
    for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
      local sCTNode = nodeCT.getPath();
      for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
        local bSourceMatch = false;
        local sEffectCTSource = DB.getValue(nodeEffect, "source_name", "");
        if sEffectCTSource == sCTNodeSource then
          bSourceMatch = true;
        elseif (sCTNode == sCTNodeSource) and (sEffectCTSource == "") then
          bSourceMatch = true;
        end
        if bSourceMatch then
          if DB.getValue(nodeEffect, "label", ""):match("%([cC]%)") then
            table.insert(aEffects, { nodeCT = nodeCT, nodeEffect = nodeEffect });
          end
        end
      end
    end
  end
  
  return aEffects;
end

function handleApplyConc(msgOOB)
  local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
  
  local rAction = {};
  rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
  rAction.sDesc = msgOOB.sDesc;
  rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
  rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
  
  applyConcentrationRoll(rSource, rAction);
end

function notifyApplyConc(rSource, bSecret, rRoll)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYCONC;
  
  if bSecret then
    msgOOB.nSecret = 1;
  else
    msgOOB.nSecret = 0;
  end
  msgOOB.sDesc = rRoll.sDesc;
  msgOOB.nTotal = ActionsManager.total(rRoll);
  msgOOB.nTarget = rRoll.nTarget;

  -- msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
  local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
  msgOOB.sSourceType = sSourceType;
  msgOOB.sSourceNode = sSourceNode;

  Comm.deliverOOBMessage(msgOOB, "");
end

function performConcentrationRoll(draginfo, rActor, nTargetDC)
  local rRoll = { };
  rRoll.sType = "concentration";
  rRoll.aDice = { "d20" };
  local nMod, bADV, bDIS, sAddText = ActorManagerADND.getSave(rActor, "constitution");
  rRoll.nMod = nMod;
  
  rRoll.sDesc = "[CONCENTRATION]";
  if sAddText and sAddText ~= "" then
    rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
  end
  if bADV then
    rRoll.sDesc = rRoll.sDesc .. " [ADV]";
  end
  if bDIS then
    rRoll.sDesc = rRoll.sDesc .. " [DIS]";
  end

  rRoll.nTarget = nTargetDC;
  
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onConcentrationRoll(rSource, rTarget, rRoll)
  ActionsManager2.decodeAdvantage(rRoll);

  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  Comm.deliverChatMessage(rMessage);

  local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
  if not bAutoFail and rRoll.nTarget then
    notifyApplyConc(rSource, rMessage.secret, rRoll);
  end
end

function applyConcentrationRoll(rSource, rAction)
  local msgShort = {font = "msgfont"};
  local msgLong = {font = "msgfont"};
  
  msgShort.text = "Concentration";
  msgLong.text = "Concentration [" .. rAction.nTotal ..  "]";
  if rAction.nTarget > 0 then
    msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
  end
  msgShort.text = msgShort.text .. " ->";
  msgLong.text = msgLong.text .. " ->";
  if rSource then
    msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
    msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
  end
  
  msgShort.icon = "roll_cast";
    
  if rAction.nTotal >= rAction.nTarget then
    msgLong.text = msgLong.text .. " [" .. Interface.getString("success") .. "]";
  else
    msgLong.text = msgLong.text .. " [" .. Interface.getString("failure") .. "]";
  end
  
  ActionsManager.outputResult(rAction.bSecret, rSource, nil, msgLong, msgShort);
  
  -- On failed concentration check, remove all effects with the same source creature
  if rAction.nTotal < rAction.nTarget then
    expireConcentrationEffects(rSource);
  end
end

function expireConcentrationEffects(rSource)
  local aSourceConcentrationEffects = getConcentrationEffects(rSource);
  for _,v in ipairs(aSourceConcentrationEffects) do
    EffectManager.expireEffect(v.nodeCT, v.nodeEffect, 0);
  end
end

function setNPCSave(nodeEntry, sSave, nodeNPC)
--UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[0][1]);    
    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", sSave);

    local nSaveIndex = DataCommonADND.saves_table_index[sSave];

    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "DataCommonADND.saves_table_index[sSave]", DataCommonADND.saves_table_index[sSave]);
    
    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "nSaveIndex", nSaveIndex);
    
    local nSaveScore = 20;
    
    local sHitDice = DB.getValue(nodeNPC, "hitDice", "1");
    DB.setValue(nodeEntry,"hitDice","string", sHitDice);
    
    local nLevel = CombatManagerADND.getNPCLevelFromHitDice(DB.getValue(nodeNPC,"hitDice","1"),nodeNPC);

    -- store it incase we wanna look at it later
    DB.setValue(nodeEntry, "level", "number", nLevel);
    
    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "nLevel", nLevel);
    
    if (nLevel > 17) then
        nSaveScore = DataCommonADND.aWarriorSaves[17][nSaveIndex];
    elseif (nLevel < 1) then
        nSaveScore = DataCommonADND.aWarriorSaves[0][nSaveIndex];
    else
        nSaveScore = DataCommonADND.aWarriorSaves[nLevel][nSaveIndex];
    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]", DataCommonADND.aWarriorSaves[nLevel][nSaveIndex]);
    end

    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "nSaveScore", nSaveScore);
    
    DB.setValue(nodeEntry, "saves." .. sSave .. ".score", "number", nSaveScore);
    DB.setValue(nodeEntry, "saves." .. sSave .. ".base", "number", nSaveScore);

    --UtilityManagerADND.logDebug("manager_action_save.lua", "setNPCSave", "setValue Done");

    return nSaveScore;
end

---
--- check magic resistance and account success or failure on a save when the target has magic resist
---
function checkMagicResist(rSource, rTarget, rRoll)
--UtilityManagerADND.logDebug("manager_action_save.lua", "checkMagicResist", "rSource", rSource);
--UtilityManagerADND.logDebug("manager_action_save.lua", "checkMagicResist", "rRoll", rRoll);
  local nCheckTotal = ActionsManager.total(rRoll);
  --local _, nMagicResist, _ = EffectManager5E.getEffectsBonus(rTarget, {"MR"}, false, nil);
  local nActiveMR = tonumber(rRoll.nActiveMR) or 0;
  local bSecret = (rRoll.bSecret == 'bTRUE');
  
  -- if the percentage rolled greater than magic resistance then spell hits
  local rMessage = ActionsManager.createActionMessage(rTarget, rRoll);
  --local nDifference = nActiveMR - nCheckTotal;
  if (nCheckTotal > nActiveMR) then
    -- failed MR check
    rMessage.secret = bSecret;
    rMessage.icon = "chat_fail";  rMessage.font = "failfont";
    rMessage.text = "[MR " .. nActiveMR .. "][MAGIC-RESIST FAILED] " .. Interface.getString("chat_combat_hit_magicresist_failed");
    Comm.deliverChatMessage(rMessage);
  else
    -- remove target if MR successful
    TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
    rMessage.secret = bSecret;
    rMessage.icon = "chat_success";rMessage.font = "successfont";
    rMessage.text = "[MR " .. nActiveMR .. "][MAGIC-RESIST SUCCESS] " .. Interface.getString("chat_combat_hit_magicresist_success");
    Comm.deliverChatMessage(rMessage);
  end
end

--[[ 
return bonuses for this type of save from racial traits

Looks for trait name and TEXT within trait.

TEXT matching:
* To match on constitution: "points of constitution score"
* To match on poison: "resistance to toxic substances" or "resistance to poisons"
* To match on rod,staff,wand,spells: "wands, staves, rods, and spells"

]]--
TRAIT_SAVE_BONUSES = "save bonuses";
TRAIT_SAVE_BONUS = "save bonus";
function getRacialSaveAdjustments(rSource,sSave)
  local nModifier = 0;
  local sSaveLower = sSave:lower();
  --local nodeActor = ActorManager.getCreatureNode(rSource);
  local _, nodeActor = ActorManager.getTypeAndNode(rSource);

  -- rod/staff/wand/spell gnome/dwarf/halfling generally
  if StringManager.contains({"rod","staff","wand","spell"},sSaveLower) then
    local nodeTrait = nil;
    if CharManager.hasTrait(nodeActor,TRAIT_SAVE_BONUSES) then
      nodeTrait = CharManager.getTraitRecord(nodeActor, TRAIT_SAVE_BONUSES);
    elseif CharManager.hasTrait(nodeActor, TRAIT_SAVE_BONUS) then
      nodeTrait = CharManager.getTraitRecord(nodeActor, TRAIT_SAVE_BONUS);
    end
    if nodeTrait then
      local sText = DB.getValue(nodeTrait,"text",""):lower();
      if sText:find("points of constitution score") then
        if sText:find("wands, staves, rods, and spells") then
          local nCon = DB.getValue(nodeActor,"abilities.constitution.total",0);
          nModifier = getConstitutionMagicModifier(nCon);
        end -- wand/rod/stave/spell
      end -- using constitution
    end -- had trait
    
  -- poison resistance from con
  elseif StringManager.contains({"poison"},sSaveLower) then
    local nodeTrait = nil;
    if CharManager.hasTrait(nodeActor,TRAIT_SAVE_BONUSES) then
      nodeTrait = CharManager.getTraitRecord(nodeActor, TRAIT_SAVE_BONUSES);
    elseif CharManager.hasTrait(nodeActor, TRAIT_SAVE_BONUS) then
      nodeTrait = CharManager.getTraitRecord(nodeActor, TRAIT_SAVE_BONUS);
    end
    if nodeTrait then
      local sText = DB.getValue(nodeTrait,"text",""):lower();
      if sText:find("points of constitution score") then
        if sText:find("resistance to toxic substances") or sText:find("resistance to poisons") then
          local nCon = DB.getValue(nodeActor,"abilities.constitution.total",0);
          nModifier = getConstitutionPoisonModifier(nCon);
        end -- poison/toxic
      end -- using constitution
    end -- had trait
  end
  
  return nModifier;
end
-- get the magic save adjustment for nCon value
function getConstitutionMagicModifier(nCon)
  local nModifier = 0;
  if nCon >= 18 then
    nModifier = 5;
  elseif nCon >=14 then
    nModifier = 4;
  elseif nCon >= 11 then
    nModifier = 3;
  elseif nCon >= 7 then
    nModifier = 2;
  elseif nCon >= 4 then
    nModifier = 1;
  end -- con
  
  return nModifier;
end
-- get the poison save adjustment for nCon value (same for now)
function getConstitutionPoisonModifier(nCon)
  return getConstitutionMagicModifier(nCon);
end

