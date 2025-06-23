local fua = {}

fua.fill = table.create
fua.clone = table.clone

function fua.is_equal(x, y, prev_x_i, prev_y_i)
    local different_types = type(x) ~= type(y)
    if different_types then
        return false
    end

    if type(x) ~= "table" then
        return x == y
    end

    local x_i, x_v = next(x, prev_x_i)
    local y_i, y_v = next(y, prev_y_i)

    local is_empty = not x_i and not y_i
    if is_empty then
        return true
    end

    return fua.is_equal(x_v, y_v) and fua.is_equal(x, y, x_i, y_i)
end

function fua.for_each(f, array, previous)
    local i, v = next(array, previous)

    if not i then
        return
    end

    f(v, i, array)

    return fua.for_each(f, array, i)
end

function fua.curry(arguments_amount, f, arguments)
    arguments = arguments or {}
    return function(arg)
        table.insert(arguments, arg)
        if arguments_amount <= 1 then
            return f(unpack(arguments))
        end
        return fua.curry(arguments_amount - 1, f, arguments)
    end
end

function fua.reduce(f, accumulator, array, previous)
    local i, v = next(array, previous)
    if not i then
        return accumulator
    end

    return fua.reduce(f, f(accumulator, v, i, array), array, i)
end

function fua.map(f, array)
    local function map(result, v, i, array)
        result[i] = f(v, i, array)
        return result
    end

    return fua.reduce(map, {}, array)
end

function fua.filter(p, array)
    local function filter(result, v, i, array)
        if p(v, i, array) then
            if #array == 0 then
                result[i] = v
            else
                table.insert(result, v)
            end
        end
        return result
    end

    return fua.reduce(filter, {}, array)
end

function fua.pipe(start, ...)
    local fs = {...}
    if #fs == 0 then
        return start
    end

    fs[1] = fs[1](start)

    return fua.pipe(unpack(fs))
end

function fua.every(p, array)
    local function satisfies(result, v, i, array)
        return result and p(v, i, array)
    end
    return fua.reduce(satisfies, true, array)
end

function fua.find(p, array)
    local function satisfies(result, v, i, array)
        if result ~= nil then
            return result
        elseif p(v, i, array) then
            return {v, i}
        else
            return nil
        end
    end

    return unpack(fua.reduce(satisfies, nil, array) or {})
end

function fua.insert_all(values, array, prev_i)
    local i, v = next(values, prev_i)
    if not i then
        return array
    end
    table.insert(array, v)
    return fua.insert_all(values, array, i)
end

function fua.flat(depth, array)
    local function flatten(result, v)
        if (type(v) ~= "table") or (depth == 0) then
            table.insert(result, v)
            return result
        else
            return fua.insert_all(fua.flat(depth - 1, v), result)
        end
    end

    return fua.reduce(flatten, {}, array)
end

function fua.includes(array, target)
    local function equal(value)
        return target == value
    end
    return fua.find(equal, array) ~= nil
end

function fua.flat_map(f, array)
    return fua.pipe(
        array,
        fua.curry(2, fua.map)(f),
        fua.curry(2, fua.flat)(1)
    )
end

function fua.some(p, array)
    local function satisfies(result, v, i, array)
        return result or p(v, i, array)
    end
    return fua.reduce(satisfies, false, array)
end

return fua