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
local imlib2 = require"imlib2_ffi"

local function histogram(src, w, h, cumul)
    local size = w*h
    local valuesR, valuesG, valuesB = {}, {}, {}
    local maxR, maxG, maxB = 0, 0, 0
    for i=0,size-1 do
        p = src[i]
        b = band(p , 0xff)
        g = band(rshift(p, 8) , 0xff);
        r = band(rshift(p, 16), 0xff);
 
        local v
        v = (valuesR[r] or 0)+1
        valuesR[r] = v
        if(v > maxR)then
            maxR = v
        end
        v = (valuesG[g] or 0)+1
        valuesG[g] = v
        if(v > maxG)then
            maxG = v
        end
        v = (valuesB[b] or 0)+1
        valuesB[b] = v
        if(v > maxB)then
            maxB = v
        end
    end
    if(cumul)then
        for i=0,255 do
            local v, v1
            if not(valuesR[i])then valuesR[i]=0 end
            v = valuesR[i] or 0
            v1 = valuesR[i+1] or 0
            valuesR[i+1] = v1+v

            v = valuesG[i+1] or 0
            v1 = valuesG[i+1] or 0
            valuesG[i+1] = v1+v

            v = valuesB[i] or 0
            v1 = valuesB[i+1] or 0
            valuesB[i+1] = v1+v
        end
        maxR = nil maxG = nil maxB = nil
    end
    -- fill empty slots
    for i=0,255 do
        if not valuesR[i] then valuesR[i] = 0 end
        if not valuesG[i] then valuesG[i] = 0 end
        if not valuesB[i] then valuesB[i] = 0 end
    end
    return false, {r=valuesR,g=valuesG,b=valuesB, maxR=maxR,maxG=maxG,maxB=maxB}
end

return {
    info = {
        desc = [[Histogram]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: histogram(cumul)]],
        cumul = [[cumulate histogram values]]
    },
    histogram
}
