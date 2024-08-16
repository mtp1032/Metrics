--=================================================================================
-- Addon: Metrics
-- Filename: MetricsTargetDummy.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024

-- https://github.com/liquidbase/wowui-source/blob/master/SmoothStatusBar.lua

--=================================================================================
local ADDON_NAME, Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
Metrics = Metrics or {}
Metrics.MetricsTargetDummy = {}

local target = Metrics.MetricsTargetDummy
local utils     = LibStub:GetLibrary("UtilsLib")
local core      = Metrics.MetricsCore 
local L         = Metrics.Locales.L

-- default health bar position
local FRAME_POINT 		= "BOTTOM"
local REFERENCE_FRAME 	= nil
local RELATIVE_TO 		= "BOTTOM"
local OFFSET_X 			= 39.398860931396
local OFFSET_Y			= 184.8804473877

local tableActiveHealthBars = {}
local healthBarPool = {}
local tableTargetGUIDs = {}
target.defaultTargetHealth = nil
-- Indices of CLEU subEvents require in this module
local CLEU_SUBEVENT		= 2
local CLEU_TARGETGUID 	= 8
local CLEU_TARGETNAME	= 9 	
local CLEU_DAMAGE_DONE	= 15

-- returns true if the GUID was inserted and a count of the number of GUIDs
-- in the table.
function target:insertTargetGUID( targetGUID )

	local subStr = strsub( targetGUID, 1, 6 )
	if subStr == "Player" then 
		return #tableTargetGUIDs 
	end
	-- do nothing if the guid is already in the table
	for _, guid in ipairs( tableTargetGUIDs) do
		if targetGUID == guid then
			return #tableTargetGUIDs
		end
	end
	
	-- Then it's a new target. Insert its targetGUID into the table
	-- and return true
	table.insert( tableTargetGUIDs, targetGUID )
	print( utils:dbgPrefix(), "Inserted targetGUID. tableActiveGUIDs: ", #tableTargetGUIDs )
	return #tableTargetGUIDs
end
function target:removeGUID( targetGUID )
	if #tableTargetGUIDs == 0 then return 0 end

	local removedGUID = nil
	for i, guid in ipairs( tableTargetGUIDs) do
		if targetGUID == guid then
			removedGUID = table.remove( tableTargetGUIDs, i )
			assert( removedGUID == targetGUID, "ASSERT FAILED: Unequal GUIDS in target:removeGUIDs().")
			break	
		end
	end
	return #tableTargetGUIDs
end
function target:numberOfTargetGUIDs()
	return #tableTargetGUIDs
end
function target:isDummy( targetName )
	local isDummy = false

	if targetName == nil then return isDummy end
	targetName = string.upper( targetName )
	if strlen(targetName) < 14 then return isDummy end
	
	local targetName = string.sub( targetName, -14)
	if targetName == "TRAINING DUMMY" then
		isDummy = true
	end
	return isDummy
end
function target:removeHealthBars()
	local num = #tableActiveHealthBars
	for i = 1, num do
		local f = table.remove( tableActiveHealthBars, tableActiveHealthBars[i])
		target:removeGUID( f.TargetGUID )
		table.insert( healthBarPool, f )
	end
	wipe( tableActiveHealthBars)
end
-- This function is only called from the minimap options module.
function target:setTargetDummyHealth( targetHealth )

	if UnitExists("Target") == false then
		UIErrorsFrame:SetTimeVisible(4)
		local msg = string.format("[INFO] No Target Selected.")	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end
	if not target:isDummy( f.TargetName ) then
		UIErrorsFrame:SetTimeVisible(5)
		local msg = string.format("[INFO] %s Must Be A Target Dummy.", f.TargetName )	
		UIErrorsFrame:AddMessage( msg, 1.0, 1.0, 0.0 )
		return
	end

	local targetGUID = UnitGUID("Target")

	-- The target's health bar should already exist because if we're
	-- here the dummy was targeted but its health had not yet been set.
	local f = nil
	for _, bar in ipairs( tableActiveHealthBars) do
		if bar.TargetGUID == targetGUID then
			f = bar
			break
		end
	end
	assert(f ~= nil )
	targetHealth = UnitHealthMax( "Target") * 2
	f.TargetMaxHealth = targetHealth
	f.TargetHealth = targetHealth
end
-- Reinitializes a target frame when retrieved from the frame pool
local function getHealthBarFromPool()
	local f = nil
	if #healthBarPool == 0 then return nil end

	f = table.remove( healthBarPool )
	return f
end
function target:createHealthBar( targetName, targetGUID, targetHealth )
	local f = getHealthBarFromPool()
	if f ~= nil then return f end

	-- no health bars in the cache (pool). Create a brand new health bar
	f = CreateFrame("Frame", "StatusBarFrame", UIParent,"TooltipBackdropTemplate")

	f.TargetMaxHealth	= targetHealth
	f.TargetHealth		= targetHealth
	f.TargetName 		= targetName
	f.TargetGUID		= targetGUID

	f:SetBackdropBorderColor(0.5,0.5,0.5)
	f:SetSize(300,30)

	local a = FRAME_POINT
	local b = REFERENCE_FRAME
	local c = RELATIVE_TO
	local d = OFFSET_X
	local e = OFFSET_Y

	-- f:SetPoint( a, b, c, d, e )
	f:SetPoint( "CENTER")

    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", 
		function(self)
			self:StopMovingOrSizing()
			local a, b, c, d, e = self:GetPoint()
			SAVED_HEALTHBAR_FRAME = {a, b, c, d, e}
		end)

	f.bar = CreateFrame("StatusBar",nil,f)
	f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.bar:SetStatusBarColor( 0.0, 1.0, 0.0 )
	f.bar:SetPoint("TOPLEFT",5,-5)
	f.bar:SetPoint("BOTTOMRIGHT",-5,5)

	-- create a font string for the text
	f.bar.text = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.bar.text:SetTextColor( 1.0, 1.0, 0.0 )	-- yellow
	f.bar.text:SetPoint("LEFT")

	-- copying mixins to statusbar
	Mixin(f.bar,SmoothStatusBarMixin)
	f.bar:SetMinMaxSmoothedValue(0, f.TargetMaxHealth )
	f.bar:SetSmoothedValue( f.TargetMaxHealth )
	local percent = math.floor( f.TargetHealth/f.TargetMaxHealth * 100)	
	local s = string.format("[%s HP %d] %0.1f%%", f.TargetName, f.TargetHealth, percent )
	f.bar.text:SetText( s )	

	table.insert( tableActiveHealthBars, f )
	target:insertTargetGUID( f.TargetGUID)
	f:Show()
	return f
end
function target:updateHealthBar( subEvent )

	local targetName = subEvent[CLEU_TARGETNAME]
	local targetGUID = subEvent[CLEU_TARGETGUID]

	-- check that this is a valid health bar
	local f = nil
	for _, bar in ipairs( tableActiveHealthBars) do
		if bar.TargetGUID == targetGUID then
			f = bar
			break
		end
	end
	if f == nil then return #tableTargetGUIDs end

	if subEvent[CLEU_SUBEVENT] == "SWING_DAMAGE" then
		f.TargetHealth = f.TargetHealth - subEvent[CLEU_DAMAGE_DONE - 3]
	else
		f.TargetHealth = f.TargetHealth - subEvent[CLEU_DAMAGE_DONE]
	end

	if f.TargetHealth <= 0 then 
		f.TargetHealth = 0

		target:removeGUID( f.TargetGUID )

		
		-- move the target health bar into the pool of [used] health bars
		for i, entry in ipairs( tableActiveHealthBars) do
			if f.TargetGUID == entry.TargetGUID then
				f = table.remove( tableActiveHealthBars, i )
				table.insert( healthBarPool, f )
			end
		end
		f:Hide()
	else 
		f.bar:SetSmoothedValue( f.TargetHealth  )
		local percent = math.floor( f.TargetHealth/f.TargetMaxHealth * 100)	
		local s = string.format("[%s HP %d] %0.1f%%", f.TargetName, f.TargetHealth, percent )
		f.bar.text:SetText( s )	
	end

	return #tableTargetGUIDs
end

--------------  	EVENT PROCESSING BELOW HERE ------------------
local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent( "PLAYER_LOGIN")
eventFrame:RegisterEvent( "PLAYER_TARGET_CHANGED")

eventFrame:SetScript("OnEvent",
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...

	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		if DPS_METRICS_HEALTHBAR_VARS  == nil then
			DPS_METRICS_HEALTHBAR_VARS = { FRAME_POINT, REFERENCE_FRAME, RELATIVE_TO, OFFSET_X, OFFSET_Y }
		end
		
		DEFAULT_CHAT_FRAME:AddMessage( L["ADDON_LOADED_MESSAGE"],  0.0, 1.0, 1.0 )
		eventFrame:UnregisterEvent("ADDON_LOADED") 
		return
	end 

	if event == "PLAYER_TARGET_CHANGED" then

		local targetName = UnitName("Target")
		local targetGUID = UnitGUID( "Target" )

		if targetGUID == nil then
			return
		end

		-- return if the target is NOT a dummy target
		local isDummy = target:isDummy( targetName )
		if not isDummy then 
			return
		end
		-- return if the guid is alredy in the table
		for _, guid in ipairs( tableTargetGUIDs ) do
			if targetGUID == guid then
				return
			end
		end

		-- did the player change to an existing target? If so, just return.
		if #tableActiveHealthBars > 0 then
			for _, bar in ipairs( tableActiveHealthBars) do
				if bar.TargetGUID == targetGUID then
					return
				end
			end
		end

		-- if we're here, this is a new target. If a target health bar exists in
		-- the pool of health bar frames, use it. If not, create a new health bar.
		local targetHealth = UnitHealthMax("Player") * 2
		local f = target:createHealthBar(targetName, targetGUID, targetHealth )
	end
end)

local fileName = "MetricsTargetDummy.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end
