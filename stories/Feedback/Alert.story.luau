--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	local Children = StoryUtil.Fusion.Children
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 8 },
		[Children] = {
			C.Alert(scope, { Title = "Info", Text = "Opaque MD3 alert.", Tone = "Info" }),
			C.Alert(scope, { Title = "Success", Text = "Saved.", Tone = "Success" }),
			C.Alert(scope, { Title = "Warning", Text = "Check this.", Tone = "Warning" }),
			C.Alert(scope, { Title = "Error", Text = "Something failed.", Tone = "Error" }),
		},
	})
end)
