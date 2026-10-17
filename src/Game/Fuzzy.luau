--!strict
--[[
	Fuzzy matching for the Hotbar search. See docs/Game/Hotbar.md.
]]

export type Scopes = { [string]: (item: any) -> (string | { string })? }

local Fuzzy = {}

local function isBoundary(char: string): boolean
	return string.match(char, "[%w]") == nil
end

--- 0..1 for how well `query` matches `text` as a subsequence, or nil when it doesn't.
function Fuzzy.score(query: string, text: string): number?
	query, text = string.lower(query), string.lower(text)
	if query == "" then
		return 1
	end
	local qi, last, total = 1, -2, 0
	for ti = 1, #text do
		if string.sub(text, ti, ti) == string.sub(query, qi, qi) then
			local bonus = 1
			if ti == last + 1 then
				bonus += 2
			end
			if ti == 1 or isBoundary(string.sub(text, ti - 1, ti - 1)) then
				bonus += 2
			end
			total += bonus
			last = ti
			qi += 1
			if qi > #query then
				break
			end
		end
	end
	if qi <= #query then
		return nil
	end
	local score = total / (#query * 5)
	local at = string.find(text, query, 1, true)
	if at then
		score += if at == 1 then 1 else 0.5
	end
	return math.clamp(score / 1.5, 0, 1)
end

--- Everything searchable about an item, grouped by scope name (lower case).
local function identifiers(item: any, scopes: Scopes?): { [string]: { string } }
	local found: { [string]: { string } } = {}
	local function add(scope: string, value: any)
		if type(value) == "string" and value ~= "" then
			found[scope] = found[scope] or {}
			table.insert(found[scope], value)
		elseif type(value) == "table" then
			for _, entry in value do
				if type(entry) == "string" then
					add(scope, entry)
				end
			end
		end
	end
	add("name", item.Name)
	add("description", item.Description)
	add("id", item.Id)
	add("tags", item.Tags)
	for key, value in item do
		local lower = string.lower(tostring(key))
		if
			type(value) == "string"
			and found[lower] == nil
			and lower ~= "image"
			and lower ~= "name"
			and lower ~= "description"
			and lower ~= "id"
		then
			add(lower, value)
		end
	end
	if scopes then
		for scope, extract in scopes do
			found[string.lower(scope)] = nil
			add(string.lower(scope), extract(item))
		end
	end
	return found
end

--- Best score of `query` against `item`, or nil if any word of it fails to match.
function Fuzzy.matchItem(query: string, item: any, scopes: Scopes?): number?
	local words: { string } = {}
	for word in string.gmatch(query, "%S+") do
		table.insert(words, word)
	end
	if #words == 0 then
		return 1
	end
	local known = identifiers(item, scopes)
	local total = 0
	for _, word in words do
		local scope, text = string.match(word, "^(%w+):(.*)$")
		local pool: { string } = {}
		if scope and known[string.lower(scope)] then
			pool = known[string.lower(scope)]
		else
			text = word
			for _, list in known do
				for _, value in list do
					table.insert(pool, value)
				end
			end
		end
		local best: number? = nil
		for _, value in pool do
			local score = Fuzzy.score(text :: string, value)
			if score and (best == nil or score > best) then
				best = score
			end
		end
		if best == nil then
			return nil
		end
		total += best
	end
	return total / #words
end

return Fuzzy
