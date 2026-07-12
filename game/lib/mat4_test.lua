local mat4 = require("lib.mat4")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function approx(a, b, eps)
    return math.abs(a - b) < (eps or 1e-9)
end

test("identity returns the identity matrix", function()
    local m = mat4.identity()
    eq(#m, 16)
    for col = 0, 3 do
        for row = 0, 3 do
            local expected = (col == row) and 1 or 0
            eq(m[col * 4 + row + 1], expected, "col " .. col .. " row " .. row)
        end
    end
end)

test("mat4_mul multiplies two diagonal matrices correctly", function()
    local a = { 2,0,0,0,  0,3,0,0,  0,0,4,0,  0,0,0,1 }
    local b = { 5,0,0,0,  0,6,0,0,  0,0,7,0,  0,0,0,1 }
    local r = mat4.mul(a, b)
    eq(r[1],  10)
    eq(r[6],  18)
    eq(r[11], 28)
    eq(r[16], 1)
end)

test("mat4_mul with identity returns the other matrix unchanged", function()
    local m = { 1,2,3,4, 5,6,7,8, 9,10,11,12, 13,14,15,16 }
    local r = mat4.mul(mat4.identity(), m)
    for i = 1, 16 do
        eq(r[i], m[i], "index " .. i)
    end
end)

test("mat4_mul_vec4 transforms a vector through a scale matrix", function()
    local scale = { 2,0,0,0,  0,3,0,0,  0,0,4,0,  0,0,0,1 }
    local r = mat4.mul_vec4(scale, { 1, 1, 1, 1 })
    eq(r[1], 2)
    eq(r[2], 3)
    eq(r[3], 4)
    eq(r[4], 1)
end)

test("mat4_translate offsets a point by (x, y, z)", function()
    local m = mat4.translate(5, -2, 3)
    local r = mat4.mul_vec4(m, { 0, 0, 0, 1 })
    eq(r[1], 5)
    eq(r[2], -2)
    eq(r[3], 3)
    eq(r[4], 1)
end)

test("mat4_translate leaves a direction vector (w=0) unaffected", function()
    local m = mat4.translate(5, -2, 3)
    local r = mat4.mul_vec4(m, { 1, 1, 1, 0 })
    eq(r[1], 1)
    eq(r[2], 1)
    eq(r[3], 1)
    eq(r[4], 0)
end)

test("mat4_rotate_x(90 degrees) carries the +Y axis onto +Z", function()
    local m = mat4.rotate_x(math.rad(90))
    local r = mat4.mul_vec4(m, { 0, 1, 0, 1 })
    eq(approx(r[1], 0), true, "x")
    eq(approx(r[2], 0), true, "y")
    eq(approx(r[3], 1), true, "z")
    eq(r[4], 1, "w")
end)

test("mat4_rotate_y(90 degrees) carries the +Z axis onto +X", function()
    local m = mat4.rotate_y(math.rad(90))
    local r = mat4.mul_vec4(m, { 0, 0, 1, 1 })
    eq(approx(r[1], 1), true, "x")
    eq(approx(r[2], 0), true, "y")
    eq(approx(r[3], 0), true, "z")
    eq(r[4], 1, "w")
end)

test("mat4_rotate_z(90 degrees) carries the +X axis onto +Y", function()
    local m = mat4.rotate_z(math.rad(90))
    local r = mat4.mul_vec4(m, { 1, 0, 0, 1 })
    eq(approx(r[1], 0), true, "x")
    eq(approx(r[2], 1), true, "y")
    eq(approx(r[3], 0), true, "z")
    eq(r[4], 1, "w")
end)

test("mat4_scale(2) doubles a point's distance from the origin on every axis", function()
    local m = mat4.scale(2)
    local r = mat4.mul_vec4(m, { 3, -4, 5, 1 })
    eq(r[1], 6, "x")
    eq(r[2], -8, "y")
    eq(r[3], 10, "z")
    eq(r[4], 1, "w")
end)

test("look_at transforms the target point to -distance on the Z axis", function()
    local view = mat4.look_at({ 0, 0, 5 }, { 0, 0, 0 }, { 0, 1, 0 })
    local r = mat4.mul_vec4(view, { 0, 0, 0, 1 })
    eq(r[1], 0)
    eq(r[2], 0)
    eq(r[3], -5)
    eq(r[4], 1)
end)

test("transpose swaps each (col, row) element with its (row, col) counterpart", function()
    local m = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 }
    local t = mat4.transpose(m)

    -- diagonal stays put
    eq(t[1], 1); eq(t[6], 6); eq(t[11], 11); eq(t[16], 16)
    -- off-diagonal pairs swap
    eq(t[2], m[5], "col0 row1 <- original col1 row0")
    eq(t[5], m[2], "col1 row0 <- original col0 row1")
    eq(t[3], m[9], "col0 row2 <- original col2 row0")
    eq(t[9], m[3], "col2 row0 <- original col0 row2")
    eq(t[8], m[14], "col1 row3 <- original col3 row1")
    eq(t[14], m[8], "col3 row1 <- original col1 row3")
end)

test("transpose of a rotation matrix is its inverse", function()
    local m = mat4.rotate_y(math.rad(50))
    local product = mat4.mul(mat4.transpose(m), m)

    for col = 0, 3 do
        for row = 0, 3 do
            local expected = (col == row) and 1 or 0
            eq(approx(product[col * 4 + row + 1], expected), true, "col " .. col .. " row " .. row)
        end
    end
end)

test("perspective produces expected matrix elements for a 90deg fov", function()
    local m = mat4.perspective(math.rad(90), 1, 1, 101)
    eq(approx(m[1], 1), true, "col0 row0 = 1/(aspect*tan(45))")
    eq(approx(m[6], 1), true, "col1 row1 = 1/tan(45)")
    eq(approx(m[11], -1.02), true, "col2 row2 = -(far+near)/(far-near)")
    eq(m[12], -1, "col2 row3 = -1")
    eq(approx(m[15], -2.02), true, "col3 row2 = -(2*far*near)/(far-near)")
end)

test("orthographic produces expected matrix elements for a symmetric box", function()
    local m = mat4.orthographic(-2, 2, -3, 3, 1, 101)
    eq(approx(m[1], 0.5), true, "col0 row0 = 2/(right-left) = 2/4")
    eq(approx(m[6], 1 / 3), true, "col1 row1 = 2/(top-bottom) = 2/6")
    eq(approx(m[11], -0.02), true, "col2 row2 = -2/(far-near) = -2/100")
    eq(m[16], 1, "col3 row3 stays 1 (no perspective divide)")
end)

test("orthographic keeps a point's screen size constant across depth", function()
    local view = mat4.identity()
    local near_proj = mat4.orthographic(-2, 2, -2, 2, 0.1, 100)
    local mvp_near = mat4.mul(near_proj, view)
    local x_near = mat4.project(mvp_near, { 2, 0, -1 }, 800, 600)
    local x_far  = mat4.project(mvp_near, { 2, 0, -50 }, 800, 600)
    eq(approx(x_near, x_far), true, "same screen x regardless of depth")
end)

test("project maps the origin to the center of the screen under an identity mvp", function()
    local x, y = mat4.project(mat4.identity(), { 0, 0, 0 }, 800, 600)
    eq(x, 400)
    eq(y, 300)
end)

test("project maps NDC (1, 0) to the right edge, vertical center", function()
    local x, y = mat4.project(mat4.identity(), { 1, 0, 0 }, 800, 600)
    eq(x, 800)
    eq(y, 300)
end)

T.report()
