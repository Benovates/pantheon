--!strict
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

return function(scope: Types.Scope, props: Types.TextProps): Instance
	local theme = resolveTheme(props)
	local variant: Types.TextVariant = props.Variant or "Body"
	local scale = theme.Typography[variant] or theme.Typography.Body

	return scope:TextLabel({
		Name = "Text",
		BackgroundTransparency = 1,
		FontFace = scale.Font,
		TextSize = scale.Size,
		LineHeight = scale.LineHeight,
		Text = props.Text,
		TextColor3 = props.Color or theme.Colors.OnSurface,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextWrapped = props.TextWrapped == true,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = props.Size,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
	}) :: TextLabel
end
