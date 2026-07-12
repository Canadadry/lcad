local four_view = require("lib.view.four_view")
local view = require("lib.view.view")
local mesh = require("lib.scene.mesh")
local mat4 = require("lib.mat4")
local colors = require("lib.colors")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("new() stores the 4 views as topLeft, topRight, bottomLeft, bottomRight", function()
    local tl = view.new("tl", mat4.identity(), mat4.identity())
    local tr = view.new("tr", mat4.identity(), mat4.identity())
    local bl = view.new("bl", mat4.identity(), mat4.identity())
    local br = view.new("br", mat4.identity(), mat4.identity())

    local fv = four_view.new(tl, tr, bl, br)

    eq(fv.views[1], tl)
    eq(fv.views[2], tr)
    eq(fv.views[3], bl)
    eq(fv.views[4], br)
end)

local function in_range(v, lo, hi, msg)
    if v < lo or v > hi then
        error((msg or "in_range") .. ": expected " .. tostring(v) .. " within [" .. lo .. ", " .. hi .. "]", 2)
    end
end

test("draw() renders each of the 4 views into its own screen quadrant", function()
    local tl = view.new("tl", mat4.identity(), mat4.identity())
    local tr = view.new("tr", mat4.identity(), mat4.identity())
    local bl = view.new("bl", mat4.identity(), mat4.identity())
    local br = view.new("br", mat4.identity(), mat4.identity())
    local fv = four_view.new(tl, tr, bl, br)

    local m = mesh.new(
        { { 0, 0, 0 }, { 0, 0, 0 } },
        {},
        { { 1, 2 } }
    )

    local w, h = 100, 80
    local hw, hh = w / 2, h / 2
    local lines = {}
    local setColor = function() end
    local drawLine = function(x1, y1, x2, y2) table.insert(lines, { x1, y1, x2, y2 }) end

    fv:draw(m, mat4.identity(), w, h, setColor, drawLine)

    -- 5 lines per view (2 mesh edges + 3 gizmo axes), in view order: tl, tr, bl, br,
    -- plus 2 divider lines drawn after all views
    eq(#lines, 22)

    local quadrants = {
        { ox = 0,  oy = 0 },  -- tl
        { ox = hw, oy = 0 },  -- tr
        { ox = 0,  oy = hh }, -- bl
        { ox = hw, oy = hh }, -- br
    }
    for viewIndex, quad in ipairs(quadrants) do
        for lineIndex = 1, 5 do
            local line = lines[(viewIndex - 1) * 5 + lineIndex]
            in_range(line[1], quad.ox, quad.ox + hw, "view " .. viewIndex .. " line " .. lineIndex .. " x1")
            in_range(line[3], quad.ox, quad.ox + hw, "view " .. viewIndex .. " line " .. lineIndex .. " x2")
            in_range(line[2], quad.oy, quad.oy + hh, "view " .. viewIndex .. " line " .. lineIndex .. " y1")
            in_range(line[4], quad.oy, quad.oy + hh, "view " .. viewIndex .. " line " .. lineIndex .. " y2")
        end
    end
end)

test("draw() splits the quadrants with a white cross line after drawing the views", function()
    local blank = view.new("blank", mat4.identity(), mat4.identity())
    local fv = four_view.new(blank, blank, blank, blank)

    local m = mesh.new({}, {}, {})

    local w, h = 100, 80
    local hw, hh = w / 2, h / 2
    local colorCalls = {}
    local lines = {}
    local setColor = function(c) table.insert(colorCalls, c) end
    local drawLine = function(x1, y1, x2, y2) table.insert(lines, { x1, y1, x2, y2 }) end

    fv:draw(m, mat4.identity(), w, h, setColor, drawLine)

    -- last color set is white, then a vertical and a horizontal divider line
    -- span the last 2 of the captured lines (after each view's own gizmo lines)
    local vertical, horizontal = lines[#lines - 1], lines[#lines]
    eq(colorCalls[#colorCalls], colors.White)
    eq(vertical[1], hw);   eq(vertical[2], 0);  eq(vertical[3], hw); eq(vertical[4], h)
    eq(horizontal[1], 0);  eq(horizontal[2], hh); eq(horizontal[3], w);  eq(horizontal[4], hh)
end)

test("locate() resolves the quadrant, its view and its screen offset for a point in the top-left quadrant", function()
    local tl = view.new("tl", mat4.identity(), mat4.identity())
    local tr = view.new("tr", mat4.identity(), mat4.identity())
    local bl = view.new("bl", mat4.identity(), mat4.identity())
    local br = view.new("br", mat4.identity(), mat4.identity())
    local fv = four_view.new(tl, tr, bl, br)

    local i, v, ox, oy, qw, qh = four_view.locate(fv, 10, 10, 100, 80)

    eq(i, 1)
    eq(v, tl)
    eq(ox, 0)
    eq(oy, 0)
    eq(qw, 50)
    eq(qh, 40)
end)

test("locate() resolves the bottom-right quadrant for a point past the midpoint on both axes", function()
    local tl = view.new("tl", mat4.identity(), mat4.identity())
    local tr = view.new("tr", mat4.identity(), mat4.identity())
    local bl = view.new("bl", mat4.identity(), mat4.identity())
    local br = view.new("br", mat4.identity(), mat4.identity())
    local fv = four_view.new(tl, tr, bl, br)

    local i, v, ox, oy, qw, qh = four_view.locate(fv, 90, 70, 100, 80)

    eq(i, 4)
    eq(v, br)
    eq(ox, 50)
    eq(oy, 40)
    eq(qw, 50)
    eq(qh, 40)
end)

test("quadrants() returns the 4 views paired with their screen offset and size, in tl/tr/bl/br order", function()
    local tl = view.new("tl", mat4.identity(), mat4.identity())
    local tr = view.new("tr", mat4.identity(), mat4.identity())
    local bl = view.new("bl", mat4.identity(), mat4.identity())
    local br = view.new("br", mat4.identity(), mat4.identity())
    local fv = four_view.new(tl, tr, bl, br)

    local qs = four_view.quadrants(fv, 100, 80)

    eq(#qs, 4)
    eq(qs[1].view, tl); eq(qs[1].ox, 0);  eq(qs[1].oy, 0);  eq(qs[1].w, 50); eq(qs[1].h, 40)
    eq(qs[2].view, tr); eq(qs[2].ox, 50); eq(qs[2].oy, 0);  eq(qs[2].w, 50); eq(qs[2].h, 40)
    eq(qs[3].view, bl); eq(qs[3].ox, 0);  eq(qs[3].oy, 40); eq(qs[3].w, 50); eq(qs[3].h, 40)
    eq(qs[4].view, br); eq(qs[4].ox, 50); eq(qs[4].oy, 40); eq(qs[4].w, 50); eq(qs[4].h, 40)
end)

T.report()
