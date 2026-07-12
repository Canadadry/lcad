local mat4   = require("lib.mat4")
local camera = require("camera.camera")

local M = {}

local EYE_DISTANCE = 10
local HALF_EXTENT  = 5
local NEAR         = 0.1
local FAR          = 100

local MIN_HALF_EXTENT  = 1
local MAX_HALF_EXTENT  = 20

local ORTHO_DEFS = {
    front = {
        eye = { 0, 0, EYE_DISTANCE }, forward = { 0, 0, -1 },
        right = { 1, 0, 0 }, up = { 0, 1, 0 },
    },
    side = {
        eye = { EYE_DISTANCE, 0, 0 }, forward = { -1, 0, 0 },
        right = { 0, 0, -1 }, up = { 0, 1, 0 },
    },
    top = {
        eye = { 0, EYE_DISTANCE, 0 }, forward = { 0, -1, 0 },
        right = { 1, 0, 0 }, up = { 0, 0, -1 },
    },
}

local function is_right_handed(right, forward, up)
    local cross = {
        right[2] * forward[3] - right[3] * forward[2],
        right[3] * forward[1] - right[1] * forward[3],
        right[1] * forward[2] - right[2] * forward[1],
    }
    return cross[1] == up[1] and cross[2] == up[2] and cross[3] == up[3]
end

for view, def in pairs(ORTHO_DEFS) do
    assert(is_right_handed(def.right, def.forward, def.up), "ortho_camera: " .. view .. " axes are not right-handed")
end

local function copy3(v)
    return { v[1], v[2], v[3] }
end

function M.new(view)
    local def = ORTHO_DEFS[view]
    assert(def, "ortho_camera.new: unknown view " .. tostring(view))
    return {
        kind        = camera.CameraKind.Ortho(),
        view        = view,
        eye         = copy3(def.eye),
        forward     = copy3(def.forward),
        right       = copy3(def.right),
        up          = copy3(def.up),
        pivot       = { 0, 0, 0 },
        half_extent = HALF_EXTENT,
    }
end

function M.view_matrix(cam)
    return mat4.look_at(cam.eye, cam.pivot, cam.up)
end

function M.projection_matrix(cam, aspect)
    local half_h = cam.half_extent
    local half_w = half_h * aspect
    return mat4.orthographic(-half_w, half_w, -half_h, half_h, NEAR, FAR)
end

function M.depth_of(cam, position)
    local d = {
        position[1] - cam.eye[1],
        position[2] - cam.eye[2],
        position[3] - cam.eye[3],
    }
    return d[1] * cam.forward[1] + d[2] * cam.forward[2] + d[3] * cam.forward[3]
end

function M.pixel_scale(cam, viewport_h)
    return 2 * cam.half_extent / viewport_h
end

function M.screen_delta_to_world(cam, position, dx, dy, viewport_h)
    local scale = M.pixel_scale(cam, viewport_h)
    local world_dx, world_dy = dx * scale, -dy * scale
    return {
        cam.right[1] * world_dx + cam.up[1] * world_dy,
        cam.right[2] * world_dx + cam.up[2] * world_dy,
        cam.right[3] * world_dx + cam.up[3] * world_dy,
    }
end

function M.pan(cam, dx, dy, viewport_h)
    local scale = M.pixel_scale(cam, viewport_h)
    local delta = camera.pan_delta(cam.right, cam.up, dx, dy, scale)
    for i = 1, 3 do
        cam.eye[i] = cam.eye[i] + delta[i]
        cam.pivot[i] = cam.pivot[i] + delta[i]
    end
end

function M.zoom(cam, delta)
    cam.half_extent = camera.apply_zoom(cam.half_extent, delta, MIN_HALF_EXTENT, MAX_HALF_EXTENT)
end

function M.screen_to_world(cam, mx, my, depth, viewport_w, viewport_h)
    local center = {
        cam.eye[1] + cam.forward[1] * depth,
        cam.eye[2] + cam.forward[2] * depth,
        cam.eye[3] + cam.forward[3] * depth,
    }

    local scale = M.pixel_scale(cam, viewport_h)
    local world_dx, world_dy = (mx - viewport_w / 2) * scale, -(my - viewport_h / 2) * scale

    return {
        center[1] + cam.right[1] * world_dx + cam.up[1] * world_dy,
        center[2] + cam.right[2] * world_dx + cam.up[2] * world_dy,
        center[3] + cam.right[3] * world_dx + cam.up[3] * world_dy,
    }
end

return M
