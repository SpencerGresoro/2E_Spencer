---
--
--
--
---

function onInit()
	-- this lets us type "/saclean all" and remove any hidden entries we can't find.
	if Session.IsHost then
		Comm.registerSlashHandler("ctclean", processTokenCleaning);
		Comm.registerSlashHandler("ctshow", processShowAll);
	end
end

--[[
	Set all entries in the combattracker.list as ACTIVe
	-useful for orphaned entries-
]]
function processShowAll(sCommand, sParams)
	if sParams == "all" then
		local aCTUnfilteredEntries = DB.getChildren("combattracker.list");
		for _,node in pairs(aCTUnfilteredEntries) do
			DB.setValue(node,"ct.visible","number",1);
		end
		ChatManager.SystemMessage("Flagging ALL combattracker entries as ACTIVE.");
	else
		ChatManager.SystemMessage("options: sashow [all]\Show ALL CT entries, hidden or otherwise.");
	end
end


--[[
	Remove ALL children in the combattracker, hidden or otherwise
]]	
function processTokenCleaning(sCommand, sParams)
	if sParams == "all" then
		DB.deleteChildren('combattracker.list');
		CombatManagerADND.buildCombatantNodesCache();
		ChatManager.SystemMessage("Deleted ALL combattracker entries.");
	else
		ChatManager.SystemMessage("options: saclean [all]\nRemoves ALL CT entries, hidden or otherwise entirely.");
	end
end

--[[
  activate/deActivateSelectedTokensInCT selected tokens in current imageControl 
]]
function activateSelectedTokensInCT(imageControl)
	manageActivationForSelectedTokens(imageControl,1);
end
function deActivateSelectedTokensInCT(imageControl)
	manageActivationForSelectedTokens(imageControl,0);
end
function manageActivationForSelectedTokens(imageControl,nActiveState)
	if imageControl then
		local aSelected = imageControl.getSelectedTokens();
		for _,nodeToken in pairs(aSelected) do
			local nodeCT = CombatManager.getCTFromTokenUnfiltered(nodeToken);
			if nodeCT then
				if (ActorManager.isPC(nodeCT) and nActiveState == 0) then 
					-- had to stop dms from hiding pcs, to many people
					-- dont know what they did.
				else 
					DB.setValue(nodeCT,"ct.visible","number",nActiveState);
				end
				if nActiveState ~= 1 then
					DB.setValue(nodeCT,"tokenvis","number",0);
				else
					-- enabling token in CT, update effects widgets
					if TokenManager.bDisplayDefaultEffects then
						TokenManager.updateAttributesHelper(nodeToken, nodeCT);
					end
				end
			end
		end
		-- rebuild the CT cache
		CombatManagerADND.buildCombatantNodesCache();
		-- this should force a refresh of the list CT entries.
		local ctwnd = Interface.findWindow("combattracker_host", "combattracker");
		if ctwnd then
			ctwnd.combatants.subwindow.list.applyFilter(true);
			ctwnd.combatants.subwindow.list.applySort(true);
		end
	end
end