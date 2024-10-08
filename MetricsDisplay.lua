--=================================================================================
-- Addon: Metrics
-- Filename: MetricsDisplay.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
Metrics = Metrics or {}
Metrics.Display = {}
local display = Metrics.Display

local utils     = LibStub:GetLibrary("UtilsLib")
local thread    = LibStub:GetLibrary("WoWThreads")
local core      = Metrics.MetricsCore

local L         = Metrics.Locales.L

------------------------------------------------------------
---                   code begins here                    --
------------------------------------------------------------

local IN_COMBAT = false
--[[ 
GameFontNormal
GameFontNormal
GameFontNormalLarge
GameFontNormalHuge
GameFontHighlight
GameFontHighlightSmall
GameFontHighlightLarge
GameFontHighlightHuge
GameFontDisable
GameFontDisableSmall
GameFontDisableLarge
GameFontDisableHuge
GameFontGreen
GameFontRed
GameFontWhite
GameFontDarkGraySmall
GameFontNormalLeft
GameFontNormalLeftGray
GameFontNormalLeft
GameFontNormalLeftGray
GameFontHighlightLeft
GameFontHighlightSmallLeft
GameFontHighlightSmallRight
GameFontDisableLeft
GameFontHighlightExtraSmall
GameFontHighlightSmallOutline
GameFontHighlightMedium
GameFontNormalMed3
GameFontNormalMed2
GameFontNormalMed1
]]
	-- set the color
	-- f.Text:SetTextColor( 1.0, 1.0, 1.0 )  -- white
	-- f.Text:SetTextColor( 0.0, 1.0, 0.0 )  -- green
	-- f.Text:SetTextColor( 1.0, 1.0, 0.0 )  -- yellow
	-- f.Text:SetTextColor( 0.0, 1.0, 1.0 )  -- turquoise
	-- f.Text:SetTextColor( 0.0, 0.0, 1.0 )  -- blue
	-- f.Text:SetTextColor( 1.0, 0.0, 0.0 )  -- red

local framePool = {}
local FRAME_TICKS_PER_INTERVAL = 4
local scrollingDmgDisabled = true
local scrollingHealsDisabled = true

function display:disableScrollingDmg()
	scrollingDmgDisabled = true
	DEFAULT_CHAT_FRAME:AddMessage("Scrolling combat damage disabled.")
end
function display:disableScrollingHeals()
	scrollingHealsDisabled = true
	DEFAULT_CHAT_FRAME:AddMessage("Scrolling combat heals disabled.")
end
function display:enableScrollingDmg()
	scrollingDmgDisabled = false
	DEFAULT_CHAT_FRAME:AddMessage("Scrolling combat damage enabled.")
end
function display:enableScrollingHeals()
	scrollingHealsDisabled = false
	DEFAULT_CHAT_FRAME:AddMessage("Scrolling combat heals enabled.")
end

function display:disableScrollingAuras()
	DEFAULT_CHAT_FRAME:AddMessage("Not Implemented")
end
function display:disableScrollingMisses()
	DEFAULT_CHAT_FRAME:AddMessage("Not Implemented")
end

function display:enableScrollingAuras()
	DEFAULT_CHAT_FRAME:AddMessage("Not Implemented")
end
function display:enableScrollingMisses()
	DEFAULT_CHAT_FRAME:AddMessage("Not Implemented")
end



	local function createNewFrame()
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(5, 5)
		f:SetPoint("CENTER", 0, 0)
	
		-- Create a FontString to hold the text
		f.Text = f:CreateFontString(nil, "OVERLAY")
	
		-- Set the font, size, and outline
		-- f.Text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
		f.Text:SetFontObject(GameFontNormal)

		-- Center the text within the frame
		f.Text:SetPoint("CENTER")
	
		-- Set the text color to red
		f.Text:SetTextColor(1.0, 0.0, 0.0)
	
		-- Set the shadow offset to create a black shadow (simulating Blizzard's combat text style)
		f.Text:SetShadowOffset(1, -1)
	
		-- Initialize the text content (this will be updated dynamically)
		f.Text:SetText("")
	
		-- Additional properties for managing the frame's behavior
		f.IsCrit = false
		f.Alpha = 1.0
		f.TotalTicks = 0
		f.TicksPerFrame = FRAME_TICKS_PER_INTERVAL
		f.TicksRemaining = f.TicksPerFrame
		return f
	end
	local function releaseFrame(f) 
		f.Text:SetText("")
		f.IsCrit = false
		f:Hide()
		table.insert(framePool, f)
	end
	local function initFramePool()
		local f = createNewFrame()
		table.insert(framePool, f)
	end
	local function acquireFrame()
		local f = table.remove(framePool)
		if f == nil then 
			f = createNewFrame()
		end
		f:Show()
		return f
	end

	local DAMAGE_EVENT 		= 1
	local HEALING_EVENT 	= 2
	
	local DMG_STARTX = 100
	local DMG_XDELTA = 4
	local DMG_STARTY = 25
	local DMG_YDELTA = 4
	
	local HEAL_STARTX = -DMG_STARTX
	local HEAL_XDELTA = -4
	local HEAL_STARTY = DMG_STARTY
	local HEAL_YDELTA = 4
	
	local AURA_STARTX = -600
	local AURA_XDELTA = 0
	local AURA_STARTY = 200
	local AURA_YDELTA = 3
	
	local MISS_STARTX = 0
	local MISS_XDELTA = 0
	local MISS_STARTY = 100
	local MISS_YDELTA = 3
	
	local count = 0
	local function getStartingPositions(combatType)
		if combatType == DAMAGE_EVENT then 
			-- if count == 1 then
			-- 	DMG_STARTX = 70
			-- 	count = 0
			-- else
			-- 	DMG_STARTX = 50
			-- 	count = 1
			-- end
			return DMG_STARTX, DMG_XDELTA, DMG_STARTY, DMG_YDELTA
		end

		if combatType == HEALING_EVENT then
			return HEAL_STARTX, HEAL_XDELTA, HEAL_STARTY, HEAL_YDELTA
		end 
		if combatType == AURA_EVENT then
			return AURA_STARTX, AURA_XDELTA, AURA_STARTY, AURA_YDELTA
		end
		if combatType == MISS_EVENT then
			return MISS_STARTX, MISS_XDELTA, MISS_STARTY, MISS_YDELTA
		end
		return nil, nil, nil, nil
	end
	local function scrollText(f, startX, xDelta, startY, yDelta)
		local xPos = startX
		local yPos = startY
	
		-- Speed of scrolling (you can adjust this value)
		local scrollSpeed = 10 -- pixels per second
		local curveIntensity = 0.02 -- Intensity of the curve
	
		-- Duration for the text to stay on screen (in seconds)
		local duration = 2
	
		-- Time passed since the text started scrolling
		local timeElapsed = 0
	
		f:SetScript("OnUpdate", 
		function(f, elapsed)
			-- Update the total time elapsed
			timeElapsed = timeElapsed + elapsed
	
			-- Calculate the distance to move based on time elapsed
			local distance = scrollSpeed * elapsed
	
			-- Update horizontal position
			xPos = xPos + (xDelta * distance)
	
			-- Create a curved effect by adjusting the vertical position
			yPos = startY + (curveIntensity * (xPos - startX)^2)
	
			-- Move the text to the new position
			f:ClearAllPoints()
			f:SetPoint("CENTER", xPos, yPos)
	
			-- Calculate the remaining alpha based on the elapsed time
			local remainingAlpha = 1 - (timeElapsed / duration)
			f:SetAlpha(math.max(remainingAlpha, 0))
	
			-- Check if the text should be fully faded out and removed
			if timeElapsed >= duration then
				f:SetScript("OnUpdate", nil)
				f.Text:SetText("")
				f:ClearAllPoints()
				f:SetPoint("CENTER", 0, 0)
				releaseFrame(f)
			end
		end)
	end
	
	function display:damageEntry( isCrit, dmgText)
		if IN_COMBAT == false then return end
		if scrollingDmgDisabled then return end

		local f = acquireFrame()
		f.Text:SetText( dmgText )
		f.IsCrit = isCrit
		local startX, xDelta, startY, yDelta = getStartingPositions(DAMAGE_EVENT)
		local xPos = startX
		local yPos = startY

		f.Text:SetTextColor(1.0, 0.0, 0.0)
		if isCrit then
			f.Text:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
		else
			f.Text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
		end
		f.Text:SetShadowOffset(1, -1)
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, yPos)
	
		scrollText(f, xPos, xDelta, yPos, yDelta)
	end
	
	function display:healEntry(isCrit, healText)
		if IN_COMBAT == false then return end
		if scrollingHealsDisabled then return end

		local f = acquireFrame()
		f.Text:SetText( healText )
		f.IsCrit = isCrit
		local startX, xDelta, startY, yDelta = getStartingPositions(HEALING_EVENT)
		local xPos = startX
		local yPos = startY

		f.Text:SetTextColor(0.0, 1.0, 0.0)
		if isCrit then
			f.Text:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
		else
			f.Text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
		end
		f.Text:SetShadowOffset(1, -1)
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, yPos)
	
		scrollText(f, xPos, xDelta, yPos, yDelta)

		-- if not IN_COMBAT then return end

		-- local f = acquireFrame()
		-- f.Text:SetTextColor(0.0, 1.0, 0.0)
		-- f.Text:SetText(healText)
		-- f.IsCrit = isCrit
	
		-- local startX, xDelta, startY, yDelta = getStartingPositions(HEALING_EVENT)
		-- local xPos = startX
		-- local yPos = startY
	
		-- f.Text:SetFontObject(GameFontNormal)
		-- if f.IsCrit then
		-- 	f.Text:SetFontObject(GameFontNormalHuge)
		-- 	yDelta = 6
		-- 	xDelta = -6
		-- 	xPos = xPos + 25
		-- end
		-- f.Text:SetShadowOffset(1, -1)

		-- f:ClearAllPoints()
		-- f:SetPoint("CENTER", xPos, yPos)
	
		-- scrollText(f, xPos, xDelta, yPos, yDelta)
	end
	
	function display:auraEntry(auraText)
		if not IN_COMBAT then return end

		local f = acquireFrame()
		f.Text:SetTextColor(1.0, 1.0, 0.0)
		f.Text:SetText(auraText)
	
		local startX, xDelta, startY, yDelta = getStartingPositions(AURA_EVENT)
		local xPos = startX 
		local yPos = startY
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, 200)
	
		scrollText(f, xPos, xDelta, startY, yDelta)
	end
	
	function display:missEntry(missText)
		if not IN_COMBAT then return end

		local f = acquireFrame()
		f.Text:SetFontObject(GameFontNormal)
		f.Text:SetTextColor(1.0, 1.0, 1.0)
		f.Text:SetText(missText)
	
		local startX, xDelta, startY, yDelta = getStartingPositions(MISS_EVENT)
		local xPos = startX 
		local yPos = startY
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, yPos)
		scrollText(f, xPos, xDelta, startY, yDelta)
	end
	function display:setCombatFlag( value )
		IN_COMBAT = value
	end
	
initFramePool()

local fileName = "MetricsDisplay.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end
