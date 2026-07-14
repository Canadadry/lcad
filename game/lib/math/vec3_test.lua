local vec3 = require("lib.math.vec3")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("barycenter() averages a single point onto itself", function()
    local b = vec3.barycenter({ { 1, 2, 3 } })

    eq(b[1], 1); eq(b[2], 2); eq(b[3], 3)
end)

test("barycenter() averages multiple points component-wise", function()
    local b = vec3.barycenter({ { 0, 0, 0 }, { 5, 5, 5 }, { 1, -2, 4 } })

    eq(b[1], 2); eq(b[2], 1); eq(b[3], 3)
end)

T.report()
