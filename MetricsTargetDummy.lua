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

local tableOfActiveHealthBars = {}
local healthBarPool = {}
local tableOfTargetGUIDs = {}
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
		return #tableOfTargetGUIDs 
	end
	-- do nothing if the guid is already in the table
	for _, guid in ipairs( tableOfTargetGUIDs) do
		if targetGUID == guid then
			return #tableOfTargetGUIDs
		end
	end
	
	-- Then it's a new target. Insert its targetGUID into the table
	-- and return true
	table.insert( tableOfTargetGUIDs, targetGUID )
	return #tableOfTargetGUIDs
end
function target:removeGUID( targetGUID )
	if #tableOfTargetGUIDs == 0 then return 0 end

	local removedGUID = nil
	for i, guid in ipairs( tableOfTargetGUIDs) do
		if targetGUID == guid then
			removedGUID = table.remove( tableOfTargetGUIDs, i )
			assert( removedGUID == targetGUID, "ASSERT FAILED: Unequal GUIDS in target:removeGUIDs().")
			break	
		end
	end
	return #tableOfTargetGUIDs
end
function target:numberOfTargetGUIDs()
	return #tableOfTargetGUIDs
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
	local num = #tableOfActiveHealthBars
	for i = 1, num do
		local f = table.remove( tableOfActiveHealthBars, tableOfActiveHealthBars[i])
		target:removeGUID( f.TargetGUID )
		table.insert( healthBarPool, f )
	end
	wipe( tableOfActiveHealthBars)
end
-- This function is only called from the minimap options file.
-- If the target is not a target dummy, then an error message
-- is displayed.
function target:setTargetDummyHealth( targetHealth )

	-- Check whether the player has a selected a target.
	-- If not, then display an error message.
	if UnitExists("Target") == false then 
		UIErrorsFrame:SetTimeVisible(4)
		local msg = string.format("[INFO] No Target Selected.")	
		UIErrorsFrame:AddMessage( msg, 1.0, 0.0, 0.0 )
		return
	end

	-- check whether the selected target's guid exists.
	local f = nil
	local targetGUID = UnitGUID("Target")
	for _, bar in ipairs( tableOfActiveHealthBars ) do
		if bar.TargetGUID == targetGUID then
			f = bar
			break
		end
	end
	assert( f ~= nil, "Target's healthbar not found." )


	-- check that the selected target is a target dummy
	local targetName = UnitName("Target")
	if not target:isDummy( targetName ) then
		UIErrorsFrame:SetTimeVisible(5)
		local msg = string.format("[INFO] %s Must Be A Target Dummy.", f.TargetName )	
		UIErrorsFrame:AddMessage( msg, 1.0, 0.0, 0.0 )
		return
	end

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
-- creates a health bar, though if one exists in the cache of removeHealthBars
-- use that instead.
function target:createHealthBar( targetName, targetGUID, targetHealth )
	local f = getHealthBarFromPool()
	if f == nil then
		f = CreateFrame("Frame", "StatusBarFrame", UIParent,"TooltipBackdropTemplate")
	end
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

	f.Bar = CreateFrame("StatusBar",nil,f)
	f.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f.Bar:SetStatusBarColor( 0.0, 1.0, 0.0 )
	f.Bar:SetPoint("TOPLEFT",5,-5)
	f.Bar:SetPoint("BOTTOMRIGHT",-5,5)

	-- create a font string for the text
	f.Bar.text = f.Bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.Bar.text:SetTextColor( 1.0, 1.0, 0.0 )	-- yellow
	f.Bar.text:SetPoint("LEFT")

	-- copying mixins to statusbar
	Mixin(f.Bar,SmoothStatusBarMixin)
	f.Bar:SetMinMaxSmoothedValue(0, f.TargetMaxHealth )
	f.Bar:SetSmoothedValue( f.TargetMaxHealth )
	local percent = math.floor( f.TargetHealth/f.TargetMaxHealth * 100)	
	local s = string.format("[%s HP %d] %0.1f%%", f.TargetName, f.TargetHealth, percent )
	f.Bar.text:SetText( s )	

	table.insert( tableOfActiveHealthBars, f )
	target:insertTargetGUID( f.TargetGUID)
	f:Show()
	return f
end

-- called from MetricsEvent.lua
function target:updateHealthBar( subEvent )

	local targetName = subEvent[CLEU_TARGETNAME]
	local targetGUID = subEvent[CLEU_TARGETGUID]

	-- check that this is a valid health bar
	local f = nil
	for _, bar in ipairs( tableOfActiveHealthBars) do
		if bar.TargetGUID == targetGUID then
			f = bar
			break
		end
	end
	if f == nil then return #tableOfTargetGUIDs end

	if subEvent[CLEU_SUBEVENT] == "SWING_DAMAGE" then
		f.TargetHealth = f.TargetHealth - subEvent[CLEU_DAMAGE_DONE - 3]
	else
		f.TargetHealth = f.TargetHealth - subEvent[CLEU_DAMAGE_DONE]
	end

	if f.TargetHealth <= 0 then 
		f.TargetHealth = 0

		target:removeGUID( f.TargetGUID )

		
		-- move the target health bar into the pool of [used] health bars
		for i, entry in ipairs( tableOfActiveHealthBars) do
			if f.TargetGUID == entry.TargetGUID then
				f = table.remove( tableOfActiveHealthBars, i )
				table.insert( healthBarPool, f )
			end
		end
		f:Hide()
	else 
		f.Bar:SetSmoothedValue( f.TargetHealth  )
		local percent = math.floor( f.TargetHealth/f.TargetMaxHealth * 100)	
		local s = string.format("[%s HP %d] %0.1f%%", f.TargetName, f.TargetHealth, percent )
		f.Bar.text:SetText( s )	
	end

	return #tableOfTargetGUIDs
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

		-- return if the target is NOT a target dummy
		local isDummy = target:isDummy( targetName )
		if not isDummy then 
			return
		end

		-- return if the guid is alredy in the table
		for _, guid in ipairs( tableOfTargetGUIDs ) do
			if targetGUID == guid then
				return
			end
		end

		-- did the player change to an existing target? If so, just return.
		if #tableOfActiveHealthBars > 0 then
			for _, bar in ipairs( tableOfActiveHealthBars) do
				if bar.TargetGUID == targetGUID then
					return
				end
			end
		end

		-- if we're here, this is a new target so we create a new, or use
		-- an existing healthbar.
		local targetHealth = UnitHealthMax("Player") * 2
		local f = target:createHealthBar(targetName, targetGUID, targetHealth )
	end
end)

local fileName = "MetricsTargetDummy.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end
