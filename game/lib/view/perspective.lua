local mat4 = require("lib.mat4")
local view = require("lib.view.view")

-- Perspective projection scales a screen-space delta by depth, so unlike an
-- orthographic view we need a depth to hold fixed. model is always a pure
-- rotation here (no translation), so the object's local origin never moves
-- under it - its view-space depth is a stable reference plane, parallel to
-- the screen, that the rest of the selection moves along together.
local function move_delta(v, model, w, h, dsx, dsy)
    local rotation = mat4.mul(v.view, model)
    local view_z = mat4.mul_vec4(rotation, { 0, 0, 0, 1 })[3]

    local proj = v.projection
    local m00, m11 = proj[1], proj[6]
    local dvx = -dsx * 2 * view_z / (w * m00)
    local dvy = dsy * 2 * view_z / (h * m11)

    return mat4.mul_vec4(mat4.transpose(rotation), { dvx, dvy, 0, 0 })
end

return function(w, h)
    local aspect = w / h
    return view.new(
        "perspective",
        mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 }),
        mat4.perspective(math.rad(60), aspect, 0.1, 100),
        move_delta
    )
end
