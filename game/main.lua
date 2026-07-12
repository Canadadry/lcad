local math = require("lib.math")
local colors = require("lib.colors")
local mat4 = require("lib.mat4")
local obj_import = require("lib.scene.obj_import")
local selection = require("lib.scene.selection")

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
local sel = selection.new()
-- viewport a drag is locked to, valid only while sel.dragging is true
local dragViewport = nil

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

local function windowToCanvas(x, y)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local ox, oy, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    return (x - ox) / s, (y - oy) / s
end

-- resolves which view a canvas point belongs to: the view itself when in
-- single-view mode, or whichever four_view quadrant contains the point
local function viewportAt(cx, cy)
    local v = views[currentView]
    if v.mvp then
        return { view = v, ox = 0, oy = 0, w = canvasWidth, h = canvasHeigh }
    end
    if v.views then
        local _, qv, ox, oy, qw, qh = four_view.locate(v, cx, cy, canvasWidth, canvasHeigh)
        return { view = qv, ox = ox, oy = oy, w = qw, h = qh }
    end
    return nil
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    local cx, cy = windowToCanvas(x, y)
    local vp = viewportAt(cx, cy)
    if not vp then
        return
    end
    dragViewport = vp
    selection.begin_drag(sel, cx - vp.ox, cy - vp.oy, vp.w, vp.h)
end

function love.mousemoved(x, y)
    if not sel.dragging or not dragViewport then
        return
    end
    local cx, cy = windowToCanvas(x, y)
    selection.update_drag(sel, cx - dragViewport.ox, cy - dragViewport.oy, dragViewport.w, dragViewport.h)
end

function love.mousereleased(x, y, button)
    if button ~= 1 or not sel.dragging or not dragViewport then
        return
    end
    selection.end_drag(sel, meshes[currentIndex].vertices, dragViewport.view:mvp(model), dragViewport.w, dragViewport.h)
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
        local ox, oy = vp.ox, vp.oy
        selection.draw(sel, meshes[currentIndex].vertices, vp.view:mvp(model), vp.w, vp.h,
            function(x1, y1, x2, y2) love.graphics.line(x1 + ox, y1 + oy, x2 + ox, y2 + oy) end,
            function(x, y, r) love.graphics.circle("line", x + ox, y + oy, r) end)
    end

    love.graphics.setColor(colors.Yellow)
    if sel.dragging and dragViewport then
        drawSelectionAt(dragViewport)
    elseif v.mvp then
        drawSelectionAt({ view = v, ox = 0, oy = 0, w = canvasWidth, h = canvasHeigh })
    elseif v.views then
        for _, q in ipairs(four_view.quadrants(v, canvasWidth, canvasHeigh)) do
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
