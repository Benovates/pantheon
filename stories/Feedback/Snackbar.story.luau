--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.Snackbar(scope, {
		Message = "Saved successfully",
		ActionText = "Undo",
		OnAction = function() end,
	})
end)
