--!strict
--[[
	Named / literal color resolution (Iona-style) + MD3-ish role derivation.
	Also resolves Material Design swatches: "Blue 500", "blue.A200", etc.
]]
local Types = require(script.Parent.Parent.Types)
local Material = require(script.Parent.MaterialColors)

local Color = {}

Color.Material = Material

local function srgbChannel(c: number): number
	if c <= 0.04045 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end

function Color.luminance(c: Color3): number
	return 0.2126 * srgbChannel(c.R) + 0.7152 * srgbChannel(c.G) + 0.0722 * srgbChannel(c.B)
end

function Color.lerp(a: Color3, b: Color3, t: number): Color3
	t = math.clamp(t, 0, 1)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

function Color.onColor(base: Color3): Color3
	return if Color.luminance(base) > 0.45 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
end

function Color.rolesFromSeed(seed: Color3, mode: Types.ThemeMode?): Types.ThemeColorRole
	local resolvedMode: Types.ThemeMode = mode or "Light"
	local container = if resolvedMode == "Dark"
		then Color.lerp(seed, Color3.new(0, 0, 0), 0.55)
		else Color.lerp(seed, Color3.new(1, 1, 1), 0.78)
	return {
		Base = seed,
		OnBase = Color.onColor(seed),
		Container = container,
		OnContainer = Color.onColor(container),
	}
end

function Color.isRole(value: any): boolean
	return typeof(value) == "table"
		and typeof(value.Base) == "Color3"
		and typeof(value.OnBase) == "Color3"
		and typeof(value.Container) == "Color3"
		and typeof(value.OnContainer) == "Color3"
end

local function normalizeKey(key: string): string
	return string.lower((string.gsub(key, "%s+", "")))
end

function Color.materialSwatch(value: any): Color3?
	if typeof(value) == "string" then
		return Material.get(value :: string)
	end
	if typeof(value) == "table" and not Color.isRole(value) then
		local tbl = value :: { [any]: any }
		for hueName, shade in tbl do
			if
				typeof(hueName) == "string"
				and (typeof(shade) == "number" or typeof(shade) == "string")
			then
				-- skip array-like numeric keys handled below
				if hueName ~= "n" then
					local found = Material.get(hueName, shade)
					if found then
						return found
					end
				end
			end
		end
		if
			typeof(tbl[1]) == "string"
			and (typeof(tbl[2]) == "number" or typeof(tbl[2]) == "string")
		then
			return Material.get(tbl[1], tbl[2])
		end
	end
	return nil
end

function Color.toColor3(value: Types.ColorInput, theme: Types.Theme?): Color3
	local t = typeof(value)
	if t == "Color3" then
		return value :: Color3
	end

	local material = Color.materialSwatch(value)
	if material then
		return material
	end

	if t == "string" then
		local name = value :: string
		if theme then
			local role = Color.resolveRole(name, theme)
			if role then
				return role.Base
			end
		end
		local ok, hex = pcall(Color3.fromHex, name)
		if ok then
			return hex
		end
		error(`Invalid color string: {name}`)
	end
	if t == "table" then
		local arr = value :: { any }
		if Color.isRole(arr) then
			return (arr :: Types.ThemeColorRole).Base
		end
		if #arr >= 3 and typeof(arr[1]) == "number" then
			return Color3.fromRGB(arr[1], arr[2], arr[3])
		end
	end
	error(`Invalid datatype for Color3: {t}`)
end

function Color.resolveRole(name: string, theme: Types.Theme): Types.ThemeColorRole?
	local key = normalizeKey(name)
	local palette = theme.Palette
	if palette then
		local direct = palette[key] or palette[name]
		if direct then
			return direct
		end
		for k, role in palette do
			if normalizeKey(tostring(k)) == key then
				return role
			end
		end
	end

	local colors = theme.Colors
	local flat: { [string]: () -> Types.ThemeColorRole } = {
		primary = function()
			return {
				Base = colors.Primary,
				OnBase = colors.OnPrimary,
				Container = colors.PrimaryContainer,
				OnContainer = colors.OnPrimaryContainer,
			}
		end,
		secondary = function()
			return {
				Base = colors.SurfaceContainerHigh,
				OnBase = colors.OnSurface,
				Container = colors.SurfaceContainer,
				OnContainer = colors.OnSurface,
			}
		end,
		surface = function()
			return {
				Base = colors.SurfaceContainerHigh,
				OnBase = colors.OnSurface,
				Container = colors.SurfaceContainer,
				OnContainer = colors.OnSurfaceVariant,
			}
		end,
		error = function()
			return {
				Base = colors.Error,
				OnBase = colors.OnError,
				Container = Color.lerp(colors.Error, colors.Surface, 0.75),
				OnContainer = colors.Error,
			}
		end,
		success = function()
			return {
				Base = colors.Success,
				OnBase = colors.OnSuccess,
				Container = Color.lerp(colors.Success, colors.Surface, 0.75),
				OnContainer = colors.Success,
			}
		end,
		warning = function()
			return {
				Base = colors.Warning,
				OnBase = colors.OnWarning,
				Container = Color.lerp(colors.Warning, colors.Surface, 0.75),
				OnContainer = colors.Warning,
			}
		end,
		info = function()
			return {
				Base = colors.Info,
				OnBase = colors.OnInfo,
				Container = Color.lerp(colors.Info, colors.Surface, 0.75),
				OnContainer = colors.Info,
			}
		end,
	}
	local builder = flat[key]
	if builder then
		return builder()
	end
	return nil
end

function Color.resolve(
	input: Types.ColorInput?,
	theme: Types.Theme,
	fallbackName: string?
): Types.ThemeColorRole
	if input == nil then
		return Color.resolveRole(fallbackName or "primary", theme)
			or Color.rolesFromSeed(theme.Colors.Primary, theme.Mode)
	end
	if Color.isRole(input) then
		return input :: Types.ThemeColorRole
	end

	local material = Color.materialSwatch(input)
	if material then
		return Color.rolesFromSeed(material, theme.Mode)
	end

	if typeof(input) == "string" then
		local role = Color.resolveRole(input :: string, theme)
		if role then
			return role
		end
		local ok, hex = pcall(Color3.fromHex, input :: string)
		if ok then
			return Color.rolesFromSeed(hex, theme.Mode)
		end
	end
	local seed = Color.toColor3(input, theme)
	return Color.rolesFromSeed(seed, theme.Mode)
end

function Color.normalizePalette(
	entries: { [string]: Color3 | Types.ThemeColorRole | Types.ColorInput }?,
	mode: Types.ThemeMode,
	base: { [string]: Types.ThemeColorRole }?
): { [string]: Types.ThemeColorRole }
	local out: { [string]: Types.ThemeColorRole } = {}
	if base then
		for k, v in base do
			out[normalizeKey(k)] = v
		end
	end
	if entries then
		for k, v in entries do
			local key = normalizeKey(tostring(k))
			if Color.isRole(v) then
				out[key] = v :: Types.ThemeColorRole
			else
				local material = Color.materialSwatch(v)
				local seed = if material
					then material
					elseif typeof(v) == "Color3" then v :: Color3
					else Color.toColor3(v :: Types.ColorInput, nil)
				out[key] = Color.rolesFromSeed(seed, mode)
			end
		end
	end
	return out
end

return Color
