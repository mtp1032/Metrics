--=================================================================================
-- Addon: Metrics
-- Filename: MetricsLocales.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
Metrics = Metrics or {}
Metrics.Locales = {}
local core = Metrics.MetricsCore
------------------------------------------------------------
---                   code begins here                    --
------------------------------------------------------------

-- Form a string representing the library's version number (see WoWThreads.lua).
local MAJOR = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-MAJOR")
local MINOR = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-MINOR")
local PATCH = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-PATCH")

local version = string.format("%s.%s.%s", MAJOR, MINOR, PATCH )

local expansionName = core:getExpansionName()
local L = setmetatable({}, { __index = function(t, k) 
    local v = tostring(k)
    rawset(t, k, v)
    return v
end })

Metrics.Locales.L = L

local LOCALE = GetLocale()
if LOCALE == "enUS" then
    L["VERSION"]            = version
    L["EXPANSION_NAME"]     = expansionName
    L["ADDON_AND_VERSION"]  = string.format("%s %s (%s). ", ADDON_NAME, version, expansionName)
    L["ADDON_LOADED_MESSAGE"]   = L["ADDON_AND_VERSION"] .. " loaded."
    L["INPUT_PARM_NIL"]     = "ERROR: Input parameter nil. "
    L["INVALID_TYPE"]       = "ERROR: Input datatype invalid. "
    L["ILLEGAL_OPERATION"]  = "ERROR: Operation is not supported. "
    L["UNEXPECTED_VALUE"]   = "ERROR: Value was unexpected. "
elseif LOCALE == "frFR" then
    L["VERSION"] = version
    L["EXPANSION_NAME"] = expansionName
    L["ADDON_LOADED_MESSAGE"] = string.format( "%s(%s) chargé ", ADDON_NAME, expansionName)
    L["INPUT_PARM_NIL"] = "ERREUR : Paramètre d'entrée nil. "
    L["INVALID_TYPE"] = "ERREUR : Type de données d'entrée invalide. "
    L["ILLEGAL_OPERATION"]  = "ERREUR : Opération non supportée. "
    L["UNEXPECTED_VALUE"]   = "ERREUR : Valeur inattendue. "
elseif LOCALE == "deDE" then
    L["VERSION"] = version
    L["EXPANSION_NAME"] = expansionName
    L["ADDON_LOADED_MESSAGE"] = string.format( "%s(%s) geladen ", ADDON_NAME, expansionName)
    L["INPUT_PARM_NIL"] = "FEHLER: Eingabeparameter nil. "
    L["INVALID_TYPE"] = "FEHLER: Ungültiger Eingabedatentyp. "
    L["ILLEGAL_OPERATION"]  = "FEHLER: Operation wird nicht unterstützt. "
    L["UNEXPECTED_VALUE"]   = "FEHLER: Unerwarteter Wert. "
elseif LOCALE == "esES" then
    L["VERSION"] = version
    L["EXPANSION_NAME"] = expansionName
    L["ADDON_LOADED_MESSAGE"] = string.format( "%s(%s) cargado ", ADDON_NAME, expansionName)
    L["INPUT_PARM_NIL"] = "ERROR: Parámetro de entrada nulo. "
    L["INVALID_TYPE"] = "ERROR: Tipo de dato de entrada inválido. "
    L["ILLEGAL_OPERATION"]  = "ERROR: Operación no soportada. "
    L["UNEXPECTED_VALUE"]   = "ERROR: Valor inesperado. "
elseif LOCALE == "ruRU" then
    L["VERSION"] = version
    L["EXPANSION_NAME"] = expansionName
    L["ADDON_LOADED_MESSAGE"] = string.format( "%s(%s) загружен ", ADDON_NAME, expansionName)
    L["INPUT_PARM_NIL"] = "ОШИБКА: Входной параметр nil. "
    L["INVALID_TYPE"] = "ОШИБКА: Неверный тип данных ввода. "
    L["ILLEGAL_OPERATION"]  = "ОШИБКА: Операция не поддерживается. "
    L["UNEXPECTED_VALUE"]   = "ОШИБКА: Неожиданное значение. "
elseif LOCALE == "ptBR" then
    L["VERSION"] = version
    L["EXPANSION_NAME"] = expansionName
    L["ADDON_LOADED_MESSAGE"] = string.format( "%s(%s) carregado ", ADDON_NAME, expansionName)
    L["INPUT_PARM_NIL"] = "ERRO: Parâmetro de entrada nulo. "
    L["INVALID_TYPE"] = "ERRO: Tipo de dado de entrada inválido. "
    L["ILLEGAL_OPERATION"]  = "ERRO: Operação não suportada. "
    L["UNEXPECTED_VALUE"]   = "ERRO: Valor inesperado. "
elseif LOCALE == "itIT" then
    L["VERSION"] = version
    L["EXPANSION_NAME"] = expansionName
    L["ADDON_LOADED_MESSAGE"] = string.format( "%s(%s) caricato ", ADDON_NAME, expansionName)
    L["INPUT_PARM_NIL"] = "ERRORE: Parametro di input nullo. "
    L["INVALID_TYPE"] = "ERRORE: Tipo di dato di input non valido. "
    L["ILLEGAL_OPERATION"]  = "ERRORE: Operazione non supportata. "
    L["UNEXPECTED_VALUE"]   = "ERRORE: Valore inaspettato. "
end

local fileName = "MetricsLocales.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end

--[[ 
English (US): enUS
English (UK): enGB
German: deDE
French: frFR
Spanish (Spain): esES
Spanish (Mexico): esMX
Russian: ruRU
Korean: koKR
Chinese (Simplified): zhCN
Chinese (Traditional): zhTW
Italian: itIT
Portuguese (Brazil): ptBR
]]
