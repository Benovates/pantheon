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
			Padding = 8,
		},
		[Children] = {
			C.IconButton(scope, { Name = "menu" }),
			C.IconButton(scope, { Name = "moon" }),
			C.IconButton(scope, { Name = "bell" }),
		},
	})
end)
