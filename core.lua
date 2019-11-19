-- return

--- config ---

local dmgTime = 3
local dmgTimeStep = 0.5

--- end of config ---
local C = {}

--Use [GUID] = {[time] = healthlost, nstart = x, nend = y}
local healthChangeTbl = {}

local tobeAddedTbl = {}
local donotWipeTbl = {}
local reuseTbl = {}

local steps = math.ceil(dmgTime / dmgTimeStep)
-- 3 seconds max, start from x to 3 then from 0 to x-0.5
-- return cur (== new nend), new nstart
local function GetCur(guid)
	if not healthChangeTbl[guid].nstart then return 1, 1
	-- when not full, add one more and keep start at 1
	elseif healthChangeTbl[guid].nstart == 1 and healthChangeTbl[guid].nend < steps then return healthChangeTbl[guid].nend+1, 1
	else
		local a,b = healthChangeTbl[guid].nend+1, healthChangeTbl[guid].nend+2
		if a > steps then a = a-steps end
		if b > steps then b = b-steps end
		return a, b
	end
end

-- Tbl pool to recycle
local function newHealthTbl()
	local t = next(reuseTbl)
	if t then
		reuseTbl[t] = nil
		return t
	else
		return {}
	end
end

local function wipeTbl(parentTbl,idx)
	local t = parentTbl[idx]
	if not t then return end
	parentTbl[idx] = nil
	for k in pairs(t) do t[k] = nil end
	reuseTbl[t] = true
end

local function recordCLEU(guid, dirc, amount, timestamp)
	tobeAddedTbl[guid] = (tobeAddedTbl[guid] or 0) + dirc*amount
	donotWipeTbl[guid] = true
end

local timeFrmae = CreateFrame("Frame")
timeFrmae.elapsed1, timeFrmae.elapsed2, timeFrmae.elapsed3 = 0, 0, 0
timeFrmae:SetScript("OnUpdate", function(self,elapsed)
	self.elapsed1 = self.elapsed1 + elapsed
	self.elapsed2 = self.elapsed2 + elapsed
	self.elapsed3 = self.elapsed3 + elapsed
	if self.elapsed1 >= dmgTimeStep then
		for guid, healthChange in pairs(tobeAddedTbl) do
			if not healthChangeTbl[guid] then healthChangeTbl[guid] = newHealthTbl() end
			local cur, new_nstart = GetCur(guid)
			healthChangeTbl[guid][cur] = healthChange
			healthChangeTbl[guid].nstart = new_nstart
			healthChangeTbl[guid].nend = cur
			tobeAddedTbl[guid] = 0
		end
		self.elapsed1 = 0
	end
	if self.elapsed2 >= 10 then
		for guid in pairs(tobeAddedTbl) do if not donotWipeTbl[guid] then tobeAddedTbl[guid] = nil end end
		for guid in pairs(healthChangeTbl) do if not donotWipeTbl[guid] then wipeTbl(healthChangeTbl,guid) end end
		for guid in pairs(donotWipeTbl) do donotWipeTbl[guid] = nil end
		self.elapsed2 = 0
	end
	if self.elapsed3 >= 0.1 then
		C.UpdateTimer()
		self.elapsed3 = 0
	end
end)

local CLEUFrame = CreateFrame("Frame")
CLEUFrame:SetScript("OnEvent", function()
	local timestamp, Event, _, sourceGUID, _, sourceFlags, _, destGUID, destName, destFlags, _, arg1, arg2, arg3, arg4, arg5, arg6, arg7, _, _, arg10 = CombatLogGetCurrentEventInfo()
	if bit.band(destFlags,bit.bor(COMBATLOG_OBJECT_AFFILIATION_OUTSIDER, COMBATLOG_OBJECT_REACTION_NEUTRAL, COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_CONTROL_NPC, COMBATLOG_OBJECT_TYPE_NPC)) <= 0 then return end
	if Event == "SWING_DAMAGE" then
		recordCLEU(destGUID, -1, arg1, timestamp)
	elseif Event == "SPELL_DAMAGE" or Event == "RANGE_DAMAGE" or Event == "SPELL_PERIODIC_DAMAGE" then
		recordCLEU(destGUID, -1, arg4, timestamp)
	elseif Event == "SPELL_HEAL" or Event == "SPELL_PERIODIC_HEAL" then
		recordCLEU(destGUID, 1, arg4, timestamp)
	end
end)
CLEUFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function GetDeathTime()
	local guid = UnitGUID("target")
	if not guid or not healthChangeTbl[guid] then return end
	local sum = 0
	for _, change in ipairs(healthChangeTbl[guid]) do
		sum = sum + change
	end
	local time = UnitHealth("target")/(- sum / dmgTime)
	if time <= 0 then return ""
	else return format("%.1f",time) end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", GetDeathTime)
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local frame = CreateFrame("Frame",nil,UIParent)
frame:SetPoint("CENTER",200,-200)
frame:SetSize(150,25)
local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
local textFont = text:GetFont()
text:SetFont(textFont, 15)
text:SetAllPoints(frame)

function C.UpdateTimer()
	text:SetText(GetDeathTime())
end
