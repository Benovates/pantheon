--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.EmptyState(scope, {
		Title = "Nothing here",
		Subtitle = "Empty state sample",
		Action = { Text = "Retry", Variant = "Tonal" },
	})
end)
