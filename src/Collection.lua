local Collection = {}

Collection.Map = function(f, domain)
	local map = {}

	for k, v in domain do
		map[k] = f(v) -- f(v) : codomain
	end

	return map
end

Collection.Image = function(f, domain)
	local image = {}

	for _, value in domain do
		table.insert(image, f(value))
	end

	return image
end

Collection.ImageArgs = function(f, domainTuples)
	local image = {}

	for _, tuple in domainTuples do
		table.insert(image, table.pack(f(table.unpack(tuple))))
	end

	return image
end

Collection.Filter = function(predicate, list)
	local filtered = {}

	for k, v in list do
		if predicate(v) then
			table.insert(filtered, v)
		end
	end

	return filtered
end

Collection.Flat = function(list, depth)
	depth = depth or 1
	local flattened = {}

	local function flatten_helper(lst, d)
		if d == 0 then
			table.insert(flattened, lst)
			return
		end

		for _, item in ipairs(lst) do
			if type(item) == "table" then
				flatten_helper(item, d - 1)
			else
				table.insert(flattened, item)
			end
		end
	end

	flatten_helper(list, depth)
	
	return flattened
end

--[[
	Example : 
	function getAge(person)
		return person.age
	end

	local people = {
		{ name = "Alice", age = 30 },
		{ name = "Bob", age = 25 },
		{ name = "Charlie", age = 30 },
		{ name = "Dave", age = 25 },
	}

	local groups = groupBy(people, getAge)

	OUTPUT : 

	{
		[25] = {
			{ name = "Bob", age = 25 },
			{ name = "Dave", age = 25 },
		},
		[30] = {
			{ name = "Alice", age = 30 },
			{ name = "Charlie", age = 30 },
		},
	}
]]
Collection.GroupBy = function(key_fn, list)
	local groups = {}

	for _, item in ipairs(list) do
		local key = key_fn(item)

		if groups[key] == nil then
			groups[key] = {}
		end

		table.insert(groups[key], item)
	end

	return groups
end

Collection.Partition = function(predicate, list)
	local filter, unFiltered = {}, {}

	for index, value in ipairs(list) do
		table.insert(predicate(value) and filter or unFiltered, value)
	end

	return filter, unFiltered
end

Collection.Uniq = function (list)
	local subList = {}
	local _contains = {}

	for index, value in ipairs(list) do
		if not _contains[value] then
			_contains[value] = true

			table.insert(subList, value)
		end
	end

	return subList
end

-- returns domain and codomain of a discrete-map as a pair of lists
Collection.MapDomains = function(map)
	local domain, codomain = {}, {}

	for k, v in map do
		table.insert(domain, k)
		table.insert(codomain, v)
	end

	return domain, codomain
end

Collection.Zip = function(...)
	local lists = {...}
	local result = {}

	for i = 1, #lists[1] do
		local tuple = {}
		
		for j, list in ipairs(lists) do
			table.insert(tuple, list[i])
		end

		table.insert(result, tuple)
	end

	return result
end

Collection.Unzip = function(zipped)
	local num_tuples = #zipped
	local tuple_size = #zipped[1]
	local unzipped = {}

	for i = 1, tuple_size do
		local _iUnzipped = {}
		unzipped[i] = _iUnzipped

		for j = 1, num_tuples do
			table.insert(_iUnzipped, zipped[j][i])
		end
	end

	return unzipped
end

Collection.Sorter = function (predicate)
	return function (list)
		return table.sort(list, predicate)
	end
end

return Collection