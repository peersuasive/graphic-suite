#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <stdbool.h>

#include <Imlib2.h>

#include "transform.h"

// http://lodev.org/cgtutor/filtering.html

#define max(a,b) (((a) > (b)) ? (a) : (b))
#define min(a,b) (((a) < (b)) ? (a) : (b))

enum _grayscale_method {
    NONE,
    LIGTHNESS,
    AVERAGE,
    LUMINOSITY
};
typedef enum _grayscale_method Grayscale;

void transform(Imlib_Image im, Filter filter, Grayscale grayscale) {
    DATA32              *src, *p1, *data, *p2;
    int                 w, h, x, y;

    imlib_context_set_image(im);
    src = imlib_image_get_data();
    w = imlib_image_get_width();
    h = imlib_image_get_height();

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

            int x = (a << 24) | (r << 16) | (g << 8) | b;

            int grey, mx, mn;
            switch(grayscale) {
                case AVERAGE:
                    grey = (r+g+b)/3;
                    *p2 = (a << 24) | (grey << 16) | (grey << 8) | grey;
                    break;
                case LIGTHNESS:
                    //grey = (max(r,g,b) + min(r,g,b))/2;
                    mx = r > g ? r : g;
                    mx = mx > b ? mx : b;
                    mn = r < g ? r : g;
                    mn = mn < b ? mn : b;
                    grey = (mn + mx) / 2;
                    *p2 = (a << 24) | (grey << 16) | (grey << 8) | grey;
                    break;
                case LUMINOSITY:
                    grey = (int)(0.21*r + 0.72*g + 0.07*b);
                    *p2 = (a << 24) | (grey << 16) | (grey << 8) | grey;
                    break;
                case NONE:
                default:
                    *p2 = (a << 24) | (r << 16) | (g << 8) | b;
                    break;
            }
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

void grayscale(Imlib_Image im, Grayscale method) {
    DATA32              *src, *p1, *data, *p2;
    int                 w, h, x, y;

    imlib_context_set_image(im);
    src = imlib_image_get_data();
    w = imlib_image_get_width();
    h = imlib_image_get_height();

    data = malloc(w * h * sizeof(DATA32));

    for (y = 0; y < h; ++y) {
        p1 = src + (y * w);
        p2 = data + (y * w);
        for (x = 0; x < w; ++x) {
            int b = (int)((p1[0]) & 0xff);
            int g = (int)((p1[0] >> 8) & 0xff);
            int r = (int)((p1[0] >> 16) & 0xff);
            int a = (int)((p1[0] >> 24) & 0xff);

            int grey, mx, mn;
            switch(method) {
                case NONE:
                case AVERAGE:
                    grey = (r+g+b)/3;
                    break;
                case LIGTHNESS:
                    //grey = (max(r,g,b) + min(r,g,b))/2;
                    mx = r > g ? r : g;
                    mx = mx > b ? mx : b;
                    mn = r < g ? r : g;
                    mn = mn < b ? mn : b;
                    grey = (mn + mx) / 2;
                    break;
                case LUMINOSITY:
                    grey = (int)(0.21*r + 0.72*g + 0.07*b);
                    break;
            }
            *p2 = (a << 24) | (grey << 16) | (grey << 8) | grey;
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

/*
 * some predefined tranformations 
 */

void transform_filter(Imlib_Image im, double *matrix, int length, double factor, double bias, Grayscale _gs) {
    Grayscale gs = _gs ? _gs : 0;
    int w, h;
    h = w = sqrt(length);
    Filter filter;
    filter.filterW = w;
    filter.filterH = h;
    filter.factor = factor;
    filter.bias = bias;
    filter.matrix = matrix;
    transform(im, filter, gs);
}

double sum(double *matrix, int size) {
    double sum = 0.0;
    double *ptr = matrix;
    for (int i=0;i<size;++i) {
        sum += *ptr;
        ++ptr;
    }
    sum = sum ? sum : 1.0;
    return sum;
}

/* template */
//void f(Imlib_Image im, double _factor, double _bias) {
//    double matrix[] = {
//    };
//    int len = sizeof(matrix)/sizeof(matrix[0]);
//    double factor = _factor ? _factor : 1.0 / sum(matrix,len);
//    double bias = _bias ? _bias : 0.0;
//    transform_filter( im, matrix, len, factor, bias, 0 );
//}

/* soft blur */
void softblur(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
         0.0, 0.2,  0.0,
         0.2, 0.2,  0.2,
         0.0, 0.2,  0.0
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* blur */
void blur(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        0, 0, 1, 0, 0,
        0, 1, 1, 1, 0,
        1, 1, 1, 1, 1,
        0, 1, 1, 1, 0,
        0, 0, 1, 0, 0,
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0 / 13;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* motion blur */
void motionblur(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
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
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0 / 9.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* edges */
void edges(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        0,  0,  0,  0,  0,
        0,  0,  0,  0,  0,
        -1, -1,  2,  0,  0,
        0,  0,  0,  0,  0,
        0,  0,  0,  0,  0,
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* vertical edges */
void verticaledges(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        0,  0, -1,  0,  0,
        0,  0, -1,  0,  0,
        0,  0,  4,  0,  0,
        0,  0, -1,  0,  0,
        0,  0, -1,  0,  0,
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* edges at 45° */
void edges45(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        -1,  0,  0,  0,  0,
        0, -2,  0,  0,  0,
        0,  0,  6,  0,  0,
        0,  0,  0, -2,  0,
        0,  0,  0,  0, -1,
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* edges in all directions */
void alledges(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        -1, -1, -1,
        -1,  8, -1,
        -1, -1, -1
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* excessively finds edges */
void excessiveedges(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        1,  1,  1,
        1, -7,  1,
        1,  1,  1
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* sharpen */
void sharpen(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        -1, -1, -1,
        -1,  9, -1,
        -1, -1, -1
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* soft sharpen */
void softsharpen(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        -1, -1, -1, -1, -1,
        -1,  2,  2,  2, -1,
        -1,  2,  8,  2, -1,
        -1,  2,  2,  2, -1,
        -1, -1, -1, -1, -1,
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0 / 8.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

/* emboss */
void emboss(Imlib_Image im, double _factor, double _bias, Grayscale _gs) {
    double matrix[] = {
        -1, -1,  0,
        -1,  0,  1,
        0,  1,  1
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0;
    double bias = _bias ? _bias : 128.0;
    Grayscale gs = _gs ? _gs : 0;
    transform_filter( im, matrix, len, factor, bias, gs );
}


/* remove noise (mean filter) */
void quickremovenoise(Imlib_Image im, double _factor, double _bias) {
    double matrix[] = {
        1, 1, 1,
        1, 1, 1,
        1, 1, 1
    };
    int len = sizeof(matrix)/sizeof(matrix[0]);
    double factor = _factor ? _factor : 1.0 / 9.0;
    double bias = _bias ? _bias : 0.0;
    transform_filter( im, matrix, len, factor, bias, 0 );
}

//combsort: bubble sort made faster by using gaps to eliminate turtles
void combsort(int * data, int amount) {
    int gap = amount;
    bool swapped = false;
    while(gap > 1 || swapped) {
        //shrink factor 1.3
        gap = (gap * 10) / 13;
        if(gap == 9 || gap == 10) gap = 11;
        if (gap < 1) gap = 1;
        swapped = false;
        for (int i = 0; i < amount - gap; i++) {
            int j = i + gap;
            if (data[i] > data[j])
            {
                data[i] += data[j]; 
                data[j] = data[i] - data[j]; 
                data[i] -= data[j]; 
                swapped = true;
            }
        }
    }
}

/* remove noise (median filter) */
void removenoise(Imlib_Image im, Filter filter) {
    DATA32              *src, *p1, *data, *p2;

    imlib_context_set_image(im);
    int w = imlib_image_get_width(),
        h = imlib_image_get_height();

    src = imlib_image_get_data();
    data = malloc(w * h * sizeof(DATA32));

    int fs = filter.filterW * filter.filterH;
    int med = fs/2;
    int red[fs], green[fs], blue[fs], alpha[fs];
    for (int y = 0; y < h; ++y) {
        p1 = src + (y * w);
        p2 = data + (y * w);
        for (int x = 0; x < w; ++x) {
            int n = 0;
            for(int fx=0;fx<filter.filterW;++fx)
            for(int fy=0;fy<filter.filterH;++fy) {
                int ix = (x - filter.filterW / 2 + fx + w) % w; 
                int iy = (y - filter.filterH / 2 + fy + h) % h; 

                int pos = ix + iy * w;
                
                blue[n] = (int)((src[pos]) & 0xff);
                green[n] = (int)((src[pos] >> 8) & 0xff);
                red[n] = (int)((src[pos] >> 16) & 0xff);
                alpha[n] = (int)((src[pos] >> 24) & 0xff);
                
                ++n;
            }
            combsort(red, fs);
            combsort(green, fs);
            combsort(blue, fs);
            combsort(alpha, fs);

            if ( (fs)%2 == 1 ) {
                *p2 = (alpha[med] << 24) | (red[med] << 16) | (green[med] << 8) | blue[med];
            } 
            else if (filter.filterW > 1) {
                int a,r,g,b;
                a = (alpha[med] + alpha[med+1])/2;
                r = (red[med] + red[med+1])/2;
                g = (green[med] + green[med+1])/2;
                b = (blue[med] + blue[med+1])/2;
                *p2 = (a << 24) | (r << 16) | (g << 8) | b;
            }
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
