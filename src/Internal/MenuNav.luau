--!strict
--[[
	Ancestor-walk navigation for composed MenuButton / MenuPage.
	Menu binds a navigator on the panel; buttons look it up on click.
]]

export type Navigator = {
	push: (id: string) -> (),
	pop: () -> (),
	page: () -> string?,
}

local registry: { [Instance]: Navigator } = {}

local MenuNav = {}

function MenuNav.bind(host: Instance, nav: Navigator)
	registry[host] = nav
	host.Destroying:Connect(function()
		registry[host] = nil
	end)
end

function MenuNav.from(inst: Instance): Navigator?
	local cur: Instance? = inst
	while cur do
		local nav = registry[cur]
		if nav then
			return nav
		end
		cur = cur.Parent
	end
	return nil
end

return MenuNav
