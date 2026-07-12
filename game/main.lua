local math = require("lib.math")
local colors = require("lib.colors")
local const = require("const")
local screen_manager = require("lib.screen_manager")
local editor = require("screen.editor")

local screenCanvas
local manager = screen_manager.new()
manager:enter(editor)

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(colors.Black)
    screenCanvas = love.graphics.newCanvas(const.canvasWidth, const.canvasHeight)
    manager:emit("load")
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end
    manager:emit("keypressed", key)
end

local function windowToCanvas(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local ox, oy, s = math.fit_rect(const.canvasWidth, const.canvasHeight, windowWidth, windowHeight)
    return (x - ox) / s, (y - oy) / s
end

function love.mousepressed(x, y, button)
    local cx, cy = windowToCanvas(x, y)
    manager:emit("mousepressed", cx, cy, button)
end

function love.mousemoved(x, y)
    local cx, cy = windowToCanvas(x, y)
    manager:emit("mousemoved", cx, cy)
end

function love.mousereleased(x, y, button)
    local cx, cy = windowToCanvas(x, y)
    manager:emit("mousereleased", cx, cy, button)
end

function love.draw()
    love.graphics.setCanvas(screenCanvas)
    local mx, my = love.mouse.getPosition()
    local cx, cy = windowToCanvas(mx, my)
    manager:emit("draw", cx, cy)
    love.graphics.setCanvas()
    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(const.canvasWidth, const.canvasHeight, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas, x, y, 0, s, s)
end
