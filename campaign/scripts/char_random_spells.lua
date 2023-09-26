--[[

]]

function onInit()
    local nodeChar = window.getDatabaseNode();
    -- only show button to host and not for PCs
    if not Session.IsHost or ActorManager.isPC(nodeChar) then
        setVisible(false);
    else
        setVisible(true);
    end
end

function onButtonPress()
    if Session.IsHost then
        generateRandomSpells();
    end
end

--[[

    This will generate random spells for learned slots that do not have spells

]]
function generateRandomSpells()
    local aSpells = UtilityManagerADND.getGlobalSpellList();
    if (#aSpells > 0) then
        local nodeChar = window.getDatabaseNode();
        local aCurrentLearned = getSpellsLearnedCount(nodeChar);
        local aRandomSpellList = {}
        -- arcane spells
        for i = 1, 9 do
            local nMaxSlots = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max",0);
            local nCurrentSlots = aCurrentLearned['arcane'][i] or 0;
            local nCountDiff = nMaxSlots - nCurrentSlots;
            if nCountDiff > 0 then
                local aRandomSpells = UtilityManagerADND.getRandomSpellList(aSpells, i, 'arcane', nCountDiff);
                if #aRandomSpells then
                    aRandomSpellList = UtilityManagerADND.TableConcat(aRandomSpellList, aRandomSpells)
                end
            end
        end
        -- divine spells
        for i = 1, 7 do
            local nMaxSlots = DB.getValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max",0);
            local nCurrentSlots = aCurrentLearned['divine'][i] or 0;
            local nCountDiff = nMaxSlots - nCurrentSlots;
            if nCountDiff > 0 then
                local aRandomSpells = UtilityManagerADND.getRandomSpellList(aSpells, i, 'divine', nCountDiff);
                if #aRandomSpells then
                    aRandomSpellList = UtilityManagerADND.TableConcat(aRandomSpellList,aRandomSpells);
                end
            end
        end

        if #aRandomSpellList > 0 then
            for i = 1, #aRandomSpellList do
                ManagerImportADND.addSpell(nodeChar,aRandomSpellList[i])
            end
            ChatManager.SystemMessage(DB.getValue(nodeChar,"name","") .. ": Spell list processed.");
        else
            ChatManager.SystemMessage(DB.getValue(nodeChar,"name","") .. ": No spells could be generated for availble slots.");
        end
    else
        ChatManager.SystemMessage("Empty spell list, no spells available?");
    end
end

--[[
    get the current count of spells by level by count
]]
function getSpellsLearnedCount(nodeChar)
    local aSpellsLearnedByLevel = {};
    aSpellsLearnedByLevel['arcane'] = {};
    aSpellsLearnedByLevel['divine'] = {};

    for _,nodePower in pairs(DB.getChildren(nodeChar, "powers")) do
        local sGroup = DB.getValue(nodePower,"group");
        local nLevel = DB.getValue(nodePower,"level");
        local sType  = DB.getValue(nodePower,"type"):lower();
        if sGroup and sGroup == "Spells" then
            if not aSpellsLearnedByLevel[sType] then
                aSpellsLearnedByLevel[sType] = {}
            end
            if aSpellsLearnedByLevel[sType][nLevel] then
                aSpellsLearnedByLevel[sType][nLevel] = aSpellsLearnedByLevel[sType][nLevel]+1;
            else
                aSpellsLearnedByLevel[sType][nLevel] = 1;
            end
        end
    end

    return aSpellsLearnedByLevel;
end