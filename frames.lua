local _, dt = ...
local C, L = unpack(dt)

local eventFrame = CreateFrame("Frame")
eventFrame.elapsed = 0
eventFrame:SetScript("OnUpdate", function(self,elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= 0.1 then
		C:UpdateText()
		self.elapsed = 0
	end
end)
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
	local time = dt.GetDeathTime()
	text:SetText(time and format("%.1f",time), "")
end

dt:AddInitFunc(function()
	C:SetFrames()
end)
