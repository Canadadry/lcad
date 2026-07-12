local mesh = require("scene.mesh")

local M = {}

local function face_vertex_index(token)
    local index = token:match("^(%d+)")
    return tonumber(index)
end

local function face_uv_index(token, vertex_index)
    local index = token:match("^%d+/(%d+)")
    return index and tonumber(index) or vertex_index
end

function M.load(path)
    local text = love.filesystem.read(path)
    assert(text, "obj_import.load: could not read file: " .. tostring(path))
    local vertices = {}
    local uvs = {}
    local faces = {}
    local face_uvs = {}
    for line in text:gmatch("[^\n]+") do
        local x, y, z = line:match("^v%s+(%S+)%s+(%S+)%s+(%S+)")
        if x then
            vertices[#vertices + 1] = { tonumber(x), tonumber(y), tonumber(z) }
        else
            local u, v = line:match("^vt%s+(%S+)%s+(%S+)")
            if u then
                uvs[#uvs + 1] = { tonumber(u), tonumber(v) }
            else
                local f = line:match("^f%s+(.+)")
                if f then
                    local indices = {}
                    local uv_indices = {}
                    for token in f:gmatch("%S+") do
                        local vertex_index = face_vertex_index(token)
                        indices[#indices + 1] = vertex_index
                        uv_indices[#uv_indices + 1] = face_uv_index(token, vertex_index)
                    end
                    faces[#faces + 1] = indices
                    face_uvs[#face_uvs + 1] = uv_indices
                end
            end
        end
    end
    return mesh.new(vertices, uvs, faces, face_uvs)
end

return M
