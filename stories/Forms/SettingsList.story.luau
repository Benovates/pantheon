--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	return C.SettingsList(scope, {
		Header = "Account",
		Items = {
			{ Title = "Profile", Subtitle = "Name, email, avatar", Icon = "user", OnClick = function() end },
			{ Title = "Notifications", Subtitle = "Push & email", Icon = "bell", OnClick = function() end },
			{
				Title = "Dark mode",
				Subtitle = "Appearance",
				Icon = "moon",
				Trailing = C.Switch(scope, { Checked = false }),
				ShowChevron = false,
			},
		},
	})
end)
