local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local sum = require"imcommon".sum

-- combsort: bubble sort made faster by using gaps to eliminate turtles
local function combsort(data)
    local amount = #data
    local gap = amount
    local swapped = false
    while(gap > 1 or swapped) do
        -- shrink factor 1.3
        gap = math.floor((gap * 10) / 13)
        if (gap == 9 or gap == 10) then gap = 11 end
        if (gap < 1) then gap = 1 end
        swapped = false
        for i=1, (amount - gap) do
            local j = i + gap
            if (data[i] > data[j]) then
                data[i] = data[i] + data[j]
                data[j] = data[i] - data[j]
                data[i] = data[i] - data[j]
                swapped = true
            end
        end
    end
end
local function denoise(src, w,h, filter, ...)
    local filter = filter or {
        matrix = {
            1,1,1, 1,1,1,
            1,1,1, 1,1,1,
            1,1,1, 1,1,1,
            1,1,1, 1,1,1,
            1,1,1, 1,1,1,
            1,1,1, 1,1,1,
        },
        factor = 1.0 / 36.0,
        bias = 0.0
    }
    local matrix, factor, bias = filter.matrix, filter.factor, filter.bias
    local fW = math.sqrt(#matrix)
    local fH = fW
    local fW2, fH2 = math.floor(fW/2), math.floor(fH/2)
    local fs = fW * fH
    local med = math.floor(fs/2)-1

    local bias = bias or 0.0
    local factor = factor or 1.0/sum(matrix)


    local data = ffi.new('DATA32 [?]', w*h)
    local red, green, blue, alpha = {}, {}, {}, {}
    local c = 0
    for y=0,h-1 do
        for x=0,w-1 do
            local n = 1
            for fx=0,fW-1 do
                for fy=0,fH-1 do
                    local ix = (x - fW2 + fx + w) % w; 
                    local iy = (y - fH2 + fy + h) % h; 
    
                    local pos = ix + iy * w;
                    
                    local p = src[pos]
                    blue[n] = band(p , 0xff)
                    green[n] = band(rshift(p, 8) , 0xff);
                    red[n] = band(rshift(p, 16), 0xff);
                    alpha[n] = band(rshift(p, 24), 0xff);

                    n = n+1
                end
            end
            combsort(red)
            combsort(green)
            combsort(blue)
            combsort(alpha)

            if ( (fs) % 2 == 1 ) then
                data[c] = bor( lshift(alpha[med], 24), lshift(red[med],16), lshift(green[med],8), blue[med] )
            elseif (fW > 1) then
                local a,r,g,b
                a = (alpha[med] + alpha[med+1])/2
                r = (red[med] + red[med+1])/2
                g = (green[med] + green[med+1])/2
                b = (blue[med] + blue[med+1])/2
                data[c] = bor( lshift(a, 24), lshift(r,16), lshift(g,8), b )
            end
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
    denoise
}
