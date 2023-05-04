local Function = {}

Function.Curry = function(f, arg)
	return function(...)
		return f(arg, ...)
	end
end

-- Lift == Curry(Image, predicate)

Function.Memoize = function (f)
	local map = {}

	return function(x)
		map[x] = map[x] or f(x)

		return map[x]
	end
end

Function.MemoizeN = function(f, numParams)
	local cache = {}
  
	return function(...)
		local args = {...}
		local cacheLevel = cache

		for i = 1, numParams - 1 do
			local arg = args[i]
			cacheLevel[arg] = cacheLevel[arg] or {}
			cacheLevel = cacheLevel[arg]
		end
		local lastArg = args[numParams]
		cacheLevel[lastArg] = cacheLevel[lastArg] or f(...)
		
		return cacheLevel[lastArg]
	end
end  

-- For a series of single argument && return functions.
Function.Pipeline1 = function(...)
	local pipeline = {...}
	local numF = #pipeline

	return function(x)
		local _lastR = x
	
		for i = 1, numF - 1 do
			_lastR = pipeline[i](x)
		end

		return pipeline[numF](_lastR)
	end
end

Function.Pipeline = function(...)
	local pipeline = {...}
	local numF = #pipeline

	return function(...)
		local _lastR = {...}
	
		for i = 1, numF - 1 do
			_lastR = table.pack(pipeline[i](table.unpack(_lastR)))
		end

		return pipeline[numF](table.unpack(_lastR))
	end
end

Function.BulkProcedure = function(f, argsList)
	for _, value in ipairs(argsList) do
		f(table.unpack(value))
	end
end

do
	-- These functions are motivated by the idea that `function` are just maps. Their images are sets, and thus we can define intersections of functions (i.e. their images) etc.

	-- TODO : Define for union / intersection return types (tuples, etc.)

	local ImageOps = {}
	m.ImageOps = ImageOps

	do
		local SingleOutput = {}
		ImageOps.SingleOutput = SingleOutput
		
		function SingleOutput.Union(f, g)
			return function (...)
				return f(...) or g(...)
			end
		end

		function SingleOutput.Intersection(f, g)
			return function (...)
				local i1, i2 = f(...), g(...)
				
				return i1 == i2 and i1
			end
		end

		-- I_f - I_g
		function SingleOutput.Complement(f, g)
			return function (...)
				local i1, i2 = f(...), g(...)
			
				return not i2 and i1
			end
		end

		function SingleOutput.SymmetricCompliment(f, g)
			return function (...)
				local i1, i2 = f(...), g(...)

				return not (i1 == i2 and i1) and (i1 or i2)
			end
		end
	end
end

return Function