--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)
local Children = StoryUtil.Fusion.Children

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	local notifyOn = scope:Value(true)
	local theme = ctx.theme
	local function close()
		open:set(false)
	end

	local drawer = C.NavigationDrawer(scope, {
		Open = open,
		Title = "Cadence",
		Subtitle = "Window shell",
		AvatarInitials = "EU",
		Inset = 4,
		CornerRadius = theme.Metrics.RadiusPanel - 3,
		OnClose = close,
		InitialPage = "root",
		Sections = {
			{
				Items = {
					{ Text = "Home", Leading = "home", OnClick = close },
					{ Text = "Library", Leading = "library", OnClick = close },
					{ Text = "Search", Leading = "search", OnClick = close },
				},
			},
			{
				Title = "Account",
				Icon = "user",
				Collapsible = true,
				DefaultExpanded = true,
				Items = {
					{ Text = "Profile", Leading = "circle-user", OnClick = close },
					{
						Text = "Settings",
						Leading = "settings",
						Trailing = "chevron-right",
						Page = "settings",
					},
					{ Text = "Sign out", Leading = "log-out", Color = "error", OnClick = close },
				} :: { any },
			},
		},
		Children = {
			C.MenuPage(scope, {
				Id = "settings",
				Title = "Settings",
				Children = {
					C.MenuButton(scope, {
						Text = "Notifications",
						Leading = "bell",
						Trailing = C.Switch(scope, { Checked = notifyOn }),
						LayoutOrder = 1,
					}),
					C.MenuButton(scope, {
						Text = "Appearance",
						Leading = "moon",
						Trailing = "chevron-right",
						Page = "appearance",
						LayoutOrder = 2,
					}),
					C.MenuButton(scope, {
						Text = "Language",
						Leading = "globe",
						Trailing = "chevron-right",
						Page = "language",
						LayoutOrder = 3,
					}),
				},
			}),
			C.MenuPage(scope, {
				Id = "appearance",
				Title = "Appearance",
				Children = {
					C.RadioGroup(scope, {
						Options = {
							{ Label = "Light", Value = "light" },
							{ Label = "Dark", Value = "dark" },
						},
					}),
				},
			}),
			C.MenuPage(scope, {
				Id = "language",
				Title = "Language",
				Children = {
					C.RadioGroup(scope, {
						Options = {
							{ Label = "English", Value = "english" },
							{ Label = "Spanish", Value = "spanish" },
							{ Label = "French", Value = "french" },
							{ Label = "German", Value = "german" },
							{ Label = "Italian", Value = "italian" },
							{ Label = "Portuguese", Value = "portuguese" },
							{ Label = "Russian", Value = "russian" },
							{ Label = "Turkish", Value = "turkish" },
						},
					}),
				},
			}),
		},
	})

	return C.Window(scope, {
		Size = UDim2.new(1, 0, 0, 420),
		RailOrientation = "Horizontal",
		AppBar = C.AppBar(scope, {
			Title = "Window",
			Leading = C.IconButton(scope, {
				Name = "menu",
				OnClick = function()
					open:set(true)
				end,
			}),
			Actions = {
				C.IconButton(scope, { Name = "ellipsis" }),
			},
		}),
		NavigationRail = C.NavigationRail(scope, {
			Orientation = "Horizontal",
			Items = {
				{ Id = "home", Icon = "home", Label = "Home" },
				{ Id = "lib", Icon = "library", Label = "Library" },
				{ Id = "set", Icon = "settings", Label = "Settings" },
			},
		}),
		Overlays = { drawer },
		Children = {
			scope:Frame({
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Padding = { theme.Metrics.SpaceMd },
				Layout = {
					Kind = "List",
					Padding = theme.Metrics.SpaceSm,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[Children] = {
					C.Text(scope, {
						Text = "Rounded Sheet chrome with AppBar, rail, and an inset drawer.",
						Variant = "Body",
						LayoutOrder = 1,
					}),
					C.Button(scope, {
						Text = "Open drawer",
						LeadingIcon = "menu",
						LayoutOrder = 2,
						OnClick = function()
							open:set(true)
						end,
					}),
				},
			}),
		},
	})
end)
