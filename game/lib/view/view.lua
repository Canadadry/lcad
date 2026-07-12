local mat4 = require("lib.mat4")
local mesh = require("lib.scene.mesh")
local gizmo = require("lib.scene.gizmo")
local colors = require("lib.colors")

local M = {}

function M.mvp(v, model)
    return mat4.mul(v.projection, mat4.mul(v.view, model))
end

function M.draw(v, sceneMesh, model, w, h, setColor, drawLine)
    local mvp = M.mvp(v, model)

    setColor(colors.RealWhite)
    mesh.draw(sceneMesh, mvp, w, h, drawLine)

    gizmo.draw(mvp, w, h, function(x1, y1, x2, y2, color)
        setColor(color)
        drawLine(x1, y1, x2, y2)
    end)
    setColor(colors.RealWhite)
end

function M.draw_selected(v, sceneMesh, selected, model, w, h, drawCircle)
    mesh.draw_selected(sceneMesh, selected, M.mvp(v, model), w, h, drawCircle)
end

function M.viewport_at(v, cx, cy, w, h)
    return { view = v, ox = 0, oy = 0, w = w, h = h }
end

function M.new(name, view, projection, move_delta)
    return {
        name = name,
        view = view,
        projection = projection,
        move_delta = move_delta,
        mvp = M.mvp,
        draw = M.draw,
        draw_selected = M.draw_selected,
        viewport_at = M.viewport_at,
    }
end

return M
