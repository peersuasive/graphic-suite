require("lunit")

local tostring = tostring
local print = print

local imlib2 = require("imlib2")
local font = imlib2.Font
local module = module

module("manipulating the font paths/listing fonts", lunit.testcase)
do
  function test_list_paths()
    assert_table(font.listPaths())
  end

  function test_add_path()
    font.addPath("foo")
    assert_equal("foo", font.listPaths()[1])
    assert_error(nil, function() font.addPath(nil) end)
  end

  function test_remove_path()
    font.addPath("foo")
    font.removePath("foo")
    assert_equal(0, #font.listPaths())
    assert_error(nil, function() font.removePath(nil) end)
  end

  function test_list_fonts()
    assert_table(font.listFonts())
  end
end

module("getting and setting the cache size", lunit.testcase)
do

  function test_get_cache_size()
    assert_number(font.getCacheSize())
  end

  function test_set_cache_size()
    local orig = font.getCacheSize()
    font.setCacheSize(1337)
    assert_equal(1337, font.getCacheSize())
    font.setCacheSize(orig)
  end
end

module("loading a font", lunit.testcase)
do
  function test_failing_to_load_a_font()
    local s, msg = font("notfound")
    assert_nil(s)
    assert_string(msg)
  end
end


module("a loaded font instance", lunit.testcase)
do
  function setup()
    font.addPath("resources")

    local msg
    a_font, msg = font("Vera/10")
    assert(a_font, msg)
  end

  function teardown()
    font.removePath("resources")
  end

  function test__tostring()
    assert_string(tostring(a_font))
  end

  function test_get_size()
    local w, h = a_font:getSize("this is a test of a test of a test")
    assert_number(w)
    assert_number(h)
    -- fails 
    assert(w >= h)
  end

  function test_get_advance()
    local h,v = a_font:getAdvance("this is a test")
    assert_number(h)
    assert_number(v)
    assert(h > v)
  end

  function test_get_inset() assert_number(a_font:getInset("foo")) end
  function test_get_ascent() assert_number(a_font:getAscent()) end
  function test_get_maximum_ascent() assert_number(a_font:getMaximumAscent()) end
  function test_get_descent() assert_number(a_font:getDescent()) end
  function test_get_maximum_descent() assert_number(a_font:getMaximumDescent()) end
end

module("setting/getting the text direction", lunit.testcase)
do
  function test_set_direction()
    assert_pass(nil, function() font.setDirection("up") end)
    assert_equal("up", font.getDirection())
    assert_error(nil, function() font.setDirection("invalid") end)
  end

  function test_set_direction_to_angle()
    assert_error(nil, function() font.setDirection("angle", "bleh") end)
    assert_pass(nil, function() font.setDirection("angle", 21.1) end)
    local dir, angle = font.getDirection()
    assert_equal("angle", dir)
    assert_equal(21.1, angle)
  end
end
