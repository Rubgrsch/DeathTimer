local _, dt = ...
local _, L = unpack(dt)

if GetLocale() ~= "zhCN" then return end

L["enableTargetFrame"] = "启用目标框架"
L["enableTargetFrameTooltips"] = "为目标显示死亡预估时间"
L["font"] = "字体"
L["fontSize"] = "字体大小"
L["mover"] = "调整位置"
L["moverTooltip"] = "点击后调整框体位置。"
L["moverMsg"] = "左键拖动：调整框体位置；右键：锁定位置。"
L["timeFormat"] = "时间格式"
L["DTFrame"] = "计时器框体"
L["ElvUINP_enabled"] = "ElvUI姓名版支持"
L["ElvUINP_enabledTooltips"] = "在ElvUI姓名版上显示死亡预估时间。|n需要重载生效。"
L["ElvUINP_font"] = "字体"
L["ElvUINP_fontSize"] = "字体大小"
