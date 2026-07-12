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

function M.draw(cursor, x, y, dragging)
    local quad = dragging and cursor.quads.grabbing or cursor.quads.arrow
    love.graphics.draw(cursor.image, quad, x, y)
end

return M
