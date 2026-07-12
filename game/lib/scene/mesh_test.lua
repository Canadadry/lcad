local mesh = require("lib.scene.mesh")
local mat4 = require("lib.mat4")

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

test("draw_selected() draws a circle at the screen position of each selected vertex, in order", function()
    local m = mesh.new(
        { { -0.5, 0, 0 }, { 0.5, 0, 0 }, { 0, 0.5, 0 } },
        {}, {}
    )
    local mvp = mat4.identity()

    local circles = {}
    mesh.draw_selected(m, { 3, 1 }, mvp, 100, 100, function(x, y)
        table.insert(circles, { x = x, y = y })
    end)

    eq(#circles, 2)
    eq(circles[1].x, 50); eq(circles[1].y, 25)
    eq(circles[2].x, 25); eq(circles[2].y, 50)
end)

test("draw_selected() calls drawCircle with only the screen position, no radius", function()
    local m = mesh.new({ { 0, 0, 0 } }, {}, {})

    local argCount
    mesh.draw_selected(m, { 1 }, mat4.identity(), 100, 100, function(...)
        argCount = select("#", ...)
    end)

    eq(argCount, 2)
end)

test("draw_selected() draws nothing for an empty selection", function()
    local m = mesh.new({ { 0, 0, 0 } }, {}, {})

    mesh.draw_selected(m, {}, mat4.identity(), 100, 100,
        function() error("drawCircle should not be called") end)
end)

T.report()
