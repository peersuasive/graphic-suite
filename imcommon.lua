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

return {
    sum = sum
}
