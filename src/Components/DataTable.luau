--!strict
--[[
	Sortable / filterable data table with virtualized body.
	CanvasGroup clips children to rounded corners (UICorner alone cannot).
]]
local Packages = script.Parent.Parent.Parent
local Fusion = require(Packages.Fusion)
local Types = require(script.Parent.Parent.Types)
local resolveTheme = require(script.Parent.Parent.Internal.resolveTheme).resolveTheme
local VirtualList = require(script.Parent.VirtualList)
local P = require(script.Parent.Parent.Internal.props)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

return function(scope: Types.Scope, props: Types.DataTableProps): Frame
	local theme = resolveTheme(props)
	local rowHeight = props.RowHeight or 48
	local sortCol = scope:Value(peek(props.SortColumn) or "")
	local sortAsc = scope:Value(if props.SortAscending == nil then true else peek(props.SortAscending))

	local processed = scope:Computed(function(use)
		local rows = table.clone(use(props.Rows) :: { { [string]: any } })
		local filter = string.lower(tostring(use(props.Filter) or ""))
		if filter ~= "" then
			local filtered = {}
			for _, row in rows do
				local parts = {}
				for _, col in props.Columns do
					table.insert(parts, tostring(row[col.Id] or ""))
				end
				local hay = string.lower(table.concat(parts, " "))
				if string.find(hay, filter, 1, true) then
					table.insert(filtered, row)
				end
			end
			rows = filtered
		end
		local col = use(sortCol)
		if col ~= "" then
			local asc = use(sortAsc)
			table.sort(rows, function(a, b)
				local av, bv = tostring(a[col] or ""), tostring(b[col] or "")
				if asc then
					return av < bv
				end
				return av > bv
			end)
		end
		return rows
	end)

	local headers = {}
	for i, col in props.Columns do
		local w = col.Width or 120
		table.insert(
			headers,
			scope:TextButton({
				Text = scope:Computed(function(use)
					local title = col.Title
					if use(sortCol) == col.Id then
						return title .. (if use(sortAsc) then " ↑" else " ↓")
					end
					return title
				end),
				FontFace = theme.Typography.Label.Font,
				TextSize = theme.Typography.Label.Size,
				TextColor3 = theme.Colors.OnSurfaceVariant,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, w, 1, 0),
				LayoutOrder = i,
				AutoButtonColor = false,
				Padding = { 0, theme.Metrics.SpaceSm },
				[OnEvent("Activated")] = function()
					if col.Sortable == false then
						return
					end
					if peek(sortCol) == col.Id then
						sortAsc:set(not peek(sortAsc))
					else
						sortCol:set(col.Id)
						sortAsc:set(true)
					end
					if props.OnSort then
						props.OnSort(peek(sortCol), peek(sortAsc))
					end
				end,
			})
		)
	end

	local body = VirtualList(scope, {
		Theme = theme,
		ItemCount = scope:Computed(function(use)
			return #use(processed)
		end),
		ItemHeight = rowHeight,
		Padding = 0,
		Size = UDim2.new(1, 0, 1, -45),
		RenderItem = function(rowScope, index)
			local cells = {}
			for i, col in props.Columns do
				table.insert(
					cells,
					rowScope:TextLabel({
						BackgroundTransparency = 1,
						FontFace = theme.Typography.Body.Font,
						TextSize = theme.Typography.Body.Size,
						TextColor3 = theme.Colors.OnSurface,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = rowScope:Computed(function(use)
							local rows = use(processed) :: { { [string]: any } }
							local row = rows[index]
							if row == nil then
								return ""
							end
							return tostring(row[col.Id] or "")
						end),
						Size = UDim2.new(0, col.Width or 120, 1, 0),
						LayoutOrder = i,
						Padding = { 0, theme.Metrics.SpaceSm },
					})
				)
			end
			return rowScope:TextButton(P({
				Text = "",
				BackgroundColor3 = theme.Colors.Surface,
				BackgroundTransparency = if index % 2 == 0 then 0 else 0.03,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, rowHeight),
				AutoButtonColor = false,
				ClipsDescendants = true,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Vertical,
					Padding = 0,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				[OnEvent("Activated")] = function()
					if props.OnSelect then
						props.OnSelect(index, true)
					end
				end,
				[Children] = {
					rowScope:Frame(P({
						Name = "Content",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, -1),
						LayoutOrder = 1,
						Layout = {
							Kind = "List",
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = 0,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						},
						[Children] = cells,
					})),
					rowScope:Frame(P({
						Name = "Divider",
						BackgroundColor3 = theme.Colors.OutlineVariant,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 1),
						LayoutOrder = 2,
					})),
				},
			}))
		end,
	})

	-- CanvasGroup clips to UICorner (Frame.ClipsDescendants does not)
	return scope:New("CanvasGroup")({
		Name = "DataTable",
		BackgroundColor3 = theme.Colors.Surface,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		LayoutOrder = props.LayoutOrder or 0,
		BorderSizePixel = 0,
		[Children] = {
			scope:New("UICorner")({
				CornerRadius = UDim.new(0, theme.Metrics.RadiusPanel),
			}),
			scope:New("UIStroke")({
				Color = theme.Colors.OutlineVariant,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			scope:Frame({
				Name = "Header",
				BackgroundColor3 = theme.Colors.SurfaceContainer,
				Size = UDim2.new(1, 0, 0, 44),
				BorderSizePixel = 0,
				Layout = {
					Kind = "List",
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = 0,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				},
				Padding = { 0, theme.Metrics.SpaceXs },
				[Children] = headers,
			}),
			scope:Frame({
				Name = "Hairline",
				BackgroundColor3 = theme.Colors.OutlineVariant,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromOffset(0, 44),
			}),
			scope:Hydrate(body)({
				Position = UDim2.fromOffset(0, 45),
				Size = UDim2.new(1, 0, 1, -45),
			}),
		},
	}) :: Frame
end
