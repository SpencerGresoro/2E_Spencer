-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


--[[
	This was originally from 5E, last comparison was v2021-11-15, still the same minus our changes
]]
function onInit()
  TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hp", "hptotal", "hpbase", "hptemp", "wounds"});
	
	TokenManager.addEffectTagIconConditional("IF", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManager5E.parseEffectComp);
end

function getHealthInfo(nodeCT)
	local rActor = ActorManager.resolveActor(nodeCT);
	return ActorHealthManager.getTokenHealthInfo(rActor);
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManager5E.checkConditional(rActor, nodeEffect, vComp.remainder);
end