--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.RangeSlider(scope, {
		Label = "Price",
		Min = 0,
		Max = 100,
		Step = 1,
		Value = NumberRange.new(20, 60),
	})
end)
