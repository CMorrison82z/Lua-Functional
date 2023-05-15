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

local function bake(Generator: Generator)
    local iterator, obj, state = Generator.Iterator, Generator.Object_0, Generator.State_0
    local t = {}

    local v
    repeat
        state, v = iterator(obj, state)

        t[state] = v
    until (state == nil)

    return t
end

Iterative.bake = bake

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
        Iterator = function(c)
            return cond(c) and gen(c) or nil
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
        Iterator = function(...)
            local r; repeat
                r = table.pack(iterator(...))
            until r[1] == nil or predicate(table.unpack(r))
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

    local iterator, obj_0, state_0 = generator.Iterator, generator.Object_0, generator.State_0    

    local filterPredicate = function(...)
        return not predicate(...)
    end

    return filter(predicate, iterator), filter(filterPredicate, iterator)
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
        Iterator = function(_gens, i)
            _vs = {}

            for _, _gener : Generator in _gens do
                local _, v = _gener.Iterator(_gener.Object_0, i)

                if v == nil then
                    _vs = nil
                    break
                else
                    table.insert(_vs, v)
                end
            end

            return _vs and table.unpack(_vs)
        end,
        Object_0 = _generators,
        State_0 = 0
    }
end

return Iterative