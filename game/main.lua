local math = require("lib.math")
local colors = require("lib.colors")

local screenCanvas
local canvasWidth = 171
local canvasHeigh = 128

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    screenCanvas = love.graphics.newCanvas(canvasWidth, canvasHeigh)
end

function love.keypressed(key, u)
    --Debug
    if key == "space" then --set to whatever key you want to use
        debug.debug()
    end
    if key == "escape" then --set to whatever key you want to use
        love.event.quit()
    end
end

function love.draw()
    love.graphics.setCanvas(screenCanvas)
    love.graphics.clear(colors.DarkGray)
    love.graphics.setColor(colors.Pink)
    love.graphics.rectangle("fill", 100, 50, 50, 50)
    love.graphics.setColor(colors.RealWhite)
    love.graphics.rectangle("line", 100, 50, 50, 50)
    love.graphics.rectangle("fill", 50, 20, 25, 25)
    love.graphics.setCanvas()

    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas,x,y,0,s,s)
end
