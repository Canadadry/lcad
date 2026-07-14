local mat4 = require("lib.math.mat4")

local M = {}

local function draw_drag_box(v, sel)
    if not sel.dragging or sel.viewport.view ~= v then
        return
    end

    local sx, sy = sel.start.x, sel.start.y
    local cx, cy = sel.current.x, sel.current.y
    love.graphics.line(sx, sy, cx, sy)
    love.graphics.line(cx, sy, cx, cy)
    love.graphics.line(cx, cy, sx, cy)
    love.graphics.line(sx, cy, sx, sy)
end

function M.draw(v, mesh, sel, mvp, w, h, radius, color)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(color)
    for _, i in ipairs(sel.selected) do
        local x, y = mat4.project(mvp, mesh.vertices[i], w, h)
        love.graphics.circle("line", x, y, radius)
    end
    draw_drag_box(v, sel)
    love.graphics.setColor({ r, g, b, a })
end

return M
