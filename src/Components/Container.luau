--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

local Children = Fusion.Children

return function(scope: Types.Scope, props: Types.ContainerProps): Frame
	local theme = resolveTheme(props)
	local maxWidth = props.MaxWidth or 960
	return scope:Frame({
		Name = "Container",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromScale(1, 1),
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			scope:Frame({
				Name = "Inner",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Padding = { theme.Metrics.SpaceMd },
				[Children] = {
					scope:New("UISizeConstraint")({
						MaxSize = Vector2.new(maxWidth, math.huge),
					}),
					props.Children,
				},
			}),
		},
	}) :: Frame
end
