--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.RadioGroup(scope, {
		Options = {
			{ Value = "a", Label = "Alpha" },
			{ Value = "b", Label = "Beta" },
		},
	})
end)
