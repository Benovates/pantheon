--!strict
--[[
	A roller: a column of numbers on a turning drum, like the time wheels of a phone. Drag, flick
	or scroll it; it settles on a number, and wraps round at the ends. Used by TimePicker.
]]
local Packages = script.Parent.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Parent.Types)
local ScrollInput = require(script.Parent.Parent.ScrollInput)

local RunService = game:GetService("RunService")
local peek = Fusion.peek

local ROW = 34
local STEP = 0.46
local RADIUS = ROW / STEP
local SLOTS = 4
local TEXT_SIZE = 26

export type Options = {
	Theme: Types.Theme,
	Count: number,
	Value: any,
	OnChanged: (number) -> (),
	Format: ((number) -> string)?,
	Width: number?,
	Height: number?,
	LayoutOrder: number?,
}

local function wrap(n: number, count: number): number
	return ((n % count) + count) % count
end

return function(scope: Types.Scope, options: Options): Frame
	local theme = options.Theme
	local count = options.Count
	local format = options.Format or function(n: number)
		return string.format("%02d", n)
	end
	local height = options.Height or ROW * 6

	local position = peek(options.Value) :: number
	local target = position
	local column = scope:New("TextButton")({
		Name = "Wheel",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(options.Width or 72, height),
		LayoutOrder = options.LayoutOrder or 0,
		ZIndex = 2,
	}) :: TextButton

	type Row = { main: TextLabel, ghosts: { TextLabel } }
	local rows: { Row } = {}
	local GHOST_OFFSETS =
		{ Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) }
	local function makeLabel(): TextLabel
		return scope:New("TextLabel")({
			Name = "Row",
			Parent = column,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, ROW),
			FontFace = theme.Fonts.Heading,
			TextSize = TEXT_SIZE,
			TextColor3 = theme.Colors.OnSurface,
			Text = "",
			Visible = false,
			ZIndex = 3,
		}) :: TextLabel
	end

	for slot = -SLOTS, SLOTS do
		local ghosts: { TextLabel } = {}
		for index = 1, #GHOST_OFFSETS do
			ghosts[index] = makeLabel()
		end
		rows[slot + SLOTS + 1] = { main = makeLabel(), ghosts = ghosts }
	end

	local function render(at: number)
		local base = math.floor(at + 0.5)
		local frac = at - base
		for slot = -SLOTS, SLOTS do
			local row = rows[slot + SLOTS + 1]
			local angle = (slot - frac) * STEP
			if math.abs(angle) >= 1.45 then
				row.main.Visible = false
				for _, ghost in row.ghosts do
					ghost.Visible = false
				end
			else
				local depth = math.cos(angle)
				local opacity = depth ^ 3
				local blur = math.clamp(math.abs(angle) / 1.1, 0, 1)
				local spread = blur * 2.6
				local text = format(wrap(base + slot, count))
				local y = RADIUS * math.sin(angle)
				local size = math.max(math.floor(TEXT_SIZE * depth + 0.5), 4)

				row.main.Visible = true
				row.main.Text = text
				row.main.Position = UDim2.new(0.5, 0, 0.5, y)
				row.main.TextSize = size
				row.main.TextTransparency = 1 - opacity * (1 - 0.6 * blur)
				for index, ghost in row.ghosts do
					local show = blur > 0.04
					ghost.Visible = show
					if show then
						local offset = GHOST_OFFSETS[index]
						ghost.Text = text
						ghost.Position =
							UDim2.new(0.5, offset.X * spread, 0.5, y + offset.Y * spread)
						ghost.TextSize = size
						ghost.TextTransparency = 1 - opacity * 0.22 * blur
					end
				end
			end
		end
	end

	local animation: RBXScriptConnection? = nil
	local function stopAnimation()
		if animation then
			animation:Disconnect()
			animation = nil
		end
	end

	local function glide()
		stopAnimation()
		animation = RunService.Heartbeat:Connect(function(dt: number)
			position += (target - position) * (1 - math.exp(-dt * 16))
			if math.abs(target - position) < 0.002 then
				position = target
				stopAnimation()
			end
			render(position)
		end)
	end

	local function settleOn(to: number)
		target = math.floor(to + 0.5)
		options.OnChanged(wrap(target, count))
		glide()
	end
	table.insert(scope, stopAnimation)
	render(position)

	table.insert(
		scope,
		scope:Observer(options.Value):onChange(function()
			local value = peek(options.Value) :: number
			if value == wrap(target, count) then
				return
			end
			local delta = wrap(value - wrap(target, count) + count / 2, count) - count / 2
			target = math.floor(target + 0.5) + delta
			glide()
		end)
	)

	table.insert(
		scope,
		column.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			stopAnimation()
			local startY = input.Position.Y
			local startAt = position
			local lastY, lastT, velocity = startY, os.clock(), 0
			local moved = 0
			ScrollInput.capture(column, function(changed: InputObject)
				return changed.UserInputType == Enum.UserInputType.MouseMovement
					or changed.UserInputType == Enum.UserInputType.Touch
			end, function(ended: InputObject)
				return ended.UserInputType == Enum.UserInputType.MouseButton1
					or ended.UserInputType == Enum.UserInputType.Touch
			end, function(pointer: Vector3)
				moved = math.max(moved, math.abs(pointer.Y - startY))
				position = startAt - (pointer.Y - startY) / ROW
				local now = os.clock()
				local dt = math.max(now - lastT, 1 / 240)
				velocity = (lastY - pointer.Y) / ROW / dt
				lastY, lastT = pointer.Y, now
				render(position)
			end, function()
				if moved < 4 then
					local centre = column.AbsolutePosition.Y + column.AbsoluteSize.Y / 2
					local sine = math.clamp((startY - centre) / RADIUS, -0.99, 0.99)
					settleOn(position + math.asin(sine) / STEP)
				else
					settleOn(position + math.clamp(velocity, -30, 30) * 0.12)
				end
			end)
		end)
	)

	local carried = 0
	table.insert(
		scope,
		ScrollInput.register({
			root = column,
			horizontal = false,
			scrollBy = function(delta: number)
				carried += delta
				local notches = if carried >= 0
					then math.floor(carried / 40)
					else math.ceil(carried / 40)
				if notches ~= 0 then
					carried -= notches * 40
					settleOn(target + notches)
				end
			end,
		})
	)

	return column
end
