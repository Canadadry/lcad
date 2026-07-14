local wireframe = require("lib.render.wireframe")
local mesh = require("lib.scene.mesh")
local mat4 = require("lib.math.mat4")
local colors = require("lib.colors")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("draw() draws one line per edge of every face directly via love.graphics, in the given color", function()
    local m = mesh.new(
        { { -0.5, 0, 0 }, { 0.5, 0, 0 }, { 0, 0.5, 0 } },
        {},
        { { 1, 2, 3 } }
    )
    local mvp = mat4.identity()

    local lines = {}
    local colorCalls = {}
    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function(c) table.insert(colorCalls, c) end
    love.graphics.line = function(x1, y1, x2, y2) table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }) end

    wireframe.draw(m, mvp, 100, 100, colors.RealWhite)

    -- 1 triangle face draws 3 edges
    eq(#lines, 3)
    eq(lines[1].x1, 25); eq(lines[1].y1, 50)
    eq(lines[1].x2, 75); eq(lines[1].y2, 50)

    -- sets the given color before drawing, then restores whatever was set before
    eq(colorCalls[1], colors.RealWhite)
    eq(colorCalls[2][1], 1); eq(colorCalls[2][2], 1); eq(colorCalls[2][3], 1); eq(colorCalls[2][4], 1)
end)

T.report()
