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
			C.Switch(scope, { Label = "Enabled" }),
			C.Switch(scope, { Label = "Disabled", Disabled = true, Checked = true }),
		},
	})
end)
