-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
--UtilityManagerADND.logDebug("npc_import.lua","onInit","getDatabaseNode",getDatabaseNode());
end


function processImportText()
    local sText = importtext.getValue() or "";
    if (sText ~= "") then
      local aNPCText = {};
      local sTextClean = sText:gsub("[\r\n]+"," "); -- remove all new lines
      sTextClean = sTextClean:gsub("  "," "); -- remove all double spaces
      --sTextClean = sTextClean:gsub("^([^:]+)([:]+)","%1%2;",1); -- make sure "Name:" has ";" after it. cause it's random
UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sTextClean",sTextClean);                
      for sLine in string.gmatch(sTextClean, '([^;]+)') do
        local sCleanLine = StringManager.trim(sLine);
        table.insert(aNPCText, sCleanLine);
      end
      local nodeNPC = ManagerImportADND.createBlankNPC();

      -- find the first value in the text line and take it's value
      -- and put it in the second value of the nodeNPC
      local text_matches = {
                        {"^sz ","size"},
                        {"^mv ","speed"},
                        {"^move ","speed"},
                        {"^ac ","actext"},
                        {"^level ","hitDice","([%d%-+]+)"},
                        {"^hd ","hitDice","([%d%-+]+)"},
                        {"^level ","hdtext"},
                        {"^hd ","hdtext"},
                        {"^#at ","numberattacks"},
                        {"^dmg ","damage"},
                        {"^d ","damage"},
                        {"^sa ","specialAttacks"},
                        {"^sd ","specialDefense"},
                        {"^mr ","magicresistance"},
                        {"^int ","intelligence_text"},
                        {"^al ","alignment"},
                        {"^alignment ","alignment"},
                        {"^morale ","morale"},
                        {"^ml ","morale"},
                        };
      local number_matches = {
                        {"thaco ","thaco","(%d+)"},
                        {"thac0 ","thaco","(%d+)"},
                        -- {"^exp ","xp","(%d+)"},
                        -- {"^xpv ","xp","(%d+)"},
                        -- {"^xp ","xp","(%d+)"},
                        {"^hp ","hp","(%d+)"},
                        };
      local sDescription = "";
      local sParagraph = "";
      local sName = sTextClean:match("^([^:;]+)");
UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sName",sName);          
      for _,sLine in ipairs(aNPCText) do
UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sLine",sLine);    
        -- each line is flipped through
        local bProcessed = false;
        
        -- get text values
        for _, sFind in ipairs(text_matches) do
--UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","text_matches",sFind);            
          local sMatch = sFind[1];
          local sValue = sFind[2];
          local sFilter = sFind[3];
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sFind[1]",sFind[1]);            
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sFind[2]",sFind[2]);            
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sFind[3]",sFind[3]);            
          if (string.match(sLine:lower(),sMatch)) then
            bProcessed = true;
            ManagerImportADND.setTextValue(nodeNPC,sLine,sMatch,sValue,sFilter);
          end
        end
        -- get number values
        for _, sFind in ipairs(number_matches) do
--UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","number_matches",sFind);            
          local sMatch = sFind[1];
          local sValue = sFind[2];
          local sFilter = sFind[3];
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText-number_matches","sLine",sLine:lower());      
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText-number_matches","sMatch",sMatch);            
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText-number_matches","sValue",sValue);            
-- UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText-number_matches","sFilter",sFilter);            
          if (string.match(sLine:lower(),sMatch)) then
            bProcessed = true;
            ManagerImportADND.setNumberValue(nodeNPC,sLine,sMatch,sValue,sFilter);
          end
        end
        
        sLine = ManagerImportADND.kludgeForSaveVersusWithPeriods(sLine);
        
        if not bProcessed and string.match(sLine:lower(),"xp.? (.*)$") then
          local sEXP = string.match(sLine:lower(),"xp.? (.*)$");
          sEXP = string.match(sEXP,"([%d,]+)");
UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sEXP1",sEXP);              
          sEXP = sEXP:gsub("[,]+","");
UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","sEXP2",sEXP);              
          local nEXP = tonumber(sEXP) or 0;
UtilityManagerADND.logDebug("npc_statblock_import.lua","processImportText","nEXP",nEXP);              
          DB.setValue(nodeNPC,"xp","number",nEXP);
          bProcessed = true;
        end
      end -- for sLine
      
      ManagerImportADND.setName(nodeNPC,sName)
      ManagerImportADND.setDescription(nodeNPC,sTextClean,"text");
      --getClassLevelAsHD(nodeNPC,sTextClean);
      ManagerImportADND.setHD(nodeNPC);
      ManagerImportADND.setAC(nodeNPC);
      ManagerImportADND.setActionWeapon(nodeNPC,true);
      ManagerImportADND.setSomeDefaults(nodeNPC);
      
      setAbilityScores(nodeNPC,sTextClean);
      ManagerImportADND.importSpells(nodeNPC,sTextClean);
      importThiefSkills(nodeNPC,sTextClean);
    end -- if sText
end

function getClassLevelAsHD(nodeNPC,sText)
  local sLevel, sClass = string.match(sText:lower(),"level (%d+) ([%w]+)");
  
  if (not sLevel or not sClass) then
    sClass, sLevel = string.match(sText:lower(),"([%w]+) l(%d+)");
  end
  
  if (sLevel) then
    DB.setValue(nodeNPC,"hitdice","string", sLevel);
  end
UtilityManagerADND.logDebug("npc_statblock_import.lua","getClassLevelAsHD","sLevel",sLevel);      
UtilityManagerADND.logDebug("npc_statblock_import.lua","getClassLevelAsHD","sClass",sClass);      
end

--S 18 I 17 W 18 D 17 C 16 Ch 18
-- or 
--S 18, I 17, W 18, D 17, C 16, Ch 18
function setAbilityScores(nodeNPC,sText)
  local sAbilityScores = string.match(sText:lower(),"([%w]+ %d+[,]? [%w]+ %d+[,]? [%w]+ %d+[,]? [%w]+ %d+[,]? [%w]+ %d+[,]? [%w]+ %d+)");
  if (sAbilityScores) then
UtilityManagerADND.logDebug("---->>npc_statblock_import.lua","setAbilityScores","sAbilityScores",sAbilityScores);       
    local sStrength     = sAbilityScores:match("str (%d+)") or sAbilityScores:match("[^i]?s (%d+)");
    local sIntelligence = sAbilityScores:match("i (%d+)") or sAbilityScores:match("int (%d+)");
    local sWisdom       = sAbilityScores:match("w (%d+)") or sAbilityScores:match("wis (%d+)");
    local sDexterity    = sAbilityScores:match("d (%d+)") or sAbilityScores:match("dex (%d+)");
    local sConstitution = sAbilityScores:match("c (%d+)") or sAbilityScores:match("con (%d+)") or sAbilityScores:match("co (%d+)");
    local sCharisma     = sAbilityScores:match("ch (%d+)") or sAbilityScores:match("cha (%d+)") or sAbilityScores:match("chr (%d+)");
    local nStr = tonumber(sStrength) or 9;
    local nInt = tonumber(sIntelligence) or 9;
    local nWis = tonumber(sWisdom) or 9;
    local nDex = tonumber(sDexterity) or 9;
    local nCon = tonumber(sConstitution) or 9;
    local nCha = tonumber(sCharisma) or 9;
    
    DB.setValue(nodeNPC,"abilities.strength.base","number",nStr);
    DB.setValue(nodeNPC,"abilities.strength.score","number",nStr);
    DB.setValue(nodeNPC,"abilities.intelligence.base","number",nInt);
    DB.setValue(nodeNPC,"abilities.intelligence.score","number",nInt);
    DB.setValue(nodeNPC,"abilities.wisdom.base","number",nWis);
    DB.setValue(nodeNPC,"abilities.wisdom.score","number",nWis);
    DB.setValue(nodeNPC,"abilities.dexterity.base","number",nDex);
    DB.setValue(nodeNPC,"abilities.dexterity.score","number",nDex);
    DB.setValue(nodeNPC,"abilities.constitution.base","number",nCon);
    DB.setValue(nodeNPC,"abilities.constitution.score","number",nCon);
    DB.setValue(nodeNPC,"abilities.charisma.base","number",nCha);
    DB.setValue(nodeNPC,"abilities.charisma.score","number",nCha);
  else
    -- sometimes they just show strength in the stat block
    local sStrength     = string.match(sText:lower(),"strength (%d+)");
    local nStr = tonumber(sStrength) or 0;
    if (nStr > 0) then
      DB.setValue(nodeNPC,"abilities.strength.base","number",nStr);
      DB.setValue(nodeNPC,"abilities.strength.score","number",nStr);
    end
  end
end

local thiefSkills = {
  'pick pockets',
  'open locks',
  'find & remove traps',
  'move silently',
  'hide in shadows',
  'hear noise',
  'climb walls',
  'read languages'
};
function importThiefSkills(nodeNPC,sText)
  --Pick Pockets (55%), Open Locks (80%), Find & Remove Traps (75%), Move Silently (65%), Hide in Shadows (65%), Hear Noise (65%), Climb Walls (95%), and Read Languages (45%)
  local sTextlower    = sText:lower();
  for _, sFind in ipairs(thiefSkills) do
UtilityManagerADND.logDebug("npc_statblock_import.lua","importThiefSkills","sFind",sFind);
    local seeking = sTextlower:match(sFind .. " [%()]?(%d+)%%[%)]?");
UtilityManagerADND.logDebug("npc_statblock_import.lua","importThiefSkills","seeking",seeking);      
    if seeking then
      local nodeSkills = nodeNPC.createChild("skilllist");
      local newSkill = nodeSkills.createChild();
      local nValue = tonumber(seeking) or 0;
      DB.setValue(newSkill,"name","string",StringManager.capitalize(sFind));
      DB.setValue(newSkill,"base_check","number",nValue);
      DB.setValue(newSkill,"stat","string","percent");
    end
  end
end