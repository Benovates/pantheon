--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local Children = StoryUtil.Fusion.Children
	local V = ctx.Pantheon.Validators
	return scope:Frame({
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		Layout = { Kind = "List", Padding = 12, SortOrder = Enum.SortOrder.LayoutOrder },
		[Children] = {
			C.TextField(scope, { Label = "Name", Placeholder = "Type…", LayoutOrder = 1 }),
			C.TextField(scope, {
				Label = "Notes",
				Placeholder = "Multiline…",
				Multiline = true,
				MinLines = 3,
				MaxLines = 6,
				Resize = "Y",
				LayoutOrder = 2,
			}),
			C.TextField(scope, {
				Label = "Email",
				Placeholder = "you@game.com",
				Error = "Required field",
				LayoutOrder = 3,
			}),
			C.TextField(scope, {
				Label = "Validated email",
				LeadingIcon = "mail",
				Placeholder = "you@game.com",
				Validators = { V.required(), V.email() },
				LayoutOrder = 4,
			}),
		},
	})
end)
