#ifndef DATA64
#define DATA64  unsigned long long
#define DATA32  unsigned int
#define DATA16  unsigned short
#define DATA8   unsigned char
#endif

struct _image_data {
   int               w, h, has_alpha;
   DATA32           *data;
};
typedef struct _image_data ImageData;

struct _dump_data {
    size_t size;
    char *data;
};
typedef struct _dump_data DumpData;

char *save(ImageData *im, int *length);
void free_data(char *data);
