-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  registerMenuItem(Interface.getString("power_menu_actiondelete"), "deletepointer", 4);
  registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 4, 3);
  
  updateDisplay();
  
  local node = getDatabaseNode();
--UtilityManagerADND.logDebug("power_action.lua","onInit","node",node);  
  windowlist.setOrder(node);

  local nodeSpell = DB.getChild(node, "...");
--UtilityManagerADND.logDebug("power_action.lua","onInit","nodeSpell",nodeSpell);
  local sNode = getDatabaseNode().getNodeName();
  DB.addHandler(sNode, "onChildUpdate", onDataChanged);
  -- update when spell type changed (a number value indicates casterlevel)
  DB.addHandler(DB.getPath(nodeSpell, "type"), "onUpdate", onDataChanged);
  -- update on level changes
  local nodeChar = node.getChild(".....");
  DB.addHandler(DB.getPath(nodeChar, "arcane.totalLevel"), "onUpdate", onDataChanged);
  DB.addHandler(DB.getPath(nodeChar, "divine.totalLevel"), "onUpdate", onDataChanged);
  DB.addHandler(DB.getPath(nodeChar, "psionic.totalLevel"), "onUpdate", onDataChanged);
  
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.dmgadj"), "onUpdate", onDataChanged);
  DB.addHandler(DB.getPath(nodeChar, "abilities.*.hitadj"), "onUpdate", onDataChanged);
  local nodeCT = CombatManager.getCTFromNode(nodeChar);
  if (nodeCT) then
    --DB.addHandler(DB.getPath(nodeCT, "effects"), "onChildUpdate", onDataChanged);
    DB.addHandler(DB.getPath(nodeCT, "effects.*.label"), "onUpdate", onDataChanged);
    DB.addHandler(DB.getPath(nodeCT, "effects.*.isactive"), "onUpdate", onDataChanged);
    --//TODO is this needed?
    --DB.addHandler("combattracker.list", "onChildDeleted", onDataChanged);
  end
  onDataChanged();
end

function onClose()
  local sNode = getDatabaseNode().getNodeName();
  DB.removeHandler(sNode, "onChildUpdate", onDataChanged);

  local node = getDatabaseNode();
  local nodeSpell = DB.getChild(node, "...");
  DB.addHandler(DB.getPath(nodeSpell, "type"), "onUpdate", onDataChanged);
  local nodeChar = node.getChild(".....");
  DB.removeHandler(DB.getPath(nodeChar, "arcane.totalLevel"), "onUpdate", onDataChanged);
  DB.removeHandler(DB.getPath(nodeChar, "divine.totalLevel"), "onUpdate", onDataChanged);
  DB.removeHandler(DB.getPath(nodeChar, "psionic.totalLevel"), "onUpdate", onDataChanged);

  DB.removeHandler(DB.getPath(nodeChar, "abilities.*.dmgadj"), "onUpdate", onDataChanged);
  DB.removeHandler(DB.getPath(nodeChar, "abilities.*.hitadj"), "onUpdate", onDataChanged);
  local nodeCT = CombatManager.getCTFromNode(nodeChar);
  if (nodeCT) then
    --DB.removeHandler(DB.getPath(nodeCT, "effects"), "onChildUpdate", onDataChanged);
    DB.removeHandler(DB.getPath(nodeCT, "effects.*.label"), "onUpdate", onDataChanged);
    DB.removeHandler(DB.getPath(nodeCT, "effects.*.isactive"), "onUpdate", onDataChanged);
    --//TODO is this needed?
    --DB.removeHandler("combattracker.list", "onChildDeleted", onDataChanged);

  end
end


function onMenuSelection(selection, subselection)
  if selection == 4 and subselection == 3 then
    getDatabaseNode().delete();
  end
end

function highlight(bState)
  if bState then
    setFrame("rowshade");
  else
    setFrame(nil);
  end
end

function updateDisplay()
  local node = getDatabaseNode();
  local sNodePath = node.getPath();
  local nodeSpell = node.getChild("...");
  local nodeChar = node.getChild(".....");
  --local bisNPC = (not ActorManager.isPC(nodeChar));
  local sType = DB.getValue(node, "type", "");
  
  local bShowCast = (sType == "cast");
  local bShowDamage = (sType == "damage");
  local bShowHeal = (sType == "heal");
  local bShowEffect = (sType == "effect");
  local bShowDamagePSP = (sType == "damage_psp");
  local bShowHealPSP = (sType == "heal_psp");

  local sSpellType = DB.getValue(nodeSpell, "type", ""):lower();
  local sSource = DB.getValue(nodeSpell, "source", ""):lower();

  --local sMode = DB.getValue(nodeChar, "powermode", "");
  --local bShowMemorize = ( PowerManager.canMemorizeSpell(nodeSpell) );
  --local bMemorized = ((DB.getValue(nodeSpell,"memorized",0) > 0));
  --local bWasMemorized = (DB.getValue(nodeSpell,"wasmemorized",0) == 1);
  --local bShowSpellHide = false;
  
  -- show the button to hide this spell since it was cast
  -- if (sMode == "combat") and (sType == "cast") and bWasMemorized and not bMemorized then
    -- bShowSpellHide = true;
    -- bShowMemorize = false;
  -- end
  
  --local bShowInitiative = false;
-- UtilityManagerADND.logDebug("power_action.lua","updateDisplay","castinitiative.getValue(",castinitiative.getValue());    
    -- if (sMode == "combat") and (sType == "cast") and (castinitiative.getValue() > 0) then
        -- bShowInitiative = true;
    -- elseif (sMode ~= "combat") and (sType == "cast") then
        -- bShowInitiative = true;
    -- else
        -- bShowInitiative = false;
    -- end
  
  --castinitiative.setVisible(true);
  -- initiativelabel.setVisible(true);

  castbutton.setVisible(bShowCast);
  castlabel.setVisible(bShowCast);
  

    -- if in spell record then we don't need to
    -- display memorize buttons
    -- if string.match(sNodePath,"^spell") then
        -- memorizebutton.setVisible(false);
        -- memorizelabel.setVisible(false);
        -- memorizedcount.setVisible(false);
    -- else
        -- memorizebutton.setVisible(bShowMemorize);
        -- memorizelabel.setVisible(bShowMemorize);
        -- memorizedcount.setVisible(bShowMemorize);
    -- end
    
--UtilityManagerADND.logDebug("power_action.lua","updateDisplay","bShowSpellHide",bShowSpellHide);    
  initiative.setVisible(bShowCast);
  initiative_label.setVisible(bShowCast);
  
  -- hidespellbutton.setVisible(bShowSpellHide);
  -- hidespelllabel.setVisible(bShowSpellHide);
    
  attackbutton.setVisible(bShowCast);
  attackviewlabel.setVisible(bShowCast);
  attackview.setVisible(bShowCast);
    
    -- hide if no attack set.
    if (bShowCast and attackview.getValue() == "") then
      attackbutton.setVisible(false);
      attackviewlabel.setVisible(false);
      attackview.setVisible(false);
    end
    
  savebutton.setVisible(bShowCast);
  saveviewlabel.setVisible(bShowCast);
  saveview.setVisible(bShowCast);
    -- hide if no save set.
    if (bShowCast and saveview.getValue() == "") then
      savebutton.setVisible(false);
      saveviewlabel.setVisible(false);
      saveview.setVisible(false);
    end
    
  castdetail.setVisible(bShowCast);
  
  damagebutton.setVisible(bShowDamage);
  damagelabel.setVisible(bShowDamage);
  damageview.setVisible(bShowDamage);
  damagedetail.setVisible(bShowDamage);

  healbutton.setVisible(bShowHeal);
  heallabel.setVisible(bShowHeal);
  healview.setVisible(bShowHeal);
  healdetail.setVisible(bShowHeal);

-- psionic nonsense
  damagepspbutton.setVisible(bShowDamagePSP);
  damagepsplabel.setVisible(bShowDamagePSP);
  damagepspview.setVisible(bShowDamagePSP);
  damagepspdetail.setVisible(bShowDamagePSP);

  healpspbutton.setVisible(bShowHealPSP);
  healpsplabel.setVisible(bShowHealPSP);
  healpspview.setVisible(bShowHealPSP);
  healpspdetail.setVisible(bShowHealPSP);

-- end psionic nonsense

  effectbutton.setVisible(bShowEffect);
  effectlabel.setVisible(bShowEffect);
  effectview.setVisible(bShowEffect);
  durationview.setVisible(bShowEffect);
  effectdetail.setVisible(bShowEffect);
end

-- when "hidespell pressed" and the spell was memorized (not any longer) 
-- we remove the wasmemorized flag and force display update to clear it from list.
-- function hideSpellPressed()
  -- local node = getDatabaseNode();
  -- local nodeSpell = node.getChild("...");

  -- DB.setValue(nodeSpell,"wasmemorized","number",0);
  -- updateDisplay();
-- end

function updateViews()
  onDataChanged();
end

function onDataChanged()
  local sType = DB.getValue(getDatabaseNode(), "type", "");
  
  if sType == "cast" then
    onCastChanged();
  elseif sType == "damage" then
    onDamageChanged();
  elseif sType == "heal" then
    onHealChanged();
  elseif sType == "effect" then
    onEffectChanged();
  elseif sType == "damage_psp" then
    onDamagePSPChanged();
  elseif sType == "heal_psp" then
    onHealPSPChanged();
  end
end

function onCastChanged()
  local nodeAction = getDatabaseNode();
  local nodeActor = nodeAction.getChild(".....")
  local rActor = ActorManager.resolveActor( nodeActor);
  
  local sAttack = "";
  local sAttackType = DB.getValue(nodeAction, "atktype", "");
  if sAttackType == "melee" then
    sAttack = Interface.getString("melee");
  elseif sAttackType == "ranged" then
    sAttack = Interface.getString("ranged");
  elseif sAttackType == "psionic" then
    sAttack = Interface.getString("psionic");
  end
  
  if sAttack ~= "" then
    local nGroupMod, sGroupStat = PowerManager.getGroupAttackBonus(rActor, nodeAction, "");
    
    local nAttackMod = 0;
    local sAttackBase = DB.getValue(nodeAction, "atkbase", "");
    if sAttackBase == "fixed" then
      nAttackMod = DB.getValue(nodeAction, "atkmod", 0);
    elseif sAttackBase == "ability" then
      local sAbility = DB.getValue(nodeAction, "atkstat", "");
      if sAbility == "base" then
        sAbility = sGroupStat;
      end
      -- local nAttackProf = DB.getValue(nodeAction, "atkprof", 1);
      
      nAttackMod = ActorManagerADND.getAbilityBonus(rActor, sAbility,"hitadj") + DB.getValue(nodeAction, "atkmod", 0);
      -- if nAttackProf == 1 then
        -- nAttackMod = nAttackMod + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
      -- end
    else
      nAttackMod = nGroupMod + DB.getValue(nodeAction, "atkmod", 0);
    end

    if nAttackMod ~= 0 then
      sAttack = string.format("%s %+d", sAttack, nAttackMod);
    end
  end
  
  local sSave = "";
  local sSaveType = DB.getValue(nodeAction, "savetype", "");
  if sSaveType ~= "" then
    local nGroupDC, sGroupStat = PowerManager.getGroupSaveDC(rActor, nodeAction, sSaveType);
    if sSaveType == "base" then
      sSaveType = sGroupStat;
    end
    
    local nDC = 0;
    local sSaveBase = DB.getValue(nodeAction, "savedcbase", "");
    if sSaveBase == "fixed" then
      nDC = DB.getValue(nodeAction, "savedcmod", 0);
    elseif sSaveBase == "ability" then
      local sAbility = DB.getValue(nodeAction, "savedcstat", "");
      if sAbility == "base" then
        sAbility = sGroupStat;
      end
      local nSaveProf = DB.getValue(nodeAction, "savedcprof", 1);
      
      nDC = DB.getValue(nodeAction, "savedcmod", 0);
      --nDC = 8 + ActorManagerADND.getAbilityBonus(rActor, sAbility) + DB.getValue(nodeAction, "savedcmod", 0);
      --if nSaveProf == 1 then
      --  nDC = nDC + DB.getValue(ActorManager.getCreatureNode(rActor), "profbonus", 0);
      --end
    else
      nDC = nGroupDC + DB.getValue(nodeAction, "savedcmod", 0);
    end

--    sSave = StringManager.capitalize(sSaveType:sub(1,3)) .. " DC " .. nDC;
        if nDC ~= 0 then
            sSave = StringManager.capitalize(sSaveType) .. " " .. UtilityManagerADND.getNumberSign(nDC);
        else
            sSave = StringManager.capitalize(sSaveType);
        end
    
    if DB.getValue(nodeAction, "onmissdamage", "") == "half" then
      sSave = sSave .. " (H)";
    end
  end

  attackview.setValue(sAttack);
  saveview.setValue(sSave);
end

function onDamageChanged()
  local sDamage = PowerManager.getActionDamageText(getDatabaseNode());
  damageview.setValue(sDamage);
end

function onHealChanged()
  local sHeal = PowerManager.getActionHealText(getDatabaseNode());
  healview.setValue(sHeal);
end

function onHealPSPChanged()
  local sHeal = PowerManager.getActionHealPSPText(getDatabaseNode());
  healpspview.setValue(sHeal);
end

function onDamagePSPChanged()
  local sDamage = PowerManager.getActionDamagePSPText(getDatabaseNode());
  damagepspview.setValue(sDamage);
end

function onEffectChanged()
  local nodeAction = getDatabaseNode();
  
  local sLabel = DB.getValue(nodeAction, "label", "");
  
  local sApply = DB.getValue(nodeAction, "apply", "");
  if sApply == "action" then
    sLabel = sLabel .. "; [ACTION]";
  elseif sApply == "roll" then
    sLabel = sLabel .. "; [ROLL]";
  elseif sApply == "single" then
    sLabel = sLabel .. "; [SINGLES]";
  end
  
  local sTargeting = DB.getValue(nodeAction, "targeting", "");
  if sTargeting == "self" then
    sLabel = sLabel .. "; [SELF]";
  end

    -- display dice/mods for duration --celestian
  local sDuration = "";
  local dDurationDice = DB.getValue(nodeAction, "durdice");
  local nDurationMod = DB.getValue(nodeAction, "durmod", 0);
  local sDurDice = StringManager.convertDiceToString(dDurationDice);
  if (sDurDice ~= "") then 
      sDuration = sDurDice;
  end

  local nDurationValue = PowerManager.getLevelBasedDurationValue(nodeAction);
  if nDurationValue > 0 then
    sDuration = nDurationValue .. "+" .. sDuration
  end

  if (nDurationMod ~= 0 and sDurDice ~= "") then
    local sSign = "+";
    if (nDurationMod < 0) then
      sSign = "";
    end
    sDuration = sDuration .. sSign .. nDurationMod;
  elseif (nDurationMod ~= 0) then
    sDuration = sDuration .. nDurationMod;
  end
  
  local sUnits = DB.getValue(nodeAction, "durunit", "");
  if sDuration ~= "" then
    --local nDuration = tonumber(sDuration);
    local bMultiple = (sDurDice ~= "") or (nDurationMod > 1);
    if sUnits == "minute" then
      sDuration = sDuration .. " turn";
    elseif sUnits == "hour" then
      sDuration = sDuration .. " hour";
    elseif sUnits == "day" then
      sDuration = sDuration .. " day";
    else
      sDuration = sDuration .. " rnd";
    end
    if (bMultiple) then
        sDuration = sDuration .. "s";
    end
  end

  effectview.setValue(sLabel);
  durationview.setValue(sDuration);
end

