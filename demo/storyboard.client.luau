--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local EstuaryUI = require(Packages.EstuaryUI)
local Fusion = EstuaryUI.Fusion
local Children = Fusion.Children
local peek = Fusion.peek

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local rootScope = EstuaryUI.scoped()
local C = EstuaryUI.Components

local mode = rootScope:Value("Light" :: "Light" | "Dark")
local scrollY = rootScope:Value(0)
local railOrientation = rootScope:Value("Horizontal" :: "Vertical" | "Horizontal")
local animateTheme = rootScope:Value(true)
local sheetOpen = rootScope:Value(false)
local refreshing = rootScope:Value(false)
local uiScope: any = nil
local V = EstuaryUI.Validators

local function appendSection(scope: any, into: { any }, title: string, order: number, kids: { any })
	local children = {
		C.Text(scope, { Text = title, Variant = "Title", LayoutOrder = 0 }),
	}
	for _, kid in kids do
		if kid ~= nil then
			table.insert(children, kid)
		end
	end
	table.insert(
		into,
		scope:Frame({
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			-- Do not clip: UIStroke / slider thumbs bleed past layout bounds.
			ClipsDescendants = false,
			Layout = {
				Kind = "List",
				Padding = 8,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			[Children] = children,
		})
	)
end

local function rebuild()
	if uiScope then
		Fusion.doCleanup(uiScope)
		uiScope = nil
	end

	uiScope = Fusion.innerScope(rootScope)
	local scope = uiScope
	-- Apps can use Theme.createAnimated(scope, mode, { Animate = true }) for live color blends.
	local theme = if peek(animateTheme)
		then peek(EstuaryUI.Theme.createAnimated(scope, mode, { Animate = true }) :: any)
		else EstuaryUI.Theme.create(peek(mode), { RespectAccessibility = true })

	EstuaryUI.Theme.Provide(theme, function()
		local drawerOpen = scope:Value(false)
		local promptOpen = scope:Value(false)
		local avatarMenuOpen = scope:Value(false)
		local popoverOpen = scope:Value(false)
		local rows = {}
		for i = 1, 200 do
			table.insert(rows, {
				id = i,
				name = "Row " .. i,
				role = if i % 2 == 0 then "Mod" else "User",
			})
		end
		local tableRows = scope:Value(rows)
		local sections = {}

		local overlayLayer = scope:Frame({
			Name = "OverlayLayer",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 50,
		}) :: Frame

		local host = C.SnackbarHost(scope, { Layer = overlayLayer })
		local avatarBtn
		local popoverBtn
		local themeBtn

		appendSection(scope, sections, "Typography & actions", 1, {
			C.Text(scope, { Text = "Display", Variant = "Display", LayoutOrder = 1 }),
			C.Text(scope, { Text = "Body copy for Cadence/Tithe surfaces.", Variant = "Body", LayoutOrder = 2 }),
			C.Button(scope, { Text = "Primary", Variant = "Primary", LayoutOrder = 3 }),
			C.Button(scope, { Text = "Tonal", Variant = "Tonal", LayoutOrder = 4 }),
			C.Button(scope, { Text = "Outlined", Variant = "Outlined", LayoutOrder = 5 }),
			C.Button(scope, { Text = "Disabled", Disabled = true, LayoutOrder = 6 }),
			C.Chip(scope, { Text = "Chip", Selected = true, LayoutOrder = 7 }),
		})
		appendSection(scope, sections, "Cadence controls", 7, {
			C.SettingsList(scope, {
				LayoutOrder = 1,
				Header = "Account",
				Items = {
					{ Title = "Profile", Subtitle = "Name, email, avatar", Icon = "user", OnClick = function() end },
					{ Title = "Notifications", Subtitle = "Push & email", Icon = "bell", OnClick = function() end },
					{
						Title = "Animate theme",
						Subtitle = "Use Theme.createAnimated in apps",
						Icon = "sparkles",
						Trailing = C.Switch(scope, {
							Checked = peek(animateTheme),
							OnChanged = function(on)
								animateTheme:set(on)
							end,
						}),
						ShowChevron = false,
					},
					{
						Title = "Dark mode",
						Subtitle = "Appearance",
						Icon = "moon",
						Trailing = C.Switch(scope, {
							Checked = peek(mode) == "Dark",
							OnChanged = function(on)
								mode:set(if on then "Dark" else "Light")
							end,
						}),
						ShowChevron = false,
					},
				},
			}),
			C.SegmentedControl(scope, {
				LayoutOrder = 2,
				Items = {
					{ Id = "day", Label = "Day" },
					{ Id = "week", Label = "Week" },
					{ Id = "month", Label = "Month" },
				},
			}),
			C.StarRating(scope, { LayoutOrder = 3, Value = 4 }),
			C.MultiSelect(scope, {
				LayoutOrder = 4,
				Layer = overlayLayer,
				Label = "Tags",
				Display = "Chips",
				Options = {
					{ Value = "a", Label = "Alpha" },
					{ Value = "b", Label = "Beta" },
					{ Value = "c", Label = "Gamma" },
				},
			}),
			C.MultiSelect(scope, {
				LayoutOrder = 4,
				Layer = overlayLayer,
				Label = "Tags (count)",
				Display = "Count",
				Options = {
					{ Value = "a", Label = "Alpha" },
					{ Value = "b", Label = "Beta" },
					{ Value = "c", Label = "Gamma" },
				},
			}),
			C.Collapsible(scope, {
				LayoutOrder = 5,
				Title = "Advanced",
				Children = {
					C.Text(scope, { Text = "Hidden until expanded.", Variant = "Body" }),
				},
			}),
			C.TreeView(scope, {
				LayoutOrder = 6,
				Nodes = {
					{
						Id = "src",
						Label = "src",
						Icon = "folder",
						Children = {
							{ Id = "btn", Label = "Button.luau", Icon = "file" },
							{ Id = "theme", Label = "Theme", Icon = "folder", Children = {
								{ Id = "init", Label = "init.luau", Icon = "file" },
							} },
						},
					},
				},
			}),
			C.Button(scope, {
				Text = "Open app sheet",
				LeadingIcon = "panel-bottom",
				LayoutOrder = 7,
				OnClick = function()
					sheetOpen:set(true)
				end,
			}),
			C.TextField(scope, {
				LayoutOrder = 8,
				Label = "Email",
				LeadingIcon = "mail",
				Placeholder = "you@game.com",
				Validators = { V.required(), V.email() },
			}),
			C.Chip(scope, { Text = "Filter", LeadingIcon = "filter", LayoutOrder = 9 }),
			C.ChoiceGroup(scope, {
				LayoutOrder = 10,
				Label = "Plan",
				Variant = "Segmented",
				Options = {
					{ Value = "free", Label = "Free" },
					{ Value = "pro", Label = "Pro" },
				},
			}),
		})
		appendSection(scope, sections, "Forms", 2, {
			C.TextField(scope, { Label = "Name", Placeholder = "Type…", LayoutOrder = 1 }),
			C.TextField(scope, {
				Label = "Notes",
				Placeholder = "Multiline…",
				Multiline = true,
				MinLines = 3,
				MaxLines = 6,
				Resize = "Y",
				LayoutOrder = 1,
			}),
			C.TextField(scope, {
				Label = "Email",
				Placeholder = "you@game.com",
				Error = "Required field",
				LayoutOrder = 1,
			}),
			C.Checkbox(scope, { Label = "Accept", LayoutOrder = 2 }),
			C.Checkbox(scope, { Label = "Disabled", Disabled = true, LayoutOrder = 2 }),
			C.Switch(scope, { Label = "Enabled", LayoutOrder = 3 }),
			C.Switch(scope, { Label = "Disabled", Disabled = true, Checked = true, LayoutOrder = 3 }),
			C.RadioGroup(scope, {
				LayoutOrder = 4,
				Options = {
					{ Value = "a", Label = "Alpha" },
					{ Value = "b", Label = "Beta" },
				},
			}),
			C.Select(scope, {
				LayoutOrder = 5,
				Label = "Role",
				Layer = overlayLayer,
				Options = {
					{ Value = "mod", Label = "Moderator" },
					{ Value = "admin", Label = "Admin" },
				},
			}),
			C.Slider(scope, { Label = "Level", Min = 0, Max = 10, Step = 1, LayoutOrder = 6 }),
			C.RangeSlider(scope, { Min = 0, Max = 100, LayoutOrder = 7 }),
		})
		appendSection(scope, sections, "Feedback", 3, {
			C.Alert(scope, { Title = "Info", Text = "Opaque MD3 alert.", Tone = "Info", LayoutOrder = 1 }),
			C.Progress(scope, { Value = 0.55, Mode = "Determinate", LayoutOrder = 2 }),
			C.Progress(scope, { Mode = "Indeterminate", LayoutOrder = 2 }),
			C.Progress(scope, { Value = 0.3, Buffer = 0.65, Mode = "Buffering", LayoutOrder = 2 }),
			C.Spinner(scope, { SizePx = 36, LayoutOrder = 2 }),
			scope:Frame({
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				LayoutOrder = 2,
				Visible = refreshing,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = 8,
				},
				[Children] = {
					C.Spinner(scope, { SizePx = 22 }),
					C.Text(scope, { Text = "Refreshing…", Variant = "Label" }),
				},
			}),
			C.Icon(scope, { Name = "sparkles", IconSize = 28, LayoutOrder = 2 }),
			C.Badge(scope, {
				LayoutOrder = 3,
				Count = 3,
				Content = C.IconButton(scope, { Name = "bell" }),
			}),
			C.Button(scope, {
				Text = "Toast",
				LayoutOrder = 4,
				OnClick = function()
					host.Show("Saved successfully")
				end,
			}),
			C.Button(scope, {
				Text = "Open prompt",
				Variant = "Outlined",
				LayoutOrder = 5,
				OnClick = function()
					promptOpen:set(true)
				end,
			}),
			C.Text(scope, {
				Text = "Pull down on the main scroll to refresh.",
				Variant = "Label",
				LayoutOrder = 6,
			}),
		})
		appendSection(scope, sections, "Navigation", 4, {
			C.Breadcrumbs(scope, {
				LayoutOrder = 1,
				Items = {
					{ Label = "Home" },
					{ Label = "Library" },
					{ Label = "Catalog" },
				},
			}),
			C.Tabs(scope, {
				LayoutOrder = 2,
				Items = {
					{ Id = "one", Label = "One" },
					{ Id = "two", Label = "Two" },
				},
			}),
			C.Pagination(scope, { PageCount = 5, LayoutOrder = 3 }),
			C.Card(scope, {
				Title = "Card",
				Subtitle = "Elevated surface",
				LayoutOrder = 4,
			}),
			C.Divider(scope, { LayoutOrder = 5 }),
			C.Button(scope, {
				Text = scope:Computed(function(use)
					return if use(railOrientation) == "Vertical"
						then "Rail → Horizontal"
						else "Rail → Vertical"
				end),
				Variant = "Tonal",
				LayoutOrder = 6,
				OnClick = function()
					railOrientation:set(if peek(railOrientation) == "Vertical" then "Horizontal" else "Vertical")
					rebuild()
				end,
			}),
			(function()
				popoverBtn = C.Button(scope, {
					Text = "Open popover",
					Variant = "Tonal",
					LayoutOrder = 7,
					OnClick = function()
						popoverOpen:set(true)
					end,
				})
				return popoverBtn
			end)(),
			(function()
				avatarBtn = C.Button(scope, {
					Text = "Avatar menu",
					Variant = "Outlined",
					LayoutOrder = 8,
					OnClick = function()
						avatarMenuOpen:set(true)
					end,
				})
				return avatarBtn
			end)(),
		})
		appendSection(scope, sections, "Pickers", 5, {
			C.DatePicker(scope, { LayoutOrder = 1 }),
			C.TimePicker(scope, { LayoutOrder = 2 }),
			C.ColorPicker(scope, { LayoutOrder = 3 }),
		})
		appendSection(scope, sections, "Data", 6, {
			C.Avatar(scope, { Initials = "EU", LayoutOrder = 1 }),
			scope:Frame({
				Size = UDim2.new(1, 0, 0, 220),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				[Children] = {
					C.DataTable(scope, {
						Columns = {
							{ Id = "id", Title = "Id", Width = 60 },
							{ Id = "name", Title = "Name", Width = 140 },
							{ Id = "role", Title = "Role", Width = 100 },
						},
						Rows = tableRows,
						Size = UDim2.fromScale(1, 1),
					}),
				},
			}),
			scope:Frame({
				Size = UDim2.new(1, 0, 0, 160),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				[Children] = {
					C.VirtualList(scope, {
						ItemCount = 1000,
						ItemHeight = 28,
						Size = UDim2.fromScale(1, 1),
						RenderItem = function(rowScope, index)
							return rowScope:TextLabel({
								BackgroundColor3 = theme.Colors.SurfaceContainer,
								Text = "Virtual row " .. index,
								TextColor3 = theme.Colors.OnSurface,
								FontFace = theme.Fonts.Body,
								TextSize = 12,
								TextXAlignment = Enum.TextXAlignment.Left,
								Padding = { 4 },
							})
						end,
					}),
				},
			}),
			C.EmptyState(scope, {
				Title = "Nothing here",
				Subtitle = "Empty state sample",
				LayoutOrder = 4,
				Action = { Text = "Retry", Variant = "Tonal" },
			}),
		})

		C.Prompt(scope, {
			Layer = overlayLayer,
			Title = "Discard changes?",
			Body = "Your edits will be lost. This action cannot be undone.",
			Icon = "triangle-alert",
			Open = promptOpen,
			ConfirmText = "Discard",
			Destructive = true,
			OnClose = function()
				promptOpen:set(false)
			end,
			OnConfirm = function()
				promptOpen:set(false)
				host.Show("Discarded")
			end,
		})
		C.NavigationDrawer(scope, {
			Layer = overlayLayer,
			Open = drawerOpen,
			Title = "Cadence",
			Subtitle = "estuary-ui catalog",
			AvatarInitials = "EU",
			OnClose = function()
				drawerOpen:set(false)
			end,
			Items = {
				{ Title = "Forms", OnClick = function() end },
				{ Title = "Navigation", OnClick = function() end },
				{ Title = "Data", OnClick = function() end },
			},
		})
		C.Popover(scope, {
			Layer = overlayLayer,
			Open = popoverOpen,
			Target = popoverBtn,
			Placement = "Bottom",
			OnClose = function()
				popoverOpen:set(false)
			end,
			Items = {
				{
					Text = "Action A",
					OnClick = function()
						host.Show("Action A")
					end,
				},
				{
					Text = "Action B",
					OnClick = function()
						host.Show("Action B")
					end,
				},
				{ Text = "Disabled", Disabled = true },
			},
		})
		C.AvatarMenu(scope, {
			Layer = overlayLayer,
			Open = avatarMenuOpen,
			Target = avatarBtn,
			Initials = "EU",
			Name = "Estuary User",
			Subtitle = "you@game.com",
			OnClose = function()
				avatarMenuOpen:set(false)
			end,
			Items = {
				{
					Text = "Profile",
					OnClick = function()
						host.Show("Profile")
					end,
				},
				{
					Text = "Settings",
					OnClick = function()
						host.Show("Settings")
					end,
				},
				{
					Text = "Sign out",
					OnClick = function()
						host.Show("Signed out")
					end,
				},
			},
		})
		C.AppSheet(scope, {
			Layer = overlayLayer,
			Open = sheetOpen,
			Title = "Quick sheet",
			OnClose = function()
				sheetOpen:set(false)
			end,
			Children = {
				C.Text(scope, { Text = "iOS-style app sheet with grabber + scrim.", Variant = "Body" }),
				C.StarRating(scope, { Value = 5 }),
			},
		})

		themeBtn = C.IconButton(scope, {
			Name = if peek(mode) == "Light" then "moon" else "sun",
			OnClick = function()
				mode:set(if peek(mode) == "Light" then "Dark" else "Light")
			end,
		})
		C.Tooltip(scope, {
			Layer = overlayLayer,
			Target = themeBtn,
			Text = if peek(mode) == "Light" then "Switch to dark" else "Switch to light",
			Placement = "Auto",
		})

		local verticalRail = peek(railOrientation) == "Vertical"
		local rail = C.NavigationRail(scope, {
			Orientation = peek(railOrientation),
			Layer = overlayLayer,
			Items = {
				{ Id = "home", Icon = "home", Label = "Home" },
				{ Id = "lib", Icon = "library", Label = "Lib" },
				{ Id = "set", Icon = "settings", Label = "Settings" },
			},
		})

		local scrollKids = {
			scope:Frame({
				Name = "PullHint",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = -1,
				Visible = refreshing,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = 8,
				},
				[Children] = {
					C.Spinner(scope, { SizePx = 20 }),
					C.Text(scope, { Text = "Refreshing feed…", Variant = "Label" }),
				},
			}),
		}
		for _, section in sections do
			table.insert(scrollKids, section)
		end

		local scroll = C.ScrollArea(scope, {
			Children = scrollKids,
			Smooth = true,
			Inertia = true,
			Keyboard = true,
			AutoCanvas = true,
			Overscroll = true,
			ScrollBarRail = true,
			ScrollBarRailBackground = true,
			ScrollBarThickness = 8,
			ScrollBarRailThickness = 2,
			ScrollBarPadding = 8,
			ScrollButtons = true,
			AutoHideScrollBar = true,
			ScrollOffset = peek(scrollY),
			OnScroll = function(y)
				scrollY:set(y)
			end,
			OnRefresh = function()
				if peek(refreshing) then
					return
				end
				refreshing:set(true)
				host.Show("Pull to refresh…")
				task.delay(1.2, function()
					refreshing:set(false)
					host.Show("Feed updated")
				end)
			end,
		})

		scope:New("ScreenGui")({
			Name = "EstuaryUIStoryboard",
			ResetOnSpawn = false,
			Parent = playerGui,
			[Children] = {
				scope:Frame({
					Name = "Root",
					BackgroundColor3 = theme.Colors.Background,
					Size = UDim2.fromScale(1, 1),
					[Children] = {
						C.AppBar(scope, {
							Title = "estuary-ui catalog",
							Leading = C.IconButton(scope, {
								Name = "menu",
								OnClick = function()
									drawerOpen:set(true)
								end,
							}),
							Actions = { themeBtn },
						}),
						scope:Hydrate(rail)({
							Position = if verticalRail
								then UDim2.fromOffset(0, theme.Metrics.AppBarHeight)
								else UDim2.new(0, 0, 1, -theme.Metrics.AppBarHeight),
							Size = if verticalRail
								then UDim2.new(0, theme.Metrics.RailWidth, 1, -theme.Metrics.AppBarHeight)
								else UDim2.new(1, 0, 0, theme.Metrics.AppBarHeight),
						}),
						scope:Hydrate(scroll)({
							Position = if verticalRail
								then UDim2.fromOffset(theme.Metrics.RailWidth, theme.Metrics.AppBarHeight)
								else UDim2.fromOffset(0, theme.Metrics.AppBarHeight),
							Size = if verticalRail
								then UDim2.new(1, -theme.Metrics.RailWidth, 1, -theme.Metrics.AppBarHeight)
								else UDim2.new(1, 0, 1, -theme.Metrics.AppBarHeight * 2),
						}),
						overlayLayer,
					},
				}),
			},
		})
	end)
end

rebuild()
rootScope:Observer(mode):onChange(rebuild)

print("estuary-ui storyboard — full Cadence catalog (light/dark)")
