local mesh = require("scene.mesh")

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

test("face_uvs_for() resolves the face_uvs entry parallel to a given face by identity", function()
    local face_a = { 1, 2, 3 }
    local face_b = { 4, 5, 6 }
    local m = mesh.new({}, {}, { face_a, face_b }, { { 10, 20, 30 }, { 40, 50, 60 } })

    eq(mesh.face_uvs_for(m, face_b), m.face_uvs[2])
end)

test("face_uvs_for() returns nil when the mesh has no face_uvs", function()
    local face_a = { 1, 2, 3 }
    local m = mesh.new({}, {}, { face_a })

    eq(mesh.face_uvs_for(m, face_a), nil)
end)

T.report()
