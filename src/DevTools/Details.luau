--!strict
--[[
	The right-hand pane of the dev tools: the selected instance, its path, and editable properties.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Properties = require(script.Parent.Properties)

local Children = Fusion.Children
local peek = Fusion.peek

local Details = {}

type Env = {
	theme: any,
	C: any,
	select: (instance: Instance?) -> (),
}

local function describe(value: any): string
	local kind = typeof(value)
	if kind == "UDim2" then
		return string.format(
			"{%.3g, %d}, {%.3g, %d}",
			value.X.Scale,
			value.X.Offset,
			value.Y.Scale,
			value.Y.Offset
		)
	elseif kind == "UDim" then
		return string.format("%.3g, %d", value.Scale, value.Offset)
	elseif kind == "Vector2" then
		return string.format("%.1f, %.1f", value.X, value.Y)
	elseif kind == "Color3" then
		return "#" .. value:ToHex()
	elseif kind == "number" then
		return string.format("%.4g", value)
	elseif kind == "EnumItem" then
		return value.Name
	end
	return tostring(value)
end

local function stepFor(name: string, value: number): (number, number?, number?)
	if string.find(name, "Transparency") then
		return 0.05, 0, 1
	elseif name == "Rotation" then
		return 1, nil, nil
	elseif math.abs(value - math.floor(value)) < 1e-9 then
		return 1, nil, nil
	end
	return 0.1, nil, nil
end

--- A row of number fields that edit the parts of a value (a UDim2 is four numbers).
local function numberParts(
	sc: any,
	env: Env,
	labels: { string },
	values: { number },
	apply: ({ number }) -> ()
): Instance
	local current = table.clone(values)
	local fields: { any } = {
		sc:New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}
	for index, label in labels do
		table.insert(
			fields,
			env.C.NumberField(sc, {
				Theme = env.theme,
				Label = label,
				Value = current[index],
				Step = if string.sub(label, 1, 1) == "S" then 0.05 else 1,
				LayoutOrder = index,
				Size = UDim2.new(1 / #labels, -4, 0, 26),
				OnChanged = function(n: number)
					current[index] = n
					apply(current)
				end,
			})
		)
	end
	return sc:New("Frame")({
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		[Children] = fields :: any,
	})
end

--- The control that edits one property, or text when it can't be edited.
local function editor(
	sc: any,
	env: Env,
	target: Instance,
	spec: Properties.Spec,
	value: any
): Instance
	local C, theme = env.C, env.theme
	local name = spec.name
	local function write(newValue: any)
		pcall(function()
			(target :: any)[name] = newValue
		end)
	end
	local state = sc:Value(value)
	table.insert(
		sc,
		target:GetPropertyChangedSignal(name):Connect(function()
			local ok, now = pcall(function()
				return (target :: any)[name]
			end)
			if ok then
				state:set(now)
			end
		end)
	)

	local kind = typeof(value)
	if not spec.readOnly then
		if kind == "boolean" then
			return C.Switch(sc, { Theme = theme, Checked = state, OnChanged = write })
		elseif kind == "number" then
			local step, low, high = stepFor(name, value)
			return C.NumberField(sc, {
				Theme = theme,
				Value = state,
				Step = step,
				Min = low,
				Max = high,
				Size = UDim2.new(1, 0, 0, 26),
				OnChanged = write,
			})
		elseif kind == "string" then
			return C.TextField(sc, {
				Theme = theme,
				Compact = true,
				Text = state,
				OnSubmit = function(text: string)
					write(text)
				end,
			})
		elseif kind == "Color3" then
			return C.TextField(sc, {
				Theme = theme,
				Compact = true,
				Prefix = "#",
				Text = sc:Computed(function(use)
					return (use(state) :: Color3):ToHex()
				end),
				OnSubmit = function(text: string)
					local ok, color = pcall(Color3.fromHex, text)
					if ok then
						write(color)
					end
				end,
			})
		elseif kind == "EnumItem" then
			-- Pressing the button goes to the next item of the enum.
			return C.Button(sc, {
				Theme = theme,
				Variant = "Tonal",
				Text = sc:Computed(function(use)
					return (use(state) :: EnumItem).Name
				end),
				OnClick = function()
					local items = (value :: EnumItem).EnumType:GetEnumItems()
					local current = peek(state) :: EnumItem
					for index, item in items do
						if item == current then
							write(items[index % #items + 1])
							return
						end
					end
				end,
			})
		elseif kind == "UDim2" then
			local udim2 = value :: UDim2
			return numberParts(
				sc,
				env,
				{ "SX", "OX", "SY", "OY" },
				{ udim2.X.Scale, udim2.X.Offset, udim2.Y.Scale, udim2.Y.Offset },
				function(n: { number })
					write(UDim2.new(n[1], n[2], n[3], n[4]))
				end
			)
		elseif kind == "UDim" then
			local udim = value :: UDim
			return numberParts(
				sc,
				env,
				{ "S", "O" },
				{ udim.Scale, udim.Offset },
				function(n: { number })
					write(UDim.new(n[1], n[2]))
				end
			)
		elseif kind == "Vector2" then
			local vector = value :: Vector2
			return numberParts(
				sc,
				env,
				{ "X", "Y" },
				{ vector.X, vector.Y },
				function(n: { number })
					write(Vector2.new(n[1], n[2]))
				end
			)
		end
	end
	return sc:New("TextLabel")({
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = theme.Fonts.Mono,
		TextSize = 12,
		TextColor3 = theme.Colors.OnSurfaceVariant,
		Text = sc:Computed(function(use)
			return describe(use(state))
		end),
	})
end

--- Build the pane for `target`. It lives in scope `sc`, so everything it connects goes with it.
function Details.build(sc: any, env: Env, target: Instance): Instance
	local C, theme = env.C, env.theme
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local kids: { any } = {
		sc:New("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		sc:New("UIPadding")({
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
	}

	local function section(title: string)
		table.insert(
			kids,
			C.Text(sc, {
				Theme = theme,
				Text = title,
				Variant = "Label",
				Color = theme.Colors.Primary,
				LayoutOrder = nextOrder(),
			})
		)
	end

	-- Header: the class, and the name, which can be edited.
	table.insert(
		kids,
		C.Text(sc, {
			Theme = theme,
			Text = target.ClassName,
			Variant = "Title",
			LayoutOrder = nextOrder(),
		})
	)
	table.insert(
		kids,
		C.TextField(sc, {
			Theme = theme,
			Compact = true,
			Label = "Name",
			Text = target.Name,
			LayoutOrder = nextOrder(),
			OnSubmit = function(text: string)
				if text ~= "" then
					pcall(function()
						target.Name = text
					end)
				end
			end,
		})
	)

	-- The path: press an ancestor to select it.
	local crumbs: { any } = {
		sc:New("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
	}
	local chain: { Instance } = {}
	local at: Instance? = target.Parent
	while at and at ~= game do
		table.insert(chain, 1, at)
		at = at.Parent
	end
	for index, ancestor in chain do
		table.insert(
			crumbs,
			C.Button(sc, {
				Theme = theme,
				Text = ancestor.Name .. " ›",
				Variant = "Text",
				LayoutOrder = index,
				Size = UDim2.fromOffset(0, 24),
				OnClick = function()
					env.select(ancestor)
				end,
			})
		)
	end
	table.insert(
		kids,
		sc:New("Frame")({
			Name = "Path",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder(),
			[Children] = crumbs :: any,
		})
	)

	-- Properties.
	local specs = Properties.specsFor(target)
	if #specs > 0 then
		section("Properties")
	end
	for _, spec in specs do
		local ok, value = pcall(function()
			return (target :: any)[spec.name]
		end)
		if ok then
			table.insert(
				kids,
				sc:New("Frame")({
					Name = spec.name,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = nextOrder(),
					[Children] = {
						sc:New("UIListLayout")({
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 8),
						}),
						sc:New("TextLabel")({
							BackgroundTransparency = 1,
							Size = UDim2.new(0.34, 0, 0, 26),
							LayoutOrder = 1,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd,
							FontFace = theme.Typography.Label.Font,
							TextSize = 12,
							TextColor3 = theme.Colors.OnSurfaceVariant,
							Text = spec.name,
						}),
						sc:New("Frame")({
							BackgroundTransparency = 1,
							Size = UDim2.new(0.66, -8, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 2,
							[Children] = editor(sc, env, target, spec, value),
						}),
					} :: any,
				})
			)
		end
	end

	-- Attributes.
	local attributes = target:GetAttributes()
	if next(attributes) ~= nil then
		section("Attributes")
		local names: { string } = {}
		for key in attributes do
			table.insert(names, key)
		end
		table.sort(names)
		for _, key in names do
			table.insert(
				kids,
				C.Text(sc, {
					Theme = theme,
					Text = `{key} = {describe(attributes[key])}`,
					Variant = "Mono",
					LayoutOrder = nextOrder(),
				})
			)
		end
	end

	-- Children: press one to select it.
	local count = #target:GetChildren()
	if count > 0 then
		section(`Children ({count})`)
		for index, child in target:GetChildren() do
			if index > 40 then
				table.insert(
					kids,
					C.Text(sc, {
						Theme = theme,
						Text = `… and {count - 40} more`,
						Variant = "Label",
						LayoutOrder = nextOrder(),
					})
				)
				break
			end
			table.insert(
				kids,
				C.Button(sc, {
					Theme = theme,
					Text = `{child.Name}  ({child.ClassName})`,
					Variant = "Text",
					LayoutOrder = nextOrder(),
					Size = UDim2.new(1, 0, 0, 24),
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					OnClick = function()
						env.select(child)
					end,
				})
			)
		end
	end

	return sc:New("Frame")({
		Name = "Details",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = kids :: any,
	})
end

return Details
