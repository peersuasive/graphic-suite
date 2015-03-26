local ffi = require"ffi"
local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

require"imcommon"

-- http://supercomputingblog.com/openmp/image-twist-and-swirl-algorithm/2/
local function twirl(src, w, h, factor, method)
    local factor = factor or 5
    factor = factor / 1000
    local data = ffi.new('DATA32 [?]', w*h)

    local cX, cY = w/2.0, h/2.0

    local c = 0
    for y=0,h-1 do
        local relY = cY - y
        for x=0,w-1 do
            local relX = x - cX
            local oAngle

            if(relX ~= 0) then
                oAngle = math.atan(math.abs(relY)/math.abs(relX))
                if (relX > 0 and relY < 0) then
                    oAngle = 2.0 * math.pi - oAngle
                elseif (relX <= 0 and relY >=0) then
                    oAngle = math.pi - oAngle
                elseif (relX <=0 and relY <0) then
                    oAngle = oAngle + math.pi
                end
            else
                if(relY>=0)then
                    oAngle = 0.5 * math.pi
                else
                    oAngle = 1.5 * math.pi
                end
            end

            local rad = math.sqrt(relX*relX + relY*relY)
            local nAngle
            if("twist"==method)then
                nAngle = oAngle + 1/(factor*rad+(4.0/math.pi))
            else
                nAngle = oAngle + factor*rad
            end

            local srcX = math.floor( rad * math.cos(nAngle)+0.5 )
            local srcY = math.floor( rad * math.sin(nAngle)+0.5 )

            srcX = srcX + cX
            srcY = srcY + cY
            srcY = h - srcY


            if(srcX<0) then srcX = 0 elseif(srcX >= w) then srcX = w - 1 end
            if(srcY<0) then srcY = 0 elseif(srcY >= h) then srcY = h - 1 end

            local p = src[ srcY*w + srcX ]
            local b = band(p , 0xff)
            local g = band(rshift(p, 8) , 0xff);
            local r = band(rshift(p, 16), 0xff);
            local a = band(rshift(p, 24), 0xff);
           
            data[y*w + x] = bor(lshift(a,24), lshift(r,16), lshift(g,8), b)
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
        desc = [[Twist/Swirl]],
        author = "Christophe Berbizier",
        version = 0.1
    },
    help = {
        [[Usage: twirl(factor,method)]],
        factor = [[Amout of effect (default: 5)]],
        method = [[Can be one of:
        swirl (default)
        twist]]
    },
    twirl
}
