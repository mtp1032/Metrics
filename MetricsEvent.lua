--=================================================================================
-- Addon: Metrics
-- Filename: MetricsEvent.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
Metrics = Metrics or {}
Metrics.Event = {}

local event = Metrics.Event

local utils     = LibStub:GetLibrary("UtilsLib")
local thread    = LibStub:GetLibrary("WoWThreads")
local core      = Metrics.MetricsCore 
local L         = Metrics.Locales.L  
local notify	= Metrics.MetricsCombatNotify
local target 	= Metrics.MetricsTargetDummy
local event 	= Metrics.Event 
local display   = Metrics.Display
local soundPlayed = false

------------------------------------------------------------
---                   code begins here                    --
------------------------------------------------------------
local COMBAT_ENABLED 		= false
local activeTargetGUIDs 	= {}
local encounterSubEvents 	= {}
local encounterSpellRecords = {}
local display_h = nil
local encounterId = 1
local previousId = 0

------ INDICES FOR THE CLEU subEvent TABLE----
local CLEU_TIMESTAMP		= 1		
local CLEU_SUBEVENT			= 2
local CLEU_HIDECASTER		= 3
local CLEU_SOURCEGUID 		= 4	
local CLEU_SOURCENAME		= 5 	
local CLEU_SOURCEFLAGS		= 6 	
local CLEU_SOURCERAIDFLAGS	= 7	
local CLEU_TARGETGUID		= 8 	
local CLEU_TARGETNAME		= 9 	
local CLEU_TARGETFLAGS		= 10 	
local CLEU_TARGETRAIDFLAGS	= 11
local CLEU_SPELLID			= 12
local CLEU_SPELLNAME		= 13
local CLEU_SPELLSCHOOL		= 14
local CLEU_DMG_AMOUNT		= 15
local CLEU_HEAL_AMOUNT		= CLEU_DMG_AMOUNT
local CLEU_MISS_TYPE				= CLEU_DMG_AMOUNT
local CLEU_AURA_TYPE				= CLEU_DMG_AMOUNT
local CLEU_DMG_OVERKILL		= 16
local CLEU_OVERHEAL					= CLEU_DMG_OVERKILL
local CLEU_MISS_OFFHAND				= CLEU_DMG_OVERKILL	
local CLEU_AURA_AMOUNT				= CLEU_DMG_OVERKILL
local CLEU_DMG_SCHOOL		= 17
local CLEU_MISS_AMOUNT				= CLEU_DMG_SCHOOL
local CLEU_HEAL_ABSORBED			= CLEU_DMG_SCHOOL
local CLEU_DMG_RESISTED		= 18
local CLEU_MISS_CRITICAL			= CLEU_DMG_RESISTED
local CLEU_HEAL_IS_CRIT				= CLEU_DMG_RESISTED
local CLEU_DMG_BLOCKED		= 19
local CLEU_DMG_ABSORBED		= 20
local CLEU_DMG_IS_CRIT		= 21 -- boolean
local CLEU_DMG_GLANCING		= 22 -- boolean
local CLEU_DMG_CRUSHING		= 23 -- boolean
local CLEU_DMG_IS_OFFHAND 	= 24 -- boolean

local function dbgDumpSubEvent( subEvent ) -- DUMPS A SUB EVENT IN A COMMA DELIMITED FORMAT.
	local dataType = nil
	
	for i = CLEU_TIMESTAMP, CLEU_DMG_IS_OFFHAND do
		if subEvent[i] ~= nil then
			local value = nil
			dataType = type(subEvent[i])

			if type(subEvent[i]) == "number" or type(subEvent[i] == "boolean") then
				value = tostring( subEvent[i] )
			end
			if i == 1 then
				utils:postMsg( string.format("arg[%d] %s, ", i, value ))
			else
				utils:postMsg( string.format(" arg[%d] %s, ", i, value ))
			end
		elseif subEvent[i] == EMPTY_STR then
			utils:postMsg( string.format(" arg[%d] EMPTY, ", i))
		else
			utils:postMsg( string.format(" arg[%d] NIL, ", i))
		end
	end
	utils:postMsg( string.format("\n\n"))
end	

local SIG_ALERT         = thread.SIG_ALERT
local SIG_GET_DATA      = thread.SIG_GET_DATA
local SIG_SEND_DATA     = thread.SIG_SEND_DATA
local SIG_BEGIN         = thread.SIG_BEGIN
local SIG_HALT          = thread.SIG_HALT
local SIG_TERMINATE     = thread.SIG_TERMINATE
local SIG_IS_COMPLETE   = thread.SIG_IS_COMPLETE
local SIG_SUCCESS       = thread.SIG_SUCCESS
local SIG_FAILURE       = thread.SIG_FAILURE  
local SIG_READY         = thread.SIG_READY 
local SIG_WAKEUP        = thread.SIG_WAKEUP 
local SIG_CALLBACK      = thread.SIG_CALLBACK
local SIG_NONE_PENDING  = thread.SIG_NONE_PENDING

local spellSchoolNames = {
	{1,  "Physical"},
	{2,  "Holy"},
	{3,  "Holystrike"},
	{4,  "Fire"},
	{5,  "Flamestrike"},
	{6,  "Holyfire (Radiant"},
	{8,  "Nature"},
	{9,  "Stormstrike"},
	{10, "Holystorm"},
	{12, "Firestorm"},
	{16, "Frost"},
	{17, "Froststrike"},
	{18, "Holyfrost"},
	{20, "Frostfire"},
	{24, "Froststorm"},
	{28, "Elemental"},
	{32, "Shadow"},
	{33, "Shadowstrike"},
	{34, "Shadowlight"},
	{36, "Shadowflame"},
	{40, "Shadowstorm(Plague)"},
	{48, "Shadowfrost"},
	{64, "Arcane"},
	{65, "Spellstrike"},
	{66, "Divine"},
	{68, "Spellfire"},
	{72, "Spellstorm"},
	{80, "Spellfrost"},
	{96, "Spellshadow"},
	{124, "Chromatic(Chaos)"},
	{126, "Magic"},
	{127, "Chaos"}
}
local function getSpellSchool( index )
	for i, v in ipairs(spellSchoolNames) do
		if v[1] == index then return v[2] end
	end
	return nil
end

local function isDamageSubEvent( subEventName )
	local isValid = false
	local str = string.sub( subEventName, -7 )
	if str == "_DAMAGE" then 
		isValid = true
	end	
	return isValid
end
local function isHealSubEvent( subEventName )
	local isValid = false
	local str = string.sub( subEventName, -5 )
	if str == "_HEAL" then 
		isValid = true
	end

	return isValid
end
local function isAuraSubEvent( subEventName )
	local isValid = false	
	local str = string.sub( subEventName, 1,11 )
	if str == "SPELL_AURA_" then 
		isValid = true
	end
	return isValid
end
local function isMissSubEvent( subEventName )
	local isValid = false
	local str = string.sub( subEventName, -5 )
	if str == "_MISSED" then 
		isValid = true 
	end
	return isValid
end
----------------------- ENCOUNTER FUNCTIONS --------------------
-- Damage Record
local DMG_SPELLNAME		    = 1
local DMG_SPELLSCHOOL	    = 2
local DMG_SUBEVENT			= 3
local DMG_AMOUNT	    	= 4 -- this is the total damage
local DMG_CRIT_AMOUNT		= 5	-- this is the total crit damage
local DMG_NUM_CASTS     	= 6 
local DMG_OVERKILL  	    = 7
local DMG_RESISTED  	    = 8
local DMG_BLOCKED   	    = 9
local DMG_ABSORBED  	    = 10
-- Heal Record
local HEAL_SPELLNAME		= 1
local HEAL_SPELLSCHOOL	    = 2
local HEAL_SUBEVENT	= 3
local HEAL_AMOUNT			= 4 -- this is the total healing
local HEAL_CRIT_AMOUNT	    = 5 -- this is the total crit healing
local HEAL_NUM_CASTS   		= 6 
local HEAL_OVERHEALING		= 7

local function createDmgRecord( subEvent ) -- create a single damage record from a subEvent block
	local dmgRecord	= {EMPTY_STR, EMPTY_STR, EMPTY_STR, 0, 0, 0, 0, 0, 0, 0 }
	local spellName = nil
	local spellSchool = nil 

	local offset	= 0
	if subEvent[CLEU_SUBEVENT] == "SWING_DAMAGE" then
		offset = 3
	end
	
	local isCritical	= subEvent[ CLEU_DMG_IS_CRIT 	- offset]
	local overkill 		= subEvent[ CLEU_DMG_OVERKILL - offset]
	local resisted 		= subEvent[ CLEU_DMG_RESISTED - offset]
	local blocked 		= subEvent[ CLEU_DMG_BLOCKED 	- offset]
	local absorbed 		= subEvent[ CLEU_DMG_ABSORBED	- offset]
	local dmgAmount		= subEvent[ CLEU_DMG_AMOUNT 	- offset]

	if overkill == nil then
		overkill = 0
	end
	if resisted == nil then
		resisted = 0
	end
	if blocked == nil then
		blocked	= 0
	end
	if absorbed == nil then
		absorbed = 0
	end

	dmgRecord[DMG_OVERKILL] 	= overkill
	dmgRecord[DMG_RESISTED] 	= resisted
	dmgRecord[DMG_BLOCKED]  	= blocked
	dmgRecord[DMG_ABSORBED] 	= absorbed 

	if isCritical then
		dmgRecord[DMG_CRIT_AMOUNT]		= dmgAmount -- accum damage from crit casts
	else
		dmgRecord[DMG_AMOUNT]	= dmgAmount 	-- accum only normal, non-crit damage
	end

	dmgRecord[DMG_SPELLNAME] 	= spellName
	dmgRecord[DMG_SUBEVENT] 	= subEvent[CLEU_SUBEVENT]

	if offset == 3 then 
		dmgRecord[DMG_SPELLNAME] 	= "Melee Swing"
		dmgRecord[DMG_SPELLSCHOOL]  = "Physical"
	else
		dmgRecord[DMG_SPELLNAME] 	= subEvent[CLEU_SPELLNAME]
		dmgRecord[DMG_SPELLSCHOOL]	= getSpellSchool( subEvent[CLEU_SPELLSCHOOL] ) 
	end

	dmgRecord[DMG_NUM_CASTS] = 1
    return dmgRecord 
end
local function sumDmgRecords( sum, rec )
	sum[DMG_AMOUNT]			= sum[DMG_AMOUNT] 		+ rec[DMG_AMOUNT]
	sum[DMG_CRIT_AMOUNT]	= sum[DMG_CRIT_AMOUNT]  + rec[DMG_CRIT_AMOUNT]
	sum[DMG_NUM_CASTS]		= sum[DMG_NUM_CASTS] 	+ 	1
	sum[DMG_OVERKILL]		= sum[DMG_OVERKILL] 	+ rec[DMG_OVERKILL]
	-- sum[DMG_RESISTED]		= sum[DMG_RESISTED] 	+ rec[DMG_RESISTED]
	-- sum[DMG_BLOCKED]		= sum[DMG_BLOCKED] 		+ rec[DMG_BLOCKED]
	-- sum[DMG_ABSORBED]		= sum[DMG_ABSORBED] 	+ rec[DMG_ABSORBED]
	return sum
end
-- HEAL RECORD
local function createHealRecord( subEvent ) -- create a single damage record from a subEvent block
	local healRecord	= {EMPTY_STR, EMPTY_STR, EMPTY_STR, 0, 0, 1, 0 }

	healRecord[HEAL_SPELLNAME] 		= subEvent[CLEU_SPELLNAME]
	healRecord[HEAL_SPELLSCHOOL]	= getSpellSchool( subEvent[CLEU_SPELLSCHOOL] ) 
	healRecord[HEAL_SUBEVENT]	  	= subEvent[CLEU_SUBEVENT]

	healRecord[HEAL_AMOUNT]	= subEvent[CLEU_HEAL_AMOUNT] -- i.e., total healing, including normal and crit heals.
	if subEvent[CLEU_HEAL_IS_CRIT] then
		healRecord[HEAL_CRIT_AMOUNT]	= subEvent[CLEU_HEAL_AMOUNT] -- accum only damage from crits
	end
	healRecord[HEAL_NUM_CASTS]	= 1

	if subEvent[CLEU_OVERHEAL] == nil then
		healRecord[HEAL_OVERHEALING] = 0
	else
		healRecord[HEAL_OVERHEALING] = subEvent[CLEU_OVERHEAL]
	end
	return healRecord 
end
local function sumHealRecords( sum, rec )
	sum[HEAL_AMOUNT]		= sum[HEAL_AMOUNT] 		+ rec[HEAL_AMOUNT]
	sum[HEAL_CRIT_AMOUNT]	= sum[HEAL_CRIT_AMOUNT] + rec[HEAL_CRIT_AMOUNT]
	sum[HEAL_NUM_CASTS]		= sum[HEAL_NUM_CASTS] 	+ 1
	sum[HEAL_OVERHEALING]	= sum[HEAL_OVERHEALING] + rec[HEAL_OVERHEALING]
	return sum
end
-----------------------------------------------------------
local function isUnitValid( subEvent )	-- checks that the unit is the player or the player's pet or guardien	
	if subEvent[CLEU_SOURCENAME] == nil then return end

	local playerName, realm = UnitFullName("Player")

	local playerPet = UnitName("Pet")

	if playerName == subEvent[CLEU_SOURCENAME] then
		return true
	end

	local petName = UnitName("Pet")
	if petName ~= nil and playerPet == subEvent[CLEU_SOURCENAME] then
		return true
	end
	
	-- Return true if this is the player's pet
	local n = bit.band(subEvent[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_TYPE_PET )
	local m = bit.band( subEvent[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_AFFILIATION_MINE)
	-- if n == 4096 and m == 1 then
	if n > 0 and m == 1 then
		return true
	end
	-- Return true if this is the player's guardian
	local n = bit.band(subEvent[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_TYPE_GUARDIAN )
	local m = bit.band( subEvent[CLEU_SOURCEFLAGS], COMBATLOG_OBJECT_AFFILIATION_MINE)
	-- if n == 8192 and m == 1 then
	if n > 0 and m == 1 then
		return true
	end
	return false
end
-- Only permit subevents whose name is included in the
-- conditional statement.
local function filterSubEvents( subEvent )
	local subEventName = subEvent[CLEU_SUBEVENT]
	-- log each of the following subEvents
	if 	subEventName ~= "SWING_DAMAGE" and
		subEventName ~= "RANGE_DAMAGE" and
		subEventName ~= "SPELL_DAMAGE" and 
		subEventName ~= "SPELL_PERIODIC_DAMAGE" and

		subEventName ~= "SWING_MISSED" and
		subEventName ~= "RANGE_MISSED" and
		subEventName ~= "SPELL_MISSED" and 
		subEventName ~= "SPELL_PERIOD_MISSED" and

		subEventName ~= "SPELL_HEAL" and
		subEventName ~= "SPELL_PERIODIC_HEAL" and
		subEventName ~= "SPELL_LEECH" and

		subEventName ~= "UNIT_DIED" and
		subEventName ~= "PARTY_KILL" and

		subEvent ~= "SPELL_AURA_APPLIED" and		-- crowd control spell 
		subEvent ~= "SPELL_AURA_APPLIED_DOSE" and
		subEvent ~= "SPELL_AURA_REMOVED" and		-- crowd control spell expired
		subEvent ~= "SPELL_AURA_REMOVED_DOSE" and
		subEvent ~= "SPELL_AURA_REFRESH" and
		subEvent ~= "SPELL_AURA_BROKEN" and			-- broken because of melee action
		subEvent ~= "SPELL_AURA_BROKEN_SPELL" then	-- broken by spell
			-- do nothing. It's an event of no interest
		return false
	end
	return true
end

function event:setDisplayThread( thread_h )
	display_h = thread_h
end
-- Function to sort subEvents by timestamp
local function sortSubEventsByTimestamp()
    table.sort(encounterSubEvents, function(a, b)
        return a[1] < b[1]
    end)
end
local function sortSpellRecordsByDamage( records )
	table.sort( records, function(a, b)
        return a[4] > b[4]
    end)
end
local function reportEncounter( index )

	if encounterSubEvents[index] == nil then
		local encounterRecord = string.format("Encounter[%d] Target was killed with 1 shot. No damage could be collected.\n", index )
		utils:postMsg( encounterRecord )
		return nil
	end

	local dmgRecord = nil
	local healRecord = nil
	local totalDamage = 0
	local totalHealing = 0

		-- order the subEvents according to their timestamp and determine 
	-- the encounters elapsed time.
	sortSubEventsByTimestamp()

	-- collect all the subEvents from this encounter (by index) into a single table,
	-- subEvents
	local subEvents = encounterSubEvents[index]

	local num = #subEvents
	
	local elapsedTime = subEvents[num][1] - subEvents[1][1]

	-- now, convert the subEvents to damage and healing records.
	for i = 1, num do
		local subEvent = subEvents[i]

		local enteredInTable = false
		if isDamageSubEvent( subEvent[CLEU_SUBEVENT]) then
			dmgRecord = createDmgRecord( subEvent )
			for _, entry in ipairs( encounterSpellRecords ) do
				if dmgRecord[DMG_SPELLNAME] == entry[DMG_SPELLNAME] then
					entry = sumDmgRecords( entry, dmgRecord)
					enteredInTable = true
				end
			end
			if not enteredInTable then
				table.insert( encounterSpellRecords, dmgRecord )
			end
		end

		if isHealSubEvent( subEvent[CLEU_SUBEVENT]) then
			healRecord = createHealRecord( subEvent )
			for _, entry in ipairs( encounterSpellRecords ) do
				if healRecord[HEAL_SPELLNAME] == entry[HEAL_SPELLNAME] then
					entry = sumHealRecords( entry, healRecord )	
					enteredInTable = true
				end
			end	
			if not enteredInTable then
				table.insert( encounterSpellRecords, healRecord )
			end
		end
	end

	local stringRecords = {}
	sortSpellRecordsByDamage( encounterSpellRecords )
	for i = 1, #encounterSpellRecords do
		local rec = encounterSpellRecords[i]
	end
	for i = 1, #encounterSpellRecords do
		local spellRecord = encounterSpellRecords[i]
		local str = nil
		if isDamageSubEvent( spellRecord[3]) then
			totalDamage = totalDamage + spellRecord[DMG_AMOUNT]
			str = string.format( "   %s, Damage: %d, Casts: %d (DPC %0.2f) \n", 
									spellRecord[1], spellRecord[4], spellRecord[6], spellRecord[4]/spellRecord[DMG_NUM_CASTS] )
		end
		if isHealSubEvent( spellRecord[3]) then
			totalHealing = totalHealing + spellRecord[4]
			str = string.format( "   %s, Healing: %d Casts: %d \n", 
			spellRecord[1], spellRecord[4], spellRecord[6] )
		end
		stringRecords[i] = str 
	end

	local dps = totalDamage/elapsedTime
	local encounterRecord = string.format("Encounter[%d] Elapsed Time: %0.2f seconds, Total Damage: %d (DPS %0.2f)\n", encounterId, elapsedTime, totalDamage, dps)
	for i = 1, #stringRecords do
		encounterRecord = encounterRecord .. stringRecords[i] 
	end
	utils:postMsg( string.format("%s\n", encounterRecord ))
end


-- Function to add subEvent to an encounter
local function addSubEventToEncounter( index, subEvent)
	if encounterSubEvents[index] == nil then
        encounterSubEvents[index] = {}
    end
    table.insert(encounterSubEvents[index], subEvent)
end
function event:enableCombat()
	COMBAT_ENABLED = true
end

local eventFrame = CreateFrame("Frame" )
eventFrame:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent( "PLAYER_REGEN_DISABLED" )
eventFrame:SetScript("OnEvent",
function( self, event, ... )
	local arg1, arg2, arg3, arg4 = ...

	if event == "PLAYER_REGEN_DISABLED" then
		if COMBAT_ENABLED == true then return end

		COMBAT_ENABLED = true
		display:setCombatFlag( COMBAT_ENABLED )
		notify:combatStatusAlert("Entering Combat", 5, 0 )
	end
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then

		-- if not display_h then return end
		local subEvent = {CombatLogGetCurrentEventInfo()}

		if filterSubEvents( subEvent ) == false then
			return 
		end
		-- return if this unit (player, pet, or guardian) is not the source or target of the attack.
		if isUnitValid( subEvent ) == false then
			return
		end

		if not COMBAT_ENABLED then return end

		-- this code block is relevant only for live encounters
		-- if subEvent[CLEU_SUBEVENT] == "UNIT_DIED" or subEvent[CLEU_SUBEVENT] == "PARTY_KILL" then
		if subEvent[CLEU_SUBEVENT] == "UNIT_DIED" or subEvent[CLEU_SUBEVENT] == "PARTY_KILL" then
			-- dbgDumpSubEvent( subEvent )
			-- print( utils:dbgPrefix(), subEvent[CLEU_TARGETNAME], subEvent[CLEU_TARGETGUID])
			-- print( utils:dbgPrefix(), target:numberOfTargetGUIDs() )
			
			local remainingTargetGUIDs = target:removeGUID( subEvent[CLEU_TARGETGUID] )

			if remainingTargetGUIDs == 0 then		-- COMBAT IS OVER.
				COMBAT_ENABLED = false
				display:setCombatFlag( COMBAT_ENABLED )
				notify:combatStatusAlert("Leaving Combat", 5, 0 )
				PlaySound( SOUNDKIT.READY_CHECK )
				reportEncounter( encounterId )
				utils:dbgPrint()
				wipe( encounterSubEvents )
				encounterId = encounterId + 1
				return
			end
		end

		-- local targetGUID = subEvent[CLEU_TARGETGUID]
		-- local targetName = subEvent[CLEU_TARGETNAME]
		
		if  isDamageSubEvent(subEvent[CLEU_SUBEVENT]) then
			if not target:isDummy( subEvent[CLEU_TARGETNAME]) then
				target:insertTargetGUID( subEvent[CLEU_TARGETGUID])
			end

			local wasSent, result = thread:sendSignal( display_h, SIG_ALERT, subEvent )
			assert( wasSent == true )
			assert( result == nil )

			if target:isDummy( subEvent[CLEU_TARGETNAME]) then
				local remainingTargetGUIDs = target:updateHealthBar( subEvent )
				if remainingTargetGUIDs == 0 then		-- COMBAT IS OVER.
					COMBAT_ENABLED = false
	
					target:removeHealthBars()
					display:setCombatFlag( COMBAT_ENABLED )
					notify:combatStatusAlert("Leaving Combat", 5, 0 )
					PlaySound( SOUNDKIT.READY_CHECK )
					reportEncounter(  encounterId )
					wipe( encounterSubEvents )
					encounterId = encounterId + 1
					return
				end
				addSubEventToEncounter( encounterId, subEvent )
				return
			end

			addSubEventToEncounter( encounterId, subEvent )
		end
		if  isHealSubEvent( subEvent[CLEU_SUBEVENT]) then
			addSubEventToEncounter( encounterId, subEvent )
			local wasSent, result = thread:sendSignal( display_h, SIG_ALERT, subEvent )
			assert( wasSent ~= nil )
			assert( result == nil )
			return
		end
		if isAuraSubEvent( subEvent[CLEU_SUBEVENT]) or isMissSubEvent( subEvent[CLEU_SUBEVENT]) then
			-- TO BE COMPLETED LATER
			return
		end
	end
end)

local fileName = "MetricsEvent.lua"
if core:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end
