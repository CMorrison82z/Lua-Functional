local getMethods = {
	Roblox = function (libName)
		return require(script[libName])
	end,
	Lua = function (libName)
		return require(libName)
	end
}

local getMethod = workspace and getMethods.Roblox or getMethods.Lua

return {
	Collection = getMethod("Collection"),
	Process = getMethod("Process"),
	Function = getMethod("Function")
}