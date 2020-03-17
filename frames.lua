local _, dt = ...
local C, L, G = unpack(dt)

local eventFrame = CreateFrame("Frame")
eventFrame.elapsed = 0
eventFrame:SetScript("OnUpdate", function(self,elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= 0.1 then
		C:UpdateTargetText()
		self.elapsed = 0
	end
end)
eventFrame:SetScript("OnEvent", C.UpdateTargetText)

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

function C:SetTargetFrame()
	local font, fontSize = LibStub("LibSharedMedia-3.0"):Fetch("font",self.db.font), self.db.fontSize
	for frame,mover in pairs(self.mover) do
		frame.text:SetFont(font, fontSize, "OUTLINE")
		mover:ClearAllPoints()
		mover:SetPoint(unpack(self.db.mover[frame:GetName()]))
	end
	if C.db.targetFrame then
		DeathTimerFrame:Show()
		eventFrame:Show()
		eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	else
		DeathTimerFrame:Hide()
		eventFrame:Hide()
		eventFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
	end
end

function C:UpdateTargetText()
	local time = G.GetDeathTime()
	if time then
		text:SetFormattedText(C.timeFormatFuncs[C.db.timeFormat](time))
	else
		text:SetText("")
	end
end

dt:AddInitFunc(function()
	C:SetTargetFrame()
end)
