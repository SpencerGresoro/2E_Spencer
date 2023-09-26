-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--[[
  
This script is used to show a user a option to select for a empty value, like a class, race, kit/etc.

]]

local sControl = nil;
local sPath    = nil;
local sClass   = nil;
local sRecord  = nil;
function onInit()
  if control then
    sControl = control[1];
  end
  if record then
    sRecord  = record[1];
  end
  sPath    = path[1];
  sClass   = class[1];
  
  if sRecord then
    sRecord = DB.getPath(window.getDatabaseNode(),sRecord);
    DB.addHandler(sRecord,"onUpdate",updateForNode);
    updateForNode();
  else
    update();
  end
  
end

function onClose()
  if sRecord then
    DB.removeHandler(sRecord,"onUpdate",updateForNode);
  end
end

-- update check for a control style
function update()
  if sControl then
    if window and sControl and window[sControl] then
      local sControlValue = window[sControl].getValue() or "";
      if sControlValue == "" then
        setVisible(true);
      else
        setVisible(false);
      end
    end
  end
end

-- update check for a database node style
function updateForNode()
  local node = DB.findNode(sRecord);
  if node then
    local recordValue = node.getValue();
    if not record or (recordValue and type(recordValue) == "string" and recordValue == "") then
      setVisible(true);
    else
      setVisible(false);
    end
  end
end

function onClickDown()
  Interface.openWindow(sPath,sClass);
  return true;
end