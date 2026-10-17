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
			Padding = 12,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},
		[Children] = {
			C.Icon(scope, { Name = "sparkles", IconSize = 28 }),
			C.Icon(scope, { Name = "bell", IconSize = 28 }),
			C.Icon(scope, { Name = "home", IconSize = 28 }),
			C.Icon(scope, { Name = "settings", IconSize = 28 }),
		},
	})
end)
