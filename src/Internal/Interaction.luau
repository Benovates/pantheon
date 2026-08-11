--!strict
--[[
	Spring-driven hover / press / focus for interactive controls.

	State layers tint the control's own BackgroundColor3 / Transparency
	(Material state-layer model). No child overlay Frame — padding must not
	create a second “hover box”.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)

local peek = Fusion.peek

export type BindOptions = {
	Disabled: boolean?,
	-- Color mixed onto the base fill (usually OnSurface or OnPrimary)
	StateColor: Color3?,
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

local function lerpColor(a: Color3, b: Color3, t: number): Color3
	t = math.clamp(t, 0, 1)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
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
			return lerpColor(base, stateColor, layerAlpha(use))
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

return {
	bind = bind,
	lerpColor = lerpColor,
}
