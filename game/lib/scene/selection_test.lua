local selection = require("lib.scene.selection")
local mat4 = require("lib.math.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function approx(a, b, eps)
    return math.abs(a - b) < (eps or 1e-9)
end

test("new() starts idle with nothing selected", function()
    local sel = selection.new()

    eq(sel.dragging, false)
    eq(#sel.selected, 0)
end)

test("begin_drag() marks the selection as dragging and stashes the viewport it was given", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0 }

    selection.begin_drag(sel, vp, 10, 20)

    eq(sel.dragging, true)
    eq(sel.viewport, vp)
end)

test("begin_drag() converts a window-space point into viewport-local space by subtracting the viewport's offset", function()
    local sel = selection.new()

    selection.begin_drag(sel, { ox = 20, oy = 10 }, 25, 15)

    eq(sel.start.x, 5)
    eq(sel.start.y, 5)
    eq(sel.current.x, 5)
    eq(sel.current.y, 5)
end)

test("update_drag() converts a window-space point into the drag viewport's local space", function()
    local sel = selection.new()
    selection.begin_drag(sel, { ox = 20, oy = 10 }, 25, 15)

    selection.update_drag(sel, 45, 30)

    eq(sel.current.x, 25)
    eq(sel.current.y, 20)
end)

test("end_drag() selects vertex indices whose projection falls inside the drag rectangle, and stops dragging", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = {
        { -0.5, 0, 0 }, -- projects to (25, 50), inside
        { 0.5, 0, 0 },  -- projects to (75, 50), inside
        { 0.9, 0.9, 0 }, -- projects to (95, 5), outside
    }

    selection.begin_drag(sel, vp, 20, 40)
    selection.update_drag(sel, 80, 60)
    selection.end_drag(sel, vertices)

    eq(sel.dragging, false)
    eq(#sel.selected, 2)
    eq(sel.selected[1], 1)
    eq(sel.selected[2], 2)
end)

test("end_drag() replaces the previous selection rather than accumulating it", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = {
        { -0.5, 0, 0 }, -- (25, 50)
        { 0.5, 0, 0 },  -- (75, 50)
    }

    selection.begin_drag(sel, vp, 0, 40)
    selection.update_drag(sel, 50, 60)
    selection.end_drag(sel, vertices)
    eq(#sel.selected, 1)
    eq(sel.selected[1], 1)

    selection.begin_drag(sel, vp, 50, 40)
    selection.update_drag(sel, 100, 60)
    selection.end_drag(sel, vertices)

    eq(#sel.selected, 1)
    eq(sel.selected[1], 2)
end)

test("end_drag() normalizes the rectangle regardless of drag direction", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- (25, 50)

    -- dragged from bottom-right to top-left
    selection.begin_drag(sel, vp, 80, 60)
    selection.update_drag(sel, 20, 40)
    selection.end_drag(sel, vertices)

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
    selection.begin_drag(sel, { ox = 0, oy = 0, w = 100, h = 150 }, 10, 10)

    selection.update_drag(sel, -5, 200)

    eq(sel.current.x, 0)
    eq(sel.current.y, 150)
end)

test("is_near_selected() returns true when the point is within radius of a selected vertex's projection", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50)
    sel.selected = { 1 }

    eq(selection.is_near_selected(sel, vp, vertices, 27, 50, 3), true)
end)

test("is_near_selected() returns false when the point is outside radius of every selected vertex's projection", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50)
    sel.selected = { 1 }

    eq(selection.is_near_selected(sel, vp, vertices, 40, 50, 3), false)
end)

test("is_near_selected() returns false when nothing is selected", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50)

    eq(selection.is_near_selected(sel, vp, vertices, 25, 50, 3), false)
end)

test("is_near_selected() offsets the point by the viewport's screen offset before comparing", function()
    local sel = selection.new()
    local vp = { view = { view = mat4.identity(), projection = mat4.identity() }, ox = 200, oy = 100, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50) in viewport-local space
    sel.selected = { 1 }

    eq(selection.is_near_selected(sel, vp, vertices, 227, 150, 3), true)
end)

test("begin_move() marks the selection as moving, snapshots the selected vertices' positions in selection order, and captures their barycenter's depth", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0, view = { view = mat4.translate(0, 0, -5), projection = mat4.identity() } }
    local vertices = { { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 } }
    sel.selected = { 1, 3 }

    selection.begin_move(sel, vp, vertices, 10, 20)

    eq(sel.moving, true)
    eq(sel.move_origin[1][1], 1); eq(sel.move_origin[1][2], 2); eq(sel.move_origin[1][3], 3)
    eq(sel.move_origin[2][1], 7); eq(sel.move_origin[2][2], 8); eq(sel.move_origin[2][3], 9)

    -- barycenter of (1,2,3) and (7,8,9) is (4,5,6); translating by (0,0,-5) gives view-space z = 1
    eq(sel.move_depth, 1)
end)

test("update_move() converts the move-start and current screen points to world space at the captured depth, and applies their difference to every selected vertex from its snapshot", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0, w = 100, h = 100, view = { view = mat4.identity(), projection = mat4.identity() } }
    local vertices = { { 0, 0, 0 }, { 5, 5, 5 } }
    sel.selected = { 1, 2 }

    selection.begin_move(sel, vp, vertices, 10, 10)
    selection.update_move(sel, vertices, 60, 30)

    -- identity view/projection: screen_to_world(sx,sy) = ((sx/w)*2-1, 1-(sy/h)*2, depth)
    -- start (10,10) -> (-0.8, 0.8); current (60,30) -> (0.2, 0.4); delta = (1.0, -0.4, 0)
    eq(approx(vertices[1][1], 1.0), true, "v1 x")
    eq(approx(vertices[1][2], -0.4), true, "v1 y")
    eq(approx(vertices[1][3], 0), true, "v1 z")
    eq(approx(vertices[2][1], 6.0), true, "v2 x")
    eq(approx(vertices[2][2], 4.6), true, "v2 y")
    eq(approx(vertices[2][3], 5), true, "v2 z")
end)

test("end_move() stops moving", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0, view = { view = mat4.identity(), projection = mat4.identity() } }
    local vertices = { { 1, 2, 3 } }
    sel.selected = { 1 }

    selection.begin_move(sel, vp, vertices, 10, 20)
    selection.end_move(sel)

    eq(sel.moving, false)
end)

T.report()
