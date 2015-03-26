#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include <Imlib2.h>

// http://lodev.org/cgtutor/filtering.html


#define max(a,b) (((a) > (b)) ? (a) : (b))
#define min(a,b) (((a) < (b)) ? (a) : (b))

void sharpen(Imlib_Image im) {
    DATA32             *p1, *p2, *src, *data;
    int                 a, r, g, b, x, y, w, h;
    int rad = 5;

    printf("SHARPEN (extern)\n");
    imlib_context_set_image(im);
    src = imlib_image_get_data();
    w = imlib_image_get_width();
    h = imlib_image_get_height();

    data = malloc(w*h*sizeof(DATA32));
    for (y = 1; y < (h - 1); y++) {
        p1 = src + 1 + (y * w);
        p2 = data + 1 + (y * w);
        for (x = 1; x < (w - 1); x++) {
            b = (int)((p1[0]) & 0xff) * rad;
            g = (int)((p1[0] >> 8) & 0xff) * rad;
            r = (int)((p1[0] >> 16) & 0xff) * rad;
            a = (int)((p1[0] >> 24) & 0xff) * rad;
            b -= (int)((p1[-1]) & 0xff);
            g -= (int)((p1[-1] >> 8) & 0xff);
            r -= (int)((p1[-1] >> 16) & 0xff);
            a -= (int)((p1[-1] >> 24) & 0xff);
            b -= (int)((p1[1]) & 0xff);
            g -= (int)((p1[1] >> 8) & 0xff);
            r -= (int)((p1[1] >> 16) & 0xff);
            a -= (int)((p1[1] >> 24) & 0xff);
            b -= (int)((p1[-w]) & 0xff);
            g -= (int)((p1[-w] >> 8) & 0xff);
            r -= (int)((p1[-w] >> 16) & 0xff);
            a -= (int)((p1[-w] >> 24) & 0xff);
            b -= (int)((p1[w]) & 0xff);
            g -= (int)((p1[w] >> 8) & 0xff);
            r -= (int)((p1[w] >> 16) & 0xff);
            a -= (int)((p1[w] >> 24) & 0xff);

            a = (a & ((~a) >> 16));
            a = ((a | ((a & 256) - ((a & 256) >> 8))));
            r = (r & ((~r) >> 16));
            r = ((r | ((r & 256) - ((r & 256) >> 8))));
            g = (g & ((~g) >> 16));
            g = ((g | ((g & 256) - ((g & 256) >> 8))));
            b = (b & ((~b) >> 16));
            b = ((b | ((b & 256) - ((b & 256) >> 8))));

            *p2 = (a << 24) | (r << 16) | (g << 8) | b;
            p1++;
            p2++;
        }
    }

    int i = 0, max = w*h;
    for (i=0;i<max;++i) {
        DATA32 p = data[i];
        src[i] = p;
    }
    free(data);

    imlib_context_set_image(im);
    imlib_image_put_back_data( src );
}

void emboss(Imlib_Image im) {
    DATA32              *src, *p1, *data, *p2;
    int                 w, h, r, g, b, x, y;

    imlib_context_set_image(im);
    src = imlib_image_get_data();
    w = imlib_image_get_width();
    h = imlib_image_get_height();

    data = malloc(w * h * sizeof(DATA32));

    for (y = 0; y < h; ++y) {
        p1 = src + (y * w);
        p2 = data + (y * w);
        for (x = 0; x < w; ++x) {
            b = (int)((p1[0]) & 0xff);
            g = (int)((p1[0] >> 8) & 0xff);
            r = (int)((p1[0] >> 16) & 0xff);

            int upperLeft = 0;
            if (y > 0 && x > 0)
                upperLeft = src[(x+y*w)-1];

            int rDiff = r - ((upperLeft >> 16) & 0xff);
            int gDiff = g - ((upperLeft >> 8) & 0xff);
            int bDiff = b - (upperLeft & 0xff);

            int diff = rDiff;
            if (abs(gDiff) > abs(diff))
                diff = gDiff;
            if (abs(bDiff) > abs(diff))
                diff = bDiff;

            int grayLevel = max(min(128 + diff, 255), 0);
           
            *p2 = (grayLevel << 16) + (grayLevel << 8) + grayLevel;

            p2++;
            p1++;
        }
    }
    
    int i, max=w*h;
    for (i=0;i<max;++i) {
        DATA32 p = data[i];
        src[i] = p;
    }
    free(data);
    imlib_context_set_image(im);
    imlib_image_put_back_data( src );
}

struct _filter {
    int filterW;
    int filterH;
    double factor;
    double bias;
    double *matrix;
};
typedef struct _filter Filter;

void transform(Imlib_Image im, Filter filter) {
    DATA32              *src, *p1, *data, *p2;
    int                 w, h, x, y;

    imlib_context_set_image(im);
    src = imlib_image_get_data();
    w = imlib_image_get_width();
    h = imlib_image_get_height();

//#define fW 3
//#define fH 3
//    double filter[fW][fH] = { 
//         0, 0, 0,
//         0, 1, 0,
//         0, 0, 0
//    };
//    double factor = 1.0;
//    double bias = 0.0;

    data = malloc(w * h * sizeof(DATA32));

    for (y = 0; y < h; ++y) {
        p1 = src + (y * w);
        p2 = data + (y * w);
        for (x = 0; x < w; ++x) {
            double red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
            for(int fx=0;fx<filter.filterW;++fx)
            for(int fy=0;fy<filter.filterH;++fy) {
                int ix = (x - filter.filterW / 2 + fx + w) % w; 
                int iy = (y - filter.filterH / 2 + fy + h) % h; 

                int pos = ix + iy * w;
                
                int b = (int)((src[pos]) & 0xff);
                int g = (int)((src[pos] >> 8) & 0xff);
                int r = (int)((src[pos] >> 16) & 0xff);
                int a = (int)((src[pos] >> 24) & 0xff);
                
                double fv = *((filter.matrix + fx*filter.filterW) + fy);
                red += r * fv;
                green += g * fv;
                blue += b * fv;
                alpha += a * fv;
            }
            int r = min(max((filter.factor * red + filter.bias), 0), 255);
            int g = min(max((filter.factor * green + filter.bias), 0), 255);
            int b = min(max((filter.factor * blue + filter.bias), 0), 255);
            int a = min(max((filter.factor * alpha + filter.bias), 0), 255);

            *p2 = (a << 24) | (r << 16) | (g << 8) | b;
            ++p1;
            ++p2;
        }
    }

    int i, max=w*h;
    for (i=0;i<max;++i) {
        DATA32 p = data[i];
        src[i] = p;
    }
    free(data);
    imlib_context_set_image(im);
    imlib_image_put_back_data( src );
}

void motionblur(Imlib_Image im) {
#define motion_blur_fW 9
#define motion_blur_fH 9
    double motion_blur[motion_blur_fW][motion_blur_fH] = {
        1, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 1,
    };
    double factor = 1.0 / 9.0;
    double bias = 0.0;

    Filter blur;
    blur.filterW = motion_blur_fW;
    blur.filterH = motion_blur_fH;
    blur.factor = factor;
    blur.bias = bias;
    blur.matrix = (double*)motion_blur;

    transform( im, blur );
}

void custom(Imlib_Image im, Filter f) {
    transform(im, f);
}
