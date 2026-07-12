local cursor = require("lib.cursor")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

local function fake_cursor()
    return { quads = { arrow = "arrow", grab = "grab", grabbing = "grabbing" } }
end

test("quad_for() picks the grabbing quad while dragging", function()
    local c = fake_cursor()

    eq(cursor.quad_for(c, true, false), "grabbing")
end)

test("quad_for() picks the grab quad while hovering near a selected vertex, when not dragging", function()
    local c = fake_cursor()

    eq(cursor.quad_for(c, false, true), "grab")
end)

test("quad_for() picks the arrow quad when neither dragging nor hovering", function()
    local c = fake_cursor()

    eq(cursor.quad_for(c, false, false), "arrow")
end)

test("quad_for() prefers grabbing over grab when both dragging and hovering", function()
    local c = fake_cursor()

    eq(cursor.quad_for(c, true, true), "grabbing")
end)

T.report()
