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

function M.transpose(m)
    local r = {}
    for col = 0, 3 do
        for row = 0, 3 do
            r[row * 4 + col + 1] = m[col * 4 + row + 1]
        end
    end
    return r
end

local function elem(m, row, col)
    return m[col * 4 + row + 1]
end

local function det3(a, b, c, d, e, f, g, h, i)
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
end

local function minor(m, skip_row, skip_col)
    local vals = {}
    for row = 0, 3 do
        if row ~= skip_row then
            for col = 0, 3 do
                if col ~= skip_col then
                    vals[#vals + 1] = elem(m, row, col)
                end
            end
        end
    end
    return det3(vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], vals[8], vals[9])
end

local function cofactor(m, row, col)
    local sign = ((row + col) % 2 == 0) and 1 or -1
    return sign * minor(m, row, col)
end

function M.invert(m)
    local det = 0
    for col = 0, 3 do
        det = det + elem(m, 0, col) * cofactor(m, 0, col)
    end

    local r = {}
    for row = 0, 3 do
        for col = 0, 3 do
            r[col * 4 + row + 1] = cofactor(m, col, row) / det
        end
    end
    return r
end

function M.depth_of(view, point)
    return M.mul_vec4(view, { point[1], point[2], point[3], 1 })[3]
end

function M.world_to_screen(view, projection, point, w, h)
    return M.project(M.mul(projection, view), point, w, h)
end

function M.screen_to_world(view, projection, sx, sy, depth, w, h)
    local view_x, view_y = M.unproject(projection, sx, sy, depth, w, h)
    local p = M.mul_vec4(M.invert(view), { view_x, view_y, depth, 1 })
    return p[1], p[2], p[3]
end

function M.project(mvp, vertex, w, h)
    local clip = M.mul_vec4(mvp, { vertex[1], vertex[2], vertex[3], 1 })
    local ndc_x, ndc_y = clip[1] / clip[4], clip[2] / clip[4]
    return (ndc_x * 0.5 + 0.5) * w, (1 - (ndc_y * 0.5 + 0.5)) * h
end

function M.unproject(proj, sx, sy, depth, w, h)
    local clip_w = proj[12] * depth + proj[16]
    local ndc_x = (sx / w) * 2 - 1
    local ndc_y = 1 - (sy / h) * 2
    return ndc_x * clip_w / proj[1], ndc_y * clip_w / proj[6]
end

return M
