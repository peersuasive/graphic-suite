#!/usr/bin/env luajit

local bit = bit or bit32
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local ffi = require"ffi"

-- load definitions
local imlib2 = require"imlib2_ffi"

local errors = {
    [ffi.C.IMLIB_LOAD_ERROR_FILE_DOES_NOT_EXIST] = "file '%s' does not exist",
    [ffi.C.IMLIB_LOAD_ERROR_FILE_IS_DIRECTORY] = "file '%s' is a directory",
    [ffi.C.IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_READ] = "permission denied to read file '%s'",
    [ffi.C.IMLIB_LOAD_ERROR_NO_LOADER_FOR_FILE_FORMAT] = "no loader for the file format used in file '%s'",
    [ffi.C.IMLIB_LOAD_ERROR_PATH_TOO_LONG] = "path for file '%s' is too long",
    [ffi.C.IMLIB_LOAD_ERROR_PATH_COMPONENT_NON_EXISTANT] = "a component of path '%s' does not exist",
    [ffi.C.IMLIB_LOAD_ERROR_PATH_COMPONENT_NOT_DIRECTORY] = "a component of path '%s' is not a directory",
    [ffi.C.IMLIB_LOAD_ERROR_PATH_POINTS_OUTSIDE_ADDRESS_SPACE] = "Path points outside of address space",
    [ffi.C.IMLIB_LOAD_ERROR_TOO_MANY_SYMBOLIC_LINKS] = "path '%s' has too many symbolic links",
    [ffi.C.IMLIB_LOAD_ERROR_OUT_OF_MEMORY] = "Out of memory",
    [ffi.C.IMLIB_LOAD_ERROR_OUT_OF_FILE_DESCRIPTORS] = "ran out of file descriptors trying to access file '%s'",
    [ffi.C.IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_WRITE] = "denied write permission for file '%s'",
    [ffi.C.IMLIB_LOAD_ERROR_OUT_OF_DISK_SPACE] = "out of disk space writing to file '%s'",
    [ffi.C.IMLIB_LOAD_ERROR_UNKNOWN] = "Unknown error",
}

-- data dumper

ffi.cdef([[
    struct _image_data{
       int               w, h, has_alpha;
       DATA32           *data;
    };
    typedef struct _image_data ImageData;

    char *save(ImageData *im, int *length);
    void free_data(char *data);
]])
local dumper = ffi.load('./dump.so')

-- plugins

local plugins = {}
ffi.cdef([[
    struct _filter {
        int filterW;
        int filterH;
        double factor;
        double bias;
        double *matrix;
    };
    typedef struct _filter Filter;

    enum _grayscale_method {
        NONE,
        LIGTHNESS,
        AVERAGE,
        LUMINOSITY
    };
    typedef enum _grayscale_method Grayscale;

    void transform(Imlib_Image im, Filter f, Grayscale grayscale);
    void grayscale(Imlib_Image im, Grayscale method);
    void motionblur(Imlib_Image im);
    void emboss(Imlib_Image im, double factor, double bias, Grayscale gs);

    void quickremovenoise(Imlib_Image im, double factor, double bias);
    void removenoise(Imlib_Image im, Filter filter);
]])
plugins = ffi.load('./transform.so')

local Filter
local filter_mt = {}
Filter = ffi.metatype('Filter', filter_mt)


-- pluggable filters

-- TODO: load on-demand from filters/
local filters = require"imfilters"
local function call_filter(name, im,...)
    if not im or im==ffi.NULL then return end --error('Trying to call destroyed object', 3) end
    imlib2.imlib_context_set_image(im)
    local w, h = imlib2.imlib_image_get_width(), imlib2.imlib_image_get_height()
    local src = imlib2.imlib_image_get_data()
    filters[name][1](src, w, h,...)
    -- TODO: eg. require("imfilters."..name)[1](src,w,h)
    imlib2.imlib_image_put_back_data(src)
end

-------------

local Color, Color_
local color_mt = {
    __index = {
        clone = function(self)
            return ffi.new('Imlib_Color',{self.alpha, self.red, self.green, self.blue})
        end,
    },
    __tostring = function(self)
        return string.format("%d,%d,%d,%d",self.red, self.green, self.blue, self.alpha)
    end,
}
Color_ = ffi.metatype('Imlib_Color', color_mt)
Color = setmetatable({}, {
    __call = function(self,r,g,b,a)
        local color
        if("cdata"==type(r))then
            color = r
        else
            local a = a or 255
            assert( (a and r and g and b) and (a>-1 and a<256) 
                and (r>-1 and r<256) 
                and (g>-1 and g<256) 
                and (b>-1 and b<256), "values must be >= 0 and <= 255")
            color = Color_(a,r,g,b)
        end
        return setmetatable({}, {
            __tostring = function()
                return string.format("%d,%d,%d,%d",color.red, color.green, color.blue, color.alpha)
            end,
            __index = function(self,k)
                return color[k]
            end,
            __newindex = function(self,k,v)
                assert(v and v>-1 and v<256, "values must be >= 0 and <= 255")
                color[k] = v
            end,
        })
    end,
    __index = {
        CLEAR       = Color_(0,0,0,0),
        TRANSPARENT = Color_(0, 0, 0, 0),
        TRANSLUCENT = Color_(0, 0, 0, 0),
        SHADOW      = Color_(64, 0, 0, 0),
        BLACK       = Color_(255, 0, 0, 0),
        DARKGRAY    = Color_(255, 64, 64, 64),
        DARKGREY    = Color_(255, 64, 64, 64),
        GRAY        = Color_(255, 128, 128, 128),
        GREY        = Color_(255, 128, 128, 128),
        LIGHTGRAY   = Color_(255, 192, 192, 192),
        LIGHTGREY   = Color_(255, 192, 192, 192),
        WHITE       = Color_(255, 255, 255, 255),
        RED         = Color_(255, 255, 0, 0),
        GREEN       = Color_(255, 0, 255, 0),
        BLUE        = Color_(255, 0, 0, 255),
        YELLOW      = Color_(255, 255, 255, 0),
        ORANGE      = Color_(255, 255, 128, 0),
        BROWN       = Color_(255, 128, 64, 0),
        MAGENTA     = Color_(255, 255, 0, 128),
        VIOLET      = Color_(255, 255, 0, 255),
        PURPLE      = Color_(255, 128, 0, 255),
        INDIGO      = Color_(255, 128, 0, 255),
        CYAN        = Color_(255, 0, 255, 255),
        AQUA        = Color_(255, 0, 128, 255),
        AZURE       = Color_(255, 0, 128, 255),
        TEAL        = Color_(255, 0, 255, 128),
        DARKRED     = Color_(255, 128, 0, 0),
        DARKGREEN   = Color_(255, 0, 128, 0),
        DARKBLUE    = Color_(255, 0, 0, 128),
        DARKYELLOW  = Color_(255, 128, 128, 0),
        DARKORANGE  = Color_(255, 128, 64, 0),
        DARKBROWN   = Color_(255, 64, 32, 0),
        DARKMAGENTA = Color_(255, 128, 0, 64),
        DARKVIOLET  = Color_(255, 128, 0, 128),
        DARKPURPLE  = Color_(255, 64, 0, 128),
        DARKINDIGO  = Color_(255, 64, 0, 128),
        DARKCYAN    = Color_(255, 0, 128, 128),
        DARKAQUA    = Color_(255, 0, 64, 128),
        DARKAZURE   = Color_(255, 0, 64, 128),
        DARKTEAL    = Color_(255, 0, 128, 64),
    },
    __tostring = function()
        return string.format("%d,%d,%d,%d",color.red, color.green, color.blue, color.alpha)
    end,
})

local ColorModifier
ColorModifier = setmetatable({}, {
    __call = function()
        local imlib2, modifier = imlib2
        local sc = function()
            imlib2.imlib_context_set_color_modifier(modifier)
        end
        local modifier_gc = function()
            if not modifier or modifier==ffi.NULL then return end
            sc()
            imlib2.imlib_free_color_modifier()
        end
        modifier = ffi.gc(imlib2.imlib_create_color_modifier(), modifier_gc)
        return {
            setGamma = function(self,v)
                assert(v,"Missing gamma value")
                sc()
                imlib2.imlib_modify_color_modifier_gamma(v)
            end,
            setBrightness = function(self,v)
                assert(v, "Missing brightness value")
                sc()
                imlib2.imlib_modify_color_modifier_brightness(v)
            end,
            setContrast = function(self,v)
                assert(v, "Missing contrast value")
                sc()
                imlib2.imlib_modify_color_modifier_contrast(v)
            end,
            setModifierTables = function(self,red,green,blue,alpha)
                local red, green, blue, alpha =
                      red or {}, green or {}, blue or {}, alpha or {}
                local red_table = ffi.new('DATA8 [256]')
                local green_table = ffi.new('DATA8 [256]')
                local blue_table = ffi.new('DATA8 [256]')
                local alpha_table = ffi.new('DATA8 [256]')
                for i=1,256 do
                    local c = red[i]
                    if c then red_table[i-1] = c end
                end
                for i=1,256 do
                    local c = green[i]
                    if c then green_table[i-1] = c end
                end
                for i=1,256 do
                    local c = blue[i]
                    if c then blue_table[i-1] = c end
                end
                for i=1,256 do
                    local c = alpha[i]
                    if c then alpha_table[i-1] = c end
                end
                sc()
                imlib2.imlib_set_color_modifier_tables(red_table, green_table, blue_table, alpha_table)
            end,
            -- FIXME: won't return set values
            getModifierTables = function()
                local red_table = ffi.new('DATA8 [256]')
                local green_table = ffi.new('DATA8 [256]')
                local blue_table = ffi.new('DATA8 [256]')
                local alpha_table = ffi.new('DATA8 [256]')
                sc()
                imlib2.imlib_get_color_modifier_tables(red_table, green_table, blue_table, alpha_table)
                local red, green, blue, alpha = {}, {}, {}, {}
                for i=0,255 do
                    local c = red_table[i]
                    red[i+1] = tonumber(c)
                    c = green_table[i]
                    green[i+1] = tonumber(c)
                    c = blue_table[i]
                    blue[i+1] = tonumber(c)
                    c = alpha_table[i]
                    alpha[i+1] = tonumber(c)
                end
                return red, green, blue, alpha
            end,
            reset = function()
                sc()
                imlib2.imlib_reset_color_modifier();
            end,
            apply = function()
                sc()
                imlib2.imlib_apply_color_modifier();
            end,
            applyToRectangle = function(self, x, y, w, h)
                sc()
                imlib2.imlib_apply_color_modifier_to_rectangle(x, y, w, h)
            end,
        }
    end
})

-- Gradient / create_color_range
local function gradient_new()
    local imlib2 = imlib2
    local gr = imlib2.imlib_create_color_range()
    local self = {
        addColor = function(self, offset, color)
            imlib2.imlib_context_set_color_range(gr)
            imlib2.imlib_context_set_color(color.red, color.green, color.blue, color.alpha)
            imlib2.imlib_add_color_to_color_range(offset)
        end,
        __get = function()
            return gr
        end
    }
    return setmetatable(self, {__call=function()return gr end})
end

local Gradient = setmetatable({}, {
    __call = gradient_new
})

-- Border

local Border
local border_mt = {
    __index = {
        clone = function(self)
            return ffi.new('Imlib_Border',{self.left, self.right, self.top, self.bottom})
        end,
    },
    __tostring = function(self)
        return string.format("%d,%d,%d,%d",self.left, self.right, self.top, self.bottom)
    end,
}
Border = ffi.metatype('Imlib_Border', border_mt)

-- Polygon

ffi.cdef([[typedef struct _imlib_point ImlibPoint;
struct _imlib_point {
   int x, y;
};

struct _imlib_rectangle {
   int x, y, w, h;
};
typedef struct _imlib_rectangle Imlib_Rectangle;

struct _imlib_polygon
{
   ImlibPoint *points;
   int pointcount;
   int  lx, rx;
   int  ty, by;
};
typedef struct _imlib_polygon _ImlibPoly;
typedef _ImlibPoly *ImlibPoly;
]])

local Polygon = setmetatable({}, {
    __call = function()
        --local po = imlib2.imlib_polygon_new()
        -- override constructor to set gc
        local imlib2 = imlib2
        local size = ffi.sizeof('_ImlibPoly')
        local po = ffi.gc(ffi.C.malloc(size), ffi.C.free)
        ffi.C.memset(po, 0, size)
        local self = {
            addPoint = function(self, x,y)
                imlib2.imlib_polygon_add_point(po, x, y)
            end,
            getBounds = function()
                local x1 = ffi.new('int [1]', 0)
                local y1 = ffi.new('int [1]', 0)
                local x2 = ffi.new('int [1]', 0)
                local y2 = ffi.new('int [1]', 0)
                imlib2.imlib_polygon_get_bounds(po,x1,y1,x2,y2)
                return x1[0], y1[0], x2[0], y2[0]
            end,
            containsPoint = function(self, x, y)
                local res = imlib2.imlib_polygon_contains_point(po, x, y)
                return res==1
            end,
            __get = function()
                return po
            end,
        }
        return self
    end
})

-- Font

local Font_dirs = {right=0, left=1, down=2, up=3, angle=4, [0]="right", [1]="left", [2]="down", [3]="up", [4]="angle"}
local Font = setmetatable({}, {
    __call = function(self, path)
        local imlib2, fo = imlib2
        local font_gc = function()
            if not fo or fo==ffi.NULL then return end
            imlib2.imlib_context_set_font(fo);
            imlib2.imlib_free_font();
        end
        local function fc()
            imlib2.imlib_context_set_font(fo)
        end
        fo = ffi.gc(imlib2.imlib_load_font(path), font_gc)
        if not fo or fo==ffi.NULL then return nil, "Can't find font: "..path end
        local path = path
        local self = {
            getSize = function(self, text)
                local text = text or ""
                local w, h = ffi.new('int [1]'), ffi.new('int [1]')
                fc()
                imlib2.imlib_get_text_size(text, w, h);
                return w[0], h[0]
            end,
            getAdvance = function(self, text)
                local text = text or ""
                local h, v = ffi.new('int [1]'), ffi.new('int [1]')
                fc()
                imlib2.imlib_get_text_advance(text, h, v)
                return h[0], v[0]
            end,
            getInset = function(self, text)
                fc()
                return imlib2.imlib_get_text_inset( text )
            end,
            getAscent = function(self)
                fc()
                return imlib2.imlib_get_font_ascent()
            end,
            getMaximumAscent = function(self)
                fc()
                return imlib2.imlib_get_maximum_font_ascent()
            end,
            getDescent = function(self)
                fc()
                return imlib2.imlib_get_font_descent()
            end,
            getMaximumDescent = function(self)
                fc()
                return imlib2.imlib_get_maximum_font_descent()
            end,

            __get = function()
                return fo
            end
        }

        return setmetatable(self, {
            __tostring = function(self)
                return string.format("Font: %s", path)
            end
        })
    end,
    __index = {
        listPaths = function()
            local cpaths = ffi.new('char **')
            local n = ffi.new('int [1]')
            cpaths = imlib2.imlib_list_font_path(n)
            local paths, n = {}, n[0]
            for i=0,n-1 do
                paths[#paths+1] = ffi.string(cpaths[i])
            end
            return paths
        end,
        addPath = function(path)
            assert(path, "Missing font path")
            imlib2.imlib_add_path_to_font_path(path)
        end,
        removePath = function(path)
            assert(path, "Missing font path")
            imlib2.imlib_remove_path_from_font_path(path)
        end,
        listFonts = function()
            local cfonts = ffi.new('char **')
            local n = ffi.new('int [1]')
            cfonts = imlib2.imlib_list_fonts(n)
            local n, fonts = n[0], {}
            for i=0,n-1 do
                fonts[#fonts+1] = ffi.string(cfonts[i])
            end
            imlib2.imlib_free_font_list(cfonts, n);
            return fonts
        end,
        setCacheSize = function(size)
            imlib2.imlib_set_font_cache_size(size);
        end,
        getCacheSize = function()
            return imlib2.imlib_get_font_cache_size()
        end,
        setDirection = function(dir, angle)
            local dirs = Font_dirs
            local dir = assert(dir and dirs[dir], "Unknown or missing font direction: "..(dir or "nil"))
            if (dir == ffi.C.IMLIB_TEXT_TO_ANGLE) then
                assert(angle, "Missing font direction angle value")
                imlib2.imlib_context_set_angle(angle)
            end
            imlib2.imlib_context_set_direction(dir)
        end,
        getDirection = function()
            local dirs = Font_dirs
            local dir = tonumber(imlib2.imlib_context_get_direction())
            if (dir == ffi.C.IMLIB_TEXT_TO_ANGLE) then
                local angle = imlib2.imlib_context_get_angle()
                return dirs[dir], angle
            else
                return dirs[dir]
            end
        end,
    }
})

-- Image

local set_color = function(c)
    imlib2.imlib_context_set_color(c.red, c.green, c.blue, c.alpha)
end
local Image
Image = setmetatable({}, {
    __call = function(self, w, h)
        if not w then error("Missing parameters", 3) end

        local imlib2, call_filter, set_color, im = imlib2, call_filter, set_color
        local sc = function()
            if not im or im==ffi.NULL then return end --error('Trying to call destroyed object', 3) end
            imlib2.imlib_context_set_image(im)
        end

        local image_gc = function(self)
            if not im or im==ffi.NULL then return end
            sc()
            imlib2.imlib_free_image()
        end

        ctype = type(w)
        if("string"==ctype and not h)then
            local err = ffi.new('Imlib_Load_Error [1]')
            im = ffi.gc(imlib2.imlib_load_image_with_error_return(w, err), image_gc)
            err = tonumber(err[0])
            if 0 ~= err then
                error( string.format( errors[err] or "Unknown error:"..err, w ), 3 )
            end
        elseif("cdata"==ctype)then
            im = ffi.gc(w, image_gc)
        elseif tonumber(w) and tonumber(h) then
            im = ffi.gc(imlib2.imlib_create_image(w,h), image_gc)
        else
            error("Missing parameters", 3)
        end

        local updates = imlib2.imlib_updates_init()

        local self = {
            fillGradient = function(self, gradient, x, y, w, h, angle)
                local angle = angle or 0.0
                sc()
                imlib2.imlib_context_set_color_range(gradient());
                imlib2.imlib_image_fill_color_range_rectangle(x, y, w, h, angle);
            end,
            drawPixel = function(self, x, y, c, update)
                sc()
                if(c)then set_color(c) end
                return imlib2.imlib_image_draw_pixel(x, y, update or 0)
            end,
            getPixel = function(self, x, y)
                sc()
                local c = Color_()
                imlib2.imlib_image_query_pixel(x, y, c)
                return Color(c)
            end,
            getPixelHSVA = function(self, x, y)
                sc()
                local hue, saturation, value, alpha = 
                    ffi.new('float[1]'),
                    ffi.new('float[1]'),
                    ffi.new('float[1]'),
                    ffi.new('int[1]')
                imlib2.imlib_image_query_pixel_hsva(x, y, hue, saturation, value, alpha)
                return hue[0], saturation[0], value[0], alpha[0]
            end,
            getPixelHLSA = function(self, x, y)
                sc()
                local hue, lightness, value, alpha = 
                    ffi.new('float[1]'),
                    ffi.new('float[1]'),
                    ffi.new('float[1]'),
                    ffi.new('int[1]')
                imlib2.imlib_image_query_pixel_hlsa(x, y, hue, lightness, saturation, alpha)
                return hue[0], lightness[0], saturation[0], alpha[0]
            end,
            getPixelCMYA = function(self, x, y)
                sc()
                local cyan, magenta, yellow, alpha = 
                    ffi.new('int[1]'),
                    ffi.new('int[1]'),
                    ffi.new('int[1]'),
                    ffi.new('int[1]')
                imlib2.imlib_image_query_pixel_cmya(x, y, cyan, magenta, yellow, alpha)
                return cyan[0], magenta[0], yellow[0], alpha[0]
            end,

            drawLine = function(self, x1, y1, x2, y2, c, update)
                sc()
                if(c)then set_color(c) end
                return imlib2.imlib_image_draw_line(x1, y1, x2, y2, update or 0)
            end,
            drawRectangle = function(self,x, y, w, h, c, update)
                sc()
                if(c)then set_color(c) end
                if (update) then
                    updates = imlib2.imlib_update_append_rect(updates, x, y, w, h)
                else
                    imlib2.imlib_image_draw_rectangle(x, y, w, h)
                end
            end,
            fillRectangle = function(self, x, y, w, h, c)
                sc()
                if(c)then set_color(c) end
                imlib2.imlib_image_fill_rectangle(x, y, w, h)
            end,
            scrollRectangle = function(self, x, y, w, h, dx, dy)
                sc()
                imlib2.imlib_image_scroll_rect(x, y, w, h, dx, dy)
            end,
            copyRectangle = function(self, x, y, w, h, dx, dy)
                sc()
                imlib2.imlib_image_copy_rect(x, y, w, h, dx, dy)
            end,

            copyAlpha = function(self, img, x, y)
                sc()
                imlib2.imlib_image_copy_alpha_to_image(img:__get(), x, y)
            end,
            copyAlphaRectangle = function(self, img, x, y, w, h, dx, dy)
                sc()
                imlib2.imlib_image_copy_alpha_rectangle_to_image(img:__get(), x, y, w, h, dx, dy)
            end,
            drawEllipse = function(self, xc, yc, a, b, c)
                sc()
                if(c)then set_color(c) end
                imlib2.imlib_image_draw_ellipse(xc,yc,a,b)
            end,
            fillEllipse = function(self, xc, yc, a, b, c)
                sc()
                if(c)then set_color(c) end
                imlib2.imlib_image_fill_ellipse(xc, yc, a, b);
            end,
            drawPolygon = function(self, poly, c, closed)
                if(c)then set_color(c) end
                sc()
                imlib2.imlib_image_draw_polygon(poly.__get(), closed or 0)
            end,
            fillPolygon = function(self, poly, c)
                if(c)then set_color(c) end
                sc()
                imlib2.imlib_image_fill_polygon(poly.__get());
            end,
            drawText = function(self, font, text, x, y, c)
                imlib2.imlib_context_set_font(font.__get())
                sc()
                if(c)then set_color(c) end
                local w, h, ha, va = ffi.new('int [1]'), ffi.new('int [1]'), ffi.new('int [1]'), ffi.new('int [1]')
                imlib2.imlib_text_draw_with_return_metrics(x, y, text, w, h, ha, va)
                return w[0], h[0], ha[0], va[0]
            end,

            merge = function(self, w, h, cb)
                do return nil, "Not implemented" end
                updates = imlib2.imlib_updates_merge_for_rendering(updates, w, h)
                local current = imlib2.imlib_updates_get_next(updates)
                while (current and current~=ffi.NULL) do
                    -- TODO
                end
            end,

            clip = function(self, x, y, w, h)
                sc()
                imlib2.imlib_context_set_cliprect(x, y, w, h)
            end,
            getClip = function(self)
                local x, y, w, h =
                    ffi.new('int[1]'),
                    ffi.new('int[1]'),
                    ffi.new('int[1]'),
                    ffi.new('int[1]')
                sc()
                imlib2.imlib_context_get_cliprect(x,y,w,h)
                return x[0], y[0], w[0], h[0]
            end,

            crop = function(self, x, y, w, h)
                sc()
                local new = ffi.gc(imlib2.imlib_create_cropped_image(x, y, w, h), image_gc)
                sc()
                imlib2.imlib_free_image()
                im = new
            end,
            cropAndScale = function(self, x, y, w, h, dw, dh)
                sc()
                local new = ffi.gc(imlib2.imlib_create_cropped_scaled_image(x, y, w, h, dw, dh), image_gc)
                sc()
                imlib2.imlib_free_image()
                im = new
            end,
            orientate = function(self,level)
                -- level * 90
                sc()
                imlib2.imlib_image_orientate(level)
            end,
            rotate = function(self, angle)
                if angle == 0 or angle == 360 then return end
                sc()
                if (angle%90==0)then
                    return imlib2.imlib_image_orientate(angle/90)
                end
                local angle = math.pi * angle / 180
                local new = ffi.gc(imlib2.imlib_create_rotated_image(angle), image_gc)
                sc()
                imlib2.imlib_free_image()
                im = new
            end,
            flipHorizontal = function()
                sc()
                imlib2.imlib_image_flip_horizontal()
            end,
            flipVertical = function()
                sc()
                imlib2.imlib_image_flip_vertical()
            end,
            flipDiagonal = function()
                sc()
                imlib2.imlib_image_flip_diagonal()
            end,

            tile = function()
                sc()
                imlib2.imlib_image_tile()
            end,
            tileHorizontal = function()
                sc()
                imlib2.imlib_image_tile_horizontal()
            end,
            tileVertical = function()
                sc()
                imlib2.imlib_image_tile_vertical()
            end,
            blur = function(self,rad)
                sc()
                imlib2.imlib_image_blur(rad)
            end,
            sharpen = function(self,rad)
                sc()
                imlib2.imlib_image_sharpen(rad)
            end,

            -- transform plugins
            transform = function(self, matrix, factor, bias, grayscale)
                local h = math.sqrt(#matrix)
                local w = h
                local factor = factor
                if not factor then
                    local sum = 0.0
                    for _,v in next,matrix do
                        sum = sum + v
                    end
                    factor = 1.0 / (sum>0 and sum or 1.0)
                end
                local bias = bias or 0.0
                
                local filter = Filter()
                filter.filterW = w
                filter.filterH = h
                filter.factor = factor
                filter.bias = bias
                filter.matrix = ffi.new("double [?]", #matrix, unpack(matrix))
                sc()
                plugins.transform(im, filter, grayscale or 0)
            end,
            grayscale = function(self, method)
                sc()
                plugins.grayscale(im, method or 0)
            end,
            motionblur = function(self)
                sc()
                plugins.motionblur(im)
            end,
            emboss = function(self, grayscale, factor, bias)
                sc()
                plugins.emboss(im, factor or 0, bias or 0, grayscale or 0)
            end,
            removenoise = function(self, matrix)
                local h = math.sqrt(#matrix)
                local w = h
                local factor = factor
                if not factor then
                    local sum = 0.0
                    for _,v in next,matrix do
                        sum = sum + v
                    end
                    factor = 1.0 / (sum>0 and sum or 1.0)
                end
                local bias = bias or 0.0
                
                local filter = Filter()
                filter.filterW = w
                filter.filterH = h
                filter.factor = factor
                filter.bias = bias
                filter.matrix = ffi.new("double [?]", #matrix, unpack(matrix))

                sc()
                plugins.removenoise(im, filter)
            end,
            quickremovenoise = function()
                sc()
                plugins.quickremovenoise(im, 0, 0)
            end,

            filter = function(self, name, ...)
                call_filter(name, im, ...)
            end,
            -- TODO: get list of files, load them (require) and get info
            listFilters = function()
                local f = {}
                for k,v in next,filters do
                    f[k] = v.info
                end
                return f
            end,
            helpFilter = function(self, name, option)
                if option then
                    return filters[name].help[option] or "no help on "..option
                else
                    return filters[name].help or {}
                end
            end,

            clear = function()
                sc()
                imlib2.imlib_image_clear()
            end,

            getWidth = function(self)
                sc()
                return imlib2.imlib_image_get_width()
            end,
            getHeight = function(self)
                sc()
                return imlib2.imlib_image_get_height()
            end,
            getBorder = function()
                local b = Border()
                sc()
                imlib2.imlib_image_get_border(b)
                return b
            end,
            setBorder = function(self,b)
                sc()
                imlib2.imlib_image_set_border(b)
            end,
            hasAlpha = function()
                sc()
                local r = imlib2.imlib_image_has_alpha()
                return r==1
            end,
            setAlpha = function(alpha)
                sc()
                imlib2.imlib_image_set_has_alpha(alpha and 1 or 0)
            end,

            getFilename = function()
                sc()
                local f = imlib2.imlib_image_get_filename()
                if not f or f==ffi.NULL then return nil end
                return ffi.string(f)
            end,
            getFormat = function()
                sc()
                local f = imlib2.imlib_image_format()
                if not f or f==ffi.NULL then return nil end
                return ffi.string(f)
            end,
            setFormat = function(self, fmt)
                if not fmt or fmt:match('^%s*$') then error("Missing format",3) end
                sc()
                imlib2.imlib_image_set_format(fmt)
            end,

            -- a bit useless as apparently not saved with the picture...
            -- setData = function(self, key, data, value)
            --     local data = ffi.new('char [?]',#data, data)
            --     sc()
            --     imlib2.imlib_image_attach_data_value(key, data, value, nil)
            -- end,
            -- getData = function(self, key)
            --     sc()
            --     local data = imlib2.imlib_image_get_attached_data(key)
            --     local data = ffi.cast('char*',data)
            --     print(data)
            --     data = data~=ffi.NULL and ffi.string(data) or nil
            --     return data
            -- end,
            -- deleteData = function(self,key)
            -- end,

            blend = function(self, other_im, merge_alpha, x, y, w, h, dx, dy, dw, dh)
                sc()
                imlib2.imlib_blend_image_onto_image(other_im.__get(), merge_alpha or 0, x, y, w, h, dx, dy, dw, dh)
            end,

            script = function(self, filter)
                sc()
                -- WARNING: imlib2 bug: scripts containing spaces are not executed
                -- TODO: improve this parsing to take care of \"
                --local filter = filter:gsub('%s','')
                imlib2.imlib_apply_filter( ffi.cast('char*',filter) )
            end,

            dump = function()
                sc()
                local data = imlib2.imlib_image_get_data_for_reading_only()

                local im = ffi.new('ImageData')
                im.data = data
                im.has_alpha = imlib2.imlib_image_has_alpha()
                im.w = imlib2.imlib_image_get_width()
                im.h = imlib2.imlib_image_get_height()

                local length = ffi.new('int [1]')
                local result = dumper.save(im, length)
                local data = ffi.string(result, length[0])
                dumper.free_data(result)
                return data
            end,
            save = function(self, path)
                local err = ffi.new('Imlib_Load_Error [1]')
                sc()
                imlib2.imlib_save_image_with_error_return(path, err)
                err = err and tonumber(err[0])
                if 0 ~= err then
                    return nil, string.format(errors[err] or "Unknown error", path)
                end
                return true
            end,
            clone = function(self)
                sc()
                local clone = imlib2.imlib_clone_image()
                return Image(clone)
            end,
            free = function(self)
                sc()
                imlib2.imlib_free_image()
                im = nil
                self = {}
                return nil
            end,

            __get = function()
                return im
            end
        }
        return self
    end
})

local setCacheSize = function(size)
    imlib2.imlib_set_cache_size(size)
end
local getCacheSize = function(size)
    return imlib2.imlib_get_cache_size()
end
local flushCache = function()
    local csize = imlib2.imlib_get_cache_size()
    imlib2.imlib_set_cache_size(0);
    imlib2.imlib_set_cache_size(csize);
end
local setAntiAlias = function(aa)
    assert(aa~=nil, "Missing Anti Alias flag")
    imlib2.imlib_context_set_anti_alias(aa or 0)
end
local getAntiAlias = function()
    local aa = imlib2.imlib_context_get_anti_alias()
    return aa==1
end

return {
    setCacheSize  = setCacheSize,
    getCacheSize  = getCacheSize,
    flushCache    = flushCache,
    setAntiAlias  = setAntiAlias ,
    getAntiAlias  = getAntiAlias,

    Gradient      = Gradient,
    Color         = Color,
    ColorModifier = ColorModifier,
    Image         = Image,
    Border        = Border,
    Polygon       = Polygon,
    Font          = Font,
}
