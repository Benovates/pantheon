--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

local Children = Fusion.Children

return function(scope: Types.Scope, props: Types.AppBarProps): Frame
	local theme = resolveTheme(props)
	local actions: { Instance } = props.Actions or {}
	return scope:Frame({
		Name = "AppBar",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size or UDim2.new(1, 0, 0, theme.Metrics.AppBarHeight),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 10,
		Outline = { Color = theme.Colors.OutlineVariant, Thickness = 1 },
		[Children] = {
			if props.Leading
				then scope:Hydrate(props.Leading)({
					Position = UDim2.fromOffset(8, 8),
					Size = UDim2.fromOffset(40, 40),
				})
				else nil,
			scope:TextLabel({
				BackgroundTransparency = 1,
				FontFace = theme.Fonts.Heading,
				TextSize = 18,
				TextColor3 = theme.Colors.OnSurface,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = props.Title or "",
				Position = UDim2.fromOffset(if props.Leading then 56 else 16, 0),
				Size = UDim2.new(1, -120, 1, 0),
			}),
			scope:Frame({
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 40),
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = 4,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				[Children] = actions,
			}),
		},
	}) :: Frame
end
