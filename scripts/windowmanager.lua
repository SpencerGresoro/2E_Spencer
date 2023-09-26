---
---
---


aWindowList = {}; 
aIgnoredWindowClasses = {};
aOnlyOneWindowClasses = {};

function onInit()
  -- set default window classes we dont only want singles for
  setIgnoredWindowClasses({"imagewindow","reference_manual","charsheet","select_dialog"});
  setOnlyOneWindowClasses({});
  
  -- uncomment this and everytime a window is opened
  -- the combat tracker will be moved ontop.
  --Interface.onWindowOpened = ctOnTopAlways;
  
	-- assign handlers
	Interface.onWindowOpened = onWindowOpened;
	local nMajor, nMinor = Interface.getVersion();
	if (nMajor >= 4) and (nMinor >= 3) then
		Interface.onWindowClosing = onWindowClosed;
	else
		Interface.onWindowClosed = onWindowClosed;
	end
end

-- keep the combat tracker on top all the time
-- this isn't used right now... 
-- function ctOnTopAlways(window)
  -- if Session.IsHost then
    -- if Interface.findWindow("combattracker_host", "combattracker") then
      -- Interface.findWindow("combattracker_host", "combattracker").bringToFront();
    -- end
  -- else
    -- if Interface.findWindow("combattracker_client", "combattracker") then
      -- Interface.findWindow("combattracker_client", "combattracker").bringToFront();
    -- end
  -- end
-- end

-- see if there is a collection of this type of window
function oneWindowGroupExists(sName)
  return aWindowList[sName];
end

-- let extensions tweak this if they like
function setIgnoredWindowClasses(aList)
  aIgnoredWindowClasses = {"masterindex"}; -- we always ignore this
  for _,sIgnoredClass in pairs(aList) do
    table.insert(aIgnoredWindowClasses,sIgnoredClass);
  end
end

-- let extensions tweak this if they like
function setOnlyOneWindowClasses(aList)
  aOnlyOneWindowClasses = {"weapon_proficiences_edit"}; -- we always block multiple of this one.
  for _,sOnlyOneWindowName in pairs(aList) do
    table.insert(aOnlyOneWindowClasses,sOnlyOneWindowName);
  end
end

-- any window class in "aIgnoredWindowClasses" array will not be managed 
function ignoredWindowClass(sName)
  local bIgnored = false;
  for _,sIgnoredClass in pairs(aIgnoredWindowClasses) do
    if sName == sIgnoredClass then
      bIgnored = true;
      break;
    end
  end
  return bIgnored;
end
-- any window class in "aOnlyOneWindowClasses" array will not be allowed to have more than 1 window
function onlyOneWindowClass(sName)
  local bOneWindow = false;
  for _,sOneWindowClass in pairs(aOnlyOneWindowClasses) do
    if sName == sOneWindowClass then
      bOneWindow = true;
      break;
    end
  end
  return bOneWindow;
end

-- called when window opened
function onWindowOpened(window)
  local node = window.getDatabaseNode(); 
  local sName = window.getClass(); 
  local aNodes = aWindowList[sName]; 
  local sPath = nil; 
-- UtilityManagerADND.logDebug("windowmanager.lua","onWindowOpened","window",window); 
-- UtilityManagerADND.logDebug("windowmanager.lua","onWindowOpened","node",node); 
-- UtilityManagerADND.logDebug("windowmanager.lua","onWindowOpened","sName",sName); 
-- UtilityManagerADND.logDebug("windowmanager.lua","onWindowOpened","aNodes",aNodes); 
  if node then
    aNodes = aWindowList[sName]; 
    -- ignore masterindex or anything with control pressed.
    --(not onlyOneWindowClass(sName)) or 
--    if not ignoredWindowClass(sName) and not Input.isControlPressed() then 
--      if aWindowList[sName] then
      if (aWindowList[sName] and onlyOneWindowClass(sName)) or 
         (aWindowList[sName] and not ignoredWindowClass(sName) and not Input.isControlPressed()) then
        sPath = aNodes[#aNodes]; 
        local w = Interface.findWindow(sName,sPath); 
        if w then
          sPath = node.getPath(); 
          table.insert(aNodes,sPath); 
          window.setPosition(w.getPosition());
          window.setSize(w.getSize());
          onWindowClosed(w); 
          w.close(); 
        else
          -- window is not around/opened
          table.remove(aNodes,#aNodes); 
          if #aNodes == 0 then
            aWindowList[sName] = nil; 
          end
        end
      else
        sPath = node.getPath(); 
        aNodes = {}; 
        table.insert(aNodes, sPath); 
        aWindowList[sName] = aNodes; 
      end
    --end
  end
end

-- function called when any window is closed.
function onWindowClosed(window)
  local sName = window.getClass(); 
  local aNodes = aWindowList[sName]; 
  local sPath = nil; 
  local node = window.getDatabaseNode(); 

-- UtilityManagerADND.logDebug("windowmanager.lua","onWindowClosed","node",node); 
--UtilityManagerADND.logDebug("windowmanager.lua","onWindowClosed","sName",sName); 
-- UtilityManagerADND.logDebug("windowmanager.lua","onWindowClosed","aNodes",aNodes); 

  if node then
    local sPath = node.getPath(); 
    if aNodes ~= nil then
      for i = #aNodes,1,-1 do
        if aNodes[i] == sPath then
          table.remove(aNodes,i); 
          break; 
        end
      end
      if #aNodes == 0 then
        aWindowList[sName] = nil; 
      end
    end
  end
end


-- manage actively minimized windows
aMinimizedWindows = {};
function minimizeWindow(wMin)
  if not wMin.isMinimized() then
    table.insert(aMinimizedWindows,wMin);
    wMin.minimize();
  end
end
function unMinimizeWindow(wMin)
  table.remove(aMinimizedWindows,wMin);
  Interface.toggleWindow(wMin.getClass(),wMin.getDatabaseNode());
end

