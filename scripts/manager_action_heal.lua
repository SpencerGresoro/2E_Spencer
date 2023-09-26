-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  ActionsManager.registerModHandler("heal", modHeal);
  ActionsManager.registerPostRollHandler("heal", onHealPostRoll);
  ActionsManager.registerResultHandler("heal", onHeal);
end

function getRoll(rActor, rAction)
  local rRoll = {};
  rRoll.sType = "heal";
  rRoll.aDice = {};
  rRoll.nMod = 0;
  
  -- Build description
  rRoll.sDesc = "[HEAL";
  if rAction.order and rAction.order > 1 then
    rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
  end
  rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;

	-- Save the heal clauses in the roll structure
	rRoll.clauses = rAction.clauses;

	-- Add heal type to roll data
	if rAction.subtype == "temp" then
		rRoll.healtype = "temp";
	else
		rRoll.healtype = "health";
	end

	-- Add the dice and modifiers, and encode ability scores used
	for _,vClause in pairs(rRoll.clauses) do
		DiceRollManager.addHealDice(rRoll.aDice, vClause.dice, { healtype = rRoll.healtype });
		rRoll.nMod = rRoll.nMod + vClause.modifier;

		local sAbility = DataCommon.ability_ltos[vClause.stat];
		if sAbility then
			rRoll.sDesc = rRoll.sDesc .. string.format(" [MOD: %s (%s)]", sAbility, vClause.statmult or 1);
		end
	end
  
	-- Encode the damage types
	ActionHeal.encodeHealClauses(rRoll);

  -- Handle temporary hit points
  if rAction.subtype == "temp" then
    rRoll.sDesc = rRoll.sDesc .. " [TEMP]";
  end

  -- Handle self-targeting
  if rAction.sTargeting == "self" then
    rRoll.bSelfTarget = true;
  end

  return rRoll;
end

function performRoll(draginfo, rActor, rAction)
  local rRoll = getRoll(rActor, rAction);
  
  ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modHeal(rSource, rTarget, rRoll)
  ActionHeal.decodeHealClauses(rRoll);
  CombatManagerADND.addRightClickDiceToClauses(rRoll);
  
  local aAddDesc = {};
  local aAddDice = {};
  local nAddMod = 0;
  
  -- Track how many heal clauses before effects applied
  local nPreEffectClauses = #(rRoll.clauses);
  
  if rSource then
    local bEffects = false;

    -- Apply general heal modifiers
    local nEffectCount;
    aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"HEAL"});
    if (nEffectCount > 0) then
      bEffects = true;
    end
    
    -- Apply multiplier heal modifiers from HEALX effect
    local aAddDice_Multiplier, nAddMod_Multiplier, nEffectCount_Multiplier = EffectManager5E.getEffectsBonus(rSource, {"HEALX"}, false, aAttackFilter, rTarget);
    if nEffectCount_Multiplier > 0 then
      local nSubTotal = StringManager.evalDice(aAddDice_Multiplier, nAddMod_Multiplier);
      rRoll.nDamageMultiplier = nSubTotal;
      -- add [x2] to the heal string for visual
      rRoll.sDesc = rRoll.sDesc .. " [x" .. nSubTotal .. "]"; 
    end

    -- If effects happened, then add note
    if bEffects then
      local sEffects = "";
      local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
      if sMod ~= "" then
        sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
      else
        sEffects = "[" .. Interface.getString("effects_tag") .. "]";
      end
      table.insert(aAddDesc, sEffects);
    end
  end
 
  
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	ActionsManager2.encodeDesktopMods(rRoll);
	DiceRollManager.addHealDice(rRoll.aDice, aAddDice, { iconcolor = "FF00FF", healtype = rRoll.healtype });
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Handle fixed damage option
	if not ActorManager.isPC(rSource) and OptionsManager.isOption("NPCD", "fixed") then
		local aFixedClauses = {};
		local aFixedDice = {};
		local nFixedPositiveCount = 0;
		local nFixedNegativeCount = 0;
		local nFixedMod = 0;

		for kClause,vClause in ipairs(rRoll.clauses) do
			if kClause <= nPreEffectClauses then
				local nClauseFixedMod = 0;
				for kDie,vDie in ipairs(vClause.dice) do
					if vDie:sub(1,1) == "-" then
						nFixedNegativeCount = nFixedNegativeCount + 1;
						nClauseFixedMod = nClauseFixedMod - math.floor(math.ceil(tonumber(vDie:sub(3)) or 0) / 2);
						if nFixedNegativeCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod - 1;
						end
					else
						nFixedPositiveCount = nFixedPositiveCount + 1;
						nClauseFixedMod = nClauseFixedMod + math.floor(math.ceil(tonumber(vDie:sub(2)) or 0) / 2);
						if nFixedPositiveCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod + 1;
						end
					end
					vClause.dice = {};
					vClause.modifier = vClause.modifier + nClauseFixedMod;
				end
				nFixedMod = nFixedMod + nClauseFixedMod;
			else
				DiceRollManager.addHealDice(aFixedDice, vClause.dice);
			end

			table.insert(aFixedClauses, vClause);
		end

		rRoll.clauses = aFixedClauses;
		rRoll.aDice = aFixedDice;
		rRoll.nMod = rRoll.nMod + nFixedMod;
	end

  -- if using multiplier adjust modifier
  -- for HEALX
  if rRoll.nDamageMultiplier then
    local nMultiplier =  rRoll.nDamageMultiplier;
    if nMultiplier < 0 then nMultiplier = 1; end;
    rRoll.nMod = math.floor(rRoll.nMod * nMultiplier);
  end
end

function onHeal(rSource, rTarget, rRoll)
  local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
  rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");
  Comm.deliverChatMessage(rMessage);
  
  local nTotal = ActionsManager.total(rRoll);
  ActionDamage.notifyApplyDamage(rSource, rTarget, rMessage.secret, rMessage.text, nTotal, rRoll.aDice);
end

--
-- UTILITY FUNCTIONS
--

function encodeHealClauses(rRoll)
  for _,vClause in ipairs(rRoll.clauses) do
    local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
    rRoll.sDesc = rRoll.sDesc .. string.format(" [CLAUSE: (%s) (%s) (%s)]", sDice, vClause.stat or "", vClause.statmult or 1);
  end
end

function decodeHealClauses(rRoll)
  -- Process each type clause in the damage description
  rRoll.clauses = {};
  for sDice, sStat, sStatMult in string.gmatch(rRoll.sDesc, "%[CLAUSE: %(([^)]*)%) %(([^)]*)%) %(([^)]*)%)]") do
    local rClause = {};
    rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDice);
    rClause.stat = sStat;
    rClause.statmult = tonumber(sStatMult) or 1;
    
    table.insert(rRoll.clauses, rClause);
  end
  
  -- Remove heal clause information from roll description
  rRoll.sDesc = string.gsub(rRoll.sDesc, " %[CLAUSE:[^]]*%]", "");
end

-- adjust dice after roll.
function onHealPostRoll(rSource, rRoll)
  -- check for heal multiplier and apply from effect DMGX
  if rRoll.nDamageMultiplier then
    local nMultiplier = tonumber(rRoll.nDamageMultiplier) or 1;
    if nMultiplier < 0 then nMultiplier = 1; end;
    for _,vDie in ipairs(rRoll.aDice) do
      local sSign, sColor, sDieSides = vDie.type:match("^([%-%+]?)([dDrRgGbBpP])([%dF]+)");
      if sDieSides then
        vDie.result = math.floor(vDie.result * nMultiplier);
        if sColor == "d" or sColor == "D" then
          if sSign == "-" then
            vDie.type = "-b" .. sDieSides;
          else
            vDie.type = "b" .. sDieSides;
          end
        end
      end
    end
    if rRoll.aDice.expr then
      rRoll.aDice.expr = nil;
    end
  end
 -- end heal multiplier
end
