--!strict
--[[
	Respect system accessibility prefs (Roblox GuiService / UserGameSettings).
]]
local GuiService = game:GetService("GuiService")
local UserSettings = UserSettings()
local UserGameSettings = UserSettings:GetService("UserGameSettings")

export type PreferredTextSizeName = "Medium" | "Large" | "Larger" | "Largest"

export type Prefs = {
	ReduceMotion: boolean,
	PreferredTransparency: number, -- 0 = opaque preferred, 1 = more transparent UI ok
	HighContrast: boolean?,
	PreferredTextSize: PreferredTextSizeName?,
}

local TEXT_SCALE: { [string]: number } = {
	Medium = 1,
	Large = 1.15,
	Larger = 1.3,
	Largest = 1.5,
}

local Accessibility = {}

local function readPreferredTextSize(): PreferredTextSizeName?
	local ok, value = pcall(function()
		return (GuiService :: any).PreferredTextSize
	end)
	if not ok or value == nil then
		return nil
	end
	if typeof(value) == "EnumItem" then
		local name = value.Name
		if TEXT_SCALE[name] then
			return name :: PreferredTextSizeName
		end
	elseif typeof(value) == "string" and TEXT_SCALE[value] then
		return value :: PreferredTextSizeName
	end
	return nil
end

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
		PreferredTextSize = readPreferredTextSize(),
	}
end

--[[
	Apply prefs onto a Theme table (returns a shallow-cloned theme).
	ReduceMotion → near-instant springs.
	PreferredTransparency → densify scrim when user prefers less transparency.
	HighContrast → push surfaces / ink toward extremes.
	PreferredTextSize → scale typography sizes.
]]
function Accessibility.apply(theme: any, prefs: Prefs?): any
	local resolved: Prefs = prefs or Accessibility.read()
	local out = table.clone(theme)
	out.Colors = table.clone(theme.Colors)
	out.Motion = table.clone(theme.Motion)
	if theme.Palette then
		out.Palette = table.clone(theme.Palette)
	end
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
	if t < 0.5 then
		local densify = (0.5 - t) * 2
		local scrim = out.Colors.Scrim
		out.Colors.Scrim = Color3.new(
			scrim.R * (1 - densify * 0.35),
			scrim.G * (1 - densify * 0.35),
			scrim.B * (1 - densify * 0.35)
		)
	end

	if resolved.HighContrast == true then
		if out.Mode == "Dark" then
			out.Colors.Background = Color3.new(0, 0, 0)
			out.Colors.Surface = Color3.fromRGB(12, 12, 14)
			out.Colors.OnSurface = Color3.new(1, 1, 1)
			out.Colors.OnSurfaceVariant = Color3.fromRGB(230, 230, 235)
			out.Colors.Outline = Color3.fromRGB(200, 205, 215)
			out.Colors.OutlineVariant = Color3.fromRGB(140, 145, 155)
		else
			out.Colors.Background = Color3.new(1, 1, 1)
			out.Colors.Surface = Color3.new(1, 1, 1)
			out.Colors.OnSurface = Color3.new(0, 0, 0)
			out.Colors.OnSurfaceVariant = Color3.fromRGB(30, 30, 35)
			out.Colors.Outline = Color3.fromRGB(40, 40, 45)
			out.Colors.OutlineVariant = Color3.fromRGB(80, 80, 90)
		end
	end

	local textSize = resolved.PreferredTextSize
	local scale = if textSize then TEXT_SCALE[textSize] else 1
	if scale ~= nil and scale ~= 1 and theme.Typography then
		local typography = table.clone(theme.Typography)
		for key, style in theme.Typography do
			typography[key] = {
				Font = style.Font,
				Size = math.round(style.Size * scale),
				LineHeight = style.LineHeight,
			}
		end
		out.Typography = typography
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

Accessibility.TEXT_SCALE = TEXT_SCALE

return Accessibility
