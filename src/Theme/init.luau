--!strict
local Packages = script.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Types)
local Accessibility = require(script.Parent.Internal.Accessibility)

local peek = Fusion.peek

local themeContext = Fusion.Contextual(nil :: Types.ThemeRef?)
--[[
	Fusion Contextual only applies during the Provide call stack. Computed /
	Observer callbacks re-run later and lose context — keep a root fallback.
]]
local rootTheme: Types.ThemeRef? = nil

local MontserratMedium = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
local MontserratBold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local MontserratSemi = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
local Mono = Font.new("rbxasset://fonts/families/RobotoMono.json")

local function lightColors(): Types.ThemeColors
	return {
		Primary = Color3.fromRGB(0, 105, 92),
		OnPrimary = Color3.fromRGB(255, 255, 255),
		PrimaryContainer = Color3.fromRGB(178, 223, 219),
		OnPrimaryContainer = Color3.fromRGB(0, 40, 35),
		Background = Color3.fromRGB(244, 246, 250),
		Surface = Color3.fromRGB(255, 255, 255),
		SurfaceDim = Color3.fromRGB(232, 235, 241),
		SurfaceBright = Color3.fromRGB(255, 255, 255),
		OnSurface = Color3.fromRGB(28, 27, 31),
		OnSurfaceVariant = Color3.fromRGB(68, 71, 79),
		SurfaceContainer = Color3.fromRGB(238, 241, 246),
		SurfaceContainerHigh = Color3.fromRGB(226, 230, 237),
		Outline = Color3.fromRGB(196, 199, 207),
		OutlineVariant = Color3.fromRGB(218, 221, 228),
		Error = Color3.fromRGB(211, 47, 47),
		OnError = Color3.fromRGB(255, 255, 255),
		Success = Color3.fromRGB(46, 125, 50),
		OnSuccess = Color3.fromRGB(255, 255, 255),
		Warning = Color3.fromRGB(237, 108, 2),
		OnWarning = Color3.fromRGB(255, 255, 255),
		Scrim = Color3.fromRGB(16, 20, 24),
		Info = Color3.fromRGB(2, 136, 209),
		OnInfo = Color3.fromRGB(255, 255, 255),
	}
end

local function darkColors(): Types.ThemeColors
	return {
		Primary = Color3.fromRGB(77, 182, 172),
		OnPrimary = Color3.fromRGB(0, 55, 49),
		PrimaryContainer = Color3.fromRGB(0, 77, 68),
		OnPrimaryContainer = Color3.fromRGB(178, 223, 219),
		Background = Color3.fromRGB(16, 20, 24),
		Surface = Color3.fromRGB(26, 31, 38),
		SurfaceDim = Color3.fromRGB(16, 20, 24),
		SurfaceBright = Color3.fromRGB(40, 48, 58),
		OnSurface = Color3.fromRGB(230, 232, 236),
		OnSurfaceVariant = Color3.fromRGB(184, 190, 200),
		SurfaceContainer = Color3.fromRGB(35, 42, 51),
		SurfaceContainerHigh = Color3.fromRGB(45, 54, 65),
		Outline = Color3.fromRGB(52, 61, 72),
		OutlineVariant = Color3.fromRGB(42, 50, 60),
		Error = Color3.fromRGB(239, 83, 80),
		OnError = Color3.fromRGB(26, 31, 38),
		Success = Color3.fromRGB(102, 187, 106),
		OnSuccess = Color3.fromRGB(26, 31, 38),
		Warning = Color3.fromRGB(255, 183, 77),
		OnWarning = Color3.fromRGB(26, 31, 38),
		Scrim = Color3.fromRGB(0, 0, 0),
		Info = Color3.fromRGB(79, 195, 247),
		OnInfo = Color3.fromRGB(26, 31, 38),
	}
end

local defaultMetrics: Types.ThemeMetrics = {
	Space2xs = 4,
	SpaceXs = 8,
	SpaceSm = 12,
	SpaceMd = 16,
	SpaceLg = 24,
	SpaceXl = 32,
	RadiusNone = 0,
	Radius2xs = 2,
	RadiusXs = 4,
	RadiusSm = 8,
	RadiusMd = 12,
	RadiusLg = 16,
	RadiusXl = 20,
	Radius2xl = 24,
	Radius3xl = 32,
	RadiusPanel = 16,
	RadiusPill = 999,
	AppBarHeight = 56,
	DrawerWidth = 280,
	RailWidth = 72,
	ButtonPadX = 20,
	ButtonPadY = 4,
}

local function typography(): Types.ThemeTypography
	return {
		Display = { Font = MontserratBold, Size = 32, LineHeight = 1.2 },
		Headline = { Font = MontserratBold, Size = 24, LineHeight = 1.25 },
		Title = { Font = MontserratSemi, Size = 18, LineHeight = 1.3 },
		Body = { Font = MontserratMedium, Size = 14, LineHeight = 1.4 },
		Label = { Font = MontserratSemi, Size = 12, LineHeight = 1.3 },
		Mono = { Font = Mono, Size = 13, LineHeight = 1.35 },
	}
end

local function lerpColor(a: Color3, b: Color3, t: number): Color3
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function blendThemes(a: Types.Theme, b: Types.Theme, t: number): Types.Theme
	t = math.clamp(t, 0, 1)
	if t <= 0 then
		return a
	end
	if t >= 1 then
		return b
	end
	local colors: any = {}
	for key, value in a.Colors :: any do
		if typeof(value) == "Color3" then
			colors[key] = lerpColor(value, (b.Colors :: any)[key], t)
		else
			colors[key] = value
		end
	end
	local out = table.clone(b)
	out.Colors = colors
	out.Mode = if t < 0.5 then a.Mode else b.Mode
	return out
end

local Theme = {}

export type ThemeCreateOpts = {
	RespectAccessibility: boolean?,
	Controls: Types.ThemeControls?,
	Overrides: { [string]: any }?,
}

local function deepMerge(base: any, over: any): any
	if typeof(over) ~= "table" then
		return over
	end
	if typeof(base) ~= "table" then
		return table.clone(over)
	end
	local out = table.clone(base)
	for key, value in over do
		local existing = out[key]
		if typeof(value) == "table" and typeof(existing) == "table" and getmetatable(value) == nil and getmetatable(existing) == nil then
			local isArray = #value > 0 or #existing > 0
			if isArray then
				out[key] = table.clone(value)
			else
				out[key] = deepMerge(existing, value)
			end
		else
			out[key] = value
		end
	end
	return out
end

function Theme.create(mode: Types.ThemeMode?, opts: ThemeCreateOpts?): Types.Theme
	local resolved: Types.ThemeMode = mode or "Light"
	local switchIcons = true
	if opts ~= nil and opts.Controls ~= nil and opts.Controls.SwitchIcons ~= nil then
		switchIcons = opts.Controls.SwitchIcons
	end
	local theme: Types.Theme = {
		Mode = resolved,
		Colors = if resolved == "Dark" then darkColors() else lightColors(),
		Fonts = {
			Heading = MontserratBold,
			Body = MontserratMedium,
			Mono = Mono,
		},
		Typography = typography(),
		Metrics = table.clone(defaultMetrics),
		Icons = {},
		Audio = {
			open = "",
			success = "",
			error = "",
			confirm = "",
		},
		Motion = {
			SpringSpeed = 36,
			SpringDamping = 0.94,
			PressScale = 1,
		},
		Controls = {
			SwitchIcons = switchIcons,
		},
	}
	if opts and opts.Overrides then
		theme = deepMerge(theme, opts.Overrides) :: Types.Theme
		theme.Mode = resolved
	end
	if opts and opts.Controls then
		theme.Controls = deepMerge(theme.Controls or {}, opts.Controls)
	end
	if opts == nil or opts.RespectAccessibility ~= false then
		theme = Accessibility.apply(theme)
	end
	return theme
end

--[[
	Animated theme ref: springs between Light/Dark when mode changes.
	Pass Animate = false for instant swap.
]]
function Theme.createAnimated(
	scope: Types.Scope,
	mode: any,
	opts: { Animate: boolean?, RespectAccessibility: boolean?, Controls: Types.ThemeControls? }?
): Types.ThemeRef
	local animate = if opts and opts.Animate == false then false else true
	local respect = if opts and opts.RespectAccessibility == false then false else true
	local createOpts: ThemeCreateOpts = {
		RespectAccessibility = respect,
		Controls = if opts then opts.Controls else nil,
	}
	local light = Theme.create("Light", createOpts)
	local dark = Theme.create("Dark", createOpts)

	local goal = scope:Computed(function(use)
		local m = if typeof(mode) == "table" then use(mode) else mode
		return if m == "Dark" then 1 else 0
	end)

	if not animate or (light.Accessibility and light.Accessibility.ReduceMotion) then
		return scope:Computed(function(use)
			return if use(goal) > 0.5 then dark else light
		end)
	end

	local blend = scope:Spring(goal, 28, 0.95)
	return scope:Computed(function(use)
		return blendThemes(light, dark, use(blend))
	end)
end

function Theme.Provide<T...>(theme: Types.ThemeRef, callback: (T...) -> ...any, ...: T...): ...any
	rootTheme = theme
	return themeContext:is(theme):during(callback, ...)
end

function Theme.use(): Types.Theme
	local ref = themeContext:now() or rootTheme
	assert(ref ~= nil, "EstuaryUI.Theme.Provide required — wrap your UI root in Theme.Provide")
	return peek(ref) :: Types.Theme
end

function Theme.useRef(): Types.ThemeRef
	local ref = themeContext:now() or rootTheme
	assert(ref ~= nil, "EstuaryUI.Theme.Provide required")
	return ref :: Types.ThemeRef
end

function Theme.resolve(props: { Theme: Types.ThemeRef? }?): Types.Theme
	if props and props.Theme ~= nil then
		return peek(props.Theme) :: Types.Theme
	end
	return Theme.use()
end

Theme.Contextual = themeContext
Theme.Accessibility = Accessibility
Theme.blend = blendThemes
Theme.deepMerge = deepMerge

return Theme
