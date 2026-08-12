--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 0 },
		[Children] = {
			C.Text(scope, { Text = "Before spacer", Variant = "Body" }),
			C.Spacer(scope, { Size = UDim2.new(1, 0, 0, 24) }),
			C.Text(scope, { Text = "After spacer", Variant = "Body" }),
		},
	})
end)
