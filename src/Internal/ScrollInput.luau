--!strict
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ACTION = "EstuaryUI_ScrollWheel"
local WHEEL_LINE = 128

export type Registration = {
	root: GuiObject,
	horizontal: boolean,
	scrollBy: (delta: number) -> (),
}

local registrations: { Registration } = {}
local wheelBound = false
local sinkBound = false
local lastHandled: InputObject? = nil

local function findPluginGui(from: Instance?): PluginGui?
	local cur: Instance? = from
	while cur do
		if cur:IsA("PluginGui") then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

local function findLayerCollector(from: Instance?): Instance?
	local cur: Instance? = from
	while cur do
		if cur:IsA("LayerCollector") then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

local function instanceDepth(inst: Instance): number
	local d = 0
	local cur: Instance? = inst
	while cur do
		d += 1
		cur = cur.Parent
	end
	return d
end

local function contains(gui: GuiObject, pt: Vector2): boolean
	local pos = gui.AbsolutePosition
	local sz = gui.AbsoluteSize
	if sz.X <= 0 or sz.Y <= 0 then
		return false
	end
	return pt.X >= pos.X and pt.X <= pos.X + sz.X and pt.Y >= pos.Y and pt.Y <= pos.Y + sz.Y
end

local function isGameHost(root: GuiObject): boolean
	return findPluginGui(root) == nil
end

local function anyGameRegistration(): boolean
	for _, reg in registrations do
		if reg.root.Parent and isGameHost(reg.root) then
			return true
		end
	end
	return false
end

local function pointerFromInput(input: InputObject): Vector2?
	if input.Position.X ~= 0 or input.Position.Y ~= 0 then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return nil
end

local function gamePointer(input: InputObject): Vector2
	local fromInput = pointerFromInput(input)
	if fromInput then
		return fromInput
	end
	local loc = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	return Vector2.new(loc.X, loc.Y - inset.Y)
end

local function pickDeepest(predicate: (Registration) -> boolean): Registration?
	local best: Registration? = nil
	local bestDepth = -1
	local bestZ = -math.huge
	for _, reg in registrations do
		local root = reg.root
		if root.Parent == nil or not root.Visible then
			continue
		end
		if not predicate(reg) then
			continue
		end
		local depth = instanceDepth(root)
		local z = root.ZIndex
		if depth > bestDepth or (depth == bestDepth and z > bestZ) then
			bestDepth = depth
			bestZ = z
			best = reg
		end
	end
	return best
end

local function pickTarget(pt: Vector2, hint: GuiObject?): Registration?
	return pickDeepest(function(reg)
		local root = reg.root
		if hint then
			if findPluginGui(root) ~= findPluginGui(hint) then
				return false
			end
		elseif not isGameHost(root) then
			return false
		end
		return contains(root, pt)
	end)
end

local function wheelDelta(input: InputObject): number
	return -input.Position.Z * WHEEL_LINE
end

local function handleWheel(input: InputObject, hint: GuiObject?): boolean
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return false
	end
	if lastHandled == input then
		return true
	end

	local target: Registration? = nil
	if hint then
		target = pickDeepest(function(reg)
			local root = reg.root
			return hint == root or hint:IsDescendantOf(root)
		end)
		if not target then
			local pt = pointerFromInput(input)
			if pt then
				target = pickTarget(pt, hint)
			end
		end
	else
		target = pickTarget(gamePointer(input), nil)
	end
	if not target then
		return false
	end

	lastHandled = input
	target.scrollBy(wheelDelta(input))
	return true
end

local function onWheelSink(
	_actionName: string,
	state: Enum.UserInputState,
	input: InputObject
): Enum.ContextActionResult
	if state ~= Enum.UserInputState.Change then
		return Enum.ContextActionResult.Pass
	end
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return Enum.ContextActionResult.Pass
	end
	if not anyGameRegistration() then
		return Enum.ContextActionResult.Pass
	end
	if pickTarget(gamePointer(input), nil) then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function ensureWheelBound()
	if wheelBound then
		return
	end
	wheelBound = true
	UserInputService.InputChanged:Connect(function(input)
		if not anyGameRegistration() then
			return
		end
		handleWheel(input, nil)
	end)
	RunService.PostSimulation:Connect(function()
		lastHandled = nil
	end)
end

local function ensureSinkBound()
	if sinkBound or not anyGameRegistration() then
		return
	end
	sinkBound = true
	ContextActionService:BindActionAtPriority(
		ACTION,
		onWheelSink,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.UserInputType.MouseWheel
	)
end

local function unbindSinkIfIdle()
	if anyGameRegistration() then
		return
	end
	if sinkBound then
		ContextActionService:UnbindAction(ACTION)
		sinkBound = false
	end
end

local function hookGuiWheel(gui: GuiObject, bucket: { RBXScriptConnection })
	table.insert(
		bucket,
		gui.InputChanged:Connect(function(input)
			handleWheel(input, gui)
		end)
	)
end

local ScrollInput = {}

function ScrollInput.findPluginGui(from: Instance?): PluginGui?
	return findPluginGui(from)
end

function ScrollInput.mouseLocation(): Vector2
	return UserInputService:GetMouseLocation()
end

--- Follow pointer after a press. Overlay lives on the LayerCollector so plugin
--- widgets receive move/end without PluginGui.InputChanged (RobloxScript).
--- `onMove` gets a position in the same space as GuiObject.AbsolutePosition.
function ScrollInput.capture(
	from: GuiObject,
	isMove: (InputObject) -> boolean,
	isEnd: (InputObject) -> boolean,
	onMove: (Vector3) -> (),
	onEnd: (InputObject) -> ()
): () -> ()
	local connections: { RBXScriptConnection } = {}
	local cover: TextButton? = nil
	local finished = false

	local function stop()
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
		if cover then
			cover:Destroy()
			cover = nil
		end
	end

	local function finish(input: InputObject)
		if finished then
			return
		end
		finished = true
		onEnd(input)
		stop()
	end

	local function bindChanged(host: GuiObject)
		table.insert(
			connections,
			host.InputChanged:Connect(function(input: InputObject)
				if isMove(input) then
					onMove(input.Position)
				end
			end)
		)
		table.insert(
			connections,
			host.InputEnded:Connect(function(input: InputObject)
				if not isEnd(input) then
					return
				end
				finish(input)
			end)
		)
	end

	local function bindEnded(source: Instance)
		if not source:IsA("GuiObject") and not source:IsA("UserInputService") then
			return
		end
		table.insert(
			connections,
			source.InputEnded:Connect(function(input: InputObject)
				if not isEnd(input) then
					return
				end
				finish(input)
			end)
		)
	end

	local collector = findLayerCollector(from)
	if collector then
		local overlay = Instance.new("TextButton")
		overlay.Name = "EstuaryPointerCapture"
		overlay.Text = ""
		overlay.AutoButtonColor = false
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.Selectable = false
		overlay.Active = true
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.Position = UDim2.fromScale(0, 0)
		overlay.ZIndex = 2147483647
		overlay.Parent = collector
		cover = overlay
		bindChanged(overlay)
		bindEnded(UserInputService)
		-- Plugin widgets often skip UIS MouseMovement; MouseMoved is widget-local.
		table.insert(
			connections,
			overlay.MouseMoved:Connect(function(x, y)
				onMove(Vector3.new(x, y, 0))
			end)
		)
	else
		bindChanged(UserInputService)
	end
	bindChanged(from)

	return stop
end

function ScrollInput.register(reg: Registration): () -> ()
	table.insert(registrations, reg)

	local wheelConns: { RBXScriptConnection } = {}
	hookGuiWheel(reg.root, wheelConns)
	for _, inst in reg.root:GetDescendants() do
		if inst:IsA("GuiObject") then
			hookGuiWheel(inst, wheelConns)
		end
	end
	table.insert(
		wheelConns,
		reg.root.DescendantAdded:Connect(function(inst)
			if inst:IsA("GuiObject") then
				hookGuiWheel(inst, wheelConns)
			end
		end)
	)

	local function syncHost()
		if isGameHost(reg.root) and reg.root.Parent then
			ensureWheelBound()
			ensureSinkBound()
		else
			unbindSinkIfIdle()
		end
	end
	syncHost()
	local ancestry = reg.root.AncestryChanged:Connect(syncHost)

	return function()
		ancestry:Disconnect()
		for _, conn in wheelConns do
			conn:Disconnect()
		end
		local i = table.find(registrations, reg)
		if i then
			table.remove(registrations, i)
		end
		unbindSinkIfIdle()
	end
end

function ScrollInput.handleWheel(input: InputObject, hint: GuiObject?): boolean
	return handleWheel(input, hint)
end

return ScrollInput
