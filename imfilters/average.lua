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
local rgb2hsl = common.rgb2hsl

local imlib2 = require"imlib2_ffi"

local function average(src, w, h, range, bx,by,bw,bh)
    local range = range
    local size = w*h

    local data = ffi.new('DATA32 [?]',w*h)

    -- compute average value
    local normR, normG, normB = 0, 0, 0
    if not range then
        for i=0,size-1 do
            p = src[i]
            b = band(p , 0xff)
            normB = normB + b
            g = band(rshift(p, 8) , 0xff);
            normG = normG + g
            r = band(rshift(p, 16), 0xff);
            normR = normR + r
        end
    end
    normR = floor(range or normR / size)
    normB = floor(range or normB / size)
    normG = floor(range or normG / size)

    -- apply range
    for i=0,size do
        p = src[i]
        b = band(p , 0xff)
        g = band(rshift(p, 8) , 0xff);
        r = band(rshift(p, 16), 0xff);

        b = min( (b+normB), 255 )
        g = min( (g+normG), 255 )
        r = min( (r+normG), 255 )
        data[i] = bor(lshift(r,16), lshift(g,8), b)
    end
    ---- set data back
    for i=0,w*h-1 do
        src[i] = data[i]
    end
    return true
end

return {
    info = {
        desc = [[Normalise Image]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: normalise(range, {x,y,w,h}(box))]],
        range = [[range to apply (default: average)]],
        box = [[apply normalisation to the x,y,w,h portion of the image]]
    },
    average
}
