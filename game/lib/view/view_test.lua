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

test("new() stores name, view and projection", function()
    local viewMatrix, projection = mat4.identity(), mat4.rotate_y(1)
    local v = view.new("test", viewMatrix, projection)

    eq(v.name, "test")
    eq(v.view, viewMatrix)
    eq(v.projection, projection)
end)

test("mvp() composes projection * view * model", function()
    local v = view.new("test", mat4.translate(1, 0, 0), mat4.scale(2))

    local mvp = v:mvp(mat4.identity())

    eq_mat(mvp, mat4.mul(mat4.scale(2), mat4.mul(mat4.translate(1, 0, 0), mat4.identity())))
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

test("draw() renders the mesh in white then the gizmo axes in their own colors, resetting to white after each", function()
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

    v:draw(m, mat4.identity(), 2, 2, setColor, drawLine)

    -- 1 white for the mesh, then (color, white) per gizmo axis
    eq(#colorCalls, 1 + 3 * 2)
    eq(colorCalls[1], colors.RealWhite)
    eq(colorCalls[2], colors.Red)
    eq(colorCalls[3], colors.RealWhite)
    eq(colorCalls[4], colors.Green)
    eq(colorCalls[5], colors.RealWhite)
    eq(colorCalls[6], colors.Blue)
    eq(colorCalls[7], colors.RealWhite)

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
    v:draw_selected(m, { 1, 2 }, mat4.identity(), 100, 100, function(x, y)
        table.insert(circles, { x = x, y = y })
    end)

    eq(#circles, 2)
    eq(circles[1].x, 25); eq(circles[1].y, 50)
    eq(circles[2].x, 75); eq(circles[2].y, 50)
end)

T.report()
