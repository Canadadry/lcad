local camera = require("camera.camera")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function approx(a, b, eps)
    return math.abs(a - b) < (eps or 1e-9)
end

test("new() places the eye at the same position as the old fixed camera", function()
    local cam = camera.new()
    local eye = camera.eye(cam)
    eq(approx(eye[1], 3), true, "eye.x")
    eq(approx(eye[2], 3), true, "eye.y")
    eq(approx(eye[3], 3), true, "eye.z")
end)

test("new() tags the camera as kind 'Free'", function()
    local cam = camera.new()
    eq(cam.kind, camera.CameraKind.Free())
end)

test("orbit(dx, 0) rotates the eye 90 degrees around the Y axis", function()
    local cam = camera.new()
    local before = camera.eye(cam)

    camera.orbit(cam, 300, 0)

    local after = camera.eye(cam)
    eq(approx(after[1], before[3]), true, "x rotates into old z")
    eq(approx(after[2], before[2]), true, "y (height) unchanged")
    eq(approx(after[3], -before[1]), true, "z rotates into old -x")
end)

test("view_matrix() places the pivot at -distance on the Z axis", function()
    local mat4 = require("lib.mat4")
    local cam = camera.new()
    local view = camera.view_matrix(cam)
    local r = mat4.mat4_mul_vec4(view, { cam.pivot[1], cam.pivot[2], cam.pivot[3], 1 })
    eq(approx(r[1], 0), true, "x")
    eq(approx(r[2], 0), true, "y")
    eq(approx(r[3], -cam.distance), true, "z")
end)

test("orbit clamps pitch at the poles instead of flipping over", function()
    local cam = camera.new()

    camera.orbit(cam, 0, 300)

    local eye = camera.eye(cam)
    local clamped_height = cam.distance * math.sin(math.rad(89))
    eq(approx(eye[2], clamped_height, 1e-6), true, "clamped at +89deg")

    camera.orbit(cam, 0, -600)

    eye = camera.eye(cam)
    clamped_height = cam.distance * math.sin(math.rad(-89))
    eq(approx(eye[2], clamped_height, 1e-6), true, "clamped at -89deg")
end)

test("zoom(1) decreases distance by one zoom step", function()
    local cam = camera.new()
    local before = cam.distance

    camera.zoom(cam, 1)

    eq(approx(cam.distance, before - 0.5), true, "distance")
end)

test("zoom clamps distance at the maximum", function()
    local cam = camera.new()

    for _ = 1, 1000 do
        camera.zoom(cam, -1)
    end

    eq(approx(cam.distance, 20), true, "distance clamped at max")
end)

test("zoom clamps distance at the minimum", function()
    local cam = camera.new()

    for _ = 1, 1000 do
        camera.zoom(cam, 1)
    end

    eq(approx(cam.distance, 2), true, "distance clamped at min")
end)

test("pan(dx, 0) at yaw=0 pitch=0 moves the pivot along world X", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    camera.pan(cam, 10, 0, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600 * 10
    eq(approx(cam.pivot[1], expected), true, "pivot.x")
    eq(approx(cam.pivot[2], 0), true, "pivot.y")
    eq(approx(cam.pivot[3], 0), true, "pivot.z")
end)

test("pan(0, dy) at yaw=0 pitch=0 moves the pivot along world Y", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    camera.pan(cam, 0, 10, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600 * 10
    eq(approx(cam.pivot[1], 0), true, "pivot.x")
    eq(approx(cam.pivot[2], expected), true, "pivot.y")
    eq(approx(cam.pivot[3], 0), true, "pivot.z")
end)

test("pan(dx, 0) at yaw=90deg moves the pivot along world -Z", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = math.rad(90), 0, 5

    camera.pan(cam, 10, 0, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600 * 10
    eq(approx(cam.pivot[1], 0), true, "pivot.x")
    eq(approx(cam.pivot[2], 0), true, "pivot.y")
    eq(approx(cam.pivot[3], -expected), true, "pivot.z")
end)

test("pan scales with the camera's distance from the pivot", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 10

    camera.pan(cam, 10, 0, 600)

    local expected = 2 * 10 * math.tan(math.rad(30)) / 600 * 10
    eq(approx(cam.pivot[1], expected), true, "pivot.x")
end)

test("pan does not change yaw, pitch, or distance", function()
    local cam = camera.new()
    local yaw, pitch, distance = cam.yaw, cam.pitch, cam.distance

    camera.pan(cam, 25, -15, 600)

    eq(approx(cam.yaw, yaw), true, "yaw")
    eq(approx(cam.pitch, pitch), true, "pitch")
    eq(approx(cam.distance, distance), true, "distance")
end)

test("depth_of(cam, pivot) equals the camera's orbit distance when facing it head-on", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local depth = camera.depth_of(cam, cam.pivot)

    eq(approx(depth, 5), true, "depth")
end)

test("depth_of(cam, position) grows for a point further along the view direction", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local depth = camera.depth_of(cam, { 0, 0, -3 })

    eq(approx(depth, 8), true, "depth")
end)

test("screen_delta_to_world(dx, 0) moves a point along world +X when facing it head-on", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local delta = camera.screen_delta_to_world(cam, { 0, 0, 0 }, 100, 0, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600 * 100
    eq(approx(delta[1], expected), true, "x")
    eq(approx(delta[2], 0), true, "y")
    eq(approx(delta[3], 0), true, "z")
end)

test("screen_delta_to_world(0, dy) moves a point along world -Y for a downward drag", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local delta = camera.screen_delta_to_world(cam, { 0, 0, 0 }, 0, 100, 600)

    local expected = -(2 * 5 * math.tan(math.rad(30)) / 600 * 100)
    eq(approx(delta[1], 0), true, "x")
    eq(approx(delta[2], expected), true, "y")
    eq(approx(delta[3], 0), true, "z")
end)

test("screen_delta_to_world(dx, 0) at yaw=90deg moves a point along world -Z", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = math.rad(90), 0, 5

    local delta = camera.screen_delta_to_world(cam, { 0, 0, 0 }, 100, 0, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600 * 100
    eq(approx(delta[1], 0), true, "x")
    eq(approx(delta[2], 0), true, "y")
    eq(approx(delta[3], -expected), true, "z")
end)

test("screen_delta_to_world scales with the point's depth", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 10

    local delta = camera.screen_delta_to_world(cam, { 0, 0, 0 }, 100, 0, 600)

    local expected = 2 * 10 * math.tan(math.rad(30)) / 600 * 100
    eq(approx(delta[1], expected), true, "x")
end)

test("pixel_scale(depth, h) matches the perspective projection's world-per-pixel size", function()
    local scale = camera.pixel_scale(5, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600
    eq(approx(scale, expected), true, "scale")
end)

test("screen_to_world at the viewport center returns the point straight ahead at the given depth", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local position = camera.screen_to_world(cam, 300, 300, cam.distance, 600, 600)

    eq(approx(position[1], cam.pivot[1]), true, "x")
    eq(approx(position[2], cam.pivot[2]), true, "y")
    eq(approx(position[3], cam.pivot[3]), true, "z")
end)

test("screen_to_world right of center offsets the point along world +X", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local position = camera.screen_to_world(cam, 400, 300, 5, 600, 600)

    local expected = 2 * 5 * math.tan(math.rad(30)) / 600 * 100
    eq(approx(position[1], expected), true, "x")
    eq(approx(position[2], 0), true, "y")
    eq(approx(position[3], 0), true, "z")
end)

test("screen_to_world below center offsets the point along world -Y", function()
    local cam = camera.new()
    cam.yaw, cam.pitch, cam.distance = 0, 0, 5

    local position = camera.screen_to_world(cam, 300, 400, 5, 600, 600)

    local expected = -(2 * 5 * math.tan(math.rad(30)) / 600 * 100)
    eq(approx(position[1], 0), true, "x")
    eq(approx(position[2], expected), true, "y")
    eq(approx(position[3], 0), true, "z")
end)

T.report()
