local M = {}

function M.new(x,y,z)
    return {x,y,z}
end

function M.sub(a, b)
    return M.new( a[1] - b[1], a[2] - b[2], a[3] - b[3] )
end

function M.cross(a, b)
    return M.new(
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1]
    )
end

function M.dot(a, b)
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

function M.normalize(a)
    local len = math.sqrt(M.dot(a, a))
    return M.new( a[1] / len, a[2] / len, a[3] / len )
end


return M
