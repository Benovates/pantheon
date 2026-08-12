--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local checked = scope:Value(true)
	return C.Radio(scope, {
		Label = "Option",
		Checked = checked,
		OnActivated = function()
			checked:set(not StoryUtil.Fusion.peek(checked))
		end,
	})
end)
