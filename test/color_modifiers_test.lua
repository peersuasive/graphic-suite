require("lunit")

local tostring = tostring
local require = require
local print = print

local imlib2 = require("imlib2")
local module = module

module("creating a new color modifier", lunit.testcase)

function test_init()
  assert_pass(function() imlib2.ColorModifier() end)
end

module("setting gamma, brightness...", lunit.testcase)

function setup()
  mod = imlib2.ColorModifier()
end

function test__tostring()
  assert_string(tostring(mod))
end

function test_gamma()
    assert_pass(function() mod:setGamma(10) end)
    assert_error(nil, function() mod:setGamma() end)
end

function test_brightness()
    assert_pass(function() mod:setBrightness(10) end)
    assert_error(nil, function() mod:setBrightness() end)
end

function test_contrast()
    assert_pass(function() mod:setContrast(10) end)
    assert_error(nil, function() mod:setContrast() end)
end

function test_set_tables()
    local red = {
        [1] = 10,
        [10] = 1,
        [255] = 250
    }
    local green = {
        [2] = 2,
        [15] = 15,
        [200] = 200,
    }
    local blue = {
        [5] = 5,
        [7] = 7,
    }
    local alpha = {
        [19] = 19
    }
    assert_pass(function() mod:setModifierTables(red, green, blue, alpha) end)
end

function test_get_tables()
    local red, green, blue, alpha = mod:getModifierTables()
    assert_table(red)
    assert_table(green)
    assert_table(blue)
    assert_table(alpha)
    --assert_equal(10, red[1])
end
