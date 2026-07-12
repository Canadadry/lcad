local perspective = require("lib.view.perspective")
local mat4 = require("lib.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function approx(a, b, eps)
    return math.abs(a - b) < (eps or 1e-9)
end

test("move_delta() returns an object-space delta that reproduces the same screen-space delta when re-projected, at the object's local origin", function()
    local v = perspective(100, 100)
    local model = mat4.identity()
    local vertex = { 0, 0, 0 }
    local mvp = v:mvp(model)
    local ox, oy = mat4.project(mvp, vertex, 100, 100)

    local d = v:move_delta(model, 100, 100, 50, 20)
    vertex[1] = vertex[1] + d[1]
    vertex[2] = vertex[2] + d[2]
    vertex[3] = vertex[3] + d[3]

    local nx, ny = mat4.project(mvp, vertex, 100, 100)
    eq(approx(nx - ox, 50), true, "screen dx")
    eq(approx(ny - oy, 20), true, "screen dy")
end)

test("move_delta() accounts for the current model rotation, still reproducing the same screen-space delta", function()
    local v = perspective(100, 100)
    local model = mat4.rotate_y(math.pi / 2)
    local vertex = { 0, 0, 0 }
    local mvp = v:mvp(model)
    local ox, oy = mat4.project(mvp, vertex, 100, 100)

    local d = v:move_delta(model, 100, 100, 50, 20)
    vertex[1] = vertex[1] + d[1]
    vertex[2] = vertex[2] + d[2]
    vertex[3] = vertex[3] + d[3]

    local nx, ny = mat4.project(mvp, vertex, 100, 100)
    eq(approx(nx - ox, 50), true, "screen dx")
    eq(approx(ny - oy, 20), true, "screen dy")
end)

T.report()
