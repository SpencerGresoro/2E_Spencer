---
--
--
--
---

OOB_MSGTYPE_APPLYUNDERLAY = "applyauraunderlay";
function onInit()
  OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYUNDERLAY, handleApplyUnderlay);
  -- override this
  -- CombatManager.handleFactionDropOnImage = handleFactionDropOnImage;
  -- capture hover/click/target updates and tweak the CT/tokens.
  Token.onHover = onHoverADND
  Token.onClickDown = onClickDownADND;
  -- Token.onDoubleClick = onDoubleClickADND;
  Token.onTargetUpdate = onTargetUpdateADND
  Token.onAdd = onAddADND
  -- Token.onDelete = onTokenDeleteADND;
  --Token.onContainerChanged = onContainerChangedADND;
  
  --CombatManager.addCombatantFieldChangeHandler("tokenrefnode", "onUpdate", onUpdateToken);
  ---
  OptionsManager.registerOption2("COMBAT_SHOW_RIP", false, "option_header_combat", "option_label_RIP", "option_entry_cycler", 
      { labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
  OptionsManager.registerOption2("COMBAT_SHOW_RIP_DM", false, "option_header_combat", "option_label_RIP_DM", "option_entry_cycler", 
      { labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
  
  CombatManager.addCombatantFieldChangeHandler("wounds", "onUpdate", updateHealth);
  --CombatManager.addCombatantFieldChangeHandler("tokenrefid", "onUpdate", updateHealth);
  CombatManager.addCombatantFieldChangeHandler("tokenrefid", "onUpdate", onUpdateToken);
  
  DB.addHandler("options.COMBAT_SHOW_RIP", "onUpdate", TokenManager.onOptionChanged);
  DB.addHandler("options.COMBAT_SHOW_RIP_DM", "onUpdate", TokenManager.onOptionChanged);
  
  -- for when options are toggled in settings.
  DB.addHandler("options.COMBAT_SHOW_RIP", "onUpdate", updateCTEntries);
  DB.addHandler("options.COMBAT_SHOW_RIP_DM", "onUpdate", updateCTEntries);  
  
  -- Narrowed down the handler as best I could
  DB.addHandler("combattracker.list.*.effects.*.label", "onUpdate", updateAuras);
  DB.addHandler("combattracker.list.*.effects.*.isactive", "onUpdate", updateAuras);
  DB.addHandler("combattracker.list.*.effects", "onChildDeleted", updateAuras);
end

-- we do this to delay it till things are loaded
-- otherwise cold start map tokens come back nil, for death indicators
function onTabletopInit()
  Interface.onWindowOpened = onWindowOpened; 
  updateCTEntries();
end

-- this will mark the clicked on token in the CT with arrows/selection.
function onClickDownADND( target, button, image ) 
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","onClickDownADND","target",target);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","onClickDownADND","button",button);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","onClickDownADND","image",image);
  -- if host and not pressing control (targeting)
  
-- kluge to make sure people can at least click the thing to get auras.
--processAuraChange(CombatManager.getCTFromToken(target),target);
--
  
  if not Input.isControlPressed() then
    -- click left mouse on token
    if button == 1 then
      local ctwnd = nil;
      local windowPath = nil
      local bOldKludge = false;
      if Session.IsHost then
        ctwnd = Interface.findWindow("combattracker_host", "combattracker");
        if ctwnd then windowPath = ctwnd.combatants.subwindow.list; end;
      else
        ctwnd = Interface.findWindow("combattracker_client", "combattracker");
        if ctwnd then windowPath = ctwnd.list; bOldKludge = true; end;
      end
      if ctwnd then
        local nodeCT = CombatManager.getCTFromToken(target);
        if nodeCT then
          local sNodeID = nodeCT.getPath();
          for k,v in pairs(windowPath.getWindows(true)) do
            local node = v.getDatabaseNode();
            local sFaction = v.friendfoe.getStringValue();
            if node.getPath() == sNodeID then 
              windowPath.scrollToWindow(v);
              if bOldKludge then
                -- v.ct_select_right.setVisible(true);
                v.ct_select_left.setVisible(true);
              else
                v.cta_select_right.setVisible(true);
              end
              --v.ct_select_left.setVisible(true);
            else
              if bOldKludge then
                -- v.ct_select_right.setVisible(false);
                v.ct_select_left.setVisible(false);
              else
              -- the sNodeID did not match, clean up select indicator.
              v.cta_select_right.setVisible(false);
              --v.ct_select_left.setVisible(false);
              end
            end
          end
          
          --
          -- this bit makes sure we select the token with initiative if they are piled up.
          --
          -- if Session.IsHost and not target.isActive() then
            -- local posOriginalToken = target.getPosition();
            -- image.clearSelectedTokens();
            -- for _, oToken in pairs(image.getTokens()) do
              -- -- otoken is ontop of selected target
              -- if oToken.getPosition() == posOriginalToken then
                -- local nodeCT = CombatManager.getCTFromToken(oToken);
                -- if nodeCT then
                  -- local bActive = (DB.getValue(nodeCT, "active", 0) == 1);
                  -- if bActive then
                    -- image.selectToken(oToken, true);
                  -- else
                    -- CombatManager.replaceCombatantToken(nodeCT,nil);
                  -- end
                -- end
              -- end
            -- end
            -- return true;
          -- end
          --
          
        end -- nodeCT entry didn't exist for token on map
      end
    end
  end
end

--[[ 
Select a specific token in a pile of tokens.

Used to push a token to the top of a pile and set as selected.

This causes various other issues, hopefully they'll just add
some decent API calls to do this natively in FGU...

]]--
function selectTokenInPile(tokenToSelect)
  if Session.IsHost then
    local imageControl = ImageManager.getImageControl(tokenToSelect, true);
    if imageControl then
      local positionTarget = tokenToSelect.getPosition();
      imageControl.clearSelectedTokens();
      for _, oToken in pairs(imageControl.getTokens()) do
        -- otoken is ontop of selected target
        if oToken.getPosition() == positionTarget then
          local nodeCT = CombatManager.getCTFromToken(oToken);
          if nodeCT then
            if tokenToSelect == oToken then
              imageControl.selectToken(oToken, true);
            else
              CombatManager.replaceCombatantToken(nodeCT,nil);
            end
          end
        end
      end
      return true;
    end
  end
  return false;
end

-- test function to flip through all tokens on map
-- function findAllTokensAndGetDistance(tokenSource)
  -- local imageControl = ImageManager.getImageControl(tokenSource, true);
  
  -- -- test effects grabber
  -- local nodeSourceCT = CombatManager.getCTFromToken(tokenSource);
  -- EffectManagerADND.getEffectsList(nodeSourceCT);
  -- --
  
  -- -- test distance checker
  -- for _, oToken in pairs(imageControl.getTokens()) do
    -- local nDistance, bValid = getTokenDistanceBetween(tokenSource,oToken)
  -- end
  -- --
-- end


--[[

  This will get the distance BETWEEN these 2 tokens. 
  
  getTokenDistance(source,target);

]]
function getTokenDistanceBetween(tokenSource,tokenTarget)
  local bValidDistance = true;
  local nDistanceBetween = 0;
  
	local imageSource = ImageManager.getImageControl(tokenSource);
	local imageTarget = ImageManager.getImageControl(tokenTarget);
  local nSourceID = tokenSource.getId();
  local nTargetID = tokenTarget.getId();

  -- UtilityManagerADND.logDebug("manager_effect_adnd.lua","getTokenDistanceBetween","imageSource",imageSource)
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getTokenDistanceBetween","imageTarget",imageTarget)
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getTokenDistanceBetween","nSourceID",nSourceID)
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getTokenDistanceBetween","nTargetID",nTargetID)

  if nSourceID ~= nTargetID and imageSource and imageTarget and 
      imageSource == imageTarget then
    local nDistance = nil;
    local nMapUnitSize = 10;

    local xSource,ySource = tokenSource.getPosition();
    local xTarget,yTarget = tokenTarget.getPosition();
    
    local nGridSize = imageSource.getGridSize();
    local xOffset,yOffset = imageSource.getGridOffset();
    
    local xGridSource = (xSource + xOffset) / nGridSize;
    local yGridSource = (ySource + yOffset) / nGridSize;

    local xGridTarget = (xTarget + xOffset) / nGridSize;
    local yGridTarget = (yTarget + yOffset) / nGridSize;

    local nX = math.abs(xGridTarget - xGridSource);
    local nY = math.abs(yGridTarget - yGridSource);

    nDistance = math.sqrt((nX * nX) + (nY * nY));	
    nMapUnitSize = imageSource.getDistanceBaseUnits() or 10;
    
    -- UtilityManagerADND.logDebug("manager_effect_adnd","getTokenDistanceBetween","nDistance",nDistance)
    -- UtilityManagerADND.logDebug("manager_effect_adnd","getTokenDistanceBetween","nMapUnitSize",nMapUnitSize)


      --- end FGC required block
    -- else 
      -- nDistance = Token.getDistanceBetween(tokenSource, tokenTarget);
      -- nMapUnitSize = imageSource.getDistanceBaseUnits() or 10;
    -- end
  

    local nodeSourceCT = CombatManager.getCTFromToken(tokenSource);
    local nSourceSpace = DB.getValue(nodeSourceCT,"space",nMapUnitSize)/nMapUnitSize;
    local nSourceSize  = ((nSourceSpace)*nMapUnitSize)/(2*nSourceSpace);

    local nodeTargetCT = CombatManager.getCTFromToken(tokenTarget);
    local nTargetSpace = DB.getValue(nodeTargetCT,"space",nMapUnitSize)/nMapUnitSize;
    local nTargetSize  = ((nTargetSpace)*nMapUnitSize)/(2*nTargetSpace);
    
    --   nDistanceBetween = math.floor((nDistance) - (nSourceSize + nTargetSize));
    nDistanceBetween = math.floor((nMapUnitSize * nDistance) - (nSourceSize + nTargetSize));
    -- end
    
    -- UtilityManagerADND.logDebug("manager_token_adnd.lua","getTokenDistanceBetween","nDistanceBetween===============>",nDistanceBetween);
  else
    -- target and source not in same image
    -- or source == target
    -- or no grid on map
    bValidDistance = false;
  end
  
  -- UtilityManagerADND.logDebug("manager_effect_adnd","getTokenDistanceBetween","nDistanceBetween",nDistanceBetween)

  return nDistanceBetween,bValidDistance;
end


--[[
  This is a debug function, to see what tokens are in the area of the initial clicked one.
]]
-- function findTokensTouchingToken(tokenSelected)
  -- if Session.IsHost then
    -- local imageControl = ImageManager.getImageControl(tokenSelected, true);
    -- if imageControl then
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","imageControl.getGridSize()",imageControl.getGridSize());

-- local nodeSource = CombatManager.getCTFromToken(tokenSelected);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeSource:",DB.getValue(nodeSource,"name",""));    
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","tokenSelected",tokenSelected);

      -- local pX,pY = tokenSelected.getPosition();
      -- local nSizeX,nSizeY = tokenSelected.getSize()
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeSource pX1",pX,"pY",pY);      
      -- pX = pX-math.floor(nSizeX/4);
      -- pY = pY-math.floor(nSizeY/4);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeSource pX2",pX,"pY",pY);      
      -- local nXSourceSpan = pX+math.floor(nSizeX/4);
      -- local nYSourceSpan = pY+math.floor(nSizeY/4);
      -- for _, oToken in pairs(imageControl.getTokens()) do
        -- if tokenSelected ~= oToken then
          -- local pXX,pYY = oToken.getPosition();
          -- local nSizeXX,nSizeYY = oToken.getSize()
          -- pXX = pXX-math.floor(nSizeXX/4);
          -- pYY = pYY-math.floor(nSizeYY/4);
          -- local nXSpan = pXX+math.floor(nSizeXX/4);
          -- local nYSpan = pYY+math.floor(nSizeYY/4);
          
-- local nodeCT = CombatManager.getCTFromToken(oToken);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeCT:",DB.getValue(nodeCT,"name",""));
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","oToken",oToken);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","-->tokenSelected",tokenSelected);

-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeSource pX3",pX,"pY",pY);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","oToken    pXX ",pXX,"pYY",pYY);

-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeSource nSizeX",nSizeX,"nSizeY",nSizeY);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","oToken    nSizeXX",nSizeXX,"nSizeYY",nSizeYY);

-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","nodeSource nXSourceSpan",nXSourceSpan,"nYSourceSpan",nYSourceSpan);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","oToken           nXSpan",nXSpan,"nYSpan",nYSpan);

-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken",'((pXX >= pX and pXX <= nXSourceSpan) or (nXSpan >= pX and nXSpan <= nXSourceSpan)) and ((pYY >= pY and pYY <= nYSourceSpan) or (nYSpan >= pY and nYSpan <= nYSourceSpan))');
          -- -- determine which tokens cross/touch tokenSelected token
          -- if ((pXX >= pX and pXX <= nXSourceSpan) or (nXSpan >= pX and nXSpan <= nXSourceSpan)) and 
             -- ((pYY >= pY and pYY <= nYSourceSpan) or (nYSpan >= pY and nYSpan <= nYSourceSpan)) then
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","findTokensTouchingToken","TOUCHING",DB.getValue(nodeSource,"name","")," with ",DB.getValue(nodeCT,"name",""));
          -- end
        -- end
      -- end
    -- end
  -- end
-- end

-- when token targeted, mark with widget (crosshairs)
function onTargetUpdateADND( source, target, targeted ) 
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","onTargetUpdateADND","source",source);
  local ctwnd = nil;
  if Session.IsHost then
    ctwnd = Interface.findWindow("combattracker_host", "combattracker");
  else
    ctwnd = Interface.findWindow("combattracker_client", "combattracker");
  end
  if ctwnd then
    --local nodeSource = CombatManager.getCTFromToken(source);
    local nodeCT = CombatManager.getCTFromToken(target);
    if nodeCT then
      setTokenTargetedIndicator(nodeCT,targeted);
    end
  end
end
-- set token targeted indicator
function setTokenTargetedIndicator(nodeCT,bState)
--UtilityManagerADND.logDebug("manager_token_adnd.lua","setTokenTargetedIndicator","nodeCT",nodeCT);
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  if (tokenCT) then
    local widgetTargeted = tokenCT.findWidget("tokenTargetedIndicator");
    if not widgetTargeted and bState then
      local nWidth, nHeight = tokenCT.getSize();
      --local nScale = tokenCT.getScale();
      local sTokenName = "token_is_targeted";
      widgetTargeted = tokenCT.addBitmapWidget(sTokenName);
      widgetTargeted.setBitmap(sTokenName);
      widgetTargeted.setName("tokenTargetedIndicator");
      local nDU = GameSystem.getDistanceUnitsPerGrid();
      local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU)*100;
      local nSizeValue = nSpace-math.ceil(nSpace*.2);
      widgetTargeted.setSize(nSizeValue,nSizeValue);
      widgetTargeted.setPosition("center", 0, 0);
      widgetTargeted.setVisible(true);
    elseif widgetTargeted and bState then
      widgetTargeted.setVisible(true);
    elseif widgetTargeted and not bState then
      widgetTargeted.destroy();
    end
  end
end

-- when hovering over a token, highlight the entry in the CT
function onHoverADND(tokenMap,bState)
--UtilityManagerADND.logDebug("manager_token_adnd.lua","onTargetUpdateADND","tokenMap",tokenMap);
  local ctwnd = nil;
  local windowPath = nil;
  local bHost = Session.IsHost;
  
  if bHost then
    ctwnd = Interface.findWindow("combattracker_host", "combattracker");
    if ctwnd then windowPath = ctwnd.combatants.subwindow.list; end;
  else
    ctwnd = Interface.findWindow("combattracker_client", "combattracker");
    if ctwnd then windowPath = ctwnd.list; end;
  end
  if ctwnd then
    local nodeCT = CombatManager.getCTFromToken(tokenMap);
    if nodeCT then
      local sNodeID = nodeCT.getPath();
       for k,v in pairs(windowPath.getWindows(true)) do
        local node = v.getDatabaseNode();
        local bActive = (DB.getValue(node, "active", 0) == 1)
        local sFaction = v.friendfoe.getStringValue();
        if node.getPath() == sNodeID then 
          -- disabling scrollToWindow() as it causes a lot of confusiong when trying to select
          -- or find when moving across map TO the CT. --celestian
          --windowPath.scrollToWindow(v);
          local sFrame, sColor;
          if bHost then
            sFrame, sColor = v.getBackground(node,bState);
          else
          -- kludge to deal with different CT on client for now
            sFrame = getCTFrameType(sFaction,bState,bActive); 
            if (bState and bActive) then
              sFrame = 'field-initiative';
            end
          end
          v.setFrame(sFrame);
          v.setBackColor(sColor);
        end
      end
    end
  end
end
-- return frame for selected or unselected(bState=FALSE) and "active" if token has initiative currently
function getCTFrameType(sFaction,bState,bActive)
--UtilityManagerADND.logDebug("manager_token_adnd.lua","getCTFrameType","sFaction",sFaction);
  local sFrame = 'field-initiative';
  
  if Session.IsHost then
  else -- this is a kludge until I get the client CT, keep old one working
    sFrame = 'ctentrybox';
    if bState or bActive then
      if sFaction == "friend" then
        sFrame = "ctentrybox_friend_active";
      elseif sFaction == "neutral" then
        sFrame = "ctentrybox_neutral_active";
      elseif sFaction == "foe" then
        sFrame = "ctentrybox_foe_active";
      else
        sFrame = "ctentrybox_active";
      end
    else
      if sFaction == "friend" then
        sFrame = "ctentrybox_friend";
      elseif sFaction == "neutral" then
        sFrame = "ctentrybox_neutral";
      elseif sFaction == "foe" then
        sFrame = "ctentrybox_foe";
      else
        sFrame = "ctentrybox";
      end
    end
  end

  return sFrame;
end

-- -- alt click to highlight name in CT for this creature.
-- function onClickReleaseADND(tokenMap, vImage)
  -- if Session.IsHost and Input.isAltPressed() then
    -- local ctwnd = Interface.findWindow("combattracker_host", "combattracker");
    -- if ctwnd then
      -- local nodeCT = CombatManager.getCTFromToken(tokenMap);
      -- local sNodeID = nodeCT.getPath();
       -- for k,v in pairs(ctwnd.list.getWindows()) do
        -- if v.getDatabaseNode().getPath() == sNodeID then 
          -- ctwnd.list.scrollToWindow(v);
          -- v.name.setFocus();
          -- v.setFrame("ctentrybox_foe_active");
        -- end
      -- end
    -- end
  -- else
   -- -- do nothing otherwise?
  -- end

-- end

-- disabled, we no longer use the ct.visible (removed situational awareness code)
--[[
  We need to add this because we altered getCombatants to only return the ones
  that are "ct.visible == 1". Because of that double clicking won't load the ones that
  are NOT ct.visible == 1.
]]
-- function onDoubleClickADND(tokenMap, vImage)
--   local tokenName = tokenMap.getName();
--   -- local nodeCT = CombatManagerADND.getCTFromTokenUnfiltered(tokenMap);
--   local nodeCT = CombatManager.getCTFromToken(tokenMap);
--   if nodeCT then
--     -- local bCTVisible = (DB.getValue(node,"ct.visible",1) == 1);

--     -- we only do this if the CT isn't visible since the default
--     -- behavior will not open the record
--     -- if not bCTVisible then

--     local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
--     if sClass == "charsheet" then
--       if DB.isOwner(sRecord) then
--         Interface.openWindow(sClass, sRecord);
--       end
--     else
--       if Session.IsHost or (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
--         Interface.openWindow("npc", nodeCT);
--       end
--     end
--     return true;
--   end
--   return false;
    
--   -- end

-- --local nodeNPC = DB.findNode(tokenName);
-- --    if (tokeName ~= "" and nodeNPC) then
--         -- local sClass = "npc";
--         -- local sName = DB.getValue(nodeNPC,"name","");
--         -- CombatManager.addNPC(sClass, nodeNPC, sName);    
-- --        spawnNPC(nodeNPC,tokenMap);
-- --    else
--         -- local nodeCT = CombatManager.getCTFromToken(tokenMap);
--         -- if nodeCT then
--             -- local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
--             -- if sClass == "charsheet" then
--                 -- if DB.isOwner(sRecord) then
--                     -- Interface.openWindow(sClass, sRecord);
--                     -- vImage.clearSelectedTokens();
--                 -- end
--             -- else
--                 -- if Session.IsHost or (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
--                     -- Interface.openWindow("npc", nodeCT);
--                     -- vImage.clearSelectedTokens();
--                 -- end
--             -- end
--         -- end
-- --    end    

--   -- -- alt-double click to bring up sheet and highlight name in CT.
--   -- if Session.IsHost and Input.isAltPressed() then
--     -- local ctwnd = Interface.findWindow("combattracker_host", "combattracker");
-- -- --UtilityManagerADND.logDebug("manager_token_adnd.lua","onDoubleClickADND","ctwnd",ctwnd);
--     -- if ctwnd then
--       -- local nodeCT = CombatManager.getCTFromToken(tokenMap);
--       -- local sNodeID = nodeCT.getPath();
--        -- for k,v in pairs(ctwnd.list.getWindows()) do
--         -- if v.getDatabaseNode().getPath() == sNodeID then 
--           -- ctwnd.list.scrollToWindow(v);
--           -- v.name.setFocus();
--         -- end
--       -- end
--     -- end
--   -- else
--     -- TokenManager.onDoubleClick(tokenMap, vImage);
--   -- end

-- end

-- spawn the npc passed using token as location
-- function spawnNPC(nodeNPC,tokenMap)
--     if nodeNPC then
--       local xpos, ypos = tokenMap.getPosition();
--       local sName = DB.getValue(nodeNPC,"name","");
--       local sClass = "npc";
--       local sRecord = tokenMap.getContainerNode().getNodeName();
      
--       -- local aPlacement = {};
--       -- for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
--           -- local rPlacement = {};
--           -- local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
--           -- rPlacement.imagelink = sRecord;
--           -- rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
--           -- rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
--           -- table.insert(aPlacement, rPlacement);
--       -- end
        
--       --local nCount = DB.getValue(vNPCItem, "count", 1);
--       local nCount = 1;
--       for i = 1, nCount do
--         local nodeEntry = CombatManager.addNPC(sClass, nodeNPC, sName);
--         if nodeEntry then
--           -- local sFaction = DB.getValue(vNPCItem, "faction", "");
--           -- if sFaction ~= "" then
--           -- DB.setValue(nodeEntry, "friendfoe", "string", sFaction);
--           -- end
--           local sToken = tokenMap.getPrototype();
--				sToken = UtilityManager.resolveDisplayToken(sToken, sName);
--           if sToken ~= "" then
--             DB.setValue(nodeEntry, "token", "token", sToken);
            
--             TokenManager.setDragTokenUnits(DB.getValue(nodeEntry, "space"));
--             local tokenAdded = Token.addToken(sRecord, sToken, xpos, ypos);
--             TokenManager.endDragTokenWithUnits(nodeEntry);
--             if tokenAdded then
--               TokenManager.linkToken(nodeEntry, tokenAdded);
--             end
--           end
--         else
--           ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail") .. " (" .. sName .. ")");
--         end
--       end
--     tokenMap.delete();
--     else
--       ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail2") .. " (" .. sName .. ")");
--     end
-- end

-- remove "selected" > Entry < indicator from combat tracker combatants list
function resetIndicators(nodeChar, bLong)
--UtilityManagerADND.logDebug("manager_token_adnd.lua","resetIndicators","nodeChar",nodeChar);
  local ctwnd = nil;
  local windowPath = nil;
  local bOldKludge = false;
  if Session.IsHost then
    ctwnd = Interface.findWindow("combattracker_host", "combattracker");
    if ctwnd then windowPath = ctwnd.combatants.subwindow.list; end;
  else
    ctwnd = Interface.findWindow("combattracker_client", "combattracker");
    if ctwnd then windowPath = ctwnd.list; bOldKludge = true; end;
  end
  if ctwnd then
    local nodeCT = CombatManager.getCTFromNode(nodeChar);
    if nodeCT then
      for k,v in pairs(windowPath.getWindows(true)) do
        local node = v.getDatabaseNode();
        if bOldKludge then
          v.ct_select_left.setVisible(false);
          -- v.ct_select_right.setVisible(false);
        else
          v.cta_select_right.setVisible(false);
        --v.ct_select_left.setVisible(false);
        end
      end
    end
  end
end

-- The first time the map is loaded after a previous session it's possible
-- that tokens will be unmarked "targeted" if multiple CT entries target the
-- same entry. This could be coded around but seems to edge case to bother with? 
-- Would need to check the "active node" targets and ignore clearing those while
-- looping through EVERYONE elses targets.
-- If someone complains I'll do it.
-- celestian
-- set targets tokens indicators if Active, or hides if not active
function setTargetsForActive(nodeCT,bForced)
  local bActive = (DB.getValue(nodeCT, "active", 0) == 1)
  if bForced then bActive = bForced; end;
  for _, nodeTarget in pairs(DB.getChildren(nodeCT,"targets")) do
    local sNodeToken = DB.getValue(nodeTarget,"noderef");
    if sNodeToken then 
      local nodeToken = DB.findNode(sNodeToken);
      setTokenTargetedIndicator(nodeToken,bActive)
    end
  end -- for
end
-- clear all widget targets on tokens
function clearAllTargetsWidgets()
  for _,node in pairs(CombatManager.getCombatantNodes()) do
    setTargetsForActive(node,false);
  end
end
--
-- Death indicator functions
--

-- Run when image is first loaded
-- flip through all the CT entries and update and then updateHealth() and set active persons targets
function updateCTEntries()
  for _,node in pairs(CombatManager.getCombatantNodes()) do
    updateHealth(node.getChild("wounds"));
    setTargetsForActive(node);
  end
  CombatManagerADND.updateAllInititiativeIndicators();
end

-- update tokens for health changes
function updateHealth(nodeField)
--UtilityManagerADND.logDebug("manager_token_adnd.lua","updateHealth","nodeField",nodeField);
  if not nodeField then
    return;
  end
  
  local nodeCT = nodeField.getParent();
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  if (tokenCT) then
    -- Percent Damage, Status String, Wound Color
    local pDmg, pStatus, sColor = TokenManager2.getHealthInfo(nodeCT);
    
    -- show rip on tokens
    local bOptionShowRIP = OptionsManager.isOption("COMBAT_SHOW_RIP", "on");
    local bOptionShowRIP_DM = OptionsManager.isOption("COMBAT_SHOW_RIP_DM", "on");
    -- display if health 0 or lower and option on
    local bPlayDead = ((pDmg >= 1) and (bOptionShowRIP));
    if Session.IsHost then
      bPlayDead = ((pDmg >= 1) and (bOptionShowRIP_DM));
    end
    local widgetDeathIndicator = tokenCT.findWidget("deathindicator");
    if bPlayDead then
      if not widgetDeathIndicator then
        local nWidth, nHeight = tokenCT.getSize();
        local nScale = tokenCT.getScale();
        local sName = DB.getValue(nodeCT,"name","Unknown");
        -- new stuff, adds indicator for "DEAD" on the token. -celestian
        local sDeathTokenName = "token_dead";
        -- sDeathTokenName = sDeathTokenName .. tostring(math.random(5)); -- creates token_dead0,token_dead1,token_dead2,token_dead3,token_dead4,token_dead5 string
        -- figure out if this is a pc token
        local rActor = ActorManager.resolveActor(nodeCT);
        -- local nodeActor = ActorManager.getCreatureNode(rActor);
        local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);     
        if sActorType == "pc" then
          sDeathTokenName = "token_dead_pc";
        end
        widgetDeathIndicator = tokenCT.addBitmapWidget(sDeathTokenName);
        widgetDeathIndicator.setBitmap(sDeathTokenName);
        widgetDeathIndicator.setName("deathindicator");
        widgetDeathIndicator.setTooltipText(ActorManager.getDisplayName(ActorManager.resolveActor(nodeCT)) .. " has fallen, as if dead.");
        local nDU = GameSystem.getDistanceUnitsPerGrid();
        local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU)*100;
        local nSizeValue = nSpace-math.ceil(nSpace*.6);
        widgetDeathIndicator.setSize(nSizeValue,nSizeValue);
        --widgetDeathIndicator.setFrame(sDeathTokenName, 5, 5, 5, 5);
      end
      widgetDeathIndicator.setVisible(bPlayDead);
    else
      if widgetDeathIndicator then
        widgetDeathIndicator.destroy();
      end
    end
  end
end

-- when token added to map run these.
function onAddADND(tokenCT)
  updateCTEntries();
  --applyAuras();
end

-- function onContainerChangedADND(tokenCT,nodeOldContain,nOldID)
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","onContainerChangedADND","tokenCT",tokenCT);
 -- local nodeCT = CombatManager.getCTFromToken(tokenCT);
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","onContainerChangedADND","nodeCT",nodeCT);
-- end



--[[
  We do this because Token.onAdd() and imageControl.onTokenAdd() do not fire after
  the image is created but before... so it's useless for setting the auras since
  we have no grid/size/etc...
]]
function onWindowOpened(windowControl)
  local sClass = windowControl.getClass(); 
  if sClass == "imagewindow" then
    applyAuras();
  end
end
-- notify handler to process a "host" access level handleApplyUnderlay
function notifyApplyUnderlay(nodeCT)
  local msgOOB = {};
  msgOOB.type = OOB_MSGTYPE_APPLYUNDERLAY;
  msgOOB.sNodeCTPath = nodeCT.getPath();
  Comm.deliverOOBMessage(msgOOB, "");
end
-- process a aura change as host.
function handleApplyUnderlay(msgOOB)
  local nodeCT = DB.findNode(msgOOB.sNodeCTPath);
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  applyAura(nodeCT,tokenCT);
end
-- if an effect is updated, update the aura underlay
function updateAuras(element)
  -- since we search for .effects* and .effects.* the paths could be different.
  local nodePath = element.getPath();
  -- grab the path of the node regardless which handler found it
  local sNodeCT = nodePath:match("^(combattracker%.list%.id%-%d+)");
  -- local nodeCT = element.getChild("...");
  local nodeCT = DB.findNode(sNodeCT);
  -- UtilityManagerADND.logDebug("manager_token_adnd.lua","updateAuras","element",element);
  -- UtilityManagerADND.logDebug("manager_token_adnd.lua","updateAuras","sNodeCT",sNodeCT);
  -- UtilityManagerADND.logDebug("manager_token_adnd.lua","updateAuras","nodeCT====",nodeCT);
  if nodeCT then
    local tokenCT = CombatManager.getTokenFromCT(nodeCT);
    processAuraChange(nodeCT,tokenCT)
  end
end
--[[ 
  This will flip through all nodeCT's with tokens and apply 
  aura visual if they have an aura effect.
]]
function applyAuras()
  for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
    local tokenCT = CombatManager.getTokenFromCT(nodeCT);
    processAuraChange(nodeCT,tokenCT);
  end
end
-- general top level, processAuraChange function with checks.
function processAuraChange(nodeCT,tokenCT)
  if Session.IsHost then
    applyAura(nodeCT,tokenCT);
  else
    -- send to msg handler to execute 
    -- as Host 
    notifyApplyUnderlay(nodeCT);
  end
end
-- if effect "AURA" exists then we apply a visual underlay
function applyAura(nodeCT,tokenCT)
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","nodeCT",nodeCT);
  if nodeCT and tokenCT then
    local nDU = GameSystem.getDistanceUnitsPerGrid();
    -- this clears out ALL underlays and then adds foe/friend/reach
    if Session.IsHost then
      TokenManager.updateSizeHelper(tokenCT, nodeCT);
    end
    for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
--  UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","nodeEffect",nodeEffect);
--  UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","nodeEffect JSON",Utility.encodeJSON(nodeEffect));
      local nActive = DB.getValue(nodeEffect, "isactive", 0);
      if nActive == 1 and EffectManagerADND.isAuraEffect(nodeEffect) then
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","nodeEffect isAURA",nodeEffect);
        local bHidden = (DB.getValue(nodeEffect,"isgmonly",0) == 1);
        local nAuraMeasure = EffectManagerADND.getAuraRange(nodeEffect);
        local sAuraColor = EffectManagerADND.getAuraColor(nodeEffect);
        local imageSource = ImageManager.getImageControl(tokenCT);
        if imageSource then
          local nGridSize = imageSource.getGridSize();
          local nMapUnitSize = 10;
          nMapUnitSize = imageSource.getDistanceBaseUnits() or 10;
--UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","nGridSize",nGridSize);
--UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","nMapUnitSize",nMapUnitSize);          
          local nSpace = DB.getValue(nodeCT,"space",nMapUnitSize)/nDU;
          local nAuraSize = (nAuraMeasure / nMapUnitSize) + (nSpace/2) ;
          -- this would hide ALL auras on npcs, do we want to do that?
          -- if CombatManagerADND.isCTNodeNPC(nodeCT) then
            -- bHidden = true;
          -- end
          --UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","sAuraColor",sAuraColor);  
          if Session.IsHost then        
            if bHidden then
              tokenCT.addUnderlay(nAuraSize, sAuraColor, "gmonly");
            else
              tokenCT.addUnderlay(nAuraSize, sAuraColor);
            end
          end
        else
           --- no imageSource
           -- UtilityManagerADND.logDebug("manager_token_adnd.lua","applyAura","imageSource NIL");          
        end
      end
    end
  end
end
-- -- set token aura indicator
-- -- currently seems to be a cap of 700ish to size of a widget?!?!? so this is
-- -- mostly useless right now
-- function setTokenAuraIndicator(nodeCT,bState,nSize,sID,sColor)
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","setTokenAuraIndicator","nodeCT",nodeCT);      
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","setTokenAuraIndicator","nSize",nSize);      
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","setTokenAuraIndicator","sID",sID);      
-- UtilityManagerADND.logDebug("manager_token_adnd.lua","setTokenAuraIndicator","sColor",sColor);      
  -- local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  -- if (tokenCT) and sID and sID ~= "" then
    -- if not sColor or sColor == "" then
      -- sColor = "yellow";
    -- end
    -- local sAuraName = "tokenAura_" .. sID .. sColor;
    -- local widgetAura = tokenCT.findWidget(sAuraName);
    -- if not widgetAura and bState then
      -- local nWidth, nHeight = tokenCT.getSize();
      -- --local nScale = tokenCT.getScale();
      -- local sTokenName = "token_aura_" .. sColor;
      -- widgetAura = tokenCT.addBitmapWidget(sTokenName);
      -- widgetAura.setBitmap(sTokenName);
      -- widgetAura.setName(sAuraName);
        -- --widgetAura.setSize(80, 80);
      -- widgetAura.setPosition("center", 0, 0);
      -- widgetAura.setVisible(true);
      -- widgetAura.setEnabled(false);
    -- elseif widgetAura and bState then
      -- widgetAura.setVisible(true);
    -- elseif widgetAura and not bState then
      -- widgetAura.destroy();
    -- end
  -- end
-- end

function onUpdateToken(nodeCT)
  -- trigger this also
  updateHealth(nodeCT);

  -- trim off .nodere
  nodeCT = nodeCT.getParent();
  local tokenCT = CombatManager.getTokenFromCT(nodeCT);
  applyAura(nodeCT,tokenCT);  
end

--[[
  Fired just before token is deleted
]]
-- function onTokenDeleteADND(nodeToken)
--   -- if a token is deleted from Image/MAP 
--   -- lets make sure to flag the CT version of it visible if it's still there.
--   -- Otherwise they'll have a lot of orphaned entries in the combattracker.lists.*
--   local nodeCT = CombatManagerADND.getCTFromTokenUnfiltered(nodeToken);
--   if nodeCT then
--     DB.setValue(nodeCT,"tokenvis","number",1);
--   end
--   --
-- end