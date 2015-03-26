local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

require"imcommon"

local function grayscale(src, w, h, method)
    local method = method or "average"
    local data = ffi.new('DATA32 [?]', w*h)
    local c = 0
    for y=0,h-1 do
        for x=0,w-1 do
            local p = src[c]
            local b = band(p , 0xff)
            local g = band(rshift(p, 8) , 0xff);
            local r = band(rshift(p, 16), 0xff);
            local a = band(rshift(p, 24), 0xff);
            local grey
            if("average"==method)then
                grey = (r+g+b)/3
            elseif("lightness"==method)then
                local max = r > g and r or g
                max = max > b and max or b
                local min = r < g and r or g
                min = min < b and mn or b
                grey = (mn + mx) / 2;
            elseif("luminosity"==method)then
                grey = (0.21*r + 0.72*g + 0.07*b)
            else
                grey = (r+g+b)/3
            end
            data[c] = bor(lshift(grey,24), lshift(grey,16), lshift(grey,8), grey)
            c = c + 1
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
        desc = [[Grayscale a picture]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: grayscale(method)]],
        method = [[Can be one of:
    average (fastest)
    ligthness (medium)
    luminosity (best)]]
    },
    grayscale
}
