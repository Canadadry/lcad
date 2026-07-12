-- Headless config for the csv2png tool: no window, only the modules
-- love.image actually needs (image, data, filesystem, event).
function love.conf(t)
    t.window = false
    t.console = false

    t.modules.audio = false
    t.modules.data = true
    t.modules.event = true
    t.modules.font = false
    t.modules.graphics = false
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = false
    t.modules.math = false
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.system = false
    t.modules.thread = false
    t.modules.timer = false
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = false
end
