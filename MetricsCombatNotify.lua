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
Metrics.MetricsCombatNotify = {}

local notify = Metrics.MetricsCombatNotify

local utils     = LibStub:GetLibrary("UtilsLib")
local core      = Metrics.MetricsCore 
local L         = Metrics.Locales.L

-- Create a frame for displaying combat notifications
local CombatNotificationFrame = CreateFrame("Frame", "CombatNotificationFrame", UIParent)
CombatNotificationFrame:SetSize(300, 50)  -- Width, Height
CombatNotificationFrame:SetPoint("CENTER", 0, GetScreenHeight() * 0.375)  -- Positioning at X=0 and 3/4 from the bottom to the top
CombatNotificationFrame:Hide()  -- Initially hide the frame

-- Create the text inside the frame
local CombatText = CombatNotificationFrame:CreateFontString(nil, "OVERLAY")
CombatText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")  -- Set the font, size, and outline
CombatText:SetPoint("CENTER", CombatNotificationFrame, "CENTER")  -- Center the text within the frame
CombatText:SetTextColor(1.0, 0.0, 0.0)  -- Red color for the text
CombatText:SetShadowOffset(1, -1)  -- Black shadow to match Blizzard's combat text

-- Function to display the notification
function notify:combatStatusAlert(message, duration)
    CombatText:SetText(message)
    CombatNotificationFrame:Show()

    -- Set up a fade-out effect
    -- duration, example, 5 seconds
    -- Ending Alpha. 0 is the visibility.
    UIFrameFadeOut(CombatNotificationFrame, duration, 1, 0)
    
    -- Hide the frame after the fade is complete
    C_Timer.After(duration, function()
        CombatNotificationFrame:Hide()
    end)
end

-- Event handler to show notifications when entering or leaving combat
-- CombatNotificationFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Event for entering combat
-- CombatNotificationFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Event for leaving combat

-- CombatNotificationFrame:SetScript("OnEvent", function(self, event)
--     if event == "PLAYER_REGEN_DISABLED" then
--         ShowCombatNotification("Entering Combat", 3)  -- Show "Entering Combat" for 3 seconds
--     elseif event == "PLAYER_REGEN_ENABLED" then
--         ShowCombatNotification("Leaving Combat", 3)  -- Show "Leaving Combat" for 3 seconds
--     end
-- end)

local fileName = "MetricsCombatNotify.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end
