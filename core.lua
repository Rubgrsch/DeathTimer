local _, dt = ...
local C, L = unpack(dt)

local dmgTime = 3
local dmgTimeStep = 0.5

local band, CombatLogGetCurrentEventInfo, ipairs, next, pairs, UnitGUID, UnitHealth = bit.band, CombatLogGetCurrentEventInfo, ipairs, next, pairs, UnitGUID, UnitHealth

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

local function recordCLEU(guid, amount) -- amount: < 0 for damage; > 0 for heal
	tobeAddedTbl[guid] = (tobeAddedTbl[guid] or 0) + amount
	donotWipeTbl[guid] = true
end

local timeFrame = CreateFrame("Frame")
timeFrame.elapsed1, timeFrame.elapsed2, timeFrame.elapsed3 = 0, 0, 0
timeFrame:SetScript("OnUpdate", function(self,elapsed)
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
		C:UpdateText()
		self.elapsed3 = 0
	end
end)

local mask_outsider_npc_npc = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_TYPE_MASK)
local flag_outsider_npc_npc = bit.bor(COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,COMBATLOG_OBJECT_CONTROL_NPC,COMBATLOG_OBJECT_TYPE_NPC)
local flag_hostile_neutral = bit.bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_REACTION_NEUTRAL)

local CLEUFrame = CreateFrame("Frame")
CLEUFrame:SetScript("OnEvent", function()
	local _, Event, _, _, _, _, _, destGUID, _, destFlags, _, arg1, _, _, arg4 = CombatLogGetCurrentEventInfo()
	if not (band(destFlags, mask_outsider_npc_npc) == flag_outsider_npc_npc and band(destFlags, flag_hostile_neutral) > 0) then return end
	if Event == "SWING_DAMAGE" then
		recordCLEU(destGUID, -arg1)
	elseif Event == "SPELL_DAMAGE" or Event == "RANGE_DAMAGE" or Event == "SPELL_PERIODIC_DAMAGE" then
		recordCLEU(destGUID, -arg4)
	elseif Event == "SPELL_HEAL" or Event == "SPELL_PERIODIC_HEAL" then
		recordCLEU(destGUID, arg4)
	end
end)

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
eventFrame:SetScript("OnEvent", C.UpdateText)
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Mover
C.mover = {}
local function moverLock(_,button)
	if button == "RightButton" then
		for f,m in pairs(C.mover) do
			m:Hide()
			C.db.mover[f:GetName()]={"BOTTOMLEFT", m:GetLeft(), m:GetBottom()}
		end
	end
end

local timerMover = CreateFrame("Frame", nil, UIParent)
timerMover:Hide()
timerMover:SetSize(150,25)
timerMover:RegisterForDrag("LeftButton")
timerMover:SetScript("OnDragStart", timerMover.StartMoving)
timerMover:SetScript("OnDragStop", timerMover.StopMovingOrSizing)
timerMover:SetScript("OnMouseDown",moverLock)
timerMover:SetMovable(true)
timerMover:EnableMouse(true)
local moverTexture = timerMover:CreateTexture(nil, "BACKGROUND")
moverTexture:SetColorTexture(1, 1, 0, 0.5)
moverTexture:SetAllPoints(true)
local moverText = timerMover:CreateFontString(nil,"ARTWORK","GameFontHighlightLarge")
moverText:SetPoint("CENTER", timerMover, "CENTER")
moverText:SetText(L["DTFrame"])
local timerFrame = CreateFrame("Frame","DeathTimerFrame",UIParent)
timerFrame:SetSize(150,25)
timerFrame:SetAllPoints(timerMover)
local text = timerFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
local textFont = text:GetFont()
text:SetFont(textFont, 15)
text:SetAllPoints(timerFrame)
timerFrame.text = text
C.mover[timerFrame] = timerMover

function C:SetFrames()
	local font, fontSize = LibStub("LibSharedMedia-3.0"):Fetch("font",self.db.font), self.db.fontSize
	for frame,mover in pairs(self.mover) do
		frame.text:SetFont(font, fontSize, "OUTLINE")
		mover:ClearAllPoints()
		mover:SetPoint(unpack(self.db.mover[frame:GetName()]))
	end
end

function C:UpdateText()
	text:SetText(GetDeathTime())
end

dt:AddInitFunc(function()
	C:SetFrames()
	CLEUFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)
