--!strict
--[[
	Player list in the style of Roblox's: translucent rows with a faded headshot, the display name
	that gives way to the username on hover, and collapsible team headers.
	See docs/Game/Leaderboard.md.
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Style = require(script.Parent.Style)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local EXIT_TIME = 0.4
local HEADER_HEIGHT = 24

export type Row = {
	--- Identifies the row. Keep it between updates, so the row isn't rebuilt.
	Id: any,
	--- Username. Shown as `@Name` on hover.
	Name: string,
	DisplayName: string?,
	--- Roblox user id, for the headshot.
	UserId: number?,
	--- Asset id of a picture, for a row that isn't a Roblox user.
	Image: string?,
	--- Asset id of a small icon at the end of the row.
	Icon: string?,
	--- A stat shown at the end of the row: a number or text.
	Value: any?,
}

export type Team = {
	Name: string,
	Color: Color3?,
	Players: { Row },
	--- A `Value<boolean>` that holds whether the team is collapsed. The list keeps its own if left out.
	Collapsed: any?,
}

export type Props = {
	--- Teams, each with a coloured header. A header is left out for a team with no `Name`.
	Teams: any?,
	--- Players with no teams.
	Players: any?,
	Title: string?,
	--- `Id` of the local player's row, which is lightly highlighted.
	Self: any?,
	--- Whether the list is on screen. It slides off the edge when `false`.
	Open: any?,
	Width: number?,
	--- Height at which the list starts to scroll.
	MaxHeight: number?,
	RowHeight: number?,
	--- "Value" sorts each team by `Value`, highest first.
	Sort: ("None" | "Value")?,
	ValueFormat: ((value: any) -> string)?,
	OnPlayerClick: ((row: Row) -> ())?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
}

local function defaultFormat(value: any): string
	if type(value) == "number" then
		local text = tostring(math.floor(value))
		local grouped = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1,")))
		return (string.gsub(grouped, "^,", ""))
	end
	return tostring(value)
end

local function isState(value: any): boolean
	return typeof(value) == "table" and (value :: any).type == "State"
end

local function read(value: any): any
	return if isState(value) then peek(value) else value
end

return function(scope: any, props: Props): Instance
	local rowHeight = props.RowHeight or 42
	local width = props.Width or 220
	local format = props.ValueFormat or defaultFormat

	local contentHeight = scope:Value(0)
	local openS = scope:Spring(
		scope:Computed(function(use)
			local open = props.Open
			if open == nil then
				return 1
			end
			return if (if isState(open) then use(open) else open) == false then 0 else 1
		end),
		22,
		1
	)

	-- the list of rows and headers
	local body = scope:New("Frame")({
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}) :: Frame
	local layout = scope:New("UIListLayout")({
		Parent = body,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) :: UIListLayout

	type Entry = { scope: any, order: any, shown: any, gone: boolean, data: any? }
	local entries: { [string]: Entry } = {}
	local collapsed: { [string]: any } = {}

	local function collapsedFor(team: Team, key: string): any
		if team.Collapsed ~= nil then
			return team.Collapsed
		end
		if collapsed[key] == nil then
			collapsed[key] = scope:Value(false)
		end
		return collapsed[key]
	end

	local function buildHeader(key: string, name: string, color: Color3, hide: any): Entry
		local inner = scope:innerScope()
		local data = inner:Value({ Name = name, Color = color, Count = 0 })
		local order = inner:Value(0)
		local shown = inner:Value(0)
		local shownS = inner:Spring(shown, 22, 1)
		inner:New("Frame")({
			Name = key,
			Parent = body,
			BackgroundColor3 = inner:Computed(function(use)
				return (use(data) :: any).Color
			end),
			BackgroundTransparency = inner:Computed(function(use)
				return 1 - 0.7 * math.clamp(use(shownS) :: number, 0, 1)
			end),
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
			[Children] = {
				inner:New("TextLabel")({
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(16, 0),
					Size = UDim2.new(0.75, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Style.FontBold,
					TextSize = 12,
					TextColor3 = Style.Text,
					TextTransparency = inner:Computed(function(use)
						return 1 - math.clamp(use(shownS) :: number, 0, 1)
					end),
					Text = inner:Computed(function(use)
						return (use(data) :: any).Name
					end),
				}),
				inner:New("TextLabel")({
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -16, 0, 0),
					Size = UDim2.new(0.25, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					FontFace = Style.Font,
					TextSize = 12,
					TextColor3 = Style.Text,
					TextTransparency = inner:Computed(function(use)
						return 1 - 0.5 * math.clamp(use(shownS) :: number, 0, 1)
					end),
					Text = inner:Computed(function(use)
						return tostring((use(data) :: any).Count)
					end),
				}),
				-- Pressing the header folds the team's rows away.
				inner:New("TextButton")({
					Name = "Toggle",
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 3,
					[OnEvent("Activated")] = function()
						hide:set(not peek(hide))
					end,
				}),
			} :: any,
		})
		task.defer(function()
			shown:set(1)
		end)
		return { scope = inner, order = order, shown = shown, gone = false, data = data }
	end

	local function buildRow(key: string, hide: any): Entry
		local inner = scope:innerScope()
		local data = inner:Value({ Id = key, Name = "" } :: Row)
		local order = inner:Value(0)
		local last = inner:Value(false)
		local shown = inner:Value(0)
		local hovered = inner:Value(false)
		-- The row's height follows `visible`: it is 0 while the team is folded or the row has not
		-- arrived yet, and the slide of the content follows the same spring.
		local visible = inner:Spring(
			inner:Computed(function(use)
				return if use(shown) == 1 and not use(hide) then 1 else 0
			end),
			26,
			1
		)
		local hover = inner:Spring(
			inner:Computed(function(use)
				return if use(hovered) then 1 else 0
			end),
			40,
			0.7
		)
		local isSelf = inner:Computed(function(use)
			local me = if props.Self ~= nil
				then (if isState(props.Self) then use(props.Self) else props.Self)
				else nil
			return me ~= nil and (use(data) :: Row).Id == me
		end)

		local function fade(base: number): any
			return inner:Computed(function(use)
				return 1 - (1 - base) * math.clamp(use(visible) :: number, 0, 1)
			end)
		end

		inner:New("Frame")({
			Name = key,
			Parent = body,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			LayoutOrder = order,
			Size = inner:Computed(function(use)
				return UDim2.new(1, 0, 0, rowHeight * math.max(use(visible) :: number, 0))
			end),
			[Children] = inner:New("Frame")({
				Name = "Slide",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, rowHeight),
				Position = inner:Computed(function(use)
					return UDim2.new(1 - math.clamp(use(visible) :: number, 0, 1), 0, 0, 0)
				end),
				[OnEvent("MouseEnter")] = function()
					hovered:set(true)
				end,
				[OnEvent("MouseLeave")] = function()
					hovered:set(false)
				end,
				[Children] = {
					inner:New("Frame")({
						Name = "Fill",
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = fade(0.5),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					}),
					inner:New("Frame")({
						Name = "SelfTint",
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = inner:Computed(function(use)
							return if use(isSelf) then 0.9 else 1
						end),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					}),
					inner:New("ImageLabel")({
						Name = "Headshot",
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(0, 0),
						Size = UDim2.fromOffset(60, rowHeight),
						ScaleType = Enum.ScaleType.Crop,
						ZIndex = 2,
						Image = inner:Computed(function(use)
							local row = use(data) :: Row
							if row.Image then
								return row.Image
							elseif row.UserId then
								return `rbxthumb://type=AvatarHeadShot&id={row.UserId}&w=60&h=60`
							end
							return ""
						end),
						ImageTransparency = fade(0.6),
						[Children] = inner:New("UIGradient")({
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0),
								NumberSequenceKeypoint.new(1, 1),
							}),
						}),
					}),
					inner:New("TextLabel")({
						Name = "DisplayName",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.55, 0, 1, 0),
						ZIndex = 3,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						FontFace = Style.FontBold,
						TextSize = 14,
						TextColor3 = Style.Text,
						Position = inner:Computed(function(use)
							return UDim2.fromOffset(16 * (1 - (use(hover) :: number)), 0)
						end),
						TextTransparency = inner:Computed(function(use)
							return math.clamp(
								1 - (1 - (use(hover) :: number)) * (use(visible) :: number),
								0,
								1
							)
						end),
						Text = inner:Computed(function(use)
							local row = use(data) :: Row
							return row.DisplayName or row.Name
						end),
					}),
					inner:New("TextLabel")({
						Name = "Username",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.55, 0, 1, 0),
						ZIndex = 3,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						FontFace = Style.Font,
						TextSize = 14,
						TextColor3 = Style.Text,
						Position = inner:Computed(function(use)
							return UDim2.fromOffset(32 - 16 * (use(hover) :: number), 0)
						end),
						TextTransparency = inner:Computed(function(use)
							return 1 - 0.5 * (use(hover) :: number) * (use(visible) :: number)
						end),
						Text = inner:Computed(function(use)
							return "@" .. (use(data) :: Row).Name
						end),
					}),
					inner:New("TextLabel")({
						Name = "Value",
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(1, 0),
						Position = inner:Computed(function(use)
							local row = use(data) :: Row
							return UDim2.new(1, if row.Icon then -40 else -16, 0, 0)
						end),
						Size = UDim2.new(0.3, 0, 1, 0),
						ZIndex = 3,
						TextXAlignment = Enum.TextXAlignment.Right,
						FontFace = Style.FontBold,
						TextSize = 14,
						TextColor3 = Style.Text,
						TextTransparency = fade(0),
						Text = inner:Computed(function(use)
							local row = use(data) :: Row
							return if row.Value ~= nil then format(row.Value) else ""
						end),
					}),
					inner:New("ImageLabel")({
						Name = "Icon",
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -16, 0.5, 0),
						Size = UDim2.fromOffset(16, 16),
						ZIndex = 3,
						ImageTransparency = fade(0),
						Image = inner:Computed(function(use)
							return (use(data) :: Row).Icon or ""
						end),
					}),
					inner:New("Frame")({
						Name = "Divider",
						AnchorPoint = Vector2.new(1, 1),
						Position = UDim2.fromScale(1, 1),
						Size = UDim2.new(1, -16, 0, 1),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						Visible = inner:Computed(function(use)
							return not use(last)
						end),
						ZIndex = 3,
					}),
					inner:New("TextButton")({
						Name = "Press",
						Text = "",
						AutoButtonColor = false,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 4,
						[OnEvent("Activated")] = function()
							if props.OnPlayerClick then
								props.OnPlayerClick(peek(data))
							end
						end,
					}),
				} :: any,
			}),
		})
		task.defer(function()
			shown:set(1)
		end)
		return {
			scope = inner,
			order = order,
			shown = shown,
			gone = false,
			data = { data = data, last = last },
		}
	end

	local function remove(key: string)
		local entry = entries[key]
		if entry == nil or entry.gone then
			return
		end
		entry.gone = true
		entries[key] = nil
		entry.shown:set(0)
		task.delay(EXIT_TIME, function()
			Fusion.doCleanup(entry.scope)
		end)
	end

	local function update()
		local teams: { Team } = {}
		if props.Teams ~= nil then
			teams = table.clone(read(props.Teams) or {})
		elseif props.Players ~= nil then
			teams = { { Name = "", Players = read(props.Players) or {} } }
		end
		local seen: { [string]: boolean } = {}
		local order = 0
		for index, team in teams do
			local teamKey = `team:{index}:{team.Name}`
			local hide = collapsedFor(team, teamKey)
			local list = table.clone(team.Players)
			if props.Sort == "Value" then
				table.sort(list, function(a, b)
					local av, bv = tonumber(a.Value) or 0, tonumber(b.Value) or 0
					if av ~= bv then
						return av > bv
					end
					return tostring(a.Id) < tostring(b.Id)
				end)
			end
			if team.Name ~= "" then
				order += 1
				seen[teamKey] = true
				local header = entries[teamKey]
				if header == nil then
					header = buildHeader(
						teamKey,
						team.Name,
						team.Color or Color3.fromRGB(80, 80, 80),
						hide
					)
					entries[teamKey] = header
				end
				header.order:set(order)
				local headerData = header.data :: any
				headerData:set({
					Name = team.Name,
					Color = team.Color or Color3.fromRGB(80, 80, 80),
					Count = #list,
				})
			end
			for position, row in list do
				order += 1
				local rowKey = `row:{row.Id}`
				seen[rowKey] = true
				local entry = entries[rowKey]
				if entry == nil then
					entry = buildRow(rowKey, hide)
					entries[rowKey] = entry
				end
				entry.order:set(order)
				entry.data.data:set(row)
				entry.data.last:set(position == #list)
			end
		end
		for key in table.clone(entries) do
			if not seen[key] then
				remove(key)
			end
		end
	end

	for _, source in { props.Teams, props.Players, props.Self } do
		if isState(source) then
			table.insert(scope, scope:Observer(source):onChange(update))
		end
	end
	update()

	-- the panel
	local scroller = scope:New("ScrollingFrame")({
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Size = scope:Computed(function(use)
			local height = use(contentHeight) :: number
			local cap = props.MaxHeight
			return UDim2.new(
				1,
				0,
				0,
				if cap then math.min(height, cap - HEADER_HEIGHT - 6) else height
			)
		end),
		LayoutOrder = 2,
		[Children] = body,
	}) :: ScrollingFrame
	table.insert(
		scope,
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			contentHeight:set(layout.AbsoluteContentSize.Y)
		end)
	)

	local function cap(name: string, order: number, top: boolean): Instance
		return scope:New("Frame")({
			Name = name,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, if top then HEADER_HEIGHT else 6),
			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0, if top then 6 else 6) }),
				if top
					then scope:New("TextLabel")({
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(16, 0),
						Size = UDim2.new(1, -32, 1, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
						FontFace = Style.FontBold,
						TextSize = 12,
						TextTransparency = 0.2,
						TextColor3 = Style.Text,
						Text = props.Title or "Players",
					})
					else nil,
			} :: any,
		})
	end

	return scope:New("Frame")({
		Name = "Leaderboard",
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint or Vector2.new(1, 0),
		Position = scope:Computed(function(use)
			local base = props.Position or UDim2.new(1, -8, 0, 8)
			return base
				+ UDim2.fromOffset((1 - math.clamp(use(openS) :: number, 0, 1)) * (width + 24), 0)
		end),
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder or 0,
		[Children] = {
			scope:New("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			cap("Header", 1, true),
			scroller,
			cap("Footer", 3, false),
		} :: any,
	}) :: Frame
end
