-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super then
        super.onInit();
    end
  --onValueChanged();
end

function update(bReadOnly)
  setReadOnly(bReadOnly);
end

function action(draginfo)
  local rActor = ActorManager.resolveActor( window.getDatabaseNode());
  --local nodeActor = ActorManager.getCreatureNode(rActor);
  local nodeType, nodeActor = ActorManager.getTypeAndNode(rActor);

  local nTargetDC = DB.getValue(nodeActor, "abilities.".. self.target[1] .. ".score", 0);

  ActionCheck.performRoll(draginfo, rActor, self.target[1], nTargetDC);
  return true;
end

function onDragStart(button, x, y, draginfo)
  if rollable then
    return action(draginfo);
  end
end
  
function onDoubleClick(x, y)
  if rollable then
    return action();
  end
end
