local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local sum = require"imcommon".sum

local function transform(src, w,h, filter, ...)
    local matrix, factor, bias = filter.matrix, filter.factor, filter.bias
    local fW = math.sqrt(#matrix)
    local fH = fW
    local fW2, fH2 = math.floor(fW/2), math.floor(fH/2)
    local bias = bias or 0.0
    local factor = factor or 1.0/sum(matrix)

    local data = ffi.new('DATA32 [?]', w*h)
    local c = 0
    for y=0,h-1 do
        for x=0,w-1 do
            local red, green, blue, alpha = 0.0, 0.0, 0.0, 0.0
            for fx=0,fW-1 do
                for fy=0,fH-1 do
                    local ix = (x - fW2 + fx + w) % w; 
                    local iy = (y - fH2 + fy + h) % h; 
    
                    local pos = ix + iy * w;

                    local p = src[pos]
                    local b = band(p , 0xff)
                    local g = band(rshift(p, 8) , 0xff);
                    local r = band(rshift(p, 16), 0xff);
                    local a = band(rshift(p, 24), 0xff);
                    
                    local fv = matrix[ fx*fW+fy+1 ]

                    red = red + r * fv
                    green = green + g * fv
                    blue = blue + b * fv
                    alpha = alpha + a * fv
                end
            end

            local r = math.floor(math.min(math.max((factor * red   + bias), 0), 255))
            local g = math.floor(math.min(math.max((factor * green + bias), 0), 255))
            local b = math.floor(math.min(math.max((factor * blue  + bias), 0), 255))
            local a = math.floor(math.min(math.max((factor * alpha + bias), 0), 255))

            data[c] = bor(lshift(a,24), lshift(r,16), lshift(g,8), b)
            c = c + 1
        end
    end
    -- set data back
    for i=0,w*h-1 do
        src[i] = data[i]
    end
    return true
end

return {
    info = {
        author = "Christophe Berbizier"
    },
    transform
}
