local vec3 = require("lib.vec3")

local M = {}

function M.identity()
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }
end

function M.mul(a, b)
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

function M.mul_vec4(m, v)
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

function M.translate(x, y, z)
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        x, y, z, 1,
    }
end

function M.rotate_x(angle_rad)
    local c, s = math.cos(angle_rad), math.sin(angle_rad)
    return {
        1, 0, 0, 0,
        0, c, s, 0,
        0, -s, c, 0,
        0, 0, 0, 1,
    }
end

function M.rotate_y(angle_rad)
    local c, s = math.cos(angle_rad), math.sin(angle_rad)
    return {
        c, 0, -s, 0,
        0, 1, 0, 0,
        s, 0, c, 0,
        0, 0, 0, 1,
    }
end

function M.rotate_z(angle_rad)
    local c, s = math.cos(angle_rad), math.sin(angle_rad)
    return {
        c, s, 0, 0,
        -s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }
end

function M.scale(s)
    return {
        s, 0, 0, 0,
        0, s, 0, 0,
        0, 0, s, 0,
        0, 0, 0, 1,
    }
end


function M.look_at(eye, target, up)
    local f = vec3.normalize(vec3.sub(target, eye))
    local s = vec3.normalize(vec3.cross(f, up))
    local u = vec3.cross(s, f)
    return {
        s[1], u[1], -f[1], 0,
        s[2], u[2], -f[2], 0,
        s[3], u[3], -f[3], 0,
        -vec3.dot(s, eye), -vec3.dot(u, eye), vec3.dot(f, eye), 1,
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

function M.project(mvp, vertex, w, h)
    local clip = M.mul_vec4(mvp, { vertex[1], vertex[2], vertex[3], 1 })
    local ndc_x, ndc_y = clip[1] / clip[4], clip[2] / clip[4]
    return (ndc_x * 0.5 + 0.5) * w, (1 - (ndc_y * 0.5 + 0.5)) * h
end

return M
