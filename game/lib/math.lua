local M = {}

function M.fit_rect(w, h, W, H)
    local scale = math.min(W / w, H / h)
    local x, y = (W - w * scale) / 2, (H - h * scale) / 2
    return x, y, scale
end

return M
