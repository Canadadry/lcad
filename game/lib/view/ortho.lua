local mat4 = require("lib.mat4")
local view = require("lib.view.view")

local orthoSize = 3

-- Orthographic projection maps view-space x/y to screen space independently of
-- depth, so a screen-space delta converts back to a fixed view-space delta on
-- the axes visible in this view. That delta is rotated into object space by
-- the transpose of view*model's rotation (its inverse, since it has no scale).
local function move_delta(v, model, w, h, dsx, dsy)
    local proj = v.projection
    local m00, m11 = proj[1], proj[6]
    local dvx = dsx * 2 / (w * m00)
    local dvy = -dsy * 2 / (h * m11)

    local rotation = mat4.transpose(mat4.mul(v.view, model))
    return mat4.mul_vec4(rotation, { dvx, dvy, 0, 0 })
end

local function make(name, eye, up)
    return function(w, h)
        local aspect = w / h
        return view.new(
            name,
            mat4.look_at(eye, { 0, 0, 0 }, up),
            mat4.orthographic(-orthoSize * aspect, orthoSize * aspect, -orthoSize, orthoSize, 0.1, 100),
            move_delta
        )
    end
end

local M = {}
M.x = make("ortho_x", { 5, 0, 0 }, { 0, 1, 0 })
M.y = make("ortho_y", { 0, 5, 0 }, { 0, 0, -1 })
M.z = make("ortho_z", { 0, 0, 5 }, { 0, 1, 0 })

return M
