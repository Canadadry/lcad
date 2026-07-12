local kind = require("lib.kind")

local T    = require("lib.t")
local test = T.test
local eq   = T.eq

test("Set tags a table with a type and returns the same table", function()
    local original = { x = 1 }
    local tagged = kind.Set(original, "Point")

    eq(tagged, original)
    eq(kind.Get(tagged), "Point")
end)

test("Get reports a placeholder for a table with no metatable", function()
    eq(kind.Get({}), "'no metatable'")
end)

test("Get reports a placeholder for a metatable with no __type", function()
    local t = setmetatable({}, {})
    eq(kind.Get(t), "'__type is nil'")
end)

test("Check returns the table unchanged when its type matches", function()
    local t = kind.Set({ x = 1 }, "Point")
    eq(kind.Check(t, "Point"), t)
end)

test("Check errors when the table's type does not match", function()
    local t = kind.Set({}, "Point")
    local ok, err = pcall(kind.Check, t, "Size")
    eq(ok, false)
    eq(err ~= nil, true)
end)

test("Check errors when the expected type argument is nil", function()
    local ok, err = pcall(kind.Check, {}, nil)
    eq(ok, false)
    eq(err ~= nil, true)
end)

test("Enum builds a constructor per value that produces a correctly-typed table", function()
    local Layout = kind.Enum("Layout", { "Vertical", "Horizontal" })

    local v = Layout.Vertical()
    eq(kind.Get(v), "Layout")
    eq(v.type, "Vertical")

    local h = Layout.Horizontal()
    eq(kind.Get(h), "Layout")
    eq(h.type, "Horizontal")
end)

test("Enum's IsValid accepts its own values and rejects values of another type", function()
    local Layout = kind.Enum("Layout", { "Vertical", "Horizontal" })
    local Size   = kind.Enum("Size", { "Small", "Large" })

    Layout.IsValid(Layout.Vertical())

    local ok, err = pcall(Layout.IsValid, Size.Small())
    eq(ok, false)
    eq(err ~= nil, true)
end)

test("Enum's constructors return the same singleton instance every call", function()
    local Layout = kind.Enum("Layout", { "Vertical", "Horizontal" })

    eq(Layout.Vertical(), Layout.Vertical())
    eq(Layout.Vertical() == Layout.Horizontal(), false)
end)

test("Enum values stringify as '<typename>.<value>'", function()
    local Layout = kind.Enum("Layout", { "Vertical", "Horizontal" })

    eq(tostring(Layout.Vertical()), "Layout.Vertical")
end)
