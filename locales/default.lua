local _, dt = ...
local _, L = unpack(dt)

if next(L) then return end

L["font"] = "Font"
L["fontSize"] = "Font Size"
L["mover"] = "Mover"
L["moverTooltip"] = "Click to enable movers."
L["moverMsg"] = "Left Drag to move frames; Right click to lock them."
L["DTFrame"] = "DTFrame"
