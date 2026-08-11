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

local EstuaryUI = {
	Theme = Theme,
	Components = Components,
	Types = Types,
	Layer = Layer,
	Validators = require(script.Internal.Validators),
	Accessibility = require(script.Internal.Accessibility),
	Shadow = require(script.Internal.Shadow),
	Fusion = Fusion,
	Iona = Iona,
	Version = { major = 0, minor = 3, isRelease = false },
}

function EstuaryUI.scoped(): Types.Scope
	return Fusion.scoped(Fusion, Iona) :: any
end

return EstuaryUI
