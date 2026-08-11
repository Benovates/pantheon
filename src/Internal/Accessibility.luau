--!strict
--[[
	Respect system accessibility prefs (Roblox GuiService / UserGameSettings).
]]
local GuiService = game:GetService("GuiService")
local UserSettings = UserSettings()
local UserGameSettings = UserSettings:GetService("UserGameSettings")

export type Prefs = {
	ReduceMotion: boolean,
	PreferredTransparency: number, -- 0 = opaque preferred, 1 = more transparent UI ok
	HighContrast: boolean?,
}

local Accessibility = {}

function Accessibility.read(): Prefs
	local reduceMotion = false
	pcall(function()
		reduceMotion = (UserGameSettings :: any).ReducedMotion == true
	end)
	local preferredTransparency = 0
	pcall(function()
		preferredTransparency = GuiService.PreferredTransparency or 0
	end)
	return {
		ReduceMotion = reduceMotion,
		PreferredTransparency = preferredTransparency,
	}
end

--[[
	Apply prefs onto a Theme table (mutates a clone).
	ReduceMotion → near-instant springs.
	PreferredTransparency → bump scrim / overlay opacity toward opaque.
]]
function Accessibility.apply(theme: any, prefs: Prefs?): any
	local resolved: Prefs = prefs or Accessibility.read()
	local out = table.clone(theme)
	out.Colors = table.clone(theme.Colors)
	out.Motion = table.clone(theme.Motion)
	if theme.Controls then
		out.Controls = table.clone(theme.Controls)
	end
	out.Accessibility = resolved

	if resolved.ReduceMotion then
		out.Motion.SpringSpeed = 120
		out.Motion.SpringDamping = 1
		out.Motion.PressScale = 1
	end

	-- PreferredTransparency: higher = user wants more transparency allowed.
	-- We *reduce* scrim when they want less see-through chrome (low value).
	local t = math.clamp(resolved.PreferredTransparency, 0, 1)
	-- When user prefers less transparency (t near 0), make scrim denser by mixing toward black
	if t < 0.5 then
		local densify = (0.5 - t) * 2
		local scrim = out.Colors.Scrim
		out.Colors.Scrim = Color3.new(
			scrim.R * (1 - densify * 0.35),
			scrim.G * (1 - densify * 0.35),
			scrim.B * (1 - densify * 0.35)
		)
	end

	return out
end

function Accessibility.motionSpeed(theme: any, multiplier: number?): number
	local m = multiplier or 1
	if theme.Accessibility and theme.Accessibility.ReduceMotion then
		return theme.Motion.SpringSpeed
	end
	return theme.Motion.SpringSpeed * m
end

return Accessibility
