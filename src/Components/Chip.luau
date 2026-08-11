--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local Button = require(script.Parent.Button)

local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.ChipProps): TextButton
	local selected = peek(props.Selected) == true
	local variant: Types.ButtonVariant = if selected then "Primary" else "Tonal"
	return Button(scope, {
		Theme = props.Theme,
		Text = props.Text,
		Variant = variant,
		OnClick = props.OnClick,
		Disabled = props.Disabled,
		LeadingIcon = props.LeadingIcon,
		TrailingIcon = props.TrailingIcon,
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.fromOffset(0, 32),
		Visible = props.Visible,
		ZIndex = props.ZIndex,
	})
end
