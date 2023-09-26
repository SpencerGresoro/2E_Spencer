--
-- This is to manage DB nodes as host
--
--

OOB_MSGTYPE_DBSETVALUE = "ashost_setvalue";
function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DBSETVALUE, handleSetValueAsHost);
end

function onClose()
end

--[[
    OOB makes changes
]]
function handleSetValueAsHost(msgOOB)
    local oNode = DB.findNode(msgOOB.sNode);
    if oNode then    
        local sTag = msgOOB.sTag;
        local sType = msgOOB.sType;
        local value = msgOOB.value;
        if sType == "number" then
            value = tonumber(value);
        end
        DB.setValue(oNode,sTag,sType,value);
    end
end

--[[
    Set a value on a DB node as host

    DB.setValue(nodeEffect,"label","string",sReplacedLabel);
]]
function setValue(sNode,sTag,sType,value)
    local msgOOB = {};
    msgOOB.type = OOB_MSGTYPE_DBSETVALUE;
    if type(sNode) == 'databasenode' then
        sNode = sNode.getPath();
    elseif type(sNode) ~= 'string' then
        DB.console("manager_ashost.lua","setValue","sNode is not a databasenode or a string",sNode);
        return;
    end
    msgOOB.sNode = sNode;
    msgOOB.sTag = sTag;
    msgOOB.sType = sType;
    msgOOB.value = value;
  
    Comm.deliverOOBMessage(msgOOB, "");
end