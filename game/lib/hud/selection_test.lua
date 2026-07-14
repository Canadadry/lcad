local hud_selection = require("lib.hud.selection")
local selection = require("lib.scene.selection")
local mesh = require("lib.scene.mesh")
local mat4 = require("lib.math.mat4")
local colors = require("lib.colors")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("draw() draws a circle at the screen position of each selected vertex, projected through the given mvp, in the given color", function()
    local mvp = mat4.identity()
    local m = mesh.new({ { -0.5, 0, 0 }, { 0.5, 0, 0 } }, {}, {})
    local sel = selection.new()
    sel.selected = { 1, 2 }
    local v = {}

    local circles = {}
    local colorCalls = {}
    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function(c) table.insert(colorCalls, c) end
    love.graphics.circle = function(mode, x, y, radius) table.insert(circles, { mode = mode, x = x, y = y, radius = radius }) end

    hud_selection.draw(v, m, sel, mvp, 100, 100, 3, colors.Yellow)

    eq(#circles, 2)
    eq(circles[1].mode, "line")
    eq(circles[1].x, 25); eq(circles[1].y, 50); eq(circles[1].radius, 3)
    eq(circles[2].x, 75); eq(circles[2].y, 50); eq(circles[2].radius, 3)

    -- sets the given color before drawing, then restores whatever was set before
    eq(colorCalls[1], colors.Yellow)
    eq(colorCalls[2][1], 1); eq(colorCalls[2][2], 1); eq(colorCalls[2][3], 1); eq(colorCalls[2][4], 1)
end)

test("draw() draws nothing for an empty selection", function()
    local m = mesh.new({ { 0, 0, 0 } }, {}, {})
    local sel = selection.new()

    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function() end
    love.graphics.circle = function() error("love.graphics.circle should not be called") end

    hud_selection.draw({}, m, sel, mat4.identity(), 100, 100, 3, colors.Yellow)
end)

test("draw() outlines the drag rectangle in viewport-local coordinates when the given view matches the dragging viewport's view", function()
    local m = mesh.new({}, {}, {})
    local v = {}
    local sel = selection.new()
    selection.begin_drag(sel, { view = v, ox = 0, oy = 0 }, 10, 20)
    selection.update_drag(sel, 30, 50)

    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function() end
    local lines = {}
    love.graphics.line = function(x1, y1, x2, y2) table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }) end

    hud_selection.draw(v, m, sel, mat4.identity(), 100, 100, 3, colors.Yellow)

    eq(#lines, 4)
    -- top edge
    eq(lines[1].x1, 10); eq(lines[1].y1, 20); eq(lines[1].x2, 30); eq(lines[1].y2, 20)
    -- right edge
    eq(lines[2].x1, 30); eq(lines[2].y1, 20); eq(lines[2].x2, 30); eq(lines[2].y2, 50)
    -- bottom edge
    eq(lines[3].x1, 30); eq(lines[3].y1, 50); eq(lines[3].x2, 10); eq(lines[3].y2, 50)
    -- left edge
    eq(lines[4].x1, 10); eq(lines[4].y1, 50); eq(lines[4].x2, 10); eq(lines[4].y2, 20)
end)

test("draw() draws no rectangle for a view that isn't the one being dragged in", function()
    local m = mesh.new({}, {}, {})
    local draggingView, otherView = {}, {}
    local sel = selection.new()
    selection.begin_drag(sel, { view = draggingView, ox = 0, oy = 0 }, 10, 20)
    selection.update_drag(sel, 30, 50)

    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function() end
    love.graphics.line = function() error("love.graphics.line should not be called") end

    hud_selection.draw(otherView, m, sel, mat4.identity(), 100, 100, 3, colors.Yellow)
end)

test("draw() draws no rectangle while idle", function()
    local m = mesh.new({}, {}, {})
    local v = {}
    local sel = selection.new()

    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function() end
    love.graphics.line = function() error("love.graphics.line should not be called") end

    hud_selection.draw(v, m, sel, mat4.identity(), 100, 100, 3, colors.Yellow)
end)

test("draw() draws no rectangle once the drag has ended", function()
    local m = mesh.new({}, {}, {})
    local v = {}
    local sel = selection.new()
    selection.begin_drag(sel, { view = v, ox = 0, oy = 0 }, 20, 40)
    selection.update_drag(sel, 80, 60)
    selection.end_drag(sel, {})

    love.graphics.getColor = function() return 1, 1, 1, 1 end
    love.graphics.setColor = function() end
    love.graphics.line = function() error("love.graphics.line should not be called once the drag has ended") end

    hud_selection.draw(v, m, sel, mat4.identity(), 100, 100, 3, colors.Yellow)
end)

T.report()
