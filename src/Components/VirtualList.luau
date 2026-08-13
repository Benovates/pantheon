--!strict
--[[
	Windowed list. Uses ScrollArea chrome; rows mount via ForPairs and only
	rebuild when the visible index window changes.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local ScrollArea = require(script.Parent.ScrollArea)

local Children = Fusion.Children
local peek = Fusion.peek

local OVERSCAN = 6

local function mapsEqual(a: { [number]: number }, b: { [number]: number }): boolean
	for k in a do
		if b[k] == nil then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

return function(scope: Types.Scope, props: Types.VirtualListProps): Instance
	local theme = resolveTheme(props)
	local itemHeight = props.ItemHeight
	local gap = props.Padding or 0
	local stride = math.max(itemHeight + gap, 1)
	local scrollY = scope:Value(0)
	local viewport = scope:Value(240)
	local visibleMap = scope:Value({} :: { [number]: number })

	local function readCount(): number
		local c = props.ItemCount
		if typeof(c) == "table" then
			return (peek(c) :: number) or 0
		end
		return (c :: number) or 0
	end

	local function updateWindow()
		local count = readCount()
		local y = math.max(peek(scrollY), 0)
		local viewH = math.max(peek(viewport), 1)
		if count <= 0 then
			if next(peek(visibleMap)) ~= nil then
				visibleMap:set({})
			end
			return
		end
		local first = math.max(1, math.floor(y / stride) - OVERSCAN + 1)
		local last = math.min(count, math.ceil((y + viewH) / stride) + OVERSCAN)
		local keyed: { [number]: number } = {}
		for index = first, last do
			keyed[index] = index
		end
		if not mapsEqual(peek(visibleMap), keyed) then
			visibleMap:set(keyed)
		end
	end

	local canvasHeight = scope:Computed(function(use)
		local count = use(props.ItemCount) :: number
		return math.max(count * stride, 0)
	end)

	local rows = scope:ForPairs(visibleMap, function(_use, rowScope, index: number, _value: number)
		local row = props.RenderItem(rowScope, index)
		return index,
			rowScope:Hydrate(row)({
				Name = "VirtualRow_" .. tostring(index),
				Position = UDim2.fromOffset(0, (index - 1) * stride),
				Size = UDim2.new(1, 0, 0, itemHeight),
				ZIndex = 1,
			})
	end)

	-- Tall spacer establishes canvas; rows sit absolutely on top.
	local host = scope:New("Frame")({
		Name = "VirtualHost",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, use(canvasHeight))
		end),
		[Children] = rows,
	})

	local list = ScrollArea(scope, {
		Theme = theme,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		LayoutOrder = props.LayoutOrder or 0,
		AutoCanvas = false,
		ContentLayout = "None" :: "None",
		ContentPadding = 0,
		ScrollButtons = false,
		DragToScroll = false,
		CanvasSize = scope:Computed(function(use)
			return UDim2.fromOffset(0, use(canvasHeight))
		end),
		OnScroll = function(y)
			scrollY:set(y)
			updateWindow()
		end,
		Children = { host },
	}) :: GuiObject
	list.Name = "VirtualList"

	local function syncViewport()
		local h = list.AbsoluteSize.Y
		if h > 1 then
			viewport:set(h)
		end
		updateWindow()
	end

	table.insert(scope, list:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncViewport))
	if typeof(props.ItemCount) == "table" then
		table.insert(
			scope,
			scope:Observer(props.ItemCount :: any):onBind(function()
				updateWindow()
			end)
		)
	end

	updateWindow()
	task.defer(syncViewport)
	task.delay(0.05, syncViewport)

	return list
end
