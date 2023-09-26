-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

windowParent = nil
function registerWindowParent(myParent)
  windowParent = myParent;
end

function minimizeMe()
  windowParent.windowDropDown.minimize();
end;

function onHover(bOver)
  if not bOver then
    minimizeMe();
  end
end    
