local colors = require("lib.colors")

local M = {}

local offsets = {
    { ox = 0, oy = 0 }, -- topLeft
    { ox = 1, oy = 0 }, -- topRight
    { ox = 0, oy = 1 }, -- bottomLeft
    { ox = 1, oy = 1 }, -- bottomRight
}

function M.draw(fv, sceneMesh, model, w, h, setColor, drawLine)
    local hw, hh = w / 2, h / 2
    for i, v in ipairs(fv.views) do
        local ox, oy = offsets[i].ox * hw, offsets[i].oy * hh
        v:draw(sceneMesh, model, hw, hh, setColor, function(x1, y1, x2, y2)
            drawLine(x1 + ox, y1 + oy, x2 + ox, y2 + oy)
        end)
    end

    setColor(colors.White)
    drawLine(hw, 0, hw, h)
    drawLine(0, hh, w, hh)
end

function M.draw_selected(fv, sceneMesh, selected, model, w, h, drawCircle)
    local hw, hh = w / 2, h / 2
    for i, v in ipairs(fv.views) do
        local ox, oy = offsets[i].ox * hw, offsets[i].oy * hh
        v:draw_selected(sceneMesh, selected, model, hw, hh, function(x, y)
            drawCircle(x + ox, y + oy)
        end)
    end
end

function M.quadrants(fv, w, h)
    local hw, hh = w / 2, h / 2
    local qs = {}
    for i, v in ipairs(fv.views) do
        qs[i] = { view = v, ox = offsets[i].ox * hw, oy = offsets[i].oy * hh, w = hw, h = hh }
    end
    return qs
end

function M.locate(fv, x, y, w, h)
    local hw, hh = w / 2, h / 2
    local qx, qy = x < hw and 0 or 1, y < hh and 0 or 1
    local i = 1 + qx + 2 * qy
    local q = M.quadrants(fv, w, h)[i]
    return i, q.view, q.ox, q.oy, q.w, q.h
end

function M.viewport_at(fv, x, y, w, h)
    local _, qv, ox, oy, qw, qh = M.locate(fv, x, y, w, h)
    return { view = qv, ox = ox, oy = oy, w = qw, h = qh }
end

function M.new(topLeft, topRight, bottomLeft, bottomRight)
    return {
        views = { topLeft, topRight, bottomLeft, bottomRight },
        draw = M.draw,
        draw_selected = M.draw_selected,
        viewport_at = M.viewport_at,
    }
end

return M
