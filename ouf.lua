local _, dt = ...
local C, L, G = unpack(dt)

local oUF = oUF or ElvUI.oUF
if not oUF then return end
local GetDeathTime = G.GetDeathTime

local function Update(self, _, unit)
    local deathTime = GetDeathTime(unit)
    if deathTime then
        self.dtText:SetFormattedText("%.1f",deathTime)
    else
        self.dtText:SetText("")
	end
end

local function Enable(self,...)
    local element = self.DeathTimer
    
    if element then
        self:RegisterEvent("UNIT_HEALTH", Update)
		self:RegisterEvent("UNIT_HEALTH_FREQUENT", Update)
        self:RegisterEvent("UNIT_MAXHEALTH", Update)

        return true
    end
end

local function Disable(self)
    local element = self.DeathTimer
    if element then
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT", Update)
		self:UnregisterEvent("UNIT_HEALTH", Update)
		self:UnregisterEvent("UNIT_MAXHEALTH", Update)
    end
end

oUF:AddElement("DeathTimer", Update, Enable, Disable)

-- ElvUI

local function BuildElvUIFrame(self, frame)
    if not frame.DeathTimer then
        local font, fontSize = LibStub("LibSharedMedia-3.0"):Fetch("font",1), 13

        frame.DeathTimer = CreateFrame("Frame", nil, frame)
        frame.DeathTimer:SetPoint("BOTTOM",frame,"TOP")
        frame.DeathTimer:SetSize(150,25)
        frame.dtText = frame.DeathTimer:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        frame.dtText:SetFont(font, fontSize, "OUTLINE")
        frame.dtText:SetAllPoints(frame.DeathTimer)
    end
    if not frame:IsElementEnabled("DeathTimer") then
        frame:EnableElement("DeathTimer")
    end
end

hooksecurefunc(ElvUI[1]:GetModule('NamePlates'), 'UpdatePlate', BuildElvUIFrame)

