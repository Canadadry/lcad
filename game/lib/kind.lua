local function SetType(table, type)
    setmetatable(table, { __type = type })
    return table
end

local function GetType(table)
    local mt = getmetatable(table)
    if mt == nil then
        return "'no metatable'"
    end
    if mt.__type == nil then
        return "'__type is nil'"
    end
    return mt.__type
end

local function IsOfType(table, type)
    return GetType(table) == type
end

local function CheckType(table, type)
    if type == nil then
        error("argument type should not be nil\n" .. debug.traceback())
    end
    if table ~= nil and not IsOfType(table, type) then
        error("expected table of " .. type .. " got " .. GetType(table) .. debug.traceback())
    end
    return table
end

local function Enum(typename, values)
    local enum = {}
    for _, value in ipairs(values) do
        local instance = setmetatable({ type = value }, {
            __type = typename,
            __tostring = function() return typename .. "." .. value end,
        })
        enum[value] = function()
            return instance
        end
    end
    enum.IsValid = function(table)
        return CheckType(table, typename)
    end
    return enum
end

return {
    Set = SetType,
    Get = GetType,
    Check = CheckType,
    Enum = Enum,
}
