-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


function onInit()
  update();
end

function undoEntry(node)
  if node then
    local nodeChar = node.getChild("....");
    local sText     = DB.getValue(node,"text","");
    local sRecord   = DB.getValue(node,"record","");
    local previous  = DB.getValue(node,"previous");
    
    ChatManager.SystemMessage('** Reverting state >' .. sText);
    
    if sRecord and sRecord ~= "" then
      -- store the nodeUndo record
      local nodeUndo = DB.findNode(DB.getPath(nodeChar,sRecord));
      if nodeUndo then
        -- if we have a previous value, revert to that
        if previous then
          local current = DB.getValue(nodeChar,sRecord);
            UtilityManagerADND.askYN(revertToPrevious, "This will revert " .. sRecord .. " from " .. current .. " to " .. previous .. ".\nAre you SURE?");
        else
          UtilityManagerADND.askYN(removeRecord, "This will remove ALL data associated with the " .. sRecord .. " record.\nAre you SURE?");
        end
      end
    end
  end
end

function revertToPrevious(response)
  if response == 'yes' then
    local node = getDatabaseNode();
    local nodeChar = node.getChild("....");
    local sRecord   = DB.getValue(node,"record","");
    local previous  = DB.getValue(node,"previous");
    
    DB.setValue(nodeChar,sRecord, type(previous),previous);
    
    setLogReverted(node);
  end
end

function removeRecord(response)
  if response == 'yes' then
    local node = getDatabaseNode();
    local nodeChar = node.getChild("....");
    local sRecord   = DB.getValue(node,"record","");
    
    local nodeUndo = DB.findNode(DB.getPath(nodeChar,sRecord));
    nodeUndo.delete();
    
    setLogReverted(node);
  end
end

function setLogReverted(node)
  -- flag as REVERTED
  local sText   = DB.getValue(node,"text","");
  DB.setValue(node,"record","string","");
  DB.setValue(node,"text","string","** REVERTED >" .. sText);
  DB.deleteChild("previous");
  update();
end

function update()
  local node = getDatabaseNode();
--UtilityManagerADND.logDebug("char_log_advancement.lua","update","node",node);  

  local sText     = DB.getValue(node,"text","");
  local sRecord   = DB.getValue(node,"record","");
  local previous  = DB.getValue(node,"previous");
  local sTooltip  = "Record: " .. sRecord
  if previous then sTooltip = sTooltip .. " Previous: " .. previous; end;

--UtilityManagerADND.logDebug("char_log_advancement.lua","update","sRecord",sRecord);    
--UtilityManagerADND.logDebug("char_log_advancement.lua","update","previous",previous);    

  if sRecord == "" then
  -- dont set tooltip for empty log entries.
    button_undo.setVisible(false);
  else
    text.setTooltipText(sTooltip);
    -- only the host can undo entries.
    if Session.IsHost then
      button_undo.setVisible(true);
    end
  end
  --text.setValue(sText);
end
