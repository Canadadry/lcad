local M = {}

function M.new(vertices, uvs, faces, face_uvs)
    return { vertices = vertices, uvs = uvs, faces = faces, face_uvs = face_uvs }
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
