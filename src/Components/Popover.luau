--!strict
--[[
	Anchored popover — Overlay + positioned Menu (Embedded).
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local Layer = require(script.Parent.Parent.Internal.Layer)
local Overlay = require(script.Parent.Overlay)
local Menu = require(script.Parent.Menu)

local Children = Fusion.Children
local peek = Fusion.peek
local RunService = game:GetService("RunService")

return function(scope: Types.Scope, props: Types.PopoverProps): Instance
	local theme = resolveTheme(props)
	local openRef = props.Open
	local open = scope:Computed(function(use)
		if openRef == nil then
			return true
		end
		return (if typeof(openRef) == "table" then use(openRef) else openRef) == true
	end)
	local openS = scope:Spring(
		scope:Computed(function(use)
			return if use(open) then 1 else 0
		end),
		theme.Motion.SpringSpeed,
		theme.Motion.SpringDamping
	)

	local width = props.Width or 240
	local placement = props.Placement or "Bottom"
	local pos = scope:Value(UDim2.fromOffset(0, 0))

	local menu = Menu(scope, {
		Theme = theme,
		Embedded = true,
		Open = open,
		OnClose = props.OnClose,
		Items = props.Items,
		Sections = props.Sections,
		MaxHeight = props.MaxHeight,
		Children = props.Children,
		Size = UDim2.fromOffset(width, 0),
		Padding = 6,
		ZIndex = (props.ZIndex or 90) + 1,
	})

	scope:Hydrate(menu)({
		Name = "PopoverPanel",
		Position = pos,
	})

	local scale = Instance.new("UIScale")
	scale.Parent = menu
	table.insert(
		scope,
		scope:Observer(openS):onBind(function()
			local t = peek(openS)
			scale.Scale = 0.92 + 0.08 * t
		end)
	)

	local function updatePosition()
		local target = Layer.asGui(props.Target)
		local layer = Layer.resolve(props)
		if target == nil or layer == nil then
			return
		end
		local gap = 8
		local tp = target.AbsolutePosition
		local ts = target.AbsoluteSize
		local lp = layer.AbsolutePosition
		local x = tp.X - lp.X
		local y = tp.Y - lp.Y
		if placement == "Bottom" then
			x = x + ts.X * 0.5 - width * 0.5
			y = y + ts.Y + gap
		elseif placement == "Top" then
			x = x + ts.X * 0.5 - width * 0.5
			y = y - gap - 8
		elseif placement == "Right" then
			x = x + ts.X + gap
			y = y
		else
			x = x - width - gap
			y = y
		end
		pos:set(UDim2.fromOffset(math.max(8, x), math.max(8, y)))
	end

	table.insert(
		scope,
		RunService.RenderStepped:Connect(function()
			if peek(open) then
				updatePosition()
			end
		end)
	)

	local root = scope:Frame({
		Name = "Popover",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = scope:Computed(function(use)
			return use(openS) > 0.02
		end),
		ZIndex = props.ZIndex or 90,
		[Children] = {
			scope:Hydrate(Overlay(scope, {
				Theme = theme,
				OnClick = props.OnClose,
				ZIndex = props.ZIndex or 90,
			}))({
				BackgroundTransparency = scope:Computed(function(use)
					-- Light dismiss scrim
					return 1 - (use(openS) :: number) * 0.25
				end),
			}),
			menu,
		},
	}) :: Frame

	Layer.mount(scope, props, root)
	return root
end
