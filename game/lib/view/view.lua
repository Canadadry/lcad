local mat4 = require("lib.mat4")
local mesh = require("lib.scene.mesh")
local gizmo = require("lib.scene.gizmo")
local colors = require("lib.colors")

local M = {}
M.__index = M

function M.new(name, view, projection)
    return setmetatable({
        name = name,
        view = view,
        projection = projection,
    }, M)
end

function M:mvp(model)
    return mat4.mul(self.projection, mat4.mul(self.view, model))
end

function M:draw(sceneMesh, model, w, h, setColor, drawLine)
    local mvp = self:mvp(model)

    setColor(colors.RealWhite)
    mesh.draw(sceneMesh, mvp, w, h, drawLine)

    gizmo.draw(mvp, w, h, function(x1, y1, x2, y2, color)
        setColor(color)
        drawLine(x1, y1, x2, y2)
        setColor(colors.RealWhite)
    end)
end

return M
