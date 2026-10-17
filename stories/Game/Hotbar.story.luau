--!strict
local StoryUtil = require(script.Parent.Parent.StoryUtil)
local Fusion = StoryUtil.Fusion

local Children = Fusion.Children
local peek = Fusion.peek

-- Keys 1-9 equip a slot (again to unequip), ` toggles the full inventory, drag items to move
-- them; slot 3 has a three second cooldown.
return StoryUtil.story(function(scope, _, ctx)
	local Game = ctx.Pantheon.Game
	local selected = scope:Value(1)
	local cooldown = scope:Value(0)
	local items = scope:Value({
		[1] = { Name = "Sword", Description = "Starter blade", Tags = { "weapon", "melee" } },
		[2] = { Name = "Bow", Description = "Ranged", Tags = { "weapon", "ranged" }, Count = 24 },
		[3] = {
			Name = "Heal",
			Description = "Restores health",
			Tags = { "consumable" },
			Count = 3,
			Cooldown = cooldown,
		},
		[4] = { Name = "Block", Count = 64 },
		[11] = { Name = "Torch", Tags = { "tool" }, Count = 8 },
		[14] = { Name = "Map", Description = "Shows the area" },
	} :: { [number]: any })
	return scope:New("Frame")({
		Name = "Stage",
		Size = UDim2.new(1, 0, 0, 300),
		BackgroundColor3 = Color3.fromRGB(46, 62, 88),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			Game.Hotbar(scope, {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -12),
				Selected = selected,
				Items = items,
				Capacity = 27,
				OnSelect = function(slot: number?)
					if slot == 3 and peek(cooldown) == 0 then
						task.spawn(function()
							local started = os.clock()
							while true do
								local left = 1 - (os.clock() - started) / 3
								cooldown:set(math.max(left, 0))
								if left <= 0 then
									break
								end
								task.wait()
							end
						end)
					end
				end,
			}),
		},
	})
end)
