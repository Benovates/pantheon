--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, _ctx)
	return C.Form(scope, {
		Title = "Profile",
		Children = {
			C.TextField(scope, { Label = "Name", Placeholder = "Type…", LayoutOrder = 1 }),
			C.Checkbox(scope, { Label = "Public profile", LayoutOrder = 2 }),
			C.Button(scope, { Text = "Save", Variant = "Primary", LayoutOrder = 3 }),
		},
	})
end)
