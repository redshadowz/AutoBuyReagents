local ABR_UnitClass = ({UnitClass("player")})[2]
local merchantIndexes,numReagentsTable
local reagents = {
	["DEATH KNIGHT"] = {},
	["DRUID"] = {},
	["HUNTER"] = {},
	["MAGE"] = { 17020, 17031, 17032 }, -- Arcane Powder, Rune of Teleportation, Rune of Portals
	["PALADIN"] = { 17033, 21177 }, -- Symbol of Divinity, Symbol of Kings
	["PRIEST"] = {},
	["ROGUE"] = {},
	["SHAMAN"] = { 17030 },
	["WARLOCK"] = { 5565, 16583 },
	["WARRIOR"] = {}
}
local rWater = { 159, 1179, 1205, 1708, 1645, 8766 } -- [1]Refreshing Spring Water(1-4), [2]Ice Cold Milk(5-14), [3]Melon Juice(15-24), [4]Sweet Nector(25-34), [5]Moonberry Juice(35-44), [6]Morning Glory Dew(45+)
local rFood = { 117, 2287, 3770, 3771, 4599, 8952} -- [1]Tough Jerky(1-4), [2]Haunch of Meat(5-14), [3]Mutton Chop(15-24), [4]Wild Hog Shank(25-34), [5]Cured Ham Steak(35-44), [6]Roasted Quail(45+)
local rCaster = { DRUID = true, HUNTER = true, PALADIN = true, PRIEST = true, SHAMAN = true, WARLOCK = true, MAGE = true }
local rDruidRebirth = { 17034,17035,17036,17037,17038 }
local rDruidGOTW = { 17021,17026 }
local rPriestPrayer = { 17028,17029 }

function AutoBuyReagents_OnLoad()
	this:RegisterEvent("MERCHANT_SHOW")
end
function AutoBuyReagents_OnEvent()
	if not reagentTable or not reagentTable[1] or not reagentTable[1][1] then reagentTable = { {0,nil},{0,nil},{0,nil},{0,nil} } end
	AutoBuyReagents_GetReagents()
	if rCaster[ABR_UnitClass] then reagents[ABR_UnitClass][4] = rWater[math.min(floor((UnitLevel("player")+15)/10),6)] else reagents[ABR_UnitClass][4] = rFood[math.min(floor((UnitLevel("player")+10)/10),6)] end
	if AutoBuyReagents_DoesMerchantHaveReagents() then
		if AutoBuyReagentsFrame:IsVisible() then AutoBuyReagents_SaveData() end
		AutoBuyReagents_GetCurrentReagents()
		AutoBuyReagents_BuyReagents()
	end
end
function AutoBuyReagents_LoadPresets()
	for i=1,4 do
		if reagents[ABR_UnitClass][i] then
			getglobal("ReagentFont"..i):Show()
			getglobal("ReagentNumBox"..i):Show()
			getglobal("ReagentCheckButton"..i):Show()
			getglobal("ReagentFont"..i):SetText(GetItemInfo(reagents[ABR_UnitClass][i]))
			getglobal("ReagentNumBox"..i):SetText(reagentTable[i][1])
			if reagentTable[i][2] then getglobal("ReagentCheckButton"..i):SetChecked(true) else getglobal("ReagentCheckButton"..i):SetChecked(false) end
		else
			getglobal("ReagentFont"..i):Hide()
			getglobal("ReagentNumBox"..i):Hide()
			getglobal("ReagentCheckButton"..i):Hide()
		end
	end
end
function AutoBuyReagents_Out(text)
	DEFAULT_CHAT_FRAME:AddMessage(text)
end
function AutoBuyReagents_GetSpellInfo(spellName)
    local spellNamei,spellRank,spellCache
    for i=1, 500 do
        spellNamei,spellRank = GetSpellName(i,BOOKTYPE_SPELL);
        if not spellNamei then break end
        if spellNamei == spellName then
            _,_,spellRank = string.find(spellRank, " (%d+)$");
            spellCache = tonumber(spellRank);
        end
    end
    return spellCache;
end
function AutoBuyReagents_GetReagents()
	if ABR_UnitClass == "DRUID" then
		reagents[ABR_UnitClass][1] = rDruidRebirth[AutoBuyReagents_GetSpellInfo("Rebirth")]
		reagents[ABR_UnitClass][2] = rDruidGOTW[AutoBuyReagents_GetSpellInfo("Gift of the Wild")]
		if reagents[ABR_UnitClass][1] and reagents[ABR_UnitClass][1] ~= 17034 then reagents[ABR_UnitClass][3] = 17034 end
	elseif ABR_UnitClass == "PRIEST" then
		reagents[ABR_UnitClass][1] = rPriestPrayer[AutoBuyReagents_GetSpellInfo("Prayer of Fortitude")]
		if reagents[ABR_UnitClass][1] then
			if reagents[ABR_UnitClass][1] ~= 17029 and (AutoBuyReagents_GetSpellInfo("Prayer of Spirit") or AutoBuyReagents_GetSpellInfo("Prayer of Shadow Protection")) then reagents[ABR_UnitClass][2] = 17029 end
		else
			if AutoBuyReagents_GetSpellInfo("Prayer of Spirit") or AutoBuyReagents_GetSpellInfo("Prayer of Shadow Protection") then reagents[ABR_UnitClass][1] = 17029 end
		end
	end
end
function AutoBuyReagents_CorrectReagents()
	for i=1, 4 do
		if not tonumber(getglobal("ReagentNumBox"..i):GetText()) then
			getglobal("ReagentNumBox"..i):SetText("0")
		elseif ABR_UnitClass == "PALADIN" and reagents[ABR_UnitClass][i] == 21177 then
			getglobal("ReagentNumBox"..i):SetText(floor(tonumber(getglobal("ReagentNumBox"..i):GetText())/20)*20)
		end
	end
end
function AutoBuyReagents_SaveData()
	AutoBuyReagents_CorrectReagents()
	for i=1,4 do
		if reagents[ABR_UnitClass][i] then
			reagentTable[i][1] = tonumber(getglobal("ReagentNumBox"..i):GetText())
			reagentTable[i][2] = getglobal("ReagentCheckButton"..i):GetChecked()
		end
	end
end
function AutoBuyReagents_GetCurrentReagents()
	numReagentsTable = {0,0,0,0}
	for bag=0,NUM_BAG_FRAMES do
		for slot=1,GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag,slot) or ""
			for itemID in string.gfind(itemLink, "|c%x+|Hitem:(%d+):%d+:%d+:%d+|h%[.-%]|h|r") do
				for i=1, 4 do
					if reagents[ABR_UnitClass][i] == tonumber(itemID) then
						local _,itemCount = GetContainerItemInfo(bag, slot)
						numReagentsTable[i] = numReagentsTable[i] + itemCount
					end
				end
			end
		end
	end
end
function AutoBuyReagents_DoesMerchantHaveReagents()
	local hasReagents
	merchantIndexes = {}
	for i=1, 4 do
		for index=0, GetMerchantNumItems() do
			if reagents[ABR_UnitClass][i] and GetMerchantItemInfo(index) == GetItemInfo(reagents[ABR_UnitClass][i]) then
				merchantIndexes[i] = index
				hasReagents = true
			end
		end
	end
	return hasReagents
end
function AutoBuyReagents_BuyReagents()
	for i=1, 4 do
		if reagentTable[i][2] and merchantIndexes[i] and numReagentsTable[i] < reagentTable[i][1]  then
			local numBuy = reagentTable[i][1] - numReagentsTable[i]
			local maxBuy = 20;
			local countBy = 20;
			if reagents[ABR_UnitClass][i] == 21177 then maxBuy = 1 countBy = 20 -- Symbol of Kings
			elseif reagents[ABR_UnitClass][i] == 17033 then maxBuy = 5 countBy = 5 -- Symbol of Divinity
			elseif i == 4 then maxBuy = 1 countBy = 5 end -- Water/Food
			while numBuy >= countBy do
				BuyMerchantItem(merchantIndexes[i], maxBuy);
				numBuy = numBuy - countBy;
			end					
			if numBuy < maxBuy and numBuy > 0 then
				BuyMerchantItem( merchantIndexes[i], numBuy);
			end
		end
	end
end
