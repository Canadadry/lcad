local context_menu  = require("lib.context_menu")
local screen_manager = require("ui.screen_manager")
local top_menu_bar   = require("ui.top_menu_bar")

local state        = require("state")
local scene_io      = require("scene_io")
local edit_input    = require("edit_input")
local texture_input = require("texture_input")
local screen_draw   = require("screen_draw")

function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    state.init()
    scene_io.bootstrap()
end

function love.mousepressed(x, y, button)
    if y < top_menu_bar.HEIGHT then
        -- TODO(refactor): have screen_manager.set_current (or context_menu
        -- itself) close any open menu on screen switch, so this comment is
        -- unnecessary
        context_menu.close(state.menu)
        local screen = top_menu_bar.hit_test(x, y)
        if screen then
            screen_manager.set_current(state.screens, screen)
        end
        return
    end
    if screen_manager.get_current(state.screens) ~= screen_manager.Screen.Edition() then
        texture_input.mousepressed(x, y, button)
        return
    end
    edit_input.mousepressed(x, y, button)
end

function love.keypressed(key)
    if screen_manager.get_current(state.screens) ~= screen_manager.Screen.Edition() then
        return
    end
    edit_input.keypressed(key)
end

function love.mousereleased(_, _, button)
    edit_input.mousereleased(button)
    if button == 1 then
        state.dragging_camera = nil
        state.drag_instance   = nil
        state.drag_camera     = nil
        state.drag_vertices   = false
        state.drag_uv_point   = false
        state.paint_stroke    = nil
    end
end

function love.mousemoved(x, y, dx, dy)
    if screen_manager.get_current(state.screens) ~= screen_manager.Screen.Edition() then
        texture_input.mousemoved(x, y, dx, dy)
        return
    end
    edit_input.mousemoved(x, y, dx, dy)
end

function love.wheelmoved(dx, dy)
    if screen_manager.get_current(state.screens) ~= screen_manager.Screen.Edition() then
        texture_input.wheelmoved(dx, dy)
        return
    end
    edit_input.wheelmoved(dx, dy)
end

function love.draw()
    screen_draw.draw()
end
