--[[

set all wished filters here

--]]

local grayscale = require"imfilters.grayscale"
local transform = require"imfilters.transform"

local denoise = require"imfilters.denoise"

local twirl = require"imfilters.twirl"
local oil = require"imfilters.oil"
local jitter = require"imfilters.jitter"
local wgn = require"imfilters.wgn"
local normalise = require"imfilters.normalise"

return {
    grayscale = grayscale,
    transform = transform,
    denoise = denoise,
    twirl = twirl,
    oil = oil,
    jitter = jitter,
    wgn = wgn,
    normalise = normalise,
}
