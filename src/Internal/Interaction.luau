--!strict
--[[
	Spring-driven hover / press / focus for interactive controls.

	State layers tint the control's own BackgroundColor3 / Transparency
	(Material state-layer model). No child overlay Frame: padding must not
	create a second “hover box”.
]]
local Fusion = require(script.Parent.Parent.Parent.Fusion)
local Types = require(script.Parent.Parent.Types)
local Focus = require(script.Parent.Focus)

export type BindOptions = {
	Disabled: boolean?,
	-- Color mixed onto the base fill (usually OnSurface or OnPrimary)
	StateColor: any?, -- a Color3 or a state of one
	HoverOpacity: number?, -- default 0.08
	PressOpacity: number?, -- default 0.12
}

export type BindResult = {
	Hover: any,
	Press: any,
	Focus: any,
	--- Resolved hover/press layer opacity (0–0.24) for use inside Computeds.
	alpha: (use: (any) -> any) -> number,
	--- Mix state-layer into a solid fill color
	fill: (base: Color3) -> any,
	--- For transparent / text buttons: baseTransparency → springed transparency
	fillTransparency: (baseTransparency: number) -> any,
	wire: (gui: GuiButton) -> (),
}

--- A colour, or a state of one. Read inside a Computed, pass its `use` so the Computed follows
--- the state; without it the state is only read once.
local function resolveColor(color: any, use: any?): Color3
	if typeof(color) == "table" and (color :: any).type == "State" then
		return if use then use(color) else Fusion.peek(color)
	end
	return color
end

local function lerpColor(a: any, b: any, t: number, use: any?): Color3
	local from, to = resolveColor(a, use), resolveColor(b, use)
	t = math.clamp(t, 0, 1)
	return Color3.new(
		from.R + (to.R - from.R) * t,
		from.G + (to.G - from.G) * t,
		from.B + (to.B - from.B) * t
	)
end

local function bind(scope: Types.Scope, theme: Types.Theme, opts: BindOptions?): BindResult
	local options: BindOptions = opts or {}
	local disabled = options.Disabled == true
	local hover = scope:Value(0)
	local press = scope:Value(0)
	local focus = scope:Value(0)

	local speed = theme.Motion.SpringSpeed
	local damp = theme.Motion.SpringDamping
	local hoverS = scope:Spring(hover, speed, damp)
	local pressS = scope:Spring(press, speed * 1.1, damp)
	local focusS = scope:Spring(focus, speed * 0.9, damp)

	local stateColor = options.StateColor or theme.Colors.OnSurface
	local hoverOp = options.HoverOpacity or 0.08
	local pressOp = options.PressOpacity or 0.12

	local function layerAlpha(use: (any) -> any): number
		if disabled then
			return 0
		end
		local hoverN = use(hoverS) :: number
		local pressN = use(pressS) :: number
		return math.clamp(hoverN * hoverOp + pressN * pressOp, 0, 0.24)
	end

	local function fill(base: Color3): any
		return scope:Computed(function(use)
			return lerpColor(base, stateColor, layerAlpha(use), use)
		end)
	end

	local function fillTransparency(baseTransparency: number): any
		return scope:Computed(function(use)
			local alpha = layerAlpha(use)
			-- Reveal tinted fill under transparency
			return math.clamp(baseTransparency * (1 - alpha) - alpha * 0.15, 0, 1)
		end)
	end

	local function wire(gui: GuiButton)
		gui.AutoButtonColor = false
		if disabled then
			return
		end
		Focus.manage(gui, theme)
		table.insert(
			scope,
			gui.MouseEnter:Connect(function()
				hover:set(1)
			end)
		)
		table.insert(
			scope,
			gui.MouseLeave:Connect(function()
				hover:set(0)
				press:set(0)
			end)
		)
		table.insert(
			scope,
			gui.MouseButton1Down:Connect(function()
				press:set(1)
			end)
		)
		table.insert(
			scope,
			gui.MouseButton1Up:Connect(function()
				press:set(0)
			end)
		)
		table.insert(
			scope,
			gui.SelectionGained:Connect(function()
				focus:set(1)
			end)
		)
		table.insert(
			scope,
			gui.SelectionLost:Connect(function()
				focus:set(0)
			end)
		)
	end

	return {
		Hover = hoverS,
		Press = pressS,
		Focus = focusS,
		alpha = layerAlpha,
		fill = fill,
		fillTransparency = fillTransparency,
		wire = wire,
	} :: BindResult
end

--- Colour for the unfilled part of a slider / progress track. Panels are often
--- SurfaceContainerHigh themselves (the elevated Window is, in dark mode), so using that
--- colour for the track makes it vanish; mix a little OnSurface in so it reads on either.
local function trackColor(theme: Types.Theme, use: any?): Color3
	return lerpColor(theme.Colors.SurfaceContainerHigh, theme.Colors.OnSurface, 0.2, use)
end

return {
	bind = bind,
	lerpColor = lerpColor,
	trackColor = trackColor,
}
