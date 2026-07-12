local math = require("lib.math")
local colors = require("lib.colors")
local cursor = require("lib.cursor")
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
local cursorIcon
local canvasWidth = 171
local canvasHeigh = 128
local selectionMarkerRadius = 3
local meshes = {}
local currentIndex = 1
local model = mat4.identity()
local rotation = 0
local rotationSpeed = _G.math.rad(45)
local rotate = false
local wasRotating = false

local sel = selection.new()


local views = {}
for i, factory in ipairs({
    ortho.x,
    ortho.y,
    ortho.z,
    perspective,
}) do
    views[i] = factory(canvasWidth, canvasHeigh)
end
views[#views + 1] = four_view.new(views[1], views[2], views[3], views[4])
local currentView = #views


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(colors.Black)
    screenCanvas = love.graphics.newCanvas(canvasWidth, canvasHeigh)
    for i, path in ipairs(assetPaths) do
        meshes[i] = obj_import.load(path)
    end
    cursorIcon = cursor.load("assets/icon.png", 8)
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

local function drawCursor()
    local mx, my = love.mouse.getPosition()
    local cx, cy = windowToCanvas(mx, my)
    local vp = viewportAt(cx, cy)
    local hovering = selection.is_near_selected(sel, vp, meshes[currentIndex].vertices, model, cx, cy,
        selectionMarkerRadius)
    cursor.draw(cursorIcon, cx, cy, sel.dragging or sel.moving, hovering)
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    local cx, cy = windowToCanvas(x, y)
    local vp = viewportAt(cx, cy)

    wasRotating = rotate
    rotate = false

    local hovering = selection.is_near_selected(sel, vp, meshes[currentIndex].vertices, model, cx, cy,
        selectionMarkerRadius)
    if hovering then
        selection.begin_move(sel, vp, meshes[currentIndex].vertices, cx, cy)
    else
        selection.begin_drag(sel, vp, cx, cy)
    end
end

function love.mousemoved(x, y)
    local cx, cy = windowToCanvas(x, y)
    if sel.moving then
        selection.update_move(sel, meshes[currentIndex].vertices, model, cx, cy)
    elseif sel.dragging then
        selection.update_drag(sel, cx, cy)
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 or not (sel.dragging or sel.moving) then
        return
    end
    if sel.moving then
        selection.end_move(sel)
    else
        selection.end_drag(sel, meshes[currentIndex].vertices, model)
    end
    rotate = wasRotating
end

function love.keypressed(key, u)
    if key == "escape" then
        love.event.quit()
    end
    if key == "right" then
        currentIndex = currentIndex % #meshes + 1
        sel = selection.new()
    end
    if key == "left" then
        currentIndex = (currentIndex - 2) % #meshes + 1
        sel = selection.new()
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

    love.graphics.setColor(colors.Yellow)
    v:draw_selected(meshes[currentIndex], sel.selected, model, canvasWidth, canvasHeigh,
        function(x, y) love.graphics.circle("line", x, y, selectionMarkerRadius) end)
    selection.draw(sel, love.graphics.line)
    love.graphics.setColor(colors.RealWhite)
    drawCursor()
    love.graphics.setCanvas()
    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas,x,y,0,s,s)
end
