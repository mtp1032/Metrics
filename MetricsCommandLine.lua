-------------------------------------------------------------------
-- MetricsCommandLine.lua
-- ORIGINAL DATE: 8 August, 2024
-------------------------------------------------------------------
local ADDON_NAME, Metrics = ...
Metrics.MetricsCommandLine = {}
-- cmd = Metrics.MetricsCommandLine

local utils     = LibStub:GetLibrary("UtilsLib")
local core      = Metrics.MetricsCore
local L         = Metrics.Locales.L
local event 	= Metrics.Event
local display   = Metrics.Display

local str1 = string.format("                             Metrics Help.\n")
local str2 = string.format("Options are 'help,' 'post,' or 'reset'. Post and reset require parameters.\n" )
local str3 = string.format("Post parameters: 'first', 'last', 'all'\n")
local str4 = string.format("    /metrics post first -- displays all encounters (Max 10).\n" )
local str5 = string.format("    /metrics post last  -- displays the last or most recent encounter.\n")
local str6 = string.format("    /metrics post all   -- displays all encounter records.\n\n")
local str7 = string.format("Reset parameters: 'combat', 'all'\n")
local str8 = string.format("    /metrics reset combat  -- resets ONLY the combat state.\n")
local str9 = string.format("    /metrics reset all     -- deletes all encounter records and resets combat state.\n")


local helpStr = string.format("%s%s%s%s%s%s%s%s%s", str1,str2,str3,str4,str5,str6,str7,str8,str9 ) 



local function commandLineParams( playerInput, editbox)

    local _, _, option, parameter = strfind( playerInput, "%s?(%w+)%s?(.*)")

    if option == nil or option == EMPTY_STR then
        utils:postMsg( helpStr )
        return
    end

    option = string.lower( option)
    parameter = string.lower( parameter )

    if option == "help" then
        utils:postMsg( helpStr )
        return
    end

    if option ~= "post" and option ~= "print" and option ~= "reset" and option ~= "combat" then
        print( utils:dbgPrefix(), "Invalid or unknown option specified." )
        return    
    end

    if option == "reset" then
        event:enableCombat()
        return
    end

    -- if the option is specified but not the parameter, then display the help message
    if option == "print" or option == "post" then
        if parameter == nil or parameter == EMPTY_STR then
            print( utils:dbgPrefix(), "No parameter specified." )
        end
    
        if parameter == "all" then
            print( utils:dbgPrefix(), "print all encounter records." )
            return
        end
        if parameter == "first" then
            print( utils:dbgPrefix(), "print the first/oldest encounter record" )
            return
        end
        if parameter == "last" then
            print( utils:dbgPrefix(), "print the last (most recent) encounter record." )
            return
        end
    end
end
    SLASH_METRICS1 = "/metrics"
    SlashCmdList["METRICS"] = commandLineParams

if core:debuggingIsEnabled() then
	local fileName = "MetricsCommandLine.lua"
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end
