--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = 24,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},
		[Children] = {
			C.LoadingIndicator(scope, { SizePx = 48, LayoutOrder = 1 }),
			C.LoadingIndicator(scope, { SizePx = 56, Contained = true, LayoutOrder = 2 }),
			C.LoadingIndicator(scope, { SizePx = 96, Contained = true, LayoutOrder = 3 }),
		},
	})
end)
