-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

aIgnoreFields = {"displaymode","powerdisplaymode","powermode","text","damage","token","name"};
aTypes = {};

function onInit()
    -- insert the "Random" button to the NPC records list menu for use
    if LibraryData.aRecords['npc'].aGMListButtons then
        table.insert(LibraryData.aRecords['npc'].aGMListButtons,'button_encounter_generator');
    else
        LibraryData.aRecords['npc'].aGMListButtons = {'button_encounter_generator'};
    end
end

function loadNPCData()
    aTypes = getFieldsInNPCRecords();
end


--[[
    Add a field that will be ignored when scanning for filters
]]
function addIgnoreField(sField)
    table.insert(aIgnoreFields,sField);
end

--[[
    Builds multi-dimensional array of data.
    
    aType[record][aListOfValues]

]]
function getFieldsInNPCRecords()
    --UtilityManagerADND.logDebug("manager_encountersafari.lua","getFieldsInNPCRecords");
    local aBuildTypes = {};
    local nCount = 0;
    for _,vMapping in ipairs(LibraryData.getMappings("npc")) do
        for _,node in pairs(DB.getChildrenGlobal(vMapping)) do
            nCount = nCount +1;
            for _,nodeEntry in pairs(DB.getChildrenGlobal(node)) do
                if type(nodeEntry.getValue()) == "string" then
                    -- strip module name out
                    local sCleanPath = StringManager.split(nodeEntry.getPath(), "@")[1];
                    -- get the data "field" name only npc.id-00000.type in this case "type"
                    local sField = sCleanPath:match("%.([_%w]+)$");
                    -- if we're not ignoring the field type then add to matrix.
                    if sField and not StringManager.contains(aIgnoreFields, sField) then
                        local aValues = {};
                        local sValue = nodeEntry.getValue() or "";
                        -- if this field already has values
                        if aBuildTypes[sField] then
                            aValues = aBuildTypes[sField];
                        end
                        local aSplitTypes = {sValue};
                        aSplitTypes = StringManager.split(sValue,",",true);
                        for _,sValueSplit in pairs(aSplitTypes) do
                            -- insert this value for the field
                            if not StringManager.contains(aValues, sValueSplit) then
                                table.insert(aValues,sValueSplit);
                            end
                        end

                        aBuildTypes[sField] = aValues;
                    end
                end
            end
        end
    end
    -- allow name entry, but blank, so they can edit and specify?
    aBuildTypes['name'] = {'<enter value>'};
    -- type MUST exist
    if not aBuildTypes['type'] then
        aBuildTypes['type'] = {'<enter value>'};
    end

    --  this is pointless, combobox sorts it and messes it up. Trying to fix that is another nightmare
--     -- sort the hitDice value a little better
--     if (sRuleset == '2E') and aBuildTypes['hitDice'] then
--         aBuildTypes['hitDice'] = sortADNDHitDice(aBuildTypes['hitDice']);
--     end            
                    
    --UtilityManagerADND.logDebug("manager_encountersafari.lua","getFieldsInNPCRecords","aBuildTypes",aBuildTypes);
    --UtilityManagerADND.logDebug("Scanned " .. nCount .. " npc entries.");
    return aBuildTypes;
end

--  this is pointless, combobox sorts it and messes it up. Trying to fix that is another nightmare
-- see if this will sort hitDice better
-- function sortADNDHitDice(aFilterValues)
--     local function fHitDiceSorValue(a)
--         --local v = tonumber(a:match("^(%d+)")) or 0;
--         local v = CombatManagerADND.getNPCLevelFromHitDice(a);
--             return v;
--         end
--     table.sort(aFilterValues, function(a,b) return fHitDiceSorValue(a) < fHitDiceSorValue(b); end);
--     return aFilterValues;
-- end

--[[
    Return array that combobox can deal with
]]
function getKeys(aMArray)
    local aList = {};
    for k,v in pairs(aMArray) do
        table.insert(aList,k);
    end
    return aList;
end

--[[
    build a table of the current filters
]]
function getFilterTable(aWindowList)
    local aFilterList = {}
    
    for _, oFilter in pairs(aWindowList) do
        local rFilter = {};
        rFilter.operation = oFilter.operation.getValue();
        rFilter.type = oFilter.filtertype.getValue();
        rFilter.value = oFilter.filtervalue.getValue();
        if oFilter.custom_toggle.getValue() == 1 then
            rFilter.value = oFilter.filtervaluecustom.getValue();
        end
        rFilter.value = rFilter.value:lower(); -- lower case this
        rFilter.logic = oFilter.logic.getValue();
        table.insert(aFilterList,rFilter);
    end
    
    return aFilterList;
end

--[[
    Get table of NPCs using filters
]]
function getFilteredNPCs(aFilterList)
    local aNPCList = {};
    -- check each npc for matches
    for _,vMapping in ipairs(LibraryData.getMappings("npc")) do
        for _,node in pairs(DB.getChildrenGlobal(vMapping)) do
            
            --local bAllFound = true;
            local aSearchResults = {};
            -- check each filter for match
            for _,rFilter in pairs(aFilterList) do
                local sValue = DB.getValue(node,rFilter.type);
                if sValue then
                    sValue = sValue:lower();
                end
                -- used as catch all for "found" the value we're looking for.
                local bFound = false;
                local rSearch = {};
                rSearch.operation = rFilter.operation;
                rSearch.type = rFilter.type;
                -- exact match
                if rFilter.logic == 0 and sValue and sValue:match("^" .. rFilter.value .. "$") then
                    bFound = true;
                -- anywhere match
                elseif rFilter.logic == 1 and sValue and sValue:match(rFilter.value) then
                    bFound = true;
                -- number or greater
                elseif rFilter.logic == 2 and sValue then
                    local sNumber = sValue:match("[%-%.%d]+");
                    local nNumber = tonumber(sNumber) or nil;
                    local sValueNumber = rFilter.value:match("[%-%.%d]+");
                    local nValueNumber = tonumber(sValueNumber) or nil;
                    
                    -- For 2E, get a "level" from HD to properly calculate comparison
                    if rFilter.type == 'hitDice' then
                        nNumber = CombatManagerADND.getNPCLevelFromHitDice(sValue);
                        nValueNumber = CombatManagerADND.getNPCLevelFromHitDice(rFilter.value);
                    end

                    if nNumber and nValueNumber and nNumber >= nValueNumber then
                        bFound = true;
                    else
                        --bMostFound = false;
                    end
                -- number or lesser
                elseif rFilter.logic == 3 and sValue then
                    local sNumber = sValue:match("[%-%.%d]+");
                    local nNumber = tonumber(sNumber) or nil;
                    local sValueNumber = rFilter.value:match("[%-%.%d]+");
                    local nValueNumber = tonumber(sValueNumber) or nil;

                    -- For 2E, get a "level" from HD to properly calculate comparison
                    if rFilter.type == 'hitDice' then
                        nNumber = CombatManagerADND.getNPCLevelFromHitDice(sValue);
                        nValueNumber = CombatManagerADND.getNPCLevelFromHitDice(rFilter.value);
                    end

                    if nNumber and nValueNumber and nNumber <= nValueNumber then
                        bFound = true;
                    else
                        --bMostFound = false;
                    end
                else
                    --bMostFound = false;
                end 
                
                rSearch.bSuccess = bFound;
                table.insert(aSearchResults,rSearch);

                --if not bMostFound then
                    --bAllFound = false;
                --end

            end -- end filters
            
            -- now validate searching with and/or logic
            local aFound = {};
            for _,rSearch in pairs(aSearchResults) do
                -- or operation, and value came up false, only set once and never if we've set its been set true
                if rSearch.operation == 1 and not rSearch.bSuccess and not aFound[rSearch.type] then 
                    -- not found this yet, so, false, if we find 1, it's always true
                    aFound[rSearch.type] = 'false';
                -- or operation, found one, set true
                elseif rSearch.operation == 1 and rSearch.bSuccess then 
                    aFound[rSearch.type] = 'true';
                -- NOT operation, found one, set false, we're NOT looking for this value
                elseif rSearch.operation == 2 and rSearch.bSuccess then 
                    aFound[rSearch.type] = 'false';
                -- and logic, if any failed, we failed all
                elseif rSearch.operation == 0 and not rSearch.bSuccess then
                    aFound[rSearch.type] = 'false';
                -- if we have false already, we've failed so wont set true, otherwise true
                elseif rSearch.operation == 0 and rSearch.bSuccess and aFound[rSearch.type] and aFound[rSearch.type] ~= 'false' then
                    aFound[rSearch.type] = 'true';
                end
            end
            -- loop through searches to determine and/or found logic
            local bSuccess = true;
            for _,sSearch in pairs(aFound) do
                if sSearch == 'false' then
                    -- something failed in the search so skip it
                    bSuccess = false;
                    break;
                end
            end
            -- if filtered match, add to list
            if bSuccess then
                table.insert(aNPCList,node.getPath());
            end
        end
    end

    return UtilityManager.getSortedTable(aNPCList);
end

--[[
    Get the NPCs found from the current searched window listing of NPCs.
]]
function getNPCListFromFiltered(aWindowList)
    local aNPCs = {}
        for _, oWin in pairs(aWindowList) do
            local node = oWin.getDatabaseNode();
            table.insert(aNPCs,node);
        end
    return aNPCs;
end

--[[
    build an encounter table from the list of npcs
]]
function buildEncounterTable(aNPCs)
    local nMaxCount = #aNPCs;
    local nMaxDiceSize = 0;
    local aEncounterTable = {};
    for _, nodeNPC in pairs(aNPCs) do
        local rEntry = {};
        local nFreq = .70;
        
        local nRollSpan = 1;
        local sFreq = DB.getValue(nodeNPC,"frequency",""):lower();
        if sFreq:match("uncommon") then
            nFreq = .20;
        elseif sFreq:match("very rare") then
            nFreq = .03;
        elseif sFreq:match("rare") then
            nFreq = .06;
        elseif sFreq:match("unique") then
            nFreq = .01;
        end
        nRollSpan = math.floor(nMaxCount * nFreq);

        rEntry.node = nodeNPC;
        rEntry.nRollStart = nMaxDiceSize + 1;
        rEntry.nRollEnd = rEntry.nRollStart + nRollSpan;
        nMaxDiceSize = rEntry.nRollEnd;
        -- try and figure out dice roll for total encountered
        local sNumAppearing = DB.getValue(nodeNPC,"numberappearing","");
        local sDiceRoll = sNumAppearing:match("%(([0-9xX%+dD]+)%)");
        if sDiceRoll then
            sDiceRoll = string.gsub(sDiceRoll,"[Xx]+","*");
        else
            local sFirst,sSecond = sNumAppearing:match("(%d+)[%-dD](%d+)");
            local nFirst = tonumber(sFirst) or 1;
            local nSecond = tonumber(sSecond) or 1;
            local nDiceCount = 1;
            local nDiceSize = nSecond;
            local nMod = 0;
            if nFirst > 1 then
                nDiceSize = math.floor(nSecond/nFirst);
                nDiceCount = nFirst;
                nMod = nSecond - (nDiceSize * nDiceCount);
            end
            sDiceRoll = nDiceCount .. "d" .. nDiceSize;
            if nMod > 0 then
                sDiceRoll = sDiceRoll .. "+" .. nMod;
            end
        end
        rEntry.sEncounterSizeRoll = sDiceRoll;

        table.insert(aEncounterTable,rEntry);
    end
    
    return aEncounterTable, nMaxDiceSize;
end
--[[
    Generate a Encounter record from the filtered NPCs.
]]
function generateEncounter(aNPCs)
    local aEncounterTable,nMaxDiceSize = buildEncounterTable(aNPCs);
    -- figure out the npc encountered
    local nodeEncounteredNPC = null;
    local nRolled = math.random(nMaxDiceSize);
    local sDiceRoll = null;
    for _,rEntry in pairs(aEncounterTable) do
        if nRolled >= rEntry.nRollStart and nRolled <= rEntry.nRollEnd then
            nodeEncounteredNPC = rEntry.node;
            sDiceRoll = rEntry.sEncounterSizeRoll;
            break;
        end
    end
    -- create Encounter/Battle record
    local sName         = DB.getValue(nodeEncounteredNPC,"name","");
    local nodeEncounter = DB.createChild("battle");
    local nodeNPCList   = nodeEncounter.createChild("npclist");
    local nodeNPCEntry  = nodeNPCList.createChild();
    DB.setValue(nodeNPCEntry,"name","string",sName);
    DB.setValue(nodeNPCEntry, "link", "windowreference", 'npc', nodeEncounteredNPC.getPath());
    DB.setValue(nodeNPCEntry,"token","token",DB.getValue(nodeEncounteredNPC,"token",""));
    -- Get encounter number and set value, for now just 1;
    local nNumberEncountered = 1;
    if sDiceRoll:len() > 0 then
        nNumberEncountered = StringManager.evalDiceMathExpression(sDiceRoll);   
    end
    DB.setValue(nodeNPCEntry,"count","number",nNumberEncountered);
    local nEXPTotal = DB.getValue(nodeEncounteredNPC,"xp",0) * nNumberEncountered;

    DB.setValue(nodeEncounter,"exp","number",nEXPTotal);
    DB.setValue(nodeEncounter,"name","string","Encounter: " .. sName);
    Interface.openWindow('battle',nodeEncounter);
--    UtilityManagerADND.logDebug("manager_encountersafari.lua","generateEncounter","aEncounterTable",aEncounterTable);
end

--[[
    Generate a Random Encounter Record from filtered NPCs
]]
function generateRandomEncounter(aNPCs)
    local aEncounterTable = buildEncounterTable(aNPCs);
    local sRootMapping = LibraryData.getRootMapping("table");
    local nodeTable = DB.createChild(sRootMapping);
    local nodeTableRows = nodeTable.createChild("tablerows");
    
    DB.setValue(nodeTable, "name", "string", "Random Encounter Table (" .. #aNPCs.. ")");
    DB.setValue(nodeTable,"description","string","Randomly Generated Table with " .. #aNPCs .. " unique entries.");

    DB.setValue(nodeTable, "output", "string", 'encounter');
    DB.setValue(nodeTable, "hiderollresults", "number",1);
	for _,rEntry in pairs(aEncounterTable) do
        local sName = DB.getValue(rEntry.node,"name","");
        local nodeRow = nodeTableRows.createChild();
	    DB.setValue(nodeRow, "fromrange", "number", rEntry.nRollStart);
        DB.setValue(nodeRow, "torange", "number", rEntry.nRollEnd);
        local nodeRowResults = nodeRow.createChild("results");
        local nodeResult = nodeRowResults.createChild();
        local sDiceRoll = rEntry.sEncounterSizeRoll;
        if sDiceRoll and sDiceRoll:len() > 0 and sDiceRoll ~= "1d1" then
            DB.setValue(nodeResult,"result","string","[" .. sDiceRoll .. "x] " .. sName);
        else
            DB.setValue(nodeResult,"result","string",sName);
        end
        DB.setValue(nodeResult,"resultlink","windowreference",'npc',rEntry.node.getPath());
    end

    Interface.openWindow('table',nodeTable);
end
