local mesh = require("lib.scene.mesh")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("new() stores face_uvs alongside vertices, uvs, and faces", function()
    local vertices = { { 0, 0, 0 } }
    local uvs = { { 0, 0 } }
    local faces = { { 1, 1, 1 } }
    local face_uvs = { { 1, 1, 1 } }

    local m = mesh.new(vertices, uvs, faces, face_uvs)

    eq(m.vertices, vertices)
    eq(m.uvs, uvs)
    eq(m.faces, faces)
    eq(m.face_uvs, face_uvs)
end)

T.report()
