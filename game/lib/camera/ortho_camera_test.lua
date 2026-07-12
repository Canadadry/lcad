local ortho_camera = require("lib.camera.ortho_camera")
local mat4         = require("lib.mat4")
local camera       = require("lib.camera.camera")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function approx(a, b, eps)
    return math.abs(a - b) < (eps or 1e-9)
end

test("new('front') places the eye on the +Z axis", function()
    local cam = ortho_camera.new("front")
    eq(cam.kind, camera.CameraKind.Ortho())
    eq(approx(cam.eye[1], 0), true, "eye.x")
    eq(approx(cam.eye[2], 0), true, "eye.y")
    eq(cam.eye[3] > 0, true, "eye.z is positive")
end)

test("new('side') places the eye on the +X axis", function()
    local cam = ortho_camera.new("side")
    eq(cam.eye[1] > 0, true, "eye.x is positive")
    eq(approx(cam.eye[2], 0), true, "eye.y")
    eq(approx(cam.eye[3], 0), true, "eye.z")
end)

test("new('top') places the eye on the +Y axis", function()
    local cam = ortho_camera.new("top")
    eq(approx(cam.eye[1], 0), true, "eye.x")
    eq(cam.eye[2] > 0, true, "eye.y is positive")
    eq(approx(cam.eye[3], 0), true, "eye.z")
end)

test("new: unknown view asserts", function()
    local ok = pcall(ortho_camera.new, "bogus")
    eq(ok, false)
end)

test("front view_matrix places the origin at -distance on the Z axis", function()
    local cam = ortho_camera.new("front")
    local view = ortho_camera.view_matrix(cam)
    local r = mat4.mat4_mul_vec4(view, { 0, 0, 0, 1 })
    eq(approx(r[1], 0), true, "x")
    eq(approx(r[2], 0), true, "y")
    eq(approx(r[3], -cam.eye[3]), true, "z")
end)

test("top view_matrix places the origin at -distance on the Z axis", function()
    local cam = ortho_camera.new("top")
    local view = ortho_camera.view_matrix(cam)
    local r = mat4.mat4_mul_vec4(view, { 0, 0, 0, 1 })
    eq(approx(r[1], 0), true, "x")
    eq(approx(r[2], 0), true, "y")
    eq(approx(r[3], -cam.eye[2]), true, "z")
end)

test("projection_matrix(cam, aspect) scales the horizontal extent by aspect", function()
    local cam = ortho_camera.new("front")
    local m = ortho_camera.projection_matrix(cam, 2)
    eq(approx(m[1], 1 / (cam.half_extent * 2)), true, "col0 row0")
    eq(approx(m[6], 1 / cam.half_extent), true, "col1 row1")
end)

test("depth_of(cam, pivot) equals the eye's distance from the origin", function()
    local cam = ortho_camera.new("front")
    local depth = ortho_camera.depth_of(cam, cam.pivot)
    eq(approx(depth, cam.eye[3]), true, "depth")
end)

test("depth_of grows for a point further along the view direction", function()
    local cam = ortho_camera.new("front")
    local depth = ortho_camera.depth_of(cam, { 0, 0, -3 })
    eq(approx(depth, cam.eye[3] + 3), true, "depth")
end)

test("pixel_scale(cam, viewport_h) matches 2*half_extent/viewport_h", function()
    local cam = ortho_camera.new("front")
    local scale = ortho_camera.pixel_scale(cam, 600)
    eq(approx(scale, 2 * cam.half_extent / 600), true, "scale")
end)

test("front screen_delta_to_world(dx, 0) moves a point along world +X", function()
    local cam = ortho_camera.new("front")
    local delta = ortho_camera.screen_delta_to_world(cam, { 0, 0, 0 }, 100, 0, 600)
    local expected = 100 * (2 * cam.half_extent / 600)
    eq(approx(delta[1], expected), true, "x")
    eq(approx(delta[2], 0), true, "y")
    eq(approx(delta[3], 0), true, "z")
end)

test("screen_delta_to_world does not scale with the point's depth", function()
    local cam = ortho_camera.new("front")
    local near = ortho_camera.screen_delta_to_world(cam, { 0, 0, 5 }, 100, 0, 600)
    local far  = ortho_camera.screen_delta_to_world(cam, { 0, 0, -50 }, 100, 0, 600)
    eq(approx(near[1], far[1]), true, "same world delta regardless of depth")
end)

test("front screen_to_world at the viewport center returns the pivot", function()
    local cam = ortho_camera.new("front")
    local position = ortho_camera.screen_to_world(cam, 300, 300, cam.eye[3], 600, 600)
    eq(approx(position[1], 0), true, "x")
    eq(approx(position[2], 0), true, "y")
    eq(approx(position[3], 0), true, "z")
end)

test("front screen_to_world right of center offsets the point along world +X", function()
    local cam = ortho_camera.new("front")
    local position = ortho_camera.screen_to_world(cam, 400, 300, cam.eye[3], 600, 600)
    local expected = 100 * (2 * cam.half_extent / 600)
    eq(approx(position[1], expected), true, "x")
    eq(approx(position[2], 0), true, "y")
    eq(approx(position[3], 0), true, "z")
end)

test("front pan(dx, 0) moves eye and pivot along world +X", function()
    local cam = ortho_camera.new("front")
    local eye_before, pivot_before = { cam.eye[1], cam.eye[2], cam.eye[3] }, { cam.pivot[1], cam.pivot[2], cam.pivot[3] }

    ortho_camera.pan(cam, 100, 0, 600)

    local expected = 100 * (2 * cam.half_extent / 600)
    eq(approx(cam.eye[1], eye_before[1] + expected), true, "eye.x")
    eq(approx(cam.eye[2], eye_before[2]), true, "eye.y")
    eq(approx(cam.eye[3], eye_before[3]), true, "eye.z")
    eq(approx(cam.pivot[1], pivot_before[1] + expected), true, "pivot.x")
    eq(approx(cam.pivot[2], pivot_before[2]), true, "pivot.y")
    eq(approx(cam.pivot[3], pivot_before[3]), true, "pivot.z")
end)

test("front pan(0, dy) moves eye and pivot along world +Y", function()
    local cam = ortho_camera.new("front")

    ortho_camera.pan(cam, 0, 100, 600)

    local expected = 100 * (2 * cam.half_extent / 600)
    eq(approx(cam.eye[1], 0), true, "eye.x")
    eq(approx(cam.eye[2], expected), true, "eye.y")
    eq(approx(cam.pivot[2], expected), true, "pivot.y")
end)

test("pan(dx, 0) moves eye along the view's own right vector, for all 3 ortho views", function()
    for _, view in ipairs({ "top", "side", "front" }) do
        local cam = ortho_camera.new(view)
        local eye_before = { cam.eye[1], cam.eye[2], cam.eye[3] }

        ortho_camera.pan(cam, 100, 0, 600)

        local expected = 100 * (2 * cam.half_extent / 600)
        for i = 1, 3 do
            eq(approx(cam.eye[i], eye_before[i] + cam.right[i] * expected), true, view .. " eye[" .. i .. "]")
        end
    end
end)

test("pan preserves the eye-to-pivot offset", function()
    local cam = ortho_camera.new("top")
    local offset_before = {
        cam.eye[1] - cam.pivot[1],
        cam.eye[2] - cam.pivot[2],
        cam.eye[3] - cam.pivot[3],
    }

    ortho_camera.pan(cam, 37, -21, 600)

    eq(approx(cam.eye[1] - cam.pivot[1], offset_before[1]), true, "offset.x")
    eq(approx(cam.eye[2] - cam.pivot[2], offset_before[2]), true, "offset.y")
    eq(approx(cam.eye[3] - cam.pivot[3], offset_before[3]), true, "offset.z")
end)

test("zoom(1) decreases half_extent by one zoom step", function()
    local cam = ortho_camera.new("front")
    local before = cam.half_extent

    ortho_camera.zoom(cam, 1)

    eq(approx(cam.half_extent, before - 0.5), true, "half_extent")
end)

test("zoom clamps half_extent at the maximum", function()
    local cam = ortho_camera.new("front")

    for _ = 1, 1000 do
        ortho_camera.zoom(cam, -1)
    end

    eq(approx(cam.half_extent, 20), true, "half_extent clamped at max")
end)

test("zoom clamps half_extent at the minimum", function()
    local cam = ortho_camera.new("front")

    for _ = 1, 1000 do
        ortho_camera.zoom(cam, 1)
    end

    eq(approx(cam.half_extent, 1), true, "half_extent clamped at min")
end)

test("zoom does not change eye or pivot", function()
    local cam = ortho_camera.new("top")
    local eye_before, pivot_before = { cam.eye[1], cam.eye[2], cam.eye[3] }, { cam.pivot[1], cam.pivot[2], cam.pivot[3] }

    ortho_camera.zoom(cam, 1)

    eq(approx(cam.eye[1], eye_before[1]), true, "eye.x")
    eq(approx(cam.eye[2], eye_before[2]), true, "eye.y")
    eq(approx(cam.eye[3], eye_before[3]), true, "eye.z")
    eq(approx(cam.pivot[1], pivot_before[1]), true, "pivot.x")
    eq(approx(cam.pivot[2], pivot_before[2]), true, "pivot.y")
    eq(approx(cam.pivot[3], pivot_before[3]), true, "pivot.z")
end)

T.report()
