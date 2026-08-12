--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 12 },
		[Children] = {
			C.Progress(scope, { Value = 0.55, Mode = "Determinate" }),
			C.Progress(scope, { Mode = "Indeterminate" }),
			C.Progress(scope, { Value = 0.3, Buffer = 0.65, Mode = "Buffering" }),
		},
	})
end)
