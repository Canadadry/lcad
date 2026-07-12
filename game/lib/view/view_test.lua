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

T.report()
