local const = require("const")
local colors = require("lib.colors")
local cursor = require("lib.hud.cursor")
local mat4 = require("lib.math.mat4")
local obj_import = require("lib.scene.obj_import")
local selection = require("lib.scene.selection")
local wireframe = require("lib.render.wireframe")
local gizmo = require("lib.hud.gizmo")
local hud_selection = require("lib.hud.selection")

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

local orthoSize = 3
local aspect = const.canvasWidth / const.canvasHeight

local function orthoView(name, eye, up)
    return {
        name = name,
        view = mat4.look_at(eye, { 0, 0, 0 }, up),
        projection = mat4.orthographic(-orthoSize * aspect, orthoSize * aspect, -orthoSize, orthoSize, 0.1, 100),
    }
end

local views = {
    orthoView("ortho_x", { 5, 0, 0 }, { 0, 1, 0 }),
    orthoView("ortho_y", { 0, 5, 0 }, { 0, 0, -1 }),
    orthoView("ortho_z", { 0, 0, 5 }, { 0, 1, 0 }),
    {
        name = "perspective",
        view = mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 }),
        projection = mat4.perspective(math.rad(60), aspect, 0.1, 100),
    },
}

local quadrantOffsets = {
    { ox = 0, oy = 0 },
    { ox = 1, oy = 0 },
    { ox = 0, oy = 1 },
    { ox = 1, oy = 1 },
}

local function quadrants(w, h)
    local hw, hh = w / 2, h / 2
    local qs = {}
    for i, v in ipairs(views) do
        local o = quadrantOffsets[i]
        qs[i] = { view = v, ox = o.ox * hw, oy = o.oy * hh, w = hw, h = hh }
    end
    return qs
end

local function locate(x, y, w, h)
    local hw, hh = w / 2, h / 2
    local qx, qy = x < hw and 0 or 1, y < hh and 0 or 1
    return quadrants(w, h)[1 + qx + 2 * qy]
end

local function viewportAt(cx, cy)
    return locate(cx, cy, const.canvasWidth, const.canvasHeight)
end

local M = {}

function M:load()
    for i, path in ipairs(assetPaths) do
        meshes[i] = obj_import.load(path)
    end
    cursorIcon = cursor.load("assets/icon.png", 8)
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
end

local function drawViewport(v, w, h)
    local mvp = mat4.mul(v.projection, v.view)
    wireframe.draw(meshes[currentIndex], mvp, w, h, colors.RealWhite)
    gizmo.draw(mvp, w, h)
    hud_selection.draw(v, meshes[currentIndex], sel, mvp, w, h, selectionMarkerRadius, colors.Yellow)
end

function M:draw(cx, cy)
    love.graphics.clear(colors.DarkGray)

    for _, q in ipairs(quadrants(const.canvasWidth, const.canvasHeight)) do
        love.graphics.push()
        love.graphics.translate(q.ox, q.oy)
        drawViewport(q.view, q.w, q.h)
        love.graphics.pop()
    end
    love.graphics.setColor(colors.RealWhite)
    local hw, hh = const.canvasWidth / 2, const.canvasHeight / 2
    love.graphics.line(hw, 0, hw, const.canvasHeight)
    love.graphics.line(0, hh, const.canvasWidth, hh)

    drawCursor(cx, cy)
end

return M
