local math = require("lib.math")
local colors = require("lib.colors")
local mat4 = require("lib.mat4")
local obj_import = require("lib.scene.obj_import")
local selection = require("lib.scene.selection")
local ortho = require("lib.view.ortho")
local four_view = require("lib.view.four_view")
local perspective = require("lib.view.perspective")

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

local currentView = 1
local sel = selection.new()
local dragViewport = nil


local views = {}
for i, factory in ipairs({
    perspective,
    ortho.x,
    ortho.y,
    ortho.z,
}) do
    views[i] = factory(canvasWidth, canvasHeigh)
end
views[#views + 1] = four_view.new(views[1], views[2], views[3], views[4])


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(colors.Black)
    screenCanvas = love.graphics.newCanvas(canvasWidth, canvasHeigh)
    for i, path in ipairs(assetPaths) do
        meshes[i] = obj_import.load(path)
    end
end

function love.update(dt)
    if rotate then
        rotation = rotation + rotationSpeed * dt
        model = mat4.rotate_y(rotation)
    end
end

local function windowToCanvas(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local ox, oy, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    return (x - ox) / s, (y - oy) / s
end

local function viewportAt(cx, cy)
    return views[currentView]:viewport_at(cx, cy, canvasWidth, canvasHeigh)
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    local cx, cy = windowToCanvas(x, y)
    local vp = viewportAt(cx, cy)
    dragViewport = vp
    selection.begin_drag(sel, vp, cx, cy)
end

function love.mousemoved(x, y)
    if not sel.dragging or not dragViewport then
        return
    end
    local cx, cy = windowToCanvas(x, y)
    selection.update_drag(sel, dragViewport, cx, cy)
end

function love.mousereleased(x, y, button)
    if button ~= 1 or not sel.dragging or not dragViewport then
        return
    end
    selection.end_drag(sel, dragViewport, meshes[currentIndex].vertices, model)
end

function love.keypressed(key, u)
    if key == "escape" then
        love.event.quit()
    end
    if key == "right" then
        currentIndex = currentIndex % #meshes + 1
        sel, dragViewport = selection.new(), nil
    end
    if key == "left" then
        currentIndex = (currentIndex - 2) % #meshes + 1
        sel, dragViewport = selection.new(), nil
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
    local v = views[currentView]
    v:draw(meshes[currentIndex], model, canvasWidth, canvasHeigh, love.graphics.setColor, love.graphics.line)

    local function drawSelectionAt(vp)
        selection.draw(sel, vp, meshes[currentIndex].vertices, model,
            love.graphics.line,
            function(x, y, r) love.graphics.circle("line", x, y, r) end)
    end

    love.graphics.setColor(colors.Yellow)
    if sel.dragging and dragViewport then
        drawSelectionAt(dragViewport)
    else
        for _, q in ipairs(v:viewports(canvasWidth, canvasHeigh)) do
            drawSelectionAt(q)
        end
    end
    love.graphics.setColor(colors.RealWhite)
    love.graphics.setCanvas()

    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas,x,y,0,s,s)
end
