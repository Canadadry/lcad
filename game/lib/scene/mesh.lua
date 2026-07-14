local M = {}

function M.new(vertices, uvs, faces, face_uvs)
    return { vertices = vertices, uvs = uvs, faces = faces, face_uvs = face_uvs }
end

return M
