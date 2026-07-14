local mat4 = require("lib.mat4")

return function(w, h)
    local aspect = w / h
    return {
        name = "perspective",
        view = mat4.look_at({ 3, 2, 4 }, { 0, 0, 0 }, { 0, 1, 0 }),
        projection = mat4.perspective(math.rad(60), aspect, 0.1, 100),
    }
end
