--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

local Children = Fusion.Children

export type FormProps = Types.BaseProps & {
	Children: any?,
	Title: Types.UsedAs<string>?,
}

return function(scope: Types.Scope, props: FormProps): Frame
	local theme = resolveTheme(props)
	return scope:Frame({
		Name = "Form",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Layout = { Kind = "List", Padding = theme.Metrics.SpaceMd, SortOrder = Enum.SortOrder.LayoutOrder },
		[Children] = {
			if props.Title
				then scope:TextLabel({
					BackgroundTransparency = 1,
					FontFace = theme.Fonts.Heading,
					TextSize = 16,
					TextColor3 = theme.Colors.OnSurface,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = props.Title,
					Size = UDim2.new(1, 0, 0, 22),
					LayoutOrder = 0,
				})
				else nil,
			props.Children,
		},
	}) :: Frame
end
