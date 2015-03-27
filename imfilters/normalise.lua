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

local function normalise(src, w, h, bx,by,bw,bh)
    -- TODO: box
    local size = w*h

    local data = ffi.new('DATA32 [?]',w*h)

    -- compute average value
    local minR,maxR, minG,maxG, minB,maxB = 0,0, 0,0, 0,0
    for i=0,size-1 do
        p = src[i]
        b = band(p , 0xff)
        g = band(rshift(p, 8) , 0xff);
        r = band(rshift(p, 16), 0xff);
        
        if r<minR then minR = r
        elseif r>maxR then maxR = r end

        if g<minG then minB = g
        elseif g>maxG then maxG = g end

        if b<minB then minB = b
        elseif b>maxB then maxB = b end
    end
    local scaleR, scaleG, scaleB = 
        255 / (maxR-minR),
        255 / (maxG-minG),
        255 / (maxB-minB)

    for i=0,size-1 do
        p = src[i]
        b = band(p , 0xff)
        g = band(rshift(p, 8) , 0xff);
        r = band(rshift(p, 16), 0xff);

        r = r - minR
        r = r * scaleR

        g = g - minG
        g = g * scaleG

        b = b - minB
        b = b * scaleB

        data[i] = bor(lshift(r,16), lshift(g,8), b)
    end
    ---- set data back
    for i=0,size-1 do
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
        [[Usage: normalise({x,y,w,h}(box))]],
        box = [[apply normalisation to the x,y,w,h portion of the image]]
    },
    normalise
}
