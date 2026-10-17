--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C)
	return C.Breadcrumbs(scope, {
		Items = {
			{ Label = "Home" },
			{ Label = "Library" },
			{ Label = "Catalog" },
		},
	})
end)
