local mat4 = require("lib.mat4")
local colors = require("lib.colors")

local M = {}

local axes = {
    { dir = { 1, 0, 0 }, color = colors.Red },
    { dir = { 0, 1, 0 }, color = colors.Green },
    { dir = { 0, 0, 1 }, color = colors.Blue },
}

function M.draw(mvp, w, h, length)
    length = length or 1
    local ox, oy = mat4.project(mvp, { 0, 0, 0 }, w, h)
    for _, axis in ipairs(axes) do
        local tip = { axis.dir[1] * length, axis.dir[2] * length, axis.dir[3] * length }
        local ex, ey = mat4.project(mvp, tip, w, h)
        love.graphics.setColor(axis.color)
        love.graphics.line(ox, oy, ex, ey)
    end
end

return M
