--
--
--
-- this code is to manage the movement speed for characters
--

function onInit()
    super.onInit();
    local nodeChar = window.getDatabaseNode();
    local nodeCT = CombatManager.getCTFromNode(nodeChar);
    DB.addHandler(DB.getPath(nodeChar, "speed.base"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.basemodenc"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.basemod"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.mod"),"onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeChar, "speed.tempmod"),"onUpdate", detailsUpdate);

    DB.addHandler(DB.getPath(nodeCT, "effects.*.label"), "onUpdate", detailsUpdate);
    DB.addHandler(DB.getPath(nodeCT, "effects.*.isactive"), "onUpdate", detailsUpdate);

    detailsUpdate();
end

function onClose()
    local nodeChar = window.getDatabaseNode();
    local nodeCT = CombatManager.getCTFromNode(nodeChar);
    DB.removeHandler(DB.getPath(nodeChar, "speed.base"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.basemodenc"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.basemod"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.mod"),"onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeChar, "speed.tempmod"),"onUpdate", detailsUpdate);

    DB.removeHandler(DB.getPath(nodeCT, "effects.*.label"), "onUpdate", detailsUpdate);
    DB.removeHandler(DB.getPath(nodeCT, "effects.*.isactive"), "onUpdate", detailsUpdate);

end

function detailsUpdate()
    local nodeChar = window.getDatabaseNode(); 
    local nodeCT = CombatManager.getCTFromNode(nodeChar);

    local nMoveBase     = DB.getValue(nodeChar,"speed.base",0);
    local nMoveBaseENC  = DB.getValue(nodeChar,"speed.basemodenc",0);
    local nMoveBaseMod = DB.getValue(nodeChar,"speed.basemod",0);

    local nMoveAdjustment, nMoveEffectCount = EffectManager5E.getEffectsBonus(nodeCT, "MOVE",true);
    local nBaseMoveAdjustment, nBaseMoveEffectCount = EffectManager5E.getEffectsBonus(nodeCT, "BASEMOVE",true);

    local nTotalBase = nMoveBase;
    if (nMoveBaseENC ~= 0) and (nMoveBaseENC < nTotalBase) then
        nTotalBase = nMoveBaseENC;
    end
    if (nMoveBaseMod ~= 0) and (nMoveBaseMod < nTotalBase) then
        nTotalBase = nMoveBaseMod;
    end


    local nMoveMod    = DB.getValue(nodeChar,"speed.mod",0);
    local nMoveTemp   = DB.getValue(nodeChar,"speed.tempmod",0);
    local nTotalMods = nMoveMod + nMoveTemp;

    -- effect adjustments
    if nMoveEffectCount > 0 then
        nTotalMods = nTotalMods + nMoveAdjustment;
    end
    -- effect adjustments
    if nBaseMoveEffectCount > 0 then
        nTotalBase = nBaseMoveAdjustment;
    end
    -- end effect adjustments
    local nTotalMove = nTotalBase + nTotalMods;
    DB.setValue(nodeChar,"speed.total","number",nTotalMove);
end
