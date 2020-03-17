local _, dt = ...
local _, L = unpack(dt)

if next(L) then return end

L["enableTargetFrame"] = "Enable Target Frame"
L["enableTargetFrameTooltips"] = "Show death time for target"
L["font"] = "Font"
L["fontSize"] = "Font Size"
L["mover"] = "Mover"
L["moverTooltip"] = "Click to enable movers."
L["moverMsg"] = "Left Drag to move frames; Right click to lock them."
L["timeFormat"] = "Time Format"
L["DTFrame"] = "DTFrame"
L["ElvUINP_enabled"] = "ElvUI NP support"
L["ElvUINP_enabledTooltips"] = "Show death time on ElvUI nameplates.|nRequire a ReloadUI."
L["ElvUINP_font"] = "Font"
L["ElvUINP_fontSize"] = "Font Size"
