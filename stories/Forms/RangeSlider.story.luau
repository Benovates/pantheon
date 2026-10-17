--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.RangeSlider(scope, { Min = 0, Max = 100 })
end)
