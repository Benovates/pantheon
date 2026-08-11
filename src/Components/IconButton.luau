--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Icon = require(script.Parent.Icon)
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.IconButtonProps): TextButton
	local theme = resolveTheme(props)
	local disabled = peek(props.Disabled) == true
	local ix = Interaction.bind(scope, theme, {
		Disabled = disabled,
		StateColor = theme.Colors.OnSurface,
	})

	local button = scope:TextButton(P({
		Name = "IconButton",
		Text = "",
		AutoButtonColor = false,
		Active = not disabled,
		BackgroundColor3 = theme.Colors.OnSurface,
		BackgroundTransparency = ix.fillTransparency(1),
		Size = props.Size or UDim2.fromOffset(40, 40),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		ClipsDescendants = true,
		CornerRadius = theme.Metrics.RadiusPill,
		[OnEvent("Activated")] = if disabled then nil else props.OnClick,
		[Children] = {
			scope:Hydrate(Icon(scope, {
				Theme = theme,
				Name = props.Name,
				Image = props.Image,
				IconSize = 20,
				Color = theme.Colors.OnSurface,
			}))({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
		},
	})) :: TextButton

	ix.wire(button)
	return button
end
