local _, dt = ...
local _, L = unpack(dt)

if GetLocale() ~= "zhTW" then return end

L["font"] = "字型"
L["fontSize"] = "字型大小"
L["mover"] = "調整位置"
L["moverTooltip"] = "點擊後調整框體位置。"
L["moverMsg"] = "左鍵拖動：調整框體位置；右鍵：鎖定位置。"
L["DTFrame"] = "計時器框體"
