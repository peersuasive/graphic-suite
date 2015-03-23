#include <stdlib.h>
#include <png.h>
#include "dump.h"

void dump_write_data(png_structp png_ptr, png_bytep data, png_size_t length);
void dump_write_data(png_structp png_ptr, png_bytep data, png_size_t length) {
    DumpData *ptr = (DumpData*)png_ptr->io_ptr;
    ptr->data = realloc(ptr->data, ptr->size + sizeof(char)*length);
    memcpy(ptr->data+ptr->size, data, length);
    ptr->size += length;
}

void dump_flush(png_structp png_ptr);
void dump_flush(png_structp png_ptr) {
    png_ptr = png_ptr;
}

char *save(ImageData *im, int *length) {
    png_structp   png_ptr;
    png_infop     info_ptr;
    DATA32       *ptr;
    int           x, y, j, interlace;
    png_bytep     row_ptr, data = NULL;
    png_color_8   sig_bit;
    int           pl = 0;
    char          pper = 0;
    int           quality = 75, compression = 3, num_passes = 1, pass;
    
    DumpData      dump_data; // = malloc(sizeof(DumpData));
    dump_data.size = 0;
    dump_data.data = NULL;

    if (!im->data)
        return 0;

    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png_ptr) {
        return 0;
    }
    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr) {
        png_destroy_write_struct(&png_ptr, (png_infopp) NULL);
        return 0;
    }
    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_write_struct(&png_ptr, (png_infopp) & info_ptr);
        png_destroy_info_struct(png_ptr, (png_infopp) & info_ptr);
        return 0;
    }

    /* check whether we should use interlacing */
    interlace = PNG_INTERLACE_NONE;

    png_set_write_fn(png_ptr, (png_voidp)&dump_data, dump_write_data, dump_flush);

    if (im->has_alpha) {
        png_set_IHDR(png_ptr, info_ptr, im->w, im->h, 8,
                PNG_COLOR_TYPE_RGB_ALPHA, interlace,
                PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
#ifdef WORDS_BIGENDIAN
        png_set_swap_alpha(png_ptr);
#else
        png_set_bgr(png_ptr);
#endif
    }
    else {
        png_set_IHDR(png_ptr, info_ptr, im->w, im->h, 8, PNG_COLOR_TYPE_RGB,
                interlace, PNG_COMPRESSION_TYPE_BASE,
                PNG_FILTER_TYPE_BASE);
        data = malloc(im->w * 3 * sizeof(char));

        sig_bit.red = 8;
        sig_bit.green = 8;
        sig_bit.blue = 8;
        sig_bit.alpha = 8;
        png_set_sBIT(png_ptr, info_ptr, &sig_bit);

        /* convert to compression */
        quality = quality / 10;
        /* compression */
        compression = 9 - quality;
        if (compression < 0)
            compression = 0;
        if (compression > 9)
            compression = 9;

        png_set_compression_level(png_ptr, compression);
        png_write_info(png_ptr, info_ptr);
        png_set_shift(png_ptr, &sig_bit);
        png_set_packing(png_ptr);

#ifdef PNG_WRITE_INTERLACING_SUPPORTED
        num_passes = png_set_interlace_handling(png_ptr);
#endif

        for (pass = 0; pass < num_passes; pass++) {
            ptr = im->data;

            for (y = 0; y < im->h; y++) {
                if (im->has_alpha)
                    row_ptr = (png_bytep) ptr;
                else {
                    for (j = 0, x = 0; x < im->w; x++) {
                        data[j++] = (ptr[x] >> 16) & 0xff;
                        data[j++] = (ptr[x] >> 8) & 0xff;
                        data[j++] = (ptr[x]) & 0xff;
                    }
                    row_ptr = (png_bytep) data;
                }
                png_write_rows(png_ptr, &row_ptr, 1);
                ptr += im->w;
            }
        }

        if (data)
            free(data);
        png_write_end(png_ptr, info_ptr);
        png_destroy_write_struct(&png_ptr, (png_infopp) & info_ptr);
        png_destroy_info_struct(png_ptr, (png_infopp) & info_ptr);

        *length = dump_data.size;
        char *result;
        result = dump_data.data;
        return result;
    }
}

void free_data(char *data) {
    if(data)
        free(data);
}
