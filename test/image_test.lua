require("lunit")

local tostring = tostring
local require = require
local print = print
local io, os = io, os

local imlib2 = require("imlib2")
local Image, Color = imlib2.Image, imlib2.Color
local module = module

module("creating a new image modifier", lunit.testcase)

function test_init()
    assert_pass(function()Image(200,200)end)
    assert_pass(function()Image('./resources/test.png')end)
    assert_error(nil, function()Image('nonexistent')end)
    assert_error(nil, function()imlib2.Image(200)end)
    assert_error(nil, function()imlib2.Image(nil,200)end)
    assert_error(nil, function()imlib2.Image()end)
end

module("querying and drawing on image", lunit.testcase)

function setup()
    img = Image(200,200)
end

function test__tostring()
    assert_string(tostring(img))
end

function test_cloning()
    assert_pass(nil, function()img:clone()end)
end

function test_get_alpha()
    assert_false(img:hasAlpha())
end

function test_draw_pixel()
    local col = Color.YELLOW
    assert_pass(nil, function()img:drawPixel(1,1)end)
    assert_pass(nil, function()img:drawPixel(2,2, col)end)
    assert_error(nil, function()img:drawPixel()end)

    local pixel = img:getPixel(2,2)
    assert_not_nil(pixel)
    assert_not_nil(pixel.red)
    assert_not_nil(pixel.green)
    assert_not_nil(pixel.blue)
    assert_not_nil(pixel.alpha)
    assert_equal(col.red, pixel.red)
    assert_equal(col.green, pixel.green)
    assert_equal(col.blue, pixel.blue)

    -- alpha's not set yet
    assert_equal(0, pixel.alpha)
end

function test_set_alpha()
    assert_pass(nil, function()img:setAlpha(true)end)
    local col = Color.YELLOW
    assert_pass(nil, function()img:drawPixel(3,3, col)end)
    local pixel = img:getPixel(3,3)
    assert_equal(col.alpha, pixel.alpha)
end

-- function test_set_data()
--     assert_pass(nil, function()img:setData("key", "data", 0)end)
-- end
-- 
-- function test_get_data()
--     local data = img:getData("key")
--     assert_not_nil(data)
--     assert_equal("data", data)
-- end

function test_dump()
    assert_pass(nil, function()img:dump()end)
    assert_not_nil(img:dump())

    local dest = 'result__1.png'
    local im = Image('resources/test.png')
    im:save(dest)
    local f = io.open(dest,'rb')
    local cmp = f:read('*a')
    f:close()
    local data = im:dump()
    assert_equal(#cmp, #data)
    os.remove(dest)
end

