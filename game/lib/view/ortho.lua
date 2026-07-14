local mat4 = require("lib.mat4")

local orthoSize = 3

local function make(name, eye, up)
    return function(w, h)
        local aspect = w / h
        return {
            name = name,
            view = mat4.look_at(eye, { 0, 0, 0 }, up),
            projection = mat4.orthographic(-orthoSize * aspect, orthoSize * aspect, -orthoSize, orthoSize, 0.1, 100),
        }
    end
end

local M = {}
M.x = make("ortho_x", { 5, 0, 0 }, { 0, 1, 0 })
M.y = make("ortho_y", { 0, 5, 0 }, { 0, 0, -1 })
M.z = make("ortho_z", { 0, 0, 5 }, { 0, 1, 0 })

return M
