--!strict
--[[
	Opt-in state persistence across rebuilds.

	Components keep their user-visible state (the selected tab, a switch, a slider's value,
	a collapsed section…) in Fusion Values created in their own scope, so rebuilding the UI,
	to switch theme or layout, throws all of it away. Give the app a store and those Values
	live in the store's scope instead, so a rebuild picks them up again:

		local store = Pantheon.Persist.createStore(rootScope)

		local function rebuild()
			Pantheon.Persist.Provide(store, function()
				-- build the UI: every Switch, Tabs, Slider… reuses its state from last time
			end)
		end

	How a new component finds its old state: by `Id` if you give it one (`Id = "settings.sound"`),
	otherwise by kind and creation order within the pass (the 3rd Switch is "Switch#3"). A rebuild
	runs the same code in the same order, so that is stable, but conditional UI that changes
	the order should use explicit `Id`s.

	A control whose value you pass in as a state (`Checked = someValue`) is left alone: you
	already own that state.

	Without a store (the default) every call just creates a plain Value.
]]
local Types = require(script.Parent.Parent.Types)

type Store = {
	scope: Types.Scope,
	values: { [string]: any },
	counters: { [string]: number },
}

local current: Store? = nil

local Persist = {}

function Persist.createStore(scope: Types.Scope): Store
	return { scope = scope, values = {}, counters = {} }
end

--- Build with `store` active. Counters restart, so the Nth component of a kind maps to the
--- same state as last pass.
function Persist.Provide<T...>(store: Store, build: (T...) -> ...any, ...: T...): ...any
	local previous = current
	current = store
	store.counters = {}
	local results = table.pack(pcall(build, ...))
	current = previous
	if not results[1] then
		error(results[2], 0)
	end
	return table.unpack(results, 2, results.n)
end

--- A stable key for one component instance, or nil when there is no store or the control is
--- already controlled by a state the app owns.
function Persist.key(kind: string, id: string?, controlled: boolean?): string?
	local store = current
	if store == nil or controlled then
		return nil
	end
	if id then
		return `{kind}:{id}`
	end
	local n = (store.counters[kind] or 0) + 1
	store.counters[kind] = n
	return `{kind}#{n}`
end

--- The Value for one piece of a component's state: the stored one if there is one, else a new
--- one (kept in the store when there is a key). `initial` is only used the first time.
function Persist.value(scope: Types.Scope, key: string?, slot: string, initial: any): any
	local store = current
	if key == nil or store == nil then
		return scope:Value(initial)
	end
	local full = `{key}/{slot}`
	local existing = store.values[full]
	if existing == nil then
		existing = store.scope:Value(initial)
		store.values[full] = existing
	end
	return existing
end

return Persist
