--!strict
--[[
	Custom scroll surface with chrome:

	  ^          (chevron-up)
	  |
	  |
	 | |         (thin rail + wider thumb)
	 | |
	  |
	  |
	  V          (chevron-down)
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Icon = require(script.Parent.Icon)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

return function(scope: Types.Scope, props: Types.ScrollAreaProps): Frame
	local theme = resolveTheme(props)
	local smooth = props.Smooth ~= false
	local inertia = props.Inertia ~= false
	local keyboard = props.Keyboard ~= false
	local autoCanvas = props.AutoCanvas ~= false
	local railClick = props.ScrollBarRail ~= false
	local showRail = if props.ScrollBarRailBackground == nil then true else props.ScrollBarRailBackground
	local autoHide = props.AutoHideScrollBar ~= false
	local hideDelay = props.AutoHideDelay or 0.85
	local showButtons = props.ScrollButtons == true
	local buttonStep = props.ScrollButtonStep or 64
	local thumbThickness = props.ScrollBarThickness or 8
	local railThickness = props.ScrollBarRailThickness or 2
	local padX = props.ScrollBarPadding or 6
	local buttonSize = if showButtons then 20 else 0
	local chromeInner = math.max(thumbThickness, railThickness, if showButtons then 16 else 0)
	local chromeWidth = chromeInner + padX * 2
	local contentLayout = props.ContentLayout or "List"
	local contentPad = if props.ContentPadding ~= nil then props.ContentPadding else theme.Metrics.SpaceMd
	local listPad = if props.ListPadding ~= nil then props.ListPadding else theme.Metrics.SpaceLg
	local useListLayout = contentLayout ~= "None"
	-- Extra inset so UIStroke near full-bleed children isn't sheared by root clip.
	local padInset = if useListLayout then contentPad + 2 else contentPad

	local idleColor = props.ScrollBarColor or theme.Colors.Outline
	local railIdleColor = props.ScrollBarRailColor or theme.Colors.OutlineVariant
	local activeColor = props.ScrollBarActiveColor or theme.Colors.Primary

	local contentSize = scope:Value(Vector2.new(0, 0))
	local viewSize = scope:Value(Vector2.new(0, 200))
	local offset = scope:Value(peek(props.ScrollOffset) or 0)
	local velocity = scope:Value(0)
	local target = scope:Value(peek(props.ScrollOffset) or 0)
	local scrollSpring = scope:Spring(target, if smooth then 52 else 120, 0.9)

	local barVisible = scope:Value(1)
	local barVisibleS = scope:Spring(barVisible, 28, 0.95)
	local hoveringBar = scope:Value(0)
	local hoveringBarS = scope:Spring(hoveringBar, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)
	local draggingBar = scope:Value(0)
	local draggingBarS = scope:Spring(draggingBar, theme.Motion.SpringSpeed * 1.2, 0.9)
	local railPressed = scope:Value(0)
	local railPressedS = scope:Spring(railPressed, theme.Motion.SpringSpeed * 1.4, 0.9)
	local stretch = scope:Value(0)
	local stretchS = scope:Spring(stretch, 40, 0.8)
	local lastActivity = scope:Value(os.clock())

	local function bumpActivity()
		lastActivity:set(os.clock())
		barVisible:set(1)
	end

	local function maxScroll(): number
		return math.max(0, peek(contentSize).Y - peek(viewSize).Y)
	end

	local overscrollEnabled = if props.Overscroll == nil then inertia else props.Overscroll
	-- Drag-to-scroll is touch-only by default (mouse uses wheel / scrollbar).
	local touchDevice = UserInputService.TouchEnabled
	local dragToScroll = if props.DragToScroll == nil then touchDevice else props.DragToScroll == true
	local refreshThreshold = props.RefreshThreshold or 72
	local contentDragging = scope:Value(false)

	local function emitScroll(y: number)
		if not props.OnScroll then
			return
		end
		local last = (scope :: any)._estuaryLastScroll
		if typeof(last) == "number" and math.abs(y - last) < 0.5 then
			return
		end
		;(scope :: any)._estuaryLastScroll = y
		props.OnScroll(y)
	end

	local function resist(y: number): number
		local max = maxScroll()
		if y < 0 then
			return y * 0.42
		end
		if y > max then
			return max + (y - max) * 0.42
		end
		return y
	end

	local function clampScroll(y: number): number
		return math.clamp(y, 0, maxScroll())
	end

	local function scrollBy(delta: number, raw: boolean?)
		bumpActivity()
		local nextY = peek(target) + delta
		if overscrollEnabled and (raw or peek(contentDragging)) then
			target:set(nextY)
			if not smooth then
				offset:set(resist(nextY))
				emitScroll(peek(offset))
			end
		else
			nextY = clampScroll(nextY)
			target:set(nextY)
			if not smooth then
				offset:set(nextY)
				emitScroll(nextY)
			end
		end
		if inertia and not peek(contentDragging) then
			velocity:set(delta * 12)
		end
	end

	local function scrollTo(y: number)
		bumpActivity()
		local nextY = clampScroll(y)
		target:set(nextY)
		velocity:set(0)
		contentDragging:set(false)
		if not smooth then
			offset:set(nextY)
			emitScroll(nextY)
		end
	end

	local function settleIfNeeded()
		local max = maxScroll()
		local y = peek(target)
		if y < 0 then
			if props.OnRefresh and y < -refreshThreshold then
				task.defer(props.OnRefresh)
			end
			target:set(0)
			velocity:set(0)
		elseif y > max then
			target:set(max)
			velocity:set(0)
		end
	end

	local function activeAmount(use: any): number
		return math.clamp(use(draggingBarS) + use(railPressedS) * 0.85 + use(hoveringBarS) * 0.35, 0, 1)
	end

	table.insert(
		scope,
		scope:Observer(scrollSpring):onBind(function()
			local raw = peek(scrollSpring)
			local y = if overscrollEnabled and peek(contentDragging) then resist(raw) else clampScroll(raw)
			-- While free-springing past edges, show resisted position then settle
			if overscrollEnabled and not peek(contentDragging) then
				if raw < 0 or raw > maxScroll() then
					y = resist(raw)
					if math.abs(raw - clampScroll(raw)) < 0.5 then
						y = clampScroll(raw)
					end
				end
			end
			offset:set(y)
			emitScroll(y)
		end)
	)

	if props.ScrollOffset ~= nil and typeof(props.ScrollOffset) == "table" then
		table.insert(
			scope,
			scope:Observer(props.ScrollOffset :: any):onChange(function()
				local y = peek(props.ScrollOffset)
				if typeof(y) == "number" and math.abs(y - peek(target)) > 0.5 then
					scrollTo(y)
				end
			end)
		)
	end

	if inertia then
		table.insert(
			scope,
			RunService.RenderStepped:Connect(function(dt)
				if peek(contentDragging) then
					return
				end
				local v = peek(velocity)
				local y = peek(target)
				local max = maxScroll()
				-- Rubber-band settle when past edges
				if overscrollEnabled and (y < 0 or y > max) then
					local goal = if y < 0 then 0 else max
					local nextY = y + (goal - y) * math.min(1, dt * 10)
					if math.abs(nextY - goal) < 0.5 then
						nextY = goal
						velocity:set(0)
					end
					target:set(nextY)
				elseif math.abs(v) >= 0.8 then
					local nextY = y + v * dt
					if overscrollEnabled then
						target:set(nextY)
					else
						target:set(clampScroll(nextY))
					end
					velocity:set(v * math.max(0, 1 - dt * 5.2))
				else
					velocity:set(0)
					if overscrollEnabled and (y < 0 or y > max) then
						settleIfNeeded()
					end
				end

				if autoHide and peek(draggingBar) < 0.5 and peek(hoveringBar) < 0.5 then
					if os.clock() - peek(lastActivity) > hideDelay then
						barVisible:set(0)
					end
				end
			end)
		)
	elseif autoHide then
		table.insert(
			scope,
			RunService.RenderStepped:Connect(function()
				if peek(draggingBar) < 0.5 and peek(hoveringBar) < 0.5 then
					if os.clock() - peek(lastActivity) > hideDelay then
						barVisible:set(0)
					end
				end
			end)
		)
	end

	local content = scope:New("Frame")({
		Name = "Content",
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Size = if autoCanvas
			then UDim2.new(1, -chromeWidth, 0, 0)
			else scope:Computed(function(use)
				return UDim2.new(1, -chromeWidth, 0, use(contentSize).Y)
			end),
		AutomaticSize = if autoCanvas then Enum.AutomaticSize.Y else Enum.AutomaticSize.None,
		Position = scope:Computed(function(use)
			return UDim2.fromOffset(0, -use(offset))
		end),
		[Children] = {
			if useListLayout
				then scope:New("UIPadding")({
					PaddingTop = UDim.new(0, padInset),
					PaddingBottom = UDim.new(0, padInset),
					PaddingLeft = UDim.new(0, padInset),
					PaddingRight = UDim.new(0, padInset),
				})
				else nil,
			if useListLayout
				then scope:New("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, listPad),
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				})
				else nil,
			props.Children,
		},
	})

	if autoCanvas then
		local layout = content:FindFirstChildOfClass("UIListLayout")
		if layout then
			table.insert(
				scope,
				layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					contentSize:set(layout.AbsoluteContentSize)
				end)
			)
		end
		table.insert(
			scope,
			content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				contentSize:set(Vector2.new(content.AbsoluteSize.X, content.AbsoluteSize.Y))
			end)
		)
	elseif props.CanvasSize then
		table.insert(
			scope,
			scope:Observer(props.CanvasSize :: any):onBind(function()
				local c = peek(props.CanvasSize)
				if typeof(c) == "UDim2" then
					contentSize:set(Vector2.new(c.X.Offset, c.Y.Offset))
				end
			end)
		)
	end

	-- Thin rail line (no accent tint — stays neutral)
	local railLine = scope:New("Frame")({
		Name = "Rail",
		BackgroundColor3 = railIdleColor,
		BackgroundTransparency = scope:Computed(function(use)
			if not showRail then
				return 1
			end
			local hide = (1 - use(barVisibleS)) * 0.35
			return math.clamp(0.4 + hide, 0.15, 0.85)
		end),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0, railThickness, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 1,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		},
	})

	-- Wider thumb sitting on the rail
	local thumb = scope:New("Frame")({
		Name = "Thumb",
		BackgroundColor3 = scope:Computed(function(use)
			return Interaction.lerpColor(idleColor, activeColor, activeAmount(use))
		end),
		BackgroundTransparency = scope:Computed(function(use)
			local hide = (1 - use(barVisibleS)) * 0.85
			local boost = activeAmount(use) * 0.4
			return math.clamp(0.25 - boost + hide, 0, 1)
		end),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Computed(function(use)
			local vs = use(viewSize) :: Vector2
			local cs = use(contentSize) :: Vector2
			local off = use(offset) :: number
			local trackH = math.max(vs.Y - buttonSize * 2, 1)
			local contentH = math.max(cs.Y, 1)
			local max = math.max(0, contentH - vs.Y)
			local thumbRatio = math.clamp(vs.Y / contentH, 0.12, 1)
			-- Clamp scroll ratio so overscroll never pushes the thumb past the track
			local t = if max <= 0 then 0 else math.clamp(off / max, 0, 1)
			local baseH = trackH * thumbRatio
			local drag = use(draggingBarS) :: number
			local velSx = math.min(math.abs(use(stretchS) :: number), baseH * 0.7)
			local sx = drag * baseH * 0.1 + velSx
			local h = math.min(baseH + sx, trackH)
			local travel = math.max(trackH - baseH, 0)
			local y = math.clamp(t * travel - (h - baseH) * 0.5, 0, math.max(trackH - h, 0))
			return UDim2.new(0.5, 0, 0, y)
		end),
		Size = scope:Computed(function(use)
			local vs = use(viewSize) :: Vector2
			local cs = use(contentSize) :: Vector2
			local trackH = math.max(vs.Y - buttonSize * 2, 1)
			local contentH = math.max(cs.Y, 1)
			local ratio = math.clamp(vs.Y / contentH, 0.12, 1)
			local baseH = trackH * ratio
			local drag = use(draggingBarS) :: number
			-- Drag: slightly thinner + longer; velocity adds more stretch
			local thin = drag * 2.5
			local velSx = math.min(math.abs(use(stretchS) :: number), baseH * 0.7)
			local sx = drag * baseH * 0.1 + velSx
			local h = math.min(baseH + sx, trackH)
			return UDim2.fromOffset(math.max(thumbThickness - thin, railThickness + 1), h)
		end),
		ZIndex = 2,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		},
	})

	local track = scope:New("Frame")({
		Name = "ScrollTrack",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -buttonSize * 2),
		Position = UDim2.fromOffset(0, buttonSize),
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 1,
		[Children] = {
			railLine,
			thumb,
		},
	})

	local function makeScrollButton(name: string, iconName: string, delta: number, top: boolean)
		local pressed = scope:Value(0)
		local pressedS = scope:Spring(pressed, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)
		local btn = scope:New("TextButton")(P({
			Name = name,
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, buttonSize),
			Position = if top then UDim2.fromOffset(0, 0) else UDim2.new(0, 0, 1, -buttonSize),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			[OnEvent("Activated")] = function()
				scrollBy(delta)
			end,
			[OnEvent("MouseButton1Down")] = function()
				pressed:set(1)
				railPressed:set(1)
				bumpActivity()
			end,
			[OnEvent("MouseButton1Up")] = function()
				pressed:set(0)
				railPressed:set(0)
			end,
			[OnEvent("MouseLeave")] = function()
				pressed:set(0)
			end,
			[Children] = {
				scope:Hydrate(Icon(scope, {
					Theme = theme,
					Name = iconName,
					IconSize = 14,
					Color = scope:Computed(function(use)
						return Interaction.lerpColor(
							theme.Colors.OnSurfaceVariant,
							activeColor,
							math.clamp(use(pressedS) + use(hoveringBarS) * 0.5, 0, 1)
						)
					end),
				}))({
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					ImageTransparency = scope:Computed(function(use)
						local hide = (1 - use(barVisibleS)) * 0.7
						return math.clamp(hide, 0, 0.85)
					end),
				}),
			},
		}))
		return btn
	end

	local chrome = scope:New("Frame")({
		Name = "ScrollChrome",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, chromeWidth, 1, 0),
		ZIndex = 5,
		[Children] = {
			scope:New("UIPadding")({
				PaddingLeft = UDim.new(0, padX),
				PaddingRight = UDim.new(0, padX),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			-- Inner column after padding
			scope:New("Frame")({
				Name = "ChromeInner",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					if showButtons then makeScrollButton("ScrollUp", "chevron-up", -buttonStep, true) else nil,
					track,
					if showButtons then makeScrollButton("ScrollDown", "chevron-down", buttonStep, false) else nil,
				},
			}),
		},
	})

	-- When buttons are off, track should fill the chrome
	if not showButtons then
		track.Size = UDim2.fromScale(1, 1)
		track.Position = UDim2.fromOffset(0, 0)
	end

	local root = scope:New("Frame")({
		Name = "ScrollArea",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = props.Size or UDim2.fromScale(1, 1),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		[Children] = {
			content,
			chrome,
		},
	}) :: Frame

	table.insert(
		scope,
		root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			viewSize:set(root.AbsoluteSize)
		end)
	)
	-- seed once
	task.defer(function()
		if root.Parent then
			viewSize:set(root.AbsoluteSize)
		end
	end)

	table.insert(
		scope,
		root.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				scrollBy(-input.Position.Z * 72)
			end
		end)
	)

	-- Drag-to-scroll / touch pan + pull-to-refresh (touch only — mouse uses wheel/scrollbar)
	if dragToScroll then
		table.insert(
			scope,
			root.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				-- Ignore if starting on scrollbar chrome
				local cx = chrome.AbsolutePosition.X
				if input.Position.X >= cx then
					return
				end
				contentDragging:set(true)
				velocity:set(0)
				local lastY = input.Position.Y
				local lastT = os.clock()
				local move = UserInputService.InputChanged:Connect(function(changed)
					if changed.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					local now = os.clock()
					local dt = math.max(now - lastT, 1 / 240)
					local dy = changed.Position.Y - lastY
					lastY = changed.Position.Y
					lastT = now
					scrollBy(-dy, true)
					velocity:set(-dy / dt)
				end)
				local ended
				ended = UserInputService.InputEnded:Connect(function(endedInput)
					if endedInput.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					contentDragging:set(false)
					settleIfNeeded()
					move:Disconnect()
					ended:Disconnect()
				end)
				table.insert(scope, move)
				table.insert(scope, ended)
			end)
		)
	end

	table.insert(
		scope,
		chrome.MouseEnter:Connect(function()
			hoveringBar:set(1)
			bumpActivity()
		end)
	)
	table.insert(
		scope,
		chrome.MouseLeave:Connect(function()
			if peek(draggingBar) < 0.5 then
				hoveringBar:set(0)
				railPressed:set(0)
			end
		end)
	)

	table.insert(
		scope,
		track.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			bumpActivity()
			local trackH = track.AbsoluteSize.Y
			local contentH = math.max(peek(contentSize).Y, 1)
			local view = peek(viewSize).Y
			local max = math.max(0, contentH - view)
			if max <= 0 then
				return
			end
			local thumbRatio = math.clamp(view / contentH, 0.12, 1)
			local thumbPx = thumbRatio * trackH
			local localY = input.Position.Y - track.AbsolutePosition.Y
			local thumbTop = (peek(offset) / max) * (trackH - thumbPx)
			local onThumb = localY >= thumbTop - 2 and localY <= thumbTop + thumbPx + 2

			if onThumb then
				draggingBar:set(1)
				hoveringBar:set(1)
				local grabOffset = localY - thumbTop
				local lastY = input.Position.Y
				local lastT = os.clock()

				local move = UserInputService.InputChanged:Connect(function(changed)
					if
						changed.UserInputType ~= Enum.UserInputType.MouseMovement
						and changed.UserInputType ~= Enum.UserInputType.Touch
					then
						return
					end
					local now = os.clock()
					local dt = math.max(now - lastT, 1 / 240)
					local vel = (changed.Position.Y - lastY) / dt
					lastY = changed.Position.Y
					lastT = now
					stretch:set(math.clamp(vel * 0.055, -36, 36))

					local y = changed.Position.Y - track.AbsolutePosition.Y - grabOffset
					local t = math.clamp(y / math.max(trackH - thumbPx, 1), 0, 1)
					scrollTo(t * max)
				end)
				local ended
				ended = UserInputService.InputEnded:Connect(function(endedInput)
					if
						endedInput.UserInputType == Enum.UserInputType.MouseButton1
						or endedInput.UserInputType == Enum.UserInputType.Touch
					then
						draggingBar:set(0)
						stretch:set(0)
						move:Disconnect()
						ended:Disconnect()
					end
				end)
				table.insert(scope, move)
				table.insert(scope, ended)
			elseif railClick then
				railPressed:set(1)
				local t = math.clamp((localY - thumbPx * 0.5) / math.max(trackH - thumbPx, 1), 0, 1)
				scrollTo(t * max)
				task.delay(0.12, function()
					railPressed:set(0)
				end)
			end
		end)
	)

	if keyboard then
		table.insert(
			scope,
			UserInputService.InputBegan:Connect(function(input, processed)
				if processed then
					return
				end
				if input.KeyCode == Enum.KeyCode.Down then
					scrollBy(56)
				elseif input.KeyCode == Enum.KeyCode.Up then
					scrollBy(-56)
				elseif input.KeyCode == Enum.KeyCode.PageDown then
					scrollBy(peek(viewSize).Y * 0.9)
				elseif input.KeyCode == Enum.KeyCode.PageUp then
					scrollBy(-peek(viewSize).Y * 0.9)
				elseif input.KeyCode == Enum.KeyCode.Home then
					scrollTo(0)
				elseif input.KeyCode == Enum.KeyCode.End then
					scrollTo(maxScroll())
				end
			end)
		)
	end

	bumpActivity()
	return root
end
