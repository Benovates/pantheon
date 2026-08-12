--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Badge(scope, {
		Count = 3,
		Content = C.IconButton(scope, { Name = "bell" }),
	})
end)
