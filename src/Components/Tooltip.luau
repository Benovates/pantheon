--!strict
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local CanvasFade = require(script.Parent.Parent.Internal.CanvasFade)
local Layer = require(script.Parent.Parent.Internal.Layer)

local Children = Fusion.Children
local peek = Fusion.peek
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local function place(
	placement: Types.TooltipPlacement,
	targetPos: Vector2,
	targetSize: Vector2,
	tipSize: Vector2,
	gap: number,
	viewport: Vector2
): (UDim2, Types.TooltipPlacement)
	local function forSide(side: Types.TooltipPlacement): (number, number, number)
		local x, y
		if side == "Bottom" then
			x = targetPos.X + targetSize.X * 0.5 - tipSize.X * 0.5
			y = targetPos.Y + targetSize.Y + gap
		elseif side == "Top" then
			x = targetPos.X + targetSize.X * 0.5 - tipSize.X * 0.5
			y = targetPos.Y - tipSize.Y - gap
		elseif side == "Left" then
			x = targetPos.X - tipSize.X - gap
			y = targetPos.Y + targetSize.Y * 0.5 - tipSize.Y * 0.5
		else -- Right
			x = targetPos.X + targetSize.X + gap
			y = targetPos.Y + targetSize.Y * 0.5 - tipSize.Y * 0.5
		end
		local overflow = 0
		if x < 8 then
			overflow += 8 - x
		end
		if y < 8 then
			overflow += 8 - y
		end
		if x + tipSize.X > viewport.X - 8 then
			overflow += (x + tipSize.X) - (viewport.X - 8)
		end
		if y + tipSize.Y > viewport.Y - 8 then
			overflow += (y + tipSize.Y) - (viewport.Y - 8)
		end
		return x, y, overflow
	end

	local chosen: Types.TooltipPlacement = if placement == "Auto" then "Bottom" else placement
	local bestX, bestY, bestOverflow = forSide(chosen)

	if placement == "Auto" then
		bestOverflow = math.huge
		local function trySide(side: Types.TooltipPlacement)
			local x, y, overflow = forSide(side)
			if overflow < bestOverflow then
				bestOverflow = overflow
				bestX, bestY = x, y
				chosen = side
			end
		end
		trySide("Bottom")
		trySide("Top")
		trySide("Right")
		trySide("Left")
	end

	bestX = math.clamp(bestX, 8, math.max(8, viewport.X - tipSize.X - 8))
	bestY = math.clamp(bestY, 8, math.max(8, viewport.Y - tipSize.Y - 8))
	return UDim2.fromOffset(bestX, bestY), chosen
end

return function(scope: Types.Scope, props: Types.TooltipProps): Instance
	local theme = resolveTheme(props)
	local visible = scope:Value(0)
	local visibleS = scope:Spring(visible, theme.Motion.SpringSpeed, theme.Motion.SpringDamping)
	local placement: Types.TooltipPlacement = props.Placement or "Auto"
	local gap = props.Gap or 8

	local tip = scope:New("Frame")({
		Name = "Tooltip",
		BackgroundColor3 = theme.Colors.SurfaceContainerHigh,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = CanvasFade.shown(scope, visibleS, nil, { Theme = theme }),
		BackgroundTransparency = CanvasFade.surfaceTransparency(scope, visibleS, { Theme = theme }),
		ZIndex = props.ZIndex or 120,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, theme.Metrics.RadiusSm) }),
			scope:New("UIPadding")({
				PaddingTop = UDim.new(0, theme.Metrics.SpaceXs),
				PaddingBottom = UDim.new(0, theme.Metrics.SpaceXs),
				PaddingLeft = UDim.new(0, theme.Metrics.SpaceSm),
				PaddingRight = UDim.new(0, theme.Metrics.SpaceSm),
			}),
			scope:New("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.Colors.Outline,
				Thickness = 1,
			}),
			scope:New("TextLabel")({
				BackgroundTransparency = 1,
				FontFace = theme.Typography.Label.Font,
				TextSize = theme.Typography.Label.Size,
				TextColor3 = theme.Colors.OnSurface,
				Text = props.Text,
				AutomaticSize = Enum.AutomaticSize.XY,
			}),
		},
	}) :: Frame

	local host = CanvasFade.host(scope, tip, visibleS, { Theme = theme })
	Layer.mount(scope, props, host)

	local function updatePosition()
		local target = Layer.asGui(props.Target)
		if target == nil then
			return
		end
		local inset = GuiService:GetGuiInset()
		local camera = workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
		local layer = Layer.resolve(props)
		local abs = target.AbsolutePosition
		local size = target.AbsoluteSize
		-- AbsolutePosition is inset-aware for ScreenGui; tip parent may be layer
		local origin = if layer then layer.AbsolutePosition else Vector2.new(0, 0)
		local pos, _ = place(
			placement,
			Vector2.new(abs.X, abs.Y),
			size,
			host.AbsoluteSize,
			gap,
			viewport - inset
		)
		if layer then
			host.Position = UDim2.fromOffset(pos.X.Offset - origin.X, pos.Y.Offset - origin.Y)
		else
			host.Position = pos
		end
	end

	local hoverTarget = Layer.asGui(props.Target)
	if hoverTarget then
		table.insert(
			scope,
			hoverTarget.MouseEnter:Connect(function()
				visible:set(1)
				task.defer(updatePosition)
			end)
		)
		table.insert(
			scope,
			hoverTarget.MouseLeave:Connect(function()
				visible:set(0)
			end)
		)
		table.insert(
			scope,
			RunService.RenderStepped:Connect(function()
				if peek(visible) > 0.5 then
					updatePosition()
				end
			end)
		)
	end

	return host
end
