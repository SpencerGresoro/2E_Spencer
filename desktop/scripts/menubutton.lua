-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


menuListType = "menus";
nFontSize = 8;
nWindowWidth = 120;
nWindowLength= 200;
windowDropDown = nil;
modulesUpdated = true;
function onInit()
  
  -- store the menutype
  if menutype then
    menuListType = menutype[1];
    if menuListType == 'menus' then
      -- add this custom menu link (Modules list)
      MenuManager.addMenuItem("sound_context", "", "sidebar_tooltip_sound_context",Interface.getString("library_button_sound"));

      MenuManager.addMenuItem("moduleselection", "", "sidebar_tooltip_moduleselection");
      --Interface.openWindow("setup", "");
      MenuManager.addMenuItem("setup", "", "menu_setup_tooltip",Interface.getString("menu_setup_label"));
      -- export
      MenuManager.addMenuItem("export", "export", "menu_export_tooltip",Interface.getString("menu_export_label"),true);
      MenuManager.addMenuItem("reference_manual", "reference.refmanualindex", "library_button_referencemanual",Interface.getString("library_button_referencemanual"),true);

      --MenuManager.addMenuItem("/console", "", "menu_console_tooltip",Interface.getString("menu_console_label"),true);
      if LinkChecker then
        MenuManager.addMenuItem("LinkCheckWindow", "", "","Link Check");
      end
    end
  end
  
  initializeMenu();
  
  -- if the option "menu" is changed, then make sure things are initialized
  -- OptionsManager.registerCallback("OPTIONS_MENU", initializeMenu);
end

local bMenuInitialized = false;
function initializeMenu()
  -- local bMenuStyle = (OptionsManager.getOption("OPTIONS_MENU") == 'menus' or 
  --                     OptionsManager.getOption("OPTIONS_MENU") == '');
  -- revisit all these checks and extra junk when Menus are default or we can dynamically toggle 
  -- between Menu and Sidebar
  -- if bMenuStyle and not bMenuInitialized and setText then 
  if not bMenuInitialized and setText then
  bMenuInitialized = true;

    setText(Interface.getString("desktop_menu_button_" .. menuListType),
            Interface.getString("desktop_menu_button_" .. menuListType),
            Interface.getString("desktop_menu_button_" .. menuListType));
    
    windowDropDown = Interface.openWindow(menuListType .. "_dropwindow","");
    windowDropDown.registerWindowParent(self);
    minimizeMe();
    
    if menuListType == 'refmanuals' then
      Module.onModuleAdded = setBooksMenuRefresh;
      Module.onModuleUpdated = setBooksMenuRefresh;
      Module.onModuleRemoved = setBooksMenuRefresh;
    end

    populateMenuList();

    window.onMove = onMove;
  end
end


-- set the update to run next press.
function setBooksMenuRefresh()
  if not modulesUpdated then
    modulesUpdated = true;
  end
end


function setupBooksMenu()
  Interface.toggleWindow(windowDropDown.getClass(),"");
  setMyButtonPositionProperly();
  minimizeMe();
end

--[[ 
  Set the position of the pulldown relative to the button
  
  I guess since the button is in a panel it never updates its
  position because if you use getPosition it's always default
  and not current. So if the user moves it the dropdowns open...
  you guessed it, at the top left and not where the buttons
  actually are. 
  
  Soooooo, window. is used but since you're not
  pointing at the button anymore you have to hard code offsets
  so the drop down appears under the right buttons...
  
]]
local nRecordsOffset = 75;
local nBooksOffset = 150;
function setMyButtonPositionProperly()
  local nOffsetX = 0;
  local nOffsetY = 0;
  local x,y = window.getPosition();
  local w,h = window.getSize();
  if menuListType == 'records' then
    nOffsetX = nRecordsOffset;
  elseif menuListType == 'refmanuals' then
    nOffsetX = nBooksOffset;
  end
  local nXPos = (x+20+nOffsetX);
  local nYPos = ((y+h-5)+nOffsetY);

  windowDropDown.setPosition(nXPos,nYPos);
end

-- minimize the dropdown for this button
function minimizeMe()
  windowDropDown.minimize();
  
  -- If we dont do this FGU keeps the clickable 
  -- space of the menu, even when not visible
  windowDropDown.setSize(0,0);
  --
end

-- when window is moved, we update locations.
function onMove(source)
  local windowList = windowDropDown[menuListType]
  setMyButtonPositionProperly();
end

--[[
    This is run when a new module is loaded/activated.
]]
function updateBookListings()
  createRefManualSelections();
  windowDropDown[menuListType].applySort(true);
  setDropDownLayout();  
end

--[[
  This builds a list of menu selections from the
  loaded modules that have ref-manualls with more than 0 chapters.
]]
function createRefManualSelections()
--library
  local listWindow = windowDropDown[menuListType];
  
  if not listWindow.isEmpty() then
    listWindow.closeAll();
  end
  
  local sLongestName = "";
  for _, sName in ipairs(Module.getModules()) do
--UtilityManagerADND.logDebug("menulist.lua","createRefManualSelections","sName",sName);  
    local rInfo = Module.getModuleInfo(sName);
    if rInfo.loaded then
      local nodeRef = DB.findNode("reference.refmanualindex@" .. rInfo.name);
      if nodeRef then
        local nChapterCount = DB.getChildCount(nodeRef,"chapters");
        if nChapterCount > 0 then
          -- remove the leading AD&D 2e
          local sButtonText = StringManager.trim(rInfo.name:gsub("AD&D %d+[eE]",""));
          if sButtonText:len() > sLongestName:len() then
            sLongestName = sButtonText;
          end
          addMenuItem('reference_manual', "reference.refmanualindex@" .. rInfo.name, rInfo.name, nil, sButtonText);
        else
--UtilityManagerADND.logDebug("menulist.lua","createRefManualSelections","** NOT ADDING to menulist :",sName);          
        end
      else
--UtilityManagerADND.logDebug("menulist.lua","createRefManualSelections","** ERROR nodeRef",nodeRef);                      
--UtilityManagerADND.logDebug("menulist.lua","createRefManualSelections","reference.refmanualindex@","reference.refmanualindex@" .. rInfo.name);                      
      end
    else
--UtilityManagerADND.logDebug("menulist.lua","createRefManualSelections","** NOT MODULE LOADED :",sName);              
    end
  end
  -- try to get the width right here... I wish 
  -- I had a api call to get font size pixel width instead.
  if sLongestName:len() > 15 then
    nWindowWidth = math.floor(sLongestName:len() * nFontSize);
  else
    nWindowWidth = 100;
  end
end


--[[ 
  Insert this into menu lists
  
  This is the modules load/unload/selection window
]]
function createMenuSelections()
  local listWindow = windowDropDown[menuListType];
  if not listWindow.isEmpty() then
    listWindow.closeAll();
  end

  if Session.IsHost then
    for _,rRecords in ipairs(Desktop.aCoreDesktopStack["host"]) do
      addMenuItem(rRecords.class,rRecords.path or rRecords.class, rRecords.tooltipres);
    end
  else
    for _,rRecords in ipairs(Desktop.aCoreDesktopStack["client"]) do
      addMenuItem(rRecords.class,rRecords.path or rRecords.class, rRecords.tooltipres);
    end
  end
  for _,rRecords in ipairs(Desktop.aCoreDesktopDockV4["live"]) do
    -- UtilityManagerADND.logDebug("menulist.lua","populateMenuList: Adding aCoreDesktopDockV4 menu--->","rRecords",rRecords);       
    addMenuItem(rRecords.class,rRecords.path or rRecords.class, rRecords.tooltipres);
  end
      
  if MenuManager and MenuManager.aAddMenuList and #MenuManager.aAddMenuList > 0 then
    for _, rMenu in ipairs(MenuManager.aAddMenuList) do
UtilityManagerADND.logDebug("menulist.lua populateMenuList: Adding custom menu--->  rMenu",rMenu);               
      addMenuItem(rMenu.sRecord,rMenu.sPath,rMenu.sToolTip,true,rMenu.sButtonCustomText);
    end
  end
end

--[[
    Populate the drop down list with all the record and config/opt options.
]]
local bPopulatedMenus = false;
function populateMenuList()
  if not bPopulatedMenus then
    --[[ POPULATE THE RECORDS MENUS ]]
    if menuListType == "records" then
      for _,sRecordType in pairs(LibraryData.getRecordTypes()) do
        if not LibraryData.isHidden(sRecordType) then
          addMenuItem(sRecordType);
          --[[ for whatever reason soundset is always hidden (I suspect its load ordering). ]]
        elseif LibraryData.isHidden(sRecordType) and sRecordType == 'soundset' then
          addMenuItem(sRecordType);
        end
      end
    end
    -- [[ POPULATE THE CONFIG/OPT MENUS ]]
    if menuListType == "menus" then 
      MenuManager.registerMenusWindow(self);
      createMenuSelections();
    end
    
    --[[ POPULATE THE BOOOKS MENU (Ref-Manuals for all modules) ]]
    if menuListType == "refmanuals" then
      createRefManualSelections();
    end
    
    --[[ Sort the windowlist, if we dont the last one entered is never sorted properly ]]
    windowDropDown[menuListType].applySort(true);
    
    setDropDownLayout();
  end
  bPopulatedMenus = true;
end

-- add the records of each menu list to the windowlist
function addMenuItem(sRecord, sPath, sToolTip, bInsert, sButtonCustomText)
  -- UtilityManagerADND.logDebug("menubutton.lua","addMenuItem","sRecord",sRecord)
  -- UtilityManagerADND.logDebug("menubutton.lua","addMenuItem","sPath",sPath)
  -- UtilityManagerADND.logDebug("menubutton.lua","addMenuItem","sToolTip",sToolTip)
  -- UtilityManagerADND.logDebug("menubutton.lua","addMenuItem","bInsert",bInsert)
  -- UtilityManagerADND.logDebug("menubutton.lua","addMenuItem","sButtonCustomText",sButtonCustomText)
  if sRecord and sRecord ~= "" then
    local listWindow = windowDropDown[menuListType].createWindowWithClass("menu_record_item");
    if listWindow then
      local sButtonText = Interface.getString("library_recordtype_label_" .. sRecord);
      -- This forces the menu option to use "Assets" if in FGU since that is the new name
      if sRecord == 'tokenbag' then
          sButtonText = Interface.getString("assetview_window_title");
      end
      if sButtonCustomText then
        sButtonText = sButtonCustomText;
      end
      listWindow.name.setValue(sButtonText);
      if type(listWindow.record_name) == "buttoncontrol" then
        listWindow.record_name.setText(sButtonText,sButtonText,sButtonText);
      else
        if sButtonText and sButtonText ~= "" then
          listWindow.record_name.setValue(sButtonText);
        else
          listWindow.record_name.setValue(sRecord);
        end
      end
      
      listWindow.record.setValue(sRecord);
      if sToolTip then
        if Interface.getString(sToolTip) ~= "" then
          listWindow.record_name.setTooltipText(Interface.getString(sToolTip));
        else
          listWindow.record_name.setTooltipText(sToolTip);
        end
      end
      if sPath and sPath ~= "" then
        listWindow.path.setValue(sPath);
      elseif bInsert then
        listWindow.insert.setValue(1);
      end
    else
      UtilityManagerADND.logDebug("menulist.lua addMenuItem FAILED: listWindow",listWindow,"sRecord",sRecord);         
    end
  end
end

-- returns the "length" of the window drop down/menu list.
function getWindowLengthValue()
  local _SIZE_START_SCROLL = 20;
  local windowList = windowDropDown[menuListType]
  local nWindowCount = windowList.getWindowCount();
  if nWindowCount < 1 then nWindowCount = 1; end;
  local nWindowLength = ((nWindowCount*20)+15);

  -- we allow a scroll bar after windowlist is > _SIZE_START_SCROLL
  if nWindowCount > _SIZE_START_SCROLL then
    -- each record is 20 pixel high.
    nWindowLength = ((_SIZE_START_SCROLL+1)*20);
  end  
  return nWindowLength;
end

--[[ 
  Setup window length based on the number of items
  in the windowlist.
]]
function setDropDownLayout()
  nWindowLength = getWindowLengthValue();
  windowDropDown.setSize(nWindowWidth,nWindowLength);
  
  -- I added this here as well because clients (not host) sometimes
  -- would show a phantom "minimized" icon. 
  setupBooksMenu();
  -- ^^^ remove if they give us a nil minimize token option.
end
--
-- open menu when button clicked
function onClickDown()
  local bMinimized = windowDropDown.isMinimized();
  if not bMinimized then
    minimizeMe();
  else
  if menuListType == 'refmanuals' then
    if modulesUpdated then
      updateBookListings();
      modulesUpdated = false;
    end
  end
    -- Adjust position to match where button is
    -- make sure to set position AFTER you toggle.
    Interface.toggleWindow(windowDropDown.getClass(),"");
    setMyButtonPositionProperly();
    
    -- for some reason in FGU we have to setSize() after a toggleWindow.
    windowDropDown.setSize(nWindowWidth,nWindowLength);
    --
  end
end

-- on hover over button
function onHover(bOver)
  if bOver then
    setColor("DAA520");
    window.hideOtherButtonMenus(menuListType);
  else
    setColor("");
  end
end       