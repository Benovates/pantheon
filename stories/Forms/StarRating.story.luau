--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.StarRating(scope, { Value = 4 })
end)
