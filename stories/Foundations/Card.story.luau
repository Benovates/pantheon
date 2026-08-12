--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Card(scope, {
		Title = "Card",
		Subtitle = "Elevated surface",
	})
end)
