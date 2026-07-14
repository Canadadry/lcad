local mat4 = require("lib.mat4")

local M = {}

function M.draw(sel)
    if not sel.dragging then
        return
    end

    local ox, oy = sel.viewport.ox, sel.viewport.oy
    local sx, sy = sel.start.x + ox, sel.start.y + oy
    local cx, cy = sel.current.x + ox, sel.current.y + oy
    love.graphics.line(sx, sy, cx, sy)
    love.graphics.line(cx, sy, cx, cy)
    love.graphics.line(cx, cy, sx, cy)
    love.graphics.line(sx, cy, sx, sy)
end

function M.draw_selected(mesh, selected, mvp, w, h, radius, color)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(color)
    for _, i in ipairs(selected) do
        local x, y = mat4.project(mvp, mesh.vertices[i], w, h)
        love.graphics.circle("line", x, y, radius)
    end
    love.graphics.setColor({ r, g, b, a })
end

return M
