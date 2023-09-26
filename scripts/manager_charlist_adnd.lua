--
--
-- Register bits for the combat tracker
--
--
--

function onInit()
  if Session.IsHost then
    --DB.addHandler("combattracker.list.*.initrolled", "onUpdate", onUpdate);
    CharacterListManager.addDecorator("init_rolled", addInitiativeWidget);
  end
end

function onUpdate(nodeField)
--UtilityManagerADND.logDebug("manager_charlist_adnd.lua","onUpdate","sIdentity",sIdentity);
  --local nodeCT = nodeInit.getChild("..");
  local nodeCT = nodeField.getParent();
  local sIdentity = UtilityManagerADND.getIdentityFromCTNode(nodeCT);
  updateWidgets(sIdentity);
end

function addInitiativeWidget(control, sIdentity)
  local widget = control.addBitmapWidget("init_rolled");
  widget.setPosition("center", -25, 9);
  widget.setVisible(true);
  widget.setName("initiativerolled");

  local textwidget = control.addTextWidget("mini_name", "");
  textwidget.setPosition("center", -25, 9);
  textwidget.setVisible(false);
  textwidget.setName("initiativerolledtext");
  
  updateWidgets(sIdentity);
end

-- update widget when init_roll value changes
function updateWidgets(sIdentity)
  local ctrlChar = CharacterListManager.getEntry(sIdentity);
  if not ctrlChar then
    return;
  end
  local widget = ctrlChar.findWidget("initiativerolled");
  local textwidget = ctrlChar.findWidget("initiativerolledtext");
  if not widget or not textwidget then
    return;
  end  
  local nodeCT = CombatManager.getCTFromNode("charsheet." .. sIdentity);
  local bRolled = (DB.getValue(nodeCT,"initrolled",0) == 1);
  if bRolled then
    widget.setVisible(false);
    textwidget.setVisible(false);
  else
    widget.setVisible(true);
    textwidget.setVisible(true);
  end
end

-- this toggles all initrolled values off
-- used for "new round" or when rest initiated
function turnOffAllInitRolled()
  for _,vChild in pairs(CombatManager.getCombatantNodes()) do
    -- toggle the rolled init value to false till
    -- until PC actually rolls.
    turnOffInitRolled(vChild);
  end
end

-- turn off a CT node initiative rolled portrait indicator
function turnOffInitRolled(vChild)
  local rActor = ActorManager.resolveActor(vChild);
  if (ActorManager.isPC(rActor)) then
    DB.setValue(vChild, "initrolled", "number", 0);
  end
end

-- this variable is a boolean value that tells us that the target has already
-- had their initiative run once. We do this to allow "delay" in a round and other things
-- and only run their effects/etc the first time init is activated for them --celestian
function turnOffAllInitRun()
  for _,vChild in pairs(CombatManager.getCombatantNodes()) do
    -- toggle the initrun boolean value to false till
    DB.setValue(vChild, "initrun", "number", 0);
  end
end