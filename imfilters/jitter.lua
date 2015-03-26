local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local max,min,floor,random = math.max, math.min, math.floor, math.random
require"imcommon"

-- http://www.codeproject.com/Articles/3419/Image-Processing-for-Dummies-with-C-and-GDI-Part
local function jitter(orig, w, h, amount, pass, seed)
    local amount = amount or 5
    local pass = max((tonumber(pass) or 1), 1)
    local seed = seed or os.time()
    math.randomseed(seed)

    local mid = floor(amount/2)

    local src = ffi.new('DATA32 *')
    local data, buffer, tmp = ffi.new('DATA32 [?]',w*h)
    if(pass>1)then
        buffer = ffi.new('DATA32 [?]', w*h)
        tmp =  ffi.new('DATA32 *')
    end
    local function render(src,data)
        local c = 0
        for y=0,h-1 do
            for x=0,w-1 do
                local nx, ny = random(amount)-mid, random(amount)-mid
                local rx, ry = x+nx, y+ny
                if(rx>0 and rx<w and ry>0 and ry<h)then
                    local p = src[ rx + ry*w ]
                    local b = band(p , 0xff)
                    local g = band(rshift(p, 8) , 0xff);
                    local r = band(rshift(p, 16), 0xff);
                    local a = band(rshift(p, 24), 0xff);
                    data[c] = bor(lshift(a,24), lshift(r,16), lshift(g,8), b)
                else
                    data[c] = src[c]
                end
                c = c + 1
            end
        end
    end
    for i=1,pass do
        if(i==1)then
            src = orig
            tmp = data
        else
            if(tmp==data)then
                tmp = buffer
                src = data
            else
                tmp = data
                src = buffer
            end
        end
        render(src, tmp)
    end
    -- set data back
    for i=0,w*h-1 do
        orig[i] = tmp[i]
    end
    return true
end
return {
    info = {
        desc = [[Jitter]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: jitter(amount,pass,seed)]],
        amount = [[Amout of effect (default: 5)]],
        pass = [[Number of pass (default: 1)]],
        seed = [[pseudo-random seed (default: os.time)]]
    },
    jitter
}
