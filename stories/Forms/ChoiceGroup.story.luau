--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.ChoiceGroup(scope, {
		Label = "Plan",
		Variant = "Segmented",
		Options = {
			{ Value = "free", Label = "Free" },
			{ Value = "pro", Label = "Pro" },
		},
	})
end)
