local view = require("lib.view.view")
local mesh = require("lib.scene.mesh")
local mat4 = require("lib.mat4")
local colors = require("lib.colors")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function eq_mat(a, b)
    eq(#a, #b)
    for i = 1, #a do
        eq(a[i], b[i], "element " .. i)
    end
end

local function approx(a, b, eps)
    return math.abs(a - b) < (eps or 1e-9)
end

test("new() stores name, view and projection", function()
    local viewMatrix, projection = mat4.identity(), mat4.rotate_y(1)
    local v = view.new("test", viewMatrix, projection)

    eq(v.name, "test")
    eq(v.view, viewMatrix)
    eq(v.projection, projection)
end)

test("world_to_screen() projects a point through the view's own mvp", function()
    local v = view.new("test", mat4.identity(), mat4.identity())

    local x, y = v:world_to_screen({ 0.5, 0, 0 }, 100, 100)

    eq(x, 75); eq(y, 50)
end)

test("depth_of() returns the view-space z of a point", function()
    local v = view.new("test", mat4.translate(0, 0, -5), mat4.identity())

    local z = v:depth_of({ 0, 0, 0 })

    eq(z, -5)
end)

test("screen_to_world() is the inverse of world_to_screen(): a point's own screen position and depth convert back to itself, for an orthographic projection", function()
    local v = view.new("test", mat4.identity(), mat4.orthographic(-1, 1, -1, 1, 0.1, 100))
    local point = { 0.3, -0.2, 0.1 }

    local sx, sy = v:world_to_screen(point, 100, 100)
    local depth = v:depth_of(point)
    local x, y, z = v:screen_to_world(sx, sy, depth, 100, 100)

    eq(approx(x, point[1]), true, "x")
    eq(approx(y, point[2]), true, "y")
    eq(approx(z, point[3]), true, "z")
end)

test("screen_to_world() is the inverse of world_to_screen(), for a perspective projection with a rotated and translated camera", function()
    local v = view.new("test", mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 }), mat4.perspective(math.rad(60), 1, 0.1, 100))
    local point = { 0.3, -0.2, 0.1 }

    local sx, sy = v:world_to_screen(point, 100, 100)
    local depth = v:depth_of(point)
    local x, y, z = v:screen_to_world(sx, sy, depth, 100, 100)

    eq(approx(x, point[1]), true, "x")
    eq(approx(y, point[2]), true, "y")
    eq(approx(z, point[3]), true, "z")
end)

test("screen_to_world() ignores depth for an orthographic projection", function()
    local v = view.new("test", mat4.identity(), mat4.orthographic(-1, 1, -1, 1, 0.1, 100))

    local nx, ny = v:screen_to_world(60, 40, 1, 100, 100)
    local fx, fy = v:screen_to_world(60, 40, 999, 100, 100)

    eq(approx(nx, fx), true, "x")
    eq(approx(ny, fy), true, "y")
end)

test("mvp() composes projection * view", function()
    local v = view.new("test", mat4.translate(1, 0, 0), mat4.scale(2))

    local mvp = v:mvp()

    eq_mat(mvp, mat4.mul(mat4.scale(2), mat4.translate(1, 0, 0)))
end)

test("viewport_at() resolves to itself covering the full canvas, regardless of the point", function()
    local v = view.new("test", mat4.identity(), mat4.identity())

    local vp = view.viewport_at(v, 30, 40, 100, 80)

    eq(vp.view, v)
    eq(vp.ox, 0)
    eq(vp.oy, 0)
    eq(vp.w, 100)
    eq(vp.h, 80)
end)

test("draw() renders the mesh in white then the gizmo axes in their own colors, resetting to white once at the end", function()
    local v = view.new("test", mat4.identity(), mat4.identity())
    local m = mesh.new(
        { { 0, 0, 0 }, { 1, 0, 0 } },
        {},
        { { 1, 2 } }
    )

    local colorCalls = {}
    local lineCalls = 0
    local setColor = function(c) table.insert(colorCalls, c) end
    local drawLine = function() lineCalls = lineCalls + 1 end

    v:draw(m, 2, 2, setColor, drawLine)

    -- 1 white for the mesh, then 1 color per gizmo axis, then 1 white reset at the end
    eq(#colorCalls, 1 + 3 + 1)
    eq(colorCalls[1], colors.RealWhite)
    eq(colorCalls[2], colors.Red)
    eq(colorCalls[3], colors.Green)
    eq(colorCalls[4], colors.Blue)
    eq(colorCalls[5], colors.RealWhite)

    -- the 2-vertex face draws 2 edges (a->b and b->a) + 3 gizmo axis lines
    eq(lineCalls, 5)
end)

test("draw_selected() draws a circle for each selected vertex, projected through the view's own mvp", function()
    local v = view.new("test", mat4.identity(), mat4.identity())
    local m = mesh.new(
        { { -0.5, 0, 0 }, { 0.5, 0, 0 } },
        {}, {}
    )

    local circles = {}
    v:draw_selected(m, { 1, 2 }, 100, 100, function(x, y)
        table.insert(circles, { x = x, y = y })
    end)

    eq(#circles, 2)
    eq(circles[1].x, 25); eq(circles[1].y, 50)
    eq(circles[2].x, 75); eq(circles[2].y, 50)
end)

T.report()
