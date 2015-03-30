local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local max,
      min, 
      floor, 
      random, 
      cos, 
      sin, 
      pi, 
      log, 
      sqrt, 
      abs,
      exp
      =
      math.max, 
      math.min, 
      math.floor, 
      math.random, 
      math.cos, 
      math.sin, 
      math.pi, 
      math.log, 
      math.sqrt, 
      math.abs,
      math.exp

local common = require"imcommon"
local rgb_to_hsl, hsl_to_rgb = common.rgb_to_hsl, common.hsl_to_rgb

local imlib2 = require"imlib2_ffi"
local ColorTypes = {
    ["RGB"] = "RGB",
    ["HSL"] = "HSL"
}
local function modulate(src, w, h, channels, colortype)
    if not channels or type(channels)~="table" or next(channels)==nil then return nil, "Missing channels" end
    local ColorTypes = ColorTypes
    local colortype = ColorTypes[colortype or "RBG"] or "RGB"
    local channels = channels
    if "RGB"==colortype then
        channels = {
            r = channels.red or 0,
            g = channels.green or 0,
            b = channels.blue or 0
        }
    else
        channels = {
            h = channels.hue or 0,
            s = (channels.sat or channels.saturation) or 0,
            l = (channels.light or channels.lightness) or 0,
        }
    end

    local size = w*h
    local data = ffi.new('DATA32 [?]',w*h)

    -- compute average value
    for i=0,size-1 do
        local p,r,g,b
        p = src[i]
        b = band(p , 0xff)
        g = band(rshift(p, 8) , 0xff)
        r = band(rshift(p, 16), 0xff)
        a = band(rshift(p, 24), 0xff)
        if "RGB"==colortype then
            r = max(min(r+channels.r,255),0)
            g = max(min(g+channels.g,255),0)
            b = max(min(b+channels.b,255),0)
        elseif "HSL" == colortype then
            local h, s, l = rgb_to_hsl(r,g,b)
            h = max(min(h+channels.h,1),0)
            s = max(min(s+channels.s,1),0)
            l = max(min(l+channels.l,1),0)
            r, g, b = hsl_to_rgb(h,s,l)
        end
        data[i] = bor(lshift(a,24),lshift(r,16), lshift(g,8), b)
    end

    ---- set data back
    for i=0,size-1 do
        src[i] = data[i]
    end
    return true
end

return {
    info = {
        desc = [[Modulate Image Channels]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [=[Usage: modulate(channels{red=value,...},[colortype[RGB,HSL]])]=],
        channels = [[Channel to modulate with value]],
        colortype = [[Color Type, one of RGB or HSL]],
    },
    modulate
}
