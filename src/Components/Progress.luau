--!strict
--[[
	Linear / circular progress.
	Indeterminate linear: ping-pong bounce with mid-travel stretch.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme

local Children = Fusion.Children
local peek = Fusion.peek
local RunService = game:GetService("RunService")

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

local function smooth(t: number): number
	t = clamp01(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

--[[
	Bounce left↔right. Returns (leftScale, widthScale).
	Stretches in the middle of each pass, compresses at the ends.
]]
local function bounceIndicator(phase: number): (number, number)
	-- phase 0..1 = full round trip (out and back)
	local cycle = phase * 2 -- 0..2
	local goingRight = cycle % 2 < 1
	local u = cycle % 1
	local t = if goingRight then u else 1 - u
	local eased = smooth(t)

	local breath = math.sin(eased * math.pi) -- 0 at ends, 1 mid
	local width = 0.18 + breath * 0.34
	local travel = 1 - width
	local left = eased * travel
	return left, width
end

return function(scope: Types.Scope, props: Types.ProgressProps): Frame
	local theme = resolveTheme(props)
	local variant: Types.ProgressVariant = props.Variant or "Linear"
	local mode: Types.ProgressMode = props.Mode
		or (if props.Value == nil then "Indeterminate" else "Determinate")
	local phase = scope:Value(0)

	if mode == "Indeterminate" or mode == "Buffering" then
		table.insert(
			scope,
			RunService.RenderStepped:Connect(function(dt)
				-- ~1.4s per full bounce round-trip
				phase:set((peek(phase) + dt / 2.4) % 1)
			end)
		)
	end

	if variant == "Circular" then
		local angle = scope:Value(0)
		table.insert(
			scope,
			RunService.RenderStepped:Connect(function(dt)
				angle:set((peek(angle) + dt * 270) % 360)
			end)
		)
		return scope:New("Frame")({
			Name = "ProgressCircular",
			BackgroundTransparency = 1,
			Size = props.Size or UDim2.fromOffset(40, 40),
			LayoutOrder = props.LayoutOrder or 0,
			[Children] = {
				scope:New("Frame")({
					Name = "Track",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					[Children] = {
						scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
						scope:New("UIStroke")({
							Color = theme.Colors.SurfaceContainerHigh,
							Thickness = 3,
						}),
					},
				}),
				scope:New("Frame")({
					Name = "Spinner",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Rotation = angle,
					[Children] = {
						scope:New("Frame")({
							BackgroundColor3 = theme.Colors.Primary,
							Size = UDim2.new(0, 3, 0.42, 0),
							AnchorPoint = Vector2.new(0.5, 0),
							Position = UDim2.new(0.5, 0, 0, 2),
							BorderSizePixel = 0,
							[Children] = {
								scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							},
						}),
					},
				}),
			},
		}) :: Frame
	end

	local kids: { any } = {
		scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
	}

	if mode == "Buffering" or mode == "Determinate" then
		local bufferW = scope:Computed(function(use)
			if mode ~= "Buffering" then
				return 0
			end
			local b = props.Buffer
			if b == nil then
				return 0.7
			end
			return math.clamp((if typeof(b) == "table" then use(b) else b) :: number, 0, 1)
		end)
		table.insert(
			kids,
			scope:New("Frame")({
				Name = "Buffer",
				BackgroundColor3 = theme.Colors.PrimaryContainer,
				Size = scope:Computed(function(use)
					return UDim2.new(use(bufferW), 0, 1, 0)
				end),
				BorderSizePixel = 0,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				},
			})
		)
	end

	if mode == "Indeterminate" then
		table.insert(
			kids,
			scope:New("Frame")({
				Name = "Indeterminate",
				BackgroundColor3 = theme.Colors.Primary,
				BorderSizePixel = 0,
				Position = scope:Computed(function(use)
					local left = bounceIndicator(use(phase))
					return UDim2.new(left, 0, 0, 0)
				end),
				Size = scope:Computed(function(use)
					local _, width = bounceIndicator(use(phase))
					return UDim2.new(width, 0, 1, 0)
				end),
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				},
			})
		)
	else
		local fill = scope:Computed(function(use)
			local v = props.Value
			if v == nil then
				return 0
			end
			return math.clamp((if typeof(v) == "table" then use(v) else v) :: number, 0, 1)
		end)
		table.insert(
			kids,
			scope:New("Frame")({
				Name = "Fill",
				BackgroundColor3 = theme.Colors.Primary,
				Size = scope:Computed(function(use)
					return UDim2.new(use(fill), 0, 1, 0)
				end),
				BorderSizePixel = 0,
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				},
			})
		)
	end

	return scope:New("Frame")({
		Name = "ProgressLinear",
		BackgroundColor3 = theme.Colors.SurfaceContainerHigh,
		Size = props.Size or UDim2.new(1, 0, 0, 4),
		LayoutOrder = props.LayoutOrder or 0,
		ClipsDescendants = true,
		[Children] = kids,
	}) :: Frame
end
