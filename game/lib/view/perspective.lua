local mat4 = require("lib.mat4")
local view = require("lib.view.view")

return function(w, h)
    local aspect = w / h
    return view.new(
        "perspective",
        mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 }),
        mat4.perspective(math.rad(60), aspect, 0.1, 100)
    )
end
