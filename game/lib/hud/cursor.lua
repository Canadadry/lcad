local M = {}

function M.load(path, frameSize)
    local image = love.graphics.newImage(path)
    local iw, ih = image:getDimensions()
    love.mouse.setVisible(false)
    return {
        image = image,
        frameSize = frameSize,
        quads = {
            arrow = love.graphics.newQuad(0, 0, frameSize, frameSize, iw, ih),
            grab = love.graphics.newQuad(frameSize, 0, frameSize, frameSize, iw, ih),
            grabbing = love.graphics.newQuad(frameSize * 2, 0, frameSize, frameSize, iw, ih),
        },
    }
end

function M.quad_for(cursor, dragging, hovering)
    if dragging then
        return cursor.quads.grabbing
    end
    if hovering then
        return cursor.quads.grab
    end
    return cursor.quads.arrow
end

function M.draw(cursor, x, y, dragging, hovering)
    love.graphics.draw(cursor.image, M.quad_for(cursor, dragging, hovering), x, y)
end

return M
