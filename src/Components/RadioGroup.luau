--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.RadioGroupProps): Frame
	local theme = resolveTheme(props)
	local selected = scope:Value(peek(props.Value) or (props.Options[1] and props.Options[1].Value) or "")
	local disabled = peek(props.Disabled) == true
	local rows = {}

	for i, opt in props.Options do
		local selectedS = scope:Spring(
			scope:Computed(function(use)
				return if use(selected) == opt.Value then 1 else 0
			end),
			theme.Motion.SpringSpeed,
			theme.Motion.SpringDamping
		)
		local ix = Interaction.bind(scope, theme, {
			Disabled = disabled,
			StateColor = theme.Colors.OnSurface,
		})

		local outer = scope:Frame({
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = scope:Computed(function(use)
				local base = theme.Colors.Surface
				return Interaction.lerpColor(base, theme.Colors.OnSurface, ix.alpha(use))
			end),
			LayoutOrder = 1,
			CornerRadius = theme.Metrics.RadiusPill,
			Outline = {
				Color = scope:Computed(function(use)
					return Interaction.lerpColor(theme.Colors.Outline, theme.Colors.Primary, use(selectedS))
				end),
				Thickness = 2,
				Mode = Enum.ApplyStrokeMode.Border,
			},
			[Children] = {
				scope:Frame({
					Name = "Dot",
					Size = scope:Computed(function(use)
						local s = 10 * use(selectedS)
						return UDim2.fromOffset(s, s)
					end),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundColor3 = theme.Colors.Primary,
					BackgroundTransparency = scope:Computed(function(use)
						return 1 - use(selectedS)
					end),
					CornerRadius = theme.Metrics.RadiusPill,
				}),
			},
		})

		local row = scope:TextButton(P({
			Name = "Radio_" .. opt.Value,
			Text = "",
			BackgroundColor3 = theme.Colors.OnSurface,
			BackgroundTransparency = ix.fillTransparency(1),
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = i,
			AutoButtonColor = false,
			Active = not disabled,
			CornerRadius = theme.Metrics.RadiusSm,
			Padding = { theme.Metrics.Space2xs, theme.Metrics.SpaceXs },
			[OnEvent("Activated")] = function()
				if disabled then
					return
				end
				selected:set(opt.Value)
				if props.OnChanged then
					props.OnChanged(opt.Value)
				end
			end,
			Layout = {
				Kind = "List",
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = theme.Metrics.SpaceSm,
			},
			[Children] = {
				outer,
				scope:TextLabel({
					BackgroundTransparency = 1,
					FontFace = theme.Typography.Body.Font,
					TextSize = theme.Typography.Body.Size,
					TextColor3 = theme.Colors.OnSurface,
					Text = opt.Label,
					AutomaticSize = Enum.AutomaticSize.XY,
					LayoutOrder = 2,
				}),
			},
		}))
		ix.wire(row)
		table.insert(rows, row)
	end

	return scope:Frame({
		Name = "RadioGroup",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Layout = { Kind = "List", Padding = theme.Metrics.Space2xs, SortOrder = Enum.SortOrder.LayoutOrder },
		[Children] = rows,
	}) :: Frame
end
