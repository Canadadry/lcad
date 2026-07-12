local rectmath = require("lib.math")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("fit_rect fills the outer rect exactly when aspect ratios match", function()
    local x, y, scale = rectmath.fit_rect(200, 100, 400, 200)
    eq(x, 0)
    eq(y, 0)
    eq(scale, 2)
end)

test("fit_rect letterboxes (bars on top/bottom) when the inner rect is wider than the outer", function()
    -- inner aspect 2:1, outer aspect 1:1 -> width-constrained, centered vertically
    local x, y, scale = rectmath.fit_rect(200, 100, 200, 200)
    eq(x, 0)
    eq(scale, 1)
    eq(y, 50)
end)

test("fit_rect pillarboxes (bars on left/right) when the inner rect is taller than the outer", function()
    -- inner aspect 1:2, outer aspect 1:1 -> height-constrained, centered horizontally
    local x, y, scale = rectmath.fit_rect(100, 200, 200, 200)
    eq(y, 0)
    eq(scale, 1)
    eq(x, 50)
end)

test("fit_rect upscales a small inner rect to fill a larger outer rect", function()
    local x, y, scale = rectmath.fit_rect(10, 10, 100, 100)
    eq(x, 0)
    eq(y, 0)
    eq(scale, 10)
end)

T.report()
