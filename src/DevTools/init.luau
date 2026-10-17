--!strict
--[[
	In-game dev tools, modelled on React DevTools: a docked panel with a Components tab (a tree
	of the live interface and an editable properties pane), a Profiler tab that counts changes,
	and Settings. Highlight Updates flashes whatever changes.
	See docs/Modules/DevTools.md.

		Pantheon.Flags.DevTools = true
		local unmount = Pantheon.DevTools.mount()   -- F8 opens and closes the panel
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Packages = script.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Types)
local Flags = require(script.Parent.Internal.Flags)
local ScrollInput = require(script.Parent.Internal.ScrollInput)
local resolveTheme = require(script.Parent.Internal.resolveTheme).resolveTheme
local Details = require(script.Details)

local Children = Fusion.Children
local peek = Fusion.peek

export type Props = {
	--- Where the overlay ScreenGui is parented (default: the local PlayerGui).
	Parent: Instance?,
	--- Opens and closes the panel (default F8).
	Hotkey: Enum.KeyCode?,
	--- Theme of the tools. The default is a dark theme of their own, so they look the same in any app.
	Theme: Types.ThemeRef?,
	--- Open at once (default false).
	Open: boolean?,
	--- Height of the panel in px (default 340).
	Height: number?,
}

-- What the profiler does not count: these change whenever the layout does.
local LAYOUT_PROPERTIES: { [string]: boolean } = {
	AbsolutePosition = true,
	AbsoluteSize = true,
	AbsoluteRotation = true,
	AbsoluteContentSize = true,
	AbsoluteCanvasSize = true,
	AbsoluteWindowSize = true,
	Parent = true,
}
local FLASH_TIME = 0.5
local MAX_FLASHES = 30
local PROFILE_ROWS = 20

local function mount(props: Props?): () -> ()
	local p: Props = props or {}
	if not Flags.DevTools then
		warn("[Pantheon.DevTools] Set Pantheon.Flags.DevTools = true before mounting.")
		return function() end
	end

	-- Required here, not at the top: the library requires this module while it loads.
	local Pantheon = require(script.Parent) :: any
	local C = Pantheon.Components
	local theme = if p.Theme then resolveTheme(p) else Pantheon.Theme.create("Dark")
	local colors = theme.Colors
	local scope = Pantheon.scoped()

	-- The tools read the local player's interface, and draw in `Parent`.
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local guiParent = p.Parent or playerGui
	local hotkey = p.Hotkey or Enum.KeyCode.F8

	-- state
	local open = scope:Value(p.Open == true)
	local inspecting = scope:Value(false)
	local highlight = scope:Value(false)
	local recording = scope:Value(false)
	local filter = scope:Value("")
	local picked = scope:Value({} :: { Instance })
	local selected = scope:Value(nil :: Instance?)
	local reveal = scope:Value(nil :: Instance?)
	local hoverFromTree = scope:Value(nil :: Instance?)
	local height = scope:Value(p.Height or 340)
	local profile = scope:Value({} :: { { instance: Instance, count: number, rate: number } })

	local gui = scope:New("ScreenGui")({
		Name = "PantheonDevTools",
		DisplayOrder = 2 ^ 20,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	local function isOwn(instance: Instance): boolean
		return instance == gui or instance:IsDescendantOf(gui)
	end

	local function choose(instance: Instance?)
		selected:set(instance)
		picked:set(if instance then { instance } else {})
		if instance then
			reveal:set(nil)
			reveal:set(instance)
		end
	end
	table.insert(
		scope,
		scope:Observer(picked):onChange(function()
			local list = peek(picked) :: { Instance }
			selected:set(list[#list])
		end)
	)

	-- highlight boxes
	local function box(color: Color3, fill: number): Frame
		return scope:New("Frame")({
			Parent = gui,
			BackgroundColor3 = color,
			BackgroundTransparency = fill,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
			[Children] = scope:New("UIStroke")({ Color = color, Thickness = 2 }),
		}) :: Frame
	end
	local hoverBox = box(Color3.fromRGB(110, 170, 255), 0.75)
	local selectBox = box(colors.Warning, 1)
	local tip = scope:New("TextLabel")({
		Parent = gui,
		ZIndex = 6,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(110, 170, 255),
		BorderSizePixel = 0,
		TextColor3 = Color3.fromRGB(10, 20, 40),
		FontFace = theme.Fonts.Mono,
		TextSize = 12,
		Text = "",
		[Children] = scope:New("UIPadding")({
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		}),
	}) :: TextLabel

	local function outline(frame: Frame, target: GuiObject?)
		if target == nil or not target:IsDescendantOf(game) or isOwn(target) then
			frame.Visible = false
			return
		end
		frame.Visible = true
		frame.Position = UDim2.fromOffset(target.AbsolutePosition.X, target.AbsolutePosition.Y)
		frame.Size = UDim2.fromOffset(target.AbsoluteSize.X, target.AbsoluteSize.Y)
	end

	-- watching for changes (Highlight Updates and the profiler)
	local counts: { [Instance]: number } = {}
	local previous: { [Instance]: number } = {}
	local watchers: { [Instance]: RBXScriptConnection } = {}
	local flashes: { { frame: Frame, target: GuiObject, born: number } } = {}
	local pool: { Frame } = {}

	local function flash(target: GuiObject)
		if #flashes >= MAX_FLASHES or isOwn(target) then
			return
		end
		local frame = table.remove(pool) or box(colors.Warning, 1)
		frame.Visible = true
		table.insert(flashes, { frame = frame, target = target, born = os.clock() })
	end

	local function watch(instance: Instance)
		if watchers[instance] or isOwn(instance) or not instance:IsA("GuiObject") then
			return
		end
		watchers[instance] = (instance :: GuiObject).Changed:Connect(function(property: string)
			if LAYOUT_PROPERTIES[property] then
				return
			end
			counts[instance] = (counts[instance] or 0) + 1
			if peek(highlight) then
				flash(instance :: GuiObject)
			end
		end)
	end
	local descendantAdded: RBXScriptConnection? = nil
	local function setWatching(on: boolean)
		if on and descendantAdded == nil then
			for _, instance in playerGui:GetDescendants() do
				watch(instance)
			end
			descendantAdded = playerGui.DescendantAdded:Connect(watch)
		elseif not on and descendantAdded then
			descendantAdded:Disconnect()
			descendantAdded = nil
			for instance, connection in watchers do
				connection:Disconnect()
				watchers[instance] = nil
			end
		end
	end
	local function refreshWatching()
		setWatching(peek(highlight) or peek(recording))
	end
	table.insert(scope, scope:Observer(highlight):onChange(refreshWatching))
	table.insert(scope, scope:Observer(recording):onChange(refreshWatching))
	table.insert(scope, function()
		setWatching(false)
	end)

	-- the Components tab
	local env = { theme = theme, C = C, select = choose }

	local emptyDetails = C.Text(scope, {
		Theme = theme,
		Text = "Select an element, or press the pointer button and click one.",
		Variant = "Body",
		Color = colors.OnSurfaceVariant,
		TextWrapped = true,
		Size = UDim2.new(1, -20, 0, 0),
	})
	local detailsHost = scope:Frame({
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = scope:Computed(function(use, inner: any)
			local target = use(selected) :: Instance?
			if target == nil or not target:IsDescendantOf(game) then
				return scope:Frame({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 60),
					Padding = { 10 },
					[Children] = emptyDetails,
				})
			end
			return Details.build(inner, env, target)
		end),
	})

	local tree = C.Explorer(scope, {
		Theme = theme,
		Roots = { playerGui },
		Filter = filter,
		Selected = picked,
		Reveal = reveal,
		Include = function(instance: Instance): boolean
			return not isOwn(instance)
		end,
		OnHover = function(instance: Instance?)
			hoverFromTree:set(instance)
		end,
	})
	local left = scope:Frame({
		BackgroundTransparency = 1,
		[Children] = {
			scope:Frame({
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				Padding = { 6 },
				[Children] = C.TextField(scope, {
					Theme = theme,
					Compact = true,
					Placeholder = "Search by name",
					LeadingIcon = "search",
					Text = filter,
				}),
			}),
			scope:Frame({
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 44),
				Size = UDim2.new(1, 0, 1, -44),
				[Children] = tree,
			}),
		},
	})
	local right = C.ScrollArea(scope, {
		Theme = theme,
		Children = { detailsHost },
		ContentPadding = 0,
	})
	local componentsTab = C.SplitPane(scope, {
		Theme = theme,
		Panes = { left, right },
		Ratios = { 5, 4 },
	})

	-- the Profiler tab
	local profilerRows = scope:Computed(function(use, inner: any)
		local list = use(profile) :: { { instance: Instance, count: number, rate: number } }
		local rows: { any } = {
			inner:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
		}
		if #list == 0 then
			table.insert(
				rows,
				C.Text(inner, {
					Theme = theme,
					Text = if peek(recording)
						then "Nothing has changed yet."
						else "Press Record, then use the interface.",
					Variant = "Body",
					Color = colors.OnSurfaceVariant,
					LayoutOrder = 1,
				})
			)
		end
		for index, entry in list do
			table.insert(
				rows,
				C.Button(inner, {
					Theme = theme,
					Variant = "Text",
					LayoutOrder = index,
					Size = UDim2.new(1, 0, 0, 28),
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Text = string.format(
						"%-34s %6d  %5.1f/s",
						string.sub(entry.instance.Name, 1, 34),
						entry.count,
						entry.rate
					),
					OnClick = function()
						choose(entry.instance)
					end,
				})
			)
		end
		return inner:Frame({
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			[Children] = rows :: any,
		})
	end)
	local profilerTab = scope:Frame({
		BackgroundTransparency = 1,
		[Children] = {
			scope:Frame({
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				Padding = { 6 },
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = 8,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				},
				[Children] = {
					C.Switch(scope, {
						Theme = theme,
						Label = "Record",
						Checked = recording,
						LayoutOrder = 1,
					}),
					C.Button(scope, {
						Theme = theme,
						Text = "Clear",
						Variant = "Tonal",
						LayoutOrder = 2,
						OnClick = function()
							table.clear(counts)
							table.clear(previous)
							profile:set({})
						end,
					}),
				},
			}),
			scope:Frame({
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 44),
				Size = UDim2.new(1, 0, 1, -44),
				[Children] = C.ScrollArea(scope, {
					Theme = theme,
					Children = { profilerRows },
					ContentPadding = 8,
				}),
			}),
		},
	})

	-- the Settings tab
	local settingKids: { any } = {}
	for index, setting in
		{
			{ "CanvasFade", "Fade chrome with a CanvasGroup (Flags.CanvasFade)" },
			{ "LifetimeChecks", "Fusion lifetime checks (slow, Flags.LifetimeChecks)" },
			{ "BetaUI", "Use Studio-beta UI features (Flags.BetaUI)" },
		}
	do
		local state = scope:Value((Flags :: any)[setting[1]] == true)
		table.insert(
			settingKids,
			C.Switch(scope, {
				Theme = theme,
				Label = setting[2],
				Checked = state,
				LayoutOrder = index,
				OnChanged = function(on: boolean)
					(Flags :: any)[setting[1]] = on
				end,
			})
		)
	end
	table.insert(
		settingKids,
		C.Text(scope, {
			Theme = theme,
			Text = "Flags apply to what is built after you change them. Rebuild the interface to see the effect.",
			Variant = "Label",
			Color = colors.OnSurfaceVariant,
			TextWrapped = true,
			LayoutOrder = 10,
			Size = UDim2.new(1, 0, 0, 0),
		})
	)
	local settingsTab = C.ScrollArea(scope, {
		Theme = theme,
		Children = settingKids,
		ListPadding = 10,
	})

	-- the panel
	local tipLayer = scope:Frame({
		Name = "TipLayer",
		Parent = gui,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})
	local openS = scope:Spring(
		scope:Computed(function(use)
			return if use(open) then 1 else 0
		end),
		22,
		1
	)

	local actions = C.Toolbar(scope, {
		Theme = theme,
		Layer = tipLayer,
		Size = UDim2.fromOffset(78, 28),
		Items = {
			{
				Id = "inspect",
				Icon = "mouse-pointer",
				Tooltip = "Select an element in the page to inspect it",
				Toggle = true,
				Toggled = inspecting,
			},
			{
				Id = "highlight",
				Icon = "zap",
				Tooltip = "Highlight updates",
				Toggle = true,
				Toggled = highlight,
			},
		},
	})
	local panelHeight = scope:Computed(function(use)
		return use(height)
	end)
	local dock = C.DockPanel(scope, {
		Theme = theme,
		Tabs = {
			{ Id = "components", Title = "Components", Content = componentsTab },
			{ Id = "profiler", Title = "Profiler", Content = profilerTab },
			{ Id = "settings", Title = "Settings", Content = settingsTab },
		},
		Actions = { actions },
		OnClose = function()
			open:set(false)
		end,
		Size = UDim2.new(1, 0, 1, -6),
	})
	local handle = scope:New("TextButton")({
		Name = "Resize",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = colors.Outline,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 6),
	}) :: TextButton
	table.insert(
		scope,
		handle.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local startY = input.Position.Y
			local startHeight = peek(height) :: number
			ScrollInput.capture(handle, function(changed: InputObject)
				return changed.UserInputType == Enum.UserInputType.MouseMovement
			end, function(ended: InputObject)
				return ended.UserInputType == Enum.UserInputType.MouseButton1
			end, function(position: Vector3)
				local limit = (
					workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
				) * 0.85
				height:set(math.clamp(startHeight - (position.Y - startY), 160, limit))
			end, function() end)
		end)
	)
	scope:New("Frame")({
		Name = "Panel",
		Parent = gui,
		AnchorPoint = Vector2.new(0, 1),
		Position = scope:Computed(function(use)
			return UDim2.new(
				0,
				0,
				1,
				(1 - math.clamp(use(openS) :: number, 0, 1)) * (use(height) :: number)
			)
		end),
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, use(panelHeight) :: number)
		end),
		Visible = scope:Computed(function(use)
			return (use(openS) :: number) > 0.01
		end),
		BackgroundColor3 = colors.Surface,
		BorderSizePixel = 0,
		ZIndex = 10,
		[Children] = {
			handle,
			scope:Frame({
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 6),
				Size = UDim2.new(1, 0, 1, -6),
				[Children] = dock,
			}),
		} :: any,
	})

	-- every frame
	local lastProfile = 0
	local connections: { RBXScriptConnection } = {}
	local function pick(): GuiObject?
		local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		for _, object in playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y) do
			if not isOwn(object) then
				return object
			end
		end
		return nil
	end

	table.insert(
		connections,
		RunService.Heartbeat:Connect(function()
			local hovered: GuiObject? = nil
			if peek(inspecting) then
				hovered = pick()
			else
				local fromTree = peek(hoverFromTree)
				hovered = if fromTree and fromTree:IsA("GuiObject") then fromTree else nil
			end
			outline(hoverBox, hovered)
			local current = peek(selected)
			outline(selectBox, if current and current:IsA("GuiObject") then current else nil)
			if hovered then
				local size = hovered.AbsoluteSize
				tip.Text = `{hovered.Name}  {math.round(size.X)} × {math.round(size.Y)}`
				tip.Position = UDim2.fromOffset(
					hovered.AbsolutePosition.X,
					math.max(hovered.AbsolutePosition.Y - 20, 0)
				)
				tip.Visible = true
			else
				tip.Visible = false
			end

			-- Flashes fade out.
			local now = os.clock()
			for index = #flashes, 1, -1 do
				local entry = flashes[index]
				local age = (now - entry.born) / FLASH_TIME
				if age >= 1 or not entry.target:IsDescendantOf(game) then
					entry.frame.Visible = false
					table.insert(pool, entry.frame)
					table.remove(flashes, index)
				else
					entry.frame.Position = UDim2.fromOffset(
						entry.target.AbsolutePosition.X,
						entry.target.AbsolutePosition.Y
					)
					entry.frame.Size =
						UDim2.fromOffset(entry.target.AbsoluteSize.X, entry.target.AbsoluteSize.Y)
					entry.frame.BackgroundTransparency = 0.6 + 0.4 * age
					local stroke = entry.frame:FindFirstChildOfClass("UIStroke")
					if stroke then
						stroke.Transparency = age
					end
				end
			end

			-- The profiler list, twice a second.
			if peek(recording) and now - lastProfile >= 0.5 then
				local elapsed = now - lastProfile
				lastProfile = now
				local rows: { { instance: Instance, count: number, rate: number } } = {}
				for instance, count in counts do
					if instance:IsDescendantOf(game) then
						table.insert(rows, {
							instance = instance,
							count = count,
							rate = (count - (previous[instance] or 0)) / math.max(elapsed, 0.01),
						})
					end
					previous[instance] = count
				end
				table.sort(rows, function(a, b)
					if a.rate ~= b.rate then
						return a.rate > b.rate
					end
					return a.count > b.count
				end)
				while #rows > PROFILE_ROWS do
					table.remove(rows)
				end
				profile:set(rows)
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject)
			if input.KeyCode == hotkey and not UserInputService:GetFocusedTextBox() then
				open:set(not peek(open))
				if not peek(open) then
					inspecting:set(false)
				end
			elseif input.KeyCode == Enum.KeyCode.Escape and peek(inspecting) then
				inspecting:set(false)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 and peek(inspecting) then
				local target = pick()
				if target then
					choose(target)
					inspecting:set(false)
				end
			end
		end)
	)

	gui.Parent = guiParent

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		Fusion.doCleanup(scope)
	end
end

return { mount = mount }
