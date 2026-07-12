local const = require("const")
local colors = require("lib.colors")
local cursor = require("lib.cursor")
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

local selectionMarkerRadius = 3
local meshes = {}
local currentIndex = 1
local cursorIcon

local sel = selection.new()

local views = {}
for i, factory in ipairs({
    ortho.x,
    ortho.y,
    ortho.z,
    perspective,
}) do
    views[i] = factory(const.canvasWidth, const.canvasHeight)
end
views[#views + 1] = four_view.new(views[1], views[2], views[3], views[4])
local currentView = #views

local M = {}

function M:load()
    for i, path in ipairs(assetPaths) do
        meshes[i] = obj_import.load(path)
    end
    cursorIcon = cursor.load("assets/icon.png", 8)
end

local function viewportAt(cx, cy)
    return views[currentView]:viewport_at(cx, cy, const.canvasWidth, const.canvasHeight)
end

local function drawCursor(cx, cy)
    local vp = viewportAt(cx, cy)
    local hovering = selection.is_near_selected(sel, vp, meshes[currentIndex].vertices, cx, cy,
        selectionMarkerRadius)
    cursor.draw(cursorIcon, cx, cy, sel.dragging or sel.moving, hovering)
end

function M:mousepressed(cx, cy, button)
    if button ~= 1 then
        return
    end
    local vp = viewportAt(cx, cy)

    local hovering = selection.is_near_selected(sel, vp, meshes[currentIndex].vertices, cx, cy,
        selectionMarkerRadius)
    if hovering then
        selection.begin_move(sel, vp, meshes[currentIndex].vertices, cx, cy)
    else
        selection.begin_drag(sel, vp, cx, cy)
    end
end

function M:mousemoved(cx, cy)
    if sel.moving then
        selection.update_move(sel, meshes[currentIndex].vertices, cx, cy)
    elseif sel.dragging then
        selection.update_drag(sel, cx, cy)
    end
end

function M:mousereleased(cx, cy, button)
    if button ~= 1 or not (sel.dragging or sel.moving) then
        return
    end
    if sel.moving then
        selection.end_move(sel)
    else
        selection.end_drag(sel, meshes[currentIndex].vertices)
    end
end

function M:keypressed(key)
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
end

function M:draw(cx, cy)
    love.graphics.clear(colors.DarkGray)
    local v = views[currentView]
    v:draw(meshes[currentIndex], const.canvasWidth, const.canvasHeight, love.graphics.setColor, love.graphics.line)

    love.graphics.setColor(colors.Yellow)
    v:draw_selected(meshes[currentIndex], sel.selected, const.canvasWidth, const.canvasHeight,
        function(x, y) love.graphics.circle("line", x, y, selectionMarkerRadius) end)
    selection.draw(sel, love.graphics.line)
    love.graphics.setColor(colors.RealWhite)
    drawCursor(cx, cy)
end

return M
