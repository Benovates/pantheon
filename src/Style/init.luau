--!strict
--[[
	Typed, ambient design tokens: no strings, no new syntax.

	Tokens read the theme provided by `Theme.Provide` (global context), so they
	are plain values usable in any prop and fully type-checked / autocompleted:

		local S = Pantheon.Style

		scope:Frame({
			BackgroundColor3 = S.Color.SurfaceContainer,
			Padding = { S.Space.Md, S.Space.Lg },
			CornerRadius = { S.Radius.Lg },
			Layout = S.Row(S.Space.Sm),
			[Children] = { ... },
		})

	Values are read when the expression runs, i.e. during the `Provide` call
	stack. For live theme switches wrap in a Computed / rebuild the tree.
]]
local Theme = require(script.Parent.Theme)
local Types = require(script.Parent.Types)

export type Space = {
	Xs2: number,
	Xs: number,
	Sm: number,
	Md: number,
	Lg: number,
	Xl: number,
}

export type Radius = {
	None: number,
	Xs2: number,
	Xs: number,
	Sm: number,
	Md: number,
	Lg: number,
	Xl: number,
	Xl2: number,
	Xl3: number,
	Panel: number,
	Pill: number,
}

-- Enumeration key → ThemeMetrics field.
local SPACE_KEYS = {
	Xs2 = "Space2xs",
	Xs = "SpaceXs",
	Sm = "SpaceSm",
	Md = "SpaceMd",
	Lg = "SpaceLg",
	Xl = "SpaceXl",
}
local RADIUS_KEYS = {
	None = "RadiusNone",
	Xs2 = "Radius2xs",
	Xs = "RadiusXs",
	Sm = "RadiusSm",
	Md = "RadiusMd",
	Lg = "RadiusLg",
	Xl = "RadiusXl",
	Xl2 = "Radius2xl",
	Xl3 = "Radius3xl",
	Panel = "RadiusPanel",
	Pill = "RadiusPill",
}

local function live<T>(pick: (Types.Theme) -> any): T
	return setmetatable({}, {
		__index = function(_, key: any)
			return pick(Theme.use())[key]
		end,
		__newindex = function()
			error("Pantheon.Style tokens are read-only")
		end,
	}) :: any
end

local function mapped<T>(keys: { [string]: string }): T
	return setmetatable({}, {
		__index = function(_, key: any)
			local field = keys[key]
			if field == nil then
				error(`Pantheon.Style: unknown token "{tostring(key)}"`, 2)
			end
			return (Theme.use().Metrics :: any)[field]
		end,
		__newindex = function()
			error("Pantheon.Style tokens are read-only")
		end,
	}) :: any
end

type Props = { [any]: any }

local Style = {
	--- theme.Colors, e.g. Style.Color.Primary
	Color = live(function(t)
		return t.Colors
	end) :: Types.ThemeColors,
	--- theme.Fonts, e.g. Style.Font.Heading
	Font = live(function(t)
		return t.Fonts
	end) :: Types.ThemeFonts,
	--- theme.Typography scales, e.g. Style.Type.Title.Size
	Type = live(function(t)
		return t.Typography
	end) :: Types.ThemeTypography,
	--- Spacing scale: Style.Space.Md
	Space = mapped(SPACE_KEYS) :: Space,
	--- Corner radius scale: Style.Radius.Lg
	Radius = mapped(RADIUS_KEYS) :: Radius,
}

--- Layout presets for the Iona `Layout` prop.
function Style.Row(gap: number?): Props
	return {
		Kind = "List",
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = gap,
	}
end

function Style.Column(gap: number?): Props
	return {
		Kind = "List",
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = gap,
	}
end

local function isPlain(v: any): boolean
	return typeof(v) == "table" and getmetatable(v) == nil
end

local function isArray(t: Props): boolean
	return #t > 0
end

--- Deep merge `over` onto `base`. Plain keyed tables (Layout, Shadow, …) merge
--- field by field; arrays, Instances and Fusion states are replaced whole.
local function deepMerge(base: Props, over: Props): Props
	local out = table.clone(base)
	for key, value in over do
		local prev = out[key]
		if isPlain(prev) and isPlain(value) and not isArray(prev) and not isArray(value) then
			out[key] = deepMerge(prev, value)
		else
			out[key] = value
		end
	end
	return out
end

--- A reusable component style: static props or `function(theme) -> props`.
export type Spec = Props | (theme: Types.Theme) -> Props

export type StyleDef = {
	--- Resolve against the ambient theme.
	resolve: (self: StyleDef) -> Props,
	--- New style = this style + overrides (overrides win).
	extend: (self: StyleDef, spec: Spec) -> StyleDef,
	--- Apply to a prop bag: style < props.
	apply: (self: StyleDef, props: Props?) -> Props,
}

local StyleDef = {}
StyleDef.__index = StyleDef

local function resolveSpec(spec: Spec): Props
	if typeof(spec) == "function" then
		return (spec :: any)(Theme.use())
	end
	return spec :: Props
end

function StyleDef.resolve(self: any): Props
	local out: Props = {}
	for _, spec in self._specs do
		out = deepMerge(out, resolveSpec(spec))
	end
	return out
end

function StyleDef.extend(self: any, spec: Spec): StyleDef
	local specs = table.clone(self._specs)
	table.insert(specs, spec)
	return setmetatable({ _specs = specs }, StyleDef) :: any
end

function StyleDef.apply(self: any, props: Props?): Props
	return deepMerge(self:resolve(), props or {})
end

--- Define a style. Pass several specs to layer them (later wins).
---   local Primary = Style.define({ Variant = "Filled" })
---   local Danger = Primary:extend(function(t) return { Color = t.Colors.Error } end)
function Style.define(...: Spec): StyleDef
	return setmetatable({ _specs = { ... } }, StyleDef) :: any
end

--- Wrap a component so `style` becomes its defaults; call-site props override.
---   local PrimaryButton = Style.styled(Components.Button, Primary)
---   PrimaryButton(scope, { Text = "Run", CornerRadius = { 4 } })  -- override
function Style.styled<P>(
	component: (Types.Scope, P) -> Instance,
	style: StyleDef | Spec
): (Types.Scope, P) -> Instance
	local def: StyleDef = if typeof(style) == "table"
			and getmetatable(style :: any) == StyleDef
		then style :: any
		else Style.define(style :: Spec)
	return function(scope: Types.Scope, props: P): Instance
		return component(scope, def:apply(props :: any) :: any)
	end
end

Style.deepMerge = deepMerge

--- Left-to-right merge of prop bags / presets (later wins; [Children] concatenate).
function Style.merge(...: Props): Props
	local out: Props = {}
	for _, bag in { ... } do
		for key, value in bag do
			local prev = out[key]
			if
				typeof(key) ~= "string"
				and typeof(prev) == "table"
				and typeof(value) == "table"
				and getmetatable(prev) == nil
				and getmetatable(value) == nil
			then
				local joined = table.clone(prev)
				table.move(value, 1, #value, #joined + 1, joined)
				out[key] = joined
			else
				out[key] = value
			end
		end
	end
	return out
end

return Style
