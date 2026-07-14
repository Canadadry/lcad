local gizmo = require("lib.hud.gizmo")
local colors = require("lib.colors")
local mat4 = require("lib.math.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("draw() draws one line per axis directly via love.graphics, tipped at (1,0,0), (0,1,0), (0,0,1) and colored red/green/blue", function()
    local mvp = mat4.identity()
    local colorCalls = {}
    local lineCalls = {}
    love.graphics.setColor = function(c) table.insert(colorCalls, c) end
    love.graphics.line = function(x1, y1, x2, y2) table.insert(lineCalls, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }) end

    gizmo.draw(mvp, 2, 2)

    eq(#lineCalls, 3)
    eq(#colorCalls, 3)

    eq(lineCalls[1].x2, 2)
    eq(lineCalls[1].y2, 1)
    eq(colorCalls[1], colors.Red)

    eq(lineCalls[2].x2, 1)
    eq(lineCalls[2].y2, 0)
    eq(colorCalls[2], colors.Green)

    eq(lineCalls[3].x2, 1)
    eq(lineCalls[3].y2, 1)
    eq(colorCalls[3], colors.Blue)
end)

test("draw() scales the axis tips by the given length", function()
    local mvp = mat4.identity()
    local lineCalls = {}
    love.graphics.setColor = function() end
    love.graphics.line = function(x1, y1, x2, y2) table.insert(lineCalls, { x2 = x2, y2 = y2 }) end

    gizmo.draw(mvp, 2, 2, 0.5)

    eq(lineCalls[1].x2, 1.5)
    eq(lineCalls[1].y2, 1)
end)

T.report()
