local _, dt = ...
local _, _, G = unpack(dt)

local band, CombatLogGetCurrentEventInfo, ipairs, next, UnitGUID, UnitHealth = bit.band, CombatLogGetCurrentEventInfo, ipairs, next, UnitGUID, UnitHealth

--Use [GUID] = {[time] = healthlost, cur = next_cur}
local healthChangeTbl = {}

local tobeAddedTbl = {}
local donotWipeTbl = {}
local reuseTbl = {}

-- Tbl pool to recycle
local function NewHealthTbl()
	local t = next(reuseTbl)
	if t then
		reuseTbl[t] = nil
		return t
	else
		return {}
	end
end

local function WipeTbl(parentTbl,idx)
	local t = parentTbl[idx]
	if not t then return end
	parentTbl[idx] = nil
	for k in next, t do t[k] = nil end
	reuseTbl[t] = true
end

local mask_outsider_npc_npc = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_TYPE_MASK)
local flag_outsider_npc_npc = bit.bor(COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,COMBATLOG_OBJECT_CONTROL_NPC,COMBATLOG_OBJECT_TYPE_NPC)
local flag_hostile_neutral = bit.bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_REACTION_NEUTRAL)

local eventFrame = CreateFrame("Frame")
eventFrame.elapsed1, eventFrame.elapsed2 = 0, 0
eventFrame:SetScript("OnUpdate", function(self,elapsed)
	self.elapsed1 = self.elapsed1 + elapsed
	self.elapsed2 = self.elapsed2 + elapsed
	if self.elapsed1 >= 0.3 then
		for guid, healthChange in next, tobeAddedTbl do
			if not healthChangeTbl[guid] then healthChangeTbl[guid] = NewHealthTbl() end
			local t = healthChangeTbl[guid]
			-- 3 seconds max, start from x to 3 then from 0 to x-0.3
			local cur
			if not t.cur then cur = 1
			else
				cur = t.cur+1
				if cur > 10 then cur = cur-10 end
			end
			t[cur] = healthChange
			t.cur = cur
			if healthChange ~= 0 then donotWipeTbl[guid] = true end
			tobeAddedTbl[guid] = 0
		end
		self.elapsed1 = self.elapsed1 - 0.3
	end
	if self.elapsed2 >= 10 then
		for guid in next, tobeAddedTbl do if not donotWipeTbl[guid] then tobeAddedTbl[guid] = nil end end
		for guid in next, healthChangeTbl do if not donotWipeTbl[guid] then WipeTbl(healthChangeTbl,guid) end end
		for guid in next, donotWipeTbl do donotWipeTbl[guid] = nil end
		self.elapsed2 = 0
	end
end)
eventFrame:SetScript("OnEvent", function()
	local _, Event, _, _, _, _, _, destGUID, _, destFlags, _, arg1, _, _, arg4 = CombatLogGetCurrentEventInfo()
	if not (band(destFlags, mask_outsider_npc_npc) == flag_outsider_npc_npc and band(destFlags, flag_hostile_neutral) > 0) then return end
	if Event == "SWING_DAMAGE" then
		tobeAddedTbl[destGUID] = (tobeAddedTbl[destGUID] or 0) - arg1
	elseif Event == "SPELL_DAMAGE" or Event == "RANGE_DAMAGE" or Event == "SPELL_PERIODIC_DAMAGE" then
		tobeAddedTbl[destGUID] = (tobeAddedTbl[destGUID] or 0) - arg4
	elseif Event == "SPELL_HEAL" or Event == "SPELL_PERIODIC_HEAL" then
		tobeAddedTbl[destGUID] = (tobeAddedTbl[destGUID] or 0) + arg4
	end
end)

function G.GetDeathTime(unit)
	if not unit then unit = "target" end
	local guid, health = UnitGUID(unit), UnitHealth(unit)
	if not guid or not healthChangeTbl[guid] then return end
	local sum, times = 0, 0
	for _, change in ipairs(healthChangeTbl[guid]) do
		sum = sum + change
		times = times + 1
	end
	local deathtime = health / (sum / (times * -0.3))
	if deathtime <= 0 then return
	else return deathtime end
end

dt:AddInitFunc(function()
	eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)
