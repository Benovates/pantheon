--!strict
--[[
	Feeds a Leaderboard from the players and teams of the Roblox experience.
	See docs/Game/Leaderboard.md.
]]
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local FRIEND_ICON = "rbxasset://textures/ui/PlayerList/FriendIcon.png"
local PREMIUM_ICON = "rbxasset://textures/ui/PlayerList/PremiumIcon.png"
local NO_TEAM_COLOR = Color3.fromRGB(110, 110, 120)

local Roster = {}

export type Options = {
	--- Return a stat for a player to show at the end of the row.
	Value: ((player: Player) -> any)?,
	--- Return an asset id for the icon of a player. The default is a friend or Premium icon.
	Icon: ((player: Player) -> string?)?,
}

function Roster.new(scope: any, options: Options?)
	local opts: Options = options or {}
	local teams = scope:Value({} :: { any })
	local localPlayer = Players.LocalPlayer
	local friends: { [number]: boolean } = {}
	local connections: { RBXScriptConnection } = {}
	local alive = true
	table.insert(scope, function()
		alive = false
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	local function iconFor(player: Player): string?
		if opts.Icon then
			return opts.Icon(player)
		end
		if friends[player.UserId] then
			return FRIEND_ICON
		elseif player.MembershipType == Enum.MembershipType.Premium then
			return PREMIUM_ICON
		end
		return nil
	end

	local function row(player: Player)
		return {
			Id = player.UserId,
			Name = player.Name,
			DisplayName = player.DisplayName,
			UserId = player.UserId,
			Icon = iconFor(player),
			Value = if opts.Value then opts.Value(player) else nil,
		}
	end

	local refresh: () -> ()
	local pending = false
	local function schedule()
		if pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			if alive then
				refresh()
			end
		end)
	end

	refresh = function()
		local built = {}
		local listed = Teams:GetTeams()
		if #listed == 0 then
			local everyone = {}
			for _, player in Players:GetPlayers() do
				table.insert(everyone, row(player))
			end
			built = { { Name = "", Players = everyone } }
		else
			for _, team in listed do
				if not team:GetAttribute("Hidden") then
					local members = {}
					for _, player in team:GetPlayers() do
						table.insert(members, row(player))
					end
					table.insert(
						built,
						{ Name = team.Name, Color = team.TeamColor.Color, Players = members }
					)
				end
			end
			local neutral = {}
			for _, player in Players:GetPlayers() do
				if player.Team == nil then
					table.insert(neutral, row(player))
				end
			end
			if #neutral > 0 then
				table.insert(built, { Name = "No Team", Color = NO_TEAM_COLOR, Players = neutral })
			end
		end
		teams:set(built)
	end

	--- Whether each other player is a friend of the local player. IsFriendsWithAsync yields, so it
	--- runs off to the side and the list is updated when the answer is in.
	local function checkFriend(player: Player)
		if localPlayer == nil or player == localPlayer then
			return
		end
		task.spawn(function()
			local ok, result = pcall(player.IsFriendsWithAsync, player, localPlayer.UserId)
			if ok and result and alive then
				friends[player.UserId] = true
				schedule()
			end
		end)
	end

	local function watch(player: Player)
		checkFriend(player)
		table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(schedule))
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	table.insert(
		connections,
		Players.PlayerAdded:Connect(function(player)
			watch(player)
			schedule()
		end)
	)
	table.insert(connections, Players.PlayerRemoving:Connect(schedule))
	table.insert(connections, Teams.ChildAdded:Connect(schedule))
	table.insert(connections, Teams.ChildRemoved:Connect(schedule))
	refresh()

	return {
		Teams = teams,
		Self = if localPlayer then localPlayer.UserId else nil,
	}
end

return Roster
