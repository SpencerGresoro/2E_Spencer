--
--
--
--

---
-- Power management script
---

--[[

]]
function buildInitiativeItem(rActor,nodePower)
    local sGroup = DB.getValue(nodePower, "group", ""):lower();
    local bIsConcentrationSpell = (string.match(sGroup,"^spell"))

    local sName = DB.getValue(nodePower,"name","");

    local rItem = {};
    rItem.sName = sName;
    rItem.nInit = DB.getValue(nodePower,"castinitiative",1);

    if (bIsConcentrationSpell) then
      rItem.spellPath = nodePower.getPath();
    else
      rItem.spellPath = nil;
    end
    rActor.itemPath = nodePower.getPath();
    return rItem;
end
--[[
    Roll initiative for a spell
]]
function onCastInitiative(draginfo,rActor,nodePower)
    local rItem = buildInitiativeItem(rActor,nodePower)
    ActionInit.performRoll(draginfo, rActor, nil, rItem);
end

--[[
  
  Used from Action/power hypertext

]]
function onCastAction(draginfo,rActor,nodeAction,sSubRoll)
--UtilityManagerADND.logDebug("manager_action_save.lua","performAction","nodeAction",nodeAction);
--UtilityManagerADND.logDebug("manager_power.manager_action_save","performAction","sSubRoll",sSubRoll);
--UtilityManagerADND.logDebug("manager_power.lua","performAction","rActor",rActor);

    -- capture this and increment spells used -celestian
    local sType = DB.getValue(nodeAction, "type", "");
    local rAction = PowerManager.getPowerRoll(rActor, nodeAction, sSubRoll);

    -- check that sSubRoll is nil so we dont remove memorization for a save.
    if sType == "cast" and not sSubRoll then 
        -- UtilityManagerADND.logDebug("manager_power.lua performAction sType",sType);        
        if not PowerManager.castMemorizedSpell(nodeAction) then 
          -- spell wasn't memorized so stop here
          return; 
        end
  
        -- mark one use of this used
        if not PowerManager.incrementUse(nodeAction) then
          -- no uses left, stop
          return;
        end
  
      end
  
    -- -- expend PSPs if not psionic attack
    if (rAction.type ~= "cast" and rAction.Psionic_Source) then
        local nPSPCost = tonumber(rAction.Psionic_PSP);
        local sPSPCost = ""..nPSPCost;
        if not ActionAttack.updatePsionicPoints(rActor,nPSPCost) then
        sPSPCost = "INSUFFCIENT-PSP REMAINING!";
        end
        local rMessage = {};
        rMessage.text = rActor.sName .. ": expend psp->" .. sPSPCost;
        rMessage.secret = true;
        rMessage.font = "missfont";
        rMessage.icon = "power_casterspontaneous";
        Comm.deliverChatMessage(rMessage);
    end

    local sRollType = nil;
    local rRolls = {};
    
    if rAction.type == "cast" then
        if not rAction.subtype then
            table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
        end
        
        if not rAction.subtype or rAction.subtype == "atk" then
            if rAction.range then
                table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
            end
        end

        if not rAction.subtype or rAction.subtype == "save" then
        if rAction.save and rAction.save ~= "" then
            local rRoll = ActionPower.getSaveVsRoll(rActor, rAction);
            if not rAction.subtype then
            rRoll.sType = "powersave";
            end
            table.insert(rRolls, rRoll);
        end
        end
    elseif rAction.type == "damage" then
        table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
        
    elseif rAction.type == "heal" then
        table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));

    elseif rAction.type == "effect" then
        local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
        if rRoll then
            table.insert(rRolls, rRoll);
        end
    elseif rAction.type == "damage_psp" then
        table.insert(rRolls, ActionDamagePSP.getRoll(rActor, rAction));
        
    elseif rAction.type == "heal_psp" then
        table.insert(rRolls, ActionHealPSP.getRoll(rActor, rAction));

    end
    
    if #rRolls > 0 then
        ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
    end
end

--[[

    Add a power on drop from ct to a nodeCT

]]
function onDropAddPower(draginfo,nodeCT)
--UtilityManagerADND.logDebug("manager_powers_adnd.lua","onDrop","draginfo",draginfo);  
--UtilityManagerADND.logDebug("manager_powers_adnd.lua","onDrop","nodeCT",nodeCT);  
    if draginfo.isType("shortcut") then
        local sClass, sRecord = draginfo.getShortcutData();
        if sClass == "reference_spell" or sClass == "power" then
            bUpdatingGroups = true;
            draginfo.setSlot(2);
            local sGroup = draginfo.getStringData();
            draginfo.setSlot(1);
            if sGroup == "" then
                -- try and load spell/power and if psionic type, set group to that
                local nodeSpell = DB.findNode(sRecord);
                if (nodeSpell) then
                    local sType = DB.getValue(nodeSpell,"type",""):lower();
                    if (sType:match("psionic")) then
                        sGroup = "Psionics";
                    end
                end
            end
            if sGroup == "" then
                sGroup = Interface.getString("power_label_groupspells");
            end
            PowerManager.addPower(sClass, draginfo.getDatabaseNode(), nodeCT, sGroup);
            bUpdatingGroups = false;
            return true;
        end

        if sClass == "reference_classfeature" then
            bUpdatingGroups = true;
            PowerManager.addPower(sClass, draginfo.getDatabaseNode(), nodeCT);
            bUpdatingGroups = false;
            return true;
        end
        if sClass == "reference_racialtrait" then
            bUpdatingGroups = true;
            PowerManager.addPower(sClass, draginfo.getDatabaseNode(), nodeCT);
            bUpdatingGroups = false;
            return true;
        end
        if sClass == "reference_feat" then
            bUpdatingGroups = true;
            PowerManager.addPower(sClass, draginfo.getDatabaseNode(), nodeCT);
            bUpdatingGroups = false;
            return true;
        end
        if sClass == "ref_ability" then
            bUpdatingGroups = true;
            PowerManager.addPower(sClass, draginfo.getDatabaseNode(), nodeCT);
            bUpdatingGroups = false;
            return true;
        end

    end
    
end

--[[
    When drag/dropping and effect in DM CT
]]
function onEffectAction(draginfo, rActor, nodeAction) 
    local rAction = PowerManager.getPowerRoll(rActor, nodeAction);
    ActionEffect.performRoll(draginfo,rActor, rAction);    
end

--[[
    When drag/dropping a heal action in DM CT
]]
function onHealAction(draginfo, rActor, nodeAction) 
    
    local rAction = PowerManager.getPowerRoll(rActor, nodeAction);
    ActionHeal.performRoll(draginfo, rActor, rAction);
end