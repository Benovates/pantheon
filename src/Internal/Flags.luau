--!strict
--[[
	Library feature flags.

		Pantheon.Flags.CanvasFade = false  -- restore BackgroundTransparency fades
]]
export type FlagName =
	"CanvasFade"
	| "LifetimeChecks"
	| "DevTools"
	| "BetaUI"
	| "ReactiveTheme"
	| "ConicalRotation"
	| "ConicalClockwise"

local Flags = {
	--- Wrap appearing chrome in a CanvasGroup and spring GroupTransparency.
	--- Off → previous per-component transparency springs.
	CanvasFade = false,
	--- Run Fusion's scope-lifetime diagnostics (slow: scans whole scopes on every `use`).
	LifetimeChecks = false,
	--- Allow Pantheon.DevTools.mount() (inspect overlay + properties panel).
	DevTools = false,
	--- Components follow a theme given as a state: when it changes, colours change in place with no
	--- rebuild. Colours that a component computes once, outside a Computed, still keep the old
	--- theme (see docs/Guides/Theming.md). Needs a theme state, such as `Theme.createAnimated`.
	ReactiveTheme = false,
	--- Use Studio-beta UI features (conical/radial gradients, text/inset shadows) when the
	--- engine has them. Set false to force the fallbacks. See Internal/Features.
	BetaUI = true,
	--- Calibration for conical UIGradients: degrees added to Rotation so position 0 sits at
	--- 12 o'clock. Measured in Studio's Upgraded UIGradients beta: a conical gradient starts at
	--- 3 o'clock (east) and sweeps clockwise, so -90 puts the start at the top. If an Arc or the
	--- colour wheel looks rotated or mirrored, adjust this / ConicalClockwise.
	ConicalRotation = -90,
	--- Calibration: whether a conical gradient sweeps clockwise (measured: it does).
	ConicalClockwise = true,
}

return Flags
