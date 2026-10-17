--!strict
--[[
	Pieces shared by ColorPicker and GradientPicker: checkerboard, slider track and thumb,
	channel row, number and hex fields. `color` is the State<Color3> the thumbs are filled with.
]]
local Packages = script.Parent.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Parent.Types)
local ColorSpaces = require(script.Parent.ColorSpaces)
local Drag = require(script.Parent.Drag)
local TextField = require(script.Parent.Parent.Parent.Components.TextField)

local Children = Fusion.Children
local peek = Fusion.peek

local TRACK_HEIGHT = 28
local THUMB_SIZE = TRACK_HEIGHT -- the thumb's size while held: it grows to meet the track
local THUMB_REST = 18

export type ChannelSpec = {
	label: string,
	min: number,
	max: number,
	decimals: number?,
	get: (use: any) -> number,
	set: (n: number) -> (),
	track: (use: any) -> ColorSequence,
	alphaTrack: boolean?,
	order: number,
}

local Widgets = {}

Widgets.TRACK_HEIGHT = TRACK_HEIGHT

function Widgets.new(theme: Types.Theme, color: any)
	--- Checkerboard under translucent colours. It is a CanvasGroup because only that clips to
	--- rounded corners; with ClipsDescendants the square cells would stick out past the rounded
	--- swatch or track.
	local function checker(
		sc: any,
		columns: number,
		rows: number,
		position: UDim2?,
		size: UDim2?,
		radius: UDim?
	): Frame
		local cells: { any } = {}
		for row = 0, rows - 1 do
			for column = 0, columns - 1 do
				if (row + column) % 2 == 0 then
					table.insert(
						cells,
						sc:New("Frame")({
							BackgroundColor3 = Color3.fromRGB(200, 200, 200),
							BorderSizePixel = 0,
							Position = UDim2.fromScale(column / columns, row / rows),
							Size = UDim2.fromScale(1 / columns, 1 / rows),
						})
					)
				end
			end
		end
		return sc:New("CanvasGroup")({
			Name = "Checker",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = position or UDim2.fromScale(0, 0),
			Size = size or UDim2.fromScale(1, 1),
			[Children] = {
				sc:New("UICorner")({ CornerRadius = radius or UDim.new(0, theme.Metrics.RadiusSm) }),
				cells,
			},
		}) :: Frame
	end

	--- Round thumb with a white ring, filled with the current colour. Smaller than the track at
	--- rest, grows to the track height while `held`.
	local function thumb(sc: any, position: any, held: any): Frame
		local grow = sc:Spring(
			sc:Computed(function(use)
				return if use(held) then 1 else 0
			end),
			32,
			0.7
		)
		return sc:New("Frame")({
			Name = "Thumb",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = sc:Computed(function(use)
				local px = THUMB_REST + (THUMB_SIZE - THUMB_REST) * use(grow)
				return UDim2.fromOffset(px, px)
			end),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 3,
			[Children] = {
				sc:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				sc:New("UIStroke")({
					Color = Color3.new(1, 1, 1),
					Thickness = 2.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			},
		}) :: Frame
	end

	--- Compact TextField for a number. Commits on blur or Enter, reverts if it isn't a number.
	local function numberBox(
		sc: any,
		get: (use: any) -> number,
		set: (n: number) -> (),
		min: number,
		max: number,
		decimals: number
	): Instance
		local function formatted(use: any): string
			return string.format(`%.{decimals}f`, get(use))
		end
		return TextField(sc, {
			Theme = theme,
			Compact = true,
			Text = sc:Computed(formatted),
			OnSubmit = function(text: string, box: TextBox)
				local n = tonumber(text)
				if n then
					set(math.clamp(n, min, max))
				end
				box.Text = formatted(peek)
			end,
		})
	end

	--- Draggable track and thumb. The caller sets the size.
	local function sliderTrack(sc: any, spec: ChannelSpec): Frame
		local span = spec.max - spec.min
		local fraction = sc:Computed(function(use)
			return math.clamp((spec.get(use) - spec.min) / span, 0, 1)
		end)

		-- The thumb moves along the track inset by its radius, so it stays inside the ends.
		local PAD = THUMB_SIZE / 2
		local trackPosition = UDim2.new(0, 0, 0.5, -TRACK_HEIGHT / 2)
		local trackSize = UDim2.new(1, 0, 0, TRACK_HEIGHT)

		local track = sc:New("Frame")({
			Name = "Track",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = trackPosition,
			Size = trackSize,
			ZIndex = 2,
			[Children] = {
				sc:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				sc:New("UIGradient")({
					Color = sc:Computed(spec.track),
					-- Alpha tracks run from clear to the full colour over the checkerboard.
					Transparency = if spec.alphaTrack then NumberSequence.new(1, 0) else nil,
				}),
			},
		}) :: Frame

		local held = sc:Value(false)
		local trackHolder = sc:New("Frame")({
			Name = "TrackHolder",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -(52 + 8), 1, 0),
			Active = true,
			[Children] = {
				if spec.alphaTrack
					then checker(sc, 30, 2, trackPosition, trackSize, UDim.new(1, 0))
					else nil,
				track,
				thumb(
					sc,
					sc:Computed(function(use)
						local along = use(fraction) :: number
						return UDim2.new(along, PAD - 2 * PAD * along, 0.5, 0)
					end)
				),
			},
		}) :: Frame

		Drag.bind(
			sc,
			trackHolder,
			function(x: number)
				local width = math.max(trackHolder.AbsoluteSize.X, 1)
				local along = math.clamp((x * width - PAD) / math.max(width - 2 * PAD, 1), 0, 1)
				spec.set(spec.min + along * span)
			end,
			nil,
			function(down: boolean)
				held:set(down)
			end
		)

		return trackHolder
	end

	--- Label above a slider row: track, thumb and number field.
	local function channel(sc: any, spec: ChannelSpec): Frame
		local trackHolder = sliderTrack(sc, spec)

		return sc:New("Frame")({
			Name = spec.label,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = spec.order,
			[Children] = {
				sc:New("UIListLayout")({
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				}),
				sc:New("TextLabel")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = theme.Typography.Label.Font,
					TextSize = 13,
					TextColor3 = theme.Colors.OnSurface,
					Text = spec.label,
					LayoutOrder = 1,
				}),
				sc:New("Frame")({
					Name = "Row",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, THUMB_SIZE + 2),
					LayoutOrder = 2,
					[Children] = {
						trackHolder,
						sc:New("Frame")({
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.fromScale(1, 0.5),
							Size = UDim2.fromOffset(52, TRACK_HEIGHT),
							[Children] = {
								numberBox(
									sc,
									spec.get,
									spec.set,
									spec.min,
									spec.max,
									spec.decimals or 0
								),
							},
						}),
					},
				}),
			},
		}) :: Frame
	end

	--- Compact TextField for a hex colour. Commits on blur or Enter.
	local function hexField(
		sc: any,
		getColor: (use: any) -> Color3,
		commit: (c: Color3) -> (),
		height: number?
	): Instance
		local function text(use: any): string
			local c = getColor(use)
			return string.sub(ColorSpaces.toHex(c.R, c.G, c.B), 2)
		end
		return TextField(sc, {
			Theme = theme,
			Compact = true,
			Height = height,
			Prefix = "#",
			Placeholder = "RRGGBB",
			Text = sc:Computed(text),
			OnSubmit = function(typed: string, box: TextBox)
				local parsed = ColorSpaces.parseHex(typed)
				if parsed then
					commit(Color3.new(parsed[1], parsed[2], parsed[3]))
				end
				box.Text = text(peek)
			end,
		})
	end

	return {
		TRACK_HEIGHT = TRACK_HEIGHT,
		checker = checker,
		thumb = thumb,
		numberBox = numberBox,
		sliderTrack = sliderTrack,
		channel = channel,
		hexField = hexField,
	}
end

return Widgets
