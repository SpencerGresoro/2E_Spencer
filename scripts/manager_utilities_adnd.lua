---
--- Various utility functions
---
---

function onInit()
  if Session.IsHost  then
    Comm.registerSlashHandler("readycheck", processReadyCheck);
    
    -- replace TableManager.onTableRoll with ours
    ActionsManager.registerResultHandler("table", onTableRoll_adnd);
  end
end

function onClose()
end

-- put timestamp in log output
function logDebug(...)
  -- we need Debug.console so we can see the variables...
  Debug.console("[" .. os.date("%x %X") .. "] ", ...);
  -- chatManager doesn't display the variables so not a real debug solution
  -- ChatManager.SystemMessage("[" .. os.date("%x %X") .. "] " .. ...);
end

-- round the number off
function round(num)
  return math.floor(num + 0.5);
end

-- replace oldWindow with a new window of sClass type
function replaceWindow(oldWindow, sClass, sNodePath)
--UtilityManagerADND.logDebug("manager_utilities_adnd.lua","replaceWindow","oldWindow",oldWindow);
  local x,y = oldWindow.getPosition();
  local w,h = oldWindow.getSize();
  -- Close here otherwise you just close the one you just made since paths are the same at times (drag/drop inline replace item/npc)
  oldWindow.close(); 
  --
  local wNew = Interface.openWindow(sClass, sNodePath);
  wNew.setPosition(x,y);
  wNew.setSize(w,h);
end 

-- check all modules loaded and local records
-- for skill with name of sSkillName 
function findSkillRecord(sSkillName)
  local nodeFound = nil;

  local vMappings = LibraryData.getMappings("skill");
  for _,sMap in ipairs(vMappings) do
    for _,nodeSkill in pairs(DB.getChildrenGlobal(sMap)) do
      local sName = DB.getValue(nodeSkill,"name");
      sName = sName:gsub("%[%d+%]",""); -- remove bracket cost 'Endurance[2]' and just get name clean.
      sName = StringManager.trim(sName);
      if (sName:lower() == sSkillName:lower()) then
        nodeFound = nodeSkill;
        break;
      end
    end
    if nodeFound then
      break
    end
  end
  return nodeFound;
end

-- check nodeChar to see if they have skill of sSKillname
-- this matches when the sSkillname appears ANYWHERE in the skill name
function hasSkill(nodeChar,sSkillName)
  local bHas = false;
  local sSkillNameLower = sSkillName:lower();
  for _,nodeChild in pairs(DB.getChildren(nodeChar, "skilllist")) do
    local sName = DB.getValue(nodeChild,"name",""):lower();
    if sName:find(sSkillNameLower) then
      bHas = true;
      break;
    end
  end

  return bHas;
end

--
-- Control+Drag/Drop story or ref-manual link, capture text and append that text
-- into the target record
--
function onDropStory(x, y, draginfo, nodeTarget, sTargetValueName)
  
  -- this is the value we're placing the text into on the target node
  if not sTargetValueName then
    sTargetValueName = 'text';
  end
  
  if not nodeTarget then
    return false;
  end
  
--UtilityManagerADND.logDebug("manager_utilities_adnd.lua","onDropStory","nodeTarget",nodeTarget);
  
  if draginfo.isType("shortcut") then
    --local nodeTarget = getDatabaseNode();
    local bLocked = (DB.getValue(nodeTarget,"locked",0) == 1);
    
    -- if record not locked and control pressed
    if not bLocked and Input.isControlPressed() then
      local nodeSource = draginfo.getDatabaseNode();
      local sClass, sRecord = draginfo.getShortcutData();
--UtilityManagerADND.logDebug("manager_utilities_adnd.lua","onDropStory","sClass",sClass);      
      -- if ref-manual page
      if (sClass == 'referencemanualpage') then
        local nodeRefMan = DB.findNode(sRecord);
        local sText = '';
        -- flip through blocks
        -- we need to sort the blocks so we get them in the right order
        local aNodeBlocks = UtilityManager.getSortedTable(DB.getChildren(nodeRefMan, "blocks"));
        for _,nodeBlock in ipairs(aNodeBlocks) do
          local sBlockType = DB.getValue(nodeBlock,"blocktype","");
          -- if the block is text append value in it to our text
          if sBlockType == 'singletext' then
            local sBlockText = DB.getValue(nodeBlock,"text","");
            sText = sText .. sBlockText;
          end
        end
        -- grab current text in target
        local sCurrentText = DB.getValue(nodeTarget,sTargetValueName);
        -- append target current text and source text together
        if sText then
          DB.setValue(nodeTarget,sTargetValueName,"formattedtext",sCurrentText .. sText);
        end
      -- if encounter/story entry
      elseif (sClass == "encounter") then
        -- grab text from source
        local sText = DB.getValue(nodeSource,"text");
        -- grab current text in target
        local sCurrentText = DB.getValue(nodeTarget,sTargetValueName);
        -- append target current text and source text together
        if sText then
          DB.setValue(nodeTarget,sTargetValueName,"formattedtext",sCurrentText .. sText);
        end
      -- if we can find "text" value on nodeSource then proceed
      elseif DB.getValue(nodeSource,"text") then
        local sText = DB.getValue(nodeSource,"text");
        local sCurrentText = DB.getValue(nodeTarget,sTargetValueName);
        if sCurrentText then
          DB.setValue(nodeTarget,sTargetValueName,"formattedtext",sCurrentText .. sText);
        end
      -- if we can find "description" value on nodeSource then proceed
      elseif DB.getValue(nodeSource,"description") then
        local sText = DB.getValue(nodeSource,"description");
        local sCurrentText = DB.getValue(nodeTarget,sTargetValueName);
        if sCurrentText then
          DB.setValue(nodeTarget,sTargetValueName,"formattedtext",sCurrentText .. sText);
        end
      end
    end
  end
end


-- get Identity of a char node or from the CT node that is a PC
function getIdentityFromCTNode(nodeCT)
  local rActor = ActorManager.resolveActor(nodeCT);
  -- local nodeActor = ActorManager.getCreatureNode(rActor);    
  local _, nodeActor = ActorManager.getTypeAndNode(rActor);    
  return getIdentityFromCharNode(nodeActor);
end
function getIdentityFromCharNode(nodeChar)
  return nodeChar.getName();
end

-- output a message simple function
function outputUserMessage(sResource, ...)
  local sFormat = Interface.getString(sResource);
  local sMsg = string.format(sFormat, ...);
  ChatManager.SystemMessage(sMsg);
end

-- output message as broadcast to all.
function outputBroadcastMessage(rActor, sResource, ...)
  local sFormat = Interface.getString(sResource);
  local sMsg = string.format(sFormat, ...);
  ChatManager.Message(sMsg, true, rActor)
end

-- (this allows me to split on 2+spaces)
function split(str, pat)
  local t = {};
  local fpat = "(.-)" .. pat;
  local last_end = 1;
  local s, e, cap = str:find(fpat, 1);
  while s do
  if s ~= 1 or cap ~= "" then
   table.insert(t,cap);
  end
    last_end = e+1;
    s, e, cap = str:find(fpat, last_end);
  end
  if last_end <= #str then
    cap = str:sub(last_end);
    table.insert(t, cap);
  end
  return t
end

-- find first item that matches this item name and return it's node.
function getItemByName(sItemName)
  local nodeItem = nil;
  local sItemNameLower = sItemName:lower();
  local vMappings = LibraryData.getMappings("item");
  for _,sMap in ipairs(vMappings) do
    for _,node in pairs(DB.getChildrenGlobal(sMap)) do
      local sName = DB.getValue(node,"name","");
      if sName:lower() == sItemNameLower then
        nodeItem = node;
        break;
      end
    end
    if nodeItem then
      break
    end
  end
  return nodeItem;
end

-- pass inventory in string format, _text is the countXname of item;countXname of item2
-- pass inventory in string format, _node is the node.getPath();node.getPath()
-- return the node for sItemToFind
---
-- <inventorylist_node type="string">npc.id-00006.inventorylist.id-00013;npc.id-00006.inventorylist.id-00024;npc.id-00006.inventorylist.id-00016;</inventorylist_node>
-- <inventorylist_text type="string">2xBackpack;10xIron Spike;14xRations, Dry, 1 day;</inventorylist_text>
function getInventoryItemFromTextList(sItemToFind, sInventoryList_Text,sInventoryList_Node)
  local nodeItem = nil;
  local nItemCount = 0;
  local sItemToFindLower = sItemToFind:lower();
  
  local aItems = StringManager.split(sInventoryList_Text,";",true);
  local aItemNodes = StringManager.split(sInventoryList_Node,";",true);
  for nID,sItemEntry in pairs(aItems) do 
    local nCount, sItemName = sItemEntry:match("(%d+)x(.*)");
    if nCount and sItemName and sItemToFindLower == sItemName:lower() then
      local nodeFoundItem = DB.findNode(sItemNodes[nID]);
      if nodeFoundItem then
        nodeItem = nodeFoundItem;
        break;
      end
    end
  end
  
  return nodeItem;
end

-- return a array of node paths that are in sTextList_Nodes of this npc
-- format is "node.getPath();node.getPath();"
function getNodeTableFromTextListInCT(nodeCT,sTextList_Nodes)
  local sTextListNodes = DB.getValue(nodeCT,sTextList_Nodes,"");
  local aNodeList = StringManager.split(sTextListNodes,";",true);
  return aNodeList;
end

-- return a array of item node paths that are in intenvory of this npc
function getItemNodeListFromNPCinCT(nodeCT)
  return getNodeTableFromTextListInCT(nodeCT,"inventorylist_node");
end


-- pass a nodeNPC node and return the "weaponlist" children as a json string to be stored into a node as one single entry.
-- Once we have it in json style text we can use it like:
-- local aWeaponList = Utility.decodeJSON(DB.getValue(nodeCT,'weaponlist_json',"");
-- DB.setValue(nodeCT,'weaponlist_json',"string",Utility.encodeJSON(aWeaponList));
function getWeaponListAsJSONText(node)
  local aWeaponsList = {};

  for sID, nodeWeapon in pairs(DB.getChildren(node,"weaponlist")) do
    local aWeapon = {};
    aWeapon.sSource = nodeWeapon.getPath();
    aWeapon.sID = sID; 
    aWeapon.sName = DB.getValue(nodeWeapon,"name","");
    aWeapon.nAttackCurrent = DB.getValue(nodeWeapon,"attackview_weapon",0);
    aWeapon.sAttackStat = DB.getValue(nodeWeapon,"attackstat","");
    aWeapon.nAttackBonus = DB.getValue(nodeWeapon,"attackbonus",0);
    aWeapon.nSpeedFactor = DB.getValue(nodeWeapon,"speedfactor",0);
    aWeapon.nType = DB.getValue(nodeWeapon,"type",0);
    aWeapon.nCarried = DB.getValue(nodeWeapon,"carried",0);
    aWeapon.nMaxAmmo = DB.getValue(nodeWeapon,"maxammo",0);
    aWeapon.nAmmo = DB.getValue(nodeWeapon,"ammo",0);
    aWeapon.nLocked = DB.getValue(nodeWeapon,"locked",1);
--    aWeapon.sShortcutClass, aWeapon.sShortcutRecord = DB.getValue(nodeWeapon,"shortcut","","");
    aWeapon.ItemNoteLocked = DB.getValue(nodeWeapon,"itemnote.locked",1);
    aWeapon.ItemNoteName = DB.getValue(nodeWeapon,"itemnote.name","");
    aWeapon.ItemNoteText = DB.getValue(nodeWeapon,"itemnote.text","");
    aWeapon.aDamageList = {};
    for sDMGid, nodeDamage in pairs(DB.getChildren(nodeWeapon,"damagelist")) do
      local aDamage = {};
      aDamage.sID = sDMGid;
      aDamage.sDamageAsString = DB.getValue(nodeDamage,"damageasstring","");
      aDamage.nBonus = DB.getValue(nodeDamage,"bonus",0);
      aDamage.dDice = DB.getValue(nodeDamage,"dice","");
      aDamage.sStat = DB.getValue(nodeDamage,"stat","");
      aDamage.sType = DB.getValue(nodeDamage,"type","");      
      table.insert(aWeapon.aDamageList,aDamage);
    end

    -- sort damage by id so they appear as they do in weapons tab right now
    local sort_byID = function( a,b ) return a.sID < b.sID end
    table.sort(aWeapon.aDamageList, sort_byID);

    -- add this weapon to weaponslist
    table.insert(aWeaponsList,aWeapon);

    -- Sort the weapons by name like they appear in list currently
    local sort_byName = function( a,b ) return a.sName < b.sName end
    table.sort(aWeaponsList, sort_byName);
  end

  local sJson = Utility.encodeJSON(aWeaponsList);
  
  return sJson;  
end

-- this is to replace a string value at a specific location
-- why the heck doesn't lua have this natively? -- celestian
function replaceStringAt(sOriginal,sReplacement,nStart,nEnd)
  local sFinal = nil;
  if (nStart == 1) then
    sFinal = sReplacement .. sOriginal:sub(nEnd+1,sOriginal:len());
  else
    sFinal = sOriginal:sub(1,nStart-1) .. sReplacement .. sOriginal:sub(nEnd+1,sOriginal:len());
  end
  return sFinal;
end

--[[
  Get a item node by string name sItem
]]
function getItemNodeByName(sItem)
  local nodeFoundItem = nil;
-- UtilityManagerADND.logDebug("manager_utilities_adnd.lua","getItemNodeByName","sItem",sItem);  
  local vMappings = LibraryData.getMappings("item");
  for _,sMap in ipairs(vMappings) do
    for _,nodeItem in pairs(DB.getChildrenGlobal(sMap)) do
      local sItemName = DB.getValue(nodeItem,"name");
      if sItemName:lower() == sItem:lower() then 
        nodeFoundItem = nodeItem;
        break;
      end
    end
    if nodeFoundItem then
      break;
    end
  end
  return nodeFoundItem;
end

-- find a weapon, by name, and return it as node
function getWeaponNodeByName(sWeapon)
  local nodeWeapon = nil;
--UtilityManagerADND.logDebug("manager_utilities_adnd.lua","getWeaponNodeByName","sWeapon",sWeapon);  
  local vMappings = LibraryData.getMappings("item");
  for _,sMap in ipairs(vMappings) do
    for _,nodeItem in pairs(DB.getChildrenGlobal(sMap)) do
      local sItemName = DB.getValue(nodeItem,"name");
      if sItemName:lower() == sWeapon:lower() then 
        if ItemManager2.isWeapon(nodeItem) then
          nodeWeapon = nodeItem;
          break;
        end
      end
    end
    if nodeWeapon then
      break;
    end
  end
  return nodeWeapon;
end

-- check to see if the node has a weapon of same name
function hasWeaponNamed(nodeEntry,sWeapon)
  local bHasWeapon = false;
  for _, nodeWeapon in pairs(DB.getChildren(nodeEntry,"weaponlist")) do
    local sName = DB.getValue(nodeWeapon,"name"):lower();
    if sWeapon == sName then
      bHasWeapon = true;
      return bHasWeapon;
    end
  end
  
  return bHasWeapon;
end

-- strip out formattedtext from a string
function stripFormattedText(sText)
  local sTextOnly = sText;
  sTextOnly = sTextOnly:gsub("</p>","\n");
  sTextOnly = sTextOnly:gsub("<.?[ubiphUBIPH]>","");
  sTextOnly = sTextOnly:gsub("<.?table>","");
  sTextOnly = sTextOnly:gsub("<.?frame>","");
  sTextOnly = sTextOnly:gsub("<.?t.?>","");
  sTextOnly = sTextOnly:gsub("<.?list>","");
  sTextOnly = sTextOnly:gsub("<.?li>","");
  return sTextOnly;  
end

-- return only the alpha characters from sText
function alphaOnly(sText)
  return sText:gsub("[^a-zA-Z]+","");
end

-- find if the "set" array contains "item" string.
-- uses find within the string, not exact match
function containsAny(aSet, item)
  for _, sSetType in ipairs(aSet) do
    local sSetTypeLower = sSetType:lower();
    if sSetTypeLower:find(item) then
			return true;
    end
  end
	return false;
end

-- clean up entries 
function sanitizeTraitText(s)
  local sSanitized = StringManager.trim(s:gsub("%s%(.*%)$", ""));
  sSanitized = sSanitized:gsub("[.,-():'’/?+–]", "_"):gsub("%s", ""):lower();
  return sSanitized
end

-- return plus or minus sign in front of number
function getNumberSign(nNumber)
  local sSign = "+";
  if nNumber < 0 then
    sSign = "-";
  end
  return sSign .. math.abs(nNumber);
end

-- wait "s" Seconds, THIS IS BLOCKING and will halt everything while it waits...
function sleep(s)
  local ntime = os.clock() + s;
  repeat until os.clock() > ntime;
end

-- ask Yes/No question and send result to "responseFunction" = function responseFunction(result) and result ="yes" or "no".
function askYN(responseFunction,sQuestion)
  if not responseFunction then
    return;
  end
  Interface.dialogMessage( responseFunction, sQuestion, 'Yes/No','yesno' );
end

-- return the version of this ruleset.
function getRulesetVersion()
  local _, _, aMajor, aMinor = DB.getRulesetVersion();
  return aMajor['2E'];
end

-- concat aSourceTable into aDestTable
function concatTables(aDestTable,aSourceTable)
  if aSourceTable and #aSourceTable > 0 then
    for _,rEntry in ipairs(aSourceTable) do
      table.insert(aDestTable,rEntry);
    end
  end
  return aDestTable;
end


function processReadyCheck(sCommand, sParams)
  if Session.IsHost then
    local wWindow = Interface.openWindow("readycheck","");
    if wWindow then
      -- share this window with every person connected.
      for _,name in pairs(User.getActiveUsers()) do
        wWindow.share(name);
      end
    end
  end
end

--[[

  Simple rate limiter, pass object, and time. 
  Returns true if the last time run is greater than the nTime limit.

]]
local aRateList = {};
function rateLimitOK(fFunction, oObject, nTime)
  local bOK = true;
  local nTimeLimit = 0;
  if nTime > 0 then
    nTimeLimit = nTime;
  end
    if not aRateList[fFunction] then
    local rRate = {};
    rRate.functionObject = fFunction;
    rRate.lastrun = os.clock();
    rRate.oObject = oObject;
    aRateList[fFunction] = rRate;
  elseif aRateList[fFunction] and nTimeLimit > 0 then
    local rRate = aRateList[fFunction]
    if rRate.oObject == oObject then
      local cCurrent = os.clock();
      local cDiff = cCurrent - rRate.lastrun;
      -- UtilityManagerADND.logDebug("manager_utilities_adnd.lua","rateLimitOK","rRate",rRate,cDiff,cCurrent,nTimeLimit)      
--      UtilityManagerADND.logDebug("manager_utilities_adnd.lua","rateLimitOK","rRate.lastrun",rRate.lastrun)    
--      UtilityManagerADND.logDebug("manager_utilities_adnd.lua","rateLimitOK","cCurrent",cCurrent)    
--      UtilityManagerADND.logDebug("manager_utilities_adnd.lua","rateLimitOK","cDiff",cDiff)    
      if cDiff < nTimeLimit then
        bOK = false;
        -- UtilityManagerADND.logDebug("manager_utilities_adnd.lua","rateLimitOK","TO SOON:rRate",rRate,cDiff,cCurrent,nTimeLimit)
      else
        rRate.lastrun = cCurrent;
        aRateList[fFunction] = rRate;
      end
    end
  end
  
  return bOK;
end
--[[
  
  return array list of all spell names 
  
  used for random spell/skill/etc population
]]
function getGlobalSpellList()
  local aNameList ={};
  local aMappings = LibraryData.getMappings('spell');
  for _,vMapping in ipairs(aMappings) do
    for _,nodeObject in pairs(DB.getChildrenGlobal(vMapping)) do
      -- UtilityManagerADND.logDebug("getGlobalSpellList","nodeObject",nodeObject)
      local sObjectName = DB.getValue(nodeObject, "name");
      if sObjectName then
        table.insert(aNameList, nodeObject);
      end
    end
  end
  
  return aNameList;
end

--[[
   get random spells for nLevel of sType nCount of
]]
function getRandomSpellList(aList, nLevel, sType, nCount)

  if #aList == 0 then
      aList = getGlobalSpellList();
  end

  local aSpellsByLevel = {};
  local aRandomSpells = {};
  
  -- build list of spells for this level
  for i= 1, #aList do
    local nodeObject = aList[i];
    local sSpellType   = DB.getValue(nodeObject,"type",""):lower();
    local nSpellLevel  = DB.getValue(nodeObject,"level",-1);
    if nSpellLevel == nLevel and sSpellType == sType then
      table.insert(aSpellsByLevel,nodeObject);
    end
  end
  -- find nCount of random spells
  local nMaxSpells = #aSpellsByLevel;

  if nMaxSpells > 0 then
    for i=1,nCount do
      local nRandom = math.random(nMaxSpells);
      table.insert(aRandomSpells,aSpellsByLevel[nRandom]);
    end
  end

  return aRandomSpells;
end

--[[ 

  Utility function to concat 2 arrays into 1

]]
function TableConcat(t1,t2)
  for i=1,#t2 do
      t1[#t1+1] = t2[i]
  end
  return t1
end

--[[
  
  Replace TableManager version of this so we can have dynamic cost of a item generated

  CoreRPG function in manager_table.lua

  The bulk of this function is untouched

]]
aTableRollStack = {};
function onTableRoll_adnd(rSource, rTarget, rRoll)
	local nodeTable = DB.findNode(rRoll.sNodeTable);
	if not nodeTable then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_tablematch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	local sOutput = rRoll.sOutput or "";
	local nTotal = ActionsManager.total(rRoll);
	local nColumn = 0;
	local sPattern2 = "%[" .. Interface.getString("table_tag") .. "%] [^[]+%[(%d+) %- ([^)]*)%]";
	local sColumn = rRoll.sDesc:match(sPattern2);
	if sColumn then
		nColumn = tonumber(sColumn) or 0;
	end
	
	local aResults = TableManager.getResults(nodeTable, nTotal, nColumn);
	if not aResults then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_columnmatch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	for _,v in ipairs(aResults) do
		v.aMult = {};
		
		v.aTableLinks = {};
		v.aOtherLink = nil;
		
		if (v.sClass or "") ~= "" then
			if v.sClass == "table" then
				table.insert(v.aTableLinks, { sClass = v.sClass, sRecord = v.sRecord });
			else
				v.aOtherLink = { sClass = v.sClass, sRecord = v.sRecord };
			end
		end

		if v.sText ~= "" then
			local sResult = v.sText;
			
			local sTag;
			local aMathResults = {};
			for nStartTag, sTag, nEndTag in v.sText:gmatch("()%[([^%]]+)%]()") do
				local bMult = false;
				local sPotentialRoll = sTag;
				if sPotentialRoll:match("x$") then
					sPotentialRoll = sPotentialRoll:sub(1, -2);
					bMult = true;
				end
				if DiceManager.isDiceMathString(sPotentialRoll) then
					local nMathResult = DiceManager.evalDiceMathExpression(sPotentialRoll);
					if bMult then
						table.insert(v.aMult, nMathResult);
						if sOutput == "parcel" then
							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
						else
							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = string.format("[%dx]", nMathResult) });
						end
					else
						table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
					end
				else
					local nodeTable = TableManager.findTable(sTag);
					if nodeTable then
						table.insert(v.aTableLinks, { sClass = "table", sRecord = DB.getPath(nodeTable) });
					end
				end
			end
			for i = #aMathResults,1,-1 do
				sResult = sResult:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sResult:sub(aMathResults[i].nEnd);
			end
			
			v.sText = sResult;
		end
	end

	local nodeTarget = nil;
	local bTopTable = true;
	if sOutput ~= "" and rRoll.sOutputNode then
		nodeTarget = DB.findNode(rRoll.sOutputNode);
		if nodeTarget then
			bTopTable = false; -- Only relevant for parcel and story output
		end
	end
	
	local sResultName = string.format("[%s] %s", Interface.getString("table_result_tag"), DB.getValue(nodeTable, "name", ""));
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Build chat messages with links as needed
	local aAddChatMessages = {};
	rMessage.shortcuts = {};
	if sOutput == "story" then
		if not nodeTarget then
			nodeTarget = DB.createChild("encounter");
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				Interface.openWindow("encounter", nodeTarget);
			else
				sOutput = "";
			end
		end

		if bTopTable then
			table.insert(rMessage.shortcuts, { description = sResultName, class = "encounter", recordname = DB.getPath(nodeTarget) });
		end
		
		local sAddDesc = "";
		for _,v in ipairs(aResults) do
			local sText = v.sText;
			sText = sText:gsub("%[[^%]]*%]", "");
			sText = StringManager.trim(sText);
			if sText:match("^%([%d]*%)$") then
				sText = "";
			end
			
			if sText ~= "" and sText ~= "-" then
				if v.aOtherLink then
					sAddDesc = sAddDesc .. "<linklist><link class=\"" .. UtilityManager.encodeXML(v.aOtherLink.sClass) .. "\" recordname=\"" .. UtilityManager.encodeXML(v.aOtherLink.sRecord) .. "\">" .. UtilityManager.encodeXML(sText) .. "</link></linklist>";
				elseif (bTopTable or (#v.aTableLinks == 0)) then
					if sText:match("^<[biu]>") then
						sAddDesc = sAddDesc .. "<p>" .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>") .. "</p>";
					elseif sText:match("^<[ph]>") then
						sAddDesc = sAddDesc .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>");
					else
						sAddDesc = sAddDesc .. "<list><li>" .. UtilityManager.encodeXML(sText) .. "</li></list>";
					end
				end
			end
		end
		
		if sAddDesc ~= "" then
			DB.setValue(nodeTarget, "text", "formattedtext", DB.getValue(nodeTarget, "text", "") .. sAddDesc);
		end
		
	elseif sOutput == "parcel" then
		if not nodeTarget then
			local sRootMapping = LibraryData.getRootMapping("treasureparcel");
			nodeTarget = DB.createChild(sRootMapping);
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				Interface.openWindow("treasureparcel", nodeTarget);
			else
				sOutput = "";
			end
		end

		if bTopTable then
			table.insert(rMessage.shortcuts, { description = sResultName, class = "treasureparcel", recordname = DB.getPath(nodeTarget) });
		end
		
		for _,v in ipairs(aResults) do
			--[[ 
				check for a @value on a table entry and if it's there
				set it as the value for the item.

        "Gem@[1d10+10*10] gp"

        Would create a item "Gem" (or copy the linked item) and set the cost to the rolled value.

        --celestian
			]]
      local sMatchString = "@([%w%s]+)$";
			if v.sText:match(sMatchString) then
				local sName = v.sText:match("^(.*)@"); 		-- get everything before @ as name
				local sValue = v.sText:match(sMatchString); -- get everything after @ as cost
				local nCount = v.aMult[1] or 1;
				local nodeItems = nodeTarget.createChild('itemlist');
				local nodeItem = nodeItems.createChild();
				-- if linked record, copy it
				if v.sRecord and v.sRecord ~= "" then
					DB.copyNode(DB.findNode(v.sRecord),nodeItem);
				else
					DB.setValue(nodeItem,"name","string",sName);
				end
				DB.setValue(nodeItem,"cost","string",sValue);
				DB.setValue(nodeItem,"count","number",nCount);
			else -- this is end of value update code for setting items values
        local bHandled = false;
        if v.aOtherLink then
          bHandled = ItemManager.addLinkToParcel(nodeTarget, v.aOtherLink.sClass, v.aOtherLink.sRecord, v.aMult[1]); 
        end
        if not bHandled and (#v.aTableLinks == 0) then
          ItemManager.handleString(nodeTarget, v.sText, v.aMult[1]);
        end
      end
		end

	elseif sOutput == "encounter" then
		if not nodeTarget then
			local sRootMapping = LibraryData.getRootMapping("battle");
			nodeTarget = DB.createChild(sRootMapping);
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				Interface.openWindow("battle", nodeTarget);
			else
				sOutput = "";
			end
		end

		if bTopTable then
			table.insert(rMessage.shortcuts, { description = sResultName, class = "battle", recordname = DB.getPath(nodeTarget) });
		end
		
		for _,v in ipairs(aResults) do
			local bHandled = false;
			if v.aOtherLink then
				NPCManager.addLinkToBattle(nodeTarget, v.aOtherLink.sClass, v.aOtherLink.sRecord, v.aMult[1]);
			end
		end

	else -- Chat output
		rMessage.text = rMessage.text .. " = ";
		
		local bResultLinks = false;
		for _,v in ipairs(aResults) do
			if v.aOtherLink then
				bResultLinks = true;
			end
		end
		
		for _,v in ipairs(aResults) do
			local sResult = v.sText;
			if ((v.sLabel or "") ~= "") and (#aResults > 1) then
				sResult = v.sLabel .. " = " .. sResult;
			end
			
			local rResultMsg = { font = "systemfont", secret = rMessage.secret };
			if bResultLinks then
				rResultMsg.text = sResult;
				if v.aOtherLink then
					rResultMsg.shortcuts = {};
					table.insert(rResultMsg.shortcuts, { class = v.aOtherLink.sClass, recordname = v.aOtherLink.sRecord });
				end
			else
				rResultMsg.text = sResult;
			end

			table.insert(aAddChatMessages, rResultMsg);
		end
	end
	
	-- Output any chat messages
	if rMessage.secret then
		Comm.addChatMessage(rMessage);
		for _,vMsg in ipairs(aAddChatMessages) do
			Comm.addChatMessage(vMsg);
		end
	else
		Comm.deliverChatMessage(rMessage);
		for _,vMsg in ipairs(aAddChatMessages) do
			Comm.deliverChatMessage(vMsg);
		end
	end
	

	-- Follow cascading table links
	local aLocalTableStack = {};
	for _,v in ipairs(aResults) do
		for kLink,vLink in ipairs(v.aTableLinks) do
			local nMult = v.aMult[kLink] or 1;
			
			for i = 1, nMult do
				local rTableRoll = {};
				rTableRoll.nodeTable = DB.findNode(vLink.sRecord);
				rTableRoll.bSecret = rRoll.bSecret;
				rTableRoll.sOutput = rRoll.sOutput;
				rTableRoll.nodeOutput = nodeTarget;
				
				table.insert(aLocalTableStack, rTableRoll);
			end
		end
	end
	for i = #aLocalTableStack, 1, -1 do
		table.insert(aTableRollStack, aLocalTableStack[i]);
	end
	if #aTableRollStack > 0 then
		local rTableRoll = table.remove(aTableRollStack);
		if not rTableRoll then
			ChatManager.SystemMessage(Interface.getString("table_error_sequentialfail") .. " (" .. sTable .. ")");
			aTableRollStack = {};
			return;
		end

		if not Interface.isDiceRollingDisabled() then
			Interface.disableDiceRolling(true);
			TableManager.performRoll(nil, rSource, rTableRoll, false);
			Interface.disableDiceRolling(false);
		else
			TableManager.performRoll(nil, rSource, rTableRoll, false);
		end
	end
end

--OLD ROLL
-- function onTableRoll_adnd_old(rSource, rTarget, rRoll)
-- 	local nodeTable = DB.findNode(rRoll.sNodeTable);
-- 	if not nodeTable then
-- 		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
-- 		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_tablematch") .. "]";
-- 		Comm.addChatMessage(rMessage);
-- 		return;
-- 	end
	
-- 	local sOutput = rRoll.sOutput or "";
-- 	local nTotal = ActionsManager.total(rRoll);
-- 	local nColumn = 0;
-- 	local sPattern2 = "%[" .. Interface.getString("table_tag") .. "%] [^[]+%[(%d+) %- ([^)]*)%]";
-- 	local sColumn = rRoll.sDesc:match(sPattern2);
-- 	if sColumn then
-- 		nColumn = tonumber(sColumn) or 0;
-- 	end
	
-- 	local aResults = TableManager.getResults(nodeTable, nTotal, nColumn);
-- 	if not aResults then
-- 		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
-- 		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_columnmatch") .. "]";
-- 		Comm.addChatMessage(rMessage);
-- 		return;
-- 	end
	
-- 	for _,v in ipairs(aResults) do
-- 		v.aMult = {};
		
-- 		v.aTableLinks = {};
-- 		v.aOtherLink = nil;
		
-- 		if (v.sClass or "") ~= "" then
-- 			if v.sClass == "table" then
-- 				table.insert(v.aTableLinks, { sClass = v.sClass, sRecord = v.sRecord });
-- 			else
-- 				v.aOtherLink = { sClass = v.sClass, sRecord = v.sRecord };
-- 			end
-- 		end

-- 		if v.sText ~= "" then
-- 			local sResult = v.sText;
			
-- 			local sTag;
-- 			local aMathResults = {};
-- 			for nStartTag, sTag, nEndTag in v.sText:gmatch("()%[([^%]]+)%]()") do
-- 				local bMult = false;
-- 				local sPotentialRoll = sTag;
-- 				if sPotentialRoll:match("x$") then
-- 					sPotentialRoll = sPotentialRoll:sub(1, -2);
-- 					bMult = true;
-- 				end
-- 				if StringManager.isDiceMathString(sPotentialRoll) then
-- 					local nMathResult = StringManager.evalDiceMathExpression(sPotentialRoll);
-- 					if bMult then
-- 						table.insert(v.aMult, nMathResult);
-- 						if sOutput == "parcel" then
-- 							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
-- 						else
-- 							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
-- 						end
-- 					else
-- 						table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
-- 					end
-- 				else
-- 					local nodeTable = TableManager.findTable(sTag);
-- 					if nodeTable then
-- 						table.insert(v.aTableLinks, { sClass = "table", sRecord = nodeTable.getPath() });
-- 					end
-- 				end
-- 			end
-- 			for i = #aMathResults,1,-1 do
-- 				sResult = sResult:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sResult:sub(aMathResults[i].nEnd);
-- 			end
			
-- 			v.sText = sResult;
-- 		end
-- 	end

-- 	local nodeTarget = nil;
-- 	local bTopTable = true;
-- 	if sOutput ~= "" and rRoll.sOutputNode then
-- 		nodeTarget = DB.findNode(rRoll.sOutputNode);
-- 		if nodeTarget then
-- 			bTopTable = false; -- Only relevant for parcel and story output
-- 		end
-- 	end
	
-- 	local sResultName = "[" .. Interface.getString("table_result_tag") .. "] " .. DB.getValue(nodeTable, "name", "");
-- 	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

-- 	-- Build chat messages with links as needed
-- 	local aAddChatMessages = {};
-- 	rMessage.shortcuts = {};
-- 	if sOutput == "story" then
-- 		if not nodeTarget then
-- 			nodeTarget = DB.createChild("encounter");
-- 			if nodeTarget then
-- 				DB.setValue(nodeTarget, "name", "string", sResultName);
-- 				Interface.openWindow("encounter", nodeTarget);
-- 			else
-- 				sOutput = "";
-- 			end
-- 		end

-- 		if bTopTable then
-- 			table.insert(rMessage.shortcuts, { description = sResultName, class = "encounter", recordname = nodeTarget.getPath() });
-- 		end
		
-- 		local sAddDesc = "";
-- 		for _,v in ipairs(aResults) do
-- 			local sText = v.sText;
-- 			sText = sText:gsub("%[[^%]]*%]", "");
-- 			sText = StringManager.trim(sText);
-- 			if sText:match("^%([%d]*%)$") then
-- 				sText = "";
-- 			end
			
-- 			if sText ~= "" and sText ~= "-" then
-- 				if v.aOtherLink then
-- 					sAddDesc = sAddDesc .. "<linklist><link class=\"" .. UtilityManager.encodeXML(v.aOtherLink.sClass) .. "\" recordname=\"" .. UtilityManager.encodeXML(v.aOtherLink.sRecord) .. "\">" .. UtilityManager.encodeXML(sText) .. "</link></linklist>";
-- 				elseif (bTopTable or (#v.aTableLinks == 0)) then
-- 					if sText:match("^<[biu]>") then
-- 						sAddDesc = sAddDesc .. "<p>" .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>") .. "</p>";
-- 					elseif sText:match("^<[ph]>") then
-- 						sAddDesc = sAddDesc .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>");
-- 					else
-- 						sAddDesc = sAddDesc .. "<list><li>" .. UtilityManager.encodeXML(sText) .. "</li></list>";
-- 					end
-- 				end
-- 			end
-- 		end
		
-- 		if sAddDesc ~= "" then
-- 			DB.setValue(nodeTarget, "text", "formattedtext", DB.getValue(nodeTarget, "text", "") .. sAddDesc);
-- 		end
		
-- 	elseif sOutput == "parcel" then
-- 		if not nodeTarget then
-- 			local sRootMapping = LibraryData.getRootMapping("treasureparcel");
-- 			nodeTarget = DB.createChild(sRootMapping);
-- 			if nodeTarget then
-- 				DB.setValue(nodeTarget, "name", "string", sResultName);
-- 				Interface.openWindow("treasureparcel", nodeTarget);
-- 			else
-- 				sOutput = "";
-- 			end
-- 		end

-- 		if bTopTable then
-- 			table.insert(rMessage.shortcuts, { description = sResultName, class = "treasureparcel", recordname = nodeTarget.getPath() });
-- 		end
		
-- 		for _,v in ipairs(aResults) do

-- 			--[[ 
-- 				check for a @value on a table entry and if it's there
-- 				set it as the value for the item.

--         "Gem@[1d10+10*10] gp"

--         Would create a item "Gem" (or copy the linked item) and set the cost to the rolled value.

--         --celestian
-- 			]]
--       local sMatchString = "@([%w%s]+)$";
-- 			if v.sText:match(sMatchString) then
-- 				local sName = v.sText:match("^(.*)@"); 		-- get everything before @ as name
-- 				local sValue = v.sText:match(sMatchString); -- get everything after @ as cost
-- 				local nCount = v.aMult[1] or 1;
-- 				local nodeItems = nodeTarget.createChild('itemlist');
-- 				local nodeItem = nodeItems.createChild();
-- 				-- if linked record, copy it
-- 				if v.sRecord and v.sRecord ~= "" then
-- 					DB.copyNode(DB.findNode(v.sRecord),nodeItem);
-- 				else
-- 					DB.setValue(nodeItem,"name","string",sName);
-- 				end
-- 				DB.setValue(nodeItem,"cost","string",sValue);
-- 				DB.setValue(nodeItem,"count","number",nCount);
-- 			else
-- 				-- this is end of value update code for setting items values

-- 				local bHandled = false;
-- 				if v.aOtherLink then
-- 					bHandled = ItemManager.addLinkToParcel(nodeTarget, v.aOtherLink.sClass, v.aOtherLink.sRecord, v.aMult[1]); 
-- 				end
-- 				if not bHandled and (#v.aTableLinks == 0) then
-- 					ItemManager.handleString(nodeTarget, v.sText, v.aMult[1]);
-- 				end
-- 			end
-- 		end

-- 	elseif sOutput == "encounter" then
-- 		if not nodeTarget then
-- 			local sRootMapping = LibraryData.getRootMapping("battle");
-- 			nodeTarget = DB.createChild(sRootMapping);
-- 			if nodeTarget then
-- 				DB.setValue(nodeTarget, "name", "string", sResultName);
-- 				Interface.openWindow("battle", nodeTarget);
-- 			else
-- 				sOutput = "";
-- 			end
-- 		end

-- 		if bTopTable then
-- 			table.insert(rMessage.shortcuts, { description = sResultName, class = "battle", recordname = nodeTarget.getPath() });
-- 		end
		
-- 		for _,v in ipairs(aResults) do
-- 			local bHandled = false;
-- 			if v.aOtherLink then
-- 				NPCManager.addLinkToBattle(nodeTarget, v.aOtherLink.sClass, v.aOtherLink.sRecord, v.aMult[1]);
-- 			end
-- 		end

-- 	else -- Chat output
-- 		rMessage.text = rMessage.text .. " = ";
		
-- 		local bResultLinks = false;
-- 		for _,v in ipairs(aResults) do
-- 			if v.aOtherLink then
-- 				bResultLinks = true;
-- 			end
-- 		end
		
-- 		for _,v in ipairs(aResults) do
-- 			local sResult = v.sText;
-- 			if ((v.sLabel or "") ~= "") and (#aResults > 1) then
-- 				sResult = v.sLabel .. " = " .. sResult;
-- 			end
			
-- 			local rResultMsg = { font = "systemfont", secret = rMessage.secret };
-- 			if bResultLinks then
-- 				rResultMsg.text = sResult;
-- 				if v.aOtherLink then
-- 					rResultMsg.shortcuts = {};
-- 					table.insert(rResultMsg.shortcuts, { class = v.aOtherLink.sClass, recordname = v.aOtherLink.sRecord });
-- 				end
-- 			else
-- 				rResultMsg.text = sResult;
-- 			end
-- 			table.insert(aAddChatMessages, rResultMsg);
-- 		end
-- 	end
	
-- 	-- Output any chat messages
-- 	if rMessage.secret then
-- 		Comm.addChatMessage(rMessage);
-- 		for _,vMsg in ipairs(aAddChatMessages) do
-- 			Comm.addChatMessage(vMsg);
-- 		end
-- 	else
-- 		Comm.deliverChatMessage(rMessage);
-- 		for _,vMsg in ipairs(aAddChatMessages) do
-- 			Comm.deliverChatMessage(vMsg);
-- 		end
-- 	end
	
-- 	-- Follow cascading table links
-- 	local aLocalTableStack = {};
-- 	for _,v in ipairs(aResults) do
-- 		for kLink,vLink in ipairs(v.aTableLinks) do
-- 			local nMult = v.aMult[kLink] or 1;
			
-- 			for i = 1, nMult do
-- 				local rTableRoll = {};
-- 				rTableRoll.nodeTable = DB.findNode(vLink.sRecord);
-- 				rTableRoll.bSecret = rRoll.bSecret;
-- 				rTableRoll.sOutput = rRoll.sOutput;
-- 				rTableRoll.nodeOutput = nodeTarget;
				
-- 				table.insert(aLocalTableStack, rTableRoll);
-- 			end
-- 		end
-- 	end
-- 	for i = #aLocalTableStack, 1, -1 do
-- 		table.insert(aTableRollStack, aLocalTableStack[i]);
-- 	end
-- 	if #aTableRollStack > 0 then
-- 		local rTableRoll = table.remove(aTableRollStack);
-- 		if not rTableRoll then
-- 			ChatManager.SystemMessage(Interface.getString("table_error_sequentialfail") .. " (" .. sTable .. ")");
-- 			aTableRollStack = {};
-- 			return;
-- 		end
-- 		TableManager.performRoll(nil, rSource, rTableRoll, false);
-- 	end
-- end