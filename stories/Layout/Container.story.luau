--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Container(scope, {
		MaxWidth = 480,
		Size = UDim2.new(1, 0, 0, 160),
		Children = {
			C.Text(scope, { Text = "Constrained container content.", Variant = "Body" }),
			C.Button(scope, { Text = "Action", Variant = "Tonal" }),
		},
	})
end)
