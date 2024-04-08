-- I am using lua 5.1 and this is one of the differences i found with the newest version and i want to ensure compatibility
table.unpack = table.unpack or unpack

local function loop(f, i, max, increment)
    increment = increment or 1

    local result = f(i)
    if i >= max or result ~= nil then
        return result
    end
    return loop(f, i + increment, max, increment)
end

local function return_after_condition_met(has_to_return)
    return function (condition)
        return function (condition_met, return_value)
            return function (tab, ...)
                local return_tab = {}
                local other_args = {...}
                local loop_result = loop(function (i)
                    local v = tab[i]
                    if condition(v, i, other_args, tab) then
                        local success_result = condition_met(v, i, other_args, tab, return_tab)
                        if has_to_return then
                            return success_result
                        end
                    end
                end, 1, #tab)
                return loop_result or return_value(tab, return_tab)
            end
        end
    end
end

local function return_true()
    return true
end
local function return_false()
    return false
end

-- only use this as "return_value" because of the different arguments
local function return_final_tab(_, return_tab)
    return return_tab
end

local empty_func = return_false

table.every = return_after_condition_met(true)(function (v, i, function_arguments)
    local f = function_arguments[1]
    return not f(v, i)
end)(return_false, return_true)

table.filter = return_after_condition_met(false)(function (v, i, function_arguments)
    local f = function_arguments[1]
    return f(v, i)
end)(function (v, _, _, _, return_tab)
    table.insert(return_tab, v)
end, return_final_tab)

table.map = return_after_condition_met(false)(return_true)(function (v, i, function_arguments, _, return_tab)
    local f = function_arguments[1]
    table.insert(return_tab, f(v, i))
end, return_final_tab)

table.find = return_after_condition_met(true)(function (v, i, function_arguments)
    local f = function_arguments[1]
    return f(v, i)
end)(function (v, i)
    return v, i
end, return_false)

table.flat = function (tab, depth)
    depth = depth or math.huge
    local return_tab = {};
    local function nested(interior_tab, interior_depth)
        for _, v in pairs(interior_tab) do
            if type(v) == "table" and interior_depth > 0 then
                nested(v, interior_depth - 1)
            else
                table.insert(return_tab, v)
            end
        end
    end
    nested(tab, depth)
    return return_tab
end

table.includes = return_after_condition_met(true)(function (v, _, function_arguments)
    local element = function_arguments[1]
    return element == v
end)(return_true, return_false)

table.indexOf = return_after_condition_met(true)(function (v, _, function_arguments)
    local element = function_arguments[1]
    return element == v
end)(function (_, i)
    return i
end, function ()
    return -1
end)

table.flatMap = function (tab, f)
    return table.flat(table.map(tab, f), 1)
end

table.reduce = return_after_condition_met(false)(return_true)(function (v, i, function_arguments, tab, accumulator)
    local f = function_arguments[1]
    local accumulator_value = accumulator[1] or function_arguments[2] or tab[1]
    accumulator[1] = f(accumulator_value, v, i)
end, function (_, accumulator)
    return accumulator[1]
end)

table.some = return_after_condition_met(true)(function (v, i, function_arguments)
    local f = function_arguments[1]
    return f(v, i)
end)(return_true, return_false)

table.foreach = return_after_condition_met(false)(return_true)(function (v, i, function_arguments)
    local f = function_arguments[1]
    f(v, i)
end, empty_func)

local function are_equal(a, b)
    if type(a) ~= type(b) or type(a) ~= "table" then
        return a == b
    end
    if #a ~= #b then
        return false
    end
    for i, v in pairs(a) do
        if type(v) == "table" then
            if not are_equal(v, b[i]) then
                return false
            end
        else
            if v ~= b[i] then
                return false
            end
        end
    end
    return true
end

local function toString(x)
    local return_self = {"number", "string", "boolean", "function"}
    if type(x) == "nil" then return nil end
    if table.includes(return_self, type(x)) then return tostring(x) end

    local result = "{"
    for i, v in pairs(x) do
        result = result .. "  " .. toString(v)
    end
    return result.."  }"
end

local function test(f, args, expected_resut)
    local result = f(table.unpack(args))
    print("Expected result " .. toString(expected_resut), "got " .. toString(result))
    if not are_equal(result, expected_resut) then
        print("ERROR")
    end
end




return table