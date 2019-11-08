
// this type is used in alloc.nim. It is intended to ensure 16 byte
// alignments for all allocations.
typedef struct {} __attribute__ ((aligned (16))) NimAlign16Type;
