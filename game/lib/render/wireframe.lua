local mat4 = require("lib.math.mat4")

local M={}

function M.draw(mesh, mvp, w, h, color)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(color)
    for _, face in ipairs(mesh.faces) do
        local n = #face
        for i = 1, n do
            local va = mesh.vertices[face[i]]
            local vb = mesh.vertices[face[(i % n) + 1]]
            local x1, y1 = mat4.project(mvp, va, w, h)
            local x2, y2 = mat4.project(mvp, vb, w, h)
            love.graphics.line(x1, y1, x2, y2)
        end
    end
    love.graphics.setColor({ r, g, b, a })
end

return M
