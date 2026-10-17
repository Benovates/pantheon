--!strict
--[[
	Inventory bar with an expandable, searchable grid. See docs/Game/Hotbar.md.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Style = require(script.Parent.Style)
local Fuzzy = require(script.Parent.Fuzzy)
local GroupFade = require(script.Parent.Parent.Internal.GroupFade)
local ScrollInput = require(script.Parent.Parent.Internal.ScrollInput)
local Theme = require(script.Parent.Parent.Theme)
local TextField = require(script.Parent.Parent.Components.TextField)
local VirtualList = require(script.Parent.Parent.Components.VirtualList)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

export type HotbarItem = {
	Name: string?,
	Description: string?,
	Image: string?,
	Count: number?,
	Cooldown: any?, -- number | State<number>
	Tags: { string }?,
	Id: string?,
	[string]: any,
}

export type HotbarProps = {
	Items: any?,
	Selected: any?,
	Expanded: any?,
	Slots: number?,
	Capacity: number?,
	Columns: number?,
	ExpandedRows: number?,
	SlotSize: number?,
	BindKeys: boolean?,
	DisableDefault: boolean?,
	SearchScopes: Fuzzy.Scopes?,
	OnSelect: ((slot: number?) -> ())?,
	OnMove: ((from: number, to: number) -> ())?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
}

local KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
}

local DRAG_THRESHOLD = 6 -- px before a press becomes a drag
local PANEL_PAD = 14
local SEARCH_HEIGHT = 40
local PANEL_GAP = 12
-- A slot arriving or leaving animates as one unit (slide, scale, fade) on a bouncy spring.
-- Its width in the layout uses a separate spring without bounce. It opens immediately and
-- closes only after the exit animation, so neighbouring slots don't overlap.
local SHOW_SPEED = 20
local SHOW_DAMPING = 0.55
local WIDTH_SPEED = 18
local EXIT_DELAY = 0.3
local ROW_PAD = 8 -- room above and below a grid row for the hover scale

local darkTheme = Theme.create("Dark")

local function isPointer(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

return function(scope: any, props: HotbarProps): Instance
	local slots = math.clamp(props.Slots or 9, 1, #KEYS)
	local capacity = math.max(props.Capacity or slots * 3, slots)
	local columns = props.Columns or slots
	local maxRows = props.ExpandedRows or 4
	local size = props.SlotSize or 56
	local gap = 6

	local selected = if typeof(props.Selected) == "table" then props.Selected else scope:Value(nil)
	local expanded = if typeof(props.Expanded) == "table"
		then props.Expanded
		else scope:Value(false)
	local dragFrom = scope:Value(nil :: number?)
	local query = scope:Value("")

	if props.DisableDefault ~= false then
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)
		table.insert(scope, function()
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, true)
		end)
	end

	local function itemAt(use: any, index: number): HotbarItem?
		local items = use(props.Items)
		return if items then items[index] else nil
	end

	-- Actions
	local function choose(slot: number)
		if itemAt(peek, slot) == nil then
			return
		end
		local next: number? = if peek(selected) == slot then nil else slot
		selected:set(next)
		if props.OnSelect then
			props.OnSelect(next)
		end
	end

	local function move(from: number, to: number)
		if from == to then
			return
		end
		if props.OnMove then
			-- OnMove owns the inventory, including which slot stays equipped.
			props.OnMove(from, to)
			return
		end
		if typeof(props.Items) ~= "table" or not (props.Items :: any).set then
			return
		end
		local list = table.clone(peek(props.Items))
		list[from], list[to] = list[to], list[from]
		props.Items:set(list)
		-- The equipped item travels with the move.
		local current = peek(selected)
		if current == from then
			selected:set(to)
		elseif current == to then
			selected:set(from)
		end
	end

	if props.BindKeys ~= false then
		table.insert(
			scope,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if processed then
					return
				end
				if input.KeyCode == Enum.KeyCode.Backquote then
					expanded:set(not peek(expanded))
					return
				end
				local index = table.find(KEYS, input.KeyCode)
				if index and index <= slots then
					choose(index)
				end
			end)
		)
	end

	-- Drag support
	type Cell = { gui: GuiObject, index: any }
	local cells: { Cell } = {}
	local root: Frame

	--- Copy of the item (icon or letters) that follows the pointer while dragging.
	local function makeGhost(item: HotbarItem, at: Vector3): Frame
		local ghost = scope:New("Frame")({
			Name = "DragGhost",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = Style.Panel,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 100,
			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, Style.Radius) }),
				scope:New("UIScale")({ Scale = 1.12 }),
				scope:New("UIStroke")({
					Color = Style.Edge,
					Transparency = 0.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				-- Held items cast a bigger shadow than an equipped one.
				scope:New("UIShadow")({
					Color = Color3.new(0, 0, 0),
					Transparency = 0.35,
					BlurRadius = UDim.new(0, 20),
					Offset = UDim2.fromOffset(0, 8),
				}),
				if item.Image
					then scope:New("ImageLabel")({
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.7, 0.7),
						Image = item.Image,
						ZIndex = 101,
					})
					else scope:New("TextLabel")({
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						FontFace = Style.FontBold,
						TextSize = math.floor(size * 0.36),
						TextColor3 = Style.Text,
						Text = string.upper(string.sub(item.Name or "", 1, 2)),
						ZIndex = 101,
					}),
			},
		}) :: Frame
		local collector = root:FindFirstAncestorWhichIsA("LayerCollector")
		if collector then
			ghost.Parent = collector
			local origin = (collector :: any).AbsolutePosition :: Vector2
			ghost.Position = UDim2.fromOffset(at.X - origin.X, at.Y - origin.Y)
		end
		return ghost
	end

	local function slotAt(point: Vector3): number?
		for _, cell in cells do
			local index = peek(cell.index) :: number?
			local topLeft, extent = cell.gui.AbsolutePosition, cell.gui.AbsoluteSize
			if
				index
				and cell.gui.Visible
				and point.X >= topLeft.X
				and point.X <= topLeft.X + math.max(extent.X, size)
				and point.Y >= topLeft.Y
				and point.Y <= topLeft.Y + extent.Y
			then
				return index
			end
		end
		return nil
	end

	-- One slot
	--- `indexArg` is a fixed slot number (the bar) or a State of one (grid cells, whose slot
	--- changes as the search reorders them).
	local function slotFrame(sc: any, indexArg: any, inBar: boolean): Instance
		local idx = if typeof(indexArg) == "number" then sc:Value(indexArg) else indexArg
		local item = sc:Computed(function(use)
			local index = use(idx)
			return if index then itemAt(use, index) else nil
		end)
		-- Keep the last item so its icon is still drawn while the slot animates out.
		local display = sc:Value(peek(item))
		table.insert(
			sc,
			sc:Observer(item):onChange(function()
				local current = peek(item)
				if current then
					display:set(current)
				end
			end)
		)
		local has = sc:Computed(function(use)
			return use(item) ~= nil
		end)
		local hovered = sc:Value(false)
		-- The name tip and the equipped shadow are created on first use, not for every slot.
		local tipWanted = sc:Value(false)
		local shadowWanted = sc:Value(false)
		local isSelected = sc:Computed(function(use)
			local index = use(idx)
			return index ~= nil and use(selected) == index
		end)
		local dragActive = sc:Computed(function(use)
			return use(dragFrom) ~= nil
		end)
		local isSource = sc:Computed(function(use)
			local index = use(idx)
			return index ~= nil and use(dragFrom) == index
		end)

		-- A slot is shown when it has an item, when it is empty during a drag (a drop target), or
		-- when the bar is expanded. Other slots are hidden and the bar closes up around them.
		local shown = sc:Computed(function(use)
			if use(idx) == nil then
				return false
			end
			return use(has) or use(dragActive) or (inBar and use(expanded))
		end)
		-- Arrival: slides up from below, small and transparent. Departure: keeps sliding up,
		-- shrinks and fades. `slide` is +1 below the slot, 0 in place and -1 above it.
		local show = sc:Spring(
			sc:Computed(function(use)
				return if use(shown) then 1 else 0
			end),
			SHOW_SPEED,
			SHOW_DAMPING
		)
		local slideGoal = sc:Value(if peek(shown) then 0 else -1)
		local slide = sc:Spring(slideGoal, SHOW_SPEED, SHOW_DAMPING)
		local widthGoal = sc:Value(if peek(shown) then 1 else 0)
		local width = sc:Spring(widthGoal, WIDTH_SPEED, 1)
		local ticket = 0
		table.insert(
			sc,
			sc:Observer(shown):onChange(function()
				ticket += 1
				local mine = ticket
				if peek(shown) then
					(slide :: any):setPosition(1)
					slideGoal:set(0)
					widthGoal:set(1)
				else
					slideGoal:set(-1)
					task.delay(EXIT_DELAY, function()
						if mine == ticket then
							widthGoal:set(0)
						end
					end)
				end
			end)
		)
		-- An item dropped into a slot that is already open just fades in.
		local itemIn = sc:Spring(
			sc:Computed(function(use)
				return if use(has) then 1 else 0
			end),
			26,
			1
		)
		local fade = sc:Computed(function(use)
			local visible = math.clamp(math.min(use(show) :: number, use(itemIn) :: number), 0, 1)
			local dimmed = if use(isSource) then 0.6 else 0
			return math.max(1 - visible, dimmed)
		end)

		local lift = sc:Spring(
			sc:Computed(function(use)
				return if use(hovered) and not use(dragActive) then 1 else 0
			end),
			34,
			0.7
		)
		local equip = sc:Spring(
			sc:Computed(function(use)
				return if use(isSelected) and use(has) then 1 else 0
			end),
			28,
			0.8
		)
		local tipIn = sc:Spring(
			sc:Computed(function(use)
				return if use(hovered) and not use(dragActive) and use(has) then 1 else 0
			end),
			36,
			1
		)
		local cooldown = sc:Computed(function(use)
			local current = use(item) :: HotbarItem?
			if current == nil or current.Cooldown == nil then
				return 0
			end
			return math.clamp(use(current.Cooldown) :: number, 0, 1)
		end)

		table.insert(
			sc,
			sc:Observer(isSelected):onBind(function()
				if peek(isSelected) then
					shadowWanted:set(true)
				end
			end)
		)

		local ink = sc:Computed(function(use)
			return if use(equip) > 0.5 then Style.OnEquipped else Style.Text
		end)

		local button = sc:New("TextButton")({
			Name = "Slot",
			Text = "",
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = sc:Computed(function(use)
				return UDim2.new(0.5, 0, 0.5, (use(slide) :: number) * size * 0.6)
			end),
			Size = UDim2.fromOffset(size, size),
			BorderSizePixel = 0,
			BackgroundColor3 = sc:Computed(function(use)
				return Style.Panel:Lerp(Style.Equipped, math.clamp(use(equip) :: number, 0, 1))
			end),
			BackgroundTransparency = sc:Computed(function(use)
				local base = Style.PanelTransparency - 0.12 * use(lift)
				local filled = base * (1 - math.clamp(use(equip) :: number, 0, 1))
					+ 0.04 * use(equip)
				-- Fade in with the slot.
				return 1 - (1 - filled) * math.clamp(use(show) :: number, 0, 1)
			end),
			[OnEvent("MouseEnter")] = function()
				hovered:set(true)
				tipWanted:set(true)
			end,
			[OnEvent("MouseLeave")] = function()
				hovered:set(false)
			end,
			[Children] = (
					{
						sc:New("UICorner")({ CornerRadius = UDim.new(0, Style.Radius) }),
						sc:New("UIScale")({
							Scale = sc:Computed(function(use)
								local present = math.clamp(use(show) :: number, 0, 1.08)
								return (0.6 + 0.4 * present)
									* (1 + 0.1 * use(lift) + 0.04 * use(equip))
							end),
						}),
						sc:New("UIStroke")({
							Color = Style.Edge,
							Thickness = 1,
							Transparency = sc:Computed(function(use)
								local lit = math.clamp(use(equip) :: number, 0, 1)
								local edge = Style.EdgeTransparency
									+ (1 - Style.EdgeTransparency) * lit
								return 1 - (1 - edge) * math.clamp(use(show) :: number, 0, 1)
							end),
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						}),
						-- Shadow for the equipped slot.
						sc:Computed(function(get: any, inner: any)
							if not get(shadowWanted) then
								return nil
							end
							return inner:New("UIShadow")({
								Color = Color3.new(0, 0, 0),
								Transparency = inner:Computed(function(use)
									return 1 - 0.5 * math.clamp(use(equip) :: number, 0, 1)
								end),
								BlurRadius = UDim.new(0, 10),
								Offset = UDim2.fromOffset(0, 3),
							})
						end),
						-- Item contents.
						sc:New("Frame")({
							Name = "Contents",
							BackgroundTransparency = 1,
							Size = UDim2.fromScale(1, 1),
							[Children] = {
								sc:New("ImageLabel")({
									Name = "Icon",
									BackgroundTransparency = 1,
									AnchorPoint = Vector2.new(0.5, 0.5),
									Position = UDim2.fromScale(0.5, 0.5),
									Size = UDim2.fromScale(0.7, 0.7),
									ImageTransparency = fade,
									Image = sc:Computed(function(use)
										local current = use(display)
										return if current then current.Image or "" else ""
									end),
									ScaleType = Enum.ScaleType.Fit,
								}),
								sc:New("TextLabel")({
									Name = "Glyph",
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(1, 1),
									FontFace = Style.FontBold,
									TextSize = math.floor(size * 0.36),
									TextColor3 = ink,
									TextTransparency = fade,
									Text = sc:Computed(function(use)
										local current = use(display)
										if current == nil or current.Image then
											return ""
										end
										return string.upper(string.sub(current.Name or "", 1, 2))
									end),
								}),
								sc:New("TextLabel")({
									Name = "Count",
									BackgroundTransparency = 1,
									AnchorPoint = Vector2.new(1, 1),
									Position = UDim2.new(1, -5, 1, -3),
									Size = UDim2.fromOffset(30, 14),
									TextXAlignment = Enum.TextXAlignment.Right,
									FontFace = Style.FontBold,
									TextSize = 13,
									TextColor3 = ink,
									TextTransparency = fade,
									Visible = sc:Computed(function(use)
										local current = use(display)
										return current ~= nil
											and current.Count ~= nil
											and current.Count > 1
									end),
									Text = sc:Computed(function(use)
										local current = use(display)
										return if current and current.Count
											then tostring(current.Count)
											else ""
									end),
								}),
							},
						}),
						-- Cooldown overlay; its height is the remaining fraction.
						sc:New("Frame")({
							Name = "Cooldown",
							AnchorPoint = Vector2.new(0, 1),
							Position = UDim2.fromScale(0, 1),
							Size = sc:Computed(function(use)
								return UDim2.fromScale(1, use(cooldown))
							end),
							BackgroundColor3 = Color3.new(0, 0, 0),
							BackgroundTransparency = 0.45,
							BorderSizePixel = 0,
							Visible = sc:Computed(function(use)
								return use(cooldown) > 0
							end),
							[Children] = {
								sc:New("UICorner")({ CornerRadius = UDim.new(0, Style.Radius) }),
							},
						}),
						if inBar
							then sc:New("TextLabel")({
								Name = "Key",
								BackgroundTransparency = 1,
								Position = UDim2.fromOffset(6, 3),
								Size = UDim2.fromOffset(14, 14),
								TextXAlignment = Enum.TextXAlignment.Left,
								FontFace = Style.FontBold,
								TextSize = 12,
								TextColor3 = sc:Computed(function(use)
									return if use(equip) > 0.5
										then Style.OnEquipped
										else Style.TextDim
								end),
								Visible = sc:Computed(function(use)
									return use(has) or use(expanded)
								end),
								Text = tostring(peek(idx) % 10),
							})
							else nil,
						-- Name tip above the slot.
						sc:Computed(function(get: any, inner: any)
							if not get(tipWanted) then
								return nil
							end
							return inner:New("Frame")({
								Name = "Tip",
								AnchorPoint = Vector2.new(0.5, 1),
								Position = inner:Computed(function(use)
									return UDim2.new(
										0.5,
										0,
										0,
										-6 - 4 * (1 - math.clamp(use(tipIn) :: number, 0, 1))
									)
								end),
								AutomaticSize = Enum.AutomaticSize.XY,
								BackgroundColor3 = Style.Panel,
								BackgroundTransparency = inner:Computed(function(use)
									return 1 - 0.9 * math.clamp(use(tipIn) :: number, 0, 1)
								end),
								BorderSizePixel = 0,
								ZIndex = 20,
								Visible = inner:Computed(function(use)
									return (use(tipIn) :: number) > 0.02
								end),
								[Children] = {
									inner:New("UICorner")({ CornerRadius = UDim.new(0, 6) }),
									inner:New("UIPadding")({
										PaddingTop = UDim.new(0, 5),
										PaddingBottom = UDim.new(0, 5),
										PaddingLeft = UDim.new(0, 9),
										PaddingRight = UDim.new(0, 9),
									}),
									inner:New("UIListLayout")({
										SortOrder = Enum.SortOrder.LayoutOrder,
									}),
									inner:New("TextLabel")({
										BackgroundTransparency = 1,
										AutomaticSize = Enum.AutomaticSize.XY,
										LayoutOrder = 1,
										FontFace = Style.FontBold,
										TextSize = 13,
										TextColor3 = Style.Text,
										TextTransparency = inner:Computed(function(use)
											return 1 - math.clamp(use(tipIn) :: number, 0, 1)
										end),
										Text = inner:Computed(function(use)
											local current = use(display)
											return if current then current.Name or "" else ""
										end),
									}),
									inner:New("TextLabel")({
										BackgroundTransparency = 1,
										AutomaticSize = Enum.AutomaticSize.XY,
										LayoutOrder = 2,
										FontFace = Style.Font,
										TextSize = 12,
										TextColor3 = Style.TextDim,
										TextTransparency = inner:Computed(function(use)
											return 1 - math.clamp(use(tipIn) :: number, 0, 1)
										end),
										Visible = inner:Computed(function(use)
											local current = use(display)
											return current ~= nil and current.Description ~= nil
										end),
										Text = inner:Computed(function(use)
											local current = use(display)
											return if current then current.Description or "" else ""
										end),
									}),
								},
							})
						end),
					} :: any
				) :: any,
		}) :: TextButton

		-- A click equips. Moving past the threshold starts a drag.
		table.insert(
			sc,
			button.InputBegan:Connect(function(input: InputObject)
				local index = peek(idx) :: number?
				if not isPointer(input) or index == nil or peek(item) == nil then
					return
				end
				local start = input.Position
				local last = start
				local ghost: Frame? = nil
				ScrollInput.capture(
					button,
					function(changed: InputObject)
						return changed.UserInputType == Enum.UserInputType.MouseMovement
							or changed.UserInputType == Enum.UserInputType.Touch
					end,
					isPointer,
					function(position: Vector3)
						last = position
						if ghost == nil and (position - start).Magnitude > DRAG_THRESHOLD then
							local picked = peek(item)
							if picked then
								dragFrom:set(index)
								hovered:set(false)
								ghost = makeGhost(picked, position)
							end
						end
						if ghost then
							local collector = root:FindFirstAncestorWhichIsA("LayerCollector")
							if collector then
								local origin = (collector :: any).AbsolutePosition :: Vector2
								ghost.Position =
									UDim2.fromOffset(position.X - origin.X, position.Y - origin.Y)
							end
						end
					end,
					function()
						if ghost then
							ghost:Destroy()
							dragFrom:set(nil)
							local target = slotAt(last)
							if target then
								move(index, target)
							end
						elseif (last - start).Magnitude <= DRAG_THRESHOLD then
							choose(index)
						end
					end
				)
			end)
		)

		local cell = sc:New("Frame")({
			Name = "Slot",
			BackgroundTransparency = 1,
			LayoutOrder = if inBar then peek(idx) else 0,
			Size = sc:Computed(function(use)
				return UDim2.fromOffset(size * math.max(use(width) :: number, 0), size)
			end),
			Visible = sc:Computed(function(use)
				return (use(width) :: number) > 0.01 or (use(show) :: number) > 0.01
			end),
			ZIndex = sc:Computed(function(use)
				return if use(hovered) or use(isSource) then 6 else 1
			end),
			[Children] = { button },
		}) :: Frame
		local entry: Cell = { gui = cell, index = idx }
		table.insert(cells, entry)
		table.insert(sc, function()
			local at = table.find(cells, entry)
			if at then
				table.remove(cells, at)
			end
		end)
		return cell
	end

	-- The bar
	local rowChildren: { any } = {
		scope:New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}),
	}
	for index = 1, slots do
		table.insert(rowChildren, slotFrame(scope, index, true))
	end

	-- The grid: which slots it lists, in what order
	-- Slots the grid lists. Normally every filled slot outside the bar, in order. While searching,
	-- the matches by score. While dragging, all of them, so items can be dropped on empty slots.
	local gridSlots = scope:Computed(function(use)
		local text = use(query) :: string
		local dragging = use(dragFrom) ~= nil
		local found: { { index: number, score: number } } = {}
		for index = slots + 1, capacity do
			local current = itemAt(use, index)
			if dragging then
				table.insert(found, { index = index, score = 1 })
			elseif current then
				local score = if text == ""
					then 1
					else Fuzzy.matchItem(text, current, props.SearchScopes)
				if score then
					table.insert(found, { index = index, score = score })
				end
			end
		end
		if text ~= "" and not dragging then
			table.sort(found, function(a, b)
				if a.score ~= b.score then
					return a.score > b.score
				end
				return a.index < b.index
			end)
		end
		local list: { number } = {}
		for _, entry in found do
			table.insert(list, entry.index)
		end
		return list
	end)
	local rowCount = scope:Computed(function(use)
		return math.ceil(#use(gridSlots) / columns)
	end)

	local rowHeight = size + 2 * ROW_PAD
	local gridWidth = columns * (size + gap) - gap
	local gridViewHeight = scope:Computed(function(use)
		return math.clamp(use(rowCount) :: number, 1, maxRows) * rowHeight
	end)
	local panelWidth = gridWidth + 2 * PANEL_PAD + 16
	local panelHeight = scope:Computed(function(use)
		return 2 * PANEL_PAD + SEARCH_HEIGHT + PANEL_GAP + (use(gridViewHeight) :: number)
	end)

	local reveal = scope:Spring(
		scope:Computed(function(use)
			return if use(expanded) then 1 else 0
		end),
		26,
		0.7
	)

	local search = TextField(scope, {
		Theme = darkTheme,
		Placeholder = "Search",
		LeadingIcon = "search",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		OnChanged = function(text: string)
			query:set(text)
		end,
	})

	local grid = VirtualList(scope, {
		Theme = darkTheme,
		LayoutOrder = 2,
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, use(gridViewHeight))
		end),
		ItemCount = rowCount,
		ItemHeight = rowHeight,
		RenderItem = function(sc: any, row: number)
			local kids: { any } = {
				sc:New("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, gap),
				}),
			}
			for column = 1, columns do
				local position = (row - 1) * columns + column
				local slotState = sc:Computed(function(use)
					return use(gridSlots)[position]
				end)
				local cell = slotFrame(sc, slotState, false) :: Frame
				cell.LayoutOrder = column
				table.insert(kids, cell)
			end
			return sc:New("Frame")({ BackgroundTransparency = 1, [Children] = kids })
		end,
	})

	-- Inventory panel. Scales up, slides up and fades in from its bottom edge.
	local panel = scope:New("Frame")({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = scope:Computed(function(use)
			return UDim2.new(0.5, 0, 1, (1 - math.clamp(use(reveal) :: number, 0, 1.2)) * 28)
		end),
		Size = scope:Computed(function(use)
			return UDim2.fromOffset(panelWidth, use(panelHeight))
		end),
		BackgroundColor3 = Style.Panel,
		BackgroundTransparency = Style.PanelTransparency,
		BorderSizePixel = 0,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
			scope:New("UIScale")({
				Scale = scope:Computed(function(use)
					return 0.9 + 0.1 * math.clamp(use(reveal) :: number, 0, 1.2)
				end),
			}),
			scope:New("UIStroke")({
				Color = Style.Edge,
				Transparency = Style.EdgeTransparency,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, PANEL_PAD),
				PaddingBottom = UDim.new(0, PANEL_PAD),
				PaddingLeft = UDim.new(0, PANEL_PAD),
				PaddingRight = UDim.new(0, PANEL_PAD),
			}),
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, PANEL_GAP),
			}),
			search,
			grid,
		},
	}) :: Frame
	GroupFade.bind(scope, panel, reveal)

	local gridHolder = scope:New("Frame")({
		Name = "GridHolder",
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = scope:Computed(function(use)
			return UDim2.fromOffset(panelWidth, use(panelHeight))
		end),
		Visible = scope:Computed(function(use)
			return (use(reveal) :: number) > 0.01
		end),
		[Children] = { panel },
	})

	root = scope:New("Frame")({
		Name = "Hotbar",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			scope:New("UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, gap),
			}),
			gridHolder,
			scope:New("Frame")({
				Name = "Bar",
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.fromOffset(0, size),
				AutomaticSize = Enum.AutomaticSize.X,
				[Children] = rowChildren,
			}),
		},
	}) :: Frame
	return root
end
