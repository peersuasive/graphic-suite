local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

require"imcommon"

-- http://www.codeproject.com/Articles/471994/OilPaintEffect
local function oil(src, w, h, radius, level)
    local hM, wM = h+1, w+1
    local radius = radius or 10
    local level = level or 50
    local data = ffi.new('DATA32 [?]', w*h)

    local c = 0
    for y=0,h-1 do
        for x=0,w-1 do
            local count, sumA, sumR, sumG, sumB = {}, {}, {}, {}, {}
            for ny=-radius,radius+1 do
                local Y=y+ny
                if Y>-1 and Y<hM then
                    for nx=-radius,radius+1 do
                        local X = x+nx
                        if X>-1 and X<wM then
                            local p = src[(x+nx) + (y+ny)*w]
                            local b = band(p , 0xff)
                            local g = band(rshift(p, 8) , 0xff);
                            local r = band(rshift(p, 16), 0xff);

                            local curI = math.floor( (((r+g+b)/3) * level) /255.0 )
                            curI = math.min(curI,255)
                            count[curI] = (count[curI] or 0) + 1
                            sumR[curI] = (sumR[curI] or 0) + r
                            sumG[curI] = (sumG[curI] or 0) + g
                            sumB[curI] = (sumB[curI] or 0) + b
                        end
                    end
                end
            end
            local max,index = 0, 0
            for i=0,256 do
                if count[i] and count[i]>max then
                    max = count[i]
                    index = i
                end
            end
            local r = sumR[index] / max
            local g = sumG[index] / max
            local b = sumB[index] / max

            data[c] = bor(lshift(r,16), lshift(g,8), b)
            c = c+1
        end
    end

    -- set data back
    for i=0,w*h do
        src[i] = data[i]
    end
    return true
end

return {
    info = {
        desc = [[Oil Painting]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: oil(radius,level)]],
        radius = [[radius]],
        level = [[level of saturation]]
    },
    oil
}
