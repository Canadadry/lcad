local mat4 = require("lib.mat4")
local kind = require("lib.kind")

local M = {}

M.CameraKind = kind.Enum("CameraKind", { "Free", "Ortho" })

local DEFAULT_YAW      = math.rad(45)
local DEFAULT_PITCH    = math.asin(1 / math.sqrt(3))
local DEFAULT_DISTANCE = math.sqrt(27)

function M.new()
    return {
        kind     = M.CameraKind.Free(),
        pivot    = { 0, 0, 0 },
        yaw      = DEFAULT_YAW,
        pitch    = DEFAULT_PITCH,
        distance = DEFAULT_DISTANCE,
    }
end

local SENSITIVITY_DEG = 0.3
local PITCH_LIMIT     = math.rad(89)
local ZOOM_STEP       = 0.5
local MIN_DISTANCE    = 2
local MAX_DISTANCE    = 20

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function M.orbit(cam, dx, dy)
    cam.yaw = cam.yaw + math.rad(dx * SENSITIVITY_DEG)
    cam.pitch = clamp(cam.pitch + math.rad(dy * SENSITIVITY_DEG), -PITCH_LIMIT, PITCH_LIMIT)
end

function M.apply_zoom(current, delta, lo, hi)
    return clamp(current - delta * ZOOM_STEP, lo, hi)
end

function M.zoom(cam, delta)
    cam.distance = M.apply_zoom(cam.distance, delta, MIN_DISTANCE, MAX_DISTANCE)
end

-- TODO(refactor): compute right/up here via normalize(cross(forward(cam), WORLD_UP)) and
-- cross(right, forward(cam)) instead of the closed-form trig, so the match to
-- mat4.look_at's convention holds by construction instead of by comment.
local function screen_axes(cam)
    local cp = math.cos(cam.pitch)
    local sp = math.sin(cam.pitch)
    local right = { math.cos(cam.yaw), 0, -math.sin(cam.yaw) }
    local up    = { -sp * math.sin(cam.yaw), cp, -sp * math.cos(cam.yaw) }
    return right, up
end

-- TODO(refactor): rename dy (here and in ortho_camera.pan's matching call) to signal
-- it is deliberately not negated, unlike screen_delta_to_world's drag dy, so this
-- comment is unnecessary.
function M.pan_delta(right, up, dx, dy, scale)
    return {
        (right[1] * dx + up[1] * dy) * scale,
        (right[2] * dx + up[2] * dy) * scale,
        (right[3] * dx + up[3] * dy) * scale,
    }
end

function M.pan(cam, dx, dy, viewport_h)
    local right, up = screen_axes(cam)
    local depth = M.depth_of(cam, cam.pivot)
    local scale = M.pixel_scale(depth, viewport_h)
    local delta = M.pan_delta(right, up, dx, dy, scale)
    for i = 1, 3 do
        cam.pivot[i] = cam.pivot[i] + delta[i]
    end
end

function M.eye(cam)
    local cp = math.cos(cam.pitch)
    return {
        cam.pivot[1] + cam.distance * cp * math.sin(cam.yaw),
        cam.pivot[2] + cam.distance * math.sin(cam.pitch),
        cam.pivot[3] + cam.distance * cp * math.cos(cam.yaw),
    }
end

function M.view_matrix(cam)
    return mat4.look_at(M.eye(cam), cam.pivot, { 0, 1, 0 })
end

local function forward(cam)
    local cp = math.cos(cam.pitch)
    local sp = math.sin(cam.pitch)
    return { -cp * math.sin(cam.yaw), -sp, -cp * math.cos(cam.yaw) }
end

function M.depth_of(cam, position)
    local eye = M.eye(cam)
    local f = forward(cam)
    local d = { position[1] - eye[1], position[2] - eye[2], position[3] - eye[3] }
    return d[1] * f[1] + d[2] * f[2] + d[3] * f[3]
end

-- TODO(refactor): tie this to mat4.perspective's symmetric-frustum assumption (e.g. a
-- shared accessor or assert) instead of relying on aspect ratio silently canceling out,
-- so this comment is unnecessary.
function M.pixel_scale(depth, viewport_h)
    return 2 * depth * math.tan(mat4.FOV / 2) / viewport_h
end

function M.screen_delta_to_world(cam, position, dx, dy, viewport_h)
    local depth = M.depth_of(cam, position)
    local scale = M.pixel_scale(depth, viewport_h)
    local right, up = screen_axes(cam)
    local world_dx, world_dy = dx * scale, -dy * scale
    return {
        right[1] * world_dx + up[1] * world_dy,
        right[2] * world_dx + up[2] * world_dy,
        right[3] * world_dx + up[3] * world_dy,
    }
end

function M.screen_to_world(cam, mx, my, depth, viewport_w, viewport_h)
    local eye = M.eye(cam)
    local f = forward(cam)
    local center = {
        eye[1] + f[1] * depth,
        eye[2] + f[2] * depth,
        eye[3] + f[3] * depth,
    }

    local scale = M.pixel_scale(depth, viewport_h)
    local right, up = screen_axes(cam)
    local world_dx, world_dy = (mx - viewport_w / 2) * scale, -(my - viewport_h / 2) * scale

    return {
        center[1] + right[1] * world_dx + up[1] * world_dy,
        center[2] + right[2] * world_dx + up[2] * world_dy,
        center[3] + right[3] * world_dx + up[3] * world_dy,
    }
end

return M
