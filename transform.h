struct _filter {
    int filterW;
    int filterH;
    double factor;
    double bias;
    double *matrix;
};
typedef struct _filter Filter;
