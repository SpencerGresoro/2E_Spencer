--
--
--
--

---
-- Script to manage text that can be clicked on an open a record window
---

-- when using an array
aSourceRecords = {}
-- list of entries and their locations
aHyperEntries = {}

dragging = false;
local hoverOnEntry = nil;
local clickOnEntry = nil;

-- options in the xml
local sActivateWindow = nil; -- <activatewindow>
local dataSource = nil;      -- <datasource>
local sTooltipField = nil    -- <tooltipfield>
local bOpenOnMouse = true;   -- <openonmouse>
local sLabelText = nil;      -- <labeltext>
---

function onInit()
    --UtilityManagerADND.logDebug("hyperlink_Text.lua","onInit");
--    UtilityManagerADND.logDebug("hyperlink_Text.lua","onInit","datasource",datasource);

    -- use activatewindow option if set
    if activatewindow and activatewindow[1] then
        sActivateWindow = activatewindow[1];
    end
    -- use datasource option if set
    if datasource and datasource[1] then
        dataSource = datasource[1];
    end
    -- use labeltext option if set
    if labeltext and labeltext[1] then
        sLabelText = labeltext[1];
    end
    -- use tooltipfield option if set
    if tooltipfield and tooltipfield[1] then
        sTooltipField = tooltipfield[1];
    end
    -- use datasource option if set
    if datasource and datasource[1] then
        dataSource = datasource[1];
    end
    --

    if dataSource and sActivateWindow then
        --local node = getDatabaseNode().getParent();
        --UtilityManagerADND.logDebug("hyperlink_Text.lua","onInit","node",node);

        refreshText();
    else
        --UtilityManagerADND.logDebug("ERROR: hyperlink_text template requires activation window and a datasource.")
    end
end

function onClose()
    --UtilityManagerADND.logDebug("hyperlink_Text.lua","onClose");
end

--[[

    Rebuild text list

]]--
function refreshText()
    local node = window.getDatabaseNode();
    local sText = "";
    local nCount = 0;
    local aList = aSourceRecords;
    if (#aSourceRecords < 1) and node and dataSource then
        aList = DB.getChildren(node, dataSource);
    end

    for _,nodeEntry in pairs(aList) do
        local rRecord = {};
        
        local sName = DB.getValue(nodeEntry,"name","no-name-set");
        local sTooltip = "";
        if sTooltipField then
            sTooltip = DB.getValue(nodeEntry,sTooltipField,"");
        end
        if sTooltip then
            rRecord.tooltiptext = sTooltip;
        end
        rRecord.name = sName;

        local sSep = "";
        if sText:len() > 0 then
            sSep = ", ";
        end
        -- stick a label if in they defined one
        if sLabelText and sText:len() < 1 then
            sText = sLabelText;
        end

        rRecord.recordpath = nodeEntry.getPath();
        
        sText = sText .. sSep;

        rRecord.nStart = sText:len();

        sText = sText .. sName;

        rRecord.nEnd = sText:len() + 1;

        nCount = nCount + 1;
        rRecord.index = nCount;
        table.insert(aHyperEntries,nCount,rRecord);
    end
    if sText == "" then
        sText = "Empty";
    end
    -- initialize value
    setValue(sText);
end

--[[
    When hovering over the template control
]]
function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Clear selection when no longer hovering over us
	if not oncontrol then
		-- Clear hover tracking
		hoverOnEntry = nil;
		
		-- Clear any selections
        setSelectionPosition(0);
        setTooltipText('');
	end
end
--[[
    When hovering over the control and mouse moves
]]
function onHoverUpdate(x, y)
    -- we do not mess about when we are dragging a record
    if dragging then
        return;
    end

    -- store the index of the mouse position
    local nMouseIndex = getIndexAt(x, y);
    -- Clear any memory of the last hover update
    hoverOnEntry = nil;
	
    -- Find the entry they have hovered over
	if #aHyperEntries > 0 then
        for _, v in pairs(aHyperEntries) do
            if (nMouseIndex >= v.nStart) and (nMouseIndex <= v.nEnd) then
                hoverOnEntry = v.recordpath;
                if v.tooltiptext then
                    setTooltipText(UtilityManagerADND.stripFormattedText(v.tooltiptext));
                else
                    setTooltipText('');
                end
                setCursorPosition(v.nStart);
                setSelectionPosition(v.nEnd);
                break;
            end
		end
	end

	-- Reset the cursor
	setHoverCursor("arrow");
end

--[[
    When clicking on the highlighted text run this
]]
function onClickDown(button, x, y)
    if hoverOnEntry then
        clickOnEntry = hoverOnEntry;
    end
end

function onClickRelease(button, x, y)
    if hoverOnEntry then
        clickOnEntry = hoverOnEntry;
        local win = Interface.openWindow(sActivateWindow,DB.findNode(hoverOnEntry));
        if win then
            if bOpenOnMouse then
                win.setPosition(x,y);
            end
            return true;
        end
    end
    return false;
end
function onDoubleClick(x, y)
    return onClickRelease(nil,x, y);
end


--[[
    Not implemented yet
]]
function onDragStart(button, x, y, draginfo)
    dragging = false;
    if clickOnEntry then
        draginfo.setShortcutData(sActivateWindow,clickOnEntry);
        draginfo.setType("shortcut");
        draginfo.setDescription(DB.getValue(DB.findNode(clickOnEntry),"name"));
        draginfo.setIcon("button_link");

        local base = draginfo.createBaseData();
        base.setShortcutData(sActivateWindow,clickOnEntry);

        dragging = true;
    end
    return dragging;
end
function onDragEnd(dragdata)
    setCursorPosition(0);
    setTooltipText('');
	dragging = false;
end        

--[[
    Add the entire table
]]
function setTable(aTable)
    aSourceRecords = aTable;
    refreshText();
end

--[[
    Convenience function to sort by name
]]
function sortByNames(aTable)
    local function sortByName(a,b)
        return DB.getValue(a,"name","") < DB.getValue(b,"name","");
    end
    local aSorted = {};
    for _,v in pairs(aTable) do
        table.insert(aSorted,v);
    end
    table.sort(aSorted,sortByName);
    return aSorted;
end

--[[
    set the activation window class
]]
function setActivateWindow(sWindowClass)
    if sWindowClass then
        sActivateWindow = sWindowClass;
        refreshText();
    end
end
--[[
    set the tooltip text field
]]
function setTooltipTextField(sTTField)
    if sTTField then
        sTooltipField = sTTField;
        refreshText();
    end
end