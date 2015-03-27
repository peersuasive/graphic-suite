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
require"imcommon"

-- http://forums.codeguru.com/showthread.php?459963-Adding-noise-to-image
local function wgn(orig, w, h, variance, mean, pass, seed)
    local TWO_PI = 6.28318530717958647688

    local variance = max((variance or 0.5),0)
    variance = variance * 100
    local mean = mean or 0
    local pass = max((tonumber(pass) or 1), 1)
    local seed = seed or os.time()
    math.randomseed(seed)

    local src = ffi.new('DATA32 *')
    local data, buffer, tmp = ffi.new('DATA32 [?]',w*h)
    if(pass>1)then
        buffer = ffi.new('DATA32 [?]', w*h)
        tmp =  ffi.new('DATA32 *')
    end

    local size = w*h
    local mid = floor(size/2)

    local function render(src,data)
        for i=0,mid-1 do
            local u1, u2, gs
            local ix, iy, pos
            local p, b, g, r, a, ga, gr, gg, gb

            u1 = random(1,100) / 100
            u2 = random(1,100) / 100
            gs = sqrt(-2 * variance * log(u1))

            ix = floor(2*i/w)
            iy = floor(2*i%w)
            pos = ix+iy*w
            p = src[pos]
            b = band(p , 0xff)
            g = band(rshift(p, 8) , 0xff);
            r = band(rshift(p, 16), 0xff);
            a = band(rshift(p, 24), 0xff);
            gr = min(max(r + floor( (gs * cos(TWO_PI*u2) + mean) ), 0), 255)
            gg = min(max(g + floor( (gs * cos(TWO_PI*u2) + mean) ), 0), 255)
            gb = min(max(b + floor( (gs * cos(TWO_PI*u2) + mean) ), 0), 255)
            data[pos] = bor(lshift(gr,16), lshift(gg,8), gb)
 
            ix = floor((2*i+1)/w)
            iy = floor((2*i+1)%w)
            pos = ix+iy*w
            p = src[pos]
            b = band(p , 0xff)
            g = band(rshift(p, 8) , 0xff);
            r = band(rshift(p, 16), 0xff);
            a = band(rshift(p, 24), 0xff);
            gr = min(max(r + floor( (gs * sin(TWO_PI*u2) + mean) ), 0), 255)
            gg = min(max(g + floor( (gs * sin(TWO_PI*u2) + mean) ), 0), 255)
            gb = min(max(b + floor( (gs * sin(TWO_PI*u2) + mean) ), 0), 255)
            data[pos] = bor(lshift(gr,16), lshift(gg,8), gb)
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
        desc = [[White Gaussian Noise]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: wgn(variance,mean,pass,seed)]],
        variance = [[Amout of effect (default: 0.5)]],
        mean = [[mean (default: 0)]],
        pass = [[Number of pass (default: 1)]],
        seed = [[pseudo-random seed (default: os.time)]]
    },
    wgn
}
