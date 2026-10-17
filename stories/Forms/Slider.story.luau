--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.Slider(scope, { Label = "Level", Min = 0, Max = 10, Step = 1 })
end)
