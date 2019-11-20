local _, dt = ...
local _, L = unpack(dt)

if GetLocale() ~= "zhCN" then return end

L["font"] = "字体"
L["fontSize"] = "字体大小"
L["mover"] = "调整位置"
L["moverTooltip"] = "点击后调整框体位置。"
L["moverMsg"] = "左键拖动：调整框体位置；右键：锁定位置。"
L["DTFrame"] = "计时器框体"
