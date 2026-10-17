--!strict
--[[
	Feeds a Hotbar from the player's Roblox Backpack. See docs/Game/Backpack.md.
]]
local Players = game:GetService("Players")

local Backpack = {}

export type Options = {
	Player: Player?,
	Capacity: number?,
}

function Backpack.new(scope: any, options: Options?)
	local opts: Options = options or {}
	local player = opts.Player or Players.LocalPlayer
	local capacity = opts.Capacity or 30

	local items = scope:Value({} :: { [number]: any })
	local selected = scope:Value(nil :: number?)
	local toolAt: { [number]: Tool } = {}
	local slotOf: { [Tool]: number } = {}
	local watching: { [Tool]: { RBXScriptConnection } } = {}
	local backpack: Instance? = nil

	local function describe(tool: Tool)
		return {
			Id = tool.Name,
			Name = tool.Name,
			Description = if tool.ToolTip ~= "" then tool.ToolTip else nil,
			Image = if tool.TextureId ~= "" then tool.TextureId else nil,
			Tool = tool,
		}
	end

	local function publish()
		local list: { [number]: any } = {}
		for slot, tool in toolAt do
			list[slot] = describe(tool)
		end
		items:set(list)
	end

	local function equipped(): Tool?
		local character = player.Character
		return if character then character:FindFirstChildOfClass("Tool") else nil
	end

	local function syncSelected()
		local tool = equipped()
		selected:set(if tool then slotOf[tool] else nil)
	end

	local function add(tool: Tool)
		if slotOf[tool] then
			return
		end
		for slot = 1, capacity do
			if not toolAt[slot] then
				toolAt[slot] = tool
				slotOf[tool] = slot
				break
			end
		end
		local connections = {}
		for _, property in { "Name", "ToolTip", "TextureId" } do
			table.insert(connections, tool:GetPropertyChangedSignal(property):Connect(publish))
		end
		watching[tool] = connections
		publish()
		syncSelected()
	end

	local function remove(tool: Tool)
		local slot = slotOf[tool]
		if slot == nil then
			return
		end
		toolAt[slot] = nil
		slotOf[tool] = nil
		local connections: { RBXScriptConnection } = watching[tool] or {}
		for _, connection in connections do
			connection:Disconnect()
		end
		watching[tool] = nil
		publish()
		syncSelected()
	end

	--- A Tool moves between the Backpack and the character when equipped or unequipped. Only
	--- forget it once it is in neither.
	local function watch(container: Instance)
		for _, child in container:GetChildren() do
			if child:IsA("Tool") then
				add(child)
			end
		end
		table.insert(
			scope,
			container.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					add(child)
					syncSelected()
				end
			end)
		)
		table.insert(
			scope,
			container.ChildRemoved:Connect(function(child)
				if not child:IsA("Tool") then
					return
				end
				task.defer(function()
					local character = player.Character
					if
						child.Parent ~= backpack and (character == nil or child.Parent ~= character)
					then
						remove(child :: Tool)
					end
					syncSelected()
				end)
			end)
		)
	end

	task.spawn(function()
		backpack = player:WaitForChild("Backpack")
		watch(backpack :: Instance)
	end)
	if player.Character then
		watch(player.Character)
	end
	table.insert(
		scope,
		player.CharacterAdded:Connect(function(character)
			watch(character)
		end)
	)
	table.insert(scope, function()
		for _, connections in watching do
			for _, connection in connections do
				connection:Disconnect()
			end
		end
	end)

	local function onSelect(slot: number?)
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid == nil then
			return
		end
		local tool = if slot then toolAt[slot] else nil
		if tool then
			humanoid:EquipTool(tool)
		else
			humanoid:UnequipTools()
		end
	end

	local function onMove(from: number, to: number)
		local a, b = toolAt[from], toolAt[to]
		toolAt[from], toolAt[to] = b, a
		if a then
			slotOf[a] = to
		end
		if b then
			slotOf[b] = from
		end
		publish()
		syncSelected()
	end

	return {
		Items = items,
		Selected = selected,
		OnSelect = onSelect,
		OnMove = onMove,
	}
end

return Backpack
