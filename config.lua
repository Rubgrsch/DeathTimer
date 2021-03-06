local addonName, dt = ...
local C, L = unpack(dt)

local _G = _G
local type, next, unpack, pairs, ipairs, floor = type, next, unpack, pairs, ipairs, math.floor
local PlaySound = PlaySound
local LSM = LibStub("LibSharedMedia-3.0")

local defaults = {
	["targetFrame"] = true,
	["timeFormat"] = "67.3",
	["fontSize"] = 14,
	["font"] = LSM:List("font")[1],
	["mover"] = {
		DeathTimerFrame = {"CENTER",200,-200},
	},
	["ElvUINP_enabled"] = true,
	["ElvUINP_font"] = LSM:List("font")[1],
	["ElvUINP_fontSize"] = 13,
}

local function copyTable(source,dest)
	for k,v in pairs(source) do
		if dest[k] == nil then dest[k] = v end
		if type(v) == "table" then copyTable(v,dest[k]) end
	end
end

dt:AddInitFunc(function()
	if type(deathTimerDB) ~= "table" or next(deathTimerDB) == nil then deathTimerDB = defaults end
	C.db = deathTimerDB
	copyTable(defaults,C.db)
	for k in pairs(C.db) do if defaults[k] == nil then C.db[k] = nil end end -- remove old keys
end)

-- Time Format
local timeFormats = {
	[1] = "67.3",
	[2] = "67",
	[3] = "01:07",
}
C.timeFormatFuncs = {
	["67.3"] = function(time) return "%.1f",time end,
	["67"] = function(time) return "%.0f", time end,
	["01:07"] = function(time) return "%02d:%02d", floor(time/60), time%60 end,
}

-- GUI Template --
local configFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
configFrame.name = addonName
InterfaceOptions_AddCategory(configFrame)
local idx, first, previous = 1, configFrame, configFrame

local function SetFramePoint(frame, pos)
	if type(pos) == "table" then -- Set custom position
		frame:SetPoint(unpack(pos))
		idx, first, previous = 1, frame, frame
	else
		if pos > 0 then
			if idx <= 3 - pos then -- same line
				frame:SetPoint("LEFT", previous, "LEFT", 170, 0)
				idx = idx + pos
			else -- nextline
				frame:SetPoint("TOPLEFT", first, "TOPLEFT", 0, -40)
				idx, first = 1, frame
			end
		else -- next line, offset definded by |pos|
			frame:SetPoint("TOPLEFT", first, "TOPLEFT", 0, 40 * pos)
			idx, first = 1, frame
		end
	end
	previous = frame
end

local function NewCheckBox(label, name, desc, pos, set)
	local Name = addonName.."Config"..label
	local check = CreateFrame("CheckButton", Name, configFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetScript("OnShow", function(self) self:SetChecked(C.db[label]) end)
	check:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		if set then set(checked) else C.db[label] = checked end
		PlaySound(checked and 856 or 857)
	end)
	_G[Name.."Text"]:SetText(name)
	check.tooltipText = name
	check.tooltipRequirement = desc
	SetFramePoint(check, pos)
end

local function NewSlider(label, name, desc, min, max, step, pos, set)
	local Name = addonName.."Config"..label
	local slider = CreateFrame("Slider",Name,configFrame,"OptionsSliderTemplate")
	local text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("BOTTOM",0,-10)
	slider.tooltipText = name
	slider.tooltipRequirement = desc
	slider:SetMinMaxValues(min, max)
	_G[Name.."Low"]:SetText(min)
	_G[Name.."High"]:SetText(max)
	_G[Name.."Text"]:SetText(name)
	slider:SetValueStep(step)
	slider:SetObeyStepOnDrag(true)
	slider:SetScript("OnShow", function(self) self:SetValue(C.db[label],true) end)
	slider:SetScript("OnValueChanged", function(_,value)
		if set then set(value) else C.db[label]=value end
		text:SetText(value)
	end)
	SetFramePoint(slider, pos)
end

local function NewButton(name, desc, pos, func)
	local button = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
	button:SetText(name)
	button.tooltipText = desc
	button:SetSize(150, 25)
	button:SetScript("OnClick", func)
	SetFramePoint(button,pos)
end

local listBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	edgeSize = 16,
	tileSize = 16,
	tile = true,
	insets = {left = 3, right = 3, top = 3, bottom = 3},
}
local optBackdrop = {bgFile = "Interface\\ChatFrame\\ChatFrameBackground"}

local function NewDropdown(label, name, pos, tbl, set, isFont)
	local f = CreateFrame("Button", nil, configFrame)
	f:SetSize(150,25)
	f:SetBackdrop(listBackdrop)
	f:SetBackdropColor(0,0,0,0)
	f.offset = 0
	local list = CreateFrame("Frame",nil,f)
	list:SetPoint("TOP",f,"BOTTOM")
	list:SetBackdrop(listBackdrop)
	list:SetBackdropColor(0,0,0,1)
	list:Hide()
	local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetText(name)
	title:SetPoint("TOPLEFT",f,"TOPLEFT",0,14)
	local downTexture = f:CreateTexture(nil, "BACKGROUND")
	downTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	downTexture:SetPoint("RIGHT",f,"RIGHT")
	downTexture:SetSize(25,25)
	local selectedText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	local _,fontSize = selectedText:GetFont()
	selectedText:SetPoint("LEFT",f,"LEFT",5,0)
	f:SetScript("OnClick",function()
		PlaySound(856)
		ToggleFrame(list)
	end)

	local opts = {}
	local function SetHighlight()
		local offset, chosen = f.offset, f.chosen
		for i, opt in ipairs(opts) do
			if chosen == tbl[i+offset] then
				opt:SetBackdropColor(0.8,0.8,0.3,0.5)
			else
				opt:SetBackdropColor(0, 0, 0, 0.5)
			end
		end
	end
	f:SetScript("OnShow", function(self)
		local chosen = C.db[label]
		self.chosen = chosen
		SetHighlight()
		selectedText:SetText(chosen)
		if isFont then selectedText:SetFont(LSM:Fetch("font",chosen),fontSize) end
	end)

	local function OnClick(self)
		PlaySound(856)
		local chosen = self.value
		f.chosen = chosen
		SetHighlight()
		selectedText:SetText(chosen)
		if set then set(chosen) else C.db[label] = chosen end
		if isFont then selectedText:SetFont(LSM:Fetch("font",chosen),fontSize) end
		list:Hide()
	end
	local function OnEnter(self) if f.chosen ~= self.value then self:SetBackdropColor(1,1,1,0.8) end end
	local function OnLeave(self) if f.chosen ~= self.value then self:SetBackdropColor(0,0,0,0.5) end end
	local function SetListValue()
		local offset = f.offset
		for i, opt in ipairs(opts) do
			local value = tbl[i+offset]
			opt.value = value
			opt.text:SetText(value)
			if isFont then opt.text:SetFont(LSM:Fetch("font",value),fontSize) end
		end
	end
	local Len = #tbl
	local listLen = min(Len,10)
	local function OnMouseWheel(_,direction)
		f.offset = max(min(Len-10, f.offset - direction),0)
		SetHighlight()
		SetListValue()
	end
	for i=1, listLen do
		local opt = CreateFrame("Button", nil, list)
		opt:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 4, -4-(i-1)*20)
		opt:SetSize(150-8,20)
		opt:SetBackdrop(optBackdrop)
		opt:SetBackdropColor(0,0,0,0.5)
		opt.text = opt:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		opt.text:SetPoint("LEFT",opt,"LEFT",5,0)
		opt:SetScript("OnClick", OnClick)
		opt:SetScript("OnEnter", OnEnter)
		opt:SetScript("OnLeave", OnLeave)
		opt:EnableMouseWheel(true)
		opt:SetScript("OnMouseWheel",OnMouseWheel)
		opts[i] = opt
	end
	list:SetSize(150, listLen*20+8)
	SetListValue()
	SetFramePoint(f,pos)
end
-- End of GUI template --

local titleText = configFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 200, -20)
titleText:SetText(addonName.." "..GetAddOnMetadata(addonName, "Version"))

dt:AddInitFunc(function()
	NewCheckBox("targetFrame", L["enableTargetFrame"], L["enableTargetFrameTooltips"], {"TOPLEFT", configFrame, "TOPLEFT", 16, -60},
		function(checked)
			C.db.targetFrame = checked
			C:SetTargetFrame()
		end)
	NewButton(L["mover"], L["moverTooltip"], 1,
		function()
			InterfaceOptionsFrame:Hide()
			HideUIPanel(GameMenuFrame)
			for _,mover in pairs(C.mover) do mover:Show() end
			print(L["moverMsg"])
		end)
	NewDropdown("font",L["font"],-1,LSM:List("font"),
		function(chosen)
			C.db.font = chosen
			C:SetTargetFrame()
		end,true)
	NewSlider("fontSize", L["fontSize"], nil, 9, 30, 1, 1,
		function(value)
			C.db.fontSize = value
			C:SetTargetFrame()
		end)
	NewDropdown("timeFormat", L["timeFormat"], 1, timeFormats,
		nil,nil)
	if ElvUI and ElvUI[1].private.nameplates.enable then
		NewCheckBox("ElvUINP_enabled", L["ElvUINP_enabled"], L["ElvUINP_enabledTooltips"], -1.5)
		NewDropdown("ElvUINP_font",L["ElvUINP_font"],-1,LSM:List("font"),nil,true)
		NewSlider("ElvUINP_fontSize", L["ElvUINP_fontSize"], nil, 9, 30, 1, 1)
	end
end)
