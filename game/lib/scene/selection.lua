local vec3 = require("lib.math.vec3")
local mat4 = require("lib.math.mat4")

local M = {}

function M.new()
    return {
        dragging = false,
        moving = false,
        selected = {},
    }
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function clamp_point(x, y, w, h)
    if w and h then
        return clamp(x, 0, w), clamp(y, 0, h)
    end
    return x, y
end

function M.begin_drag(sel, vp, cx, cy)
    local x, y = clamp_point(cx - vp.ox, cy - vp.oy, vp.w, vp.h)
    sel.dragging = true
    sel.viewport = vp
    sel.start = { x = x, y = y }
    sel.current = { x = x, y = y }
end

function M.update_drag(sel, cx, cy)
    local vp = sel.viewport
    local x, y = clamp_point(cx - vp.ox, cy - vp.oy, vp.w, vp.h)
    sel.current.x = x
    sel.current.y = y
end

function M.end_drag(sel, vertices)
    local vp = sel.viewport
    local minX, maxX = math.min(sel.start.x, sel.current.x), math.max(sel.start.x, sel.current.x)
    local minY, maxY = math.min(sel.start.y, sel.current.y), math.max(sel.start.y, sel.current.y)

    local selected = {}
    for i, vertex in ipairs(vertices) do
        local x, y = mat4.world_to_screen(vp.view.view, vp.view.projection, vertex, vp.w, vp.h)
        if x >= minX and x <= maxX and y >= minY and y <= maxY then
            selected[#selected + 1] = i
        end
    end

    sel.dragging = false
    sel.selected = selected
end

function M.begin_move(sel, vp, vertices, cx, cy)
    sel.moving = true
    sel.viewport = vp
    sel.move_start = { x = cx, y = cy }
    sel.move_origin = {}
    for j, i in ipairs(sel.selected) do
        local v = vertices[i]
        sel.move_origin[j] = { v[1], v[2], v[3] }
    end
    sel.move_depth = mat4.depth_of(vp.view.view, vec3.barycenter(sel.move_origin))
end

function M.update_move(sel, vertices, cx, cy)
    local vp = sel.viewport
    local x1, y1, z1 = mat4.screen_to_world(vp.view.view, vp.view.projection, sel.move_start.x, sel.move_start.y, sel.move_depth, vp.w, vp.h)
    local x2, y2, z2 = mat4.screen_to_world(vp.view.view, vp.view.projection, cx, cy, sel.move_depth, vp.w, vp.h)
    local d = vec3.sub({ x2, y2, z2 }, { x1, y1, z1 })

    for j, i in ipairs(sel.selected) do
        local origin = sel.move_origin[j]
        local v = vertices[i]
        v[1] = origin[1] + d[1]
        v[2] = origin[2] + d[2]
        v[3] = origin[3] + d[3]
    end
end

function M.end_move(sel)
    sel.moving = false
end

function M.is_near_selected(sel, vp, vertices, cx, cy, radius)
    local x, y = cx - vp.ox, cy - vp.oy
    for _, i in ipairs(sel.selected) do
        local vx, vy = mat4.world_to_screen(vp.view.view, vp.view.projection, vertices[i], vp.w, vp.h)
        local dx, dy = vx - x, vy - y
        if dx * dx + dy * dy <= radius * radius then
            return true
        end
    end
    return false
end

return M
