--[[

set all wished filters here

--]]

local grayscale = require"imfilters.grayscale"
local transform = require"imfilters.transform"

local denoise = require"imfilters.denoise"

local twirl = require"imfilters.twirl"
local oil = require"imfilters.oil"

return {
    grayscale = grayscale,
    transform = transform,
    denoise = denoise,
    twirl = twirl,
    oil = oil,
}
