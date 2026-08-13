--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Button = require(script.Parent.Button)

local Children = Fusion.Children

return function(scope: Types.Scope, props: Types.SnackbarProps): Instance
	local theme = resolveTheme(props)
	return scope:Frame({
		Name = "Snackbar",
		BackgroundColor3 = theme.Colors.SurfaceContainerHigh,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = props.Size,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex or 90,
		CornerRadius = theme.Metrics.RadiusPanel,
		Padding = { theme.Metrics.SpaceMd },
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = theme.Metrics.SpaceSm,
		},
		[Children] = {
			scope:TextLabel({
				BackgroundTransparency = 1,
				FontFace = theme.Fonts.Body,
				TextSize = 14,
				TextColor3 = theme.Colors.OnSurface,
				Text = props.Message,
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 1,
			}),
			if props.ActionText
				then Button(scope, {
					Text = props.ActionText,
					Variant = "Text" :: Types.ButtonVariant,
					OnClick = props.OnAction,
					LayoutOrder = 2,
				})
				else nil,
		},
	}) :: Frame
end
