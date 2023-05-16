local Collection = {}

Collection.map = function(f, domain)
    local map = {}

    for k, v in pairs(domain) do
        map[k] = f(v) -- f(v) : codomain
    end

    return map
end

Collection.image = function(f, domain)
    local image = {}

    for _, value in pairs(domain) do
        table.insert(image, f(value))
    end

    return image
end

Collection.image_args = function(f, domain_tuples)
    local image = {}

    for _, tuple in pairs(domain_tuples) do
        table.insert(image, table.pack(f(table.unpack(tuple))))
    end

    return image
end

Collection.filter = function(predicate, list)
    local filtered = {}

    for k, v in pairs(list) do
        if predicate(v) then
            table.insert(filtered, v)
        end
    end

    return filtered
end

Collection.flat = function(list, depth)
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

Collection.group_by = function(key_fn, list)
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

Collection.partition = function(predicate, list)
    local filter, unfiltered = {}, {}

    for index, value in ipairs(list) do
        table.insert(predicate(value) and filter or unfiltered, value)
    end

    return filter, unfiltered
end

Collection.uniq = function(list)
    local sublist = {}
    local contains = {}

    for index, value in ipairs(list) do
        if not contains[value] then
            contains[value] = true
            table.insert(sublist, value)
        end
    end

    return sublist
end

Collection.map_domains = function(map)
    local domain, codomain = {}, {}

    for k, v in pairs(map) do
        table.insert(domain, k)
        table.insert(codomain, v)
    end

    return domain, codomain
end

Collection.zip = function(...)
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

Collection.unzip = function(zipped)
    local num_tuples = #zipped
    local tuple_size = #zipped[1]
    local unzipped = {}

    for i = 1, tuple_size do
        local i_unzipped = {}
        unzipped[i] = i_unzipped

        for j = 1, num_tuples do
            table.insert(i_unzipped, zipped[j][i])
        end
    end

    return unzipped
end


Collection.sorter = function(predicate)
    return function(list)
        return table.sort(list, predicate)
    end
end

Collection.reduce = function(predicate, list)
    local result = list[1]

    for i = 2, #list do
        result = predicate(result, list[i])
    end

    return result
end

Collection.transduce = function(trans, predicate, list)
    local result = trans(list[1])

    for index, value in ipairs(list) do
        result = predicate(result, trans(value))
    end

    return result
end

Collection.fold_l = function(predicate, idE, list)
    local result = idE

    for i = 1, #list do
        result = predicate(result, list[i])
    end

    return result
end

Collection.fold_r = function(predicate, idE, list)
    local result = idE

    for i = #list, 1, -1 do
        result = predicate(result, list[i])
    end

    return result
end

Collection.scan = function(predicate, idE, list)
    local scanned_l = {}
    local result = idE

    for i = 1, #list do
        result = predicate(result, list[i])
        table.insert(scanned_l, result)
    end

    return scanned_l
end

Collection.trans_fold_l = function(trans, predicate, ide, list)
    local result = ide

    for index, value in ipairs(list) do
        result = predicate(result, trans(value))
    end

    return result
end

Collection.trans_fold_r = function(trans, predicate, ide, list)
    local result = ide

    for i = #list, 1, -1 do
        result = predicate(result, trans(list[i]))
    end

    return result
end

Collection.unfold = function(generator, condition, seed)
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
    local curry = {}
    Collection.curry = curry

    curry.transducer = function(trans, predicate)
        return function(list)
            local result = trans(list[1])

            for index, value in ipairs(list) do
                result = predicate(result, trans(value))
            end

            return result
        end
    end

    curry.l_folder = function(predicate, idE)
        return function(list)
            local result = idE

            for i = 1, #list do
                result = predicate(result, list[i])
            end

            return result
        end
    end

    curry.r_folder = function(predicate, idE)
        return function(list)
            local result = idE

            for i = #list, 1, -1 do
                result = predicate(result, list[i])
            end

            return result
        end
    end

    curry.scanner = function(predicate, idE)
        return function(list)
            local scanned_l = {}
            local result = idE

            for i = 1, #list do
                result = predicate(result, list[i])
                table.insert(scanned_l, result)
            end

            return scanned_l
        end
    end
end

return Collection