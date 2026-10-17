--!strict
--[[
	Animated number, in the style of SwiftUI's `.contentTransition(.numericText())`.

	Style "Numeric" (default) follows iOS's measured behaviour (see react-native-numeric-text,
	which reverse-engineered it frame by frame). A digit that changes goes straight from its
	old value to its new one, and each glyph animates four independent channels, each a
	second-order step response with its own damping:

		offset  0.59 glyph-heights; the only channel that overshoots (iOS: ~12%, here ~25%)
		scale   born / dies at 0.3984, critically damped
		opacity critically damped
		blur    0.2 × text size at its peak (text-mode UIShadow; without it, no blur)

	The arriving glyph enters from one side and the departing one leaves to the other: from
	above when the number rose, below when it fell. Changing columns cascade left to right over
	0.15 s; a change in digit count (999 → 1,000) doesn't cascade. New digits grow in place from
	small and blurred, removed ones shrink and blur away in place. A new change never cancels
	one in flight: the old glyph keeps fading while the next layers on top.

	Style "Roll": the odometer wheel instead, passing through every digit in between.

	Columns are keyed by position from the right, so the decimal point and suffix stay put
	while the integer part grows and shrinks.

	Size: the box is fixed, so changing the number never resizes or shifts the layout around it.
	Width is reserved for `Digits` integer digits (or set `Width`). It includes a little padding
	for the glyphs' travel and blur and clips to it: glyphs overflowing an unclipped box would
	count towards the parent's automatic size and make the row grow and shrink as digits move.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Features = require(script.Parent.Parent.Internal.Features)

local RunService = game:GetService("RunService")

local Children = Fusion.Children
local peek = Fusion.peek

local LINE_HEIGHT = 1.25 -- × text size
local DIGIT_WIDTH = 0.62 -- × text size (≈ tabular digits)
-- "Roll" style: an underdamped spring, so the wheel overshoots a touch.
local SPRING_SPEED = 11 -- Fusion spring speed; lower = slower
local SPRING_DAMPING = 0.6
local ROLL_SCALE = 0.3 -- digits shrink to 70% as they leave / arrive from 70%

-- "Numeric" style: constants measured from iOS (react-native-numeric-text).
local ENTRY = 0.59375 -- offset, in glyph heights (a glyph is ~ the text size tall)
local BORN_SCALE = 0.3984375 -- size a glyph is born at and dies at
local CASCADE = 0.15 -- seconds, left to right across changing columns
local LIFETIME = 1.1 -- seconds until every channel has settled
local BLUR_RADIUS = 0.3 -- peak blur radius, × text size
-- Second-order step response parameters per channel. These are deliberately a bit slower and
-- bouncier than iOS's own measurements (offset damping 0.55, ω ≈ 20, ~12% overshoot): the
-- offset lands with ~25% overshoot and takes ~0.7 s to settle. `Speed` and `Bounce` tune them.
local BOUNCE_DEFAULT = 0.8 -- damping = 1 - 0.75 * bounce → 0.4 (≈ 25% overshoot)
local OFFSET_OMEGA = 15
local SCALE_DAMPING, SCALE_OMEGA = 1, 15
local ALPHA_DAMPING, ALPHA_OMEGA = 1, 16
local BLUR_DAMPING, BLUR_OMEGA = 0.91, 9

--- Unit step response of a second-order system: 0 at t = 0, settling to 1 (overshooting
--- first when damping < 1).
local function response(t: number, damping: number, omega: number): number
	if t <= 0 then
		return 0
	end
	if damping >= 1 then
		local x = omega * t
		return 1 - (1 + x) * math.exp(-x)
	end
	local damped = omega * math.sqrt(1 - damping * damping)
	local decay = math.exp(-damping * omega * t)
	return 1 - decay * (math.cos(damped * t) + (damping * omega / damped) * math.sin(damped * t))
end

local function smoothstep(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

type Glyph = {
	label: TextLabel,
	scale: UIScale,
	ghost: any?, -- the text shadow standing in for the blurred glyph
	role: "arrive" | "depart",
	onset: number,
	--- -1 when the number rose (arrivals enter from above), +1 when it fell.
	rise: number,
	--- false: grows / shrinks in place (a digit being added or removed).
	moves: boolean,
	--- Opacity a glyph still had when it was interrupted mid-arrival.
	carry: number,
	slot: any,
	--- At rest (never animated, or finished): no need to evaluate its curves.
	settled: boolean,
}

type Slot = {
	kind: "digit" | "text",
	char: string,
	root: Instance,
	inner: any,
	--- Flipped by the inner scope's own cleanup, whoever triggers it (us or the parent).
	dead: { value: boolean },
	target: any?,
	--- Roll: the digit position the spring heads for.
	position: number,
	--- Numeric: the cell glyphs live in, and the glyph currently at rest / arriving.
	cell: Frame?,
	glyph: Glyph?,
}

local function format(props: Types.NumberSpinnerProps, value: number): string
	local decimals = props.Decimals or 0
	local text = string.format(`%.{decimals}f`, math.abs(value))
	local matchedInt, matchedFrac = string.match(text, "^(%d+)%.?(%d*)$")
	local int: string = matchedInt or text
	local frac: string = matchedFrac or ""
	if props.Grouping ~= false then
		local grouped = string.reverse(int)
		grouped = (string.gsub(grouped, "(%d%d%d)", "%1,"))
		grouped = string.reverse(grouped)
		int = (string.gsub(grouped, "^,", ""))
	end
	local negative = value < 0 and tonumber(text) ~= 0
	return (props.Prefix or "")
		.. (if negative then "-" else "")
		.. int
		.. (if decimals > 0 then "." .. frac else "")
		.. (props.Suffix or "")
end

return function(scope: Types.Scope, props: Types.NumberSpinnerProps): Frame
	local theme = resolveTheme(props)
	local textSize = props.TextSize or 28
	local lineHeight = math.floor(textSize * LINE_HEIGHT)
	local digitWidth = props.DigitWidth or math.floor(textSize * DIGIT_WIDTH)
	local color = props.Color or theme.Colors.OnSurface
	local font = props.FontFace or theme.Fonts.Body

	-- Reserve a fixed width so the box never changes size as the number does.
	local function integerDigits(v: number): number
		return #tostring(math.floor(math.abs(v)))
	end
	local startValue: number = if typeof(props.Value) == "table"
		then peek(props.Value :: any) :: number
		else props.Value :: number
	local decimals = props.Decimals or 0
	local digits = props.Digits or math.max(integerDigits(startValue) + 1, 4)
	local separatorWidth = textSize * 0.32
	local affixWidth = (#(props.Prefix or "") + #(props.Suffix or "")) * textSize * 0.62
	local reserved = digits * digitWidth
		+ (if props.Grouping ~= false then math.floor((digits - 1) / 3) * separatorWidth else 0)
		+ (if decimals > 0 then decimals * digitWidth + separatorWidth else 0)
		+ affixWidth
	local width = props.Width or math.ceil(reserved)

	-- The box carries padding for the glyphs' travel and blur and clips to it, so nothing that
	-- overflows can influence the parent's layout.
	local style = props.Style or "Numeric"
	local useBlur = Features.shadowText()
	local blurMax = textSize * (if style == "Roll" then 0.32 else BLUR_RADIUS)
	local padX, padY
	if style == "Roll" then
		padX = if useBlur then math.ceil(blurMax) + 2 else 0
		padY = if useBlur then math.ceil(blurMax * 1.25 + lineHeight * 0.14) else 0
	else
		padX = math.ceil(blurMax) + 2
		padY = math.ceil(textSize * 0.4 + blurMax * 0.6)
	end
	if props.Padding then
		padX, padY = props.Padding, props.Padding
	end

	-- Fixed-size, clipping outer box.
	local container = scope:New("Frame")({
		Name = "NumberSpinner",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.None,
		ClipsDescendants = style ~= "Roll" or useBlur,
		Size = UDim2.fromOffset(width + padX * 2, lineHeight + padY * 2),
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
	}) :: Frame

	-- The digit cells, inset by the padding.
	local cells = scope:New("Frame")({
		Name = "Cells",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.None,
		Position = UDim2.fromOffset(padX, padY),
		Size = UDim2.fromOffset(width, lineHeight),
		Parent = container,
		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = props.Align or Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	}) :: Frame

	local slots: { [number]: Slot } = {}

	local function destroySlot(slot: Slot)
		if not slot.dead.value then
			Fusion.doCleanup(slot.inner)
		end
	end

	--- Inner scopes are destroyed exactly once, either by us when a column is replaced or by
	--- the parent scope when the whole spinner goes. Track which, so we never destroy twice.
	local function innerScope(): (any, { value: boolean })
		local inner = scope:innerScope()
		local dead = { value = false }
		table.insert(inner, function()
			dead.value = true
		end)
		return inner, dead
	end

	local function makeText(index: number, char: string): Slot
		local inner, dead = innerScope()
		inner:New("TextLabel")({
			Name = `Text{index}`,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, lineHeight),
			LayoutOrder = -index,
			FontFace = font,
			TextSize = textSize,
			TextColor3 = color,
			Text = char,
			Parent = cells,
		})
		return {
			kind = "text",
			char = char,
			root = container,
			inner = inner,
			dead = dead,
			position = 0,
		}
	end

	-- p: how far a label is from being the resting digit (0 = sharp and in place, 1 = gone).
	--   glyph: fades out over the first ~45% of p
	--   blur : text shadow that rises quickly, blurs more with p, then fades before p = 1
	local function glyphTransparency(p: number): number
		local t = math.clamp(p / 0.45, 0, 1)
		return t * t * (3 - 2 * t)
	end
	local function shadowStrength(p: number): number
		local rise = math.clamp(p / 0.2, 0, 1)
		local fall = 1 - math.clamp((p - 0.55) / 0.45, 0, 1)
		return rise * fall
	end
	local function motionBlur(inner: any, progress: any)
		return inner:New("UIShadow")({
			Mode = "Text",
			Color = color,
			Transparency = inner:Computed(function(use)
				return 1 - 0.75 * shadowStrength(use(progress) :: number)
			end),
			BlurRadius = inner:Computed(function(use)
				return UDim.new(0, blurMax * (use(progress) :: number) ^ 0.8)
			end),
			Offset = UDim2.fromOffset(0, 0),
		})
	end

	local function digitFrame(inner: any, index: number, kids: { any }): Frame
		return inner:New("Frame")({
			Name = `Digit{index}`,
			BackgroundTransparency = 1,
			-- Digits are fully faded before they leave their cell, so clipping is only needed
			-- without the blur; with it, clipping would cut the shadow off at the cell edge.
			ClipsDescendants = not useBlur,
			Size = UDim2.fromOffset(digitWidth, lineHeight),
			LayoutOrder = -index,
			Parent = cells,
			[Children] = kids,
		}) :: Frame
	end

	-- Numeric: per-glyph transitions, after iOS
	local glyphHeight = textSize
	local timeScale = math.max(props.Speed or 1, 0.1)
	local offsetDamping = math.clamp(1 - 0.75 * (props.Bounce or BOUNCE_DEFAULT), 0.1, 1)
	local active: { [Glyph]: boolean } = {}
	local stepConnection: RBXScriptConnection? = nil
	table.insert(scope, function()
		if stepConnection then
			stepConnection:Disconnect()
			stepConnection = nil
		end
	end)

	--- Where a glyph is at time `now`: (offset px, scale, opacity, blur 0..1).
	local function poseOf(g: Glyph, now: number): (number, number, number, number)
		if g.settled then
			return 0, 1, 1, 0
		end
		local t = (now - g.onset) * timeScale
		if g.role == "arrive" then
			if t < 0 then
				return 0, BORN_SCALE, 0, 1 -- waiting its turn in the cascade
			end
			local offset = if g.moves
				then g.rise * ENTRY * glyphHeight * (1 - response(t, offsetDamping, OFFSET_OMEGA))
				else 0
			return offset,
				BORN_SCALE + (1 - BORN_SCALE) * response(t, SCALE_DAMPING, SCALE_OMEGA),
				response(t, ALPHA_DAMPING, ALPHA_OMEGA),
				1 - response(t, BLUR_DAMPING, BLUR_OMEGA)
		end
		if t < 0 then
			return 0, 1, g.carry, 0 -- still showing, waiting its turn
		end
		local offset = if g.moves
			then -g.rise * ENTRY * glyphHeight * response(t, offsetDamping, OFFSET_OMEGA)
			else 0
		return offset,
			1 - (1 - BORN_SCALE) * response(t, SCALE_DAMPING, SCALE_OMEGA),
			g.carry * (1 - response(t, ALPHA_DAMPING, ALPHA_OMEGA)),
			response(t, BLUR_DAMPING, BLUR_OMEGA)
	end

	local function applyPose(g: Glyph, offset: number, scale: number, alpha: number, blur: number)
		g.label.Position = UDim2.new(0.5, 0, 0.5, offset)
		g.scale.Scale = math.max(scale, 0.02)
		local ghost = g.ghost
		if ghost then
			-- The sharp glyph gives way to its text shadow, which stands in for the blurred
			-- glyph: blurrier = more shadow, less glyph.
			local b = math.clamp(blur, 0, 1)
			g.label.TextTransparency = 1 - math.clamp(alpha * (1 - smoothstep(b / 0.7)), 0, 1)
			ghost.Transparency = 1 - 0.9 * math.clamp(alpha * smoothstep(b / 0.3), 0, 1)
			ghost.BlurRadius = UDim.new(0, b * BLUR_RADIUS * textSize)
		else
			g.label.TextTransparency = 1 - math.clamp(alpha, 0, 1)
		end
	end

	local function tick()
		local now = os.clock()
		for g in active do
			if g.slot.dead.value then
				active[g] = nil
			elseif (now - g.onset) * timeScale > LIFETIME then
				active[g] = nil
				if g.role == "depart" then
					g.label:Destroy()
				else
					g.settled = true
					applyPose(g, 0, 1, 1, 0)
				end
			else
				applyPose(g, poseOf(g, now))
			end
		end
		if next(active) == nil and stepConnection then
			stepConnection:Disconnect()
			stepConnection = nil
		end
	end

	local function activate(g: Glyph)
		g.settled = false
		active[g] = true
		if stepConnection == nil then
			stepConnection = RunService.RenderStepped:Connect(tick)
		end
		applyPose(g, poseOf(g, os.clock()))
	end

	local function newGlyph(
		slot: Slot,
		char: string,
		role: "arrive" | "depart",
		onset: number,
		rise: number,
		moves: boolean
	): Glyph
		local scaleInstance = slot.inner:New("UIScale")({}) :: UIScale
		local kids: { any } = { scaleInstance }
		local ghost: any = nil
		if useBlur then
			ghost = slot.inner:New("UIShadow")({
				Name = "Ghost",
				Mode = "Text",
				Color = color,
				Transparency = 1,
				BlurRadius = UDim.new(0, 0),
				Offset = UDim2.fromOffset(0, 0),
			})
			table.insert(kids, ghost)
		end
		local label = slot.inner:New("TextLabel")({
			Name = "Glyph",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			FontFace = font,
			TextSize = textSize,
			TextColor3 = color,
			Text = char,
			Parent = slot.cell,
			[Children] = kids,
		}) :: TextLabel
		return {
			label = label,
			scale = scaleInstance,
			ghost = ghost,
			role = role,
			onset = onset,
			rise = rise,
			moves = moves,
			carry = 1,
			settled = false,
			slot = slot,
		}
	end

	local function makeNumericDigit(
		index: number,
		char: string,
		appear: boolean,
		now: number,
		rise: number
	): Slot
		local inner, dead = innerScope()
		local cell = inner:New("Frame")({
			Name = `Digit{index}`,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(digitWidth, lineHeight),
			LayoutOrder = -index,
			Parent = cells,
		}) :: Frame
		local slot: Slot = {
			kind = "digit",
			char = char,
			root = container,
			inner = inner,
			dead = dead,
			position = 0,
			cell = cell,
		}
		local glyph = newGlyph(slot, char, "arrive", now, rise, false)
		slot.glyph = glyph
		if appear then
			-- A digit being added grows in place from small and blurred.
			activate(glyph)
		else
			glyph.settled = true
			applyPose(glyph, 0, 1, 1, 0)
		end
		return slot
	end

	--- The glyph at rest / arriving departs and a new one arrives, both starting at `onset`
	--- (later columns of a cascade start later). An interrupted glyph keeps the opacity it had.
	local function changeDigit(slot: Slot, char: string, onset: number, rise: number)
		local old = slot.glyph
		if old then
			local _, _, currentAlpha = poseOf(old, os.clock())
			old.carry = currentAlpha
			old.role = "depart"
			old.onset = onset
			old.rise = rise
			old.moves = true
			activate(old)
		end
		local glyph = newGlyph(slot, char, "arrive", onset, rise, true)
		slot.glyph = glyph
		slot.char = char
		activate(glyph)
	end

	--- A digit that is no longer there shrinks and blurs away in place, then goes.
	local function retireDigit(slot: Slot, now: number)
		local old = slot.glyph
		if old then
			local _, _, currentAlpha = poseOf(old, now)
			old.carry = currentAlpha
			old.role = "depart"
			old.onset = now
			old.moves = false
			activate(old)
		end
	end

	-- Roll: the odometer wheel, through every digit in between
	local function makeRollDigit(index: number, digit: number, rollIn: boolean): Slot
		local inner, dead = innerScope()
		local target = inner:Value(if rollIn then digit - 1 else digit)
		-- Underdamped: a touch of overshoot.
		local position = inner:Spring(
			target,
			props.SpringSpeed or SPRING_SPEED,
			props.SpringDamping or SPRING_DAMPING
		)

		local whole = inner:Computed(function(use)
			return math.floor(use(position) :: number)
		end)
		local fraction = inner:Computed(function(use)
			local p = use(position) :: number
			return p - math.floor(p)
		end)

		local function wheelLabel(name: string, step: number)
			local progress = inner:Computed(function(use)
				local f = use(fraction) :: number
				return if step == 0 then f else 1 - f
			end)
			-- Scale around the glyph's centre: digits shrink as they leave and grow as they
			-- arrive. Smoothstep so it eases rather than tracking the roll linearly.
			local scaleIn = inner:New("UIScale")({
				Scale = inner:Computed(function(use)
					local t = math.clamp(use(progress) :: number, 0, 1)
					return 1 - ROLL_SCALE * t * t * (3 - 2 * t)
				end),
			})
			local labelKids: { any } = { scaleIn }
			if useBlur then
				table.insert(labelKids, motionBlur(inner, progress))
			end
			return inner:New("TextLabel")({
				Name = name,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				FontFace = font,
				TextSize = textSize,
				TextColor3 = color,
				Text = inner:Computed(function(use)
					return tostring((use(whole) :: number + step) % 10)
				end),
				-- Current digit slides up and out, the next slides up from below.
				Position = inner:Computed(function(use)
					return UDim2.new(0.5, 0, 0.5, (step - (use(fraction) :: number)) * lineHeight)
				end),
				TextTransparency = inner:Computed(function(use)
					local p = use(progress) :: number
					return if useBlur then glyphTransparency(p) else math.clamp(p * 1.15, 0, 1)
				end),
				[Children] = labelKids,
			})
		end

		digitFrame(inner, index, { wheelLabel("Current", 0), wheelLabel("Next", 1) })

		if rollIn then
			task.defer(function()
				if not dead.value then
					target:set(digit)
				end
			end)
		end
		return {
			kind = "digit",
			char = tostring(digit),
			root = container,
			inner = inner,
			dead = dead,
			target = target,
			position = digit,
		}
	end

	local last: number? = nil
	local lastLength = 0
	-- Digits that are leaving, by column index, so a column that returns replaces them.
	local exiting: { [number]: Slot } = {}

	local function renderRoll(text: string, increasing: boolean, initial: boolean)
		local n = #text
		for index = 1, n do
			local char = string.sub(text, n - index + 1, n - index + 1)
			local isDigit = string.match(char, "^%d$") ~= nil
			local slot = slots[index]

			if slot and slot.kind == "digit" and isDigit then
				local digit = tonumber(char) :: number
				local current = slot.position % 10
				if current ~= digit then
					local delta = if increasing
						then (digit - current) % 10
						else -((current - digit) % 10)
					slot.position += delta
					local target = slot.target :: any
					target:set(slot.position)
				end
				slot.char = char
			elseif slot and slot.kind == "text" and not isDigit and slot.char == char then
				continue -- unchanged separator
			else
				if slot then
					destroySlot(slot)
				end
				slots[index] = if isDigit
					then makeRollDigit(index, tonumber(char) :: number, not initial)
					else makeText(index, char)
			end
		end
		-- Value got shorter: drop the extra leading columns.
		for index = n + 1, #slots do
			local slot = slots[index]
			if slot then
				destroySlot(slot)
				slots[index] = nil
			end
		end
	end

	local function renderNumeric(
		text: string,
		increasing: boolean,
		initial: boolean,
		structural: boolean
	)
		local n = #text
		local now = os.clock()
		local rise = if increasing then -1 else 1
		local changing: { number } = {}
		local nextChar: { [number]: string } = {}

		for index = 1, n do
			local char = string.sub(text, n - index + 1, n - index + 1)
			local isDigit = string.match(char, "^%d$") ~= nil
			local slot = slots[index]

			if slot and slot.kind == "digit" and isDigit then
				if slot.char ~= char then
					nextChar[index] = char
					table.insert(changing, index)
				end
			elseif slot and slot.kind == "text" and not isDigit and slot.char == char then
				continue -- unchanged separator
			else
				-- New column, or a column that changed kind (digit <-> separator).
				if slot then
					destroySlot(slot)
				end
				local leaving = exiting[index]
				if leaving then
					destroySlot(leaving)
					exiting[index] = nil
				end
				slots[index] = if isDigit
					then makeNumericDigit(index, char, not initial, now, rise)
					else makeText(index, char)
			end
		end

		-- Value got shorter: those digits shrink and blur away where they stand.
		for index = n + 1, #slots do
			local slot = slots[index]
			if slot then
				slots[index] = nil
				if slot.kind == "digit" then
					retireDigit(slot, now)
					exiting[index] = slot
					task.delay(LIFETIME / timeScale + 0.1, function()
						if exiting[index] == slot then
							exiting[index] = nil
						end
						destroySlot(slot)
					end)
				else
					destroySlot(slot)
				end
			end
		end

		-- Changing columns cascade left to right; a change in digit count commits together.
		table.sort(changing, function(a, b)
			return a > b -- larger index = further left
		end)
		local count = #changing
		for rank, index in changing do
			local delay = if structural or count <= 1
				then 0
				else CASCADE / timeScale * (rank - 1) / (count - 1)
			changeDigit(slots[index], nextChar[index], now + delay, rise)
		end
	end

	local function render(value: number)
		local increasing = last == nil or value >= last
		local initial = last == nil
		last = value

		local text = format(props, value)
		if style == "Roll" then
			renderRoll(text, increasing, initial)
		else
			renderNumeric(text, increasing, initial, not initial and #text ~= lastLength)
		end
		lastLength = #text
	end

	local source: any = props.Value
	if typeof(source) == "table" then
		render(peek(source) :: number)
		table.insert(
			scope,
			scope:Observer(source):onChange(function()
				render(peek(source) :: number)
			end)
		)
	else
		render(source :: number)
	end

	return container
end
