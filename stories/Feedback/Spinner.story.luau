--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = 16,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},
		[Children] = {
			C.Spinner(scope, { SizePx = 22 }),
			C.Spinner(scope, { SizePx = 36 }),
			C.Text(scope, { Text = "Loading…", Variant = "Label" }),
		},
	})
end)
