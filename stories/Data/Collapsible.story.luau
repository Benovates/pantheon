--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.Collapsible(scope, {
		Title = "Advanced",
		Children = {
			C.Text(scope, { Text = "Hidden until expanded.", Variant = "Body" }),
		},
	})
end)
