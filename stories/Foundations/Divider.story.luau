--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 12 },
		[Children] = {
			C.Text(scope, { Text = "Above", Variant = "Body" }),
			C.Divider(scope, {}),
			C.Text(scope, { Text = "Below", Variant = "Body" }),
		},
	})
end)
