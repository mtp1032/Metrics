--=================================================================================
-- Addon: Metrics
-- Filename: MetricsCore.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
Metrics = Metrics or {}
Metrics.MetricsCore = {}
local core = Metrics.MetricsCore  -- Local reference to the core table

-- import the utility and the threads library
local utils = LibStub:GetLibrary("UtilsLib")
if not utils then 
    DEFAULT_CHAT_FRAME:AddMessage("UtilsLib not found!")
    return 
end
local thread = LibStub:GetLibrary("WoWThreads")
if not thread then 
    DEFAULT_CHAT_FRAME:AddMessage("WoWThreads-1.0 not found!")
    return 
end
------------------------------------------------------------
---                   code begins here                    --
------------------------------------------------------------

local DEBUGGING_ENABLED = false
function core:debuggingIsEnabled()
    return DEBUGGING_ENABLED
end
function core:enableDebugging()
    DEBUGGING_ENABLED = true
end
function core:disableDebugging()
    DEBUGGING_ENABLED = false
end

function core:getExpansionName( )
    local expansionLevel = GetExpansionLevel()
    print( expansionLevel )
    local expansionNames = { -- Use a table to map expansion levels to names
        [LE_EXPANSION_DRAGONFLIGHT] = "Dragon Flight",
        [LE_EXPANSION_SHADOWLANDS] = "Shadowlands",
        [LE_EXPANSION_CATACLYSM] = "Classic (Cataclysm)",
        [LE_EXPANSION_WRATH_OF_THE_LICH_KING] = "Classic (WotLK)",
        [LE_EXPANSION_CLASSIC] = "Classic (Vanilla)",

        [LE_EXPANSION_MISTS_OF_PANDARIA] = "Classic (Mists of Pandaria",
        [LE_EXPANSION_LEGION] = "Classic (Legion)",
        [LE_EXPANSION_BATTLE_FOR_AZEROTH] = "Classic (Battle for Azeroth)",
        [LE_EXPANSION_WAR_WITHIN]   = "Retail (The War Within)"
    }
    return expansionNames[expansionLevel] -- Directly return the mapped name
end
function core:getVersion()
    return C_AddOns.GetAddOnMetadata( ADDON_NAME, "Version")
end

local fileName = "MetricsCore.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end

