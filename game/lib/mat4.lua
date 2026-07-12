local M = {}

function M.mat4_identity()
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }
end

function M.mat4_mul(a, b)
    local r = {}
    for col = 0, 3 do
        for row = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + a[k * 4 + row + 1] * b[col * 4 + k + 1]
            end
            r[col * 4 + row + 1] = sum
        end
    end
    return r
end

function M.mat4_mul_vec4(m, v)
    local r = {}
    for row = 0, 3 do
        local sum = 0
        for k = 0, 3 do
            sum = sum + m[k * 4 + row + 1] * v[k + 1]
        end
        r[row + 1] = sum
    end
    return r
end

function M.mat4_translate(x, y, z)
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        x, y, z, 1,
    }
end

-- Right-hand rule: +90 degrees carries +Y onto +Z (mat4_rotate_y/z follow
-- the same cyclic convention for their own axes).
function M.mat4_rotate_x(angle_rad)
    local c, s = math.cos(angle_rad), math.sin(angle_rad)
    return {
        1, 0, 0, 0,
        0, c, s, 0,
        0, -s, c, 0,
        0, 0, 0, 1,
    }
end

function M.mat4_rotate_y(angle_rad)
    local c, s = math.cos(angle_rad), math.sin(angle_rad)
    return {
        c, 0, -s, 0,
        0, 1, 0, 0,
        s, 0, c, 0,
        0, 0, 0, 1,
    }
end

function M.mat4_rotate_z(angle_rad)
    local c, s = math.cos(angle_rad), math.sin(angle_rad)
    return {
        c, s, 0, 0,
        -s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }
end

function M.mat4_scale(s)
    return {
        s, 0, 0, 0,
        0, s, 0, 0,
        0, 0, s, 0,
        0, 0, 0, 1,
    }
end

function M.vec3_sub(a, b)
    return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

function M.vec3_cross(a, b)
    return {
        a[2] * b[3] - a[3] * b[2],
        a[3] * b[1] - a[1] * b[3],
        a[1] * b[2] - a[2] * b[1],
    }
end

local function vec3_dot(a, b)
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local function vec3_normalize(a)
    local len = math.sqrt(vec3_dot(a, a))
    return { a[1] / len, a[2] / len, a[3] / len }
end

function M.look_at(eye, target, up)
    local f = vec3_normalize(M.vec3_sub(target, eye))
    local s = vec3_normalize(M.vec3_cross(f, up))
    local u = M.vec3_cross(s, f)
    return {
        s[1], u[1], -f[1], 0,
        s[2], u[2], -f[2], 0,
        s[3], u[3], -f[3], 0,
        -vec3_dot(s, eye), -vec3_dot(u, eye), vec3_dot(f, eye), 1,
    }
end

function M.perspective(fovy, aspect, near, far)
    local tan_half_fovy = math.tan(fovy / 2)
    return {
        1 / (aspect * tan_half_fovy), 0, 0, 0,
        0, 1 / tan_half_fovy, 0, 0,
        0, 0, -(far + near) / (far - near), -1,
        0, 0, -(2 * far * near) / (far - near), 0,
    }
end

function M.orthographic(left, right, bottom, top, near, far)
    return {
        2 / (right - left), 0, 0, 0,
        0, 2 / (top - bottom), 0, 0,
        0, 0, -2 / (far - near), 0,
        -(right + left) / (right - left), -(top + bottom) / (top - bottom), -(far + near) / (far - near), 1,
    }
end

-- TODO(refactor): introduce a shared accessor for the FOV instead of this
-- bare exported constant, which camera.lua's drag/plane-projection math
-- reads directly to stay in sync with M.perspective's fov, so this comment
-- is unnecessary.
M.FOV = math.rad(60)
local NEAR = 0.1
local FAR  = 100

function M.project(mvp, vertex, w, h)
    local clip = M.mat4_mul_vec4(mvp, { vertex[1], vertex[2], vertex[3], 1 })
    local ndc_x, ndc_y = clip[1] / clip[4], clip[2] / clip[4]
    return (ndc_x * 0.5 + 0.5) * w, (1 - (ndc_y * 0.5 + 0.5)) * h
end

function M.mvp(view, model, w, h, projection)
    model = model or M.mat4_identity()
    if not (w and h) then
        w, h = love.graphics.getDimensions()
    end
    projection = projection or M.perspective(M.FOV, w / h, NEAR, FAR)
    return M.mat4_mul(projection, M.mat4_mul(view, model)), w, h
end

return M
