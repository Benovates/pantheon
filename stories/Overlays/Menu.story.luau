--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)

return StoryUtil.story(function(scope, C, ctx)
	local open = scope:Value(false)
	local notifyOn = scope:Value(true)
	local function close()
		open:set(false)
	end
	local trigger = C.Button(scope, {
		Text = "Open menu",
		Variant = "Tonal" :: "Tonal",
		OnClick = function()
			open:set(true)
		end,
	})
	C.Menu(scope, {
		Layer = ctx.overlayLayer,
		Open = open,
		OnClose = close,
		MaxHeight = 280,
		InitialPage = "root",
		Children = {
			C.MenuPage(scope, {
				Id = "root",
				LayoutOrder = 1,
				Children = {
					C.MenuSection(scope, {
						Title = "File",
						Icon = "folder",
						LayoutOrder = 1,
						Children = {
							C.MenuButton(scope, {
								Text = "New",
								Leading = "file-plus",
								OnClose = close,
								LayoutOrder = 1,
							}),
							C.MenuButton(scope, {
								Text = "Open",
								Leading = "folder-open",
								OnClose = close,
								LayoutOrder = 2,
							}),
							C.MenuButton(scope, {
								Text = "Save",
								Leading = "save",
								Trailing = "corner-down-left",
								OnClose = close,
								LayoutOrder = 3,
							}),
						},
					}),
					C.MenuSection(scope, {
						Title = "Edit",
						Icon = "pencil",
						Collapsible = true,
						DefaultExpanded = true,
						LayoutOrder = 2,
						Children = {
							C.MenuButton(scope, {
								Text = "Cut",
								Leading = "scissors",
								OnClose = close,
								LayoutOrder = 1,
							}),
							C.MenuButton(scope, {
								Text = "Copy",
								Leading = "copy",
								OnClose = close,
								LayoutOrder = 2,
							}),
							C.MenuButton(scope, {
								Text = "Paste",
								Leading = "clipboard",
								OnClose = close,
								LayoutOrder = 3,
							}),
							C.MenuButton(scope, {
								Text = "Disabled",
								Leading = "ban",
								Disabled = true,
								LayoutOrder = 4,
							}),
						},
					}),
					C.MenuSection(scope, {
						Title = "Account",
						Icon = "user",
						LayoutOrder = 3,
						Children = {
							C.MenuButton(scope, {
								Text = "Settings",
								Leading = "settings",
								Trailing = "chevron-right",
								Page = "settings",
								LayoutOrder = 1,
							}),
							C.MenuButton(scope, {
								Text = "Sign out",
								Leading = "log-out",
								Color = "error",
								OnClose = close,
								LayoutOrder = 2,
							}),
						},
					}),
				},
			}),
			C.MenuPage(scope, {
				Id = "settings",
				Title = "Settings",
				LayoutOrder = 2,
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
						OnClose = close,
						LayoutOrder = 2,
					}),
				},
			}),
		},
	})
	return trigger
end)
