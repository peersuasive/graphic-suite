--[[

set all wished filters here

--]]

local grayscale = require"imfilters.grayscale"
local transform = require"imfilters.transform"

local denoise = require"imfilters.denoise"

return {
    grayscale = grayscale,
    transform = transform,
    denoise = denoise,
}
