--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.TimePicker(scope, {})
end)
