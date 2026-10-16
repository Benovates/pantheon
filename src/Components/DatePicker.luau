--!strict
--[[
	Date picker — `<  Aug 2026 >` header; Aug / year are separate hit targets.
	Month & year pickers; day grid animates diagonally on period change.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Calendar = require(script.Parent.Parent.Internal.Picker.Calendar)
local Interaction = require(script.Parent.Parent.Internal.Interaction)
local Icon = require(script.Parent.Icon)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local CELL = 36
local GAP = 4
local COLS = 7
local ROWS = 6
local GRID_W = COLS * CELL + (COLS - 1) * GAP
local BODY_H = ROWS * CELL + (ROWS - 1) * GAP
local NAV = 36

type ViewMode = "Days" | "Months" | "Years"

local function monthLabel(month: number): string
	return Calendar.MONTHS_SHORT[month] or "?"
end

return function(scope: Types.Scope, props: Types.DatePickerProps): Instance
	local theme = resolveTheme(props)
	local now = os.date("*t")
	local y0, m0, d0 = Calendar.parseISO(peek(props.Value) or "")
	local year = scope:Value(y0 or now.year)
	local month = scope:Value(m0 or now.month)
	local day = scope:Value(d0 or now.day)
	local view = scope:Value("Days" :: ViewMode)
	local generation = scope:Value(0)

	-- Mode progress springs so we can animate fades/scale while keeping the
	-- corresponding UI alive briefly instead of toggling Visibility instantly.
	local daysModeS = scope:Spring(
		scope:Computed(function(use)
			return if use(view) == "Days" then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)
	local monthsModeS = scope:Spring(
		scope:Computed(function(use)
			return if use(view) == "Months" then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)
	local yearsModeS = scope:Spring(
		scope:Computed(function(use)
			return if use(view) == "Years" then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)

	local function bumpGeneration()
		generation:set(peek(generation) + 1)
	end

	local function shiftMonth(delta: number)
		local m = peek(month) + delta
		local y = peek(year)
		while m < 1 do
			m += 12
			y -= 1
		end
		while m > 12 do
			m -= 12
			y += 1
		end
		month:set(m)
		year:set(y)
		bumpGeneration()
		view:set("Days")
	end

	local function makeHit(
		name: string,
		label: any,
		activeMode: ViewMode,
		onClick: () -> ()
	): TextButton
		local ix = Interaction.bind(scope, theme, {
			StateColor = theme.Colors.OnSurface,
			HoverOpacity = 0.1,
			PressOpacity = 0.16,
		})
		local activeS = scope:Computed(function(use)
			return use(view) == activeMode
		end)
		local btn = scope:TextButton(P({
			Name = name,
			Text = label,
			FontFace = scope:Computed(function(use)
				return if use(activeS) then theme.Fonts.Heading else theme.Fonts.Body
			end),
			TextSize = 16,
			TextColor3 = scope:Computed(function(use)
				return if use(activeS) then theme.Colors.OnPrimary else theme.Colors.OnSurface
			end),
			BackgroundColor3 = scope:Computed(function(use)
				if use(activeS) then
					return theme.Colors.Primary
				end
				return Interaction.lerpColor(
					theme.Colors.SurfaceContainer,
					theme.Colors.OnSurface,
					ix.alpha(use)
				)
			end),
			BackgroundTransparency = scope:Computed(function(use)
				if use(activeS) then
					return 0
				end
				local alpha = ix.alpha(use)
				return math.clamp(1 - alpha * 4, 0, 1)
			end),
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.XY,
			Padding = { 8, 14 },
			CornerRadius = theme.Metrics.RadiusPill,
			[OnEvent("Activated")] = onClick,
		}))
		ix.wire(btn)
		return btn
	end

	local monthHit = makeHit(
		"MonthHit",
		scope:Computed(function(use)
			return monthLabel(use(month))
		end),
		"Months",
		function()
			view:set(if peek(view) == "Months" then "Days" else "Months")
		end
	)
	monthHit.LayoutOrder = 1

	local yearHit = makeHit(
		"YearHit",
		scope:Computed(function(use)
			return tostring(use(year))
		end),
		"Years",
		function()
			view:set(if peek(view) == "Years" then "Days" else "Years")
		end
	)
	yearHit.LayoutOrder = 2

	local titleRow = scope:Frame({
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = 0,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = { monthHit, yearHit },
	})

	local titleMid = scope:Frame({
		Name = "TitleMid",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		LayoutOrder = 2,
		Layout = {
			Kind = "List",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		},
		[Children] = { titleRow },
	})
	local titleFlex = Instance.new("UIFlexItem")
	titleFlex.FlexMode = Enum.UIFlexMode.Fill
	titleFlex.Parent = titleMid

	local function navButton(iconName: string, onClick: () -> ()): TextButton
		local ix = Interaction.bind(scope, theme, {
			StateColor = theme.Colors.OnSurface,
			HoverOpacity = 0.1,
			PressOpacity = 0.16,
		})
		local btn = scope:TextButton(P({
			Text = "",
			BackgroundColor3 = scope:Computed(function(use)
				local alpha = ix.alpha(use)
				return Interaction.lerpColor(
					theme.Colors.SurfaceContainer,
					theme.Colors.OnSurface,
					alpha
				)
			end),
			BackgroundTransparency = 0,
			Size = UDim2.fromOffset(NAV, NAV),
			AutoButtonColor = false,
			CornerRadius = theme.Metrics.RadiusPill,
			[OnEvent("Activated")] = onClick,
			[Children] = {
				scope:Apply(Icon(scope, {
					Theme = theme,
					Name = iconName,
					IconSize = 18,
					Color = theme.Colors.OnSurface,
				}))({
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}),
			},
		}))
		ix.wire(btn)
		return btn
	end

	local prevBtn = navButton("chevron-left", function()
		if peek(view) == "Years" then
			year:set(peek(year) - 16)
		elseif peek(view) == "Months" then
			year:set(peek(year) - 1)
		else
			shiftMonth(-1)
		end
	end)
	prevBtn.LayoutOrder = 1

	local nextBtn = navButton("chevron-right", function()
		if peek(view) == "Years" then
			year:set(peek(year) + 16)
		elseif peek(view) == "Months" then
			year:set(peek(year) + 1)
		else
			shiftMonth(1)
		end
	end)
	nextBtn.LayoutOrder = 3

	-- Day slots: key includes generation so ForPairs fully tears down on period change
	local daySlots = scope:Computed(function(use)
		local y = use(year)
		local m = use(month)
		local gen = use(generation)
		local firstWeekday = Calendar.weekday(y, m, 1)
		local dim = Calendar.daysInMonth(y, m)
		local map: { [number]: { day: number, order: number } } = {}
		for d = 1, dim do
			map[gen * 40 + d] = { day = d, order = firstWeekday + d }
		end
		return map
	end)

	local blankSlots = scope:Computed(function(use)
		local gen = use(generation)
		local n = Calendar.weekday(use(year), use(month), 1)
		local map: { [number]: number } = {}
		for i = 1, n do
			map[gen * 40 + i] = i
		end
		return map
	end)

	local blankCells = scope:ForPairs(
		blankSlots,
		function(_use, innerScope, key: number, index: number)
			local cellScope: Types.Scope = innerScope :: any
			return key,
				cellScope:Frame({
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(CELL, CELL),
					LayoutOrder = index,
				})
		end
	)

	local dayCells = scope:ForPairs(
		daySlots,
		function(_use, innerScope, key: number, info: { day: number, order: number })
			local cellScope: Types.Scope = innerScope :: any
			local dayNum = info.day
			local order = info.order
			local col = (order - 1) % COLS
			local row = math.floor((order - 1) / COLS)
			local delay = (row + col) * 0.018

			-- Radial weight for "explode from center to outer" during Days exit.
			local centerCol = (COLS - 1) * 0.5
			local centerRow = (ROWS - 1) * 0.5
			local dx = col - centerCol
			local dy = row - centerRow
			local dist = math.sqrt(dx * dx + dy * dy)
			local maxDist = math.sqrt(centerCol * centerCol + centerRow * centerRow)
			local distN = if maxDist > 0 then dist / maxDist else 0
			-- Larger power => faster fade as daysModeS approaches 0.
			local fadePower = 0.85 + distN * 0.75

			local alive = true
			table.insert(cellScope, function()
				alive = false
			end)

			local appear = cellScope:Value(0)
			local appearS = cellScope:Spring(appear, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)
			task.delay(delay, function()
				if alive then
					appear:set(1)
				end
			end)

			local ix = Interaction.bind(cellScope, theme, {
				StateColor = theme.Colors.OnSurface,
				HoverOpacity = 0.1,
				PressOpacity = 0.16,
			})

			local selectedS = cellScope:Computed(function(use)
				return use(day) == dayNum
			end)

			local btn = cellScope:TextButton(P({
				Name = "Day_" .. dayNum,
				Text = tostring(dayNum),
				FontFace = cellScope:Computed(function(use)
					return if use(selectedS) then theme.Fonts.Heading else theme.Fonts.Body
				end),
				TextSize = 13,
				TextColor3 = cellScope:Computed(function(use)
					return if use(selectedS) then theme.Colors.OnPrimary else theme.Colors.OnSurface
				end),
				TextTransparency = cellScope:Computed(function(use)
					local t = (use(appearS) :: number) * ((use(daysModeS) :: number) ^ fadePower)
					return 1 - t
				end),
				BackgroundColor3 = cellScope:Computed(function(use)
					if use(selectedS) then
						return theme.Colors.Primary
					end
					return Interaction.lerpColor(
						theme.Colors.SurfaceContainer,
						theme.Colors.OnSurface,
						ix.alpha(use)
					)
				end),
				BackgroundTransparency = cellScope:Computed(function(use)
					local t = (use(appearS) :: number) * ((use(daysModeS) :: number) ^ fadePower)
					local fade = 1 - t
					if use(selectedS) then
						return fade * 0.55
					end
					return math.clamp(fade * 0.85, 0, 1)
				end),
				Size = UDim2.fromOffset(CELL, CELL),
				LayoutOrder = order,
				AutoButtonColor = false,
				CornerRadius = theme.Metrics.RadiusPill,
				[OnEvent("Activated")] = function()
					day:set(dayNum)
					local iso = Calendar.formatISO(peek(year), peek(month), dayNum)
					if props.OnChanged then
						props.OnChanged(iso)
					end
				end,
				[Children] = {
					cellScope:New("UIScale")({
						Scale = cellScope:Computed(function(use)
							local t = use(appearS)
							local mode = use(daysModeS)
							local explode = 1 - mode
							local base = 1.22 - 0.22 * t
							-- Outer cells scale a bit more as we leave Days mode.
							local radial = 1 + distN * 0.18 * explode
							return base * radial
						end),
					}),
				},
			}))
			ix.wire(btn)
			return key, btn
		end
	)

	local monthCells = scope:Computed(function(use, innerScope)
		local cellScope: Types.Scope = innerScope :: any
		if use(monthsModeS) < 0.001 then
			return {}
		end
		local nodes = {}
		for m = 1, 12 do
			local monthNum = m
			local selected = use(month) == monthNum
			local ix = Interaction.bind(cellScope, theme, {
				StateColor = theme.Colors.OnSurface,
				HoverOpacity = 0.1,
				PressOpacity = 0.16,
			})
			local btn = cellScope:TextButton(P({
				Text = monthLabel(monthNum),
				FontFace = if selected then theme.Fonts.Heading else theme.Fonts.Body,
				TextSize = 13,
				TextColor3 = if selected then theme.Colors.OnPrimary else theme.Colors.OnSurface,
				AutoButtonColor = false,
				CornerRadius = theme.Metrics.RadiusSm,
				Size = UDim2.new(1 / 3, -4, 0, 40),
				LayoutOrder = monthNum,
				Active = cellScope:Computed(function(useButton)
					return useButton(view) == "Months"
				end),
				BackgroundColor3 = cellScope:Computed(function(useColor)
					if selected then
						return theme.Colors.Primary
					end
					return Interaction.lerpColor(
						theme.Colors.SurfaceContainer,
						theme.Colors.OnSurface,
						ix.alpha(useColor)
					)
				end),
				[OnEvent("Activated")] = function()
					month:set(monthNum)
					bumpGeneration()
					view:set("Days")
				end,
			}))
			ix.wire(btn)
			table.insert(nodes, btn)
		end
		return nodes
	end)

	local yearCells = scope:Computed(function(use, innerScope)
		local cellScope: Types.Scope = innerScope :: any
		if use(yearsModeS) < 0.001 then
			return {}
		end
		local center = use(year) :: number
		local nodes = {}
		local start = center - 7
		for i = 0, 15 do
			local y = start + i
			local selected = use(year) == y
			local ix = Interaction.bind(cellScope, theme, {
				StateColor = theme.Colors.OnSurface,
				HoverOpacity = 0.1,
				PressOpacity = 0.16,
			})
			local btn = cellScope:TextButton(P({
				Text = tostring(y),
				FontFace = if selected then theme.Fonts.Heading else theme.Fonts.Body,
				TextSize = 13,
				TextColor3 = if selected then theme.Colors.OnPrimary else theme.Colors.OnSurface,
				AutoButtonColor = false,
				CornerRadius = theme.Metrics.RadiusSm,
				Size = UDim2.new(1 / 4, -4, 0, 40),
				LayoutOrder = i + 1,
				Active = cellScope:Computed(function(useButton)
					return useButton(view) == "Years"
				end),
				BackgroundColor3 = cellScope:Computed(function(useColor)
					if selected then
						return theme.Colors.Primary
					end
					return Interaction.lerpColor(
						theme.Colors.SurfaceContainer,
						theme.Colors.OnSurface,
						ix.alpha(useColor)
					)
				end),
				[OnEvent("Activated")] = function()
					year:set(y)
					bumpGeneration()
					view:set("Days")
				end,
			}))

			ix.wire(btn)
			table.insert(nodes, btn)
		end
		return nodes
	end)

	return scope:Frame({
		Name = "DatePicker",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size or UDim2.fromOffset(GRID_W + theme.Metrics.SpaceMd * 2, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		-- Allow overflow (e.g. animated day "bubbles") to escape the container.
		ClipsDescendants = false,
		CornerRadius = theme.Metrics.RadiusPanel,
		Padding = { theme.Metrics.SpaceMd },
		Layout = {
			Kind = "List",
			Padding = theme.Metrics.SpaceSm,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		[Children] = {
			scope:Frame({
				Name = "Header",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				LayoutOrder = 1,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = theme.Metrics.SpaceXs,
				},
				[Children] = { prevBtn, titleMid, nextBtn },
			}),
			scope:Frame({
				Name = "Body",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, BODY_H),
				LayoutOrder = 2,
				ClipsDescendants = false,
				[Children] = {
					scope:Frame({
						Name = "Days",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Visible = scope:Computed(function(use)
							return use(daysModeS) > 0.001
						end),
						Layout = {
							Kind = "List",
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Top,
						},
						[Children] = {
							scope:Frame({
								Name = "DayGrid",
								BackgroundTransparency = 1,
								Size = UDim2.fromOffset(GRID_W, BODY_H),
								Layout = {
									Kind = "Grid",
									CellSize = UDim2.fromOffset(CELL, CELL),
									CellPadding = UDim2.fromOffset(GAP, GAP),
									FillDirectionMaxCells = COLS,
									SortOrder = Enum.SortOrder.LayoutOrder,
								},
								[Children] = { blankCells, dayCells },
							}),
						},
					}),
					scope:Frame({
						Name = "Months",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Visible = scope:Computed(function(use)
							return use(monthsModeS) > 0.001
						end),
						Layout = {
							Kind = "Grid",
							CellSize = UDim2.new(1 / 3, -4, 0, 40),
							CellPadding = UDim2.fromOffset(4, 4),
							FillDirectionMaxCells = 3,
							SortOrder = Enum.SortOrder.LayoutOrder,
						},
						[Children] = monthCells,
					}),
					scope:Frame({
						Name = "Years",
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Visible = scope:Computed(function(use)
							return use(yearsModeS) > 0.001
						end),
						Layout = {
							Kind = "Grid",
							CellSize = UDim2.new(1 / 4, -4, 0, 40),
							CellPadding = UDim2.fromOffset(4, 4),
							FillDirectionMaxCells = 4,
							SortOrder = Enum.SortOrder.LayoutOrder,
						},
						[Children] = yearCells,
					}),
				},
			}),
		},
	}) :: Frame
end
