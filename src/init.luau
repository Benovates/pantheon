--!strict
--[[
	koterahq/estuary-ui — Cadence/Tithe design system for Fusion + Iona.
	Vuetify-scale component kit (unpublished; path-link siblings).
]]

local Packages = script.Parent
local Fusion = require(Packages.Fusion)
local Iona = require(Packages.Iona)

local Theme = require(script.Theme)
local Components = require(script.Components)
local Types = require(script.Types)
local Layer = require(script.Internal.Layer)

export type Theme = Types.Theme
export type ThemeMode = Types.ThemeMode
export type Scope = Types.Scope
export type ButtonProps = Types.ButtonProps
export type TextFieldProps = Types.TextFieldProps
export type ListItemProps = Types.ListItemProps
export type ButtonVariant = Types.ButtonVariant
export type ColorInput = Types.ColorInput
export type ThemeColorRole = Types.ThemeColorRole
export type ThemePalette = Types.ThemePalette

local EstuaryUI = {
	Theme = Theme,
	Components = Components,
	Types = Types,
	Layer = Layer,
	Flags = require(script.Internal.Flags),
	CanvasFade = require(script.Internal.CanvasFade),
	Validators = require(script.Internal.Validators),
	Accessibility = require(script.Internal.Accessibility),
	Shadow = require(script.Internal.Shadow),
	Color = require(script.Internal.Color),
	Material = require(script.Internal.MaterialColors),
	Fusion = Fusion,
	Iona = Iona,
	Version = { major = 0, minor = 3, isRelease = false },
}

-- Fusion's Hydrate is slated for deprecation. Estuary scopes expose its own
-- `Apply` (and keep `Hydrate` as an alias so Iona / older code keeps working)
-- without touching Fusion's implementation.
local Apply = require(script.Internal.Apply)
local FusionMethods = table.clone(Fusion :: any)
FusionMethods.Hydrate = Apply
FusionMethods.Apply = Apply
table.freeze(FusionMethods)

EstuaryUI.Apply = Apply

function EstuaryUI.scoped(): Types.Scope
	return Fusion.scoped(FusionMethods, Iona) :: any
end

return EstuaryUI
