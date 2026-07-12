local obj_import = require("lib.scene.obj_import")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("load() parses vertex count correctly", function()
    love.filesystem.read = function(path)
        return [[
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.vertices, 3)
end)

test("load() parses face indices correctly", function()
    love.filesystem.read = function(path)
        return [[
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0
f 1 2 3
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.faces, 1)
    local face = mesh.faces[1]
    eq(face[1], 1)
    eq(face[2], 2)
    eq(face[3], 3)
end)

test("load() ignores comment lines", function()
    love.filesystem.read = function(path)
        return [[
# this is a comment
v 0.0 0.0 0.0
# another comment before a face
v 1.0 0.0 0.0
v 1.0 1.0 0.0
f 1 2 3
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.vertices, 3)
    eq(#mesh.faces, 1)
end)

test("load() parses a minimal cube fixture with quads and uvs", function()
    love.filesystem.read = function(path)
        return [[
# minimal cube
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0
v 0.0 1.0 0.0
v 0.0 0.0 1.0
v 1.0 0.0 1.0
v 1.0 1.0 1.0
v 0.0 1.0 1.0
vt 0.0 0.0
vt 1.0 0.0
vt 1.0 1.0
vt 0.0 1.0
f 1 2 3 4
f 5 6 7 8
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.vertices, 8)
    eq(#mesh.uvs, 4)
    eq(#mesh.faces, 2, "faces are kept as-authored, one per quad")
    eq(#mesh.faces[1], 4, "quad faces keep all 4 indices")
    eq(mesh.faces[1][1], 1)
    eq(mesh.faces[1][2], 2)
    eq(mesh.faces[1][3], 3)
    eq(mesh.faces[1][4], 4)
    eq(mesh.faces[2][1], 5)
    eq(mesh.faces[2][2], 6)
    eq(mesh.faces[2][3], 7)
    eq(mesh.faces[2][4], 8)
end)

test("load() parses a hand-written pyramid fixture with a quad base and four triangular sides (mirrors assets/pyramid.obj vertex/face counts)", function()
    love.filesystem.read = function(path)
        return [[
# hand-authored 5-vertex pyramid (square base + apex), centered on origin, UVs included
v 0.0 1.0 0.0
v -1.0 -1.0 -1.0
v 1.0 -1.0 -1.0
v 1.0 -1.0 1.0
v -1.0 -1.0 1.0
vt 0.5 1.0
vt 0.0 0.0
vt 1.0 0.0
vt 1.0 1.0
vt 0.0 1.0
f 5/5 4/4 3/3 2/2
f 1/1 2/2 3/3
f 1/1 3/3 4/4
f 1/1 4/4 5/5
f 1/1 5/5 2/2
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.vertices, 5)
    eq(#mesh.uvs, 5)
    eq(#mesh.faces, 5, "one quad base plus four triangular sides")
    eq(#mesh.faces[1], 4, "base face keeps all 4 indices")
    eq(mesh.faces[1][1], 5)
    eq(mesh.faces[1][2], 4)
    eq(mesh.faces[1][3], 3)
    eq(mesh.faces[1][4], 2)
    for i = 2, 5 do
        eq(#mesh.faces[i], 3, "side faces are triangles")
    end
    eq(mesh.faces[2][1], 1)
    eq(mesh.faces[5][3], 2)
end)

test("load() parses a hand-written cylinder fixture with two octagon caps and eight side quads (mirrors assets/cylinder.obj vertex/face counts)", function()
    love.filesystem.read = function(path)
        return [[
# hand-authored 16-vertex, 8-sided cylinder (radius 1, height 2), centered on origin, UVs included
v 1.0 -1.0 0.0
v 0.7071068 -1.0 0.7071068
v 0.0 -1.0 1.0
v -0.7071068 -1.0 0.7071068
v -1.0 -1.0 0.0
v -0.7071068 -1.0 -0.7071068
v 0.0 -1.0 -1.0
v 0.7071068 -1.0 -0.7071068
v 1.0 1.0 0.0
v 0.7071068 1.0 0.7071068
v 0.0 1.0 1.0
v -0.7071068 1.0 0.7071068
v -1.0 1.0 0.0
v -0.7071068 1.0 -0.7071068
v 0.0 1.0 -1.0
v 0.7071068 1.0 -0.7071068
vt 0.0 0.0
vt 0.125 0.0
vt 0.25 0.0
vt 0.375 0.0
vt 0.5 0.0
vt 0.625 0.0
vt 0.75 0.0
vt 0.875 0.0
vt 0.0 1.0
vt 0.125 1.0
vt 0.25 1.0
vt 0.375 1.0
vt 0.5 1.0
vt 0.625 1.0
vt 0.75 1.0
vt 0.875 1.0
f 8/8 7/7 6/6 5/5 4/4 3/3 2/2 1/1
f 9/9 10/10 11/11 12/12 13/13 14/14 15/15 16/16
f 1/1 2/2 10/10 9/9
f 2/2 3/3 11/11 10/10
f 3/3 4/4 12/12 11/11
f 4/4 5/5 13/13 12/12
f 5/5 6/6 14/14 13/13
f 6/6 7/7 15/15 14/14
f 7/7 8/8 16/16 15/15
f 8/8 1/1 9/9 16/16
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.vertices, 16)
    eq(#mesh.uvs, 16)
    eq(#mesh.faces, 10, "two octagon caps plus eight side quads")
    eq(#mesh.faces[1], 8, "bottom cap keeps all 8 indices")
    eq(#mesh.faces[2], 8, "top cap keeps all 8 indices")
    for i = 3, 10 do
        eq(#mesh.faces[i], 4, "side faces are quads")
    end
    eq(mesh.faces[1][1], 8)
    eq(mesh.faces[2][1], 9)
    eq(mesh.faces[3][1], 1)
    eq(mesh.faces[10][3], 9)
end)

test("load() parses a hand-written prism fixture with two triangle caps and three side quads (mirrors assets/prism.obj vertex/face counts)", function()
    love.filesystem.read = function(path)
        return [[
# hand-authored 6-vertex triangular prism, centered on origin, UVs included
v 0.0 -1.0 1.0
v -0.8660254 -1.0 -0.5
v 0.8660254 -1.0 -0.5
v 0.0 1.0 1.0
v -0.8660254 1.0 -0.5
v 0.8660254 1.0 -0.5
vt 0.5 0.0
vt 0.0 0.0
vt 1.0 0.0
vt 0.5 1.0
vt 0.0 1.0
vt 1.0 1.0
f 3/3 2/2 1/1
f 4/4 5/5 6/6
f 1/1 2/2 5/5 4/4
f 2/2 3/3 6/6 5/5
f 3/3 1/1 4/4 6/6
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.vertices, 6)
    eq(#mesh.uvs, 6)
    eq(#mesh.faces, 5, "two triangle caps plus three side quads")
    eq(#mesh.faces[1], 3, "bottom cap is a triangle")
    eq(#mesh.faces[2], 3, "top cap is a triangle")
    for i = 3, 5 do
        eq(#mesh.faces[i], 4, "side faces are quads")
    end
    eq(mesh.faces[1][1], 3)
    eq(mesh.faces[2][1], 4)
    eq(mesh.faces[5][3], 4)
end)

test("load() parses f v/vt tokens into parallel faces and face_uvs lists", function()
    love.filesystem.read = function(path)
        return [[
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0
vt 0.0 0.0
vt 1.0 0.0
vt 1.0 1.0
f 1/3 2/2 3/1
]]
    end
    local mesh = obj_import.load("fixture.obj")
    eq(#mesh.faces, 1)
    local face = mesh.faces[1]
    eq(face[1], 1)
    eq(face[2], 2)
    eq(face[3], 3)
    local face_uv = mesh.face_uvs[1]
    eq(face_uv[1], 3)
    eq(face_uv[2], 2)
    eq(face_uv[3], 1)
end)

test("load() falls back to the vertex index as its own UV index for a face line with no /vt", function()
    love.filesystem.read = function(path)
        return [[
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 1.0 1.0 0.0
f 1 2 3
]]
    end
    local mesh = obj_import.load("fixture.obj")
    local face_uv = mesh.face_uvs[1]
    eq(face_uv[1], 1)
    eq(face_uv[2], 2)
    eq(face_uv[3], 3)
end)

T.report()
