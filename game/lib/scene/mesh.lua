local mat4 = require("lib.mat4")

local M = {}

function M.new(vertices, uvs, faces, face_uvs)
    return { vertices = vertices, uvs = uvs, faces = faces, face_uvs = face_uvs }
end

function M.draw(mesh,mvp,w,h,drawLine)
    for _, face in ipairs(mesh.faces) do
        local n = #face
        for i = 1, n do
            local a = mesh.vertices[face[i]]
            local b = mesh.vertices[face[(i % n) + 1]]
            local x1, y1 = mat4.project(mvp, a, w, h)
            local x2, y2 = mat4.project(mvp, b, w, h)
            drawLine(x1, y1, x2, y2)
        end
    end
end

function M.draw_selected(mesh, selected, mvp, w, h, drawCircle)
    for _, i in ipairs(selected) do
        local x, y = mat4.project(mvp, mesh.vertices[i], w, h)
        drawCircle(x, y)
    end
end

-- TODO(refactor): thread the face index through hit-test/highlight callers so this
-- can index mesh.face_uvs directly instead of scanning by identity, so this comment
-- is unnecessary
function M.face_uvs_for(mesh, face)
    if not mesh.face_uvs then
        return nil
    end
    for i, f in ipairs(mesh.faces) do
        if f == face then
            return mesh.face_uvs[i]
        end
    end
    return nil
end

return M
