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
    sel.start = { x = x, y = y }
    sel.current = { x = x, y = y }
end

function M.update_drag(sel, vp, cx, cy)
    local x, y = clamp_point(cx - vp.ox, cy - vp.oy, vp.w, vp.h)
    sel.current.x = x
    sel.current.y = y
end

function M.end_drag(sel, vp, vertices, model)
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

local markerRadius = 3

function M.draw(sel, vp, vertices, model, drawLine, drawCircle)
    local ox, oy = vp.ox, vp.oy

    if sel.dragging then
        local sx, sy, cx, cy = sel.start.x + ox, sel.start.y + oy, sel.current.x + ox, sel.current.y + oy
        drawLine(sx, sy, cx, sy)
        drawLine(cx, sy, cx, cy)
        drawLine(cx, cy, sx, cy)
        drawLine(sx, cy, sx, sy)
        return
    end

    local mvp = vp.view:mvp(model)
    for _, i in ipairs(sel.selected) do
        local x, y = mat4.project(mvp, vertices[i], vp.w, vp.h)
        drawCircle(x + ox, y + oy, markerRadius)
    end
end

return M
