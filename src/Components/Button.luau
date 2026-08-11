--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Icon = require(script.Parent.Icon)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local function variantColors(theme: Types.Theme, variant: Types.ButtonVariant): (Color3, Color3, number, boolean, Color3)
	if variant == "Primary" then
		return theme.Colors.Primary, theme.Colors.OnPrimary, 0, false, theme.Colors.OnPrimary
	elseif variant == "Destructive" then
		return theme.Colors.Error, theme.Colors.OnError, 0, false, theme.Colors.OnError
	elseif variant == "Tonal" then
		return theme.Colors.PrimaryContainer, theme.Colors.OnPrimaryContainer, 0, false, theme.Colors.OnPrimaryContainer
	elseif variant == "Outlined" then
		return theme.Colors.Surface, theme.Colors.Primary, 0, true, theme.Colors.Primary
	end
	return theme.Colors.Primary, theme.Colors.Primary, 1, false, theme.Colors.Primary
end

return function(scope: Types.Scope, props: Types.ButtonProps): TextButton
	local theme = resolveTheme(props)
	local variant: Types.ButtonVariant = props.Variant or "Primary"
	local bg, fg, transparency, outlined, stateColor = variantColors(theme, variant)
	local disabled = peek(props.Disabled) == true
	local padX = math.max(theme.Metrics.ButtonPadX - 4, 8)
	local padY = math.max(theme.Metrics.ButtonPadY - 2, 2)
	local leading = props.LeadingIcon or props.Icon
	local trailing = props.TrailingIcon

	local ix = Interaction.bind(scope, theme, {
		Disabled = disabled,
		StateColor = stateColor,
	})

	-- MD3 disabled: on-surface @ 12% container, label @ 38%
	local disabledBg = Interaction.lerpColor(theme.Colors.Surface, theme.Colors.OnSurface, 0.12)
	local disabledFg = theme.Colors.OnSurface

	local kids = {}
	if leading then
		table.insert(
			kids,
			scope:Hydrate(Icon(scope, {
				Theme = theme,
				Name = leading,
				IconSize = 18,
				Color = if disabled then disabledFg else fg,
			}))({
				LayoutOrder = 1,
				ImageTransparency = if disabled then 0.62 else 0,
			})
		)
	end
	table.insert(
		kids,
		scope:TextLabel({
			BackgroundTransparency = 1,
			FontFace = theme.Typography.Label.Font,
			TextSize = theme.Typography.Body.Size,
			Text = props.Text or "Button",
			TextColor3 = if disabled then disabledFg else fg,
			TextTransparency = if disabled then 0.62 else 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			LayoutOrder = 2,
		})
	)
	if trailing then
		table.insert(
			kids,
			scope:Hydrate(Icon(scope, {
				Theme = theme,
				Name = trailing,
				IconSize = 18,
				Color = if disabled then disabledFg else fg,
			}))({
				LayoutOrder = 3,
				ImageTransparency = if disabled then 0.62 else 0,
			})
		)
	end

	local button = scope:TextButton(P({
		Name = "Button",
		Text = "",
		AutoButtonColor = false,
		Active = not disabled,
		BackgroundColor3 = if disabled
			then disabledBg
			else (if transparency >= 1 then stateColor else ix.fill(bg)),
		BackgroundTransparency = if disabled
			then 0
			else (if transparency >= 1 then ix.fillTransparency(1) else transparency),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = props.Size or UDim2.fromOffset(0, 40),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		-- Clipping cuts UIStroke; only clip filled variants.
		ClipsDescendants = not outlined,
		CornerRadius = theme.Metrics.RadiusPill,
		Padding = { padY, padX },
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = 6,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		Outline = if outlined and not disabled
			then {
				Color = theme.Colors.Outline,
				Thickness = 1,
				Mode = Enum.ApplyStrokeMode.Border,
			}
			else nil,
		[OnEvent("Activated")] = if disabled then nil else props.OnClick,
		[Children] = kids,
	})) :: TextButton

	if not disabled then
		ix.wire(button)
	end
	return button
end
