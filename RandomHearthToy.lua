local locale = GetLocale()
local Locales = AllHearthToyIndex.Locales

-- Define fallback order (e.g., esMX -> esES -> enUS)
local activeLocale
if locale == "esMX" or locale == "esES" then
    activeLocale = Locales.esES or Locales.enUS
elseif locale == "deDE" then
	activeLocale = Locales.deDE or Locales.enUS
elseif locale == "frFR" then
    activeLocale = Locales.frFR or Locales.enUS
elseif locale == "zhCN" then
    activeLocale = Locales.zhCN or Locales.enUS
elseif locale == "zhTW" then
	activeLocale = Locales.zhTW or Locales.enUS
elseif locale == "ruRU" then
    activeLocale = Locales.ruRU or Locales.enUS
else
    activeLocale = Locales.enUS -- Default to English
end


-- Assign the returned table to your addon's variable
local AllHearthToyIndex = activeLocale

-- Ensure Ace3 is loaded
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
RandomHearthToySettings = {} --Settings for the addon

local function InitializeDB()
	local defaults = {
		profile = {}
	}
	for key, _ in pairs(AllHearthToyIndex) do
		defaults.profile[key] = true
	end
	RandomHearthToySettings = LibStub("AceDB-3.0"):New("RandomHearthToyDB", defaults, true)
end

-- Define your addon
local RandomHearthToy = AceAddon:NewAddon("RandomHearthToy", "AceConsole-3.0")

local function registerOptions()
	InitializeDB()
	-- Define your options table
	local options = {
		name = "RandomHearthToy Options",
		type = "group",
		args = {}
	}
	-- For each hearthstone, create an option
	for k, hearthstone in pairs(AllHearthToyIndex) do
		options.args["hearthstone" .. k] = {
				type = "toggle",
				name = tostring(hearthstone["name"]),
				desc = "Toggle " .. tostring(hearthstone["name"]),
				get = function() return RandomHearthToySettings.profile[k] end,
				set = function(_, value) RandomHearthToySettings.profile[k] = value end,
		}
	end
	-- Register your options table with AceConfig
	AceConfig:RegisterOptionsTable("RandomHearthToy", options)

	-- Add the options table to the Blizzard Interface Options
	AceConfigDialog:AddToBlizOptions("RandomHearthToy", "RandomHearthToy")
end

local UsableHearthToyIndex = {} --Usable toys
local RHTIndex = false --Macro index
RHT = {} --Setup for button and timeout frame
local RHTInitialized = false
local macroVersion = 1 -- macro version to know if we need to forcefully update users
local needsOne = GetCVar("ActionButtonUseKeyDown")

local SetRandomHearthToy
local GetLearnedStones
local GetMacroIndex
local CheckMacroIndex
local GenMacro
local RemoveStone
local SpellcastUpdate
local RandomKey

-- Setting up an invisible button named RHTB.  Toys can only be used through a button click, so we need one for the macro to click.
local frame = CreateFrame("Frame")
RHT.b = CreateFrame("Button","RHTB",nil,"SecureActionButtonTemplate")
RHT.b:SetAttribute("type","item")
-- Setting up a frame to wait and see if the toybox is loaded before getting stones on login.
local timeOut = 10 --Delay for checking stones.
C_Timer.After(timeOut, function()
	local ticker
	ticker = C_Timer.NewTicker(1, function()
		if C_ToyBox.GetNumToys() > 0 then
			GetLearnedStones()
			if RHTInitialized then
				SetRandomHearthToy()
				registerOptions()
				ticker:Cancel()
			end
		end
	end)
end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("LOADING_SCREEN_DISABLED")
-- Spellcast stopping is the check for if a hearthstone has been used.
frame:RegisterEvent("UNIT_SPELLCAST_STOP")

local function Event(self, event, arg1, arg2, arg3)
	if event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
		if RHTInitialized then
			SetRandomHearthToy()
		else
			GetMacroIndex()
		end
	end
	-- When a spell cast stops and it's the player's spell, send the ID to check if it's a stone.
	if event == "UNIT_SPELLCAST_STOP" and arg1 == "player" then
		SpellcastUpdate(arg3)
	end
end

frame:SetScript("OnEvent", Event)

function removeUnwantedStones()
	if RandomHearthToySettings.profile then
		for k, v in pairs(RandomHearthToySettings.profile) do
			if not v then
				RemoveStone(k)
			end
		end
	end
end

-- This is the meat right here.
function SetRandomHearthToy()
	--debugOptions()
	-- Setting the new stone while in combat is bad.
	if not InCombatLockdown() then
		-- Find the macro.
		CheckMacroIndex()
		-- Remove stones based on settings from UsableHearthToyIndex
		removeUnwantedStones()
		-- Rebuild the stone list if it's empty.
		if next(UsableHearthToyIndex) == nil then
			GetLearnedStones()
			removeUnwantedStones()
		end		
		local itemID, toyName = ''
		-- Randomly pick one.
		local itemID = RandomKey(UsableHearthToyIndex)
		local toyName = AllHearthToyIndex[itemID]["name"]
	
		if toyName then
			-- Remove it from the list so we don't pick it again.
			RemoveStone(k)
			-- Write the macro.
			GenMacro(itemID, toyName)
			-- Set button for first use
			if not RHT.b:GetAttribute("item") then RHT.b:SetAttribute("item",toyName) end
		end
	end
end

-- Get stones learned and usable by character
function GetLearnedStones()
	-- Get the current setting for the toybox so we can set it back after we're done.
	for k in pairs(AllHearthToyIndex) do
		if PlayerHasToy(k) then
			UsableHearthToyIndex[k] = 1
		end
	end
	if next(UsableHearthToyIndex) then
		--print "Random Hearthstone Toy: Stones loaded"
		RHTInitialized = true
	end
end

-- We've removed the name from the macro, so now we need to find it so we know which one to edit.
function GetMacroIndex()
	local numg, numc = GetNumMacros()
	for i = 1, numg do
		local macroCont = GetMacroBody(i)
		if(macroCont) then -- apperently there's a chance of not having anything here
			--  Hopefully no other macro ever made has "RHT.b" in it...
			if string.find(macroCont, "RHT.b") then
				-- check if we have the correct macro version, purge it if not 
				-- this fixes issues when the addon got broken and we need people to remake their macros
				if(string.find(macroCont, "#macro version " .. macroVersion)) then
					RHTIndex = i
				else
					DeleteMacro(i)
					print "ATTENTION: Your random hearthstone macro had to be deleted due to an update of the game, a new one was created, please add the new macro to your action bar"
				end
			end
		end
	end
end

-- Have we found the macro yet? Also, make sure the macro we're editing is the right one in case the user rearranged things or deleted it.  If not, go find it.
function CheckMacroIndex()
	local macroCont = GetMacroBody(RHTIndex)
	if macroCont then
		if string.find(macroCont, "RHT.b") then
			return
		end
	end
	GetMacroIndex()
end

-- Macro writing time.
-- if this method is changed, increment macroVersion var
function GenMacro(itemID, toyName)
	-- Did we find the index?  If so, edit that. The macro changes the button to the next stone, but only if we aren't in combat; can't SetAttribute. It then "clicks" the RHTB button
	if RHTIndex then
		EditMacro(RHTIndex, " ", "INV_MISC_QUESTIONMARK", "#showtooltip item:" .. itemID .. "\r#macro version " .. macroVersion .. "\r/run if not InCombatLockdown() then RHT.b:SetAttribute(\"item\",\"" .. toyName .. "\") end\r/click RHTB LeftButton" .. (needsOne == "1" and " 1" or ""))
	else
		-- No macro found, make a new one, get it's ID, then set the toy on the invisble button. This one is named so people can find it on first use.
		CreateMacro("RHT", "INV_MISC_QUESTIONMARK", "#showtooltip item:" .. itemID .. "\r#macro version " .. macroVersion .. "\r/run if not InCombatLockdown() then RHT.b:SetAttribute(\"item\",\"" .. toyName .. "\") end\r/click RHTB LeftButton" .. (needsOne == "1" and " 1" or ""))
		GetMacroIndex()
	end
end

-- Remove stone from the list so we don't use it again. (Here for debugging)
function RemoveStone(k)
	if(UsableHearthToyIndex[k]) then
		UsableHearthToyIndex[k] = nil
	end
end

-- Did a stone get used?
function SpellcastUpdate(spellID)
	if not InCombatLockdown() then
		for k in pairs(AllHearthToyIndex) do
			if spellID == AllHearthToyIndex[k]["spellId"] or spellID == 346060 then -- there are two necrolord spells, adding one here temporarily, should refactor the spell lists soon
				SetRandomHearthToy()
				break
			end
		end
	end
end

-- Code to randomly pick a key from a table.
function RandomKey(t)
	local keys = {}
	for key, value in pairs(t) do
		keys[#keys+1] = key --Store keys in another table.
	end
	if (not #keys) or (#keys < 1) then return 0 end
	index = keys[math.random(1, #keys)]
	return index
end

function debugOptions()
	DevTools_Dump({ RandomHearthToySettings.profile });
end
