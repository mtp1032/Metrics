--------------------------------------------------------------------------------------
-- MetricsIcon.lua
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 November, 2019
local ADDON_NAME, Metrics = ...
Metrics.MetricsIcon = {}
local icon = Metrics.MetricsIcon

local panel = Metrics.OptionsPanel
local core  = Metrics.MetricsCore

local L     = Metrics.Locales.L

local ICON_DPS_TRACKER = 237569	-- this is the icon's texture

-- register the addon with ACE
local addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0")

local shiftLeftClick 	= (button == "LeftButton") and IsShiftKeyDown()
local shiftRightClick 	= (button == "RightButton") and IsShiftKeyDown()
local altLeftClick 		= (button == "LeftButton") and IsAltKeyDown()
local altRightClick 	= (button == "RightButton") and IsAltKeyDown()
local rightButtonClick	= (button == "RightButton")

-- The addon's icon state (e.g., position, etc.,) is kept in the MetricsDB. Therefore
--  this is set as the ##SavedVariable in the .toc file
local MetricsDB = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, 
	{
		type = "data source",
		text = ADDON_NAME,
		icon = ICON_DPS_TRACKER,
		OnTooltipShow = function( tooltip )
			tooltip:AddLine(L["ADDON_AND_VERSION"])
			tooltip:AddLine(L["Left click to toggle options menu."])
			-- tooltip:AddLine(L["Right click to show encounter report(s)."])
			-- tooltip:AddLine(L["Shift right click to clear encounter text."])
			-- tooltip:AddLine(L["Shift left click - NOT IMPLENTED"])
		end, 
		OnClick = function(self, button )
			-- LEFT CLICK - Display the options menu
			if button == "LeftButton" and not IsShiftKeyDown() then 
				if panel:isVisible() then
					panel:hide()
				else
					panel:show()
				end
			end
			-- RIGHT CLICK - Show the encounter reports
			if button == "RightButton" and not IsShiftKeyDown() then
				-- mf:eraseText()
				-- options:summarizeEncounter()
			end
			if button == "LeftButton" and IsShiftKeyDown() then
			end
			if button == "RightButton" and IsShiftKeyDown() then
				-- mf:eraseText()
			end
	end,
	})

-- so far so good. Now, create the actual icon	
local icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MetricsDB", 
					{ profile = { minimap = { hide = false, }, }, }) 
	icon:Register(ADDON_NAME, MetricsDB, self.db.profile.minimap) 
end

local fileName = "MetricsIcon.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end

