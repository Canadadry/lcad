local gizmo = require("lib.scene.gizmo")
local colors = require("lib.colors")
local mat4 = require("lib.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("draw() emits one line per axis, tipped at (1,0,0), (0,1,0), (0,0,1) and colored red/green/blue", function()
    local mvp = mat4.identity()
    local calls = {}
    gizmo.draw(mvp, 2, 2, function(x1, y1, x2, y2, color)
        table.insert(calls, { x1 = x1, y1 = y1, x2 = x2, y2 = y2, color = color })
    end)

    eq(#calls, 3)

    eq(calls[1].x2, 2)
    eq(calls[1].y2, 1)
    eq(calls[1].color, colors.Red)

    eq(calls[2].x2, 1)
    eq(calls[2].y2, 0)
    eq(calls[2].color, colors.Green)

    eq(calls[3].x2, 1)
    eq(calls[3].y2, 1)
    eq(calls[3].color, colors.Blue)
end)

test("draw() scales the axis tips by the given length", function()
    local mvp = mat4.identity()
    local calls = {}
    gizmo.draw(mvp, 2, 2, function(x1, y1, x2, y2, color)
        table.insert(calls, { x2 = x2, y2 = y2 })
    end, 0.5)

    eq(calls[1].x2, 1.5)
    eq(calls[1].y2, 1)
end)

T.report()
