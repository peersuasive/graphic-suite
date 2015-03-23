require("lunit")

local tostring = tostring

local imlib2 = require("imlib2")
local module = module

module("Anti alias setting", lunit.testcase)
do
  function test_get_antialias()
    assert_true(imlib2.getAntiAlias()) -- want to be true by default
  end

  function test_set_anti_alias()
    assert_error(nil, function() imlib2.setAntiAlias() end)
    imlib2.setAntiAlias(false)
    assert_false(imlib2.getAntiAlias())
    imlib2.setAntiAlias(true)
    assert_true(imlib2.getAntiAlias())
  end
end

module("Cache functions", lunit.testcase)
do
  function test_get_cache_size()
    assert_number(imlib2.getCacheSize())
  end

  function test_set_cache_size()
    local orig = imlib2.getCacheSize()
    imlib2.setCacheSize(50000)
    assert_equal(50000, imlib2.getCacheSize())
    imlib2.setCacheSize(orig)
    assert_equal(orig, imlib2.getCacheSize())
  end

  function test_flush_cache()
    local orig = imlib2.getCacheSize()
    imlib2.flushCache() -- should restore original cache size
    assert_equal(orig, imlib2.getCacheSize())
  end
end
