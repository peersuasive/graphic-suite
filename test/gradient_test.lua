require("lunit")

local tostring = tostring
local imlib2 = require "imlib2"

module("a newly created gradient", lunit.testcase)
do
  function setup()
    a_gradient = imlib2.Gradient()
  end

  function test__tostring()
    assert_string(tostring(a_gradient))
  end

  function test_add_color()
    assert_error(nil, function() a_gradient:addColor() end)
    assert_error(nil, function() a_gradient:addColor(1, {}) end)
    assert_pass(nil, function() a_gradient:addColor(1, imlib2.Color(1,1,1)) end)
  end
end
