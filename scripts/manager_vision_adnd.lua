

--[[

VisionManager.clearLightDefaults/addLightDefault/addLightDefaults/removeLightDefault

]]
function onInit()
    VisionManager.addVisionType(Interface.getString("vision_infravision"), "infravision");
    -- this allows us to include vision "Infravision 60" in the specialDefense field of npcs.
    VisionManager.addVisionField('specialDefense');
    
    -- reconfigure Light Effect Presets
    setupLightEffectPresets();
end

--[[
	We adjust all of the lighting presets here to match 2e style
]]
_tTokenLightDefaults_ADND = {
	["candle"] = {
		sColor = "FFFFFCC3",
		nBright = 2,
		nDim = 2,
		sAnimType = "flicker",
		nAnimSpeed = 100,
		nDuration = 60,
	},
	["torch"] = {
		sColor = "FFFFF3E1",
		nBright = 3,
		nDim = 3,
		sAnimType = "flicker",
		nAnimSpeed = 25,
		nDuration = 30,
	},
	["lantern"] = {
		sColor = "FFF9FEFF",
		nBright = 8,
		nDim = 8,
		nDuration = 120,
	},
	["spell_darkness"] = {
		sColor = "FF000000",
		nBright = 3,
		nDim = 3,
		nDuration = 0,
	},
	["spell_light"] = {
		sColor = "FFFFF3E1",
		nBright = 4,
		nDim = 4,
		nDuration = 0,
	},
};
function setupLightEffectPresets()
    VisionManager.removeLightDefault("lamp");
    VisionManager.addLightDefaults(_tTokenLightDefaults_ADND);
    VisionManager.updateLightPresets();
end