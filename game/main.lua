local math = require("lib.math")
local colors = require("lib.colors")
local mat4 = require("lib.mat4")
local obj_import = require("lib.scene.obj_import")
local mesh = require("lib.scene.mesh")
local gizmo = require("lib.scene.gizmo")

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
local mvp
local rotation = 0
local rotationSpeed = _G.math.rad(45)

local aspect = canvasWidth / canvasHeigh
local orthoSize = 3
local projectionNames = { "perspective", "ortho_x", "ortho_y", "ortho_z" }
local currentProjection = 1
local views = {
    perspective = mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 }),
    ortho_x = mat4.look_at({ 5, 0, 0 }, { 0, 0, 0 }, { 0, 1, 0 }),
    ortho_y = mat4.look_at({ 0, 5, 0 }, { 0, 0, 0 }, { 0, 0, -1 }),
    ortho_z = mat4.look_at({ 0, 0, 5 }, { 0, 0, 0 }, { 0, 1, 0 }),
}
local projections = {
    perspective = mat4.perspective(_G.math.rad(60), aspect, 0.1, 100),
    ortho_x = mat4.orthographic(-orthoSize * aspect, orthoSize * aspect, -orthoSize, orthoSize, 0.1, 100),
    ortho_y = mat4.orthographic(-orthoSize * aspect, orthoSize * aspect, -orthoSize, orthoSize, 0.1, 100),
    ortho_z = mat4.orthographic(-orthoSize * aspect, orthoSize * aspect, -orthoSize, orthoSize, 0.1, 100),
}

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
    rotation = rotation + rotationSpeed * dt
    local model = mat4.rotate_y(rotation)
    local name = projectionNames[currentProjection]
    mvp = mat4.mul(projections[name], mat4.mul(views[name], model))
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
        currentProjection = currentProjection % #projectionNames + 1
    end
    if key == "up" then
        currentProjection = (currentProjection - 2) % #projectionNames + 1
    end
end

function love.draw()
    love.graphics.setCanvas(screenCanvas)
    love.graphics.clear(colors.DarkGray)
    love.graphics.setColor(colors.RealWhite)
    mesh.draw(meshes[currentIndex],mvp,canvasWidth, canvasHeigh,love.graphics.line)
    gizmo.draw(mvp, canvasWidth, canvasHeigh, function(x1, y1, x2, y2, color)
        love.graphics.setColor(color)
        love.graphics.line(x1, y1, x2, y2)
        love.graphics.setColor(colors.RealWhite)
    end)
    love.graphics.setCanvas()

    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas,x,y,0,s,s)
end
