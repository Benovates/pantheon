--!strict
--[[
	Editor for a NumberSequence: a plot with draggable keypoints, and number fields for the
	selected keypoint. See docs/Components/Pickers/CurveEditor.md.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Persist = require(script.Parent.Parent.Internal.Persist)
local Bind = require(script.Parent.Parent.Internal.Bind)
local Focus = require(script.Parent.Parent.Internal.Focus)
local ScrollInput = require(script.Parent.Parent.Internal.ScrollInput)
local NumberField = require(script.Parent.NumberField)
local IconButton = require(script.Parent.IconButton)

local Children = Fusion.Children
local peek = Fusion.peek

local HANDLE = 14
local DOUBLE_CLICK = 0.35
local EPSILON = 0.001 -- smallest gap in time between two keypoints
local PAD = 12 -- space between the plot's edge and the area the keypoints move in

type Point = { time: number, value: number, envelope: number }

local function fromSequence(sequence: NumberSequence): { Point }
	local list: { Point } = {}
	for _, key in sequence.Keypoints do
		table.insert(list, { time = key.Time, value = key.Value, envelope = key.Envelope })
	end
	return list
end

local function toSequence(list: { Point }): NumberSequence
	local keys: { NumberSequenceKeypoint } = {}
	for _, point in list do
		table.insert(keys, NumberSequenceKeypoint.new(point.time, point.value, point.envelope))
	end
	return NumberSequence.new(keys)
end

local function samePoints(a: { Point }, b: { Point }): boolean
	if #a ~= #b then
		return false
	end
	for index, point in a do
		local other = b[index]
		if
			math.abs(point.time - other.time) > 1e-6
			or math.abs(point.value - other.value) > 1e-6
			or math.abs(point.envelope - other.envelope) > 1e-6
		then
			return false
		end
	end
	return true
end

--- Value of the line through the points at `time`.
local function valueAt(list: { Point }, time: number): number
	for index = 2, #list do
		local a, b = list[index - 1], list[index]
		if time <= b.time then
			local span = b.time - a.time
			return a.value + (b.value - a.value) * (if span > 0 then (time - a.time) / span else 0)
		end
	end
	return list[#list].value
end

return function(scope: Types.Scope, props: Types.CurveEditorProps): Instance
	local theme = resolveTheme(props)
	local minValue = props.Min or 0
	local maxValue = props.Max or 1
	local span = math.max(maxValue - minValue, 1e-9)
	local height = props.Height or 180
	local disabled = peek(props.Disabled) == true
	local showEnvelope = props.ShowEnvelope == true

	local initial = if peek(props.Value)
		then fromSequence(peek(props.Value) :: NumberSequence)
		else {
			{ time = 0, value = minValue, envelope = 0 },
			{ time = 1, value = maxValue, envelope = 0 },
		}
	local persistKey = Persist.key("CurveEditor", props.Id, typeof(props.Value) == "table")
	local points = Persist.value(scope, persistKey, "points", initial)
	Bind.link(scope, props.Value, points, {
		toInternal = fromSequence,
		toProp = toSequence,
		equals = samePoints,
	})
	local selected = scope:Value(1)

	local function commit(list: { Point })
		if samePoints(list, peek(points)) then
			return
		end
		points:set(list)
		if props.OnChanged then
			props.OnChanged(toSequence(list))
		end
	end

	-- ── the plot ──
	local plot = scope:TextButton({
		Name = "Plot",
		Text = "",
		AutoButtonColor = false,
		Active = not disabled,
		BackgroundColor3 = theme.Colors.SurfaceContainer,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = 1,
		CornerRadius = theme.Metrics.RadiusSm,
	}) :: TextButton
	local area = scope:New("Frame")({
		Name = "Area",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(PAD, PAD),
		Size = UDim2.new(1, -2 * PAD, 1, -2 * PAD),
		Parent = plot,
	}) :: Frame

	-- Grid: quarters, with the 0 line across the middle when the range crosses it.
	for step = 0, 4 do
		local fraction = step / 4
		scope:New("Frame")({
			Name = "GridX",
			Parent = area,
			BackgroundColor3 = theme.Colors.OutlineVariant,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(fraction, 0),
			AnchorPoint = Vector2.new(fraction, 0),
			Size = UDim2.new(0, 1, 1, 0),
		})
		scope:New("Frame")({
			Name = "GridY",
			Parent = area,
			BackgroundColor3 = theme.Colors.OutlineVariant,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, fraction),
			AnchorPoint = Vector2.new(0, fraction),
			Size = UDim2.new(1, 0, 0, 1),
		})
	end
	for _, label in { { maxValue, 0 }, { minValue, 1 } } do
		scope:New("TextLabel")({
			Name = "AxisLabel",
			Parent = plot,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, label[2]),
			Position = UDim2.new(0, 3, label[2], if label[2] == 0 then 1 else -1),
			Size = UDim2.fromOffset(40, 12),
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = theme.Fonts.Mono,
			TextSize = 10,
			TextColor3 = theme.Colors.OnSurfaceVariant,
			Text = tostring(label[1]),
		})
	end

	local segments: { Frame } = {}
	local envelopes: { Frame } = {}
	local handles: { TextButton } = {}

	local function pixelsOf(point: Point): (number, number)
		local size = area.AbsoluteSize
		return point.time * size.X, (1 - (point.value - minValue) / span) * size.Y
	end

	local function line(pool: { Frame }, index: number, color: any, thickness: number): Frame
		local frame = pool[index]
		if not frame then
			frame = scope:New("Frame")({
				Name = "Segment",
				Parent = area,
				AnchorPoint = Vector2.new(0, 0.5),
				BorderSizePixel = 0,
				ZIndex = 2,
			}) :: Frame
			pool[index] = frame
		end
		frame.BackgroundColor3 = peek(color :: any)
		frame.Visible = true
		frame.Size = UDim2.fromOffset(frame.Size.X.Offset, thickness)
		return frame
	end

	local function hideFrom(pool: { Frame }, index: number)
		for at = index, #pool do
			pool[at].Visible = false
		end
	end

	local ensureHandles: () -> ()

	local function redraw()
		local list = peek(points) :: { Point }
		local size = area.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		-- AbsoluteSize can fire before the first refresh, so make sure the handles exist.
		ensureHandles()
		-- Line segments between keypoints.
		for index = 1, #list - 1 do
			local x1, y1 = pixelsOf(list[index])
			local x2, y2 = pixelsOf(list[index + 1])
			local segment = line(segments, index, theme.Colors.Primary, 2)
			local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
			segment.Position = UDim2.fromOffset(x1, y1)
			segment.Size = UDim2.fromOffset(length, 2)
			segment.Rotation = math.deg(math.atan2(y2 - y1, x2 - x1))
		end
		hideFrom(segments, #list)

		-- Envelope: a bar from value − envelope to value + envelope at each keypoint.
		local used = 0
		if showEnvelope then
			for _, point in list do
				if point.envelope > 0 then
					used += 1
					local x, y = pixelsOf(point)
					local reach = point.envelope / span * size.Y
					local bar = line(envelopes, used, theme.Colors.Warning, 1)
					bar.AnchorPoint = Vector2.new(0.5, 0.5)
					bar.Position = UDim2.fromOffset(x, y)
					bar.Size = UDim2.fromOffset(2, reach * 2)
					bar.Rotation = 0
					bar.BackgroundTransparency = 0.35
				end
			end
		end
		hideFrom(envelopes, used + 1)

		-- Handles.
		local current = peek(selected) :: number
		for index, point in list do
			local handle = handles[index]
			local x, y = pixelsOf(point)
			handle.Visible = true
			handle.Position = UDim2.fromOffset(x, y)
			local isSelected = index == current
			handle.Size = UDim2.fromOffset(
				if isSelected then HANDLE + 4 else HANDLE,
				if isSelected then HANDLE + 4 else HANDLE
			)
			handle.BackgroundColor3 =
				peek((if isSelected then theme.Colors.Primary else theme.Colors.Surface) :: any)
		end
		for index = #list + 1, #handles do
			handles[index].Visible = false
		end
	end

	--- Move keypoint `index`. The first and last keypoints stay at 0 and 1.
	local function move(index: number, time: number, value: number)
		local list = table.clone(peek(points)) :: { Point }
		local point = list[index]
		local nextTime = point.time
		if index > 1 and index < #list then
			nextTime =
				math.clamp(time, list[index - 1].time + EPSILON, list[index + 1].time - EPSILON)
		end
		list[index] = {
			time = nextTime,
			value = math.clamp(value, minValue, maxValue),
			envelope = point.envelope,
		}
		commit(list)
	end

	local function addAt(time: number)
		local list = table.clone(peek(points)) :: { Point }
		local at = #list
		for index, point in list do
			if point.time > time then
				at = index
				break
			end
		end
		table.insert(list, at, { time = time, value = valueAt(list, time), envelope = 0 })
		selected:set(at)
		commit(list)
	end

	local function remove(index: number)
		local list = table.clone(peek(points)) :: { Point }
		if index <= 1 or index >= #list then
			return
		end
		table.remove(list, index)
		selected:set(math.max(index - 1, 1))
		commit(list)
	end

	--- Make sure there is one handle for each keypoint.
	function ensureHandles()
		local list = peek(points) :: { Point }
		for index = #handles + 1, #list do
			local handle = scope:New("TextButton")({
				Name = `Point{index}`,
				Text = "",
				AutoButtonColor = false,
				Active = not disabled,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(HANDLE, HANDLE),
				BackgroundColor3 = theme.Colors.Surface,
				BorderSizePixel = 0,
				ZIndex = 4,
				Parent = area,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					scope:New("UIStroke")({
						Color = theme.Colors.Primary,
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				},
			}) :: TextButton
			handles[index] = handle
			Focus.manage(handle, theme)
			table.insert(
				scope,
				handle.InputBegan:Connect(function(input: InputObject)
					if
						disabled
						or (
							input.UserInputType ~= Enum.UserInputType.MouseButton1
							and input.UserInputType ~= Enum.UserInputType.Touch
						)
					then
						return
					end
					selected:set(index)
					redraw()
					ScrollInput.capture(handle, function(changed: InputObject)
						return changed.UserInputType == Enum.UserInputType.MouseMovement
							or changed.UserInputType == Enum.UserInputType.Touch
					end, function(ended: InputObject)
						return ended.UserInputType == Enum.UserInputType.MouseButton1
							or ended.UserInputType == Enum.UserInputType.Touch
					end, function(position: Vector3)
						local origin, size = area.AbsolutePosition, area.AbsoluteSize
						local time = math.clamp((position.X - origin.X) / math.max(size.X, 1), 0, 1)
						local across =
							math.clamp((position.Y - origin.Y) / math.max(size.Y, 1), 0, 1)
						move(index, time, minValue + (1 - across) * span)
					end, function() end)
				end)
			)
			-- Arrow keys nudge a focused keypoint, Delete removes it.
			Focus.onKey(handle, function(key: InputObject): boolean
				local current = (peek(points) :: { Point })[index]
				local point = current
				local stepTime, stepValue = 0.01, span / 100
				if key.KeyCode == Enum.KeyCode.Left then
					move(index, point.time - stepTime, point.value)
				elseif key.KeyCode == Enum.KeyCode.Right then
					move(index, point.time + stepTime, point.value)
				elseif key.KeyCode == Enum.KeyCode.Up then
					move(index, point.time, point.value + stepValue)
				elseif key.KeyCode == Enum.KeyCode.Down then
					move(index, point.time, point.value - stepValue)
				elseif
					key.KeyCode == Enum.KeyCode.Delete or key.KeyCode == Enum.KeyCode.Backspace
				then
					remove(index)
				else
					return false
				end
				return true
			end)
		end
	end

	-- A double click on the plot adds a keypoint there.
	local lastPress = 0
	table.insert(
		scope,
		plot.InputBegan:Connect(function(input: InputObject)
			if disabled or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local now = os.clock()
			if now - lastPress < DOUBLE_CLICK then
				lastPress = 0
				local origin, size = area.AbsolutePosition, area.AbsoluteSize
				addAt(
					math.clamp(
						(input.Position.X - origin.X) / math.max(size.X, 1),
						EPSILON,
						1 - EPSILON
					)
				)
			else
				lastPress = now
			end
		end)
	)

	local function refresh()
		ensureHandles()
		redraw()
	end
	table.insert(scope, scope:Observer(points):onChange(refresh))
	table.insert(
		scope,
		scope:Observer(selected):onChange(function()
			redraw()
		end)
	)
	table.insert(scope, area:GetPropertyChangedSignal("AbsoluteSize"):Connect(redraw))
	-- The segments and handles are drawn by hand, so a theme change has to redraw them.
	for _, color in { theme.Colors.Primary, theme.Colors.Surface, theme.Colors.Warning } do
		if (color :: any).type == "State" then
			table.insert(scope, scope:Observer(color :: any):onChange(redraw))
		end
	end
	task.defer(refresh)

	-- ── fields for the selected keypoint ──
	local function field(
		label: string,
		order: number,
		get: (Point) -> number,
		set: (Point, number) -> Point,
		min: number,
		max: number,
		step: number
	): Instance
		local shown = scope:Value(0)
		local function pull()
			local list = peek(points) :: { Point }
			local point = list[math.clamp(peek(selected) :: number, 1, #list)]
			shown:set(get(point))
		end
		pull()
		table.insert(scope, scope:Observer(points):onChange(pull))
		table.insert(scope, scope:Observer(selected):onChange(pull))
		return NumberField(scope, {
			Theme = theme,
			Label = label,
			Value = shown,
			Min = min,
			Max = max,
			Step = step,
			Disabled = disabled,
			LayoutOrder = order,
			Size = UDim2.new(1 / 3, -6, 0, 32),
			OnChanged = function(n: number)
				local list = table.clone(peek(points)) :: { Point }
				local index = math.clamp(peek(selected) :: number, 1, #list)
				local updated = set(list[index], n)
				if index == 1 then
					updated.time = 0
				elseif index == #list then
					updated.time = 1
				else
					updated.time = math.clamp(
						updated.time,
						list[index - 1].time + EPSILON,
						list[index + 1].time - EPSILON
					)
				end
				list[index] = updated
				commit(list)
			end,
		})
	end

	local fields = scope:New("Frame")({
		Name = "Fields",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = 2,
		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			field("T", 1, function(p)
				return p.time
			end, function(p, n)
				return { time = n, value = p.value, envelope = p.envelope }
			end, 0, 1, 0.01),
			field("V", 2, function(p)
				return p.value
			end, function(p, n)
				return { time = p.time, value = n, envelope = p.envelope }
			end, minValue, maxValue, span / 100),
			if showEnvelope
				then field("±", 3, function(p)
					return p.envelope
				end, function(p, n)
					return { time = p.time, value = p.value, envelope = n }
				end, 0, span, span / 100)
				else nil,
			IconButton(scope, {
				Theme = theme,
				Name = "trash-2",
				Disabled = disabled,
				LayoutOrder = 4,
				Size = UDim2.fromOffset(32, 32),
				OnClick = function()
					remove(peek(selected) :: number)
				end,
			}),
		} :: any,
	}) :: Frame

	return scope:New("Frame")({
		Name = "CurveEditor",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		[Children] = {
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			plot,
			fields,
		} :: any,
	}) :: Frame
end
