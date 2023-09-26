-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  local node = getDatabaseNode();
  DB.addHandler(DB.getPath(node, "isidentified"), "onUpdate", updateForID);
  
  if not string.match(node.getPath(),"^charsheet") and not Session.IsHost then
    return;
  end        
  local sMode = DB.getValue(node, "powermode","");
  if (sMode == "") then
    DB.setValue(node, "powermode", "string", "standard");
  end
  updateForID();
end
      
function onClose()
  local node = getDatabaseNode();
  DB.removeHandler(DB.getPath(node, "isidentified"), "onUpdate", updateForID);
end

-- hide the weapons and powers tab subwindows if the item is no identified
function updateForID()
  local nodeRecord = getDatabaseNode();
  local bID = (Session.IsHost or LibraryData.getIDState("item", nodeRecord, true));
  contents.setVisible(bID);
end      
