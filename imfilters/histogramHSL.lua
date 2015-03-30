local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local mmax,
      mmin, 
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
local rgb_to_hsl = common.rgb_to_hsl
local imlib2 = require"imlib2_ffi"

local function histogram(src, w, h, cumul)
    local size = w*h
    local valuesH, valuesS, valuesL = {}, {}, {}
    local maxH, maxS, maxL = 0, 0, 0
    for i=0,size-1 do
        local p,r,g,b
        p = src[i]
        b = band(p , 0xff)
        g = band(rshift(p, 8) , 0xff);
        r = band(rshift(p, 16), 0xff);
        local h, s, l = rgb_to_hsl(r,g,b)
        h,s,l = floor(h*100+0.5), floor(s*100+0.5), floor(l*100+0.5)
 
        local v
        v = (valuesH[h] or 0)+1
        valuesH[h] = v
        if(v > maxH)then
            maxH = v
        end
        v = (valuesS[s] or 0)+1
        valuesS[s] = v
        if(v > maxS)then
            maxS = v
        end
        v = (valuesL[l] or 0)+1
        valuesL[l] = v
        if(v > maxL)then
            maxL = v
        end
    end
    if(cumul)then
        for i=0,100 do
            local v, v1
            v = valuesH[i] or 0
            v1 = valuesH[i+1] or 0
            valuesH[i+1] = v1+v

            v = valuesS[i+1] or 0
            v1 = valuesS[i+1] or 0
            valuesS[i+1] = v1+v

            v = valuesL[i] or 0
            v1 = valuesL[i+1] or 0
            valuesL[i+1] = v1+v
        end
        maxH = nil maxS = nil maxL = nil
    end
    -- fill empty slots
    for i=0,100 do
        if not valuesH[i] then valuesH[i] = 0 end
        if not valuesS[i] then valuesS[i] = 0 end
        if not valuesL[i] then valuesL[i] = 0 end
    end
    return false, {h=valuesH,s=valuesS,l=valuesL, maxH=maxH,maxS=maxS,maxL=maxL}
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
