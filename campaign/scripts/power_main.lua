-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  DB.addHandler(DB.getPath(getDatabaseNode(), "type"), "onUpdate", update);
  onSummaryChanged();
  update();
end

function onClose()
  DB.removeHandler(DB.getPath(getDatabaseNode(), "type"), "onUpdate", update);
end


function onSummaryChanged()
  local nLevel = level.getValue();
  local sSchool = school.getValue();
  local sSphere = sphere.getValue();
  local sDiscipline = discipline.getValue();
  
  local aText = {};
  if nLevel > 0 then
    table.insert(aText, Interface.getString("level") .. " " .. nLevel);
  end
  if sSchool ~= "" then
    table.insert(aText, sSchool);
  end
  if sSphere ~= "" then
    table.insert(aText, sSphere);
  end
  if sDiscipline ~= "" then
    table.insert(aText, sDiscipline);
  end
  if nLevel == 0 then
    table.insert(aText, Interface.getString("ref_label_cantrip"));
  end
--  if ritual.getValue() ~= 0 then
--    table.insert(aText, "(" .. Interface.getString("ref_label_ritual") .. ")");
--  end
  
  summary_label.setValue(StringManager.capitalize(table.concat(aText, " ")));
end

function updateControl(sControl, bReadOnly, bForceHide)
  if not self[sControl] then
    return false;
  end
  
  return self[sControl].update(bReadOnly, bForceHide);
end

function update()
  local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

  local bSection1 = false;
  if updateControl("shortdescription", bReadOnly) then bSection1 = true; end;
  
  local bSection2 = false;
  if updateControl("level", bReadOnly, bReadOnly) then bSection2 = true; end;
  if updateControl("school", bReadOnly, bReadOnly) then bSection2 = true; end;
  if updateControl("sphere", bReadOnly) then bSection2 = true; end;
  if updateControl("discipline", bReadOnly) then bSection2 = true; end;
--  if updateControl("ritual", bReadOnly, bReadOnly) then bSection2 = true; end;
  if (not bReadOnly) or (level.getValue() == 0 and school.getValue() == "") then
    summary_label.setVisible(false);
  else
    summary_label.setVisible(true);
    bSection2 = true;
  end
  
  local bSection3 = false;
  if updateControl("castingtime", bReadOnly) then bSection3 = true; end;
  if updateControl("range", bReadOnly) then bSection3 = true; end;
  if updateControl("components", bReadOnly) then bSection3 = true; end;
  if updateControl("duration", bReadOnly) then bSection3 = true; end;
  if updateControl("description", bReadOnly) then bSection3 = true; end;
  if updateControl("aoe", bReadOnly) then bSection3 = true; end;
  if updateControl("save", bReadOnly) then bSection3 = true; end;
  if updateControl("type", bReadOnly) then bSection3 = true; end;

  if updateControl("mac", bReadOnly) then bSection3 = true; end;
  if updateControl("pspcost", bReadOnly) then bSection3 = true; end;
  if updateControl("pspfail", bReadOnly) then bSection3 = true; end;
  if updateControl("prerequisite", bReadOnly) then bSection3 = true; end;
  if updateControl("discipline", bReadOnly) then bSection3 = true; end;
  if updateControl("disciplinetype", bReadOnly) then bSection3 = true; end;

  local bSection4 = false;
  if updateControl("source", bReadOnly) then bSection4 = true; end;
  
  divider.setVisible(bSection1 and bSection2);
  divider2.setVisible((bSection1 or bSection2) and bSection3);
  divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
    
    --local bSphere = bReadOnly?(sphere.getValue() ~= ""):true);
    -- local bSphere = false;
    -- if (bReadOnly and sphere.getValue() ~= "") then
        -- bSphere = true;
    -- elseif not bReadOnly then
        -- bSphere = true;
    -- end
    -- sphere_label.setVisible(bSphere);
    -- sphere.setVisible(bSphere);

  local bType = false;
  if (bReadOnly and type.getValue() ~= "") then
      bType = true;
  elseif not bReadOnly then
      bType = true;
  end
  type_label.setVisible(bType);
  type.setVisible(bType);
  
  -- check to see if it's type "psionic"
  local sType = type.getValue():lower();
  if (sType:match("psion")) then
    mac.setVisible(true);
    pspcost.setVisible(true);
    pspfail.setVisible(true);
    prerequisite.setVisible(true);
    discipline.setVisible(true);
    disciplinetype.setVisible(true);
  else
    mac.setVisible(false);
    pspcost.setVisible(false);
    pspfail.setVisible(false);
    prerequisite.setVisible(false);
    mac_label.setVisible(false);
    pspcost_label.setVisible(false);
    pspfail_label.setVisible(false);
    prerequisite_label.setVisible(false);
    discipline.setVisible(false);
    disciplinetype.setVisible(false);
    discipline_label.setVisible(false);
    disciplinetype_label.setVisible(false);
    
  end
  
end
