--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 8, SortOrder = Enum.SortOrder.LayoutOrder },
		[Children] = {
			C.Text(scope, { Text = "Variants", Variant = "Label", LayoutOrder = 0 }),
			C.Button(scope, { Text = "Filled", Variant = "Filled", Color = "primary", LayoutOrder = 1 }),
			C.Button(scope, { Text = "Tonal", Variant = "Tonal", Color = "primary", LayoutOrder = 2 }),
			C.Button(scope, { Text = "Outlined", Variant = "Outlined", Color = "primary", LayoutOrder = 3 }),
			C.Text(scope, { Text = "Material swatches", Variant = "Label", LayoutOrder = 4 }),
			C.Button(scope, { Text = "Blue 500", Variant = "Filled", Color = "Blue 500", LayoutOrder = 5 }),
			C.Button(scope, { Text = "Blue 700", Variant = "Filled", Color = "Blue 700", LayoutOrder = 6 }),
			C.Button(scope, { Text = "Red A200", Variant = "Filled", Color = "Red A200", LayoutOrder = 7 }),
			C.Button(scope, { Text = "Teal 400", Variant = "Tonal", Color = { Teal = 400 }, LayoutOrder = 8 }),
			C.Button(scope, { Text = "Grey 600", Variant = "Tonal", Color = "Grey 600", LayoutOrder = 9 }),
			C.Button(scope, { Text = "DeepPurple 500", Variant = "Outlined", Color = "DeepPurple 500", LayoutOrder = 10 }),
			C.Text(scope, { Text = "Semantic", Variant = "Label", LayoutOrder = 11 }),
			C.Button(scope, { Text = "Secondary", Variant = "Tonal", Color = "secondary", LayoutOrder = 12 }),
			C.Button(scope, { Text = "Error", Variant = "Filled", Color = "error", LayoutOrder = 13 }),
			C.Button(scope, { Text = "Disabled", Disabled = true, LayoutOrder = 14 }),
		},
	})
end)
