local selection = require("lib.scene.selection")
local mat4 = require("lib.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function view_with_mvp(mvp)
    return { mvp = function(_, model) return mvp end }
end

test("new() starts idle with nothing selected", function()
    local sel = selection.new()

    eq(sel.dragging, false)
    eq(#sel.selected, 0)
end)

test("begin_drag() marks the selection as dragging", function()
    local sel = selection.new()

    selection.begin_drag(sel, { ox = 0, oy = 0 }, 10, 20)

    eq(sel.dragging, true)
end)

test("begin_drag() converts a window-space point into viewport-local space by subtracting the viewport's offset", function()
    local sel = selection.new()

    selection.begin_drag(sel, { ox = 20, oy = 10 }, 25, 15)

    eq(sel.start.x, 5)
    eq(sel.start.y, 5)
    eq(sel.current.x, 5)
    eq(sel.current.y, 5)
end)

test("update_drag() converts a window-space point into viewport-local space by subtracting the viewport's offset", function()
    local sel = selection.new()
    local vp = { ox = 20, oy = 10 }
    selection.begin_drag(sel, vp, 25, 15)

    selection.update_drag(sel, vp, 45, 30)

    eq(sel.current.x, 25)
    eq(sel.current.y, 20)
end)

test("draw() outlines the drag rectangle between start and current point while dragging", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0 }
    selection.begin_drag(sel, vp, 10, 20)
    selection.update_drag(sel, vp, 30, 50)

    local lines = {}
    selection.draw(sel, vp, {}, nil, function(x1, y1, x2, y2)
        table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 })
    end, function() error("drawCircle should not be called while dragging") end)

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

test("draw() offsets the in-progress drag rectangle by the viewport's screen offset", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(nil), ox = 200, oy = 100 }
    selection.begin_drag(sel, vp, 210, 120)
    selection.update_drag(sel, vp, 230, 150)

    local lines = {}
    selection.draw(sel, vp, {}, nil, function(x1, y1, x2, y2)
        table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 })
    end, function() error("drawCircle should not be called while dragging") end)

    eq(lines[1].x1, 210); eq(lines[1].y1, 120)
    eq(lines[2].x2, 230); eq(lines[2].y2, 150)
end)

test("draw() emits nothing when idle with no selection", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(nil), ox = 0, oy = 0, w = 100, h = 100 }

    selection.draw(sel, vp, {}, nil,
        function() error("drawLine should not be called") end,
        function() error("drawCircle should not be called") end)
end)

test("end_drag() selects vertex indices whose projection falls inside the drag rectangle, and stops dragging", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = {
        { -0.5, 0, 0 }, -- projects to (25, 50), inside
        { 0.5, 0, 0 },  -- projects to (75, 50), inside
        { 0.9, 0.9, 0 }, -- projects to (95, 5), outside
    }

    selection.begin_drag(sel, vp, 20, 40)
    selection.update_drag(sel, vp, 80, 60)
    selection.end_drag(sel, vp, vertices, nil)

    eq(sel.dragging, false)
    eq(#sel.selected, 2)
    eq(sel.selected[1], 1)
    eq(sel.selected[2], 2)
end)

test("draw() draws a circle above each selected vertex's screen position, and no drag rectangle", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = {
        { -0.5, 0, 0 }, -- projects to (25, 50)
        { 0.5, 0, 0 },  -- projects to (75, 50)
    }
    selection.begin_drag(sel, vp, 20, 40)
    selection.update_drag(sel, vp, 80, 60)
    selection.end_drag(sel, vp, vertices, nil)

    local circles = {}
    selection.draw(sel, vp, vertices, nil,
        function() error("drawLine should not be called once selection is settled") end,
        function(x, y) table.insert(circles, { x = x, y = y }) end)

    eq(#circles, 2)
    eq(circles[1].x, 25); eq(circles[1].y, 50)
    eq(circles[2].x, 75); eq(circles[2].y, 50)
end)

test("draw() offsets the drag rectangle and the selected-vertex markers by the viewport's screen offset", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 200, oy = 100, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- local (25, 50) -> screen (225, 150)
    selection.begin_drag(sel, vp, 220, 140)
    selection.update_drag(sel, vp, 280, 160)
    selection.end_drag(sel, vp, vertices, nil)

    local circles = {}
    selection.draw(sel, vp, vertices, nil,
        function() error("drawLine should not be called once selection is settled") end,
        function(x, y) table.insert(circles, { x = x, y = y }) end)

    eq(#circles, 1)
    eq(circles[1].x, 225)
    eq(circles[1].y, 150)
end)

test("end_drag() replaces the previous selection rather than accumulating it", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = {
        { -0.5, 0, 0 }, -- (25, 50)
        { 0.5, 0, 0 },  -- (75, 50)
    }

    selection.begin_drag(sel, vp, 0, 40)
    selection.update_drag(sel, vp, 50, 60)
    selection.end_drag(sel, vp, vertices, nil)
    eq(#sel.selected, 1)
    eq(sel.selected[1], 1)

    selection.begin_drag(sel, vp, 50, 40)
    selection.update_drag(sel, vp, 100, 60)
    selection.end_drag(sel, vp, vertices, nil)

    eq(#sel.selected, 1)
    eq(sel.selected[1], 2)
end)

test("end_drag() normalizes the rectangle regardless of drag direction", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- (25, 50)

    -- dragged from bottom-right to top-left
    selection.begin_drag(sel, vp, 80, 60)
    selection.update_drag(sel, vp, 20, 40)
    selection.end_drag(sel, vp, vertices, nil)

    eq(#sel.selected, 1)
    eq(sel.selected[1], 1)
end)

test("begin_drag() clamps the start point into [0,w]x[0,h] when bounds are given", function()
    local sel = selection.new()

    selection.begin_drag(sel, { ox = 0, oy = 0, w = 100, h = 150 }, -5, 200)

    eq(sel.start.x, 0)
    eq(sel.start.y, 150)
    eq(sel.current.x, 0)
    eq(sel.current.y, 150)
end)

test("update_drag() clamps the current point into [0,w]x[0,h] when bounds are given", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0, w = 100, h = 150 }
    selection.begin_drag(sel, vp, 10, 10)

    selection.update_drag(sel, vp, -5, 200)

    eq(sel.current.x, 0)
    eq(sel.current.y, 150)
end)

T.report()
