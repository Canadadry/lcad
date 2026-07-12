local mat4 = require("lib.mat4")
local mesh = require("lib.scene.mesh")
local gizmo = require("lib.scene.gizmo")
local colors = require("lib.colors")

local M = {}

function M.mvp(v)
    return mat4.mul(v.projection, v.view)
end

function M.draw(v, sceneMesh, w, h, setColor, drawLine)
    local mvp = M.mvp(v)

    setColor(colors.RealWhite)
    mesh.draw(sceneMesh, mvp, w, h, drawLine)

    gizmo.draw(mvp, w, h, function(x1, y1, x2, y2, color)
        setColor(color)
        drawLine(x1, y1, x2, y2)
    end)
    setColor(colors.RealWhite)
end

function M.draw_selected(v, sceneMesh, selected, w, h, drawCircle)
    mesh.draw_selected(sceneMesh, selected, M.mvp(v), w, h, drawCircle)
end

function M.viewport_at(v, cx, cy, w, h)
    return { view = v, ox = 0, oy = 0, w = w, h = h }
end

function M.world_to_screen(v, point, w, h)
    return mat4.project(M.mvp(v), point, w, h)
end

function M.depth_of(v, point)
    return mat4.mul_vec4(v.view, { point[1], point[2], point[3], 1 })[3]
end

function M.screen_to_world(v, sx, sy, depth, w, h)
    local view_x, view_y = mat4.unproject(v.projection, sx, sy, depth, w, h)
    local p = mat4.mul_vec4(mat4.invert(v.view), { view_x, view_y, depth, 1 })
    return p[1], p[2], p[3]
end

function M.new(name, view, projection)
    return {
        name = name,
        view = view,
        projection = projection,
        mvp = M.mvp,
        world_to_screen = M.world_to_screen,
        depth_of = M.depth_of,
        screen_to_world = M.screen_to_world,
        draw = M.draw,
        draw_selected = M.draw_selected,
        viewport_at = M.viewport_at,
    }
end

return M
