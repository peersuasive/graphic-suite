=========================
draft for a graphic suite
=========================

(based on imlib2)

ffi binding, greatly inspired by `lua-imlib2 <https://github.com/asb/lua-imlib2>`__

filters are implemented based on different sources (see comments in code)


---

requirements
============

- luajit (should work with lua+ffi too)
- imlib2
- libpng 1.2


examples
========

load an existing image
----------------------

.. code:: lua

    local imlib2 = require"imlib2"

    -- load test.png
    local im = imlib2.Image('resources/test.png')

    -- use Jitter filter to add some noise
    im:filter('jitter')

    -- save
    im:save('result.png')


create a new image
------------------

.. code:: lua

    local imlib2 = require"imlib2"

    local Image, Color, Gradient = imlib2.Image, imlib2.Color, imlib2.Gradient

    -- create a new 256x256 canvas, with a white background (default: black)
    local im = Image(256,256, Color.WHITE)

    -- add some Gaussian noise
    im:filter('wgn')

    -- scale 2x
    im:scale(2)

    -- crop x,y,w,h
    im:crop(0,0,256,256)

    -- resize 128x128 (WxH, H==W if not provided)
    im:resize(128)

    im:drawRectangle(10,10,100,100, Color.RED)

    -- create a gradient colour
    local gr = Gradient()
    gr:addColor(0, Color(128,10,10,200))
    gr:addColor(1, Color.GREEN)

    -- fill the rectangle with the gradient colour at an angle or 135
    -- and a gap of 5
    im:fillGradient(gr, 15,15,90,90, 135)

    -- add a white, semi-transparent rectangle in the middle
    im:fillRectangle(40,40, 40, 40, Color(255,255,255,150))

    -- save
    im:save('result.png')


import all classes and methods locally
--------------------------------------

.. code:: lua

    local imlib2 = require"imlib2"
    local
        Gradient,
        Color,
        ColorHSLA,
        ColorModifier,
        Image,
        Border,
        Polygon,
        Font,
        setCacheSize,
        getCacheSize,
        flushCache,
        setAntiAlias,
        getAntiAlias
        = 
        imlib2.Gradient,
        imlib2.Color,
        imlib2.ColorHSLA,
        imlib2.ColorModifier,
        imlib2.Image,
        imlib2.Border,
        imlib2.Polygon,
        imlib2.Font,
        imlib2.setCacheSize,
        imlib2.getCacheSize,
        imlib2.flushCache,
        imlib2.setAntiAlias,
        imlib2.getAntiAlias


API
===

Image
-----

Image(w[,h,[Color,transparent=false])

Image("file.ext")

drawing methods
~~~~~~~~~~~~~~~

    fillGradient (Gradient, x, y, w, h, angle)

    drawPixel (x, y, c, update)

    getPixel (x, y)

    getPixelHSVA (x, y)

    getPixelHSLA (x, y)

    getPixelCMYA (x, y)

    drawLine (x1, y1, x2, y2, Color, update)

    drawRectangle (x, y, w, h, Color, update)

    fillRectangle (x, y, w, h, Color)

    scrollRectangle (x, y, w, h, dx, dy)

    copyRectangle (x, y, w, h, dx, dy)

    copyAlpha (img, x, y)

    copyAlphaRectangle (img, x, y, w, h, dx, dy)

    drawEllipse (xc, yc, a, b, Color)

    fillEllipse (xc, yc, a, b, Color)

    drawPolygon (Polygon, Color, closed)

    fillPolygon (Polygon, Color)

    drawText (font, text, x, y, Color)

    clip (x, y, w, h)

    getClip ()

    orientate (level)

    rotate (angle)

    flipHorizontal ()

    flipVertical ()

    flipDiagonal ()

    tile ()

    tileHorizontal ()

    tileVertical ()

    blur (rad)

    sharpen (rad)

    clear ()

filters
~~~~~~~

    transform (matrix, factor, bias, grayscale)
        apply a transformation matrix (see imfilters/transform)

    filter (name, ...)
        transform filter to use
 
    listFilters ()
        list available filters

    helpFilter (name, option)
        get help on filter options (or all available help when option name is not provided)

get/set
~~~~~~~

    getWidth ()

    getHeight ()

    getBorder ()

    setBorder (b)

    hasAlpha ()

    setAlpha (alpha)

    getFilename ()

    getFormat ()

    setFormat (fmt)
        can be one of png, jpg or gif
        if unset, file extension will be used when saving image

image manipulation
~~~~~~~~~~~~~~~~~~

    blend (...)
        blend(width,[height],{option=value,...})
                
        blend, resize or scale an image onto a new image or in-place

        width, height
            resize to widht and height (height=width if omitted)

        options:

        keep_aspect
            keep width/height aspect ratio (omit width to scale with height)

        in_place
            blend onto current image instead of creating a new one

        colour
            set background colour

        transparent
            active alpha channel on background colour or set a transparent background (default: black)

        merge_alpha
            when background colour is provided, blend image with background alpha channel

        x,y,w,h
            use this portion of source

        dx,dy
            put source image at x,y onto destination

        dw,dh
            set destination image width and height (height=width if not provided)

        return
            image or nil[, error]

    resize (dw,dh,in_place)
        resize image (if in_place if false, return a new image and leave source untouched)

    scale (ratio, in_place)
        scale image (if in_place if false, return a new image and leave source untouched)

    crop (x, y, w, h,...)
        crop(x,y,w,h,[dw,dh],[in-place])

        crop or crop and scale an image in-place or as a new image

        x,y,w,h: dimension of source to crop
        dw,dh: dimension of target image, if scaling (default: nil, no scaling)
        in-place: crop in place or return a new image (default: true)


saving and cloning
~~~~~~~~~~~~~~~~~~

    data ()
        get internal data

    dump ()
        get data as a PNG string

    save (path)
        save to file (extension matters if format is not set)

    clone ()
        clone to as a new Image

internal
~~~~~~~~

    free ()
        frees internal image object (this is normally done by luajit's gc)

    __get ()
        returns imlib2's image object


Color
-----

Color(r,g,b,a)

Color(ColorHSLA)

methods
~~~~~~~

    clone()
        return a copy of the current colour

    toHSLA()
        return a ColorHSLA colour based on current one

    red, green, blue, alpha
        get or set the channel value
    
predefined colours
~~~~~~~~~~~~~~~~~~
::

        colour      r, g, b, a

        CLEAR       0, 0, 0, 0
        TRANSPARENT 0, 0, 0, 0
        TRANSLUCENT 0, 0, 0, 0
        SHADOW      0, 0, 0, 64
        BLACK       0, 0, 0, 255
        DARKGRAY    64, 64, 64, 255
        DARKGREY    64, 64, 64, 255
        GRAY        128, 128, 128, 255
        GREY        128, 128, 128, 255
        LIGHTGRAY   192, 192, 192, 255
        LIGHTGREY   192, 192, 192, 255
        WHITE       255, 255, 255, 255
        RED         255, 0, 0, 255
        GREEN       0, 255, 0, 255
        BLUE        0, 0, 255, 255
        YELLOW      255, 255, 0, 255
        ORANGE      255, 128, 0, 255
        BROWN       128, 64, 0, 255
        MAGENTA     255, 0, 128, 255
        VIOLET      255, 0, 255, 255
        PURPLE      128, 0, 255, 255
        INDIGO      128, 0, 255, 255
        CYAN        0, 255, 255, 255
        AQUA        0, 128, 255, 255
        AZURE       0, 128, 255, 255
        TEAL        0, 255, 128, 255
        DARKRED     128, 0, 0, 255
        DARKGREEN   0, 128, 0, 255
        DARKBLUE    0, 0, 128, 255
        DARKYELLOW  128, 128, 0, 255
        DARKORANGE  128, 64, 0, 255
        DARKBROWN   64, 32, 0, 255
        DARKMAGENTA 128, 0, 64, 255
        DARKVIOLET  128, 0, 128, 255
        DARKPURPLE  64, 0, 128, 255
        DARKINDIGO  64, 0, 128, 255
        DARKCYAN    0, 128, 128, 255
        DARKAQUA    0, 64, 128, 255
        DARKAZURE   0, 64, 128, 255
        DARKTEAL    0, 128, 64, 255

ColorHSLA
---------

ColorHSLA(h,s,l,a)

ColorHSLA(Color)

methods
~~~~~~~

    clone()
        return a copy of the current colour

    toRGBA()
        return a RGB Color object based on current one

    hue, saturation, lighness, alpha
        get or set the channel value
 

ColorModifier
-------------

ColorModifier()

methods
~~~~~~~

    setGamma (v)

    setBrightness (v)

    setContrast (v)

    setModifierTables (red,green,blue,alpha)

    getModifierTables ()

    reset ()

    apply ()

    applyToRectangle ( x, y, w, h )



Gradient
--------

Gradient()

methods
~~~~~~~

    addColor ( offset, Color )


Border
------

Border( left, right, top, bottom )

methods
~~~~~~~

    clone ()
        clone existing border

    left, right, top, bottom
        get or set value

Polygon
-------

Polygon()

methods
~~~~~~~

    addPoint (x,y)
        add a new point to the polygon

    getBounds ()

    containsPoint (x, y)


Font
----

Font(path)

static methods
~~~~~~~~~~~~~~

    listPaths ()

    addPath (path)
    
    removePath (path)

    listFonts ()

    setCacheSize (size)

    getCacheSize ()

    setDirection (dir, angle)

    getDirection ()


methods
~~~~~~~

    getSize (text)

    getAdvance (text)

    getInset (text)

    getAscent ()

    getMaximumAscent ()

    getDescent ()

    getMaximumDescent ()


