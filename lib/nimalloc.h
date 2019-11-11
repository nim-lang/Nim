#include <stdalign.h>

// this type is used in alloc.nim. It is intended to ensure 16 byte
// alignments for all allocations.
typedef struct {
  alignas(16) char unused;
} NimAlign16Type;
