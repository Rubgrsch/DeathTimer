local _, dt = ...
dt[1] = {} -- Config
dt[2] = {} -- Locales
local _, L = unpack(dt)

_G.DeathTimer = dt

setmetatable(L, {__index=function(_, key) return key end})

local init = {}
function dt:AddInitFunc(func)
	init[#init+1] = func
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	for _,v in ipairs(init) do v() end
	init = nil
end)
