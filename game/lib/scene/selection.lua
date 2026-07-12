local mat4 = require("lib.mat4")

local M = {}

function M.new()
    return {
        dragging = false,
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

function M.end_drag(sel, vertices, model)
    local vp = sel.viewport
    local mvp = vp.view:mvp(model)
    local minX, maxX = math.min(sel.start.x, sel.current.x), math.max(sel.start.x, sel.current.x)
    local minY, maxY = math.min(sel.start.y, sel.current.y), math.max(sel.start.y, sel.current.y)

    local selected = {}
    for i, vertex in ipairs(vertices) do
        local x, y = mat4.project(mvp, vertex, vp.w, vp.h)
        if x >= minX and x <= maxX and y >= minY and y <= maxY then
            selected[#selected + 1] = i
        end
    end

    sel.dragging = false
    sel.selected = selected
end

function M.is_near_selected(sel, vp, vertices, model, cx, cy, radius)
    local mvp = vp.view:mvp(model)
    local x, y = cx - vp.ox, cy - vp.oy
    for _, i in ipairs(sel.selected) do
        local vx, vy = mat4.project(mvp, vertices[i], vp.w, vp.h)
        local dx, dy = vx - x, vy - y
        if dx * dx + dy * dy <= radius * radius then
            return true
        end
    end
    return false
end

function M.draw(sel, drawLine)
    if not sel.dragging then
        return
    end

    local ox, oy = sel.viewport.ox, sel.viewport.oy
    local sx, sy = sel.start.x + ox, sel.start.y + oy
    local cx, cy = sel.current.x + ox, sel.current.y + oy
    drawLine(sx, sy, cx, sy)
    drawLine(cx, sy, cx, cy)
    drawLine(cx, cy, sx, cy)
    drawLine(sx, cy, sx, sy)
end

return M
