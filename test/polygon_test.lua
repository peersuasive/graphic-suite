require("lunit")

local tostring = tostring

local imlib2 = require "imlib2"
local module = module

module("a new, empty polygon", lunit.testcase)
do
  function setup()
    a_poly = imlib2.Polygon()
  end

  function test__tostring()
    assert_string(tostring(a_poly))
  end

  function test_bounds()
    -- should have bounds of (0,0) and (0,0)
    local res = {a_poly:getBounds()}
    for i=1, 4 do assert_equal(0, res[i]) end
  end
end

module("a polygon with one point")
do
  function setup()
    a_poly = imlib2.polygon()
    a_poly:addPoint(1,2)
  end

  function test_bounds()
    local res = {a_poly:getBounds()}
    assert_equal(1, res[1])
    assert_equal(2, res[2])
    assert_equal(1, res[3])
    assert_equal(2, res[4])
  end

  function test_contains()
    assert_true(a_poly:containsPoint(1,2))
    assert_false(a_poly:containsPoint(1,1))
  end
end
