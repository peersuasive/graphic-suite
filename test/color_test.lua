require("lunit")

local tostring = tostring
local next = next
local unpack = unpack
local print = print

local imlib2 = require("imlib2")
local Color = imlib2.Color
local module = module

module("creating a new color", lunit.testcase)

function test_too_few_colors()
  assert_error(nil, function() Color(255, 255, nil, nil) end)
  assert_error(nil, function() Color(nil, nil, nil, 255) end)
end

function test_allow_missing_alpha()
  assert_pass(nil, function() Color(255, 255, 255) end)
end

function test_allowed_range()
  assert_error(nil, function() Color(255, 255, 255, 256) end)
  assert_error(nil, function() Color(256, 255, 255, 255) end)
  assert_error(nil, function() Color(0, 0, -1, 0) end)
  assert_error(nil, function() Color(0, -1, -1, 0) end)
end

module("querying and modifying an existing color", lunit.testcase)

function setup()
  col = Color(0, 0, 0, 255)
end

function test__tostring()
  assert_string(tostring(col))
end

function test_get_rgba()
  assert_equal(0, col.red)
  assert_equal(0, col.green)
  assert_equal(0, col.blue)
  assert_equal(255, col.alpha)
end

function test_set_rgba()
  col.red=255
  col.green=255
  col.blue=255
  col.alpha=0
  assert_equal(255, col.red)
  assert_equal(255, col.green)
  assert_equal(255, col.blue)
  assert_equal(0, col.alpha)
end

function test_set_rgba_out_of_range()
  assert_error(nil, function() col.red=256 end)
  assert_error(nil, function() col.alpha=-1 end)
end

function test_clone()
    local clone = col:clone()
    assert_equal(col.red, clone.red)
    assert_equal(col.green, clone.green)
    assert_equal(col.blue, clone.blue)
    assert_equal(col.alpha, clone.alpha)
end

function test_predefined_colors()
    assert_equal(255, Color.YELLOW.red)
    assert_equal(255, Color.YELLOW.green)
    assert_equal(0, Color.YELLOW.blue)
    assert_equal(255, Color.YELLOW.alpha)

    local pre = {
        CLEAR       = {0,0,0,0},
        TRANSPARENT = {0, 0, 0, 0},
        TRANSLUCENT = {0, 0, 0, 0},
        SHADOW      = {64, 0, 0, 0},
        BLACK       = {255, 0, 0, 0},
        DARKGRAY    = {255, 64, 64, 64},
        DARKGREY    = {255, 64, 64, 64},
        GRAY        = {255, 128, 128, 128},
        GREY        = {255, 128, 128, 128},
        LIGHTGRAY   = {255, 192, 192, 192},
        LIGHTGREY   = {255, 192, 192, 192},
        WHITE       = {255, 255, 255, 255},
        RED         = {255, 255, 0, 0},
        GREEN       = {255, 0, 255, 0},
        BLUE        = {255, 0, 0, 255},
        YELLOW      = {255, 255, 255, 0},
        ORANGE      = {255, 255, 128, 0},
        BROWN       = {255, 128, 64, 0},
        MAGENTA     = {255, 255, 0, 128},
        VIOLET      = {255, 255, 0, 255},
        PURPLE      = {255, 128, 0, 255},
        INDIGO      = {255, 128, 0, 255},
        CYAN        = {255, 0, 255, 255},
        AQUA        = {255, 0, 128, 255},
        AZURE       = {255, 0, 128, 255},
        TEAL        = {255, 0, 255, 128},
        DARKRED     = {255, 128, 0, 0},
        DARKGREEN   = {255, 0, 128, 0},
        DARKBLUE    = {255, 0, 0, 128},
        DARKYELLOW  = {255, 128, 128, 0},
        DARKORANGE  = {255, 128, 64, 0},
        DARKBROWN   = {255, 64, 32, 0},
        DARKMAGENTA = {255, 128, 0, 64},
        DARKVIOLET  = {255, 128, 0, 128},
        DARKPURPLE  = {255, 64, 0, 128},
        DARKINDIGO  = {255, 64, 0, 128},
        DARKCYAN    = {255, 0, 128, 128},
        DARKAQUA    = {255, 0, 64, 128},
        DARKAZURE   = {255, 0, 64, 128},
        DARKTEAL    = {255, 0, 128, 64},
    }

    for k,v in next,pre do
        --print(k)
        local a,r,g,b = unpack(v)
        assert_equal(r, Color[k].red)
        assert_equal(g, Color[k].green)
        assert_equal(b, Color[k].blue)
        assert_equal(a, Color[k].alpha)
    end

end
