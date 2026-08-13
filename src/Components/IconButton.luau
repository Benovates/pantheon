--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Icon = require(script.Parent.Icon)
local Color = require(script.Parent.Parent.Internal.Color)
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local function normalizeVariant(
	variant: string?,
	colorProp: Types.ColorInput?
): (string, Types.ColorInput?)
	local v = variant or "Text"
	-- Legacy variants that encoded color
	if v == "Primary" then
		return "Filled", colorProp or "primary"
	end
	if v == "Destructive" then
		return "Filled", colorProp or "error"
	end
	if v == "Tonal" or v == "Outlined" or v == "Text" or v == "Filled" then
		return v, colorProp
	end

	return "Text", colorProp
end

local function styleFromRole(
	style: string,
	role: Types.ThemeColorRole,
	theme: Types.Theme
): (Color3, Color3, number, boolean, Color3)
	if style == "Tonal" then
		return role.Container, role.OnContainer, 0, false, role.OnContainer
	end
	if style == "Outlined" then
		return theme.Colors.Surface, role.Base, 0, true, role.Base
	end
	if style == "Filled" then
		return role.Base, role.OnBase, 0, false, role.OnBase
	end

	-- Text
	return theme.Colors.OnSurface, theme.Colors.OnSurface, 1, false, theme.Colors.OnSurface
end

return function(scope: Types.Scope, props: Types.IconButtonProps): Instance
	local theme = resolveTheme(props)
	local style, colorInput = normalizeVariant(props.Variant, peek(props.Color) :: Types.ColorInput?)
	local role = Color.resolve(colorInput, theme, "primary")
	local bg, fg, transparency, outlined, stateColor = styleFromRole(style, role, theme)
	local disabled = peek(props.Disabled) == true
	local ix = Interaction.bind(scope, theme, {
		Disabled = disabled,
		StateColor = stateColor,
	})

	-- MD3 disabled: on-surface @ 12% container, label @ 38%
	local disabledBg = Interaction.lerpColor(theme.Colors.Surface, theme.Colors.OnSurface, 0.12)
	local disabledFg = theme.Colors.OnSurface

	local button = scope:TextButton(P({
		Name = "IconButton",
		Text = "",
		AutoButtonColor = false,
		Active = not disabled,
		BackgroundColor3 = if disabled
			then disabledBg
			else (if transparency >= 1 then stateColor else ix.fill(bg)),
		BackgroundTransparency = if disabled
			then 0
			else (if transparency >= 1 then ix.fillTransparency(1) else transparency),
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
				Color = if disabled then disabledFg else fg,
				Transparency = if disabled then 0.62 else 0,
			}))({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
		},
	})) :: TextButton

	ix.wire(button)
	return button
end
