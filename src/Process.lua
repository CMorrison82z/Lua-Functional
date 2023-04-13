local Process = {}

Process.Reduce = function (predicate, list)
	local result = list[1]

	for i = 2, #list do
		result = predicate(result, list[i])
	end

	return result
end

Process.Transduce = function (trans, predicate, list)
	local result = trans(list[1])

	for index, value in ipairs(list) do
		result = predicate(result, trans(value))
	end

	return result
end

Process.FoldL = function (predicate, idE, list)
	local result = idE

	for i = 1, #list do
		result = predicate(result, list[i])
	end

	return result
end

Process.FoldR = function (predicate, idE, list)
	local result = idE

	for i = #list, 1, -1 do
		result = predicate(result, list[i])
	end

	return result
end

Process.Scan = function (predicate, idE, list)
	local scannedL = {}
	local result = idE

	for i = 1, #list do
		result = predicate(result, list[i])
		table.insert(scannedL, result)
	end

	return scannedL
end

Process.TransFoldL = function (trans, predicate, ide, list)
	local result = ide

	for index, value in ipairs(list) do
		result = predicate(result, trans(value))
	end

	return result
end


Process.TransFoldR = function (trans, predicate, ide, list)
	local result = ide

	for i = #list, 1, -1 do
		result = predicate(result, trans(list[i]))
	end

	return result
end

Process.Unfold = function(generator, condition, seed)
	local result = {}
	local current = seed
	table.insert(result, current)

	while condition(current) do
	  current = generator(current)
	  table.insert(result, current)
	end
	
	return result
  end
  

-- The following are simply currying options for FoldR, FoldL, and Scan

do
	local Curry = {}
	Process.Curry = Curry

	Curry.Transducer = function (trans, predicate)
		return function(list)
			local result = trans(list[1])
	
			for index, value in ipairs(list) do
				result = predicate(result, trans(value))
			end
	
			return result
		end
	end
	
	-- Example : `Summer` = LFolder(function(result, val) return result + val end, 0)
	Curry.LFolder = function (predicate, idE)
		return function (list)
			local result = idE
	
			for i = 1, #list do
				result = predicate(result, list[i])
			end
	
			return result
		end
	end
	
	Curry.RFolder = function (predicate, idE)
		return function (list)
			local result = idE
	
			for i = #list, 1, -1 do
				result = predicate(result, list[i])
			end
	
			return result
		end
	end
	
	Curry.Scanner = function (predicate, idE)
		return function (list)
			local scannedL = {}
			local result = idE
	
			for i = 1, #list do
				result = predicate(result, list[i])
				table.insert(scannedL, result)
			end
	
			return scannedL
		end
	end
end

return Process