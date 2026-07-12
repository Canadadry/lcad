local selection = require("lib.scene.selection")
local mat4 = require("lib.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function view_with_mvp(mvp)
    return {
        world_to_screen = function(_, point, w, h)
            return mat4.project(mvp, point, w, h)
        end,
    }
end

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

test("draw() outlines the drag rectangle between start and current point while dragging", function()
    local sel = selection.new()
    selection.begin_drag(sel, { ox = 0, oy = 0 }, 10, 20)
    selection.update_drag(sel, 30, 50)

    local lines = {}
    selection.draw(sel, function(x1, y1, x2, y2)
        table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 })
    end)

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

test("draw() offsets the in-progress drag rectangle by the drag viewport's screen offset", function()
    local sel = selection.new()
    selection.begin_drag(sel, { ox = 200, oy = 100 }, 210, 120)
    selection.update_drag(sel, 230, 150)

    local lines = {}
    selection.draw(sel, function(x1, y1, x2, y2)
        table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 })
    end)

    eq(lines[1].x1, 210); eq(lines[1].y1, 120)
    eq(lines[2].x2, 230); eq(lines[2].y2, 150)
end)

test("draw() emits nothing when idle", function()
    local sel = selection.new()

    selection.draw(sel, function() error("drawLine should not be called") end)
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
    selection.update_drag(sel, 80, 60)
    selection.end_drag(sel, vertices)

    eq(sel.dragging, false)
    eq(#sel.selected, 2)
    eq(sel.selected[1], 1)
    eq(sel.selected[2], 2)
end)

test("draw() draws no rectangle once the drag has ended", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    selection.begin_drag(sel, vp, 20, 40)
    selection.update_drag(sel, 80, 60)
    selection.end_drag(sel, {})

    selection.draw(sel, function() error("drawLine should not be called once the drag has ended") end)
end)

test("end_drag() replaces the previous selection rather than accumulating it", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
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
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
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
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50)
    sel.selected = { 1 }

    eq(selection.is_near_selected(sel, vp, vertices, 27, 50, 3), true)
end)

test("is_near_selected() returns false when the point is outside radius of every selected vertex's projection", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50)
    sel.selected = { 1 }

    eq(selection.is_near_selected(sel, vp, vertices, 40, 50, 3), false)
end)

test("is_near_selected() returns false when nothing is selected", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 0, oy = 0, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50)

    eq(selection.is_near_selected(sel, vp, vertices, 25, 50, 3), false)
end)

test("is_near_selected() offsets the point by the viewport's screen offset before comparing", function()
    local sel = selection.new()
    local vp = { view = view_with_mvp(mat4.identity()), ox = 200, oy = 100, w = 100, h = 100 }
    local vertices = { { -0.5, 0, 0 } } -- projects to (25, 50) in viewport-local space
    sel.selected = { 1 }

    eq(selection.is_near_selected(sel, vp, vertices, 227, 150, 3), true)
end)

test("begin_move() marks the selection as moving, snapshots the selected vertices' positions in selection order, and captures their barycenter's depth", function()
    local sel = selection.new()
    local depth_calls = {}
    local view = {
        depth_of = function(v, point)
            depth_calls[#depth_calls + 1] = { point[1], point[2], point[3] }
            return 42
        end,
    }
    local vp = { ox = 0, oy = 0, view = view }
    local vertices = { { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 } }
    sel.selected = { 1, 3 }

    selection.begin_move(sel, vp, vertices, 10, 20)

    eq(sel.moving, true)
    eq(sel.move_origin[1][1], 1); eq(sel.move_origin[1][2], 2); eq(sel.move_origin[1][3], 3)
    eq(sel.move_origin[2][1], 7); eq(sel.move_origin[2][2], 8); eq(sel.move_origin[2][3], 9)

    eq(#depth_calls, 1)
    eq(depth_calls[1][1], 4); eq(depth_calls[1][2], 5); eq(depth_calls[1][3], 6)
    eq(sel.move_depth, 42)
end)

test("update_move() converts the move-start and current screen points to world space at the captured depth, and applies their difference to every selected vertex from its snapshot", function()
    local sel = selection.new()
    local calls = {}
    local view = {
        depth_of = function() return 42 end,
        screen_to_world = function(v, sx, sy, depth, w, h)
            calls[#calls + 1] = { sx = sx, sy = sy, depth = depth, w = w, h = h }
            if sx == 10 and sy == 10 then
                return 0, 0, 0
            end
            return 1, -2, 3
        end,
    }
    local vp = { ox = 0, oy = 0, w = 100, h = 100, view = view }
    local vertices = { { 0, 0, 0 }, { 5, 5, 5 } }
    sel.selected = { 1, 2 }

    selection.begin_move(sel, vp, vertices, 10, 10)
    selection.update_move(sel, vertices, 60, 30)

    eq(#calls, 2)
    eq(calls[1].sx, 10); eq(calls[1].sy, 10); eq(calls[1].depth, 42); eq(calls[1].w, 100); eq(calls[1].h, 100)
    eq(calls[2].sx, 60); eq(calls[2].sy, 30); eq(calls[2].depth, 42); eq(calls[2].w, 100); eq(calls[2].h, 100)

    eq(vertices[1][1], 1); eq(vertices[1][2], -2); eq(vertices[1][3], 3)
    eq(vertices[2][1], 6); eq(vertices[2][2], 3); eq(vertices[2][3], 8)
end)

test("end_move() stops moving", function()
    local sel = selection.new()
    local vp = { ox = 0, oy = 0, view = { depth_of = function() return 0 end } }
    local vertices = { { 1, 2, 3 } }
    sel.selected = { 1 }

    selection.begin_move(sel, vp, vertices, 10, 20)
    selection.end_move(sel)

    eq(sel.moving, false)
end)

T.report()
