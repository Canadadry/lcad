local math = require("lib.math")
local colors = require("lib.colors")
local mat4 = require("lib.mat4")
local obj_import = require("lib.scene.obj_import")

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
local view
local proj
local mvp
local rotation = 0
local rotationSpeed = _G.math.rad(45)

local function draw_mesh(mesh)
    for _, face in ipairs(mesh.faces) do
        local n = #face
        for i = 1, n do
            local a = mesh.vertices[face[i]]
            local b = mesh.vertices[face[(i % n) + 1]]
            local x1, y1 = mat4.project(mvp, a, canvasWidth, canvasHeigh)
            local x2, y2 = mat4.project(mvp, b, canvasWidth, canvasHeigh)
            love.graphics.line(x1, y1, x2, y2)
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setBackgroundColor(colors.Black)
    screenCanvas = love.graphics.newCanvas(canvasWidth, canvasHeigh)

    for i, path in ipairs(assetPaths) do
        meshes[i] = obj_import.load(path)
    end

    view = mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 })
    proj = mat4.perspective(_G.math.rad(60), canvasWidth / canvasHeigh, 0.1, 100)
end

function love.update(dt)
    rotation = rotation + rotationSpeed * dt
    local model = mat4.rotate_y(rotation)
    mvp = mat4.mul(proj, mat4.mul(view, model))
end

function love.keypressed(key, u)
    if key == "escape" then --set to whatever key you want to use
        love.event.quit()
    end
    if key == "space" then
        currentIndex = currentIndex % #meshes + 1
    end
end

function love.draw()
    love.graphics.setCanvas(screenCanvas)
    love.graphics.clear(colors.DarkGray)
    love.graphics.setColor(colors.RealWhite)
    draw_mesh(meshes[currentIndex])
    love.graphics.setCanvas()

    love.graphics.clear(colors.Black)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local x, y, s = math.fit_rect(canvasWidth, canvasHeigh, windowWidth, windowHeight)
    love.graphics.draw(screenCanvas,x,y,0,s,s)
end
