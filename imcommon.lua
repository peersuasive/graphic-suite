local ffi = require"ffi"
ffi.cdef([[
    void *malloc(size_t size);
    void free(void *ptr);
    void *memset(void *s, int c, size_t n);
    typedef unsigned int DATA32;
]])

local sum = function(matrix)
    local t = 0
    for _,v in next, matrix do
        t = t + v
    end
    t = math.floor(t)
    t = t>0 and t or 1.0
    return t
end

local floor, mmax, mmin = math.floor, math.max, math.min
-- ImageMagick's
local function rgb_to_hsl(red, green, blue)
    local b, delta, g, max, min, r
    local hue, saturation, lightness
    local q_scale = 1/255

    r = q_scale*red
    g = q_scale*green
    b = q_scale*blue
    max = mmax(r,mmax(g,b))
    min = mmin(r,mmin(g,b))
    lightness = ((min+max)/2)
    delta = max-min
    if (delta == 0.0) then
        hue = 0
        saturation = 0
        return hue, saturation, lightness
    end  
    if (lightness < 0.5) then
        saturation = (delta/(min+max))
    else
        saturation = (delta/(2-max-min))
    end

    if (r == max) then
        hue= ( ( ((max-b)/6) + (delta/2) ) - ( ((max-g)/6) +(delta/2) ) ) / delta
    else
        if (g == max) then
            hue = (1/3) + ( ( ((max-r)/6) + (delta/2) ) - ( ((max-b)/6) + (delta/2) ) ) / delta
        elseif (b == max) then
            hue = (2/3)+((((max-g)/6)+(delta/2))-(((max-r)/6)+ (delta/2)))/delta
        end
    end
    if (hue < 0) then
        hue = hue + 1
    end
    if (hue > 1) then
        hue = hue - 1
    end
    return hue, saturation, lightness
end

local function ConvertHueToRGB(m1,m2,hue)
    if (hue < 0) then
        hue = hue + 1
    end   
    if (hue > 1) then
        hue = hue - 1
    end
    if ((6*hue) < 1) then
        return (m1 + 6 * (m2-m1) * hue)
    end
    if ((2*hue) < 1) then
        return m2
    end
    if ((3*hue) < 2) then
        return(m1 + 6 * (m2-m1) * (2/3 - hue))
    end
    return m1
end
local function hsl_to_rgb(hue, saturation, lightness)
    local b, g, r, m1, m2
    local red, green, blue
    if (saturation == 0) then
        local r = floor(255 * lightness)
        return r,r,r
    end  
    if (lightness < 0.5) then
        m2 = lightness * (saturation + 1)
    else
        m2 = (lightness + saturation) - (lightness * saturation)
    end

    m1 = 2 * lightness - m2
    r = ConvertHueToRGB(m1, m2, hue + 1/3)
    g = ConvertHueToRGB(m1, m2, hue)
    b = ConvertHueToRGB(m1, m2, hue - 1/3)
    red   = floor(255 * r + 0.5)
    green = floor(255 * g + 0.5)
    blue  = floor(255 * b + 0.5)

    return red, green, blue
end


return {
    sum = sum,
    rgb_to_hsl = rgb_to_hsl,
    hsl_to_rgb = hsl_to_rgb,
}
