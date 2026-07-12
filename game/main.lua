local math = require("lib.math")
local colors = require("lib.colors")
local mat4 = require("lib.mat4")
local obj_import = require("lib.scene.obj_import")

local ortho = require("lib.view.ortho")
local four_view = require("lib.view.four_view")
local viewFactories = {
    require("lib.view.perspective"),
    ortho.x,
    ortho.y,
    ortho.z,
}

local assetPaths = {
    "assets/cube.obj",
    "assets/cylinder.obj",
    "assets/prism.obj",
    "assets/pyramid.obj",
    "assets/sphere.obj",
}

local screenCanvas
local canvasWidth = 171
local canvasHeigh = 128
local meshes = {}
local currentIndex = 1
local model = mat4.identity()
local rotation = 0
local rotationSpeed = _G.math.rad(45)
local rotate = true

local views = {}
local currentView = 1

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(colors.Black)
    screenCanvas = love.graphics.newCanvas(canvasWidth, canvasHeigh)
    for i, path in ipairs(assetPaths) do
        meshes[i] = obj_import.load(path)
    end
    for i, factory in ipairs(viewFactories) do
        views[i] = factory(canvasWidth, canvasHeigh)
    end
    views[#views + 1] = four_view.new(views[1], views[2], views[3], views[4])
end

function love.update(dt)
    if rotate then
        rotation = rotation + rotationSpeed * dt
        model = mat4.rotate_y(rotation)
    end
end

function love.keypressed(key, u)
    if key == "escape" then
        love.event.quit()
    end
    if key == "right" then
        currentIndex = currentIndex % #meshes + 1
    end
    if key == "left" then
        currentIndex = (currentIndex - 2) % #meshes + 1
    end
    if key == "down" then
        currentView = currentView % #views + 1
    end
    if key == "up" then
        currentView = (currentView - 2) % #views + 1
    end
    if key == "space" then
        rotate = not rotate
    end
end

function love.draw()
    love.graphics.setCanvas(screenCanvas)
    love.graphics.clear(colors.DarkGray)
    views[currentView]:draw(meshes[currentIndex], model, canvasWidth, canvasHeigh, love.graphics.setColor, love.graphics.line)
    love.graphics.setCanvas()

    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas,x,y,0,s,s)
end
