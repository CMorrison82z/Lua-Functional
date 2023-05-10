local function bake(iterator, obj, state)
    local t = {}
    
    local v; repeat
        state, v = iterator(obj, state)

        t[state] = v
    until (state == nil)

    return t
end

local function bake_list(iterator, obj, state)
    local t, i = {}, 1
    
    local v; repeat
        state, v = iterator(obj, state)

        if v ~= nil then
            t[i], i = v, i + 1
        end
    until (state == nil)

    return t
end

local function cycle(iterator, obj_0, state_0)
    if type(iterator) == "table" then
        iterator, obj_0, state_0 = (#iterator > 0 and ipairs or pairs)(iterator)
    end

    local v;
    
    return function(obj, state)
        state, v = iterator(obj, state)

        if state == nil then
            state, v = iterator(obj, state_0)
        end

        return state, v
    end, obj_0, state_0
end

local function map(predicate)
    return function(iter, obj_0, state_0)
        if type(iter) == "table" then
            iter, obj_0, state_0 = ipairs(iter)
        end

        local v, r;

        return function(obj, ...)
			return predicate(iter(obj, ...))
        end, obj_0, state_0
    end
end

-- maps values, ignoring the first value returned by an iterator (assumed to be the state)
local function mapV(predicate)
	return map(function(i, ...)
		return i, predicate(...)
	end)
end

-- local function mapNthArgs(predicate, n)
-- 	return map(function(...)

-- 		return i, predicate(...)
-- 	end)
-- end


local function sort(predicate, iterator, obj_0, state_0)
    if type(iterator) == "table" then
        iterator, obj_0, state_0 = ipairs(iterator)
    end

    local v;

    return function (obj, state)
        local i_state, best_val = nil, nil; repeat
            state, v = iterator(obj, state)

            if best_val == nil then
                i_state = state
                best_val = v
            else
                best_val = predicate(v, best_val) and v or best_val
            end
        until (state == nil)

        return i_state, best_val
    end, obj_0, state_0
end

-- generators : 

local function unfold(gen, cond, seed)
    return function(a, c)
        if c == nil then
            return seed
        else
            return cond(c) and gen(c) or nil
        end
    end, seed
end

local function filter(predicate, iterator, object_0, state_0)
    if type(iterator) == "table" then
        iterator, object_0, state_0 = ipairs(iterator)
    end

    local r;
    
    return function(o, ...)
        repeat
            r = table.pack(iterator(...))
        until r[1] == nil or predicate(table.unpack(r))
        return table.unpack(r)
    end, object_0, state_0
end

local function partition(predicate, iterator, object_0, state_0)
    if type(iterator) == "table" then
        iterator, object_0, state_0 = ipairs(iterator)
    end

    local r;
    
    return function(o, ...)
        repeat
            r = table.pack(iterator(...))
        until r[1] == nil or predicate(table.unpack(r))
        return table.unpack(r)
    end, object_0, state_0, function(o, ...)
        repeat
            r = table.pack(iterator(...))
        until r[1] == nil or not predicate(table.unpack(r))
        return table.unpack(r)
    end, object_0, state_0
end

for value in unfold(function(x)
    return x + 1
end, function(x)
    return x < 10
end, 0) do
    print(value)
end