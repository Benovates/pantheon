--!strict
--[[
	Pantheon's replacement for Fusion's (soon deprecated) `Hydrate`.

		scope:Apply(instance)({ Text = state, [OnEvent "Activated"] = fn, [Children] = kids })

	Uses only Fusion's public surface: `Observer`, `peek`, state objects
	(`.type == "State"`) and the documented SpecialKey interface
	(`{ type = "SpecialKey", stage, apply(self, scope, value, target) }`).

	Behaviour matches Fusion 0.3 Hydrate: the target is added to `scope` (so it is
	destroyed with it), string keys are bound or assigned, special keys run in
	stage order self → descendants → Parent → ancestor → observer.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)

local peek = Fusion.peek

local STAGES = { "self", "descendants" }
local LATE_STAGES = { "ancestor", "observer" }

local function isState(v: any): boolean
	return typeof(v) == "table" and (v :: any).type == "State"
end

local function isSpecialKey(k: any): boolean
	return typeof(k) == "table" and (k :: any).type == "SpecialKey"
end

local function assign(target: Instance, property: string, value: any)
	local ok, err = pcall(function()
		(target :: any)[property] = value
	end)
	if not ok then
		warn(`[Pantheon] cannot set {target.ClassName}.{property} = {typeof(value)}: {err}`)
	end
end

local function bind(scope: any, target: Instance, property: string, value: any)
	if isState(value) then
		table.insert(
			scope,
			Fusion.Observer(scope, value):onBind(function()
				assign(target, property, peek(value))
			end)
		)
	else
		assign(target, property, value)
	end
end

local function applyProps(scope: any, target: Instance, props: { [any]: any }): Instance
	table.insert(scope, target)

	local byStage: { [string]: { { key: any, value: any } } } = {}
	for key, value in props do
		if type(key) == "string" then
			if key ~= "Parent" then
				bind(scope, target, key, value)
			end
		elseif isSpecialKey(key) then
			local stage = (key :: any).stage :: string
			local list = byStage[stage]
			if list == nil then
				list = {}
				byStage[stage] = list
			end
			table.insert(list, { key = key, value = value })
		else
			error(`[Pantheon] unrecognised property key of type {typeof(key)}`, 3)
		end
	end

	local function run(stage: string)
		local list = byStage[stage]
		if list then
			for _, entry in list do
				entry.key:apply(scope, entry.value, target)
			end
		end
	end

	for _, stage in STAGES do
		run(stage)
	end
	if props.Parent ~= nil then
		bind(scope, target, "Parent", props.Parent)
	end
	for _, stage in LATE_STAGES do
		run(stage)
	end
	return target
end

--- scope:Apply(instance)(props) → instance
local function Apply(scope: any, target: Instance): ({ [any]: any }) -> Instance
	assert(
		target,
		"scope:Apply(instance) requires an instance, did you call it with `.` instead of `:`?"
	)
	return function(props)
		return applyProps(scope, target, props)
	end
end

return Apply
