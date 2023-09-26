--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

aAddMenuList = {}
menusWindow = nil
-- local funcOriginalInitialization;
function onInit()

  -- because we do not always have a sidebar we do this.
  -- store the original sidebar initialization function
  -- funcOriginalInitialization = DesktopManager.initializeSidebar;
  -- now point it to ours
  -- DesktopManager.initializeSidebar = initializeSidebar_adnd;  

  Comm.registerSlashHandler("preferences", processPreferences)
  Comm.registerSlashHandler("settings", processPreferences)
  Comm.registerSlashHandler("options", processPreferences)
end

-- -- override CoreRPG function with this because of the dropdown menu
-- function initializeSidebar_adnd()
--   local bMenuStyle = (OptionsManager.getOption("OPTIONS_MENU") == 'menus' or OptionsManager.getOption("OPTIONS_MENU") == '');
--   -- UtilityManagerADND.logDebug("manager_desktop_adnd.lua","initializeSidebar_adnd","bMenuStyle",bMenuStyle);
  
--   -- if not using drop down menus, we initialize sidebar.
--   if not bMenuStyle then 
--       funcOriginalInitialization();
--   end
-- end

--[[
  This will add a custom menu/window item to the Menu button.
  
  sRecord           The window class
  sPath             The database node associated with this window (if any)
  sToolTip          The tooltip string record, Interface.getString(sTooltip); Displayed when someone hovers over the menu selection
  sButtonCustomText The text used as the name for the menu. If doesn't exist will look for "library_recordtype_label_" .. sRecord
]]
function addMenuItem(sRecord, sPath, sToolTip, sButtonCustomText, bHostOnly)
  if (not bHostOnly) or (bHostOnly and Session.IsHost) then
    local rMenu = {}

    rMenu.sRecord = sRecord
    rMenu.sPath = sPath
    rMenu.sToolTip = sToolTip
    rMenu.sButtonCustomText = sButtonCustomText

    table.insert(aAddMenuList, rMenu)
    -- if the menusWindow is already active then
    -- we destroy the list and rebuild adding
    -- the menu just added
    if menusWindow then
      menusWindow.createMenuSelections()
    end
  end
end

function registerMenusWindow(wList)
  menusWindow = wList
end
-- if you ever need to get to menus because they are not working
-- this will let you get to the settings
function processPreferences()
  Interface.openWindow("options", "")
end
