export type Generator = {
    Iterator: (t: table, state...) -> any,
    Object_0: table,
    State_0: any
}

local function isGenerator(t : Generator)
    return type(t) == "table" and t.Iterator and t.Object_0 and t.State_0
end

local Iterative = {}

local function iter(t)
    local generator : Generator = {}
    generator.Iterator, generator.Object_0, generator.State_0 = (#t > 0 and ipairs or pairs)(t)

    return generator
end

Iterative.iter = iter

-- local function TEMPLATE_FUNCTION(generator: Generator) : Generator
--     if not isGenerator(generator) then
--         generator = iter(generator)
--     end

--     local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0

--     local v

--     return {
--         Iterator = function(obj: any, state: any)
            
--         end,
--         Object_0 = obj_0,
--         State_0 = state_0
--     }
-- end

function Iterative.enumerate(generator: Generator) : Generator
    if not isGenerator(generator) then
        generator = iter(generator)
    end

    local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0

    local i = 0

    return {
        Iterator = function(obj: any, state: any)
            i += 1

            return i, iterator(obj, state)
        end,
        Object_0 = obj_0,
        State_0 = state_0
    }
end

function Iterative.cycle(generator: Generator) : Generator
    if not isGenerator(generator) then
        generator = iter(generator)
    end

    local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0

    local v

    return {
        Iterator = function(obj: any, state: any)
            state, v = iterator(obj, state)
    
            if state == nil then
                state, v = iterator(obj, state_0)
            end
    
            return state, v
        end,
        Object_0 = obj_0,
        State_0 = state_0
    }
end

local function map(predicate: (any...) -> any)
    return function(generator: Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
    
        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0    

        local v, r

        return {
            Iterator = function(obj: any, ...)
                return predicate(iterator(obj, ...))
            end,
            Object_0 = obj_0,
            State_0 = state_0
        }
    end
end
Iterative.map = map

function Iterative.mapV(predicate: (any...) -> any)
    return map(function(i, ...)
        return i, predicate(...)
    end)
end

function Iterative.sort(predicate : (a : any, b : any) -> boolean, generator : Generator)
    local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    local pq = {} -- priority queue

    return {
        Iterator = function(obj, state)
            local _done = false

            if #pq == 0 then -- if priority queue is empty
                _done = true

                for k, v in iterator, obj, state do
                    _done = false
                    -- insert into priority queue
                    table.insert(pq, v)
                    local i = #pq
                    while i > 1 and predicate(pq[i], pq[math.floor(i / 2)]) do
                        pq[i], pq[math.floor(i / 2)] = pq[math.floor(i / 2)], pq[i]
                        i = math.floor(i / 2)
                    end
                end
            end
            -- remove from priority queue
            local result = pq[1]
            pq[1] = pq[#pq]
            pq[#pq] = nil
            local i = 1
            while true do
                local j = 2 * i
                if j < #pq and predicate(pq[j + 1], pq[j]) then j = j + 1 end
                if j > #pq or not predicate(pq[j], pq[i]) then break end
                pq[i], pq[j] = pq[j], pq[i]
                i = j
            end
            
            return not _done and state + 1 or nil, result
        end,
        Object_0 = obj_0,
        State_0 = state_0
    }
end

function Iterative.unfold(gen: (any) -> any, cond: (any) -> boolean, seed: any): Generator
    return {
        Iterator = function(_, c)
            if c then
                c = gen(c)
                return cond(c) and c or nil
            else
                return cond(seed) and seed
            end
        end,
        Object_0 = seed,
        State_0 = nil
    }
end



local function filter(predicate: (...any) -> boolean, generator: Generator): Generator
    if not isGenerator(generator) then
        generator = iter(generator)
    end

    local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0

    return {
        Iterator = function(obj, ...)
            local r = table.pack(iterator(obj, ...))
            
            while r[1] ~= nil and not predicate(table.unpack(r)) do
                r = table.pack(iterator(obj, table.unpack(r)))
            end
            
            return table.unpack(r)
        end,
        Object_0 = obj_0,
        State_0 = state_0
    }
end

Iterative.filter = filter

function Iterative.partition(predicate: (...any) -> boolean, generator: Generator): Generator
    if not isGenerator(generator) then
        generator = iter(generator)
    end

    local filterPredicate = function(...)
        return not predicate(...)
    end

    return filter(predicate, generator), filter(filterPredicate, generator)
end

function Iterative.zip(...: Generator)
    local _generators = table.pack(...)

    for index, value in _generators do
        if not isGenerator(value) then
            _generators[index] = iter(value)
        end
    end

    local _vs;

    return {
        Iterator = function(_gens)
            _vs = {}

            local v;

            for _, _gener in ipairs(_gens) do
                _gener._state, v = _gener.Iterator(_gener.Object_0, _gener._state or 0)
                
                if v == nil then
                    _vs = nil
                    break
                else
                    table.insert(_vs, v)
                end
            end

            if _vs then
                return table.unpack(_vs)
            end
        end,
        Object_0 = _generators,
        State_0 = 0
    }
end

do
    local _fold = {}
    Iterative.Fold = _fold

    function _fold.each(predicate, generator : Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
    
        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    
        local r repeat
            r = r and table.pack(iterator(obj_0, table.unpack(r))) or table.pack(iterator(obj_0, state_0))

            predicate(table.unpack(r))
        until r[1] == nil
    end

    function _fold.bake(Generator: Generator)
        local iterator, obj_0, state_0 = Generator.Iterator, Generator.Object_0, Generator.State_0
        local t = {}
    
        local state, v = iterator(obj_0, state_0)
        while state~= nil do
            t[state] = v
            state, v = iterator(obj_0, state)
        end
    
        return t
    end

    -- todo : make it not suck
    function _fold.bake_N(Generator: Generator)
        local iterator, obj_0, state_0 = Generator.Iterator, Generator.Object_0, Generator.State_0
        local t = {}
    
        local r = table.pack(iterator(obj_0, state_0))

        local state = r[1]

        while state~= nil do
            t[state] = table.pack(select(2, table.unpack(r)))
            r = table.pack(iterator(obj_0, state_0))

            state = r[1]
        end
    
        return t
    end

    function _fold.fold_l(predicate: (result : any, args...) -> any, idE, generator : Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
        
        local result = idE

        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    
        local r repeat
            r = r and table.pack(iterator(obj_0, table.unpack(r))) or table.pack(iterator(obj_0, state_0))

            result = predicate(result, table.unpack(r))
        until r[1] == nil
    
        return result
    end
    
    -- * Note that predicate includes the state
    -- ! Assumes that the 2nd value (usually the `value`) is the initial value of the `result`.
    function _fold.reduce(predicate: (result : any, args...) -> any, generator : Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
        
        local result;

        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    
        local r repeat
            r = r and table.pack(iterator(obj_0, table.unpack(r))) or table.pack(iterator(obj_0, state_0))

            result = result and predicate(result, table.unpack(r)) or r[2]
        until r[1] == nil
    
        return result
    end

    function _fold.trans_fold_l(trans, predicate: (result : any, args...) -> any, idE, generator : Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
        
        local result = idE

        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    
        local r repeat
            r = r and table.pack(iterator(obj_0, table.unpack(r))) or table.pack(iterator(obj_0, state_0))

            result = predicate(result, trans(table.unpack(r)))
        until r[1] == nil
    
        return result
    end

    function _fold.transduce(trans, predicate: (result : any, args...) -> any, generator : Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
        
        local result;

        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    
        local r repeat
            r = r and table.pack(iterator(obj_0, table.unpack(r))) or table.pack(iterator(obj_0, state_0))

            result = predicate(result, trans(table.unpack(r)))
        until r[1] == nil
    
        return result
    end

    function _fold.scan(predicate: (result : any, args...) -> any, idE, generator : Generator)
        if not isGenerator(generator) then
            generator = iter(generator)
        end
        
        local result = idE
        local _scan = {result}

        local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0
    
        local r repeat
            r = r and table.pack(iterator(obj_0, table.unpack(r))) or table.pack(iterator(obj_0, state_0))

            result = predicate(result, table.unpack(r))
        until r[1] == nil
    
        return _scan
    end

    -- todo : write curried forms (ex. Trans_ducer (trans, predicate) -> f(generator) -> any)
end

return Iterative